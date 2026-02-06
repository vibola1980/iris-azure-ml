# Phase 2: Spring Boot Migration (v3) - Quick Start

## 📋 Overview

Phase 2 implements the v3 architecture using Spring Boot 3.2.1 with Java 17. The system consists of:

- **Java API** (Spring Boot): REST endpoints, health checks, request validation
- **Python Service** (FastAPI): Model inference, model management
- **Docker Compose**: Local development orchestration

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│         Client / External System                    │
└────────────────────┬────────────────────────────────┘
                     │ HTTP
          ┌──────────▼──────────┐
          │   Java API (8080)   │  Spring Boot 3.2.1
          │   ┌──────────────┐  │
          │   │ Controllers  │  │
          │   │ Services     │  │
          │   │ Validation   │  │
          │   │ Logging      │  │
          │   └──────┬───────┘  │
          └──────────┼──────────┘
                     │ HTTP
          ┌──────────▼─────────────┐
          │ Python Service (5000)  │  FastAPI
          │ ┌────────────────────┐ │
          │ │ Model Inference    │ │
          │ │ scikit-learn       │ │
          │ │ Health Checks      │ │
          │ └────────────────────┘ │
          │  model.pkl (joblib)    │
          └────────────────────────┘
```

## 🚀 Quick Start (Local Development)

### Prerequisites
- Docker & Docker Compose
- OR Maven 3.9+ & Java 17 & Python 3.12

### Option A: Docker Compose (Recommended)

```bash
# Start both services
cd v3/iris-spring-boot
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f api-service        # Java API logs
docker-compose logs -f inference-service  # Python logs

# Stop
docker-compose down
```

### Option B: Manual Development

#### 1. Start Python Inference Service
```bash
cd inference-service

# Install dependencies
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt

# Start service
export MODEL_PATH=../models/model.pkl
export MODEL_VERSION=1.0.0
export API_KEY=test123
python -m uvicorn app:app --host 0.0.0.0 --port 5000 --reload
```

#### 2. Build & Start Java API
```bash
cd ..

# Build
mvn clean package

# Run
export IRIS_INFERENCE_SERVICE_URL=http://localhost:5000
mvn spring-boot:run
```

## 🔧 Configuration

### Environment Variables

**Java API** (`application.yml`):
```yaml
iris:
  model:
    version: 1.0.0
    path: models/model.pkl
  inference:
    service:
      url: http://localhost:5000  # OR http://inference-service:5000 (Docker)
  api:
    key: test123  # Optional API key
```

**Python Service** (`.env`):
```env
MODEL_PATH=models/model.pkl
MODEL_VERSION=1.0.0
API_KEY=test123
```

## 📡 API Endpoints

### Health Checks (Kubernetes Probes)

```bash
# Liveness probe (Is container alive?)
curl http://localhost:8080/health/live

# Readiness probe (Is app ready for traffic?)
curl http://localhost:8080/health/ready

# Legacy endpoint
curl http://localhost:8080/health
```

### Prediction

```bash
# Classify iris flower
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: test123" \
  -d '{
    "sepal_length": 5.1,
    "sepal_width": 3.5,
    "petal_length": 1.4,
    "petal_width": 0.2
  }'

# Response
{
  "predicted_class_id": 0,
  "predicted_class_name": "setosa",
  "probabilities": [0.97, 0.03, 0.0],
  "model_version": "1.0.0",
  "timestamp": "2024-01-15T10:30:45.123456"
}
```

## 📁 Project Structure

```
v3/iris-spring-boot/
├── pom.xml                          # Maven configuration
├── Dockerfile                       # Java API Docker image
├── docker-compose.yml               # Orchestration
├── train_model.py                   # Script para treinar modelo
├── src/
│   ├── main/
│   │   ├── java/com/iris/
│   │   │   ├── IrisApplication.java      # Main class
│   │   │   ├── controller/
│   │   │   │   ├── HealthController.java    # Health probes
│   │   │   │   └── PredictionController.java # Predictions
│   │   │   ├── service/
│   │   │   │   └── ModelInferenceClient.java # Python calls
│   │   │   └── model/
│   │   │       ├── PredictRequest.java       # Request DTO
│   │   │       ├── PredictionResponse.java   # Response DTO
│   │   │       ├── HealthResponse.java       # Health model
│   │   │       └── LivenessResponse.java     # Liveness model
│   │   └── resources/
│   │       ├── application.yml          # Default config
│   │       └── application-docker.yml   # Docker config
│   └── test/java/com/iris/             # Unit & integration tests
├── inference-service/
│   ├── app.py                       # FastAPI inference app
│   ├── requirements.txt             # Python dependencies
│   ├── .env                         # Configuration
│   └── Dockerfile                   # Python image
├── docs/                            # Documentation
│   ├── TESTING.md                   # Test scenarios
│   ├── TROUBLESHOOTING.md           # Common issues & solutions
│   └── VALIDATION_CHECKLIST.md      # Validation steps
└── models/
    └── model.pkl                    # Trained scikit-learn model
