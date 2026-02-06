"""
Python Inference Service for Iris Classification
REST endpoint for model predictions
Based on v2 architecture but simplified for inference-only
"""

import os
import logging
import json
from datetime import datetime
from typing import Dict, List, Optional

from fastapi import FastAPI, HTTPException, Header
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field, validator
import joblib
import numpy as np
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Constants
MODEL_PATH = os.getenv("MODEL_PATH", "models/model.pkl")
MODEL_VERSION = os.getenv("MODEL_VERSION", "1.0.0")
API_KEY = os.getenv("API_KEY", "")

# Target classes
CLASS_NAMES = ["setosa", "versicolor", "virginica"]

# Initialize FastAPI
app = FastAPI(
    title="Iris Inference Service",
    description="REST endpoint for iris model predictions",
    version=MODEL_VERSION
)

# Global model reference
model = None
model_load_time = None


class PredictRequest(BaseModel):
    """Prediction request model"""
    sepal_length: float = Field(..., alias="sepal_length", ge=0.0, le=10.0)
    sepal_width: float = Field(..., alias="sepal_width", ge=0.0, le=10.0)
    petal_length: float = Field(..., alias="petal_length", ge=0.0, le=10.0)
    petal_width: float = Field(..., alias="petal_width", ge=0.0, le=10.0)

    @validator('sepal_length', 'sepal_width', 'petal_length', 'petal_width')
    def validate_measurements(cls, v):
        if v < 0 or v > 10:
            raise ValueError('Measurement must be between 0 and 10')
        return v

    class Config:
        allow_population_by_field_name = True


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


@app.on_event("startup")
async def startup():
    """Load model on startup"""
    global model, model_load_time
    
    logger.info("🚀 Starting Iris Inference Service...")
    
    try:
        if not os.path.exists(MODEL_PATH):
            logger.error(f"❌ Model file not found at {MODEL_PATH}")
            raise FileNotFoundError(f"Model file not found: {MODEL_PATH}")
        
        logger.info(f"📦 Loading model from {MODEL_PATH}...")
        model = joblib.load(MODEL_PATH)
        model_load_time = datetime.utcnow().isoformat()
        logger.info(f"✅ Model loaded successfully (v{MODEL_VERSION})")
        
    except Exception as e:
        logger.error(f"❌ Failed to load model: {str(e)}")
        model = None


@app.on_event("shutdown")
async def shutdown():
    """Cleanup on shutdown"""
    logger.info("🛑 Shutting down Iris Inference Service")


@app.get("/health/live")
async def liveness():
    """Kubernetes liveness probe"""
    return LivenessResponse(status="alive")


@app.get("/health/ready")
async def readiness():
    """Kubernetes readiness probe"""
    if model is None:
        logger.warning("⚠️ Model not loaded")
        raise HTTPException(
            status_code=503,
            detail={
                "status": "not_ready",
                "ready": False,
                "model_loaded": False,
                "model_version": MODEL_VERSION,
                "model_path": MODEL_PATH,
                "error": "Model not loaded"
            }
        )
    
    return HealthResponse(
        status="ready",
        ready=True,
        model_loaded=True,
        model_version=MODEL_VERSION,
        model_path=MODEL_PATH,
        loaded_at=model_load_time
    )


@app.get("/health")
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
    if API_KEY and API_KEY.strip():
        if not x_api_key or x_api_key != API_KEY:
            logger.warning("⚠️ Unauthorized prediction attempt")
            raise HTTPException(status_code=401, detail="Unauthorized")
    
    # Check model is loaded
    if model is None:
        logger.error("❌ Model not loaded")
        raise HTTPException(
            status_code=503,
            detail="Model not available"
        )
    
    try:
        logger.info(f"📊 Prediction request: SL={request.sepal_length}, SW={request.sepal_width}, "
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
            model_version=MODEL_VERSION,
            timestamp=datetime.utcnow().isoformat()
        )
        
        logger.info(f"✅ Prediction successful: class_id={predicted_class_id}, "
                   f"class_name={predicted_class_name}")
        
        return response
        
    except Exception as e:
        logger.error(f"❌ Prediction failed: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Prediction failed: {str(e)}"
        )


# Root endpoint
@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "service": "Iris Inference Service",
        "version": MODEL_VERSION,
        "status": "running",
        "endpoints": {
            "predict": "POST /predict",
            "health": "GET /health",
            "readiness": "GET /health/ready",
            "liveness": "GET /health/live"
        }
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5000, log_level="info")
