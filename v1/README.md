# Iris ML na Azure (Terraform + FastAPI + ACI)

## Pré-requisitos
- Azure CLI autenticado (`az login`)
- Terraform instalado
- Docker instalado
- Python 3.11+

## 1) Subir infra (ACR, Storage, KeyVault) com Terraform
cd infra
cp terraform.tfvars.example terraform.tfvars
# Edite prefix/container_image/api_key

terraform init
terraform apply

Anote os outputs:
- acr_login_server    (ex: irisexpvibolaacr.azurecr.io)
- acr_name            (ex: irisexpvibolaacr)
- key_vault_name      (ex: irisexp-vibola-1-kv)
- storage_account_name (ex: irisexpvibola1sa)
- file_share_name     (ex: mlshare)

## 2) Build e push da imagem para o ACR
cd ..
docker build -t iris-api:1.0.0 .

# Login no ACR
az acr login --name <acr_name>
# Exemplo: az acr login --name irisexpvibola1acr.azurecr.io

# Tag e push para o ACR
docker tag iris-api:1.0.0 <acr_login_server>/iris-api:1.0.0
docker push <acr_login_server>/iris-api:1.0.0
# Exemplo:
# docker tag vibola/iris-api:1.0.0 irisexpvibola1acr.azurecr.io/iris-api:1.0.0
# docker push irisexpvibola1acr.azurecr.io/iris-api:1.0.0

## 3) Treinar e gerar artifacts/model.pkl
cd training
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python train.py

## 4) Upload do model.pkl para o File Share montado no container
cd ..
./scripts/upload_model_to_fileshare.sh <key_vault_name> <storage_account_name> <file_share_name>

## 5) Provisionar ACI com a imagem já disponível no ACR
cd infra
terraform apply

Anote o output:
- predict_url = http://<fqdn>:8000/predict

## 6) Testar API
cd ..
./scripts/test_api.sh <predict_url> <api_key>

## 7) Destruir recursos (evitar custos)
cd infra
terraform destroy
