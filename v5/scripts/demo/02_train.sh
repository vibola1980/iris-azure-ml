#!/bin/bash
# ============================================
# Demo Ato 3/6: Databricks Training Pipeline
# ============================================
# Usage:
#   ./02_train.sh sepal_only 1    # v1: 2 features
#   ./02_train.sh all_features 2  # v2: 4 features
# ============================================

set -euo pipefail

FEATURE_SET="${1:?Usage: $0 <sepal_only|all_features> <model_version>}"
MODEL_VERSION="${2:?Usage: $0 <sepal_only|all_features> <model_version>}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$PROJECT_DIR/.demo-env"

source "$ENV_FILE"

DATABRICKS_HOST="${DATABRICKS_HOST:?Set DATABRICKS_HOST in .demo-env}"
DATABRICKS_TOKEN="${DATABRICKS_TOKEN:?Set DATABRICKS_TOKEN in .demo-env}"
STORAGE_CONNECTION_STRING="${STORAGE_CONNECTION_STRING:?Run 01_provision.sh first}"
NOTEBOOK_BASE="/Users/viniciuspolmil@gmail.com/iris-ml-v5"

echo "============================================"
echo " Databricks Training Pipeline"
echo "============================================"
echo "  Feature set:    $FEATURE_SET"
echo "  Model version:  $MODEL_VERSION"
echo "  Workspace:      $DATABRICKS_HOST"
echo ""

# --- Upload notebooks ---
echo "--- Uploading notebooks ---"
for nb in 01_data_ingestion 02_automl_training 03_model_export; do
    NB_FILE="$PROJECT_DIR/databricks/notebooks/${nb}.py"
    CONTENT=$(python -c "
import base64, sys
with open(sys.argv[1], 'rb') as f:
    print(base64.b64encode(f.read()).decode())
" "$NB_FILE")

    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "${DATABRICKS_HOST}/api/2.0/workspace/import" \
        -H "Authorization: Bearer ${DATABRICKS_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{
            \"path\": \"${NOTEBOOK_BASE}/${nb}\",
            \"language\": \"PYTHON\",
            \"overwrite\": true,
            \"content\": \"${CONTENT}\"
        }")
    echo "  ${nb}: ${HTTP_CODE}"
done

# --- Submit training job ---
echo ""
echo "--- Submitting job (feature_set=$FEATURE_SET, version=$MODEL_VERSION) ---"

# Write job JSON to temp file (avoids escaping issues)
JOB_JSON=$(mktemp)
cat > "$JOB_JSON" <<JOBEOF
{
    "run_name": "iris-demo-v${MODEL_VERSION}-${FEATURE_SET}",
    "tasks": [
        {
            "task_key": "data_ingestion",
            "notebook_task": {
                "notebook_path": "${NOTEBOOK_BASE}/01_data_ingestion"
            }
        },
        {
            "task_key": "automl_training",
            "depends_on": [{"task_key": "data_ingestion"}],
            "notebook_task": {
                "notebook_path": "${NOTEBOOK_BASE}/02_automl_training",
                "base_parameters": {
                    "feature_set": "${FEATURE_SET}",
                    "model_version": "${MODEL_VERSION}"
                }
            }
        },
        {
            "task_key": "model_export",
            "depends_on": [{"task_key": "automl_training"}],
            "notebook_task": {
                "notebook_path": "${NOTEBOOK_BASE}/03_model_export",
                "base_parameters": {
                    "storage_connection_string": "${STORAGE_CONNECTION_STRING}",
                    "storage_container": "models"
                }
            }
        }
    ]
}
JOBEOF

RUN_RESPONSE=$(curl -s -X POST "${DATABRICKS_HOST}/api/2.1/jobs/runs/submit" \
    -H "Authorization: Bearer ${DATABRICKS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d @"$JOB_JSON")
rm -f "$JOB_JSON"

RUN_ID=$(python -c "import sys,json; print(json.load(sys.stdin)['run_id'])" <<< "$RUN_RESPONSE")
echo "  Run ID: $RUN_ID"

# --- Wait for completion ---
echo ""
echo "--- Aguardando conclusao ---"
while true; do
    STATUS_RESPONSE=$(curl -s \
        "${DATABRICKS_HOST}/api/2.1/jobs/runs/get?run_id=${RUN_ID}" \
        -H "Authorization: Bearer ${DATABRICKS_TOKEN}")

    STATE=$(python -c "import sys,json; print(json.load(sys.stdin)['state']['life_cycle_state'])" <<< "$STATUS_RESPONSE")

    if [ "$STATE" = "TERMINATED" ]; then
        RESULT=$(python -c "import sys,json; print(json.load(sys.stdin)['state']['result_state'])" <<< "$STATUS_RESPONSE")
        echo "  Concluido: $RESULT"
        if [ "$RESULT" != "SUCCESS" ]; then
            echo "  ERRO: Job falhou!"
            python -c "import sys,json; s=json.load(sys.stdin)['state']; print(s.get('state_message',''))" <<< "$STATUS_RESPONSE"
            exit 1
        fi
        break
    elif [ "$STATE" = "INTERNAL_ERROR" ] || [ "$STATE" = "SKIPPED" ]; then
        echo "  ERRO: $STATE"
        exit 1
    else
        echo "  Status: $STATE ..."
        sleep 15
    fi
done

echo ""
echo "============================================"
echo " Training Completo"
echo "============================================"
echo "  Modelo: iris-classifier/v${MODEL_VERSION}/model.pkl"
echo "  Storage: models (container)"
echo "  Features: $FEATURE_SET"
echo "============================================"
