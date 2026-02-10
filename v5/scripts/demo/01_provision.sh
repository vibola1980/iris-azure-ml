#!/bin/bash
# ============================================
# Demo Ato 2: Provisionar Infraestrutura Azure
# ============================================
# Executa terraform apply e salva outputs em .demo-env
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$PROJECT_DIR/.demo-env"
TF_DIR="$PROJECT_DIR/infra/environments/dev"

# Load existing .demo-env for Databricks creds
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo "ERRO: Crie o arquivo .demo-env primeiro:"
    echo "  cp scripts/demo/demo.env.example .demo-env"
    echo "  # Preencha DATABRICKS_HOST, DATABRICKS_TOKEN e API_KEY"
    exit 1
fi

API_KEY="${API_KEY:-demo-key-2025}"

echo "============================================"
echo " Ato 2: Provisionar Infraestrutura Azure"
echo "============================================"
echo ""

# Terraform init + apply
echo "--- Terraform Init ---"
cd "$TF_DIR"
terraform init -input=false

echo ""
echo "--- Terraform Apply ---"
terraform apply -var="api_key=$API_KEY" -auto-approve

# Capture outputs
ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
ACR_NAME=$(echo "$ACR_LOGIN_SERVER" | cut -d. -f1)
STORAGE_ACCOUNT=$(terraform output -raw storage_account_name)
AKS_CLUSTER_NAME=$(terraform output -raw aks_cluster_name 2>/dev/null || echo "aks-iris-dev")
RESOURCE_GROUP="rg-iris-dev"

# Get storage connection string
echo ""
echo "--- Obtendo Connection String ---"
STORAGE_CONNECTION_STRING=$(az storage account show-connection-string \
    --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" \
    --query connectionString -o tsv)

# Create models container
echo "--- Criando container 'models' ---"
az storage container create \
    --name models \
    --connection-string "$STORAGE_CONNECTION_STRING" \
    --output none 2>/dev/null || true

# Save to .demo-env (preserve Databricks creds)
cat > "$ENV_FILE" <<EOF
# Databricks (pre-configured)
DATABRICKS_HOST=${DATABRICKS_HOST}
DATABRICKS_TOKEN=${DATABRICKS_TOKEN}
API_KEY=${API_KEY}

# Azure (from terraform output)
ACR_LOGIN_SERVER=${ACR_LOGIN_SERVER}
ACR_NAME=${ACR_NAME}
STORAGE_ACCOUNT=${STORAGE_ACCOUNT}
STORAGE_CONNECTION_STRING="${STORAGE_CONNECTION_STRING}"
AKS_CLUSTER_NAME=${AKS_CLUSTER_NAME}
RESOURCE_GROUP=${RESOURCE_GROUP}
EOF

echo ""
echo "============================================"
echo " Infraestrutura Provisionada"
echo "============================================"
echo "  ACR:     $ACR_LOGIN_SERVER"
echo "  Storage: $STORAGE_ACCOUNT"
echo "  AKS:     $AKS_CLUSTER_NAME"
echo "  RG:      $RESOURCE_GROUP"
echo ""
echo "  Outputs salvos em: .demo-env"
echo "============================================"
