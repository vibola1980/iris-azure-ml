# ============================================
# Iris Inference Service - Multi-stage Dockerfile
# Enterprise-ready build for Azure AKS
# ============================================

# Stage 1: Build dependencies
FROM python:3.12-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy and install requirements
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Stage 2: Runtime
FROM python:3.12-slim

LABEL maintainer="Iris ML Team"
LABEL description="Iris Inference Service v4 (Enterprise)"
LABEL version="1.0.0"

WORKDIR /app

# Security: Create non-root user
RUN groupadd -g 1000 appgroup && \
    useradd -u 1000 -g appgroup -s /bin/bash -m appuser

# Copy Python packages from builder
COPY --from=builder /root/.local /home/appuser/.local
ENV PATH=/home/appuser/.local/bin:$PATH

# Copy application source
COPY --chown=appuser:appgroup src/ .

# Create models directory (will be mounted or filled by init container)
RUN mkdir -p /app/models && chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 5000

# Environment defaults
ENV MODEL_PATH=/app/models/model.pkl
ENV MODEL_VERSION=1.0.0
ENV PYTHONUNBUFFERED=1

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=15s --retries=5 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health/live', timeout=2)" || exit 1

# Run application
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "5000"]
