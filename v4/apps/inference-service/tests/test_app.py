"""
Tests for Iris Inference Service
"""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
import numpy as np


class MockModel:
    """Mock sklearn model for testing"""

    def predict(self, X):
        return np.array([0])

    def predict_proba(self, X):
        return np.array([[0.97, 0.02, 0.01]])


@pytest.fixture
def client():
    """Create test client with mocked model"""
    with patch.dict('os.environ', {'MODEL_PATH': 'test_model.pkl', 'API_KEY': ''}):
        # Import after patching environment
        from src.app import app, load_model
        import src.app as app_module

        # Mock the model
        app_module.model = MockModel()
        app_module.model_load_time = "2024-01-01T00:00:00"

        return TestClient(app)


class TestLiveness:
    def test_liveness_returns_alive(self, client):
        response = client.get("/health/live")
        assert response.status_code == 200
        assert response.json()["status"] == "alive"


class TestReadiness:
    def test_readiness_when_model_loaded(self, client):
        response = client.get("/health/ready")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ready"
        assert data["ready"] is True
        assert data["model_loaded"] is True

    def test_readiness_when_model_not_loaded(self, client):
        import src.app as app_module
        original_model = app_module.model
        app_module.model = None

        response = client.get("/health/ready")
        assert response.status_code == 503

        app_module.model = original_model


class TestPredict:
    def test_predict_valid_request(self, client):
        response = client.post("/predict", json={
            "sepal_length": 5.1,
            "sepal_width": 3.5,
            "petal_length": 1.4,
            "petal_width": 0.2
        })
        assert response.status_code == 200
        data = response.json()
        assert data["predicted_class_id"] == 0
        assert data["predicted_class_name"] == "setosa"
        assert len(data["probabilities"]) == 3

    def test_predict_invalid_values(self, client):
        response = client.post("/predict", json={
            "sepal_length": -1.0,
            "sepal_width": 3.5,
            "petal_length": 1.4,
            "petal_width": 0.2
        })
        assert response.status_code == 422

    def test_predict_missing_fields(self, client):
        response = client.post("/predict", json={
            "sepal_length": 5.1
        })
        assert response.status_code == 422


class TestRoot:
    def test_root_returns_service_info(self, client):
        response = client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert data["service"] == "Iris Inference Service"
        assert "endpoints" in data
