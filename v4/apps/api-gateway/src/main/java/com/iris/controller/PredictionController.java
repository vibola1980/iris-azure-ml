package com.iris.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import com.iris.model.PredictRequest;
import com.iris.model.PredictionResponse;
import com.iris.service.InferenceServiceClient;

import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;

/**
 * Prediction endpoints for iris classification
 * Routes requests to Python inference service
 */
@Slf4j
@RestController
@RequestMapping("/predict")
@Validated
public class PredictionController {

    @Autowired
    private InferenceServiceClient inferenceClient;

    @Value("${iris.api.key:}")
    private String apiKey;

    /**
     * POST /predict - Classify iris flower
     *
     * @param request Iris measurements (sepal_length, sepal_width, petal_length, petal_width)
     * @param xApiKey Optional API key header for authentication
     * @return Prediction with class ID, name, and probabilities
     */
    @PostMapping
    public ResponseEntity<PredictionResponse> predict(
            @Valid @RequestBody PredictRequest request,
            @RequestHeader(value = "X-API-Key", required = false) String xApiKey) {

        log.info("Prediction request received: sepal_length={}, sepal_width={}, petal_length={}, petal_width={}",
                request.getSepalLength(), request.getSepalWidth(),
                request.getPetalLength(), request.getPetalWidth());

        // Validate API key if configured
        if (apiKey != null && !apiKey.isEmpty()) {
            if (xApiKey == null || !xApiKey.equals(apiKey)) {
                log.warn("Unauthorized prediction attempt");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
            }
        }

        try {
            PredictionResponse response = inferenceClient.predict(request);
            log.info("Prediction successful: class_id={}, class_name={}",
                    response.getPredictedClassId(), response.getPredictedClassName());
            return ResponseEntity.ok(response);

        } catch (RuntimeException e) {
            log.error("Prediction failed", e);
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).build();
        }
    }
}
