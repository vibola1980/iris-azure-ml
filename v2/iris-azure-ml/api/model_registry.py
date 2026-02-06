"""
Model Registry Abstrato

Permite diferentes implementações de model registry:
- Local File System
- Azure Blob Storage
- MLflow Registry
- AWS S3
"""

import os
import logging
from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
from pathlib import Path

logger = logging.getLogger(__name__)


class ModelRegistry(ABC):
    """Interface abstrata para Model Registry"""
    
    @abstractmethod
    def download_model(self, model_version: str, local_path: str) -> Dict[str, Any]:
        """
        Baixa o modelo do registry
        
        Args:
            model_version: Versão do modelo (ex: "1.2.3")
            local_path: Caminho local onde salvar o modelo
        
        Returns:
            Dict com modelo e metadados
        """
        pass
    
    @abstractmethod
    def get_latest_version(self) -> Optional[str]:
        """
        Retorna a versão mais recente do modelo
        
        Returns:
            String com versão ou None se não houver
        """
        pass
    
    @abstractmethod
    def get_model_metadata(self, model_version: str) -> Optional[Dict[str, Any]]:
        """
        Retorna metadados do modelo (data treinamento, acurácia, etc)
        """
        pass


class LocalFileSystemRegistry(ModelRegistry):
    """Registry que usa o File System local (para dev/teste)"""
    
    def __init__(self, base_path: str = "./models"):
        self.base_path = Path(base_path)
        self.base_path.mkdir(exist_ok=True, parents=True)
        logger.info(f"LocalFileSystemRegistry initialized at {self.base_path}")
    
    def download_model(self, model_version: str, local_path: str) -> Dict[str, Any]:
        """Copia modelo do local"""
        import joblib
        import shutil
        
        source_file = self.base_path / f"model-{model_version}.pkl"
        
        if not source_file.exists():
            raise FileNotFoundError(f"Model not found: {source_file}")
        
        logger.info(f"Copying model from {source_file} to {local_path}")
        shutil.copy(source_file, local_path)
        
        # Carregar modelo
        bundle = joblib.load(local_path)
        logger.info(f"✅ Model {model_version} loaded successfully")
        
        return bundle
    
    def get_latest_version(self) -> Optional[str]:
        """Retorna a versão mais recente"""
        pkl_files = list(self.base_path.glob("model-*.pkl"))
        if not pkl_files:
            return None
        
        # Extrai versão do nome do arquivo
        versions = [
            f.name.replace("model-", "").replace(".pkl", "")
            for f in pkl_files
        ]
        return sorted(versions)[-1] if versions else None
    
    def get_model_metadata(self, model_version: str) -> Optional[Dict[str, Any]]:
        """Retorna metadados"""
        metadata_file = self.base_path / f"model-{model_version}.json"
        if metadata_file.exists():
            import json
            with open(metadata_file) as f:
                return json.load(f)
        return None


class AzureBlobStorageRegistry(ModelRegistry):
    """Registry que usa Azure Blob Storage"""
    
    def __init__(self, connection_string: str, container_name: str = "models"):
        try:
            from azure.storage.blob import BlobServiceClient
        except ImportError:
            raise ImportError("azure-storage-blob not installed")
        
        self.connection_string = connection_string
        self.container_name = container_name
        self.client = BlobServiceClient.from_connection_string(connection_string)
        self.container_client = self.client.get_container_client(container_name)
        logger.info(f"AzureBlobStorageRegistry initialized (container: {container_name})")
    
    def download_model(self, model_version: str, local_path: str) -> Dict[str, Any]:
        """Baixa modelo do Azure Blob Storage"""
        import joblib
        
        blob_name = f"models/model-{model_version}.pkl"
        
        try:
            logger.info(f"Downloading model {blob_name} from Azure Blob Storage...")
            
            blob_client = self.container_client.get_blob_client(blob_name)
            with open(local_path, "wb") as file:
                file.write(blob_client.download_blob().readall())
            
            bundle = joblib.load(local_path)
            logger.info(f"✅ Model {model_version} loaded from Azure")
            return bundle
        
        except Exception as e:
            logger.error(f"Failed to download model: {str(e)}")
            raise
    
    def get_latest_version(self) -> Optional[str]:
        """Retorna a versão mais recente"""
        try:
            blobs = self.container_client.list_blobs(name_starts_with="models/model-")
            versions = [
                blob.name.replace("models/model-", "").replace(".pkl", "")
                for blob in blobs
            ]
            return sorted(versions)[-1] if versions else None
        except Exception as e:
            logger.error(f"Failed to get latest version: {str(e)}")
            return None
    
    def get_model_metadata(self, model_version: str) -> Optional[Dict[str, Any]]:
        """Retorna metadados do modelo"""
        import json
        
        try:
            metadata_blob_name = f"models/model-{model_version}.json"
            blob_client = self.container_client.get_blob_client(metadata_blob_name)
            data = blob_client.download_blob().readall()
            return json.loads(data)
        except Exception as e:
            logger.warning(f"Could not load metadata: {str(e)}")
            return None


