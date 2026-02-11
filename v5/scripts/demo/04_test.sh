#!/bin/bash
# ============================================
# Demo Ato 5: Testar Predicoes na API
# ============================================
# Salva resultados em .demo-results-v{N}.json
# Se v1 e v2 existem, mostra tabela comparativa
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$PROJECT_DIR/.demo-env"

source "$ENV_FILE"
API_KEY="${API_KEY:-demo-key-2025}"

# Wait for External IP with retry
echo "--- Obtendo External IP ---"
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

if [ -z "$EXTERNAL_IP" ]; then
    echo "ERRO: External IP nao disponivel apos ${MAX_WAIT}s."
    echo "Execute: kubectl get svc api-gateway-external -n iris-ml -w"
    exit 1
fi

API_URL="http://${EXTERNAL_IP}"

# Detect model version from API (try both camelCase and snake_case)
MODEL_VERSION=$(curl -s -m 10 "${API_URL}/health/ready" \
    -H "X-API-Key: ${API_KEY}" \
    | python -c "
import sys, json
data = json.load(sys.stdin)
v = data.get('modelVersion', data.get('model_version', 'unknown'))
print(v)
" 2>/dev/null || echo "unknown")

RESULTS_FILE="$PROJECT_DIR/.demo-results-${MODEL_VERSION}.json"

echo "============================================"
echo " Testando API: $API_URL"
echo " Modelo: $MODEL_VERSION"
echo "============================================"
echo ""

# Health check
echo "--- Health Check ---"
curl -s -m 10 "${API_URL}/health/ready" \
    -H "X-API-Key: ${API_KEY}" | python -m json.tool
echo ""

# Define test cases
INPUTS=(
    '{"sepal_length":5.1,"sepal_width":3.5,"petal_length":1.4,"petal_width":0.2}'
    '{"sepal_length":6.0,"sepal_width":2.7,"petal_length":4.5,"petal_width":1.5}'
    '{"sepal_length":6.7,"sepal_width":3.0,"petal_length":5.2,"petal_width":2.3}'
)
LABELS=("Setosa tipica" "Versicolor (ambigua)" "Virginica (dificil)")
COORDS=("[5.1, 3.5, 1.4, 0.2]" "[6.0, 2.7, 4.5, 1.5]" "[6.7, 3.0, 5.2, 2.3]")

# Run predictions and collect results
ALL_RESULTS="["
FIRST=true

for i in 0 1 2; do
    echo "--- Predicao $((i+1)): ${LABELS[$i]} ---"
    echo "  Input: ${COORDS[$i]}"

    RESULT=$(curl -s -m 10 -X POST "${API_URL}/predict" \
        -H "Content-Type: application/json" \
        -H "X-API-Key: ${API_KEY}" \
        -d "${INPUTS[$i]}")

    echo "$RESULT" | python -m json.tool
    echo ""

    if [ "$FIRST" = true ]; then
        ALL_RESULTS="${ALL_RESULTS}${RESULT}"
        FIRST=false
    else
        ALL_RESULTS="${ALL_RESULTS},${RESULT}"
    fi
done

ALL_RESULTS="${ALL_RESULTS}]"

# Save results
echo "$ALL_RESULTS" | python -m json.tool > "$RESULTS_FILE"
echo "Resultados salvos em: .demo-results-${MODEL_VERSION}.json"

# Check if both v1 and v2 exist for comparison
V1_FILE="$PROJECT_DIR/.demo-results-v1.json"
V2_FILE="$PROJECT_DIR/.demo-results-v2.json"

if [ -f "$V1_FILE" ] && [ -f "$V2_FILE" ]; then
    echo ""
    python "$SCRIPT_DIR/compare_results.py" "$V1_FILE" "$V2_FILE"
fi
