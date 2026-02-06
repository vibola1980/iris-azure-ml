package com.iris.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.Instant;
import java.util.List;

/**
 * Response model for iris prediction
 * Same format as v2 (FastAPI) for compatibility
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PredictionResponse {

    @JsonProperty("predicted_class_id")
    private Integer predictedClassId;

    @JsonProperty("predicted_class_name")
    private String predictedClassName;

    @JsonProperty("probabilities")
    private List<Double> probabilities;

    @JsonProperty("model_version")
    private String modelVersion;

    @JsonProperty("timestamp")
    private String timestamp;
}
