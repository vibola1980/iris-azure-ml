# Operations Runbook

This runbook contains operational procedures for the Iris ML API v4.

## Service Overview

| Service | Port | Health Check | Description |
|---------|------|--------------|-------------|
| API Gateway | 8080 | `/health/live`, `/health/ready` | Java Spring Boot API |
| Inference Service | 5000 | `/health/live`, `/health/ready` | Python ML inference |

## Quick Reference

### Check Service Status

```bash
# Kubernetes
kubectl get pods -n iris-ml
kubectl get svc -n iris-ml
kubectl get hpa -n iris-ml

# Local
docker-compose ps
```

### View Logs

```bash
# Kubernetes
kubectl logs -f deployment/api-gateway -n iris-ml
kubectl logs -f deployment/inference-service -n iris-ml

# Local
docker-compose logs -f api-gateway
docker-compose logs -f inference-service
```

### Health Checks

```bash
# API Gateway
curl http://<service-ip>:8080/health/live
curl http://<service-ip>:8080/health/ready

# Inference Service (internal)
kubectl exec -it deployment/api-gateway -n iris-ml -- curl http://inference-service:5000/health/ready
```

---

## Incident Response

### High CPU Alert

**Symptoms:** Alert triggered for CPU > 70%

**Investigation:**
```bash
# Check pod resource usage
kubectl top pods -n iris-ml

# Check HPA status
kubectl get hpa -n iris-ml

# Check node resources
kubectl top nodes
```

**Actions:**
1. Check if HPA is scaling (may need time)
2. Review recent deployments for resource-intensive changes
3. Check for traffic spikes in monitoring
4. If needed, manually scale: `kubectl scale deployment/inference-service --replicas=5 -n iris-ml`

---

### High Memory Alert

**Symptoms:** Alert triggered for memory > 80%

**Investigation:**
```bash
# Check pod memory
kubectl top pods -n iris-ml

# Check for memory leaks (OOMKilled restarts)
kubectl get pods -n iris-ml -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[*].restartCount}{"\n"}{end}'
```

**Actions:**
1. Check for OOMKilled events
2. Review recent changes to model or code
3. Consider increasing memory limits in Kustomize
4. Restart pods if memory leak suspected

---

### Pod CrashLoopBackOff

**Symptoms:** Pod status shows `CrashLoopBackOff`

**Investigation:**
```bash
# Get pod details
kubectl describe pod <pod-name> -n iris-ml

# Check logs (including previous container)
kubectl logs <pod-name> -n iris-ml --previous

# Check events
kubectl get events -n iris-ml --sort-by='.lastTimestamp'
```

**Common Causes:**
1. Model file not found (init container failed)
2. Configuration error (missing env vars)
3. Application startup error
4. Resource limits too low

**Actions:**
1. Fix the root cause based on logs
2. Delete the pod to trigger recreation: `kubectl delete pod <pod-name> -n iris-ml`

---

### Inference Service Not Ready

**Symptoms:** Readiness probe failing, traffic not reaching service

**Investigation:**
```bash
# Check inference service health
kubectl exec -it deployment/api-gateway -n iris-ml -- curl -v http://inference-service:5000/health/ready

# Check init container status
kubectl describe pod -l app=inference-service -n iris-ml | grep -A 10 "Init Containers"

# Check model download
kubectl logs -l app=inference-service -n iris-ml -c download-model
```

**Common Causes:**
1. Model download failed (storage account access)
2. Model file corrupted
3. Init container failed

**Actions:**
1. Check Azure Blob Storage connectivity
2. Verify managed identity permissions
3. Check model exists in storage: `az storage blob list --account-name <storage> --container-name models`

---

### Deployment Failed / Stuck

**Symptoms:** Deployment not completing, pods not becoming ready

**Investigation:**
```bash
# Check deployment status
kubectl rollout status deployment/api-gateway -n iris-ml
kubectl rollout status deployment/inference-service -n iris-ml

# Check deployment history
kubectl rollout history deployment/api-gateway -n iris-ml

# Check events
kubectl get events -n iris-ml --sort-by='.lastTimestamp' | head -20
```

