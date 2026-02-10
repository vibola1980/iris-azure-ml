package com.iris.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import com.iris.model.HealthResponse;
import com.iris.model.LivenessResponse;
import com.iris.service.InferenceServiceClient;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import java.time.Instant;

/**
 * Health check endpoints for Kubernetes probes
 * Implements standard K8s health check patterns
 */
@Slf4j
@RestController
public class HealthController {

    @Autowired
    private InferenceServiceClient inferenceClient;

    @Value("${iris.model.version:1.0.0}")
    private String modelVersion;

    @Value("${iris.model.path:models/model.pkl}")
    private String modelPath;

    /**
     * Kubernetes Liveness Probe: Is the container alive?
     * Returns 200 OK if container is running
     * Used by K8s to determine if container needs restart
     */
    @GetMapping("/health/live")
    public ResponseEntity<LivenessResponse> liveness() {
        log.debug("Liveness probe called");
        return ResponseEntity.ok(new LivenessResponse("alive"));
    }

    /**
     * Kubernetes Readiness Probe: Is the app ready for traffic?
     * Returns 200 OK if inference service is ready, 503 otherwise
     * Used by K8s to determine if pod should receive traffic
     */
    @GetMapping("/health/ready")
    public ResponseEntity<HealthResponse> readiness() {
        log.debug("Readiness probe called");

        boolean isReady = inferenceClient.isInferenceServiceReady();

        HealthResponse health = HealthResponse.builder()
                .status(isReady ? "ready" : "not_ready")
                .ready(isReady)
                .modelLoaded(isReady)
                .modelVersion(modelVersion)
                .modelPath(modelPath)
                .loadedAt(Instant.now().toString())
                .error(isReady ? null : "Inference service not ready")
                .build();

        if (!isReady) {
            log.warn("Readiness probe failed: inference service not ready");
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(health);
        }

        log.debug("Readiness probe successful");
        return ResponseEntity.ok(health);
    }

    /**
     * Legacy health endpoint (backward compatible)
     */
    @GetMapping("/health")
    public ResponseEntity<HealthResponse> health() {
        return readiness();
    }
}
