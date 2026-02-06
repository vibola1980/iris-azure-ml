package com.iris.model;

import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Request model for iris prediction
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class PredictRequest {

    @NotNull(message = "sepal_length is required")
    @DecimalMin(value = "0.0", message = "sepal_length must be positive")
    @DecimalMax(value = "10.0", message = "sepal_length must be <= 10")
    @JsonProperty("sepal_length")
    private Double sepalLength;

    @NotNull(message = "sepal_width is required")
    @DecimalMin(value = "0.0", message = "sepal_width must be positive")
    @DecimalMax(value = "10.0", message = "sepal_width must be <= 10")
    @JsonProperty("sepal_width")
    private Double sepalWidth;

    @NotNull(message = "petal_length is required")
    @DecimalMin(value = "0.0", message = "petal_length must be positive")
    @DecimalMax(value = "10.0", message = "petal_length must be <= 10")
    @JsonProperty("petal_length")
    private Double petalLength;

    @NotNull(message = "petal_width is required")
    @DecimalMin(value = "0.0", message = "petal_width must be positive")
    @DecimalMax(value = "10.0", message = "petal_width must be <= 10")
    @JsonProperty("petal_width")
    private Double petalWidth;
}
