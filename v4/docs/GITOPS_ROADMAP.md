# Roadmap GitOps: Times de Desenvolvimento e ML

> Plano estruturado para implementar CI/CD completo com dois times trabalhando em paralelo.
> Criado em: 2024-02-04

## Visao Geral da Arquitetura Alvo

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              GITHUB REPOSITORY                               │
├─────────────────────┬───────────────────────┬───────────────────────────────┤
│   Java Team (PR)    │    ML Team (PR)       │     Infrastructure           │
│   apps/api-gateway/ │    ml/training/       │     infra/, k8s/             │
└─────────┬───────────┴───────────┬───────────┴───────────────┬───────────────┘
          │                       │                           │
          ▼                       ▼                           ▼
┌─────────────────────┐ ┌─────────────────────┐ ┌─────────────────────────────┐
│  CI: Build & Test   │ │ CI: Train & Validate│ │  CI: Terraform Plan         │
│  - Maven/Gradle     │ │ - Train model       │ │  - Security scan            │
│  - Unit tests       │ │ - Evaluate metrics  │ │  - Cost estimation          │
│  - Docker build     │ │ - Upload to MLflow  │ │                             │
│  - Push to ACR      │ │ - Push to Blob      │ │                             │
└─────────┬───────────┘ └─────────┬───────────┘ └─────────────┬───────────────┘
          │                       │                           │
          ▼                       ▼                           ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              ARGOCD (GitOps)                                 │
│  - Sync k8s manifests automatically                                         │
│  - Self-healing deployments                                                 │
│  - Rollback on failure                                                      │
└─────────────────────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           AZURE KUBERNETES SERVICE                           │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │  API Gateway    │  │Inference Service│  │  MLflow / Model Registry    │  │
│  │  (Java)         │──│  (Python)       │──│  - Model versioning         │  │
│  │                 │  │  + Init Container│  │  - Metrics tracking         │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Status Atual vs. Objetivo

| Componente | Status Atual | Objetivo | Gap |
|------------|--------------|----------|-----|
| **CI Java** | 90% | Build, test, push ACR | Falta: approval gates |
| **CI Python** | 90% | Build, test, push ACR | Falta: approval gates |
| **CD Deploy** | 70% | GitOps automatico | Falta: ArgoCD |
| **Model Training** | 10% | Pipeline automatizado | Falta: CI/CD completo |
| **Model Registry** | 0% | MLflow com versionamento | Nao existe |
| **Model Versioning** | 20% | Semver + metadata | Apenas ConfigMap |
| **Secrets Management** | 50% | External Secrets | Dev usa plaintext |
| **Observability** | 40% | Prometheus + Grafana | Terraform cria, nao wira |

---

## Roadmap de Implementacao

### FASE 1: Fundacao GitOps (Semana 1-2)
*Objetivo: Estabelecer deploy automatico para o time Java*

#### 1.1 Instalar ArgoCD no Cluster

**Arquivos a criar:**
```
v4/
├── k8s/
│   └── argocd/
│       ├── namespace.yaml
│       ├── install.yaml          # ArgoCD installation
│       ├── argocd-cm.yaml        # ConfigMap customizations
│       ├── applications/
│       │   ├── iris-dev.yaml     # Application para dev
│       │   └── iris-prod.yaml    # Application para prod
│       └── projects/
│           └── iris-project.yaml # AppProject com RBAC
```

**Workflow a criar:** `.github/workflows/argocd-setup.yml`

#### 1.2 Configurar Image Updater

O ArgoCD Image Updater monitora o ACR e atualiza automaticamente as tags de imagem.

**Fluxo resultante:**
```
Java Team PR merged → CI builds image → Push to ACR →
Image Updater detecta → Atualiza manifest → ArgoCD sync → Deploy
```

#### 1.3 Implementar Ingress Controller + TLS

**Arquivos a criar:**
```
v4/k8s/base/ingress/
├── kustomization.yaml
├── ingress-nginx-values.yaml
├── ingress.yaml              # Ingress rules
├── cluster-issuer.yaml       # Let's Encrypt
└── certificate.yaml          # TLS certificate
```

