#!/bin/bash
# ============================================
# Init Container: Download model from Azure Blob Storage
#
# Auth modes (auto-detected):
#   1. Connection string (STORAGE_CONNECTION_STRING) - for demo/dev
#   2. Managed Identity (Workload Identity on AKS) - for production
# ============================================

set -euo pipefail

MODEL_DIR="/models"
STORAGE_CONTAINER="${STORAGE_CONTAINER:-models}"
MODEL_BLOB_NAME="${MODEL_BLOB_NAME:?MODEL_BLOB_NAME is required}"

echo "=== Model Download Init Container ==="
echo "Container:       ${STORAGE_CONTAINER}"
echo "Blob:            ${MODEL_BLOB_NAME}"
echo "Target:          ${MODEL_DIR}/model.pkl"

if [ -n "${STORAGE_CONNECTION_STRING:-}" ]; then
    # Mode 1: Connection string (demo/dev)
    echo "Auth mode:       Connection String"
    az storage blob download \
        --connection-string "${STORAGE_CONNECTION_STRING}" \
        --container-name "${STORAGE_CONTAINER}" \
        --name "${MODEL_BLOB_NAME}" \
        --file "${MODEL_DIR}/model.pkl" \
        --output none
else
    # Mode 2: Managed Identity (production)
    STORAGE_ACCOUNT="${STORAGE_ACCOUNT:?STORAGE_ACCOUNT or STORAGE_CONNECTION_STRING is required}"
    echo "Auth mode:       Managed Identity"
    echo "Storage Account: ${STORAGE_ACCOUNT}"

    az login --identity --allow-no-subscriptions --output none 2>/dev/null || {
        echo "WARN: Managed Identity login failed, trying existing credentials..."
    }

    az storage blob download \
        --account-name "${STORAGE_ACCOUNT}" \
        --container-name "${STORAGE_CONTAINER}" \
        --name "${MODEL_BLOB_NAME}" \
        --file "${MODEL_DIR}/model.pkl" \
        --auth-mode login \
        --output none
fi

# Verify download
if [ -f "${MODEL_DIR}/model.pkl" ]; then
    FILE_SIZE=$(stat -c%s "${MODEL_DIR}/model.pkl" 2>/dev/null || stat -f%z "${MODEL_DIR}/model.pkl" 2>/dev/null || echo "unknown")
    echo "Download complete. File size: ${FILE_SIZE} bytes"
else
    echo "ERROR: model.pkl not found after download"
    exit 1
fi

echo "=== Init Container Complete ==="
