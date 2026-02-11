#!/bin/bash
# ============================================
# Demo Ato 2: Provisionar Infraestrutura Azure
# ============================================
# Executa terraform apply e salva outputs em .demo-env
# Inclui retry para RBAC propagation delays
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

# Terraform init + apply with retry for RBAC propagation
echo "--- Terraform Init ---"
cd "$TF_DIR"
terraform init -input=false

echo ""
echo "--- Terraform Apply ---"
MAX_RETRIES=2
for attempt in $(seq 1 $MAX_RETRIES); do
    echo "  Tentativa $attempt de $MAX_RETRIES..."
    if terraform apply -var="api_key=$API_KEY" -auto-approve; then
        echo "  Terraform apply: OK"
        break
    else
        if [ "$attempt" -lt "$MAX_RETRIES" ]; then
            echo "  Terraform apply falhou (provavel RBAC propagation delay)."
            echo "  Aguardando 60s antes de retry..."
            sleep 60
        else
            echo "  ERRO: Terraform apply falhou apos $MAX_RETRIES tentativas."
            exit 1
        fi
    fi
done

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
# Use printf to avoid heredoc expansion issues with ; and $ in connection string
{
    printf '# Databricks (pre-configured)\n'
    printf 'DATABRICKS_HOST=%s\n' "$DATABRICKS_HOST"
    printf 'DATABRICKS_TOKEN=%s\n' "$DATABRICKS_TOKEN"
    printf 'API_KEY=%s\n' "$API_KEY"
    printf '\n'
    printf '# Azure (from terraform output)\n'
    printf 'ACR_LOGIN_SERVER=%s\n' "$ACR_LOGIN_SERVER"
    printf 'ACR_NAME=%s\n' "$ACR_NAME"
    printf 'STORAGE_ACCOUNT=%s\n' "$STORAGE_ACCOUNT"
    printf "STORAGE_CONNECTION_STRING='%s'\n" "$STORAGE_CONNECTION_STRING"
    printf 'AKS_CLUSTER_NAME=%s\n' "$AKS_CLUSTER_NAME"
    printf 'RESOURCE_GROUP=%s\n' "$RESOURCE_GROUP"
} > "$ENV_FILE"

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
