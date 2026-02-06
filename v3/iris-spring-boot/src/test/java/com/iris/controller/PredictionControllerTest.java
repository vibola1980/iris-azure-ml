package com.iris.controller;

import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import com.iris.model.PredictRequest;
import com.iris.model.PredictionResponse;
import com.iris.service.ModelInferenceClient;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.Arrays;

@SpringBootTest
@AutoConfigureMockMvc
class PredictionControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ModelInferenceClient inferenceClient;

    @Autowired
    private ObjectMapper objectMapper;

    @BeforeEach
    void setUp() {
        reset(inferenceClient);
    }

    @Test
    void testPredictSuccess() throws Exception {
        // Given
        PredictRequest request = new PredictRequest(5.1, 3.5, 1.4, 0.2);

        PredictionResponse response = PredictionResponse.builder()
                .predictedClassId(0)
                .predictedClassName("setosa")
                .probabilities(Arrays.asList(0.97, 0.03, 0.0))
                .modelVersion("1.0.0")
                .timestamp("2024-01-15T10:30:45.123456")
                .build();

        when(inferenceClient.predict(any(PredictRequest.class))).thenReturn(response);

        // When & Then
        mockMvc.perform(post("/predict")
                .contentType(MediaType.APPLICATION_JSON)
                .header("X-API-Key", "test123")
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.predicted_class_id").value(0))
                .andExpect(jsonPath("$.predicted_class_name").value("setosa"));
    }

    @Test
    void testPredictInvalidData() throws Exception {
        // Given - Invalid (value > 10)
        String invalidRequest = "{\"sepal_length\": 100, \"sepal_width\": 3.5, \"petal_length\": 1.4, \"petal_width\": 0.2}";

        // When & Then
        mockMvc.perform(post("/predict")
                .contentType(MediaType.APPLICATION_JSON)
                .header("X-API-Key", "test123")
                .content(invalidRequest))
                .andExpect(status().isBadRequest());
    }

    @Test
    void testPredictUnauthorized() throws Exception {
        // Given - No API key
        PredictRequest request = new PredictRequest(5.1, 3.5, 1.4, 0.2);

        // When & Then
        mockMvc.perform(post("/predict")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized());
    }
}
