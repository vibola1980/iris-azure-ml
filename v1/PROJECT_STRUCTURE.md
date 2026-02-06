# 📊 PROJECT STRUCTURE - v2 Hybrid Architecture

```
📦 iris-azure-ml/
│
├── 📄 ROOT DOCUMENTATION
│   ├── QUICK_REFERENCE.md          ⭐ Start here! (3-minute quickstart)
│   ├── PHASE1_SUMMARY.md           (What changed in v2)
│   └── ARCHITECTURE.md             (Original architecture)
│
├── 📁 v2/iris-azure-ml/            (🆕 PHASE 1 - HYBRID PATTERN)
│   │
│   ├── 📄 SETUP & DOCUMENTATION
│   │   ├── README.md               (Complete setup guide)
│   │   ├── ROADMAP.md              (v3 & v4 planning)
│   │   ├── TEST_PLAN.md            (10 test scenarios)
│   │   ├── .env.example            (Configuration template)
│   │   └── PHASE1_SUMMARY.md       (What changed)
│   │
│   ├── 🐍 API (FastAPI)
│   │   ├── app.py                  (Main application - ENHANCED ✨)
│   │   ├── model_registry.py       (🆕 Registry abstraction)
│   │   ├── __init__.py
│   │   └── requirements.txt         (Dependencies - UPDATED)
│   │
│   ├── 🗂️ Models
│   │   ├── .gitkeep
│   │   └── model-1.0.0.pkl        (Place trained model here)
│   │
│   ├── 🧪 Tests
│   │   ├── __init__.py
│   │   └── test_api.py             (Unit tests)
│   │
│   ├── 🐳 Docker
│   │   ├── Dockerfile              (Container image)
│   │   └── docker-compose.yml      (🆕 Enhanced - with model loader)
│   │
│   ├── ⚙️ Configuration
│   │   ├── .env                    (Your local config)
│   │   └── .env.example            (🆕 Template)
│   │
│   └── .gitignore                  (Git configuration)
│
├── 📁 api/                         (Original v1 - Keep for reference)
│   ├── app.py
│   ├── requirements.txt
│   └── README.md
│
├── 📁 infra/                       (Terraform files)
│   ├── main.tf
│   ├── variables.tf
│   └── ...
│
├── 📁 scripts/                     (Utility scripts)
│   ├── test_api.ps1
│   └── ...
│
└── 📁 training/                    (Model training)
    ├── train.py
    ├── requirements.txt
    └── artifacts/
        └── model.pkl              (Trained model)
```

---

## 🎯 What's New in v2 (Phase 1)

### ✨ Enhanced Files

| File | Before | After | Change |
|------|--------|-------|--------|
| **app.py** | 53 lines | 230+ lines | ⬆️ Lifecycle, health checks, logging |
| **requirements.txt** | 4 deps | 7 deps (pinned) | ⬆️ Explicit versions |
| **README.md** | 91 lines | 350+ lines | ⬆️ Complete guide |
| **docker-compose.yml** | Simple | Complex | ⬆️ Model loader, logging |

### 🆕 New Files

| File | Purpose | Lines |
|------|---------|-------|
| **model_registry.py** | Abstract registry + 3 backends | 300+ |
| **TEST_PLAN.md** | 10 comprehensive tests | 200+ |
| **.env.example** | Configuration reference | 50+ |
| **ROADMAP.md** | v3 & v4 planning | 400+ |
| **PHASE1_SUMMARY.md** | Changes summary | 400+ |
| **QUICK_REFERENCE.md** | Quick start guide | 250+ |

---

## 🚀 Starting Points

### For Quick Start
👉 **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** (5 min read)
- Commands to run right now
- Endpoint cheat sheet
- Common tasks

### For Complete Setup
👉 **[v2/iris-azure-ml/README.md](v2/iris-azure-ml/README.md)** (20 min read)
- Full setup guide
- All endpoints documented
- Kubernetes deployment examples

### For Testing
👉 **[v2/iris-azure-ml/TEST_PLAN.md](v2/iris-azure-ml/TEST_PLAN.md)** (30 min)
- 10 test scenarios with cURL
- Expected responses
- Success checklist

### For Future Planning
👉 **[v2/iris-azure-ml/ROADMAP.md](v2/iris-azure-ml/ROADMAP.md)** (30 min read)
- v3 Java/Spring Boot design
- v4 AKS production vision
- Key architectural decisions

### For Understanding Changes
👉 **[v2/iris-azure-ml/PHASE1_SUMMARY.md](v2/iris-azure-ml/PHASE1_SUMMARY.md)** (20 min read)
- What changed in v2
- Before/after comparisons
- File modifications

---

## 📖 Reading Order (Recommended)

