#!/bin/bash
# ============================================
# Demo Ato 4: Build, Push e Deploy no AKS
# ============================================
# Builds Docker images, pushes to ACR, deploys to AKS
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

echo "============================================"
echo " Ato 4: Build, Push e Deploy"
echo "============================================"
echo "  ACR:     $ACR_LOGIN_SERVER"
echo "  AKS:     $AKS_CLUSTER_NAME"
echo "  Model:   v$MODEL_VERSION"
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

# --- Update K8s overlay with real values ---
echo ""
echo "--- Atualizando K8s manifests ---"
OVERLAY_DIR="$PROJECT_DIR/k8s/overlays/dev"
KUSTOMIZATION="$OVERLAY_DIR/kustomization.yaml"
SECRETS="$OVERLAY_DIR/secrets.yaml"

# Update ACR image references
sed -i "s|acririsdev.azurecr.io|${ACR_LOGIN_SERVER}|g" "$KUSTOMIZATION"
# Update image tags
sed -i "s|newTag: \"1.0.0\"|newTag: \"v${MODEL_VERSION}\"|g" "$KUSTOMIZATION"
# Update storage account
sed -i "s|value: \"stirisdevxjrpx1\"|value: \"${STORAGE_ACCOUNT}\"|g" "$KUSTOMIZATION"
# Update model blob name
MODEL_BLOB="iris-classifier/v${MODEL_VERSION}/model.pkl"

# Add model blob name patch if not present, or update existing
if grep -q "MODEL_BLOB_NAME" "$KUSTOMIZATION"; then
    sed -i "s|path: /data/MODEL_BLOB_NAME|path: /data/MODEL_BLOB_NAME|g" "$KUSTOMIZATION"
fi

# Update secrets with real values
cat > "$SECRETS" <<EOF
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
  storage-connection-string: "${STORAGE_CONNECTION_STRING}"
EOF
echo "  Overlay atualizado com valores reais"

# Update base configmap with correct blob name
CONFIGMAP="$PROJECT_DIR/k8s/base/common/configmap.yaml"
sed -i "s|MODEL_BLOB_NAME:.*|MODEL_BLOB_NAME: \"${MODEL_BLOB}\"|g" "$CONFIGMAP"
sed -i "s|MODEL_VERSION:.*|MODEL_VERSION: \"v${MODEL_VERSION}\"|g" "$CONFIGMAP"

# --- Deploy ---
echo ""
echo "--- Deploying to AKS ---"
kubectl apply -k "$OVERLAY_DIR"

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

# Get external IP
echo ""
echo "============================================"
echo " Deploy Completo"
echo "============================================"
EXTERNAL_IP=$(kubectl get svc api-gateway -n iris-ml -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
echo "  API: http://${EXTERNAL_IP}/api/v1/predict"
echo "  Model: v${MODEL_VERSION} (${MODEL_BLOB})"
echo ""
echo "  Se IP=pending, aguarde e execute:"
echo "    kubectl get svc api-gateway -n iris-ml -w"
echo "============================================"
