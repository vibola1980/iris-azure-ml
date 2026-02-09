# Iris ML on Azure (Terraform + FastAPI + ACI)

Deploy a machine learning model as a REST API on Azure using Terraform, Docker, and Azure Container Instances (ACI).

## Architecture

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Azure Key   │     │   Azure      │     │   Azure      │
│   Vault      │     │  Container   │     │  File Share  │
│  (secrets)   │     │  Registry    │     │  (model.pkl) │
└──────┬───────┘     └──────┬───────┘     └──────┬───────┘
       │                    │                    │
       └────────────────────┼────────────────────┘
                            │
                   ┌────────▼────────┐
                   │  Azure Container│
                   │   Instances     │
                   │  (FastAPI app)  │
                   └────────┬────────┘
                            │
                     POST /predict
```

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) (`az login`)
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- [Docker](https://docs.docker.com/get-docker/)
- Python 3.11+

## Quick Start

### 1. Provision base infrastructure (ACR, Storage, Key Vault)

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set prefix, container_image, api_key, subscription_id
# Keep deploy_aci = false (ACI will be deployed in step 5)
terraform init
terraform apply
```

Take note of the outputs:
- `acr_login_server` (e.g., `myprefix-acr.azurecr.io`)
- `acr_name` (e.g., `myprefixacr`)
- `key_vault_name` (e.g., `myprefix-kv`)
- `storage_account_name` (e.g., `myprefixsa`)
- `file_share_name` (e.g., `mlshare`)

### 2. Train the model

```bash
cd training
python -m venv .venv
# Windows: .venv\Scripts\activate
# Linux/Mac: source .venv/bin/activate
pip install -r requirements.txt
python train.py
```

This creates `artifacts/model.pkl` and `artifacts/metrics.json`.

### 3. Build and push Docker image to ACR

```bash
cd ..
docker build -t iris-api:1.0.0 .

az acr login --name <acr_name>
docker tag iris-api:1.0.0 <acr_login_server>/iris-api:1.0.0
docker push <acr_login_server>/iris-api:1.0.0
```

### 4. Upload model to Azure File Share

```powershell
.\scripts\upload_model_to_fileshare.ps1 `
  -KeyVaultName <key_vault_name> `
  -StorageAccountName <storage_account_name> `
  -FileShareName mlshare
```

### 5. Deploy ACI with the image

Now that the image is in ACR and the model is in the File Share, deploy the container:

```bash
cd infra
terraform apply -var="deploy_aci=true"
```

Note the output: `predict_url = http://<fqdn>:8000/predict`

> **Why two phases?** The ACI needs the Docker image in ACR and the model in the File Share to start correctly. By using `deploy_aci=false` (default) first, we create the base infrastructure, then deploy ACI only when everything is ready.

### 6. Test the API

```powershell
.\scripts\test_api.ps1 -PredictUrl <predict_url> -ApiKey <api_key>
```

Or with curl:

```bash
curl -X POST http://<fqdn>:8000/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{"sepal_length":5.1,"sepal_width":3.5,"petal_length":1.4,"petal_width":0.2}'
```

### 7. Clean up (avoid charges)

```bash
cd infra
terraform destroy
```

## Local Development

```bash
pip install -r api/requirements.txt
export MODEL_PATH=training/artifacts/model.pkl
export API_KEY=test123
uvicorn api.app:app --reload
```

## API Endpoints

| Method | Path      | Description                        |
|--------|-----------|------------------------------------|
| GET    | `/health` | Health check (model loaded status) |
| POST   | `/predict`| Iris classification (requires `X-API-Key` header) |
| GET    | `/docs`   | Swagger UI (interactive API docs)  |

## Estimated Azure Costs

| Resource              | Estimated Cost     |
|-----------------------|-------------------|
| Container Instances   | ~$25/month (1 vCPU, 1.5 GB) |
| Container Registry    | ~$5/month (Basic) |
| Storage Account       | < $1/month        |
| Key Vault             | < $1/month        |
| **Total**             | **~$30/month**    |

> **Tip:** Run `terraform destroy` when not using the resources to avoid charges.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `Model not loaded` (503) | Ensure model.pkl was uploaded to the file share |
| `Unauthorized` (401) | Check X-API-Key header matches the configured api_key |
| `terraform apply` fails | Verify `az login` is active and subscription_id is correct |
| Docker push fails | Run `az acr login --name <acr_name>` first |
| Training script fails | Ensure Python 3.11+ and requirements are installed |
