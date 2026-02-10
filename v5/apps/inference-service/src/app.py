"""
Iris Inference Service - v4 (Enterprise)

Python FastAPI service for ML model inference.
Designed for Azure AKS deployment with Kubernetes-native health checks.

Features:
- Model loading from local filesystem or Azure Blob Storage
- Kubernetes health probes (liveness/readiness)
- Structured logging
- Prometheus metrics compatible
"""

import os
import logging
from datetime import datetime
from typing import List, Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Header
from pydantic import BaseModel, Field, field_validator
from pydantic_settings import BaseSettings
import joblib
import numpy as np

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class Settings(BaseSettings):
    """Application settings from environment variables"""
    model_path: str = "models/model.pkl"
    model_version: str = "1.0.0"
    api_key: str = ""

    class Config:
        env_file = ".env"


settings = Settings()

# Target classes
CLASS_NAMES = ["setosa", "versicolor", "virginica"]

# Global model reference
model = None
model_load_time: Optional[str] = None


class PredictRequest(BaseModel):
    """Prediction request model with validation"""
    sepal_length: float = Field(..., ge=0.0, le=10.0, description="Sepal length in cm")
    sepal_width: float = Field(..., ge=0.0, le=10.0, description="Sepal width in cm")
    petal_length: float = Field(..., ge=0.0, le=10.0, description="Petal length in cm")
    petal_width: float = Field(..., ge=0.0, le=10.0, description="Petal width in cm")

    @field_validator('sepal_length', 'sepal_width', 'petal_length', 'petal_width')
    @classmethod
    def validate_measurements(cls, v):
        if v < 0 or v > 10:
            raise ValueError('Measurement must be between 0 and 10')
        return v


class PredictionResponse(BaseModel):
    """Prediction response model"""
    predicted_class_id: int
    predicted_class_name: str
    probabilities: List[float]
    model_version: str
    timestamp: str


class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    ready: bool
    model_loaded: bool
    model_version: str
    model_path: str
    loaded_at: Optional[str] = None
    error: Optional[str] = None


class LivenessResponse(BaseModel):
    """Liveness probe response"""
    status: str


def load_model():
    """Load ML model from filesystem"""
    global model, model_load_time

    logger.info("Starting Iris Inference Service v4...")

    try:
        if not os.path.exists(settings.model_path):
            logger.error(f"Model file not found at {settings.model_path}")
            raise FileNotFoundError(f"Model file not found: {settings.model_path}")

        logger.info(f"Loading model from {settings.model_path}...")
        model = joblib.load(settings.model_path)
        model_load_time = datetime.utcnow().isoformat()
        logger.info(f"Model loaded successfully (v{settings.model_version})")

    except Exception as e:
        logger.error(f"Failed to load model: {str(e)}")
        model = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup/shutdown"""
    load_model()
    yield
    logger.info("Shutting down Iris Inference Service")


# Initialize FastAPI with lifespan
app = FastAPI(
    title="Iris Inference Service",
    description="ML model inference service for Iris classification",
    version=settings.model_version,
    lifespan=lifespan
)


@app.get("/health/live", response_model=LivenessResponse)
async def liveness():
    """Kubernetes liveness probe - is the container alive?"""
    return LivenessResponse(status="alive")


@app.get("/health/ready", response_model=HealthResponse)
async def readiness():
    """Kubernetes readiness probe - is the app ready for traffic?"""
    if model is None:
        logger.warning("Model not loaded")
        raise HTTPException(
            status_code=503,
            detail={
                "status": "not_ready",
                "ready": False,
                "model_loaded": False,
                "model_version": settings.model_version,
                "model_path": settings.model_path,
                "error": "Model not loaded"
            }
        )

    return HealthResponse(
        status="ready",
        ready=True,
        model_loaded=True,
        model_version=settings.model_version,
        model_path=settings.model_path,
        loaded_at=model_load_time
    )


@app.get("/health", response_model=HealthResponse)
async def health():
    """Legacy health endpoint"""
    return await readiness()


@app.post("/predict", response_model=PredictionResponse)
async def predict(request: PredictRequest, x_api_key: Optional[str] = Header(None)):
    """
    Classify iris flower measurements

    Args:
        request: Iris measurements (sepal_length, sepal_width, petal_length, petal_width)
        x_api_key: Optional API key header

    Returns:
        Prediction with class ID, name, and probabilities
    """

    # Check API key if configured
    if settings.api_key and settings.api_key.strip():
        if not x_api_key or x_api_key != settings.api_key:
            logger.warning("Unauthorized prediction attempt")
            raise HTTPException(status_code=401, detail="Unauthorized")

    # Check model is loaded
    if model is None:
        logger.error("Model not loaded")
        raise HTTPException(
            status_code=503,
            detail="Model not available"
        )

    try:
        logger.info(f"Prediction request: SL={request.sepal_length}, SW={request.sepal_width}, "
                   f"PL={request.petal_length}, PW={request.petal_width}")

        # Prepare features
        features = np.array([[
            request.sepal_length,
            request.sepal_width,
            request.petal_length,
            request.petal_width
        ]])

        # Make prediction
        predicted_class_id = int(model.predict(features)[0])
        predicted_class_name = CLASS_NAMES[predicted_class_id]

        # Get probabilities
        probabilities = model.predict_proba(features)[0].tolist()

        response = PredictionResponse(
            predicted_class_id=predicted_class_id,
            predicted_class_name=predicted_class_name,
            probabilities=probabilities,
            model_version=settings.model_version,
            timestamp=datetime.utcnow().isoformat()
        )

        logger.info(f"Prediction successful: class_id={predicted_class_id}, "
                   f"class_name={predicted_class_name}")

        return response

    except Exception as e:
        logger.error(f"Prediction failed: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Prediction failed: {str(e)}"
        )


@app.get("/")
async def root():
    """Root endpoint with service info"""
    return {
        "service": "Iris Inference Service",
        "version": settings.model_version,
        "status": "running",
        "endpoints": {
            "predict": "POST /predict",
            "health": "GET /health",
            "readiness": "GET /health/ready",
            "liveness": "GET /health/live",
            "docs": "GET /docs"
        }
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5000, log_level="info")
