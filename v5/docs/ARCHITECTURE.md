# Architecture Decisions

This document records the key architectural decisions made for the Iris ML API v4.

## Overview

The v4 architecture is designed to be an enterprise-ready template for deploying ML models on Azure Kubernetes Service (AKS).

## Decision Records

### ADR-001: Microservices Architecture

**Status:** Accepted

**Context:** We need to deploy an ML model with a REST API in a scalable, maintainable way.

**Decision:** Split the application into two services:
- **API Gateway** (Java/Spring Boot): Handles HTTP requests, authentication, and routing
- **Inference Service** (Python/FastAPI): Loads the ML model and performs predictions

**Rationale:**
- Separation of concerns: API logic vs ML logic
- Independent scaling: Scale inference pods based on ML workload
- Technology fit: Java for enterprise API patterns, Python for ML ecosystem
- Team expertise: Different teams can work on different services

**Consequences:**
- Added network hop between services
- Need to manage inter-service communication
- More complex deployment

---

### ADR-002: Azure Blob Storage for Models

**Status:** Accepted

**Context:** We need a place to store ML model artifacts with versioning support.

**Decision:** Use Azure Blob Storage with versioned paths (e.g., `models/iris-classifier/v1.0.0/model.pkl`).

**Rationale:**
- Cost-effective (~$0/month for small models)
- Simple to implement and understand
- Native Azure integration (managed identity)
- Versioning through folder structure

**Alternatives Considered:**
- Azure ML Registry: More features but more complex, better for larger ML teams
- Container image embedding: Simple but requires image rebuild for model updates

**Migration Path:** Architecture supports future migration to Azure ML Registry when governance requirements increase.

---

### ADR-003: Init Container for Model Download

**Status:** Accepted

**Context:** Pods need access to the ML model file at startup.

**Decision:** Use a Kubernetes Init Container to download the model from Azure Blob Storage before the main container starts.

**Rationale:**
- Zero downtime deployments: New pods only receive traffic after model is loaded
- Clear separation: Download logic separate from inference logic
- Managed identity: No credentials in containers

**Consequences:**
- Pod startup time includes download time
- Need to ensure Blob Storage is accessible from AKS

---

### ADR-004: Kustomize for Environment Management

**Status:** Accepted

**Context:** We need to manage different configurations for dev and prod environments.

**Decision:** Use Kustomize with base/overlays pattern.

**Rationale:**
- Native Kubernetes tooling (no additional dependencies)
- Clear separation of base configuration and environment patches
- Easy to understand and extend

**Alternatives Considered:**
- Helm: More powerful but more complex for our use case
- Raw YAML with sed/envsubst: Error-prone and hard to maintain

---

### ADR-005: GitHub Actions for CI/CD

**Status:** Accepted

**Context:** We need automated build, test, and deployment pipelines.

**Decision:** Use GitHub Actions with OIDC authentication to Azure.

**Rationale:**
- Native GitHub integration
- OIDC eliminates need for long-lived credentials
- Matrix builds for parallel execution
- Good community support

---

### ADR-006: External Secrets Operator for Production

**Status:** Accepted

**Context:** Production needs secure secret management.

**Decision:** Use External Secrets Operator with Azure Key Vault in production.

**Rationale:**
- Secrets never stored in Git
- Automatic rotation support
- Audit trail in Key Vault
- Kubernetes-native secret references

**Dev Environment:** Uses simple Kubernetes secrets for convenience.

---

### ADR-007: HPA with CPU/Memory Metrics

**Status:** Accepted

**Context:** We need automatic scaling based on load.

**Decision:** Use Horizontal Pod Autoscaler with CPU (70%) and Memory (80%) targets.

**Rationale:**
- Simple and reliable metrics
- Native Kubernetes support
- Predictable scaling behavior

**Future Consideration:** Add custom metrics (inference latency, queue depth) when needed.

---

### ADR-008: PodDisruptionBudget for Availability

**Status:** Accepted

**Context:** We need to maintain availability during cluster maintenance.

**Decision:** Configure PDB with `minAvailable: 2` for production inference service.

**Rationale:**
- Prevents all pods from being evicted simultaneously
- Maintains availability during node drains
- Works with cluster autoscaler

---

### ADR-009: Network Policies for Security

**Status:** Accepted

**Context:** We need to restrict network access between services.

**Decision:** Implement Calico Network Policies:
- Inference Service only accepts traffic from API Gateway
- API Gateway accepts external traffic on port 8080
- Default deny for other ingress

**Rationale:**
- Defense in depth
- Limits blast radius of compromised pods
- Required for many compliance standards

---

### ADR-010: Workload Identity for Azure Access

**Status:** Accepted

**Context:** Services need access to Azure resources (Blob Storage, Key Vault).

**Decision:** Use Azure Workload Identity (OIDC federation).

**Rationale:**
- No credentials in pods or environment variables
- Automatic token rotation
- Fine-grained RBAC at Azure level
- Microsoft recommended approach

---

## Technology Stack Summary

| Component | Technology | Justification |
|-----------|------------|---------------|
| API Gateway | Spring Boot 3.2 | Enterprise Java patterns, Actuator metrics |
| Inference Service | FastAPI | Python ML ecosystem, async support |
| Container Runtime | Docker | Industry standard, multi-stage builds |
| Orchestration | AKS | Managed Kubernetes, Azure integration |
| IaC | Terraform | Multi-cloud, mature ecosystem |
| K8s Config | Kustomize | Native tooling, simple patches |
| CI/CD | GitHub Actions | Native integration, OIDC support |
| Model Storage | Azure Blob | Simple, cost-effective |
| Secrets | Key Vault + ESO | Secure, auditable |
| Monitoring | Azure Monitor | Native integration, Container Insights |

---

## Future Considerations

1. **Service Mesh (Istio/Linkerd):** Consider when need mTLS, traffic management, or observability
2. **Azure ML Registry:** Migrate when ML governance requirements increase
3. **GPU Nodes:** Add when model requires GPU inference
4. **Multi-region:** Consider for global deployments with low latency requirements
