# 🎯 INDEX - Complete Documentation Map

## 📍 Start Here!

**New to this project?**
1. Read [QUICK_REFERENCE.md](QUICK_REFERENCE.md) (5 minutes)
2. Run the quick start commands
3. Then explore the detailed docs below

---

## 📚 Documentation by Purpose

### 🚀 Getting Started

| Document | Content | Time |
|----------|---------|------|
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | Start in 3 minutes, command cheatsheet | 5 min |
| [v2/iris-azure-ml/README.md](v2/iris-azure-ml/README.md) | Complete setup & deployment guide | 20 min |
| [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) | File organization overview | 10 min |

### 🧪 Testing & Validation

| Document | Content | Time |
|----------|---------|------|
| [v2/iris-azure-ml/TEST_PLAN.md](v2/iris-azure-ml/TEST_PLAN.md) | 10 test scenarios with cURL examples | 30 min |
| [v2/iris-azure-ml/.env.example](v2/iris-azure-ml/.env.example) | Configuration reference | 5 min |

### 📖 Understanding the Changes

| Document | Content | Time |
|----------|---------|------|
| [v2/iris-azure-ml/PHASE1_SUMMARY.md](v2/iris-azure-ml/PHASE1_SUMMARY.md) | What changed in v2, before/after | 20 min |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Original solution architecture | 15 min |

### 🗺️ Future Roadmap

| Document | Content | Time |
|----------|---------|------|
| [v2/iris-azure-ml/ROADMAP.md](v2/iris-azure-ml/ROADMAP.md) | v3 (Java/Spring Boot) & v4 (AKS) planning | 30 min |

---

## 🔧 Code Reference

### API Implementation

| File | Purpose | Type | Status |
|------|---------|------|--------|
| [v2/iris-azure-ml/api/app.py](v2/iris-azure-ml/api/app.py) | FastAPI application | Python | ✅ Enhanced |
| [v2/iris-azure-ml/api/model_registry.py](v2/iris-azure-ml/api/model_registry.py) | Model Registry abstraction | Python | ✅ New |
| [v2/iris-azure-ml/api/requirements.txt](v2/iris-azure-ml/api/requirements.txt) | Python dependencies | Pip | ✅ Updated |

### Testing

| File | Purpose | Type | Status |
|------|---------|------|--------|
| [v2/iris-azure-ml/tests/test_api.py](v2/iris-azure-ml/tests/test_api.py) | Unit tests | Python | 📝 Ready for updates |
| [v2/iris-azure-ml/TEST_PLAN.md](v2/iris-azure-ml/TEST_PLAN.md) | Manual test scenarios | Documentation | ✅ Complete |

### Configuration

| File | Purpose | Type | Status |
|------|---------|------|--------|
| [v2/iris-azure-ml/.env.example](v2/iris-azure-ml/.env.example) | Environment variables template | Config | ✅ New |
| [v2/iris-azure-ml/.env](v2/iris-azure-ml/.env) | Your local configuration | Config | 📝 To create |
| [v2/iris-azure-ml/docker-compose.yml](v2/iris-azure-ml/docker-compose.yml) | Local Docker development | Docker | ✅ Enhanced |
| [v2/iris-azure-ml/Dockerfile](v2/iris-azure-ml/Dockerfile) | Container image definition | Docker | 📝 Verify |

---

## 📊 Learning Paths

