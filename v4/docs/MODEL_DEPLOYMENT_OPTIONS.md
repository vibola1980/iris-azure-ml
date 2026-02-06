# Opcoes de Deploy de Modelos ML: Databricks para Azure

> Documento que analisa as diferentes estrategias para transferir modelos treinados no Databricks para o ambiente de inferencia no Azure.

---

## Contexto

O modelo de Machine Learning (`.pkl`) e treinado no **Databricks** e precisa ser disponibilizado para o servico de inferencia rodando no **Azure Kubernetes Service (AKS)**.

Este documento apresenta 3 opcoes de arquitetura, comparando complexidade, custo e casos de uso.

---

## Visao Geral das Opcoes

```
                         DATABRICKS (Treino)
                                |
                                | Modelo treinado (.pkl)
                                |
        +-----------------------+-----------------------+
        |                       |                       |
        v                       v                       v
+---------------+     +-------------------+     +---------------+
|   OPCAO 1     |     |     OPCAO 2       |     |   OPCAO 3     |
|               |     |                   |     |               |
| Azure Blob    |     | Azure Machine     |     | MLflow        |
| Storage       |     | Learning          |     | Registry      |
|               |     |                   |     |               |
| (Simples)     |     | (Enterprise)      |     | (Hibrido)     |
+-------+-------+     +---------+---------+     +-------+-------+
        |                       |                       |
        +-----------------------+-----------------------+
                                |
                                v
                    +------------------------+
                    |   AKS (Inferencia)     |
                    |   Consome o modelo     |
                    +------------------------+
```

---

## Opcao 1: Azure Blob Storage (Direto)

### Arquitetura

```
+------------------+          +------------------+          +------------------+
|    DATABRICKS    |          |   AZURE BLOB     |          |      AKS         |
|                  |          |   STORAGE        |          |                  |
|  Treina modelo   |   --->   |  /models/        |   --->   |  Init Container  |
|  Salva .pkl      |  upload  |    model_v1.pkl  |  download|  baixa modelo    |
|                  |          |    model_v2.pkl  |          |                  |
|                  |          |    latest.pkl    |          |  Inference Svc   |
|                  |          |                  |          |  carrega e serve |
+------------------+          +------------------+          +------------------+
```

### Como Funciona

1. **Databricks** treina o modelo e faz upload direto para o Blob Storage
2. **Blob Storage** armazena multiplas versoes do modelo
3. **AKS** usa um Init Container para baixar o modelo antes de iniciar o servico
4. **Inference Service** carrega o `.pkl` e serve predicoes

### Vantagens

| Vantagem | Descricao |
|----------|-----------|
| Simplicidade | Menor curva de aprendizado, menos componentes |
| Custo | Apenas Storage (centavos por GB) |
| Controle | Voce decide a estrutura de pastas e versionamento |
| Velocidade | Implementacao rapida, ideal para MVP |

### Desvantagens

| Desvantagem | Descricao |
|-------------|-----------|
| Sem versionamento automatico | Voce precisa gerenciar versoes manualmente |
| Sem metricas integradas | Nao ha tracking de experimentos |
| Sem rollback facil | Precisa implementar logica de rollback |
| Sem governanca | Dificil auditar quem publicou qual modelo |

### Custo Estimado

| Componente | Custo Mensal |
|------------|--------------|
| Blob Storage (LRS, 10GB) | ~$0.20 |
| Transferencia de dados | ~$0.05 |
| **Total** | **~$0.25/mes** |

### Quando Usar

- Projetos em fase inicial (MVP/PoC)
- Equipes pequenas (1-3 pessoas)
- Modelos que mudam com pouca frequencia
- Orcamento limitado

---

## Opcao 2: Azure Machine Learning

### Arquitetura

```
+------------------+          +------------------+          +------------------+
|    DATABRICKS    |          |    AZURE ML      |          |      AKS         |
|                  |          |    WORKSPACE     |          |                  |
|  Treina modelo   |   --->   |  Model Registry  |   --->   |  Managed         |
|  Registra no     |   SDK    |    - Versoes     |  deploy  |  Endpoint        |
|  Azure ML        |          |    - Metricas    |          |                  |
|                  |          |    - Linhagem    |          |  OU              |
|  Loga metricas   |          |                  |          |                  |
|  e experimentos  |          |  Experiments     |          |  Custom AKS      |
|                  |          |    - Runs        |          |  (seu controle)  |
|                  |          |    - Comparacao  |          |                  |
+------------------+          +------------------+          +------------------+
```

