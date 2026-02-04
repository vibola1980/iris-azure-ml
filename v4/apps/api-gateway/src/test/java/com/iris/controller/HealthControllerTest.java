package com.iris.controller;

import com.iris.service.InferenceServiceClient;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(HealthController.class)
class HealthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private InferenceServiceClient inferenceClient;

    @Test
    void liveness_shouldReturnAlive() throws Exception {
        mockMvc.perform(get("/health/live"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("alive"));
    }

    @Test
    void readiness_whenServiceReady_shouldReturnReady() throws Exception {
        when(inferenceClient.isInferenceServiceReady()).thenReturn(true);

        mockMvc.perform(get("/health/ready"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ready"))
                .andExpect(jsonPath("$.ready").value(true))
                .andExpect(jsonPath("$.modelLoaded").value(true));
    }

    @Test
    void readiness_whenServiceNotReady_shouldReturn503() throws Exception {
        when(inferenceClient.isInferenceServiceReady()).thenReturn(false);

        mockMvc.perform(get("/health/ready"))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.status").value("not_ready"))
                .andExpect(jsonPath("$.ready").value(false));
    }

    @Test
    void health_shouldReturnSameAsReadiness() throws Exception {
        when(inferenceClient.isInferenceServiceReady()).thenReturn(true);

        mockMvc.perform(get("/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ready"));
    }
}
