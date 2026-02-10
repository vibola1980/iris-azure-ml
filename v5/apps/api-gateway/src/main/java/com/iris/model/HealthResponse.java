package com.iris.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Response model for health checks
 * Used by Kubernetes readiness probe
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HealthResponse {
    private String status;
    private Boolean ready;
    private Boolean modelLoaded;
    private String modelVersion;
    private String modelPath;
    private String loadedAt;
    private String error;
}
