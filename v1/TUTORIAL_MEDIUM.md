# Como Treinar um Modelo de Machine Learning e Colocar na Azure (sem surtar no processo)

> Do Jupyter Notebook ao deploy em produção: o guia que eu queria ter lido antes de perder um final de semana inteiro tentando fazer isso sozinho.

---

Você treinou um modelo de Machine Learning no seu notebook, a acurácia ficou linda, você mostrou pro chefe, ele adorou e disse: *"Massa! Agora bota em produção até sexta."*

E aí veio aquele frio na barriga. Porque entre um `model.fit()` funcionando no seu Jupyter e uma API respondendo na nuvem, existe um abismo chamado **MLOps**.

Calma. Respira. Pega um cafe. Este tutorial vai te guiar por **todo o caminho** - do treinamento ao deploy - sem enrolação e sem precisar de PhD em DevOps.

**O que vamos construir:**

```
Treinar Modelo  -->  Criar API  -->  Docker  -->  Terraform  -->  Azure  -->  Profit!
  (scikit-learn)    (FastAPI)     (container)    (infra)      (nuvem)      ($$$?)
```

**A stack:**
- **Python + scikit-learn** - treinamento (o feijao com arroz do ML)
- **FastAPI** - API REST (rapida que nem o Usain Bolt dos frameworks)
- **Docker** - containerizacao (funciona na minha maquina E na sua)
- **Terraform** - infraestrutura como codigo (chega de clicar no portal do Azure feito louco)
- **Azure** (ACR + ACI + Storage + Key Vault) - a nuvem onde tudo vai morar

