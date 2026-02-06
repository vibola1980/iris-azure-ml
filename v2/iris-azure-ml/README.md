# Iris Classifier API - v2 (Hybrid Architecture)

## 🏗️ Overview

The **Iris Classifier API v2** is an improved FastAPI application with:

- ✅ **Kubernetes-ready health checks** (liveness + readiness probes)
- ✅ **Model Registry abstraction** (local, Azure Blob, MLflow)
- ✅ **Version tracking** (model versioning in responses)
- ✅ **Graceful shutdown** (proper lifecycle management)
- ✅ **Structured logging** (production-grade logging)
- ✅ **Enhanced error handling** (detailed error messages)
- ✅ **Configuration-driven deployment** (environment variables)

This is **Phase 1** of a 3-phase evolution toward Java/Spring Boot + AKS:

```
v2 (You are here)          v3 (Next)           v4 (Future)
FastAPI + Hybrid ──────→ Java/Spring + Model ──────→ AKS Native
Model Registry           Registry Integration      Multi-region
Kubernetes ready         with Secrets              Auto-scaling
```

---

## 📁 Project Structure

```
iris-azure-ml/
├── api/
│   ├── app.py                 # FastAPI application (main)
│   ├── model_registry.py      # Abstract Model Registry implementations
│   ├── __init__.py
│   └── requirements.txt        # Python dependencies (pinned versions)
├── models/
│   ├── .gitkeep               # Placeholder for model files
│   ├── model-1.0.0.pkl        # Example: v1.0.0 model
│   └── model-1.0.0.json       # Metadata (optional)
├── tests/
│   ├── __init__.py
│   └── test_api.py            # Unit tests
├── .env                        # Environment variables (local dev)
├── .env.example                # Template for .env
├── .gitignore
├── Dockerfile                  # Container build
├── docker-compose.yml          # Local development with Docker
├── README.md                   # This file
├── ARCHITECTURE.md             # Technical architecture
└── TEST_PLAN.md                # Comprehensive test scenarios
```

---

## 🚀 Setup Instructions

### 1. Clone and prepare

```bash
cd v2/iris-azure-ml
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 2. Install dependencies

```bash
pip install -r api/requirements.txt
```

### 3. Configure environment

```bash
# Copy template
cp .env.example .env

# Edit .env with your settings
# KEY VARIABLES:
export MODEL_PATH=./models/model.pkl
export MODEL_VERSION=1.0.0
export API_KEY=your-secret-key-123
export MODEL_REGISTRY_TYPE=local  # or: azure, mlflow
```

### 4. Prepare model

Copy your trained model to the models directory:

```bash
# From project root:
cp training/artifacts/model.pkl v2/iris-azure-ml/models/model-1.0.0.pkl
```

### 5. Run the API

```bash
# Development mode (with auto-reload):
uvicorn api.app:app --reload --host 0.0.0.0 --port 8000

# Production mode:
uvicorn api.app:app --host 0.0.0.0 --port 8000 --workers 4
```

The API will be available at: **http://localhost:8000**

---

## 🔍 API Endpoints

### Health Checks (for Kubernetes probes)

#### 1. **Liveness Probe** - Is the container alive?

```bash
GET /health/live
```

**Response (200 OK):**
```json
{
  "status": "alive"
}
```

✅ Use in Kubernetes: `livenessProbe`

---

#### 2. **Readiness Probe** - Is the app ready for traffic?

```bash
GET /health/ready
```

**Response when READY (200 OK):**
```json
{
  "status": "ready",
  "ready": true,
  "model_loaded": true,
  "model_version": "1.0.0",
  "model_path": "./models/model.pkl",
  "loaded_at": "2026-02-03T10:30:45.123456",
  "error": null
}
```

**Response when NOT READY (503 Service Unavailable):**
```json
{
  "status": "not_ready",
  "ready": false,
  "model_loaded": false,
  "model_version": "1.0.0",
  "model_path": "./models/model.pkl",
  "loaded_at": null,
  "error": "Model file not found at ./models/model.pkl"
}
```

✅ Use in Kubernetes: `readinessProbe`

---

#### 3. **Legacy Health Endpoint** (backward compatible)

```bash
GET /health
```

Same response as `/health/ready`

---

### Prediction

#### **POST /predict** - Classify an iris

```bash
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-secret-key-123" \
  -d '{
    "sepal_length": 5.1,
    "sepal_width": 3.5,
    "petal_length": 1.4,
    "petal_width": 0.2
  }'
