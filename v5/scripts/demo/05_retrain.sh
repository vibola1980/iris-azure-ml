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

echo "============================================"
echo " Ato 6: Retreinar e Redeploy"
echo "============================================"
echo ""

# Step 1: Train v2
echo "=== Step 1: Treinar v2 (all_features) ==="
bash "$SCRIPT_DIR/02_train.sh" all_features 2

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

echo ""
echo "============================================"
echo " Redeploy Completo - Modelo v2 ativo"
echo "============================================"
echo ""
echo " Execute o teste novamente para comparar:"
echo "   make demo-test"
echo "============================================"
