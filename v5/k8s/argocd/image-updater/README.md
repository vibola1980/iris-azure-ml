# ArgoCD Image Updater

Atualiza automaticamente as imagens Docker quando novas versoes sao publicadas no ACR.

## Como Funciona

```
+------------------+          +------------------+          +------------------+
|  GitHub Actions  |          |      ACR         |          | Image Updater    |
|                  |          |                  |          |                  |
|  Build & Push    |  ------> |  iris/api:1.2.3  |  <------ |  Monitora a cada |
|  nova imagem     |          |  iris/api:1.2.4  |          |  2 minutos       |
+------------------+          +------------------+          +--------+---------+
                                                                     |
                                                                     | Nova tag detectada!
                                                                     v
+------------------+          +------------------+          +------------------+
|      AKS         |          |     ArgoCD       |          |     GitHub       |
|                  |          |                  |          |                  |
|  Pod atualizado  |  <------ |  Sync automatico |  <------ |  Commit auto     |
|  com nova imagem |          |                  |          |  "update to 1.2.4"|
+------------------+          +------------------+          +------------------+
```

## Estrategias de Update

| Estrategia | Descricao | Exemplo |
|------------|-----------|---------|
| `semver` | Segue versionamento semantico | 1.2.3 → 1.2.4 → 1.3.0 |
| `latest` | Sempre pega a tag mais recente | latest, main |
| `digest` | Atualiza baseado no SHA | sha256:abc123 |

Usamos `semver` para ter controle de versao.

## Configuracao das Imagens

No arquivo `applications/iris-dev.yaml`, as annotations definem:

```yaml
annotations:
  # Quais imagens monitorar
  argocd-image-updater.argoproj.io/image-list: |
    api-gateway=acririsdev.azurecr.io/iris/api-gateway,
    inference-service=acririsdev.azurecr.io/iris/inference-service

  # Estrategia (semver = 1.2.3)
  argocd-image-updater.argoproj.io/api-gateway.update-strategy: semver

  # Filtro de tags (so aceita formato X.Y.Z)
  argocd-image-updater.argoproj.io/api-gateway.allow-tags: regexp:^[0-9]+\.[0-9]+\.[0-9]+$
```

## Setup Manual de Secrets

Os secrets NAO estao commitados (por seguranca). Criar manualmente:

### 1. Secret do ACR

```bash
# Obter credenciais do ACR
ACR_NAME="acririsdev"
ACR_USERNAME=$(az acr credential show -n $ACR_NAME --query "username" -o tsv)
ACR_PASSWORD=$(az acr credential show -n $ACR_NAME --query "passwords[0].value" -o tsv)

# Criar secret
kubectl create secret docker-registry acr-credentials \
  --namespace argocd \
  --docker-server=${ACR_NAME}.azurecr.io \
  --docker-username=$ACR_USERNAME \
  --docker-password=$ACR_PASSWORD
```

### 2. Secret do GitHub (para write-back)

```bash
# Criar token em: https://github.com/settings/tokens
# Permissoes necessarias: repo (Full control)

kubectl create secret generic git-credentials \
  --namespace argocd \
  --from-literal=username=vibola1980 \
  --from-literal=password=ghp_XXXXXXXXXXXXXXXXXXXX
```

## Verificar Funcionamento

```bash
# Ver logs do Image Updater
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-image-updater -f

# Ver quais imagens estao sendo monitoradas
kubectl get applications -n argocd -o yaml | grep -A 10 "image-updater"

# Forcar verificacao imediata
kubectl annotate application iris-ml-dev -n argocd \
  argocd-image-updater.argoproj.io/refresh=now --overwrite
```

## Fluxo de CI/CD Completo

```
1. Dev faz merge de PR
         |
         v
2. GitHub Actions executa:
   - Build da imagem
   - Tag com versao (1.2.3)
   - Push para ACR
         |
         v
3. Image Updater (a cada 2 min):
   - Verifica ACR
   - Encontra nova tag 1.2.3
   - Commit no GitHub: "update api-gateway to 1.2.3"
         |
         v
4. ArgoCD detecta commit
   - Sync automatico
   - Atualiza Deployment
   - Rolling update dos pods
         |
         v
5. Nova versao rodando!
```

## Troubleshooting

### Image Updater nao detecta novas imagens

```bash
# Verificar se o secret do ACR esta correto
kubectl get secret acr-credentials -n argocd -o yaml

# Testar conexao com ACR
kubectl run test-acr --image=acririsdev.azurecr.io/iris/api-gateway:latest --rm -it -- /bin/sh
```

### Commit no GitHub falha

```bash
# Verificar secret do GitHub
kubectl get secret git-credentials -n argocd -o yaml

# Ver logs detalhados
kubectl logs -n argocd deployment/argocd-image-updater --tail=100
```

### Imagem nao atualiza no cluster

```bash
# Verificar se ArgoCD esta sincronizando
kubectl get application iris-ml-dev -n argocd -o yaml | grep -A 5 "status:"

# Forcar sync
kubectl -n argocd patch application iris-ml-dev --type merge -p '{"operation": {"sync": {}}}'
```
