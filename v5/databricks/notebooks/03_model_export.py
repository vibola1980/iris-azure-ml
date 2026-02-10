# Databricks notebook source
# MAGIC %md
# MAGIC # 03 - Model Export: MLflow -> pkl -> Azure Blob Storage
# MAGIC
# MAGIC Downloads the best model from MLflow and exports it as a pickle file
# MAGIC to Azure Blob Storage for consumption by the AKS inference service.
# MAGIC
# MAGIC Uses connection string for Databricks Community Edition.
# MAGIC In production (Azure Databricks), replace with managed identity.

# COMMAND ----------

# MAGIC %pip install azure-storage-blob

# COMMAND ----------

import mlflow
import mlflow.sklearn
import joblib
import os
import tempfile

print("Imports OK")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Retrieve Task Values from Training Notebook

# COMMAND ----------

best_run_id = dbutils.jobs.taskValues.get(
    taskKey="automl_training", key="best_run_id"
)
model_version = dbutils.jobs.taskValues.get(
    taskKey="automl_training", key="model_version"
)
model_name = dbutils.jobs.taskValues.get(
    taskKey="automl_training", key="model_name"
)

print(f"Run ID: {best_run_id}")
print(f"Model: {model_name} v{model_version}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Download Model from MLflow and Save as pkl

# COMMAND ----------

model_uri = f"runs:/{best_run_id}/model"
model = mlflow.sklearn.load_model(model_uri)

pkl_dir = tempfile.mkdtemp()
pkl_path = os.path.join(pkl_dir, "model.pkl")

joblib.dump(model, pkl_path)
file_size = os.path.getsize(pkl_path)
print(f"Model saved to: {pkl_path} ({file_size} bytes)")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Upload to Azure Blob Storage

# COMMAND ----------

from azure.storage.blob import BlobServiceClient

# Connection string passed as job parameter
connection_string = dbutils.widgets.get("storage_connection_string")
container_name = dbutils.widgets.get("storage_container")

blob_path = f"iris-classifier/v{model_version}/model.pkl"

blob_service = BlobServiceClient.from_connection_string(connection_string)
blob_client = blob_service.get_blob_client(container=container_name, blob=blob_path)

with open(pkl_path, "rb") as f:
    blob_client.upload_blob(f, overwrite=True)

print(f"Model uploaded to Azure Blob Storage:")
print(f"  Container: {container_name}")
print(f"  Blob: {blob_path}")
print(f"  Size: {file_size} bytes")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Summary

# COMMAND ----------

print("=" * 50)
print("Model Export Complete")
print("=" * 50)
print(f"  Model:   {model_name}")
print(f"  Version: v{model_version}")
print(f"  Run ID:  {best_run_id}")
print(f"  Blob:    {blob_path}")
print(f"  Storage: {container_name}")
print("=" * 50)