### Como Funciona

1. **Databricks** treina e registra o modelo no Azure ML via SDK
2. **Azure ML** armazena modelo com versionamento, metricas e linhagem
3. **Model Registry** gerencia ciclo de vida (Staging → Production)
4. **Deploy** pode ser para endpoint gerenciado ou AKS customizado

### Vantagens

| Vantagem | Descricao |
|----------|-----------|
| Versionamento automatico | Cada registro cria nova versao |
| Tracking de experimentos | Compara runs, metricas, parametros |
| Linhagem de dados | Sabe qual dataset gerou qual modelo |
| Governanca | Audit trail completo, RBAC granular |
| Deploy integrado | Um clique para criar endpoint |
| Rollback facil | Voltar para versao anterior e trivial |
| CI/CD nativo | Integra com Azure DevOps/GitHub Actions |

### Desvantagens

| Desvantagem | Descricao |
|-------------|-----------|
| Complexidade | Mais componentes para gerenciar |
| Custo | Workspace + compute + storage |
| Curva de aprendizado | SDK extenso, muitos conceitos |
| Vendor lock-in | Forte dependencia do ecossistema Azure |

### Custo Estimado

| Componente | Custo Mensal |
|------------|--------------|
| ML Workspace (Basic) | Gratuito |
| ML Workspace (Enterprise) | ~$100 |
| Storage associado | ~$5-10 |
| Compute (se usado) | Variavel |
| Managed Endpoints | ~$50-200 |
| **Total (Basic)** | **~$50-100/mes** |
| **Total (Enterprise)** | **~$150-400/mes** |

### Quando Usar

- Projetos em producao com multiplos modelos
- Equipes medias/grandes (5+ pessoas)
- Necessidade de auditoria e compliance
- Modelos que mudam frequentemente
- Necessidade de comparar experimentos

---

## Opcao 3: MLflow Registry (Databricks Nativo)

### Arquitetura

```
+------------------+          +------------------+          +------------------+
|    DATABRICKS    |          |   MLFLOW         |          |   AZURE          |
|                  |          |   (Databricks)   |          |                  |
|  Treina modelo   |   --->   |  Model Registry  |   --->   |  Blob Storage    |
|  mlflow.log_model|  auto    |    - Versoes     |   job    |  (export)        |
|                  |          |    - Stages      |          |                  |
|  Loga metricas   |          |    - Metricas    |          +--------+---------+
|  mlflow.log_*    |          |                  |                   |
|                  |          |  Experiments     |                   v
|                  |          |    - Runs        |          +------------------+
|                  |          |    - Artifacts   |          |      AKS         |
|                  |          |                  |          |  Inference Svc   |
+------------------+          +------------------+          +------------------+
```

### Como Funciona

1. **Databricks** treina usando MLflow (ja integrado nativamente)
2. **MLflow Registry** armazena modelos com stages (None → Staging → Production)
3. **Job agendado** exporta modelo "Production" para Azure Storage
4. **AKS** consome do Storage (mesmo fluxo da Opcao 1)

### Vantagens

| Vantagem | Descricao |
|----------|-----------|
| Integracao nativa | MLflow ja vem no Databricks |
| Tracking completo | Experimentos, metricas, parametros |
| Versionamento | Automatico com stages |
| Portabilidade | MLflow e open-source, sem vendor lock-in |
| UI amigavel | Interface visual no Databricks |
| Comparacao de modelos | Facil comparar diferentes runs |

### Desvantagens

| Desvantagem | Descricao |
|-------------|-----------|
| Export manual | Precisa de job para copiar para Storage |
| Dois sistemas | MLflow + Storage para o AKS |
| Custo Databricks | MLflow "gratuito" mas paga pelo Databricks |
| Menor integracao Azure | Nao tem deploy direto para AKS |

### Custo Estimado

| Componente | Custo Mensal |
|------------|--------------|
| MLflow Registry | Incluso no Databricks |
| Databricks Workspace | Ja existente |
| Job de export (DBU) | ~$5-10 |
| Blob Storage | ~$0.25 |
| **Total adicional** | **~$5-15/mes** |

