# 🧪 Test Plan - API Health Checks & Predictions

## Setup

```bash
# 1. Instalar dependências
pip install -r api/requirements.txt

# 2. Treinar modelo (se necessário)
python training/train.py

# 3. Copiar modelo para v2
cp training/artifacts/model.pkl v2/iris-azure-ml/models/

# 4. Iniciar aplicação
cd v2/iris-azure-ml
export MODEL_PATH=models/model.pkl
export MODEL_VERSION=1.0.0
export API_KEY=test-key-123
uvicorn api.app:app --reload --host 0.0.0.0 --port 8000
```

---

## Teste 1: Liveness Probe (Container vivo?)

```bash
curl -v http://localhost:8000/health/live
```

**Resposta Esperada:**
```json
{
  "status": "alive"
}
```

**Status esperado:** ✅ 200 OK

---

## Teste 2: Readiness Probe (Pronto para tráfego?)

```bash
curl -v http://localhost:8000/health/ready
```

**Resposta Esperada (Pronto):**
```json
{
  "status": "ready",
  "ready": true,
  "model_loaded": true,
  "model_version": "1.0.0",
  "model_path": "models/model.pkl",
  "loaded_at": "2026-02-03T10:30:45.123456",
  "error": null
}
```

**Status esperado:** ✅ 200 OK

**Resposta Esperada (Não pronto):**
```json
{
  "status": "not_ready",
  "ready": false,
  "model_loaded": false,
  "model_version": "1.0.0",
  "model_path": "models/model.pkl",
  "loaded_at": null,
  "error": "Model file not found at models/model.pkl"
}
```

**Status esperado:** ❌ 503 Service Unavailable

---

## Teste 3: Legacy Health Endpoint

```bash
curl -v http://localhost:8000/health
```

**Resposta Esperada:** (mesmo que readiness)

**Status esperado:** ✅ 200 OK (ou 503)

---

## Teste 4: Predição com API Key

```bash
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: test-key-123" \
  -d '{
    "sepal_length": 5.1,
    "sepal_width": 3.5,
    "petal_length": 1.4,
    "petal_width": 0.2
  }'
```

**Resposta Esperada:**
```json
{
  "predicted_class_id": 0,
  "predicted_class_name": "setosa",
  "probabilities": [0.98, 0.02, 0.0],
  "model_version": "1.0.0",
  "timestamp": "2026-02-03T10:35:20.654321"
}
```

**Status esperado:** ✅ 200 OK

---

## Teste 5: Predição sem API Key (quando não requerida)

```bash
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{
    "sepal_length": 6.2,
    "sepal_width": 2.9,
    "petal_length": 4.3,
    "petal_width": 1.3
  }'
```

**Resposta Esperada:**
```json
{
  "predicted_class_id": 1,
  "predicted_class_name": "versicolor",
  "probabilities": [0.05, 0.90, 0.05],
  "model_version": "1.0.0",
  "timestamp": "2026-02-03T10:36:15.123456"
}
```

**Status esperado:** ✅ 200 OK

---

## Teste 6: Predição com API Key Inválida

```bash
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: wrong-key" \
  -d '{
    "sepal_length": 5.1,
    "sepal_width": 3.5,
    "petal_length": 1.4,
    "petal_width": 0.2
  }'
```

**Resposta Esperada:**
```json
{
  "detail": "Invalid API key"
}
```

**Status esperado:** ❌ 401 Unauthorized

---

## Teste 7: Swagger/OpenAPI Documentation

```bash
# Abrir no navegador:
http://localhost:8000/docs
```

Deve mostrar:
- ✅ `/health/live` (GET)
- ✅ `/health/ready` (GET)
- ✅ `/health` (GET)
- ✅ `/predict` (POST)

---

## Teste 8: Validação de Entrada

```bash
# Falta campo obrigatório
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: test-key-123" \
  -d '{
    "sepal_length": 5.1,
    "sepal_width": 3.5
  }'
```

**Resposta Esperada:**
```json
{
  "detail": [
    {
      "type": "missing",
      "loc": ["body", "petal_length"],
      "msg": "Field required"
    }
  ]
}
```

**Status esperado:** ❌ 422 Unprocessable Entity

---

## Teste 9: Modelo não carregado

(Simular removendo o arquivo do modelo)

```bash
rm models/model.pkl
curl http://localhost:8000/health/ready
```

**Resposta Esperada:**
```json
{
  "status": "not_ready",
  "ready": false,
  "model_loaded": false,
  "model_version": "1.0.0",
  "model_path": "models/model.pkl",
  "loaded_at": null,
  "error": "Model file not found at models/model.pkl"
}
```

**Status esperado:** ❌ 503 Service Unavailable

---

## Teste 10: Logs

Verificar na saída do console:

```
✅ Model loaded successfully (version: 1.0.0)
INFO:     Uvicorn running on http://0.0.0.0:8000
Prediction: class=0, confidence=0.98
```

---

## Checklist de Sucesso

- [ ] ✅ Liveness probe retorna 200
- [ ] ✅ Readiness probe retorna 200 quando modelo carregado
- [ ] ✅ Readiness probe retorna 503 quando modelo não carregado
- [ ] ✅ Predição retorna resultado correto com API key
- [ ] ✅ Predição rejeita API key inválida (401)
- [ ] ✅ Validação de entrada funciona (422)
- [ ] ✅ Modelo version retornado em cada predição
- [ ] ✅ Timestamp ISO retornado em cada predição
- [ ] ✅ Swagger docs funciona e mostra todos endpoints
- [ ] ✅ Logs estruturados e informativos

---

## Kubernetes Integration (Próximas Etapas)

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
