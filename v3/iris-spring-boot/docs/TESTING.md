# Phase 2 Testing Guide

## 🧪 Complete Test Scenarios

### Prerequisites
- Docker & Docker Compose installed
- `curl` or `jq` for testing (or Postman)
- Models directory with `model.pkl` present

### Scenario 1: Start Services

```bash
cd v3/iris-spring-boot

# Start both services
docker-compose up -d

# Verify status
docker-compose ps

# Expected output:
# STATUS            PORTS
# Up (healthy)      inference-service
# Up (healthy)      api-service
```

### Scenario 2: Health Checks

```bash
# Test 1: Liveness (should always return 200)
echo "=== Test 1: Liveness Probe ==="
curl -v http://localhost:8080/health/live

# Test 2: Readiness (depends on inference service)
echo "=== Test 2: Readiness Probe ==="
curl -v http://localhost:8080/health/ready

# Test 3: Legacy health endpoint
echo "=== Test 3: Health Endpoint ==="
curl -v http://localhost:8080/health
```

### Scenario 3: Valid Predictions

```bash
API_KEY="test123"

# Prediction 1: Setosa (small flowers)
echo "=== Test 3a: Setosa Classification ==="
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: ${API_KEY}" \
  -d '{
    "sepal_length": 5.1,
    "sepal_width": 3.5,
    "petal_length": 1.4,
    "petal_width": 0.2
  }' | jq .

# Expected: predicted_class_id: 0, predicted_class_name: "setosa"

# Prediction 2: Versicolor (medium flowers)
echo "=== Test 3b: Versicolor Classification ==="
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: ${API_KEY}" \
  -d '{
    "sepal_length": 6.2,
    "sepal_width": 2.9,
    "petal_length": 4.3,
    "petal_width": 1.3
  }' | jq .

# Expected: predicted_class_id: 1, predicted_class_name: "versicolor"

# Prediction 3: Virginica (large flowers)
echo "=== Test 3c: Virginica Classification ==="
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: ${API_KEY}" \
  -d '{
    "sepal_length": 7.9,
    "sepal_width": 3.8,
    "petal_length": 6.4,
    "petal_width": 2.0
  }' | jq .

# Expected: predicted_class_id: 2, predicted_class_name: "virginica"
```

### Scenario 4: Validation Errors

```bash
API_KEY="test123"

# Test 4a: Missing field
echo "=== Test 4a: Missing Field ==="
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: ${API_KEY}" \
  -d '{
    "sepal_length": 5.1,
    "sepal_width": 3.5
  }'

# Expected: 400 Bad Request

# Test 4b: Invalid value (> 10)
echo "=== Test 4b: Out of Range ==="
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: ${API_KEY}" \
  -d '{
    "sepal_length": 100,
    "sepal_width": 3.5,
    "petal_length": 1.4,
    "petal_width": 0.2
  }'

# Expected: 400 Bad Request

# Test 4c: Negative value
echo "=== Test 4c: Negative Value ==="
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: ${API_KEY}" \
  -d '{
    "sepal_length": -5.1,
    "sepal_width": 3.5,
    "petal_length": 1.4,
    "petal_width": 0.2
  }'

# Expected: 400 Bad Request

# Test 4d: Non-numeric value
echo "=== Test 4d: Non-Numeric Value ==="
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: ${API_KEY}" \
  -d '{
    "sepal_length": "invalid",
    "sepal_width": 3.5,
    "petal_length": 1.4,
    "petal_width": 0.2
  }'

# Expected: 400 Bad Request
```

### Scenario 5: Authentication

```bash
# Test 5a: Missing API key (should fail if configured)
echo "=== Test 5a: Missing API Key ==="
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -d '{
    "sepal_length": 5.1,
    "sepal_width": 3.5,
    "petal_length": 1.4,
    "petal_width": 0.2
  }'

# Expected: 401 Unauthorized

# Test 5b: Invalid API key
echo "=== Test 5b: Invalid API Key ==="
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: wrong-key" \
  -d '{
    "sepal_length": 5.1,
    "sepal_width": 3.5,
    "petal_length": 1.4,
    "petal_width": 0.2
  }'

# Expected: 401 Unauthorized

# Test 5c: Correct API key
echo "=== Test 5c: Correct API Key ==="
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: test123" \
  -d '{
    "sepal_length": 5.1,
    "sepal_width": 3.5,
    "petal_length": 1.4,
    "petal_width": 0.2
  }'

# Expected: 200 OK with prediction
```

### Scenario 6: Service Unavailability

```bash
# Test 6a: Stop inference service
echo "=== Test 6a: Stop Inference Service ==="
docker-compose stop inference-service

# Try to get readiness
echo "=== Readiness Check (service down) ==="
curl -v http://localhost:8080/health/ready

# Expected: 503 Service Unavailable

# Try to predict
echo "=== Prediction (service down) ==="
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: test123" \
  -d '{
    "sepal_length": 5.1,
    "sepal_width": 3.5,
    "petal_length": 1.4,
    "petal_width": 0.2
  }'

# Expected: 503 Service Unavailable

# Restart service
echo "=== Restart Inference Service ==="
docker-compose start inference-service
docker-compose exec inference-service curl http://localhost:5000/health/ready

# Wait for readiness
sleep 5

# Try readiness again (should be OK)
echo "=== Readiness Check (service restored) ==="
curl http://localhost:8080/health/ready
```