### Quando Usar

- Ja usa Databricks para treino
- Quer tracking de experimentos sem custo extra
- Prefere solucoes open-source
- Equipe familiarizada com MLflow

---

## Comparativo Geral

### Matriz de Decisao

| Criterio | Blob Storage | Azure ML | MLflow |
|----------|:------------:|:--------:|:------:|
| Simplicidade | +++ | + | ++ |
| Custo | +++ | + | ++ |
| Versionamento | + | +++ | +++ |
| Tracking Experimentos | - | +++ | +++ |
| Governanca/Auditoria | - | +++ | ++ |
| Rollback | + | +++ | ++ |
| Integracao Databricks | ++ | ++ | +++ |
| Vendor Lock-in | + | +++ | + |
| Tempo de Setup | +++ | + | ++ |

**Legenda:** +++ Excelente | ++ Bom | + Regular | - Fraco

### Custo Total de Propriedade (TCO) - 12 meses

```
                    Blob Storage    Azure ML (Basic)    MLflow
                    ============    ================    ======
Infraestrutura         ~$3              ~$600            ~$60
Manutencao (horas)     40h               20h             30h
Custo hora ($50)     $2000             $1000           $1500
                    ------            ------          ------
TCO Anual            ~$2003            ~$1600          ~$1560
```

> **Nota:** O Blob Storage tem menor custo de infra, mas maior custo de manutencao pois voce precisa implementar versionamento, rollback e monitoramento manualmente.

---

## Recomendacao por Fase do Projeto

### Fase 1: MVP/PoC (0-3 meses)

**Recomendacao: Opcao 1 (Blob Storage)**

```
Databricks ---> Blob Storage ---> AKS
```

- Foco em validar o modelo funciona
- Menor investimento inicial
- Rapido de implementar

### Fase 2: Producao Inicial (3-12 meses)

**Recomendacao: Opcao 3 (MLflow)**

```
Databricks ---> MLflow Registry ---> Blob Storage ---> AKS
```

- Adiciona tracking de experimentos
- Mantem custos controlados
- Prepara para escalar

### Fase 3: Producao Enterprise (12+ meses)

**Recomendacao: Opcao 2 (Azure ML)**

```
Databricks ---> Azure ML ---> AKS Managed Endpoint
```

- Governanca completa
- Multiplos modelos em producao
- Equipe crescendo

---

## Fluxo de Decisao

```
                              START
                                |
                                v
                    +------------------------+
                    | Quantos modelos em     |
                    | producao?              |
                    +------------------------+
                         |            |
                       1-2          3+
                         |            |
                         v            v
              +----------------+  +------------------+
              | Precisa de     |  | Azure ML         |
              | auditoria/     |  | (Opcao 2)        |
              | compliance?    |  +------------------+
              +----------------+
                   |        |
                  Nao      Sim
                   |        |
                   v        v
        +-------------+  +------------------+
        | Ja usa      |  | Azure ML         |
        | Databricks? |  | (Opcao 2)        |
        +-------------+  +------------------+
             |      |
            Sim    Nao
             |      |
             v      v
      +----------+  +------------------+
      | MLflow   |  | Blob Storage     |
      | (Opcao 3)|  | (Opcao 1)        |
      +----------+  +------------------+
```

---

## Proximos Passos

1. **Definir fase atual do projeto** - MVP, Producao Inicial ou Enterprise?
2. **Avaliar requisitos de compliance** - Ha necessidade de auditoria?
3. **Verificar familiaridade da equipe** - Com quais ferramentas a equipe ja trabalha?
4. **Estimar volume de modelos** - Quantos modelos diferentes serao servidos?
5. **Escolher opcao** - Baseado nos criterios acima

---

## Documentos Relacionados

| Documento | Descricao |
|-----------|-----------|
| [INFRASTRUCTURE_DEV_OVERVIEW.md](./INFRASTRUCTURE_DEV_OVERVIEW.md) | Visao geral da infra DEV |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | Arquitetura detalhada do sistema |
| [GITOPS_ROADMAP.md](./GITOPS_ROADMAP.md) | Roadmap de evolucao GitOps |

---

> **Documento criado em:** Fevereiro/2025
> **Autor:** Equipe de Engenharia ML
> **Ultima atualizacao:** Fevereiro/2025
