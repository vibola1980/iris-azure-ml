# ✅ Phase 2 Validation Checklist

## 📋 Pre-Validation Requirements

- [ ] Docker & Docker Compose installed
- [ ] Git configured
- [ ] Port 8080 available (Java API)
- [ ] Port 5000 available (Python service)
- [ ] At least 2GB free disk space
- [ ] `curl` or equivalent HTTP client available

---

## 🚀 Validation Steps

### Step 1: Verify File Structure (5 minutes)

```bash
cd c:\DESENV\workspace\testeMLIrisAzure\iris-azure-ml\v3\iris-spring-boot

# Check key files exist
ls pom.xml           # ✅ should exist
ls docker-compose.yml # ✅ should exist
ls Dockerfile        # ✅ should exist

# Check directories
ls src/main/java/com/iris/controller/     # ✅ should have 2 .java files
ls inference-service/                     # ✅ should have app.py, requirements.txt
ls kubernetes/                            # ✅ empty (Phase 3)

# Check documentation
ls README.md         # ✅ should exist
ls TESTING.md        # ✅ should exist
ls NEXT_STEPS.md     # ✅ should exist
```

**Expected Output:**
```
✅ All files present
✅ pom.xml valid (Maven format)
✅ Docker files valid (Dockerfile syntax)
✅ Java source files exist
✅ Python service files exist
✅ Documentation complete
```

### Step 2: Build Java Project (5-10 minutes)

```bash
# Build with Maven
mvn clean package

# Expected: BUILD SUCCESS
# Output: target/iris-classifier-api-3.0.0.jar
```

**Validation:**
- [ ] Build completes without errors
- [ ] No compilation errors
- [ ] JAR file created in target/
- [ ] All tests pass (7 tests)

### Step 3: Start Docker Compose (10 minutes)

```bash
# Start services
docker-compose up -d

# Check status
docker-compose ps

# Expected output:
# CONTAINER ID    IMAGE                    STATUS            PORTS
# xxxxx            iris-inference-service   Up (healthy)      5000/tcp
# xxxxx            iris-api-service         Up (healthy)      8080/tcp
```

**Validation:**
- [ ] Both services start
- [ ] No error messages
- [ ] Status shows "Up (healthy)"
- [ ] Ports are correct

### Step 4: Health Checks (5 minutes)

#### Test 1: Liveness Probe

```bash
curl -v http://localhost:8080/health/live

# Expected:
# HTTP/1.1 200 OK
# {"status":"alive"}
```

**Validation:**
- [ ] HTTP 200 status
- [ ] Response: `{"status":"alive"}`
- [ ] Response time < 100ms

#### Test 2: Readiness Probe

```bash
curl -v http://localhost:8080/health/ready

# Expected:
# HTTP/1.1 200 OK
# {"status":"ready","ready":true,"model_loaded":true,...}
```

**Validation:**
- [ ] HTTP 200 status
- [ ] `ready: true`
- [ ] `model_loaded: true`
- [ ] Response time < 100ms

### Step 5: API Predictions (5 minutes)

#### Test 1: Valid Prediction

```bash
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: test123" \
  -d '{
    "sepal_length": 5.1,
    "sepal_width": 3.5,
    "petal_length": 1.4,
    "petal_width": 0.2
  }'

# Expected:
# HTTP/1.1 200 OK
# {
#   "predicted_class_id": 0,
#   "predicted_class_name": "setosa",
#   "probabilities": [0.97, 0.03, 0.0],
#   "model_version": "1.0.0",
#   "timestamp": "2024-01-15T..."
# }
```

**Validation:**
- [ ] HTTP 200 status
- [ ] `predicted_class_name` is one of: setosa, versicolor, virginica
- [ ] `probabilities` is an array of 3 floats
- [ ] All fields present
- [ ] Response time < 200ms

#### Test 2: Different Class Prediction

```bash
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: test123" \
  -d '{
    "sepal_length": 7.9,
    "sepal_width": 3.8,
    "petal_length": 6.4,
    "petal_width": 2.0
  }'

# Expected: virginica (class_id: 2)
```

**Validation:**
- [ ] HTTP 200 status
- [ ] `predicted_class_id` is 2
- [ ] `predicted_class_name` is "virginica"

#### Test 3: Invalid Data (Validation Error)

```bash
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: test123" \
  -d '{
    "sepal_length": 100,
    "sepal_width": 3.5,
    "petal_length": 1.4,
    "petal_width": 0.2
  }'

# Expected: HTTP/1.1 400 Bad Request
```

**Validation:**
- [ ] HTTP 400 status
- [ ] Error message returned
- [ ] No stack trace in response

#### Test 4: Missing API Key

```bash
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -d '{
    "sepal_length": 5.1,
    "sepal_width": 3.5,
    "petal_length": 1.4,
    "petal_width": 0.2
  }'

# Expected: HTTP/1.1 401 Unauthorized
```

**Validation:**
- [ ] HTTP 401 status
- [ ] Request rejected

### Step 6: Run Unit Tests (5 minutes)

