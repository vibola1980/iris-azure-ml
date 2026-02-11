#!/bin/bash
# ============================================
# Demo Ato 3/6: Databricks Training Pipeline
# ============================================
# Usa job persistente (jobs/create + jobs/run-now)
# O job fica visivel no Databricks UI com historico de runs
#
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

JOB_NAME="iris-automl-training-v5"
JOB_DEF_FILE="$PROJECT_DIR/databricks/jobs/training_job.json"
TIMEOUT_SECONDS=900  # 15 minutes

echo "============================================"
echo " Databricks Training Pipeline"
echo "============================================"
echo "  Feature set:    $FEATURE_SET"
echo "  Model version:  $MODEL_VERSION"
echo "  Workspace:      $DATABRICKS_HOST"
echo "  Job:            $JOB_NAME"
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

    NOTEBOOK_BASE="/Users/viniciuspolmil@gmail.com/iris-ml-v5"

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

# --- Find or create persistent job ---
echo ""
echo "--- Buscando job '$JOB_NAME' ---"

LIST_RESPONSE=$(curl -s -G \
    "${DATABRICKS_HOST}/api/2.1/jobs/list" \
    --data-urlencode "name=${JOB_NAME}" \
    -H "Authorization: Bearer ${DATABRICKS_TOKEN}")

JOB_ID=$(python -c "
import sys, json
data = json.load(sys.stdin)
jobs = data.get('jobs', [])
for j in jobs:
    if j['settings']['name'] == '${JOB_NAME}':
        print(j['job_id'])
        sys.exit(0)
print('')
" <<< "$LIST_RESPONSE" 2>/dev/null || echo "")

if [ -z "$JOB_ID" ]; then
    echo "  Job nao encontrado. Criando..."
    CREATE_RESPONSE=$(curl -s -X POST \
        "${DATABRICKS_HOST}/api/2.1/jobs/create" \
        -H "Authorization: Bearer ${DATABRICKS_TOKEN}" \
        -H "Content-Type: application/json" \
        -d @"$JOB_DEF_FILE")

    JOB_ID=$(python -c "import sys,json; print(json.load(sys.stdin)['job_id'])" <<< "$CREATE_RESPONSE")
    echo "  Job criado: ID=$JOB_ID"
else
    echo "  Job encontrado: ID=$JOB_ID"
fi

# --- Trigger run with parameters ---
echo ""
echo "--- Triggering run (feature_set=$FEATURE_SET, version=$MODEL_VERSION) ---"

RUN_RESPONSE=$(curl -s -X POST \
    "${DATABRICKS_HOST}/api/2.1/jobs/run-now" \
    -H "Authorization: Bearer ${DATABRICKS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
        \"job_id\": ${JOB_ID},
        \"job_parameters\": {
            \"feature_set\": \"${FEATURE_SET}\",
            \"model_version\": \"${MODEL_VERSION}\",
            \"storage_connection_string\": \"${STORAGE_CONNECTION_STRING}\"
        }
    }")

RUN_ID=$(python -c "import sys,json; print(json.load(sys.stdin)['run_id'])" <<< "$RUN_RESPONSE")
echo "  Run ID: $RUN_ID"

# --- Wait for completion with timeout ---
echo ""
echo "--- Aguardando conclusao (timeout: ${TIMEOUT_SECONDS}s) ---"
START_TIME=$SECONDS

while true; do
    ELAPSED=$(( SECONDS - START_TIME ))
    if [ "$ELAPSED" -ge "$TIMEOUT_SECONDS" ]; then
        echo "  ERRO: Timeout apos ${TIMEOUT_SECONDS}s!"
        echo "  Verifique no Databricks UI: Jobs > $JOB_NAME > Run $RUN_ID"
        exit 1
    fi

    STATUS_RESPONSE=$(curl -s \
        "${DATABRICKS_HOST}/api/2.1/jobs/runs/get?run_id=${RUN_ID}" \
        -H "Authorization: Bearer ${DATABRICKS_TOKEN}")

    STATE=$(python -c "import sys,json; print(json.load(sys.stdin)['state']['life_cycle_state'])" <<< "$STATUS_RESPONSE")

    if [ "$STATE" = "TERMINATED" ]; then
        RESULT=$(python -c "import sys,json; print(json.load(sys.stdin)['state']['result_state'])" <<< "$STATUS_RESPONSE")
        echo "  Concluido: $RESULT (${ELAPSED}s)"
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
        echo "  Status: $STATE (${ELAPSED}s elapsed)..."
        sleep 15
    fi
done

echo ""
echo "============================================"
echo " Training Completo"
echo "============================================"
echo "  Job:      $JOB_NAME (ID: $JOB_ID)"
echo "  Run:      $RUN_ID"
echo "  Modelo:   iris-classifier/v${MODEL_VERSION}/model.pkl"
echo "  Storage:  models (container)"
echo "  Features: $FEATURE_SET"
echo "============================================"
