#!/bin/bash
# ============================================
# Demo Ato 7: Cleanup - Destruir todos recursos
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$PROJECT_DIR/.demo-env"
TF_DIR="$PROJECT_DIR/infra/environments/dev"

# Load env for RESOURCE_GROUP
RESOURCE_GROUP="rg-iris-dev"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
    RESOURCE_GROUP="${RESOURCE_GROUP:-rg-iris-dev}"
fi

echo "============================================"
echo " Ato 7: Cleanup"
echo "============================================"
echo ""
echo " ATENCAO: Isso vai destruir TODOS os recursos Azure!"
echo ""
read -p " Confirma? [y/N] " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo " Cancelado."
    exit 0
fi

# Delete K8s namespace first (avoids terraform destroy hanging on AKS resources)
echo ""
echo "--- Deletando namespace iris-ml ---"
kubectl delete namespace iris-ml --timeout=120s 2>/dev/null || true

# Terraform destroy
echo ""
echo "--- Terraform Destroy ---"
cd "$TF_DIR"
if terraform destroy -auto-approve; then
    echo "  Terraform destroy: OK"
else
    echo "  AVISO: Terraform destroy falhou. Tentando fallback com az group delete..."
    echo ""
    echo "--- Fallback: az group delete ---"
    az group delete --name "$RESOURCE_GROUP" --yes --no-wait || true
    echo "  Resource group '$RESOURCE_GROUP' marcado para delecao."
fi

# Remove terraform state files
echo ""
echo "--- Limpando terraform state ---"
rm -f "$TF_DIR/terraform.tfstate" "$TF_DIR/terraform.tfstate.backup"
rm -rf "$TF_DIR/.terraform"

# Restore any modified git-tracked files (use git restore instead of checkout --)
echo ""
echo "--- Restaurando arquivos git ---"
cd "$PROJECT_DIR"
git restore k8s/overlays/dev/kustomization.yaml 2>/dev/null || true
git restore k8s/overlays/dev/secrets.yaml 2>/dev/null || true
git restore k8s/base/common/configmap.yaml 2>/dev/null || true

# Remove .demo-env and results files
rm -f "$ENV_FILE"
rm -f "$PROJECT_DIR"/.demo-results-*.json

echo ""
echo "============================================"
echo " Cleanup Completo"
echo "============================================"
echo " Todos os recursos Azure foram destruidos."
echo " Arquivos temporarios e resultados removidos."
echo "============================================"