```bash
# Run tests
mvn test

# Expected: BUILD SUCCESS with 7 tests passed
```

**Expected Output:**
```
-------------------------------------------------------
 T E S T S
-------------------------------------------------------
Running com.iris.controller.HealthControllerTest
Tests run: 4, Failures: 0, Errors: 0, Skipped: 0

Running com.iris.controller.PredictionControllerTest
Tests run: 3, Failures: 0, Errors: 0, Skipped: 0

-------------------------------------------------------
BUILD SUCCESS
```

**Validation:**
- [ ] All 7 tests pass
- [ ] No failures or errors
- [ ] No skipped tests
- [ ] Build SUCCESS message

### Step 7: Log Analysis (5 minutes)

```bash
# View Java API logs
docker-compose logs api-service | tail -30

# View Python service logs
docker-compose logs inference-service | tail -30

# Check for errors
docker-compose logs | grep ERROR

# Expected: No critical errors
```

**Validation:**
- [ ] No ERROR messages
- [ ] No exceptions
- [ ] Service startup messages present
- [ ] Health check messages present

### Step 8: Performance Test (5 minutes)

```bash
# Simple performance test: 5 requests
for i in {1..5}; do
  time curl -X POST http://localhost:8080/predict \
    -H "Content-Type: application/json" \
    -H "X-API-Key: test123" \
    -d '{"sepal_length": 5.1, "sepal_width": 3.5, "petal_length": 1.4, "petal_width": 0.2}' \
    -w "\nTime: %{time_total}s\n" \
    -o /dev/null -s
done

# Expected: Average time < 200ms
```

**Validation:**
- [ ] All requests succeed (HTTP 200)
- [ ] Average response time < 200ms
- [ ] No timeouts
- [ ] Consistent performance

### Step 9: Container Health (5 minutes)

```bash
# Check container stats
docker stats --no-stream

# Expected resource usage:
# - Java API: <300MB RAM
# - Python Service: <200MB RAM
```

**Validation:**
- [ ] Both containers running
- [ ] Reasonable memory usage
- [ ] CPU usage normal (0-20% at idle)
- [ ] No memory leaks evident

### Step 10: Cleanup (2 minutes)

```bash
# Stop containers
docker-compose down

# Expected: Both services stop cleanly
```

**Validation:**
- [ ] Containers stop without errors
- [ ] No orphaned containers
- [ ] Volumes cleaned up

---

## 📊 Validation Results Template

```
PHASE 2 VALIDATION RESULTS
==========================
Date: ____________________
Tester: __________________

RESULTS:
--------
File Structure:           [ PASS / FAIL ]
Maven Build:              [ PASS / FAIL ]
Docker Compose Start:     [ PASS / FAIL ]
Liveness Probe:           [ PASS / FAIL ]
Readiness Probe:          [ PASS / FAIL ]
API Predictions:          [ PASS / FAIL ]
Input Validation:         [ PASS / FAIL ]
Authentication:           [ PASS / FAIL ]
Unit Tests:               [ PASS / FAIL ]
Logs (no errors):         [ PASS / FAIL ]
Performance (< 200ms):    [ PASS / FAIL ]
Container Health:         [ PASS / FAIL ]
Cleanup:                  [ PASS / FAIL ]

OVERALL SCORE: ____/13

ISSUES FOUND:
1. ___________________________
2. ___________________________
3. ___________________________

NOTES:
_______________________________
_______________________________
_______________________________

RECOMMENDATION:
[ ] Ready for Phase 3
[ ] Ready with minor fixes
[ ] Needs rework
```

---

## 🔍 Troubleshooting During Validation

### Issue: Docker build fails
```bash
# Solution 1: Clean build
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# Solution 2: Check disk space
docker system prune -a
```

### Issue: Port already in use
```bash
# Find process using port
netstat -tulpn | grep 8080
netstat -tulpn | grep 5000

# Solution: Kill process or change ports in docker-compose.yml
```

### Issue: Services not healthy
```bash
# Check logs
docker-compose logs

# Restart
docker-compose restart

# Check specific service
docker-compose logs inference-service
```

### Issue: Prediction fails
```bash
# Check service connectivity
curl http://localhost:5000/health/ready

# Check model file
ls -la models/model.pkl

# Check environment variables
docker-compose config | grep MODEL_PATH
```

### Issue: Tests fail
```bash
# Run with verbose output
mvn test -X

# Run specific test
mvn test -Dtest=HealthControllerTest

# Check Maven cache
mvn clean -DremoveSnapshots
```

---

## ✅ Sign-Off

When all validations pass:

```
Phase 2 Validation: ✅ APPROVED
Status: Ready for Phase 3
Date: ________________
Validated by: ________________
```

---

## 📚 Next Actions After Successful Validation

1. ✅ **All tests pass?**
   - Proceed to Phase 3 planning
   - Create Kubernetes manifests
   - Setup CI/CD pipeline

2. ❌ **Issues found?**
   - Document in GitHub Issues
   - Fix issues
   - Re-validate

---

**Expected Duration: 60-90 minutes total**

Start validation whenever ready! 🚀