**Repositorio completo:** [github.com/vibola1980/iris-azure-ml](https://github.com/vibola1980/iris-azure-ml) (pasta `v1/`)

> *"Talk is cheap. Show me the code."* - Linus Torvalds (e provavelmente seu tech lead tambem)

---

## A Arquitetura (ou: o mapa do tesouro)

Antes de sair codando, vamos entender o que vamos montar. Pense assim: voce tem um bolo (o modelo), precisa de uma vitrine (a API), um caminhao (o Docker), e uma loja (a Azure) pra vender ele.

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Azure Key   │     │   Azure      │     │   Azure      │
│   Vault      │     │  Container   │     │  File Share  │
│  (o cofre)   │     │  Registry    │     │  (o modelo)  │
└──────┬───────┘     └──────┬───────┘     └──────┬───────┘
       │                    │                    │
       └────────────────────┼────────────────────┘
                            │
                   ┌────────▼────────┐
                   │  Azure Container│
                   │   Instances     │
                   │  (a vitrine!)   │
                   └────────┬────────┘
                            │
                     POST /predict
                   "Ei Azure, que flor e essa?"
```

- **Container Registry (ACR)**: o "Docker Hub privado" - guarda sua imagem Docker
- **Container Instances (ACI)**: roda seu container na nuvem (e um `docker run` so que chique)
- **Storage + File Share**: HD na nuvem onde fica o `model.pkl`
- **Key Vault**: o cofre das senhas (porque hardcoded nao, ne?)

**Por que essa arquitetura?** Porque e a forma mais simples e barata de colocar ML em producao na Azure. Sem Kubernetes (calma, a gente chega la), sem VMs, sem dor de cabeca. So um container, feliz, rodando sua API.

---

## Pre-requisitos (a lista de compras)

Instale essas ferramentas. Prometo que e a parte mais chata - depois so melhora:

1. **Python 3.11+** - [python.org](https://www.python.org/downloads/) (se voce ta lendo isso, provavelmente ja tem)
2. **Docker Desktop** - [docker.com](https://www.docker.com/products/docker-desktop/) (o canivete suico do deploy)
3. **Azure CLI** - [docs.microsoft.com](https://learn.microsoft.com/cli/azure/install-azure-cli) (pra conversar com a Azure sem mouse)
4. **Terraform** - [terraform.io](https://developer.hashicorp.com/terraform/install) (infra as code = paz de espirito)
5. **Uma conta Azure** - [portal.azure.com](https://portal.azure.com) (conta gratuita funciona! Sim, de graca!)

Depois de instalar o Azure CLI:

```bash
az login
# Abre o browser, voce faz login, e voila - Azure desbloqueada!
```

---

## Passo 1: Treinar o Modelo (a parte que voce ja sabe fazer)

Vamos usar o dataset Iris - o "Hello World" do Machine Learning. Sao 150 amostras de 3 especies de flores, com 4 medidas cada:

| Medida | O que e |
|---|---|
| sepal_length | Comprimento da sepala (cm) |
| sepal_width | Largura da sepala (cm) |
| petal_length | Comprimento da petala (cm) |
| petal_width | Largura da petala (cm) |

**Especies:** Setosa (a pequeninha), Versicolor (a do meio), Virginica (a grandona).

> *"Mas por que flores?"* Porque o dataset e simples, limpo, e perfeito pra focar no deploy em vez de ficar 3 horas limpando dados. O conceito e o mesmo se voce tiver prevendo churn de clientes ou classificando gatinhos.

### O script de treinamento

Crie `training/train.py`:

```python
import json
import os
import joblib
import numpy as np

from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import accuracy_score, classification_report

from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC
from sklearn.ensemble import RandomForestClassifier


def main():
    # Carrega o dataset Iris (150 amostras, 3 classes, 4 features)
    iris = load_iris()
    X = iris.data
    y = iris.target

    # 80% treino, 20% teste - stratify mantem a proporcao das classes
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    # Pipeline: primeiro normaliza, depois classifica
    # StandardScaler e crucial pro SVM e Logistic Regression
    # (imagina comparar metros com centimetros sem normalizar... ia dar ruim)
    pipe = Pipeline([
        ("scaler", StandardScaler()),
        ("clf", LogisticRegression(max_iter=2000))
    ])

    # O GridSearchCV e tipo um estagiario muito dedicado:
    # testa TODAS as combinacoes e te entrega a melhor
    param_grid = [
        {
            "clf": [LogisticRegression(max_iter=2000)],
            "clf__C": [0.1, 1.0, 10.0],
            "clf__solver": ["lbfgs"],
        },
        {
            "clf": [SVC(probability=True)],
            "clf__C": [0.1, 1.0, 10.0],
            "clf__kernel": ["rbf", "linear"],
            "clf__gamma": ["scale", "auto"],
        },
        {
            "clf": [RandomForestClassifier(random_state=42)],
            "clf__n_estimators": [50, 150, 300],
            "clf__max_depth": [None, 3, 5],
            "clf__min_samples_split": [2, 5],
        }
    ]

    search = GridSearchCV(
        estimator=pipe,
        param_grid=param_grid,
        scoring="accuracy",
        cv=5,          # 5-fold cross-validation (robusto!)
        n_jobs=-1,     # usa todos os cores (bora com tudo!)
        verbose=1,
    )

    search.fit(X_train, y_train)

    best_model = search.best_estimator_
    y_pred = best_model.predict(X_test)

    acc = accuracy_score(y_test, y_pred)

    # Salva tudo em artifacts/
    os.makedirs("artifacts", exist_ok=True)

    joblib.dump(
        {
            "model": best_model,
            "target_names": iris.target_names.tolist(),
            "feature_names": iris.feature_names,
        },
        "artifacts/model.pkl",
    )

    print(f"Best model: {best_model.named_steps['clf'].__class__.__name__}")
    print(f"Best CV score: {search.best_score_:.4f}")
    print(f"Test accuracy: {acc:.4f}")


if __name__ == "__main__":
    main()
```

### Hora de treinar!

```bash
cd training
pip install scikit-learn joblib numpy
python train.py
```

**Saida esperada:**

```
Fitting 5 folds for each of 33 candidates, totalling 165 fits
Best model: SVC
Best CV score: 0.9750
Test accuracy: 0.9333
```

97.5% de acuracia! O modelo ta praticamente formado em botanica.

Isso gera o arquivo `artifacts/model.pkl` - o cerebro do nosso sistema, serializado e pronto pra trabalhar.

> **O que aconteceu nos bastidores?** O GridSearchCV testou 33 combinacoes de 3 algoritmos diferentes (Logistic Regression, SVM e Random Forest) com varios hiperparametros, fazendo validacao cruzada de 5 folds em cada. Tipo um reality show: 33 candidatos entraram, so o melhor saiu vivo.

---

## Passo 2: Criar a API com FastAPI (a vitrine do modelo)

Modelo treinado. Agora precisamos de uma forma de alguem perguntar *"ei, que flor e essa?"* e receber uma resposta. Enter: **FastAPI**.

### `api/app.py`

```python
import logging
import os

import joblib
import numpy as np
from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel, Field

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

MODEL_PATH = os.getenv("MODEL_PATH", "model.pkl")
API_KEY = os.getenv("API_KEY", "")

app = FastAPI(title="Iris Classifier API", version="1.0.0")

_model_bundle = None


class PredictRequest(BaseModel):
    sepal_length: float = Field(..., example=5.1)
    sepal_width: float = Field(..., example=3.5)
    petal_length: float = Field(..., example=1.4)
    petal_width: float = Field(..., example=0.2)


def load_model():
    global _model_bundle
    if _model_bundle is None:
        if not os.path.exists(MODEL_PATH):
            logger.error("Model file not found: %s", MODEL_PATH)
            return None
        try:
            bundle = joblib.load(MODEL_PATH)
            if "model" not in bundle or "target_names" not in bundle:
                logger.error("Invalid model bundle: missing required keys")
                return None
            _model_bundle = bundle
            logger.info("Model loaded successfully from %s", MODEL_PATH)
        except Exception as e:
            logger.error("Failed to load model: %s", e)
            return None
    return _model_bundle


@app.get("/health")
def health():
    bundle = load_model()
    return {
        "status": "ok",
        "model_loaded": bundle is not None,
        "model_path": MODEL_PATH,
    }


@app.post("/predict")
def predict(payload: PredictRequest, x_api_key: str | None = Header(default=None)):
    if API_KEY and x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Unauthorized")

    bundle = load_model()
    if bundle is None:
        raise HTTPException(
            status_code=503,
            detail="Model not loaded. Check MODEL_PATH configuration.",
        )

    model = bundle["model"]
    target_names = bundle["target_names"]

    X = np.array([[
        payload.sepal_length,
        payload.sepal_width,
        payload.petal_length,
        payload.petal_width,
    ]])
    pred = int(model.predict(X)[0])
    proba = model.predict_proba(X)[0].tolist() if hasattr(model, "predict_proba") else None

    logger.info("Prediction: %s (class %d)", target_names[pred], pred)
    return {
        "predicted_class_id": pred,
        "predicted_class_name": target_names[pred],
        "probabilities": proba,
    }
```

**Destaques do codigo (pra voce brilhar na code review):**
- **Logging** - porque `print("deu ruim")` nao escala
- **Validacao do model bundle** - se o arquivo estiver corrompido, voce sabe ANTES de dar 500
- **API Key via header** - seguranca basica (ninguem quer um bot minerando previsoes de flores de graca)
- **Cache do modelo** - carrega uma vez, usa pra sempre (lazy loading FTW)

### Testando localmente

```bash
pip install fastapi uvicorn scikit-learn joblib numpy

export MODEL_PATH=training/artifacts/model.pkl
export API_KEY=test123

uvicorn api.app:app --reload
```

Abra http://localhost:8000/docs e prepare-se pra ficar impressionado. O FastAPI gera um Swagger UI automatico. De graca. Sem voce fazer nada.

Teste com curl:

```bash
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: test123" \
  -d '{"sepal_length":5.1,"sepal_width":3.5,"petal_length":1.4,"petal_width":0.2}'
```

**Resposta:**

```json
{
  "predicted_class_id": 0,
  "predicted_class_name": "setosa",
  "probabilities": [0.97, 0.02, 0.01]
}
```

97% de certeza que e uma Setosa. O modelo ta confiante. Eu nunca estou tao confiante assim nem pra pedir comida no iFood.

---

## Passo 3: Containerizar com Docker (o "funciona na minha maquina" killer)

Agora vamos empacotar tudo num container Docker. Porque "funciona no meu computador" nao e argumento valido em producao.

### Dockerfile

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY api/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY api/app.py /app/app.py

# Seguranca: NUNCA rode containers como root
# (e tipo dar a chave de casa pro entregador do iFood)
RUN adduser --disabled-password --no-create-home appuser
USER appuser

EXPOSE 8000
CMD ["uvicorn", "app:app", "--host=0.0.0.0", "--port=8000"]
```

**Por que essas escolhas?**
- `python:3.11-slim` - imagem de ~150MB (a versao completa tem ~900MB... ninguem merece)
- `requirements.txt` primeiro - Docker cacheia essa layer, entao se so mudar o `app.py`, nao reinstala tudo
- `adduser` + `USER appuser` - rodar como root dentro de container e pedir pra ter problema
- `--no-cache-dir` - pip nao precisa guardar cache dentro do container

### Build e teste

```bash
docker build -t iris-api:1.0.0 .

docker run -p 8000:8000 \
  -v $(pwd)/training/artifacts:/mnt/model \
  -e MODEL_PATH=/mnt/model/model.pkl \
  -e API_KEY=test123 \
  iris-api:1.0.0
```

Se tudo deu certo, voce tem uma API rodando dentro de um container. Parabens, voce ja e mais DevOps que 80% dos data scientists. (brincadeira... ou nao)

---

## Passo 4: Infraestrutura na Azure com Terraform (o melhor amigo do preguicoso produtivo)

Aqui e onde a magica acontece. Em vez de clicar em 47 telas do portal Azure, vamos descrever TODA a infraestrutura em codigo e deixar o Terraform criar tudo pra gente.

> *"Infraestrutura como codigo e tipo uma receita de bolo. Voce escreve uma vez e qualquer pessoa consegue reproduzir."*

### Estrutura

```
infra/
├── main.tf                  # Os recursos Azure (o bolo)
├── variables.tf             # Variaveis de config (os ingredientes)
├── outputs.tf               # O que queremos saber no final (o sabor)
└── terraform.tfvars.example # Exemplo (a receita de referencia)
```

### main.tf (versao resumida e comentada)

```hcl
# Grupo de recursos - a "pasta" que contem tudo na Azure
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

# Storage Account + File Share - o "HD na nuvem" pro model.pkl
resource "azurerm_storage_account" "sa" {
  name                     = lower(replace("${var.prefix}sa", "-", ""))
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"  # Local Redundant (mais barato)
}

resource "azurerm_storage_share" "share" {
  name               = "mlshare"
  storage_account_id = azurerm_storage_account.sa.id
  quota              = 1  # 1 GB - pro scikit-learn, e tipo alugar uma mansao pra um hamster
}

# Key Vault - o cofre dos segredos (literalmente)
resource "azurerm_key_vault" "kv" {
  name                = "${var.prefix}-kv"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  # ... access policies (quem pode abrir o cofre)
}

# Container Registry - o "Docker Hub" privado na Azure
resource "azurerm_container_registry" "acr" {
  name                = lower(replace("${var.prefix}acr", "-", ""))
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Container Instance - AQUI roda a API de verdade!
# count = so cria quando deploy_aci = true (evita erro no primeiro apply)
resource "azurerm_container_group" "aci" {
  count               = var.deploy_aci ? 1 : 0
  name                = "${var.prefix}-aci"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"

  container {
    name   = "iris-api"
    image  = "${azurerm_container_registry.acr.login_server}/${var.container_image}"
    cpu    = 1
    memory = 1.5

    ports {
      port     = 8000
      protocol = "TCP"
    }

    # O modelo e montado como volume - o container le direto do File Share
    environment_variables = {
      MODEL_PATH = "/mnt/model/model.pkl"
    }

    secure_environment_variables = {
      API_KEY = var.api_key  # Chega de senha no codigo, pelo amor!
    }

    volume {
      name                 = "modelshare"
      mount_path           = "/mnt/model"
      storage_account_name = azurerm_storage_account.sa.name
      storage_account_key  = azurerm_storage_account.sa.primary_access_key
      share_name           = azurerm_storage_share.share.name
    }
  }
}
```

### variables.tf (as variaveis de entrada)

Sem este arquivo o Terraform nao sabe o que significam `var.prefix`, `var.api_key` e cia. E tipo tentar fazer um bolo sem lista de ingredientes.

```hcl
variable "prefix" {
  type        = string
  description = "Short unique prefix for resource naming (e.g., irisml01)."
}

variable "location" {
  type        = string
  description = "Azure region (e.g., eastus)."
  default     = "eastus"
}

variable "container_image" {
  type        = string
  description = "Docker image in ACR (e.g., iris-api:1.0.0, without the server URL)."
}

variable "api_key" {
  type        = string
  description = "API key to protect the prediction endpoint."
  sensitive   = true
}

variable "tags" {
  type    = map(string)
  default = { project = "iris-ml" }
}

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID where resources will be created."
}

variable "deploy_aci" {
  type        = bool
  description = "Set to true to deploy the ACI container (requires image in ACR and model in File Share)."
  default     = false
}
```

> **Nota:** `sensitive = true` na `api_key` faz o Terraform esconder o valor nos logs. Seguranca ate nos detalhes.

### outputs.tf (o que voce quer saber no final)

```hcl
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "aci_fqdn" {
  value = var.deploy_aci ? azurerm_container_group.aci[0].fqdn : "(ACI not deployed yet)"
}

output "predict_url" {
  value = var.deploy_aci ? "http://${azurerm_container_group.aci[0].fqdn}:8000/predict" : "(deploy with -var=deploy_aci=true after pushing image and model)"
}
```

Note como os outputs do ACI usam condicional - se `deploy_aci` e `false`, em vez de dar erro ele mostra uma mensagem amigavel. Terraform elegante e Terraform feliz.

### Configurar e aplicar

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
```

Edite o `terraform.tfvars`:

```hcl
prefix          = "irisml01"          # Prefixo unico (tipo seu username)
location        = "eastus"            # Regiao Azure (eastus e mais barato)
container_image = "iris-api:1.0.0"    # Nome da imagem (sem o servidor ACR)
api_key         = "sua-chave-secreta" # Invente uma boa! (nao use "123456")
subscription_id = "seu-subscription-id"
deploy_aci      = false               # Nao mexa nisso agora! Vamos ativar no Passo 5
```

> **Dica:** Pra encontrar o subscription_id: `az account show --query id -o tsv`

```bash
terraform init    # Baixa os plugins necessarios
terraform apply   # Cria a infra BASE (ACR, Storage, Key Vault)
```

O Terraform vai mostrar um plano com os recursos base. Note que o ACI **ainda nao sera criado** (`deploy_aci = false`). Isso e proposital - o ACI precisa da imagem Docker e do modelo pra funcionar. Digite `yes` e va pegar um cafe.

> **"Mas por que nao cria tudo de uma vez?"** Porque o ACI tenta baixar a imagem do ACR no momento que e criado. Se a imagem nao existe ainda... boom, erro. Separar em duas fases evita essa dor de cabeca.

**Outputs que voce vai precisar:**

```
acr_login_server     = "irisml01acr.azurecr.io"
acr_name             = "irisml01acr"
key_vault_name       = "irisml01-kv"
storage_account_name = "irisml01sa"
predict_url          = "(deploy with -var=deploy_aci=true after pushing image and model)"
```

Guarde esses valores como se fossem senhas do Wi-Fi.

---

## Passo 5: Deploy (a hora da verdade!)

Tudo criado na Azure. Agora vamos enviar nosso container e modelo pra la.

### Push da imagem pro ACR

```bash
# Login no SEU Container Registry
az acr login --name irisml01acr

# Tag e push (tipo git push, mas pra Docker)
docker tag iris-api:1.0.0 irisml01acr.azurecr.io/iris-api:1.0.0
docker push irisml01acr.azurecr.io/iris-api:1.0.0
```

### Upload do modelo pro File Share

**Windows (PowerShell):**

```powershell
.\scripts\upload_model_to_fileshare.ps1 `
  -KeyVaultName "irisml01-kv" `
  -StorageAccountName "irisml01sa" `
  -FileShareName "mlshare"
```

**Linux / Mac (Bash):**

```bash
# Busca a chave do Storage Account no Key Vault
SA_KEY=$(az keyvault secret show \
  --vault-name "irisml01-kv" \
  --name "storage-account-key" \
  --query value -o tsv)

# Faz upload do modelo pro File Share
az storage file upload \
  --account-name "irisml01sa" \
  --account-key "$SA_KEY" \
  --share-name "mlshare" \
  --source "training/artifacts/model.pkl" \
  --path "model.pkl"

echo "Upload complete: model.pkl"
```

> **Dica pra quem usa Linux/Mac:** os comandos `az` sao identicos - a unica diferenca e trocar PowerShell por Bash. O Azure CLI e multiplataforma, entao funciona igual nos dois mundos.

### Agora sim: subir o ACI!

Imagem no ACR, modelo no File Share. Agora podemos ligar o motor:

```bash
cd infra
terraform apply -var="deploy_aci=true"
```

Agora o ACI vai puxar a imagem do ACR e montar o File Share com o modelo. Em ~2 minutos sua API estara respondendo na nuvem!

> *Esse momento em que o `terraform apply` termina sem erro... e quase tao bom quanto um `npm install` sem vulnerabilidades.*

---

## Passo 6: Testar a API em Producao (o momento "funciona!")

A API ta no ar. Vamos provar que funciona com as 3 especies:

```bash
# Health check (ta vivo?)
curl http://irisml01-iris.eastus.azurecontainer.io:8000/health

# Setosa (a florzinha pequena e delicada)
curl -X POST http://irisml01-iris.eastus.azurecontainer.io:8000/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: sua-chave-secreta" \
  -d '{"sepal_length":5.1,"sepal_width":3.5,"petal_length":1.4,"petal_width":0.2}'
# Resultado: "setosa" com 97% de certeza

# Versicolor (a flor do meio-termo)
curl -X POST http://irisml01-iris.eastus.azurecontainer.io:8000/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: sua-chave-secreta" \
  -d '{"sepal_length":7.0,"sepal_width":3.2,"petal_length":4.7,"petal_width":1.4}'
# Resultado: "versicolor" com 86% de certeza

# Virginica (a grandalona)
curl -X POST http://irisml01-iris.eastus.azurecontainer.io:8000/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: sua-chave-secreta" \
  -d '{"sepal_length":6.3,"sepal_width":3.3,"petal_length":6.0,"petal_width":2.5}'
# Resultado: "virginica" com 99% de certeza
```

Se chegou aqui e tudo funcionou: parabens! Voce acaba de fazer deploy de um modelo de ML na nuvem. Pode colocar "MLOps" no LinkedIn. (brincadeira... mas pode sim)

---

## Passo 7: Limpeza - NAO PULE ESTE PASSO!

Serio. Eu sei que voce ta empolgado, mas se voce nao destruir os recursos, a Azure vai te cobrar. E nao aceita "esqueci" como desculpa.

```bash
cd infra
terraform destroy
```

**Quanto custa se voce esquecer?**

| Recurso | Custo/mes |
|---|---|
| Container Instances (1 vCPU, 1.5 GB) | ~R$ 125 |
| Container Registry (Basic) | ~R$ 25 |
| Storage + Key Vault | ~R$ 5 |
| **Total** | **~R$ 150/mes** |

> *Ja vi gente deixar recursos ligados por 3 meses sem perceber. Deu R$ 450 de susto na fatura. Nao seja essa pessoa. Rode o `terraform destroy`.*

---

## O Mapa Completo (recap da arquitetura)

```
┌─────────────────────────────────────────────────────────────────┐
│                        AZURE SUBSCRIPTION                        │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              RESOURCE GROUP                                 │ │
│  │                                                             │ │
│  │  Container Registry ──pull──> Container Instance (ACI)     │ │
│  │  (imagem Docker)              |── FastAPI (porta 8000)     │ │
│  │                               |── MODEL_PATH=/mnt/model/   │ │
│  │  Storage + File Share ──mount──    model.pkl               │ │
│  │  (model.pkl)                                                │ │
│  │                                                             │ │
│  │  Key Vault ──secrets──> ACI (API_KEY como env var segura)  │ │
│  │                                                             │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## O que voce aprendeu (e pode contar na entrevista)

1. **Treinar um modelo ML** com GridSearchCV e Pipeline do scikit-learn
2. **Serializar o modelo** com joblib (o `pickle` que funciona com numpy)
3. **Criar uma API REST** com FastAPI (com auth, logging e validacao)
4. **Containerizar** com Docker (imagem slim, usuario non-root)
5. **Infraestrutura como Codigo** com Terraform (reproducivel e versionavel)
6. **Deploy na Azure** usando ACR + ACI + File Share
7. **Gerenciar secrets** com Key Vault (chega de `.env` commitado no Git)

---

## Proximos Passos (pro seu eu do futuro)

Este tutorial cobre o MVP. Em projetos reais, voce vai querer:

- **CI/CD** - GitHub Actions pra automatizar tudo a cada `git push`
- **Monitoramento** - Application Insights pra saber quando algo der errado (e vai dar)
- **Versionamento de modelos** - MLflow pra rastrear experimentos e nao perder aquele modelo "que tava bom"
- **HTTPS** - Porque HTTP em 2026 e tipo usar cadeado de bicicleta num cofre
- **Auto-scaling** - Kubernetes (AKS) quando uma instancia nao for o suficiente

> Este projeto faz parte de uma serie evolutiva. A v1 (este tutorial) foca na simplicidade. As versoes v2, v3 e v4 vao adicionando progressivamente: model registry, microservicos (Java + Python), e deploy enterprise com AKS + ArgoCD. Mas isso fica pro proximo episodio...

---

## Repositorio

Todo o codigo esta no GitHub: [github.com/vibola1980/iris-azure-ml](https://github.com/vibola1980/iris-azure-ml)

A pasta `v1/` tem tudo que vimos aqui. Clone, fork, estude, quebre, conserte. E assim que a gente aprende.

---

*Se este tutorial te ajudou a finalmente sair do notebook pro mundo real, deixa um like e compartilha com aquele colega que ainda ta rodando modelo no Jupyter em producao (a gente conhece pelo menos um). Qualquer duvida, comenta ai que eu respondo!*
