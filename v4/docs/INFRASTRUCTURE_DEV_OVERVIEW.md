# Infraestrutura DEV - Visao Geral (Explain Like I'm Five)

> Documento que explica de forma simples todos os componentes provisionados no ambiente de desenvolvimento do projeto Iris ML v4.

---

## Diagrama da Infraestrutura DEV

```
                                    AZURE CLOUD
    +---------------------------------------------------------------------------------+
    |                                                                                 |
    |   RESOURCE GROUP (rg-iris-dev)                                                  |
    |   "Uma pasta que guarda tudo organizado"                                        |
    |                                                                                 |
    |   +-------------------------------------------------------------------------+   |
    |   |  NETWORKING (Rede Virtual)                                              |   |
    |   |  +-------------------------+    +-------------------------+             |   |
    |   |  |  AKS Subnet             |    |  Private Endpoints      |             |   |
    |   |  |  10.1.0.0/20            |    |  Subnet 10.1.16.0/24    |             |   |
    |   |  |  "Rua do Kubernetes"    |    |  "Rua dos Segredos"     |             |   |
    |   |  +-------------------------+    +-------------------------+             |   |
    |   +-------------------------------------------------------------------------+   |
    |                                                                                 |
    |   +------------------+  +------------------+  +----------------------------+    |
    |   | ACR              |  | STORAGE          |  | KEY VAULT                  |    |
    |   | (Container       |  | (Armazenamento)  |  | (Cofre de Segredos)        |    |
    |   |  Registry)       |  |                  |  |                            |    |
    |   |                  |  | Guarda o         |  | Guarda:                    |    |
    |   | Guarda as        |  | modelo.pkl       |  | - api-key                  |    |
    |   | "fotos" dos      |  | (cerebro do ML)  |  | - storage-access-key       |    |
    |   | containers       |  |                  |  |                            |    |
    |   +--------+---------+  +--------+---------+  +-------------+--------------+    |
    |            |                     |                          |                   |
    |            +---------------------+--------------------------+                   |
    |                                  |                                              |
    |                                  v                                              |
    |   +-------------------------------------------------------------------------+   |
    |   |  AKS CLUSTER (Kubernetes)                                               |   |
    |   |  "O maestro que orquestra tudo"                                         |   |
    |   |                                                                         |   |
    |   |   +---------------+    +---------------+                                |   |
    |   |   | Node 1        |    | Node 2        |  (auto-escala de 1 a 2)        |   |
    |   |   | (VM D2s_v3)   |    | (VM D2s_v3)   |                                |   |
    |   |   |               |    |               |                                |   |
    |   |   | +-----------+ |    | +-----------+ |                                |   |
    |   |   | | Java API  | |    | | Python ML | |                                |   |
    |   |   | | :8080     | |    | | :5000     | |                                |   |
    |   |   | +-----------+ |    | +-----------+ |                                |   |
    |   |   +---------------+    +---------------+                                |   |
    |   +-------------------------------------------------------------------------+   |
    |                                                                                 |
    |   +-------------------------------------------------------------------------+   |
    |   |  MONITORING (Log Analytics + App Insights)                              |   |
    |   |  "O detetive que observa tudo e anota"                                  |   |
    |   +-------------------------------------------------------------------------+   |
    |                                                                                 |
    +---------------------------------------------------------------------------------+
```

---

## Explicacao dos Componentes

### 1. Resource Group (`rg-iris-dev`)

> **"Uma caixa de brinquedos onde guardamos tudo junto"**

Imagina que voce tem uma caixa grande onde guarda todos os brinquedos de um tema so. O Resource Group e exatamente isso - uma "pasta" no Azure que mantem todos os recursos do projeto juntos. Se voce quiser apagar tudo, e so deletar a caixa!

---

### 2. Networking (Rede Virtual)

> **"As ruas e avenidas onde os dados transitam"**

Pensa numa cidade com ruas. Os dados precisam de "ruas" para ir de um lugar para outro. Criamos duas "ruas" (subnets):

| Subnet | Endereco | Para que serve |
|--------|----------|----------------|
| **AKS Subnet** | `10.1.0.0/20` | Rua onde o Kubernetes mora |
| **Private Endpoints** | `10.1.16.0/24` | Rua secreta para acessar cofres e storage |

---

### 3. ACR - Azure Container Registry

> **"O album de fotos dos nossos programas"**

Quando voce tira uma foto, guarda num album, certo? O ACR e o "album" onde guardamos as "fotos" (imagens Docker) dos nossos programas. Quando o Kubernetes quer rodar o programa Java ou Python, ele pega a "foto" do ACR e cria uma copia rodando.

**Configuracao DEV:**
- SKU: Standard (tamanho medio)
- Admin habilitado (facilita testes)

