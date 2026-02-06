FROM python:3.12-slim

LABEL maintainer="Iris ML Team"
LABEL description="Python inference service for iris classification model"

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY app.py .

# Create models directory
RUN mkdir -p ../models

# Health check - using Python requests
HEALTHCHECK --interval=10s --timeout=5s --start-period=15s --retries=5 \
    CMD python -c "import requests,sys; r=requests.get('http://localhost:5000/health/ready', timeout=2); sys.exit(0 if r.status_code==200 else 1)"

# Expose port and run Uvicorn
EXPOSE 5000

# Start the app with Uvicorn
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "5000"]