class MLflowRegistry(ModelRegistry):
    """Registry que usa MLflow Model Registry"""
    
    def __init__(self, tracking_uri: str = "http://localhost:5000"):
        try:
            import mlflow
        except ImportError:
            raise ImportError("mlflow not installed")
        
        import mlflow
        self.mlflow = mlflow
        self.tracking_uri = tracking_uri
        self.mlflow.set_tracking_uri(tracking_uri)
        logger.info(f"MLflowRegistry initialized (tracking_uri: {tracking_uri})")
    
    def download_model(self, model_version: str, local_path: str) -> Dict[str, Any]:
        """Baixa modelo do MLflow Registry"""
        import joblib
        
        try:
            logger.info(f"Downloading model {model_version} from MLflow...")
            
            # MLflow típicamente salva em formato diferente
            # Este é um exemplo simplificado
            model_uri = f"models://iris-classifier/{model_version}"
            model = self.mlflow.pyfunc.load_model(model_uri)
            
            logger.info(f"✅ Model {model_version} loaded from MLflow")
            return {"model": model}
        
        except Exception as e:
            logger.error(f"Failed to download model from MLflow: {str(e)}")
            raise
    
    def get_latest_version(self) -> Optional[str]:
        """Retorna a versão mais recente do MLflow"""
        try:
            client = self.mlflow.tracking.MlflowClient(self.tracking_uri)
            latest = client.get_latest_versions("iris-classifier", stages=["Production"])
            return latest[0].version if latest else None
        except Exception as e:
            logger.warning(f"Could not get latest version from MLflow: {str(e)}")
            return None
    
    def get_model_metadata(self, model_version: str) -> Optional[Dict[str, Any]]:
        """Retorna metadados do modelo no MLflow"""
        try:
            client = self.mlflow.tracking.MlflowClient(self.tracking_uri)
            model_version_detail = client.get_model_version("iris-classifier", model_version)
            return {
                "version": model_version_detail.version,
                "created_timestamp": model_version_detail.creation_timestamp,
                "last_updated_timestamp": model_version_detail.last_updated_timestamp,
                "tags": model_version_detail.tags,
                "status": model_version_detail.status
            }
        except Exception as e:
            logger.warning(f"Could not get metadata: {str(e)}")
            return None


def get_registry() -> ModelRegistry:
    """
    Factory function para obter a implementação correta de Model Registry
    baseado em variáveis de ambiente
    """
    registry_type = os.getenv("MODEL_REGISTRY_TYPE", "local").lower()
    
    if registry_type == "azure":
        connection_string = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
        if not connection_string:
            raise ValueError("AZURE_STORAGE_CONNECTION_STRING not set")
        return AzureBlobStorageRegistry(connection_string)
    
    elif registry_type == "mlflow":
        tracking_uri = os.getenv("MLFLOW_TRACKING_URI", "http://localhost:5000")
        return MLflowRegistry(tracking_uri)
    
    else:  # default: local
        base_path = os.getenv("LOCAL_MODELS_PATH", "./models")
        return LocalFileSystemRegistry(base_path)
