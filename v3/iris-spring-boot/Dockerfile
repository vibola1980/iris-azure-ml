FROM eclipse-temurin:17-jdk AS builder

LABEL maintainer="Iris ML Team"
LABEL description="Builder stage for Spring Boot Iris Classifier API"

WORKDIR /app

# Copy pom.xml
COPY pom.xml .

# Copy source code
COPY src src

# Install Maven
RUN apt-get update && apt-get install -y maven && rm -rf /var/lib/apt/lists/*

# Build application
RUN mvn clean package -DskipTests -q


# Final stage
FROM eclipse-temurin:17-jre

LABEL maintainer="Iris ML Team"
LABEL description="Spring Boot Iris Classifier API v3"

WORKDIR /app

# Copy JAR from builder
COPY --from=builder /app/target/iris-classifier-api-*.jar app.jar

# Create non-root user (use a different UID to avoid conflicts)
RUN useradd -m -u 2000 appuser && chown -R appuser:appuser /app
USER appuser

# Port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:8080/health/live || exit 1

# Run application
ENTRYPOINT ["java", "-jar", "app.jar"]