### Path A: Quick Developer (30 min)
1. [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - 5 min
2. Copy `.env.example` → `.env`
3. Run `uvicorn api.app:app --reload`
4. Test endpoints with cURL (10 min)
5. Done! Ready to develop

### Path B: Complete Understanding (2 hours)
1. [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - 5 min
2. [PHASE1_SUMMARY.md](v2/iris-azure-ml/PHASE1_SUMMARY.md) - 20 min
3. [v2/README.md](v2/iris-azure-ml/README.md) - 20 min
4. Run locally & test - 20 min
5. [TEST_PLAN.md](v2/iris-azure-ml/TEST_PLAN.md) - 30 min
6. [ROADMAP.md](v2/iris-azure-ml/ROADMAP.md) - 30 min

### Path C: Production Deployment (4 hours)
1. Complete Path B (2 hours)
2. [v2/README.md](v2/iris-azure-ml/README.md) - Kubernetes section (30 min)
3. Deploy docker-compose locally (30 min)
4. Decide on registry backend (Azure/MLflow) (30 min)
5. Create Kubernetes manifests (1 hour)

### Path D: Planning v3 (1 hour)
1. [ROADMAP.md](v2/iris-azure-ml/ROADMAP.md) - 30 min
2. Decide: ONNX vs Python REST service (20 min)
3. Plan Spring Boot scaffold (10 min)

---

## 🎯 By Use Case

### "I want to run the API locally"
→ [QUICK_REFERENCE.md](QUICK_REFERENCE.md) (Commands section)

### "I need to test all endpoints"
→ [TEST_PLAN.md](v2/iris-azure-ml/TEST_PLAN.md) (10 test scenarios)

### "I need to deploy to Docker"
→ [v2/README.md](v2/iris-azure-ml/README.md) (Docker section)

### "I need to deploy to Kubernetes/AKS"
→ [v2/README.md](v2/iris-azure-ml/README.md) (Kubernetes section)

### "I want to use Azure Storage for models"
→ [QUICK_REFERENCE.md](QUICK_REFERENCE.md) (Azure Storage section)

### "I want to understand what changed"
→ [PHASE1_SUMMARY.md](v2/iris-azure-ml/PHASE1_SUMMARY.md)

### "I want to see the future roadmap"
→ [ROADMAP.md](v2/iris-azure-ml/ROADMAP.md)

### "I'm new to this project"
→ [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) (Overview)

---

## 🔑 Key Concepts

### Health Checks (Kubernetes)

**Liveness Probe** - Is the container alive?
- Endpoint: `/health/live`
- Returns: `{"status": "alive"}`
- Usage: Container restart detection
- Docs: [v2/README.md](v2/iris-azure-ml/README.md#1-liveness-probe)

**Readiness Probe** - Is the app ready for traffic?
- Endpoint: `/health/ready`
- Returns: Detailed status + model info
- Usage: Traffic routing decisions
- Docs: [v2/README.md](v2/iris-azure-ml/README.md#2-readiness-probe)

### Model Registry

Abstraction for loading models from different sources:

**LocalFileSystem** - For development
- Models stored in: `./models/model-{version}.pkl`
- Docs: [api/model_registry.py](v2/iris-azure-ml/api/model_registry.py)

**AzureBlobStorage** - For production
- Models stored in: Azure Blob Storage
- Docs: [v2/README.md](v2/iris-azure-ml/README.md#2-azure-blob-storage)

**MLflow** - For enterprise
- Models stored in: MLflow Model Registry
- Docs: [v2/README.md](v2/iris-azure-ml/README.md#3-mlflow-model-registry)

---

## 🗂️ Directory Structure

```
Root
├── 📄 QUICK_REFERENCE.md          ← START HERE
├── 📄 INDEX.md                     (This file)
├── 📄 PROJECT_STRUCTURE.md
├── 📄 ARCHITECTURE.md
│
├── v2/iris-azure-ml/               (MAIN PROJECT - v2)
│   ├── 📄 README.md                (Full setup guide)
│   ├── 📄 ROADMAP.md               (Future planning)
│   ├── 📄 TEST_PLAN.md             (Test scenarios)
│   ├── 📄 PHASE1_SUMMARY.md        (What changed)
│   ├── 📄 .env.example
│   ├── 🐍 api/
│   │   ├── app.py
│   │   ├── model_registry.py
│   │   └── requirements.txt
│   ├── 🗂️ models/
│   ├── 🧪 tests/
│   ├── 🐳 Dockerfile
│   ├── 🐳 docker-compose.yml
│   └── .gitignore
│
├── api/                            (Original v1 - Reference)
├── infra/                          (Terraform files)
├── scripts/                        (Utility scripts)
└── training/                       (Model training)
```

---

## ✨ What's New in v2

**Phase 1: Hybrid Architecture** ✅ COMPLETE

8 improvements implemented:

1. ✅ Kubernetes-ready health checks
2. ✅ Model Registry abstraction (local, Azure, MLflow)
3. ✅ Version tracking in responses
4. ✅ Graceful lifecycle management
5. ✅ Structured logging
6. ✅ Enhanced error handling
7. ✅ Configuration management
8. ✅ Comprehensive documentation

**Files Modified**: 4 (app.py, requirements.txt, README.md, docker-compose.yml)
**Files Created**: 8 (model_registry.py, TEST_PLAN.md, ROADMAP.md, etc)
**Total Lines Added**: 1500+

---

## 📅 Timeline

```
✅ Phase 1 (COMPLETE)
   └─ v2 Hybrid Architecture
      └─ 8 improvements in FastAPI

🚀 Phase 2 (NEXT)
   └─ v3 Java/Spring Boot
      └─ Same API, enterprise-ready

🌟 Phase 3 (FUTURE)
   └─ v4 AKS Production
      └─ Multi-region, auto-scaling
```

---

## 🎓 External Resources

### Kubernetes & Health Checks
- [Kubernetes Health Checks](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Init Containers Pattern](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)

### FastAPI
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Lifespan Events](https://fastapi.tiangolo.com/advanced/events/)
- [Pydantic Models](https://docs.pydantic.dev/)

### Azure
- [Azure Container Registry](https://learn.microsoft.com/en-us/azure/container-registry/)
- [Azure Blob Storage](https://learn.microsoft.com/en-us/azure/storage/blobs/)
- [Azure Kubernetes Service](https://learn.microsoft.com/en-us/azure/aks/)

### MLflow
- [MLflow Model Registry](https://mlflow.org/docs/latest/model-registry.html)
- [MLflow Tracking](https://mlflow.org/docs/latest/tracking.html)

### Java/Spring Boot (for v3)
- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Spring Boot Actuator](https://spring.io/guides/gs/actuator-service/)
- [Kubernetes with Spring Boot](https://spring.io/blog/2021/08/11/spring-boot-docker-applications)

---

## 🆘 Getting Help

### Documentation Issues?
- Check [FAQ section](v2/iris-azure-ml/README.md#-troubleshooting) in README
- Review [TEST_PLAN.md](v2/iris-azure-ml/TEST_PLAN.md) for similar issues

### Running Locally?
- Follow [QUICK_REFERENCE.md](QUICK_REFERENCE.md) exactly
- Check [Troubleshooting](v2/iris-azure-ml/README.md#-troubleshooting) section

### Deployment Questions?
- [Kubernetes section](v2/iris-azure-ml/README.md#-kubernetes-deployment) in README
- [ROADMAP.md](v2/iris-azure-ml/ROADMAP.md) for planning

### Planning v3?
- Read [ROADMAP.md](v2/iris-azure-ml/ROADMAP.md) completely
- Review "Key Decisions" section

---

## ✅ Quick Checklist

Getting started? Do this:

- [ ] Clone/download the project
- [ ] Read [QUICK_REFERENCE.md](QUICK_REFERENCE.md) (5 min)
- [ ] Run `pip install -r api/requirements.txt`
- [ ] Copy `.env.example` to `.env`
- [ ] Run `uvicorn api.app:app --reload`
- [ ] Test with cURL (see [QUICK_REFERENCE.md](QUICK_REFERENCE.md))
- [ ] Read [PHASE1_SUMMARY.md](v2/iris-azure-ml/PHASE1_SUMMARY.md) (20 min)
- [ ] Try [TEST_PLAN.md](v2/iris-azure-ml/TEST_PLAN.md) (30 min)
- [ ] Plan next steps with [ROADMAP.md](v2/iris-azure-ml/ROADMAP.md)

---

## 📊 Documentation Stats

| Metric | Count |
|--------|-------|
| Documentation files | 6 |
| Code files | 3 |
| Total documentation | 2000+ lines |
| Code examples | 50+ |
| Test scenarios | 10 |
| Setup guides | 2 |

---

**Last Updated**: February 3, 2026
**Status**: Phase 1 Complete ✅ | Ready for Phase 2 🚀
**Next**: Review [ROADMAP.md](v2/iris-azure-ml/ROADMAP.md) for v3 planning

---

**Quick Links**:
- 🚀 [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- 📖 [README.md](v2/iris-azure-ml/README.md)
- 🧪 [TEST_PLAN.md](v2/iris-azure-ml/TEST_PLAN.md)
- 🗺️ [ROADMAP.md](v2/iris-azure-ml/ROADMAP.md)
- ✨ [PHASE1_SUMMARY.md](v2/iris-azure-ml/PHASE1_SUMMARY.md)