### Day 1: Understand the Changes
1. [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Get the big picture (5 min)
2. [PHASE1_SUMMARY.md](v2/iris-azure-ml/PHASE1_SUMMARY.md) - See what changed (20 min)
3. [v2/iris-azure-ml/README.md](v2/iris-azure-ml/README.md) - Read the full guide (20 min)

### Day 2: Run & Test
1. Follow [QUICK_REFERENCE.md](QUICK_REFERENCE.md) to run locally (15 min)
2. Follow [TEST_PLAN.md](v2/iris-azure-ml/TEST_PLAN.md) to test all endpoints (30 min)
3. Try Docker with `docker-compose up` (10 min)

### Day 3: Plan Next Phase
1. [ROADMAP.md](v2/iris-azure-ml/ROADMAP.md) - Review v3 planning (30 min)
2. Decide on Python model execution strategy (ONNX vs REST service)
3. Start v3 Spring Boot scaffold

---

## 🎓 Key Architecture Changes

### Before (v1 + Current)
```
FastAPI
├─ Single health endpoint
├─ Loads model on first request
└─ No version tracking
```

### After (v2 - Your Current State)
```
FastAPI (Enhanced)
├─ Lifecycle management (startup/shutdown)
├─ 3 health endpoints (live/ready/legacy)
├─ Model Registry abstraction
│  ├─ LocalFileSystem
│  ├─ AzureBlobStorage
│  └─ MLflow
├─ Version tracking
├─ Structured logging
└─ Kubernetes-ready probes
```

### Future (v3)
```
Spring Boot
├─ Same API contract
├─ Model Registry in Java
├─ Spring Boot Actuator
├─ Native Kubernetes integration
└─ Metrics/Monitoring ready
```

---

## ✅ Verification Checklist

### Code Quality
- ✅ Type hints on all functions
- ✅ Docstrings on all endpoints
- ✅ Structured logging
- ✅ Error handling

### Documentation
- ✅ README.md (complete)
- ✅ ROADMAP.md (future planning)
- ✅ TEST_PLAN.md (test scenarios)
- ✅ Code comments

### Kubernetes Ready
- ✅ `/health/live` endpoint
- ✅ `/health/ready` endpoint
- ✅ Health check responses
- ✅ Graceful shutdown
- ✅ Environment-driven config

### Testing
- ✅ 10 test scenarios defined
- ✅ cURL examples provided
- ✅ Error cases covered
- ✅ Success checklist included

---

## 🔄 Next Actions

### This Week
```
[ ] Review QUICK_REFERENCE.md
[ ] Run v2 locally (3 min)
[ ] Test all 4 endpoints
[ ] Try docker-compose
[ ] Read PHASE1_SUMMARY.md
```

### Next Week
```
[ ] Read ROADMAP.md
[ ] Decide v3 strategy (ONNX vs REST)
[ ] Plan Spring Boot scaffold
[ ] Review registry backends
[ ] Test with Azure Storage (optional)
```

### Planning
```
[ ] When to start v3? (Week 2 or 3?)
[ ] Which registry backend for production?
[ ] Model retraining frequency?
[ ] SLA requirements?
[ ] Multi-region needed?
```

---

## 📞 Quick Links

| Document | Purpose | Read Time |
|----------|---------|-----------|
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | Quick start & commands | 5 min |
| [v2/README.md](v2/iris-azure-ml/README.md) | Full setup guide | 20 min |
| [TEST_PLAN.md](v2/iris-azure-ml/TEST_PLAN.md) | Test scenarios | 30 min |
| [ROADMAP.md](v2/iris-azure-ml/ROADMAP.md) | Future phases | 30 min |
| [PHASE1_SUMMARY.md](v2/iris-azure-ml/PHASE1_SUMMARY.md) | What changed | 20 min |

---

## 🎯 Success Metrics

Phase 1 is **COMPLETE** when:

✅ API has Kubernetes-ready health checks
✅ Model loading is abstracted (multiple backends)
✅ Version tracking in responses
✅ Configuration is environment-driven
✅ All endpoints documented
✅ Test plan created
✅ Docker deployment works
✅ Roadmap for v3 created

**Status**: ✅ ALL COMPLETE

---

## 📈 Project Timeline

```
Phase 1 (DONE) ✅
  └─ FastAPI + Hybrid Pattern
     └─ 8 improvements implemented

Phase 2 (NEXT) 🚀
  └─ Java/Spring Boot
     └─ Same API, production-grade

Phase 3 (FUTURE) 🌟
  └─ AKS Production
     └─ Multi-region, auto-scaling
```

---

**Welcome to v2! Ready to explore? Start with [QUICK_REFERENCE.md](QUICK_REFERENCE.md) 🚀**