---

### 4. Storage Account

> **"O HD externo na nuvem"**

E como um pendrive gigante na nuvem. Aqui guardamos o **modelo.pkl** - o "cerebro" treinado do Machine Learning que sabe classificar flores Iris.

**Configuracao DEV:**
- Tipo: Standard
- Replicacao: LRS (so uma copia - mais barato)
- Versionamento: Ativo (guarda versoes antigas)

---

### 5. Key Vault

> **"O cofre do banco onde guardamos senhas"**

Imagina um cofre de banco super seguro. O Key Vault guarda as "senhas" (secrets) do projeto:

| Secret | O que e |
|--------|---------|
| `api-key` | Senha para usar nossa API |
| `storage-access-key` | Senha para acessar o Storage |

**Configuracao DEV:**
- Pode ser apagado (purge permitido)
- 7 dias de "lixeira" antes de apagar de vez

---

### 6. AKS - Azure Kubernetes Service

> **"O maestro que rege a orquestra de containers"**

O Kubernetes e como um maestro de orquestra. Ele decide:
- Quantos "musicos" (containers) precisam tocar
- Se um "musico" ficar doente, substitui por outro
- Distribui o trabalho entre todos

**Configuracao DEV:**

| Parametro | Valor | Explicacao |
|-----------|-------|------------|
| Versao | 1.32 | Versao do Kubernetes |
| VM | Standard_D2s_v3 | Tipo de computador (2 CPUs, 8GB RAM) |
| Nodes | 1-2 | Minimo 1, maximo 2 computadores |
| Auto-scaling | Sim | Aumenta/diminui automaticamente |
| Node pool ML | Nao | Sem GPUs extras (e so dev) |

---

### 7. Monitoring (Log Analytics + Application Insights)

> **"O detetive que anota tudo que acontece"**

E como uma camera de seguranca + um caderno de anotacoes. Registra:
- Quem acessou a API
- Erros que aconteceram
- Quanto de CPU/memoria esta usando
- Logs de todos os programas

**Configuracao DEV:**
- Retencao: 30 dias (guarda logs por 1 mes)
- Alertas: Desabilitados (nao manda email quando algo da errado)

---

### 8. RBAC - Permissoes

> **"Os crachas de acesso para cada funcionario"**

Definimos "quem pode fazer o que":

| Quem | Acessa o que | Permissao |
|------|--------------|-----------|
| Terraform (voce) | Key Vault | Secrets Officer (criar/editar segredos) |
| AKS | Key Vault | Secrets User (so ler segredos) |
| AKS | Storage | Blob Data Reader (so ler arquivos) |
| AKS | ACR | AcrPull (baixar imagens Docker) |

---

## Fluxo Simplificado

```
   Usuario faz request
          |
          v
   +--------------+      +--------------+
   |  Java API    | ---> |  Python ML   |
   |  (porta 8080)|      |  (porta 5000)|
   +--------------+      +------+-------+
                                |
                                v
                         +--------------+
                         |  model.pkl   |
                         |  (Storage)   |
                         +--------------+
                                |
                                v
                         "E uma Iris Setosa!"
```

---

## Custo Estimado (DEV)

| Recurso | Custo mensal aproximado |
|---------|-------------------------|
| AKS (1 node D2s_v3) | ~$70-100 |
| ACR Standard | ~$5 |
| Storage LRS | ~$1-2 |
| Key Vault | ~$0.03/operacao |
| Log Analytics | ~$2-5 |
| **Total DEV** | **~$80-120/mes** |

---

## Arquivos Relacionados

| Arquivo | Descricao |
|---------|-----------|
| `v4/infra/environments/dev/main.tf` | Configuracao Terraform do ambiente DEV |
| `v4/infra/modules/` | Modulos reutilizaveis (aks, acr, storage, etc.) |
| `v4/k8s/overlays/dev/` | Manifests Kubernetes para DEV |
| `v4/docs/ARCHITECTURE.md` | Arquitetura detalhada do sistema |
| `v4/docs/RUNBOOK.md` | Guia de operacoes |

---

## Comandos Uteis

```bash
# Provisionar infraestrutura DEV
cd v4/infra/environments/dev
terraform init
terraform plan -var="api_key=sua-chave"
terraform apply -var="api_key=sua-chave"

# Ver recursos criados
terraform output

# Conectar ao AKS
az aks get-credentials --resource-group rg-iris-dev --name aks-iris-dev

# Verificar pods
kubectl get pods -n iris-ml

# Destruir tudo (cuidado!)
terraform destroy -var="api_key=sua-chave"
```

---

> **Documento criado em:** Fevereiro/2025
> **Ultima atualizacao:** Fevereiro/2025
