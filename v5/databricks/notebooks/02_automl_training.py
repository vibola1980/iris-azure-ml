# Databricks notebook source
# MAGIC %md
# MAGIC # 02 - AutoML Training: Iris Classifier
# MAGIC
# MAGIC Trains multiple sklearn models on the Iris dataset, selects the best one
# MAGIC based on F1 score, and logs results to MLflow.
# MAGIC
# MAGIC **Parameters:**
# MAGIC - `feature_set`: `"sepal_only"` (2 features) or `"all_features"` (4 features)
# MAGIC
# MAGIC When `sepal_only`, models are wrapped in a Pipeline with feature selection,
# MAGIC so the exported pkl always accepts 4 features as input (API contract unchanged).

# COMMAND ----------

import mlflow
import mlflow.sklearn
from mlflow.models.signature import infer_signature
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.model_selection import cross_val_score

# Configure MLflow to use Unity Catalog for model registry
mlflow.set_registry_uri("databricks-uc")
print("Imports OK - Registry: Unity Catalog")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Parameters

# COMMAND ----------

dbutils.widgets.dropdown("feature_set", "all_features", ["sepal_only", "all_features"])
dbutils.widgets.text("model_version", "")
feature_set = dbutils.widgets.get("feature_set")
model_version_override = dbutils.widgets.get("model_version")
print(f"Feature set: {feature_set}")
if model_version_override:
    print(f"Model version override: {model_version_override}")

ALL_FEATURES = ["sepal_length", "sepal_width", "petal_length", "petal_width"]
SEPAL_FEATURES = ["sepal_length", "sepal_width"]

if feature_set == "sepal_only":
    train_features = SEPAL_FEATURES
    print(f"Training with {len(train_features)} features: {train_features}")
    print("Models will be wrapped in Pipeline with feature selector")
else:
    train_features = ALL_FEATURES
    print(f"Training with {len(train_features)} features: {train_features}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Load Delta Table

# COMMAND ----------

table_name = "workspace.default.iris_dataset"
df = spark.read.table(table_name).toPandas()
print(f"Loaded {len(df)} rows from {table_name}")

X_all = df[ALL_FEATURES]
X_train = df[train_features]
y = df["target"]

# COMMAND ----------

# MAGIC %md
# MAGIC ## Train Multiple Models with MLflow Tracking

# COMMAND ----------

def build_model(classifier):
    """Wrap classifier in Pipeline with feature selection if needed."""
    if feature_set == "sepal_only":
        # ColumnTransformer is natively pickle-serializable (no custom functions)
        selector = ColumnTransformer(
            transformers=[("sepal", "passthrough", [0, 1])],
            remainder="drop",
        )
        return Pipeline([
            ("feature_selector", selector),
            ("classifier", classifier),
        ])
    return classifier

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

for name, classifier in candidates.items():
    with mlflow.start_run(run_name=f"{name}_{feature_set}") as run:
        # Cross-validate on training features only
        scores = cross_val_score(classifier, X_train, y, cv=5, scoring="f1_macro")
        mean_f1 = scores.mean()

        # Build final model (Pipeline if sepal_only, raw classifier if all_features)
        final_model = build_model(type(classifier)(**classifier.get_params()))
        final_model.fit(X_all, y)  # Always fit on X_all so Pipeline learns the selector

        mlflow.log_param("model_type", name)
        mlflow.log_param("feature_set", feature_set)
        mlflow.log_param("n_features", len(train_features))
        mlflow.log_metric("f1_cv_mean", mean_f1)
        mlflow.log_metric("f1_cv_std", scores.std())

        # Signature uses X_all (4 features) - matches API contract
        signature = infer_signature(X_all, final_model.predict(X_all))
        mlflow.sklearn.log_model(final_model, "model", signature=signature)

        print(f"  {name} [{feature_set}]: F1={mean_f1:.4f} (+/- {scores.std():.4f}) run_id={run.info.run_id}")

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
    model_version = model_version_override if model_version_override else "1"

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
print(f"  feature_set: {feature_set}")
