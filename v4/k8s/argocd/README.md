# ArgoCD - GitOps para Iris ML

Este diretorio contem os manifests para instalar e configurar o ArgoCD no cluster AKS.

## Arquitetura

```
GitHub (vibola1980/iris-azure-ml)
         |
         | webhook / polling (3 min)
         v
+------------------+
|     ArgoCD       |
|                  |
|  - Detecta       |
|    mudancas      |
|  - Aplica no     |
|    cluster       |
|  - Auto-healing  |
+--------+---------+
         |
         v
+------------------+
|   AKS Cluster    |
|                  |
|  namespace:      |
|  - iris-ml (dev) |
|  - iris-ml-prod  |
+------------------+
```

## Pre-requisitos

- Cluster AKS rodando
- `kubectl` configurado para o cluster
- Acesso ao namespace `argocd`

## Instalacao

### 1. Aplicar os manifests

```bash
# Conectar ao cluster AKS
az aks get-credentials --resource-group rg-iris-dev --name aks-iris-dev

# Instalar ArgoCD via Kustomize
kubectl apply -k v4/k8s/argocd/
```

### 2. Aguardar pods ficarem prontos

```bash
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s
```

### 3. Obter senha inicial do admin

```bash
# A senha inicial e o nome do pod do argocd-server
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 4. Acessar a UI

```bash
# Opcao 1: Port-forward (desenvolvimento)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Acessar: https://localhost:8080
# Usuario: admin
# Senha: (obtida no passo 3)

# Opcao 2: LoadBalancer (se habilitado)
kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

## Estrutura de Arquivos

```
argocd/
├── kustomization.yaml      # Kustomize principal
├── namespace.yaml          # Namespace argocd
├── argocd-cm.yaml          # ConfigMaps de configuracao
├── applications/
│   ├── iris-dev.yaml       # App DEV (sync automatico)
│   └── iris-prod.yaml      # App PROD (sync manual)
└── projects/
    └── iris-project.yaml   # Projeto com RBAC
```

## Comportamento por Ambiente

| Ambiente | Sync | Prune | Self-Heal |
|----------|------|-------|-----------|
| DEV | Automatico | Sim | Sim |
| PROD | Manual | Sim | Nao |

## Comandos Uteis

```bash
# Ver status das aplicacoes
kubectl get applications -n argocd

# Forcar sync manual
kubectl -n argocd patch application iris-ml-dev --type merge -p '{"operation": {"sync": {}}}'

# Ver logs do ArgoCD
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server

# Deletar aplicacao (cuidado!)
kubectl delete application iris-ml-dev -n argocd
```

## Troubleshooting

### Aplicacao stuck em "Progressing"

```bash
# Verificar eventos
kubectl describe application iris-ml-dev -n argocd

# Verificar pods da aplicacao
kubectl get pods -n iris-ml
```

### Sync falhou

```bash
# Ver detalhes do erro
kubectl -n argocd get application iris-ml-dev -o yaml | grep -A 20 "status:"
```

### Resetar senha admin

```bash
# Deletar secret e reiniciar argocd-server
kubectl delete secret argocd-initial-admin-secret -n argocd
kubectl rollout restart deployment argocd-server -n argocd
```

## Proximos Passos

1. [ ] Configurar Ingress com TLS para ArgoCD
2. [ ] Integrar com GitHub SSO
3. [ ] Instalar ArgoCD Image Updater
4. [ ] Configurar notificacoes (Slack/Teams)
