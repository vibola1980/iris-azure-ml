package com.iris.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.client.RestClientException;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;

import com.iris.model.PredictRequest;
import com.iris.model.PredictionResponse;

import lombok.extern.slf4j.Slf4j;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;

/**
 * Service for calling Python inference service
 * Handles model predictions via REST call
 */
@Slf4j
@Service
public class ModelInferenceClient {

    @Autowired
    private RestTemplate restTemplate;

    @Value("${iris.inference.service.url:http://localhost:5000}")
    private String inferenceServiceUrl;

    @Value("${iris.model.version:1.0.0}")
    private String modelVersion;

    @Value("${iris.api.key:test123}")
    private String apiKey;

    /**
     * Call Python inference service to get prediction
     */
    public PredictionResponse predict(PredictRequest request) {
        try {
            log.info("Calling inference service at: {}", inferenceServiceUrl);

            String url = inferenceServiceUrl + "/predict";

            // Create headers with API key
            HttpHeaders headers = new HttpHeaders();
            headers.set("Content-Type", "application/json");
            headers.set("X-API-Key", apiKey);

            // Create HTTP entity with headers
            HttpEntity<PredictRequest> entity = new HttpEntity<>(request, headers);

            // Call Python service
            ResponseEntity<LinkedHashMap> response = restTemplate.postForEntity(
                    url,
                    entity,
                    LinkedHashMap.class);

            if (!response.getStatusCode().is2xxSuccessful()) {
                log.error("Inference service returned error: {}", response.getStatusCode());
                throw new RuntimeException("Inference service error: " + response.getStatusCode());
            }

            LinkedHashMap<String, Object> body = response.getBody();
            if (body == null) {
                log.error("Inference service returned empty response");
                throw new RuntimeException("Inference service returned empty response");
            }

            // Map response to our model
            PredictionResponse prediction = PredictionResponse.builder()
                    .predictedClassId(((Number) body.get("predicted_class_id")).intValue())
                    .predictedClassName((String) body.get("predicted_class_name"))
                    .probabilities((List<Double>) body.get("probabilities"))
                    .modelVersion(modelVersion)
                    .timestamp(Instant.now().toString())
                    .build();

            log.info("Prediction successful: class={}, confidence={}",
                    prediction.getPredictedClassName(),
                    prediction.getProbabilities() != null && !prediction.getProbabilities().isEmpty()
                            ? prediction.getProbabilities().get(0)
                            : "N/A");

            return prediction;

        } catch (RestClientException e) {
            log.error("Failed to call inference service", e);
            throw new RuntimeException("Inference service unavailable: " + e.getMessage(), e);
        }
    }

    /**
     * Check if inference service is ready
     */
    public boolean isInferenceServiceReady() {
        try {
            String url = inferenceServiceUrl + "/health/ready";
            ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);
            return response.getStatusCode().is2xxSuccessful();
        } catch (Exception e) {
            log.warn("Inference service not ready: {}", e.getMessage());
            return false;
        }
    }
}
