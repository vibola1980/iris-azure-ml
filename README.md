# Iris Azure ML

Projeto de Machine Learning para classificação de flores Iris, com múltiplas implementações para deploy na Azure.

## Versões

| Versão | Stack | Status | Descrição |
|--------|-------|--------|-----------|
| [v1](./v1/) | FastAPI + ACI + Terraform | ✅ Funcional | API Python com deploy via Azure Container Instances |
| [v2](./v2/) | FastAPI + Model Registry | ✅ Completo | API com abstração de registry (local/azure/mlflow) |
| [v3](./v3/) | Spring Boot + Java | 🚧 Em progresso | Implementação Java mantendo mesmo contrato de API |

## Estrutura

```
iris-azure-ml/
├── v1/                 # FastAPI + ACI + Terraform (original)
│   ├── api/            # Código da API
│   ├── infra/          # Terraform para Azure
│   ├── training/       # Treinamento do modelo
│   └── scripts/        # Scripts utilitários
├── v2/                 # FastAPI com Model Registry
└── v3/                 # Spring Boot (Java)
```

## Pré-requisitos Gerais

- Azure CLI autenticado (`az login`)
- Docker instalado
- Python 3.11+ (para v1/v2)
- Java 17+ (para v3)
- Terraform >= 1.6.0 (para v1)

## Quick Start

Escolha uma versão e siga o README específico:

- **v1**: Deploy completo na Azure com ACI → [v1/README.md](./v1/README.md)
- **v2**: Desenvolvimento local com registry flexível → [v2/iris-azure-ml/README.md](./v2/iris-azure-ml/README.md)
- **v3**: Implementação Java → [v3/iris-spring-boot/README.md](./v3/iris-spring-boot/README.md)
