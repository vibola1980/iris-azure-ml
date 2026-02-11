#!/bin/bash
# ============================================
# Demo Ato 4: Build, Push e Deploy no AKS
# ============================================
# Builds Docker images, pushes to ACR, deploys to AKS
# Usa overlay temporario para NAO modificar arquivos git-tracked
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$PROJECT_DIR/.demo-env"

source "$ENV_FILE"

ACR_LOGIN_SERVER="${ACR_LOGIN_SERVER:?Run 01_provision.sh first}"
ACR_NAME="${ACR_NAME:?Run 01_provision.sh first}"
AKS_CLUSTER_NAME="${AKS_CLUSTER_NAME:?Run 01_provision.sh first}"
RESOURCE_GROUP="${RESOURCE_GROUP:?Run 01_provision.sh first}"
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:?Run 01_provision.sh first}"
STORAGE_CONNECTION_STRING="${STORAGE_CONNECTION_STRING:?Run 01_provision.sh first}"
API_KEY="${API_KEY:-demo-key-2025}"
MODEL_VERSION="${1:-1}"
MODEL_BLOB="iris-classifier/v${MODEL_VERSION}/model.pkl"

echo "============================================"
echo " Ato 4: Build, Push e Deploy"
echo "============================================"
echo "  ACR:     $ACR_LOGIN_SERVER"
echo "  AKS:     $AKS_CLUSTER_NAME"
echo "  Model:   v$MODEL_VERSION ($MODEL_BLOB)"
echo ""

# --- Build Docker images ---
echo "--- Building Docker images ---"
docker build -t "${ACR_LOGIN_SERVER}/iris/inference-service:v${MODEL_VERSION}" \
    "$PROJECT_DIR/apps/inference-service"
echo "  inference-service: OK"

docker build -t "${ACR_LOGIN_SERVER}/iris/api-gateway:v${MODEL_VERSION}" \
    "$PROJECT_DIR/apps/api-gateway"
echo "  api-gateway: OK"

# --- Push to ACR ---
echo ""
echo "--- Pushing to ACR ---"
az acr login --name "$ACR_NAME"
docker push "${ACR_LOGIN_SERVER}/iris/inference-service:v${MODEL_VERSION}"
echo "  inference-service: pushed"
docker push "${ACR_LOGIN_SERVER}/iris/api-gateway:v${MODEL_VERSION}"
echo "  api-gateway: pushed"

# --- Configure AKS ---
echo ""
echo "--- Configurando AKS ---"
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER_NAME" --overwrite-existing

# --- Create namespace ---
echo ""
echo "--- Criando namespace iris-ml ---"
kubectl create namespace iris-ml 2>/dev/null || true

# --- Create temporary overlay (do NOT modify git-tracked files) ---
echo ""
echo "--- Criando overlay temporario ---"
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Copy overlay files to temp dir
cp "$PROJECT_DIR/k8s/overlays/dev/kustomization.yaml" "$TEMP_DIR/kustomization.yaml"

# Fix base path: relative ../../base -> absolute path
sed -i "s|../../base|${PROJECT_DIR}/k8s/base|g" "$TEMP_DIR/kustomization.yaml"

# Update ACR image references
sed -i "s|acririsdev.azurecr.io|${ACR_LOGIN_SERVER}|g" "$TEMP_DIR/kustomization.yaml"
sed -i "s|acririsdevXXXXXX.azurecr.io|${ACR_LOGIN_SERVER}|g" "$TEMP_DIR/kustomization.yaml"

# Update image tags
sed -i "s|newTag: \"v1\"|newTag: \"v${MODEL_VERSION}\"|g" "$TEMP_DIR/kustomization.yaml"
sed -i "s|newTag: \"1.0.0\"|newTag: \"v${MODEL_VERSION}\"|g" "$TEMP_DIR/kustomization.yaml"

# Update storage account
sed -i "s|stirisdevXXXXXX|${STORAGE_ACCOUNT}|g" "$TEMP_DIR/kustomization.yaml"
sed -i "s|stirisdevxjrpx1|${STORAGE_ACCOUNT}|g" "$TEMP_DIR/kustomization.yaml"

# Update model blob name and version
sed -i "s|iris-classifier/v1/model.pkl|${MODEL_BLOB}|g" "$TEMP_DIR/kustomization.yaml"
sed -i "s|iris-classifier/v1.0.0/model.pkl|${MODEL_BLOB}|g" "$TEMP_DIR/kustomization.yaml"
sed -i 's|value: "1"|value: "'"v${MODEL_VERSION}"'"|g' "$TEMP_DIR/kustomization.yaml"

# Generate secrets.yaml in temp dir with real values
cat > "$TEMP_DIR/secrets.yaml" <<SECEOF
apiVersion: v1
kind: Secret
metadata:
  name: iris-ml-secrets
  namespace: iris-ml
  labels:
    app.kubernetes.io/name: iris-ml
type: Opaque
stringData:
  api-key: "${API_KEY}"
  storage-connection-string: '${STORAGE_CONNECTION_STRING}'
SECEOF

echo "  Overlay temporario criado em: $TEMP_DIR"

# --- Deploy ---
echo ""
echo "--- Deploying to AKS ---"
kubectl apply -k "$TEMP_DIR"

echo ""
echo "--- Aguardando pods ficarem prontos ---"
kubectl rollout status deployment/api-gateway -n iris-ml --timeout=300s
kubectl rollout status deployment/inference-service -n iris-ml --timeout=300s

# --- Show status ---
echo ""
echo "--- Status ---"
kubectl get pods -n iris-ml
echo ""
kubectl get svc -n iris-ml

# --- Wait for External IP ---
echo ""
echo "--- Aguardando External IP ---"
MAX_WAIT=120
WAITED=0
EXTERNAL_IP=""
while [ "$WAITED" -lt "$MAX_WAIT" ]; do
    EXTERNAL_IP=$(kubectl get svc api-gateway-external -n iris-ml \
        -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ -n "$EXTERNAL_IP" ]; then
        break
    fi
    echo "  Aguardando IP... (${WAITED}s)"
    sleep 10
    WAITED=$((WAITED + 10))
done

echo ""
echo "============================================"
echo " Deploy Completo"
echo "============================================"
if [ -n "$EXTERNAL_IP" ]; then
    echo "  API: http://${EXTERNAL_IP}/predict"
else
    echo "  API: IP ainda pendente (aguarde e execute):"
    echo "    kubectl get svc api-gateway-external -n iris-ml -w"
fi
echo "  Model: v${MODEL_VERSION} (${MODEL_BLOB})"
echo "============================================"