### Scenario 7: Monitoring & Metrics

```bash
# Test 7a: Actuator health
echo "=== Test 7a: Actuator Health ==="
curl http://localhost:8080/actuator/health | jq .

# Test 7b: Metrics
echo "=== Test 7b: Metrics ==="
curl http://localhost:8080/actuator/metrics | jq .

# Test 7c: Prometheus format
echo "=== Test 7c: Prometheus Metrics ==="
curl http://localhost:8080/actuator/prometheus

# Test 7d: Specific metric
echo "=== Test 7d: HTTP Requests Metric ==="
curl http://localhost:8080/actuator/metrics/http.server.requests | jq .
```

### Scenario 8: Log Analysis

```bash
# View all logs
docker-compose logs

# Follow Java API logs
docker-compose logs -f api-service

# Follow Python service logs
docker-compose logs -f inference-service

# Check logs for errors
docker-compose logs | grep ERROR

# Export logs
docker-compose logs > combined_logs.txt
```

### Scenario 9: Performance Test

```bash
# Simple load test (10 requests)
echo "=== Performance Test: 10 Requests ==="
for i in {1..10}; do
  time curl -X POST http://localhost:8080/predict \
    -H "Content-Type: application/json" \
    -H "X-API-Key: test123" \
    -d '{"sepal_length": 5.1, "sepal_width": 3.5, "petal_length": 1.4, "petal_width": 0.2}' \
    -w "\nResponse Time: %{time_total}s\n"
done
```

### Scenario 10: Cleanup

```bash
# Stop services
docker-compose down

# Remove volumes
docker-compose down -v

# Remove images
docker-compose down --rmi local

# Clean up containers
docker system prune -a
```

## Expected Response Formats

### Success Response (200 OK)
```json
{
  "predicted_class_id": 0,
  "predicted_class_name": "setosa",
  "probabilities": [0.97, 0.03, 0.0],
  "model_version": "1.0.0",
  "timestamp": "2024-01-15T10:30:45.123456"
}
```

### Health Ready Response (200 OK)
```json
{
  "status": "ready",
  "ready": true,
  "model_loaded": true,
  "model_version": "1.0.0",
  "model_path": "models/model.pkl",
  "loaded_at": "2024-01-15T10:30:45.123456"
}
```

### Health Not Ready Response (503 Service Unavailable)
```json
{
  "status": "not_ready",
  "ready": false,
  "model_loaded": false,
  "model_version": "1.0.0",
  "model_path": "models/model.pkl",
  "error": "Inference service not ready"
}
```

### Validation Error Response (400 Bad Request)
```json
{
  "error": "Validation failed",
  "message": "sepal_length must be between 0 and 10"
}
```

### Unauthorized Response (401 Unauthorized)
```json
{
  "error": "Unauthorized",
  "message": "Invalid or missing API key"
}
```

## Troubleshooting During Tests

### Issue: Connection refused
```bash
# Check services
docker-compose ps

# Check ports
netstat -tulpn | grep 8080
netstat -tulpn | grep 5000

# View logs
docker-compose logs api-service
```

### Issue: Model not found
```bash
# Check model file
ls -la models/

# Verify path in .env
cat inference-service/.env

# Check inference service logs
docker-compose logs inference-service | grep "Model"
```

### Issue: Slow responses
```bash
# Check CPU usage
docker stats

# Check memory
docker ps --format "table {{.Names}}\t{{.MemUsage}}"

# Profile with curl timing
curl -w "@curl-format.txt" -o /dev/null http://localhost:8080/health/live
```

## Test Automation Script

Save as `test_api.sh`:

```bash
#!/bin/bash

API_URL="http://localhost:8080"
API_KEY="test123"
PASSED=0
FAILED=0

test_endpoint() {
  local name=$1
  local method=$2
  local endpoint=$3
  local data=$4
  local expected_code=$5

  echo -n "Testing $name... "
  
  if [ -z "$data" ]; then
    response=$(curl -s -w "\n%{http_code}" -X $method "${API_URL}${endpoint}")
  else
    response=$(curl -s -w "\n%{http_code}" -X $method "${API_URL}${endpoint}" \
      -H "Content-Type: application/json" \
      -H "X-API-Key: ${API_KEY}" \
      -d "$data")
  fi
  
  http_code=$(echo "$response" | tail -1)
  
  if [ "$http_code" = "$expected_code" ]; then
    echo "✅ PASSED (HTTP $http_code)"
    ((PASSED++))
  else
    echo "❌ FAILED (Expected $expected_code, got $http_code)"
    ((FAILED++))
  fi
}

# Run tests
test_endpoint "Liveness" "GET" "/health/live" "" "200"
test_endpoint "Readiness" "GET" "/health/ready" "" "200"
test_endpoint "Prediction" "POST" "/predict" '{"sepal_length": 5.1, "sepal_width": 3.5, "petal_length": 1.4, "petal_width": 0.2}' "200"
test_endpoint "Missing Field" "POST" "/predict" '{"sepal_length": 5.1}' "400"
test_endpoint "Out of Range" "POST" "/predict" '{"sepal_length": 100, "sepal_width": 3.5, "petal_length": 1.4, "petal_width": 0.2}' "400"

echo ""
echo "=============================="
echo "Test Results: ${PASSED} passed, ${FAILED} failed"
echo "=============================="

exit $FAILED
```

Run with:
```bash
chmod +x test_api.sh
./test_api.sh
```
