# Databricks notebook source
# MAGIC %md
# MAGIC # 01 - Data Ingestion: Iris Dataset -> Delta Table
# MAGIC
# MAGIC Loads the Iris dataset from sklearn and saves it as a Delta Table
# MAGIC for use in AutoML training.

# COMMAND ----------

from sklearn.datasets import load_iris
import pandas as pd

# Load Iris dataset
iris = load_iris()
df = pd.DataFrame(iris.data, columns=iris.feature_names)
df["target"] = iris.target
df["target_name"] = df["target"].map(
    {0: "setosa", 1: "versicolor", 2: "virginica"}
)

# Rename columns to remove special characters (Spark-friendly)
df.columns = [
    "sepal_length",
    "sepal_width",
    "petal_length",
    "petal_width",
    "target",
    "target_name",
]

print(f"Dataset shape: {df.shape}")
display(df.head(10))

# COMMAND ----------

# MAGIC %md
# MAGIC ## Save as Delta Table

# COMMAND ----------

spark_df = spark.createDataFrame(df)

table_name = "workspace.default.iris_dataset"

spark_df.write.mode("overwrite").saveAsTable(table_name)

print(f"Delta Table saved: {table_name}")
print(f"Row count: {spark_df.count()}")
