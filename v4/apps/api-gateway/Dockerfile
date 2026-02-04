# ============================================
# Iris API Gateway - Multi-stage Dockerfile
# Enterprise-ready build for Azure AKS
# ============================================

# Stage 1: Build
FROM eclipse-temurin:17-jdk AS builder

LABEL maintainer="Iris ML Team"
LABEL description="Builder stage for Iris API Gateway"

WORKDIR /app

# Copy pom.xml and download dependencies (layer caching)
COPY pom.xml .
RUN apt-get update && apt-get install -y maven && rm -rf /var/lib/apt/lists/*
RUN mvn dependency:go-offline -B

# Copy source code and build
COPY src src
RUN mvn clean package -DskipTests -q

# Stage 2: Runtime
FROM eclipse-temurin:17-jre-alpine

LABEL maintainer="Iris ML Team"
LABEL description="Iris API Gateway v4 (Enterprise)"
LABEL version="1.0.0"

WORKDIR /app

# Security: Create non-root user
RUN addgroup -g 1000 appgroup && \
    adduser -u 1000 -G appgroup -s /bin/sh -D appuser && \
    chown -R appuser:appgroup /app

# Copy JAR from builder
COPY --from=builder --chown=appuser:appgroup /app/target/api-gateway-*.jar app.jar

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# JVM tuning for containers
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:InitialRAMPercentage=50.0"

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD wget -q --spider http://localhost:8080/health/live || exit 1

# Run application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
