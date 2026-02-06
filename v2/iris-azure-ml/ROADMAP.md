# 🗺️ ROADMAP - Iris ML Azure Evolution

## 📊 Current State: v2 (COMPLETED ✅)

### What's Been Done

#### Phase 1: API Modernization
- ✅ Kubernetes-ready health checks
  - `/health/live` - Liveness probe
  - `/health/ready` - Readiness probe (503 if not ready)
- ✅ Model Registry abstraction
  - Local FileSystem (dev/testing)
  - Azure Blob Storage (production)
  - MLflow integration (enterprise)
- ✅ Version tracking in responses
- ✅ Graceful lifecycle management (startup/shutdown)
- ✅ Structured logging (production-grade)
- ✅ Enhanced error handling
- ✅ Configuration-driven via environment variables
- ✅ Comprehensive test plan
- ✅ Improved docker-compose.yml

#### Files Modified/Created

```
v2/iris-azure-ml/
├── api/app.py (ENHANCED)
│   ├─ Added: Lifecycle management (@asynccontextmanager)
│   ├─ Added: Health check endpoints (/health/live, /health/ready)
│   ├─ Added: Response models with Pydantic
│   ├─ Added: Structured logging
│   └─ Added: Model version tracking
│
├── api/model_registry.py (NEW)
│   ├─ ModelRegistry (abstract base class)
│   ├─ LocalFileSystemRegistry
│   ├─ AzureBlobStorageRegistry
│   ├─ MLflowRegistry
│   └─ Factory function: get_registry()
│
├── api/requirements.txt (UPDATED)
│   └─ Pinned versions for reproducibility
│
├── README.md (REWRITTEN)
│   ├─ Comprehensive setup guide
│   ├─ All endpoints documented
│   ├─ K8s deployment examples
│   └─ Troubleshooting guide
│
├── .env.example (NEW)
│   └─ All environment variables documented
│
├── TEST_PLAN.md (NEW)
│   ├─ 10 test scenarios
│   ├─ cURL examples for each
│   └─ Success checklist
│
└── docker-compose.yml (ENHANCED)
    ├─ Better health checks
    ├─ Model loader service
    ├─ Optional MLflow & PostgreSQL
    └─ Proper logging configuration
```

---

## 🚀 Next: Phase 2 (v3) - Java/Spring Boot

### Timeline: 2-3 weeks

### Goals

- [ ] Migrate from Python FastAPI → Java Spring Boot
- [ ] Keep same API contract (same endpoints + responses)
- [ ] Implement Model Registry in Java
- [ ] Support .pkl models via ONNX or direct Python interop
- [ ] Add metrics/monitoring (Spring Boot Actuator)
- [ ] Deploy to AKS with proper scaling

### Implementation Plan

#### Step 1: Project Setup (Week 1)

```bash
v3/iris-spring-boot/
├── pom.xml                          # Maven build
├── src/main/java/com/iris/
│   ├── IrisApplication.java         # Spring Boot main
│   ├── controller/
│   │   └── PredictionController.java
│   ├── service/
│   │   ├── PredictionService.java
│   │   └── ModelRegistry.java       # Same interface as v2
│   ├── model/
│   │   ├── PredictRequest.java
│   │   ├── PredictionResponse.java
│   │   └── HealthResponse.java
│   └── config/
│       ├── AppConfig.java
│       └── SecurityConfig.java
├── src/main/resources/
│   └── application.yml              # Spring Boot config
├── Dockerfile
└── kubernetes/
    ├── deployment.yaml
    ├── configmap.yaml
    └── secrets.yaml
```

#### Step 2: Python Model Integration (Week 1-2)

**Challenge**: Load `.pkl` files in Java

**Solution Options**:

1. **Option A: Python Subprocess (Simple)**
   ```java
   ProcessBuilder pb = new ProcessBuilder(
       "python", "-c", 
       "import pickle; pickle.load(...)"
   );
   ```
   ✅ Simple | ❌ Slow | ❌ System dependency

2. **Option B: ONNX Model (Best)**
   ```java
   // Convert model.pkl to model.onnx
   import ai.onnxruntime.OrtSession;
   
   OrtSession session = ortEnv.createSession("model.onnx");
   OrtSession.Result results = session.run(inputs);
   ```
   ✅ Fast | ✅ No Python needed | ⚠️ Requires conversion

3. **Option C: Python REST Service (Recommended)**
   ```java
   // Keep Python inference server separate
   HttpClient.newHttpClient().send(
       HttpRequest.newBuilder()
           .uri(URI.create("http://model-service:5000/predict"))
           .POST(...)
           .build()
   );
   ```
   ✅ Clean separation | ✅ Scalable | ✅ Each tech excels

**Recommendation**: Option C (Python REST Service)
- Keeps concerns separated
- Python handles ML, Java handles API/business logic
- Easier to scale independently
- Proven pattern in production

#### Step 3: Health Checks & Lifecycle (Week 1-2)

```java
@RestController
@RequestMapping("/health")
public class HealthController {
    
    @GetMapping("/live")
    public ResponseEntity<?> liveness() {
        return ResponseEntity.ok(Map.of("status", "alive"));
    }
    
    @GetMapping("/ready")
    public ResponseEntity<?> readiness() {
        if (!modelService.isReady()) {
            return ResponseEntity.status(503)
                .body(Map.of("status", "not_ready"));
        }
        return ResponseEntity.ok(Map.of("status", "ready"));
    }
}
```

#### Step 4: Spring Boot Actuator (Week 2)

