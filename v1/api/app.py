import os
import joblib
import numpy as np
from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel, Field

MODEL_PATH = os.getenv("MODEL_PATH", "model.pkl")
API_KEY = os.getenv("API_KEY", "")

app = FastAPI(title="Iris Classifier API", version="1.0.0")

_model_bundle = None


class PredictRequest(BaseModel):
    sepal_length: float = Field(..., example=5.1)
    sepal_width: float = Field(..., example=3.5)
    petal_length: float = Field(..., example=1.4)
    petal_width: float = Field(..., example=0.2)


def load_model():
    global _model_bundle
    if _model_bundle is None:
        if not os.path.exists(MODEL_PATH):
            return None
        _model_bundle = joblib.load(MODEL_PATH)
    return _model_bundle


@app.get("/health")
def health():
    bundle = load_model()
    return {"status": "ok", "model_loaded": bundle is not None, "model_path": MODEL_PATH}


@app.post("/predict")
def predict(payload: PredictRequest, x_api_key: str | None = Header(default=None)):
    if API_KEY and x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Unauthorized")

    bundle = load_model()
    if bundle is None:
        raise HTTPException(status_code=503, detail="Model not loaded. Upload model.pkl to the mounted file share.")

    model = bundle["model"]
    target_names = bundle["target_names"]

    X = np.array([[payload.sepal_length, payload.sepal_width, payload.petal_length, payload.petal_width]])
    pred = int(model.predict(X)[0])
    proba = model.predict_proba(X)[0].tolist() if hasattr(model, "predict_proba") else None

    return {"predicted_class_id": pred, "predicted_class_name": target_names[pred], "probabilities": proba}
