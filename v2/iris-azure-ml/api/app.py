import os
import json
import logging
import joblib
import numpy as np
from datetime import datetime
from pathlib import Path
from fastapi import FastAPI, Header, HTTPException
from contextlib import asynccontextmanager
from pydantic import BaseModel, Field

# Carregar variáveis de ambiente do arquivo .env
try:
    from dotenv import load_dotenv
    env_file = Path(__file__).parent.parent / ".env"
    if env_file.exists():
        load_dotenv(env_file)
except ImportError:
    pass

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

MODEL_PATH = os.getenv("MODEL_PATH", "model.pkl")
MODEL_VERSION = os.getenv("MODEL_VERSION", "unknown")
API_KEY = os.getenv("API_KEY", "")

# Estado da aplicação
_app_state = {
    "model_bundle": None,
    "model_loaded_at": None,
    "is_ready": False,
    "last_error": None
}


class PredictRequest(BaseModel):
    sepal_length: float = Field(..., example=5.1)
    sepal_width: float = Field(..., example=3.5)
    petal_length: float = Field(..., example=1.4)
    petal_width: float = Field(..., example=0.2)


class HealthResponse(BaseModel):
    status: str
    ready: bool
    model_loaded: bool
    model_version: str
    model_path: str
    loaded_at: str | None = None
    error: str | None = None


class LivenessResponse(BaseModel):
    status: str


# ============================================================================
# Lifecycle Management
# ============================================================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gerencia startup e shutdown da aplicação"""
    logger.info("🚀 Iniciando aplicação...")
    load_model_on_startup()
    yield
    logger.info("🛑 Encerrando aplicação...")
    # Cleanup se necessário


def load_model_on_startup():
    """Carrega o modelo na inicialização"""
    global _app_state
    try:
        if not os.path.exists(MODEL_PATH):
            msg = f"Model file not found at {MODEL_PATH}"
            logger.error(msg)
            _app_state["last_error"] = msg
            _app_state["is_ready"] = False
            return
        
        logger.info(f"Loading model from {MODEL_PATH}...")
        bundle = joblib.load(MODEL_PATH)
        _app_state["model_bundle"] = bundle
        _app_state["model_loaded_at"] = datetime.utcnow().isoformat()
        _app_state["is_ready"] = True
        logger.info(f"✅ Model loaded successfully (version: {MODEL_VERSION})")
    except Exception as e:
        logger.error(f"❌ Failed to load model: {str(e)}")
        _app_state["last_error"] = str(e)
        _app_state["is_ready"] = False


def load_model():
    """Retorna o modelo carregado"""
    return _app_state["model_bundle"]


# ============================================================================
# FastAPI App
# ============================================================================

app = FastAPI(
    title="Iris Classifier API",
    version="1.0.0",
    lifespan=lifespan
)


# ============================================================================
# Health Check Endpoints
# ============================================================================

@app.get("/health/live", response_model=LivenessResponse, tags=["Health"])
def liveness():
    """
    Kubernetes Liveness Probe: Indica se o container está vivo
    ✅ 200 OK: Container em bom funcionamento
    """
    return {"status": "alive"}


@app.get("/health/ready", response_model=HealthResponse, tags=["Health"])
def readiness():
    """
    Kubernetes Readiness Probe: Indica se a app está pronta para receber tráfego
    ✅ 200 OK: Pronto para aceitar requisições
    ❌ 503 Service Unavailable: Não pronto (modelo não carregado)
    """
    bundle = load_model()
    is_ready = bundle is not None and _app_state["is_ready"]
    
    response = {
        "status": "ready" if is_ready else "not_ready",
        "ready": is_ready,
        "model_loaded": bundle is not None,
        "model_version": MODEL_VERSION,
        "model_path": MODEL_PATH,
        "loaded_at": _app_state["model_loaded_at"],
        "error": _app_state["last_error"]
    }
    
    if not is_ready:
        raise HTTPException(status_code=503, detail=response)
    
    return response


@app.get("/health", response_model=HealthResponse, tags=["Health"])
def health():
    """
    Legacy health endpoint (compatibilidade)
    """
    return readiness()




class PredictionResponse(BaseModel):
    predicted_class_id: int
    predicted_class_name: str
    probabilities: list[float] | None = None
    model_version: str
    timestamp: str


@app.post("/predict", response_model=PredictionResponse, tags=["Prediction"])
def predict(payload: PredictRequest, x_api_key: str | None = Header(default=None)):
    """
    Realiza uma predição da classificação de Iris
    
    Requer:
    - Header: X-API-Key (se API_KEY estiver configurada)
    
    Retorna:
    - predicted_class_id: ID da classe (0, 1 ou 2)
    - predicted_class_name: Nome da classe (setosa, versicolor, virginica)
    - probabilities: Probabilidades para cada classe
    - model_version: Versão do modelo usado
    - timestamp: Timestamp ISO da predição
    """
    
    # Autenticação
    if API_KEY and x_api_key != API_KEY:
        logger.warning(f"Unauthorized access attempt")
        raise HTTPException(status_code=401, detail="Invalid API key")

    # Validação
    bundle = load_model()
    if bundle is None:
        logger.error("Model not loaded")
        raise HTTPException(
            status_code=503,
            detail="Model not loaded. Ensure model.pkl is available."
        )

    try:
        model = bundle["model"]
        target_names = bundle["target_names"]

        # Preparar dados
        X = np.array([
            [payload.sepal_length, payload.sepal_width, 
             payload.petal_length, payload.petal_width]
        ])
        
        # Predição
        pred = int(model.predict(X)[0])
        proba = (
            model.predict_proba(X)[0].tolist() 
            if hasattr(model, "predict_proba") 
            else None
        )

        logger.info(f"Prediction: class={pred}, confidence={max(proba) if proba else 'N/A'}")

        return {
            "predicted_class_id": pred,
            "predicted_class_name": target_names[pred],
            "probabilities": proba,
            "model_version": MODEL_VERSION,
            "timestamp": datetime.utcnow().isoformat()
        }
    
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")