#### 1.4 Workflow de PR com Validacao

Adicionar ao CI:
- kubeval para validar manifests
- kube-score para best practices
- Security gate para bloquear vulnerabilidades criticas

#### Checklist Fase 1

- [ ] Instalar ArgoCD (`k8s/argocd/`)
- [ ] Criar ArgoCD Applications (`applications/*.yaml`)
- [ ] Configurar Image Updater (`image-updater/`)
- [ ] Instalar NGINX Ingress (`k8s/base/ingress/`)
- [ ] Configurar TLS (`certificate.yaml`)
- [ ] Adicionar kubeval ao CI (`ci-*.yml`)
- [ ] Testar fluxo Java PR → Deploy

---

### FASE 2: Pipeline de ML (Semana 3-4)
*Objetivo: Automatizar treinamento e versionamento de modelos*

#### 2.1 Implementar MLflow como Model Registry

**Arquivos a criar:**
```
v4/
├── k8s/base/mlflow/
│   ├── kustomization.yaml
│   ├── deployment.yaml       # MLflow server
│   ├── service.yaml
│   ├── pvc.yaml             # Persistent storage
│   └── ingress.yaml         # Acesso externo
├── ml/
│   └── training/
│       ├── train.py         # (modificar para MLflow)
│       ├── mlflow_config.py # Novo: config MLflow
│       └── evaluate.py      # Novo: metricas
```

#### 2.2 Criar Workflow de Treinamento

**Arquivo:** `.github/workflows/ml-training.yml`

Triggers:
- Push em `v4/ml/training/**`
- Schedule semanal (domingo 2am)
- Manual dispatch com parametros

Steps:
1. Train model
2. Evaluate metrics (accuracy threshold)
3. Register in MLflow
4. Upload to Azure Blob

#### 2.3 Desacoplar Modelo da Imagem Docker

Implementar Init Container para download do modelo do Blob Storage.

**Beneficio:** Novo modelo = atualizar ConfigMap → Pod restart → Download novo modelo (sem rebuild de imagem)

#### 2.4 Workflow de Promocao de Modelo

**Arquivo:** `.github/workflows/ml-promote.yml`

1. Deploy to staging
2. Run integration tests
3. Manual approval (environment protection)
4. Update prod ConfigMap
5. Trigger rollout

#### Checklist Fase 2

- [ ] Deploy MLflow no cluster (`k8s/base/mlflow/`)
- [ ] Modificar train.py para MLflow (`ml/training/train.py`)
- [ ] Criar workflow de training (`ml-training.yml`)
- [ ] Implementar init container (`deployment.yaml`)
- [ ] Criar workflow de promocao (`ml-promote.yml`)
- [ ] Configurar ambiente staging (`k8s/overlays/staging/`)
- [ ] Testar fluxo ML PR → Model update

---

### FASE 3: Observabilidade e Seguranca (Semana 5-6)
*Objetivo: Monitoramento, alertas e hardening de seguranca*

#### 3.1 Stack de Monitoramento

**Arquivos a criar:**
```
v4/k8s/base/monitoring/
├── prometheus/
├── grafana/
│   └── dashboards/
│       ├── iris-api.json
│       ├── iris-ml.json
│       └── kubernetes.json
└── alertmanager/
```

#### 3.2 Metricas de ML Especificas

Adicionar ao inference-service:
- `iris_predictions_total` (Counter por classe)
- `iris_prediction_latency_seconds` (Histogram)
- `iris_model_version` (Gauge)
- `iris_prediction_confidence` (Histogram)

#### 3.3 External Secrets Operator

Sincronizar secrets do Azure Key Vault automaticamente.

#### 3.4 Sealed Secrets para Dev

Substituir plaintext secrets por Sealed Secrets (criptografados no Git).

#### Checklist Fase 3