**Actions:**
1. If stuck, check pod logs for startup errors
2. Rollback if needed: `kubectl rollout undo deployment/api-gateway -n iris-ml`
3. Check image pull errors (ACR access)

---

## Routine Operations

### Deploy New Version

```bash
# Via GitHub Actions (recommended)
# 1. Push to main branch
# 2. CI pipeline builds and pushes images
# 3. Manually trigger CD pipeline or use workflow_dispatch

# Manual deployment
make deploy-dev  # or deploy-prod
```

### Update Model Version

1. Upload new model to Azure Blob Storage:
```bash
az storage blob upload \
  --account-name <storage-account> \
  --container-name models \
  --name iris-classifier/v2.0.0/model.pkl \
  --file model.pkl
```

2. Update ConfigMap:
```bash
kubectl edit configmap model-config -n iris-ml
# Change MODEL_VERSION and MODEL_BLOB_NAME
```

3. Trigger rolling restart:
```bash
kubectl rollout restart deployment/inference-service -n iris-ml
```

### Scale Services

```bash
# Manual scaling
kubectl scale deployment/api-gateway --replicas=5 -n iris-ml
kubectl scale deployment/inference-service --replicas=5 -n iris-ml

# Check HPA configuration
kubectl get hpa -n iris-ml -o yaml
```

### View Metrics

```bash
# Prometheus metrics (API Gateway)
curl http://<api-gateway-ip>:8080/actuator/prometheus

# Azure Monitor
# Navigate to: Azure Portal > AKS Cluster > Insights
```

### Rotate Secrets

1. Update secret in Azure Key Vault
2. External Secrets Operator will sync automatically (1h refresh)
3. To force sync:
```bash
kubectl annotate externalsecret iris-ml-secrets -n iris-ml force-sync=$(date +%s) --overwrite
```

---

## Recovery Procedures

### Full Service Restart

```bash
# Restart all pods
kubectl rollout restart deployment/api-gateway -n iris-ml
kubectl rollout restart deployment/inference-service -n iris-ml

# Wait for rollout
kubectl rollout status deployment/api-gateway -n iris-ml
kubectl rollout status deployment/inference-service -n iris-ml
```

### Rollback Deployment

```bash
# View history
kubectl rollout history deployment/api-gateway -n iris-ml

# Rollback to previous version
kubectl rollout undo deployment/api-gateway -n iris-ml

# Rollback to specific revision
kubectl rollout undo deployment/api-gateway -n iris-ml --to-revision=2
```

### Disaster Recovery

1. **AKS Cluster Failure:**
   - Run Terraform to recreate cluster: `terraform apply`
   - Deploy applications: `make deploy-prod`

2. **Data Loss:**
   - Models are stored in Azure Blob Storage with versioning
   - Restore from previous version if needed

3. **Complete Region Failure:**
   - Deploy to secondary region (requires multi-region Terraform)
   - Update DNS to point to new region

---

## Monitoring & Alerts

### Azure Monitor Alerts

| Alert | Threshold | Action |
|-------|-----------|--------|
| High CPU | > 80% for 15min | Scale up or investigate |
| High Memory | > 85% for 15min | Check for leaks, scale |
| Pod Restarts | > 5 in 15min | Check logs, fix issue |

### Log Queries (Azure Monitor)

```kusto
// Recent errors
ContainerLog
| where LogEntry contains "ERROR"
| where TimeGenerated > ago(1h)
| project TimeGenerated, ContainerName, LogEntry

// Request latency
requests
| where timestamp > ago(1h)
| summarize avg(duration), percentile(duration, 95) by bin(timestamp, 5m)

// Pod restarts
KubePodInventory
| where TimeGenerated > ago(24h)
| where Namespace == "iris-ml"
| summarize Restarts=sum(PodRestartCount) by PodName, bin(TimeGenerated, 1h)
```

---

## Contact

- **On-Call:** Check PagerDuty schedule
- **Slack:** #iris-ml-alerts
- **Email:** ml-platform-team@example.com
