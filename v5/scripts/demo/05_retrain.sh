#!/bin/bash
# ============================================
# Demo Ato 6: Retreinar v2 + Redeploy
# ============================================
# Treina com all_features, atualiza configmap, redeploy
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$PROJECT_DIR/.demo-env"

source "$ENV_FILE"
API_KEY="${API_KEY:-demo-key-2025}"

echo "============================================"
echo " Ato 6: Retreinar e Redeploy"
echo "============================================"
echo ""

# Step 1: Train v2
echo "=== Step 1: Treinar v2 (all_features) ==="
if ! bash "$SCRIPT_DIR/02_train.sh" all_features 2; then
    echo "ERRO: Training v2 falhou!"
    exit 1
fi

# Step 2: Update configmap with new model blob
echo ""
echo "=== Step 2: Atualizando ConfigMap ==="
kubectl patch configmap model-config -n iris-ml \
    --type merge \
    -p '{"data":{"MODEL_BLOB_NAME":"iris-classifier/v2/model.pkl","MODEL_VERSION":"v2"}}'
echo "  MODEL_BLOB_NAME -> iris-classifier/v2/model.pkl"

# Step 3: Restart deployment (triggers init container re-download)
echo ""
echo "=== Step 3: Restarting pods ==="
kubectl rollout restart deployment/inference-service -n iris-ml

echo ""
echo "--- Aguardando pods ficarem prontos ---"
kubectl rollout status deployment/inference-service -n iris-ml --timeout=300s

# Step 4: Health check after restart
echo ""
echo "=== Step 4: Health check ==="
MAX_WAIT=60
WAITED=0
EXTERNAL_IP=$(kubectl get svc api-gateway-external -n iris-ml \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

if [ -n "$EXTERNAL_IP" ]; then
    API_URL="http://${EXTERNAL_IP}"
    while [ "$WAITED" -lt "$MAX_WAIT" ]; do
        HTTP_CODE=$(curl -s -m 10 -o /dev/null -w "%{http_code}" \
            "${API_URL}/health/ready" \
            -H "X-API-Key: ${API_KEY}" 2>/dev/null || echo "000")
        if [ "$HTTP_CODE" = "200" ]; then
            echo "  API respondendo: HTTP $HTTP_CODE"
            break
        fi
        echo "  Aguardando API ficar pronta... (${WAITED}s, HTTP $HTTP_CODE)"
        sleep 5
        WAITED=$((WAITED + 5))
    done
    if [ "$WAITED" -ge "$MAX_WAIT" ]; then
        echo "  AVISO: API nao respondeu em ${MAX_WAIT}s, mas pods estao prontos."
    fi
else
    echo "  AVISO: External IP nao disponivel para health check."
fi

echo ""
echo "============================================"
echo " Redeploy Completo - Modelo v2 ativo"
echo "============================================"
echo ""
echo " Execute o teste novamente para comparar:"
echo "   make demo-test"
echo "============================================"
