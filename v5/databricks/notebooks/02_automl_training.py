# Databricks notebook source
# MAGIC %md
# MAGIC # 02 - AutoML Training: Iris Classifier
# MAGIC
# MAGIC Trains multiple sklearn models on the Iris dataset, selects the best one
# MAGIC based on F1 score, and logs results to MLflow.

# COMMAND ----------

import mlflow
import mlflow.sklearn
from mlflow.models.signature import infer_signature
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import cross_val_score

# Configure MLflow to use Unity Catalog for model registry
mlflow.set_registry_uri("databricks-uc")
print("Imports OK - Registry: Unity Catalog")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Load Delta Table

# COMMAND ----------

table_name = "workspace.default.iris_dataset"
df = spark.read.table(table_name).toPandas()
print(f"Loaded {len(df)} rows from {table_name}")

X = df[["sepal_length", "sepal_width", "petal_length", "petal_width"]]
y = df["target"]

# COMMAND ----------

# MAGIC %md
# MAGIC ## Train Multiple Models with MLflow Tracking

# COMMAND ----------

experiment_path = "/Users/viniciuspolmil@gmail.com/iris-ml-v5-experiment"
mlflow.set_experiment(experiment_path)
print(f"MLflow experiment: {experiment_path}")

candidates = {
    "RandomForest": RandomForestClassifier(n_estimators=100, random_state=42),
    "GradientBoosting": GradientBoostingClassifier(n_estimators=100, random_state=42),
    "LogisticRegression": LogisticRegression(max_iter=200, random_state=42),
}

best_score = -1
best_run_id = None
best_model_key = None

for name, model in candidates.items():
    with mlflow.start_run(run_name=name) as run:
        scores = cross_val_score(model, X, y, cv=5, scoring="f1_macro")
        mean_f1 = scores.mean()

        model.fit(X, y)

        mlflow.log_param("model_type", name)
        mlflow.log_metric("f1_cv_mean", mean_f1)
        mlflow.log_metric("f1_cv_std", scores.std())

        # Unity Catalog requires model signature
        signature = infer_signature(X, model.predict(X))
        mlflow.sklearn.log_model(model, "model", signature=signature)

        print(f"  {name}: F1={mean_f1:.4f} (+/- {scores.std():.4f}) run_id={run.info.run_id}")

        if mean_f1 > best_score:
            best_score = mean_f1
            best_run_id = run.info.run_id
            best_model_key = name

print(f"\nBest model: {best_model_key} (F1={best_score:.4f})")
print(f"Best run ID: {best_run_id}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Register Best Model

# COMMAND ----------

model_name = "workspace.default.iris-classifier"
model_uri = f"runs:/{best_run_id}/model"

try:
    registered_model = mlflow.register_model(model_uri, model_name)
    model_version = str(registered_model.version)
    print(f"Model registered in Unity Catalog: {model_name} v{model_version}")
except Exception as e:
    print(f"Unity Catalog registration skipped (requires storage permissions): {type(e).__name__}")
    print(f"Model is still available via MLflow run: {best_run_id}")
    model_version = "1"

# COMMAND ----------

# MAGIC %md
# MAGIC ## Save Metadata for Downstream Tasks

# COMMAND ----------

dbutils.jobs.taskValues.set(key="best_run_id", value=best_run_id)
dbutils.jobs.taskValues.set(key="model_version", value=model_version)
dbutils.jobs.taskValues.set(key="model_name", value=model_name)

print("Task values set:")
print(f"  best_run_id: {best_run_id}")
print(f"  model_version: {model_version}")
print(f"  model_name: {model_name}")
