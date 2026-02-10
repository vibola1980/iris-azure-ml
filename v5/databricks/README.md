# Databricks AutoML - Iris Classifier

Pipeline de treinamento automatizado usando Databricks AutoML.

## Arquitetura

```
01_data_ingestion → 02_automl_training → 03_model_export
   (Iris→Delta)     (AutoML+MLflow)      (pkl→Blob Storage)
```

## Notebooks

| Notebook | Descricao |
|----------|-----------|
| `01_data_ingestion.py` | Carrega Iris dataset do sklearn e salva como Delta Table |
| `02_automl_training.py` | Executa AutoML classification, registra melhor modelo no MLflow |
| `03_model_export.py` | Exporta modelo como `.pkl` para Azure Blob Storage |

## Job

O arquivo `jobs/training_job.json` define um workflow multi-task (DAG) com dependencias:

```
data_ingestion → automl_training → model_export
```

### Criar o Job via Databricks CLI

```bash
# Configurar CLI
databricks configure --token

# Criar job
databricks jobs create --json @jobs/training_job.json

# Executar manualmente
databricks jobs run-now --job-id <JOB_ID>
```

## Parametros

O notebook `03_model_export` recebe parametros via widget:

| Parametro | Descricao | Exemplo |
|-----------|-----------|---------|
| `storage_account` | Nome do Storage Account | `stirisdev<suffix>` |
| `storage_container` | Container do Blob | `models` |

## Saida

O modelo exportado fica em:
```
Azure Blob Storage
└── models/
    └── iris-classifier/
        └── v{N}/
            └── model.pkl
```

Este pkl e baixado pelo Init Container no AKS durante o startup dos pods.
