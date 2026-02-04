# Azure Deployment Guide

Guia passo a passo para fazer o deploy do Iris ML API v4 na Azure usando Terraform.

## Pré-requisitos

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) instalado
- [Terraform](https://www.terraform.io/downloads) 1.5+ instalado
- [kubectl](https://kubernetes.io/docs/tasks/tools/) instalado
- Conta Azure com permissões de Contributor

## 1. Configurar Azure CLI

```bash
# Login na Azure (abre navegador)
az login

# Verificar subscription ativa
az account show

# Listar todas as subscriptions
az account list --output table

# Se precisar mudar de subscription
az account set --subscription "SUBSCRIPTION_ID"
```

## 2. Criar Service Principal para Terraform

O Terraform precisa de um Service Principal para autenticar na Azure.

```bash
# Obter o ID da subscription atual
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Criar Service Principal com role Contributor
az ad sp create-for-rbac \
  --name "sp-iris-terraform" \
  --role Contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --sdk-auth
```

**Guarde o output JSON!** Você precisará dos seguintes valores:

| Campo JSON | Variável Terraform |
|------------|-------------------|
| `clientId` | `ARM_CLIENT_ID` |
| `clientSecret` | `ARM_CLIENT_SECRET` |
| `subscriptionId` | `ARM_SUBSCRIPTION_ID` |
| `tenantId` | `ARM_TENANT_ID` |

## 3. Configurar Variáveis de Ambiente

### Opção A: Variáveis de Ambiente (Recomendado para CI/CD)

**Windows PowerShell:**
```powershell
$env:ARM_CLIENT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$env:ARM_CLIENT_SECRET="sua-senha-secreta"
$env:ARM_SUBSCRIPTION_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$env:ARM_TENANT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

**Windows CMD:**
```cmd
set ARM_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
set ARM_CLIENT_SECRET=sua-senha-secreta
set ARM_SUBSCRIPTION_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
set ARM_TENANT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

**Linux/Mac:**
```bash
export ARM_CLIENT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export ARM_CLIENT_SECRET="sua-senha-secreta"
export ARM_SUBSCRIPTION_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export ARM_TENANT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

### Opção B: Arquivo terraform.tfvars (Desenvolvimento Local)

Crie o arquivo `v4/infra/environments/dev/terraform.tfvars`:

```hcl
location = "eastus"
api_key  = "sua-api-key-segura"

alert_email_addresses = [
  "seu-email@example.com"
]
```

> **IMPORTANTE:** Nunca commite o arquivo `terraform.tfvars` com secrets! Ele já está no `.gitignore`.

## 4. Configurar Backend Remoto (Opcional, Recomendado)

Para armazenar o estado do Terraform de forma segura e compartilhada:

```bash
# Criar Resource Group para o state
az group create --name rg-terraform-state --location eastus

# Criar Storage Account (nome deve ser único globalmente)
STORAGE_ACCOUNT_NAME="stterraformstate$(date +%s)"
az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group rg-terraform-state \
  --sku Standard_LRS \
  --encryption-services blob

# Criar container para o tfstate
az storage container create \
  --name tfstate \
  --account-name $STORAGE_ACCOUNT_NAME

# Mostrar o nome da storage account
echo "Storage Account: $STORAGE_ACCOUNT_NAME"
```

Depois, descomente o bloco `backend` em `v4/infra/environments/dev/main.tf`:

```hcl
backend "azurerm" {
  resource_group_name  = "rg-terraform-state"
  storage_account_name = "SEU_STORAGE_ACCOUNT_NAME"
  container_name       = "tfstate"
  key                  = "iris-ml-v4-dev.tfstate"
}
```

## 5. Deploy da Infraestrutura

### 5.1 Inicializar Terraform

```bash
cd v4/infra/environments/dev

# Inicializar (baixa providers e módulos)
terraform init
```

### 5.2 Validar Configuração

```bash
# Validar sintaxe
terraform validate

# Formatar código (opcional)
terraform fmt
```

### 5.3 Planejar Deploy

```bash
# Ver o que será criado (sem aplicar)
terraform plan -var="api_key=minha-api-key-segura"

# Ou se estiver usando terraform.tfvars
terraform plan
```

Revise o plano cuidadosamente. Você verá algo como:

```
Plan: 15 to add, 0 to change, 0 to destroy.
```

### 5.4 Aplicar Deploy

```bash
# Criar os recursos na Azure
terraform apply -var="api_key=minha-api-key-segura"

# Digite "yes" quando solicitado
```

O deploy leva aproximadamente **15-20 minutos** (AKS é o mais demorado).

### 5.5 Obter Outputs

```bash
# Ver todos os outputs
terraform output

# Outputs específicos
terraform output acr_login_server
terraform output aks_cluster_name
terraform output keyvault_name
```

## 6. Configurar kubectl para o AKS

```bash
# Obter credenciais do AKS
az aks get-credentials \
  --resource-group rg-iris-dev \
  --name aks-iris-dev

# Verificar conexão
kubectl get nodes
```

## 7. Deploy da Aplicação

### 7.1 Build e Push das Imagens

```bash
# Login no ACR
ACR_NAME=$(terraform output -raw acr_name)
az acr login --name $ACR_NAME

# Build e push das imagens
cd v4

# API Gateway
docker build -t $ACR_NAME.azurecr.io/iris/api-gateway:v1.0.0 ./apps/api-gateway
docker push $ACR_NAME.azurecr.io/iris/api-gateway:v1.0.0

# Inference Service
docker build -t $ACR_NAME.azurecr.io/iris/inference-service:v1.0.0 ./apps/inference-service
docker push $ACR_NAME.azurecr.io/iris/inference-service:v1.0.0
```

### 7.2 Upload do Modelo para Blob Storage

```bash
# Treinar modelo se necessário
cd v4/ml/training
python train.py

# Upload para Azure Blob Storage
STORAGE_ACCOUNT=$(terraform output -raw storage_account_name)
az storage blob upload \
  --account-name $STORAGE_ACCOUNT \
  --container-name models \
  --name iris-classifier/v1.0.0/model.pkl \
  --file ../models/model.pkl \
  --auth-mode login
```

### 7.3 Atualizar Kustomize com ACR

Edite `v4/k8s/overlays/dev/kustomization.yaml`:

```yaml
images:
  - name: api-gateway
    newName: SEU_ACR.azurecr.io/iris/api-gateway
    newTag: v1.0.0
  - name: inference-service
    newName: SEU_ACR.azurecr.io/iris/inference-service
    newTag: v1.0.0
```

### 7.4 Deploy no Kubernetes

```bash
cd v4

# Validar manifests
kubectl apply --dry-run=client -k k8s/overlays/dev

# Aplicar
kubectl apply -k k8s/overlays/dev

# Verificar status
kubectl get pods -n iris-ml
kubectl get svc -n iris-ml
```

## 8. Testar a Aplicação

```bash
# Obter IP externo do LoadBalancer
EXTERNAL_IP=$(kubectl get svc api-gateway-external -n iris-ml -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Testar health check
curl http://$EXTERNAL_IP/health/live

# Testar predição
curl -X POST http://$EXTERNAL_IP/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: minha-api-key-segura" \
  -d '{"sepal_length": 5.1, "sepal_width": 3.5, "petal_length": 1.4, "petal_width": 0.2}'
```

## 9. Limpeza (Destruir Recursos)

**CUIDADO:** Isso irá deletar TODOS os recursos criados!

```bash
cd v4/infra/environments/dev

# Ver o que será destruído
terraform plan -destroy

# Destruir recursos
terraform destroy -var="api_key=minha-api-key-segura"

# Digite "yes" quando solicitado
```

## Estimativa de Custos

### Ambiente Dev

| Recurso | Especificação | Custo Estimado/mês |
|---------|--------------|-------------------|
| AKS Cluster | 2x Standard_D2s_v3 | ~$140 |
| Container Registry | Standard SKU | ~$5 |
| Storage Account | LRS, <1GB | ~$0.02 |
| Key Vault | Standard | ~$0.03 |
| Log Analytics | 5GB/mês | ~$2-5 |
| Virtual Network | - | Gratuito |
| **Total Dev** | | **~$150/mês** |

### Ambiente Prod

| Recurso | Especificação | Custo Estimado/mês |
|---------|--------------|-------------------|
| AKS Cluster | 3x Standard_D2s_v3 + 2x D4s_v3 | ~$350 |
| Container Registry | Premium SKU | ~$50 |
| Storage Account | GRS | ~$0.05 |
| Key Vault | Standard | ~$0.03 |
| Log Analytics | 10GB/mês | ~$5-10 |
| Private Endpoints | 3 endpoints | ~$22 |
| **Total Prod** | | **~$430/mês** |

> **Dica:** Para reduzir custos em dev, você pode desligar o cluster AKS quando não estiver usando:
> ```bash
> az aks stop --name aks-iris-dev --resource-group rg-iris-dev
> az aks start --name aks-iris-dev --resource-group rg-iris-dev
> ```

## Troubleshooting

### Erro: "AuthorizationFailed"

Verifique se o Service Principal tem permissões corretas:
```bash
az role assignment list --assignee $ARM_CLIENT_ID --output table
```

### Erro: "Resource already exists"

O recurso pode já existir. Use `terraform import` ou delete manualmente.

### AKS não consegue puxar imagens do ACR

Verifique o role assignment:
```bash
az aks check-acr --name aks-iris-dev --resource-group rg-iris-dev --acr SEU_ACR.azurecr.io
```

### Pods em CrashLoopBackOff

Verifique os logs:
```bash
kubectl logs -l app=inference-service -n iris-ml --previous
kubectl describe pod -l app=inference-service -n iris-ml
```

## Próximos Passos

1. Configurar domínio customizado e HTTPS (Azure Application Gateway ou Ingress Controller)
2. Configurar GitHub Actions secrets para CI/CD automatizado
3. Implementar Azure Monitor alerts personalizados
4. Configurar backup do Terraform state
