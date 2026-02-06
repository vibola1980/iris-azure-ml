## 🚀 QUICK REFERENCE - v2 Hybrid Architecture

### ⚡ Start Development in 3 Minutes

```bash
# 1. Go to project
cd v2/iris-azure-ml

# 2. Install & setup
pip install -r api/requirements.txt
cp .env.example .env
cp ../../../training/artifacts/model.pkl models/model.pkl

# 3. Run
export MODEL_PATH=models/model.pkl MODEL_VERSION=1.0.0 API_KEY=test123
uvicorn api.app:app --reload
```

**Open browser**: http://localhost:8000/docs

---

### 📍 Endpoints Cheat Sheet

```bash
# Liveness (is container alive?)
curl http://localhost:8000/health/live
# → {"status": "alive"}

# Readiness (is app ready for traffic?)
curl http://localhost:8000/health/ready
# → {"status": "ready", "ready": true, "model_version": "1.0.0", ...}

# Make prediction
curl -X POST http://localhost:8000/predict \
  -H "X-API-Key: test123" \
  -d '{"sepal_length":5.1,"sepal_width":3.5,"petal_length":1.4,"petal_width":0.2}'
# → {"predicted_class_id": 0, "predicted_class_name": "setosa", ...}
```

---

### 🐳 Docker Quick Commands

```bash
# Build
docker build -t iris-api:1.0.0 .

# Run
docker run -p 8000:8000 \
  -e MODEL_PATH=/models/model.pkl \
  -e API_KEY=test123 \
  -v $(pwd)/models:/models \
  iris-api:1.0.0

# Docker Compose
docker-compose up
```

---

### 🔧 Environment Variables

```bash
# Core
MODEL_PATH=./models/model.pkl              # Where's the model?
MODEL_VERSION=1.0.0                        # What version?
API_KEY=your-secret-key                    # Auth key (optional)

# Registry (choose one)
MODEL_REGISTRY_TYPE=local                  # local | azure | mlflow
LOCAL_MODELS_PATH=./models                 # For local
AZURE_STORAGE_CONNECTION_STRING=...        # For azure
MLFLOW_TRACKING_URI=http://localhost:5000  # For mlflow
```

---

### 📚 File Reference

| File | Purpose | Status |
|------|---------|--------|
| [api/app.py](../iris-azure-ml/api/app.py) | Main FastAPI app | ✅ Updated |
| [api/model_registry.py](../iris-azure-ml/api/model_registry.py) | Registry backends | ✅ New |
| [api/requirements.txt](../iris-azure-ml/api/requirements.txt) | Dependencies | ✅ Updated |
| [README.md](../iris-azure-ml/README.md) | Full guide | ✅ New |
| [TEST_PLAN.md](../iris-azure-ml/TEST_PLAN.md) | Test scenarios | ✅ New |
| [ROADMAP.md](../iris-azure-ml/ROADMAP.md) | Future phases | ✅ New |
| [.env.example](../iris-azure-ml/.env.example) | Config template | ✅ New |

---

### 🎯 Common Tasks

#### Add Azure Storage Registry

```bash
# Set env var
export AZURE_STORAGE_CONNECTION_STRING="DefaultEndpointProtocol=https;AccountName=myaccount;AccountKey=...;EndpointSuffix=core.windows.net"
export MODEL_REGISTRY_TYPE=azure

# Upload model to blob
az storage blob upload \
  --account-name myaccount \
  --container-name models \
  --name model-1.0.0.pkl \
  --file ./models/model.pkl
```

#### Add MLflow Registry

```bash
# Start MLflow server
mlflow server --host 0.0.0.0 --port 5000

# Set env var
export MODEL_REGISTRY_TYPE=mlflow
export MLFLOW_TRACKING_URI=http://localhost:5000
```

#### Deploy to Docker

```bash
docker-compose up -d
curl http://localhost:8000/health/ready
```

#### Deploy to AKS

```bash
# Create ConfigMap
kubectl create configmap model-config \
  --from-literal=version=1.0.0

# Create Secret
kubectl create secret generic api-secrets \
  --from-literal=api-key=your-secret-key

# Deploy
kubectl apply -f kubernetes/deployment.yaml

# Check
kubectl get pods
kubectl logs deployment/iris-api
```

---

### 🔍 Troubleshooting

**Q: Model not loading?**
```bash
# Check file exists
ls -la models/model.pkl

# Check env var
echo $MODEL_PATH

# Check logs
tail -f logs.txt  # or docker logs
```

**Q: Health check failing?**
```bash
# Check readiness endpoint
curl -v http://localhost:8000/health/ready

# Response should be 200 OK with status: "ready"
```

**Q: API Key issue?**
```bash
# With key
curl -H "X-API-Key: test123" http://localhost:8000/predict

# Without key (if API_KEY not set in env)
curl http://localhost:8000/predict
```

---

### 📊 Kubernetes Probes

```yaml
livenessProbe:
  httpGet:
    path: /health/live
    port: 8000
  initialDelaySeconds: 10
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health/ready
    port: 8000
  initialDelaySeconds: 30
  periodSeconds: 5
```

---

### 🎓 Key Concepts

| Concept | Explanation |
|---------|-------------|
| **Liveness Probe** | Detects if container is hung/crashed → restarts pod |
| **Readiness Probe** | Detects if ready for traffic → drains traffic during startup/shutdown |
| **Model Registry** | Abstraction for loading models from different sources |
| **Init Container** | Runs before main container to prepare environment |
| **ConfigMap** | Kubernetes config storage (model version, etc) |
| **Secret** | Kubernetes encrypted storage (API keys, passwords) |

---

### 🚀 Next Phase (v3 - Java/Spring Boot)

**Timeline**: 2-3 weeks

**Key Changes**:
- Python FastAPI → Java Spring Boot
- Same API contract (backward compatible)
- Model Registry in Java
- Spring Boot Actuator for metrics
- Deploy to AKS with scaling

**Questions to think about**:
1. ONNX conversion or Python service for inference?
2. How often do models get retrained?
3. What's the expected RPS/concurrency?
4. Multi-region deployment needed?

---

### 📞 Questions?

Refer to:
- [README.md](../iris-azure-ml/README.md) - Full setup guide
- [TEST_PLAN.md](../iris-azure-ml/TEST_PLAN.md) - Test scenarios  
- [ROADMAP.md](../iris-azure-ml/ROADMAP.md) - Future planning
- [PHASE1_SUMMARY.md](../iris-azure-ml/PHASE1_SUMMARY.md) - What changed

---

**Last Updated**: February 3, 2026
**Version**: v2 Phase 1 Complete ✅
**Next**: v3 Planning 🚀
