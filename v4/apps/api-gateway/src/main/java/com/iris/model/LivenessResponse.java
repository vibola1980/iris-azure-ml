package com.iris.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Response model for liveness probe
 * Used by Kubernetes liveness probe
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class LivenessResponse {
    private String status;
}