```

## 🧪 Testing

### Unit Tests
```bash
mvn test
```

### Integration Tests
```bash
mvn verify
```

### Manual Testing with cURL

```bash
#!/bin/bash
API_URL="http://localhost:8080"
API_KEY="test123"

# Test 1: Liveness
echo "Test 1: Liveness probe"
curl -s "${API_URL}/health/live" | jq .

# Test 2: Readiness
echo "Test 2: Readiness probe"
curl -s "${API_URL}/health/ready" | jq .

# Test 3: Prediction (valid)
echo "Test 3: Prediction (Setosa)"
curl -s -X POST "${API_URL}/predict" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: ${API_KEY}" \
  -d '{"sepal_length": 5.1, "sepal_width": 3.5, "petal_length": 1.4, "petal_width": 0.2}' | jq .

# Test 4: Prediction (different class)
echo "Test 4: Prediction (Virginica)"
curl -s -X POST "${API_URL}/predict" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: ${API_KEY}" \
  -d '{"sepal_length": 7.9, "sepal_width": 3.8, "petal_length": 6.4, "petal_width": 2.0}' | jq .

# Test 5: Prediction (invalid - no API key)
echo "Test 5: Prediction (unauthorized)"
curl -s -X POST "${API_URL}/predict" \
  -H "Content-Type: application/json" \
  -d '{"sepal_length": 5.1, "sepal_width": 3.5, "petal_length": 1.4, "petal_width": 0.2}'

# Test 6: Prediction (invalid - bad data)
echo "Test 6: Prediction (validation error)"
curl -s -X POST "${API_URL}/predict" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: ${API_KEY}" \
  -d '{"sepal_length": 100, "sepal_width": 3.5, "petal_length": 1.4, "petal_width": 0.2}'
```

## 📦 Build & Deployment

### Build JAR
```bash
mvn clean package
# Output: target/iris-classifier-api-*.jar
```

### Docker Images
```bash
# Build manually
docker build -t iris-api:v3 .
docker build -t iris-inference:v3 inference-service/

# Or use docker-compose
docker-compose build
```

### Local Testing
```bash
docker-compose up -d
docker-compose ps

# Test endpoints
curl http://localhost:8080/health/ready
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: test123" \
  -d '{"sepal_length": 5.1, "sepal_width": 3.5, "petal_length": 1.4, "petal_width": 0.2}'

docker-compose down
```

## 🔍 Troubleshooting

### Issue: "Inference service not ready"

**Check Python service:**
```bash
curl http://localhost:5000/health/ready
```

**Check logs:**
```bash
docker-compose logs inference-service
```

**Verify model file:**
```bash
ls -la models/model.pkl
```

### Issue: "Connection refused"

**Verify services are running:**
```bash
docker-compose ps
```

**Rebuild:**
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Issue: "Validation error"

Check request format matches OpenAPI spec:
```bash
curl http://localhost:8080/swagger-ui.html
```

## 📊 Monitoring & Metrics

### Actuator Endpoints
```bash
# Health details
curl http://localhost:8080/actuator/health

# Metrics
curl http://localhost:8080/actuator/metrics

# Prometheus format
curl http://localhost:8080/actuator/prometheus
```

## 🎯 Next Steps

1. **Local Validation**: Test all endpoints with docker-compose
2. **Unit Tests**: Write tests for controllers and services
3. **Integration Tests**: End-to-end testing
4. **Kubernetes Manifests**: Deploy to AKS
5. **CI/CD Pipeline**: GitHub Actions workflow
6. **Performance Testing**: Load testing with k6 or JMeter

## 📚 References

- [Spring Boot 3.2.1 Docs](https://spring.io/projects/spring-boot)
- [FastAPI Docs](https://fastapi.tiangolo.com/)
- [Kubernetes Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)

## 🚢 Deployment Timeline

| Phase | Duration | Focus |
|-------|----------|-------|
| Phase 2.1 | Days 1-3 | Local Docker Compose testing |
| Phase 2.2 | Days 4-5 | Unit & Integration tests |
| Phase 2.3 | Day 6-7 | CI/CD Pipeline setup |
| Phase 3 | Week 2 | Kubernetes deployment to AKS |

---

**Status**: ✅ Phase 2 Scaffolding Complete  
**Last Updated**: 2024  
**Version**: 3.0.0 (Spring Boot)