```

**Response (200 OK):**
```json
{
  "predicted_class_id": 0,
  "predicted_class_name": "setosa",
  "probabilities": [0.98, 0.02, 0.0],
  "model_version": "1.0.0",
  "timestamp": "2026-02-03T10:35:20.654321"
}
```

**Error - Invalid API Key (401 Unauthorized):**
```json
{
  "detail": "Invalid API key"
}
```

**Error - Model not loaded (503 Service Unavailable):**
```json
{
  "detail": "Model not loaded. Ensure model.pkl is available."
}
```

---

## 📊 Model Registry

The API abstracts model loading through a `ModelRegistry` interface, supporting multiple backends:

### 1. **Local File System** (default, for dev/testing)

```python
# Automatically used when:
export MODEL_REGISTRY_TYPE=local
export LOCAL_MODELS_PATH=./models
```

Models expected at: `./models/model-{version}.pkl`

### 2. **Azure Blob Storage** (production recommended)

```python
# Setup:
export MODEL_REGISTRY_TYPE=azure
export AZURE_STORAGE_CONNECTION_STRING=DefaultEndpointProtocol=https;...
```

Models stored at: `https://{storage}.blob.core.windows.net/models/model-{version}.pkl`

### 3. **MLflow Model Registry** (enterprise)

```python
# Setup:
export MODEL_REGISTRY_TYPE=mlflow
export MLFLOW_TRACKING_URI=http://mlflow-server:5000
```

---

## 🧪 Testing

### Run unit tests

```bash
pytest tests/test_api.py -v
```

### Manual testing (comprehensive)

See [TEST_PLAN.md](TEST_PLAN.md) for 10 detailed test scenarios

Quick test:

```bash
# 1. Check if model is ready
curl http://localhost:8000/health/ready

# 2. Make a prediction
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-secret-key-123" \
  -d '{"sepal_length":5.1,"sepal_width":3.5,"petal_length":1.4,"petal_width":0.2}'
```

### Interactive documentation

Open in browser: **http://localhost:8000/docs** (Swagger UI)

---

## 🐳 Docker

### Build image

```bash
docker build -t iris-api:1.0.0 .
```

### Run locally with docker-compose

```bash
docker-compose up
```

This starts:
- FastAPI app on `http://localhost:8000`
- Mounts `./models` as volume for model persistence

### Push to Azure Container Registry

```bash
az acr build --registry myregistry \
  --image iris-api:1.0.0 .
```

---

## ☸️ Kubernetes Deployment

### Probes Configuration

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: iris-api
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: iris-api
        image: myregistry.azurecr.io/iris-api:1.0.0
        
        # Liveness: Restart if crashed
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 10
          failureThreshold: 3
        
        # Readiness: Drain traffic if not ready
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 5
          failureThreshold: 2
        
        # Configuration
        env:
        - name: MODEL_VERSION
          valueFrom:
            configMapKeyRef:
              name: model-config
              key: version
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: api-secrets
              key: api-key
```

---

## 📈 Architecture Evolution

### Current State (v2 - You are here)

✅ Hybrid pattern ready
✅ Config-driven via ConfigMap/Secrets
✅ Multiple registry backends
✅ Kubernetes health checks

### Next Phase (v3 - Java/Spring Boot)

🔜 Java application
🔜 Spring Boot framework
🔜 Native metrics/monitoring
🔜 Spring Cloud integration

### Future (v4 - Full AKS)

🔜 Multi-region deployment
🔜 Auto-scaling policies
🔜 CI/CD with GitHub Actions
🔜 MLflow integration for retraining

---

## 🔐 Security

- API authentication via `X-API-Key` header
- Secrets stored in Kubernetes Secrets (not in code)
- Model registry credentials in environment variables
- Structured logging (no secrets in logs)

---

## 📝 Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `MODEL_PATH` | `model.pkl` | Path to model file |
| `MODEL_VERSION` | `unknown` | Version identifier |
| `API_KEY` | `` | API authentication key (empty = no auth) |
| `MODEL_REGISTRY_TYPE` | `local` | Registry backend: `local`, `azure`, `mlflow` |
| `LOCAL_MODELS_PATH` | `./models` | Local models directory |
| `AZURE_STORAGE_CONNECTION_STRING` | `` | Azure connection string (if azure registry) |
| `MLFLOW_TRACKING_URI` | `http://localhost:5000` | MLflow server URI (if mlflow registry) |

---

## 🐛 Troubleshooting

**Q: Model not loading?**
- Check file path: `echo $MODEL_PATH`
- Check file exists: `ls -la models/`
- Check `/health/ready` for error details

**Q: API Key not working?**
- Ensure `API_KEY` is set: `echo $API_KEY`
- Ensure header is `X-API-Key`, not `Authorization`

**Q: Container keeps restarting?**
- Check liveness probe: `curl http://localhost:8000/health/live`
- Check logs: `docker logs iris-api`

---

## 📚 Additional Resources

- [TEST_PLAN.md](TEST_PLAN.md) - Comprehensive testing guide
- [ARCHITECTURE.md](../ARCHITECTURE.md) - Full architecture overview
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Kubernetes Health Checks](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)

---

## 🤝 Contributing

1. Create a feature branch
2. Make changes in `v2/iris-azure-ml`
3. Run tests: `pytest tests/`
4. Submit pull request

---

## 📄 License

This project is part of the Iris ML Azure POC.