- [ ] Deploy Prometheus (`k8s/base/monitoring/prometheus/`)
- [ ] Deploy Grafana (`k8s/base/monitoring/grafana/`)
- [ ] Criar dashboards (`dashboards/*.json`)
- [ ] Adicionar metricas ML (`app.py`)
- [ ] Configurar alertas (`alertmanager/config.yaml`)
- [ ] Instalar External Secrets (`external-secrets/`)
- [ ] Migrar dev para Sealed Secrets

---

### FASE 4: Producao e Governanca (Semana 7-8)
*Objetivo: Approval gates, canary deployments, compliance*

#### 4.1 Environment Protection Rules

Configurar no GitHub:
- Required reviewers para production
- Wait timer: 5 minutes
- Deployment branches: `main` only

#### 4.2 Canary Deployments com Flagger

```
New image → 10% traffic → Monitor metrics →
OK? → 20% → ... → 100% |
FAIL? → Automatic rollback
```

#### 4.3 Policy as Code (OPA Gatekeeper)

Politicas:
- Require labels (team, version)
- Require probes
- Deny privileged containers
- Require resource limits

#### Checklist Fase 4

- [ ] Configurar Environment Protection (GitHub Settings)
- [ ] Instalar Flagger (`k8s/base/flagger/`)
- [ ] Criar Canary resources (`canary-*.yaml`)
- [ ] Instalar OPA Gatekeeper (`k8s/base/policies/`)
- [ ] Criar politicas de compliance (`constraints/`)
- [ ] Documentar processo de auditoria (`docs/COMPLIANCE.md`)

---

## Estrutura Final de Arquivos

```
v4/
├── .github/workflows/
│   ├── ci-api-gateway.yml       ✅ Existe (melhorar)
│   ├── ci-inference-service.yml ✅ Existe (melhorar)
│   ├── cd-deploy.yml            ✅ Existe (substituir por ArgoCD)
│   ├── infra-terraform.yml      ✅ Existe
│   ├── ml-training.yml          🆕 CRIAR
│   ├── ml-promote.yml           🆕 CRIAR
│   └── argocd-setup.yml         🆕 CRIAR
├── k8s/
│   ├── argocd/                  🆕 CRIAR
│   ├── base/
│   │   ├── common/              ✅ Existe
│   │   ├── api-gateway/         ✅ Existe
│   │   ├── inference-service/   ✅ Existe (modificar)
│   │   ├── ingress/             🆕 CRIAR
│   │   ├── mlflow/              🆕 CRIAR
│   │   ├── monitoring/          🆕 CRIAR
│   │   ├── external-secrets/    🆕 CRIAR
│   │   ├── flagger/             🆕 CRIAR
│   │   └── policies/            🆕 CRIAR
│   └── overlays/
│       ├── dev/                 ✅ Existe
│       ├── staging/             🆕 CRIAR
│       └── prod/                ✅ Existe
├── ml/training/
│   ├── train.py                 ✅ Existe (modificar)
│   ├── evaluate.py              🆕 CRIAR
│   └── mlflow_config.py         🆕 CRIAR
└── docs/
    ├── GITOPS_ROADMAP.md        ✅ Este arquivo
    ├── ML_PIPELINE.md           🆕 CRIAR
    └── COMPLIANCE.md            🆕 CRIAR
```

---

## Metricas de Sucesso

### Time Java
| Metrica | Atual | Meta |
|---------|-------|------|
| Tempo PR merge → Deploy | Manual | < 10 min |
| Rollback time | Manual | < 2 min (automatico) |
| Deploy frequency | Semanal | Diario |
| Failed deployments | ? | < 5% |

### Time ML
| Metrica | Atual | Meta |
|---------|-------|------|
| Tempo treino → Producao | Manual (dias) | < 4 horas |
| Model versions tracked | 0 | 100% |
| A/B test capability | Nao | Sim |
| Model rollback time | Manual | < 5 min |

---

## Proximos Passos

Para continuar a implementacao, pedir ao Claude:
1. "Implementar Fase 1.1 - ArgoCD"
2. "Implementar Fase 2.1 - MLflow"
3. Ou qualquer fase especifica do roadmap
