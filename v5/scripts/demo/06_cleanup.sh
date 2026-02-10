#!/bin/bash
# ============================================
# Demo Ato 7: Cleanup - Destruir todos recursos
# ============================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$PROJECT_DIR/.demo-env"
TF_DIR="$PROJECT_DIR/infra/environments/dev"

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

# Terraform destroy
echo ""
echo "--- Terraform Destroy ---"
cd "$TF_DIR"
terraform destroy -auto-approve

# Restore modified K8s files
echo ""
echo "--- Restaurando arquivos K8s ---"
cd "$PROJECT_DIR"
git checkout -- k8s/overlays/dev/kustomization.yaml
git checkout -- k8s/overlays/dev/secrets.yaml
git checkout -- k8s/base/common/configmap.yaml

# Remove .demo-env
rm -f "$ENV_FILE"

echo ""
echo "============================================"
echo " Cleanup Completo"
echo "============================================"
echo " Todos os recursos Azure foram destruidos."
echo " Arquivos K8s restaurados ao estado original."
echo "============================================"