```yaml
# application.yml
management:
  endpoints:
    web:
      exposure:
        include: health,metrics,prometheus
  endpoint:
    health:
      show-details: always
```

Exposes:
- `/actuator/health` - Application health
- `/actuator/metrics` - Request metrics
- `/actuator/prometheus` - Prometheus format

#### Step 5: Kubernetes Integration (Week 2-3)

```yaml
# kubernetes/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: iris-api
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  
  template:
    spec:
      initContainers:
      - name: model-loader
        image: alpine:latest
        command:
          - wget
          - https://storage.blob.core.windows.net/models/model-1.0.0.pkl
          - -O
          - /models/model.pkl
        volumeMounts:
        - name: models
          mountPath: /models
      
      containers:
      - name: iris-api
        image: myregistry.azurecr.io/iris-spring-boot:1.0.0
        
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
        
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 5
        
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
        - name: MODEL_PYTHON_SERVICE_URL
          value: http://model-inference-service:5000
      
      volumes:
      - name: models
        emptyDir: {}
```

```yaml
# kubernetes/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: model-config
data:
  version: "1.0.0"
  model-source: "https://storage.blob.core.windows.net/models"
```

```yaml
# kubernetes/secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: api-secrets
type: Opaque
stringData:
  api-key: your-secret-key-123
```

### Testing Plan

- [ ] Unit tests (JUnit 5)
- [ ] Integration tests (TestContainers)
- [ ] Load tests (JMeter)
- [ ] Kubernetes dry-run
- [ ] AKS deployment in dev environment

### Success Criteria

- ✅ Same API contract as v2 (same responses)
- ✅ Passes same test suite
- ✅ Faster response times
- ✅ Deployable to AKS
- ✅ Metrics exposed via Prometheus
- ✅ Health checks working

---

## 🌟 Future: Phase 3 (v4) - AKS Production

### Timeline: 4-6 weeks after v3

### Goals

- [ ] Multi-region deployment
- [ ] Auto-scaling based on metrics
- [ ] CI/CD with GitHub Actions
- [ ] Model retraining pipeline
- [ ] Monitoring with Application Insights
- [ ] Disaster recovery setup

### Architecture

```
┌─────────────────────────────────────────────────────┐
│          Azure Global Load Balancer                 │
└────┬──────────────────────────────────────┬─────────┘
     │                                      │
     ▼                                      ▼
┌──────────────────────┐        ┌──────────────────────┐
│  AKS East US         │        │  AKS West Europe     │
│  iris-api (3 pods)   │        │  iris-api (3 pods)   │
│  + model-inference   │        │  + model-inference   │
└──────────────────────┘        └──────────────────────┘
     │                                      │
     └──────────────────┬───────────────────┘
                        ▼
        ┌─────────────────────────────────┐
        │   Azure ML Model Registry       │
        │   (Central model storage)       │
        └─────────────────────────────────┘
```

### Key Components

1. **Global Load Balancer**: Traffic routing across regions
2. **Model Registry**: Central storage with versioning
3. **Retraining Pipeline**: Automated model updates
4. **Monitoring**: Application Insights + Prometheus
5. **CI/CD**: GitHub Actions workflows
6. **Disaster Recovery**: Backup & failover

---

## 📋 Checklist: What to Do Next

### Immediate (Next Meeting)

- [ ] Test v2 in your environment
  ```bash
  cd v2/iris-azure-ml
  pip install -r api/requirements.txt
  uvicorn api.app:app --reload
  ```
- [ ] Verify all health checks work
- [ ] Try model registry with different backends
- [ ] Review test plan and run tests

### Week 2-3: Start v3 Planning

- [ ] Evaluate Python model execution options
  - ONNX conversion feasibility
  - Python REST service vs direct integration
- [ ] Start Spring Boot project scaffold
- [ ] Plan Java model registry implementation

### Week 4+: v3 Development

- [ ] Spring Boot API implementation
- [ ] Model integration tests
- [ ] Kubernetes manifests
- [ ] AKS deployment testing

---

## 🎯 Key Decisions Made

| Decision | Rationale |
|----------|-----------|
| **Model as separate service (v3)** | Separation of concerns, Python optimized for ML, Java for orchestration |
| **Kubernetes init containers** | Download model before pod is ready to serve traffic |
| **Config via ConfigMap/Secrets** | Easy model version updates without redeployment |
| **Multiple registry backends** | Flexibility: local dev, Azure prod, MLflow enterprise |
| **Health check separation** | Liveness (is it alive?) vs Readiness (is it ready?) |
| **Hybrid architecture first** | Validate pattern before full Java migration |

---

## 📚 References

- [Spring Boot Kubernetes Integration](https://spring.io/blog/2021/08/11/spring-boot-docker-applications)
- [ONNX Runtime Java](https://onnxruntime.ai/docs/get-started/with-java.html)
- [Kubernetes Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
- [AKS Best Practices](https://learn.microsoft.com/en-us/azure/aks/best-practices)
- [Azure Container Registry](https://learn.microsoft.com/en-us/azure/container-registry/)

---

## 🤝 Questions & Discussion

1. **Python Model Execution**: Do you prefer ONNX conversion or Python service?
2. **Retraining**: How often do models get updated? (daily, weekly, on-demand?)
3. **Compliance**: Any regulatory requirements for model versioning/audit logs?
4. **Scale**: Expected RPS and concurrent users?
5. **Multi-region**: Is disaster recovery requirement for v3 or v4?

---

**Status**: ✅ v2 Complete | 🚀 Ready for v3 Planning
