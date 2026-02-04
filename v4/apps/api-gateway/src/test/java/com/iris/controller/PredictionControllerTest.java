package com.iris.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.iris.model.PredictRequest;
import com.iris.model.PredictionResponse;
import com.iris.service.InferenceServiceClient;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Arrays;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(PredictionController.class)
class PredictionControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private InferenceServiceClient inferenceClient;

    @Test
    void predict_withValidRequest_shouldReturnPrediction() throws Exception {
        PredictRequest request = new PredictRequest(5.1, 3.5, 1.4, 0.2);
        PredictionResponse response = PredictionResponse.builder()
                .predictedClassId(0)
                .predictedClassName("setosa")
                .probabilities(Arrays.asList(0.97, 0.02, 0.01))
                .modelVersion("1.0.0")
                .timestamp("2024-01-01T00:00:00Z")
                .build();

        when(inferenceClient.predict(any(PredictRequest.class))).thenReturn(response);

        mockMvc.perform(post("/predict")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.predicted_class_id").value(0))
                .andExpect(jsonPath("$.predicted_class_name").value("setosa"));
    }

    @Test
    void predict_withInvalidRequest_shouldReturn400() throws Exception {
        String invalidJson = "{\"sepal_length\": -1}";

        mockMvc.perform(post("/predict")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(invalidJson))
                .andExpect(status().isBadRequest());
    }

    @Test
    void predict_whenServiceUnavailable_shouldReturn503() throws Exception {
        PredictRequest request = new PredictRequest(5.1, 3.5, 1.4, 0.2);

        when(inferenceClient.predict(any(PredictRequest.class)))
                .thenThrow(new RuntimeException("Service unavailable"));

        mockMvc.perform(post("/predict")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isServiceUnavailable());
    }
}
