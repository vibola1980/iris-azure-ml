package com.iris.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.mockito.Mockito.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

import com.iris.service.ModelInferenceClient;

@SpringBootTest
@AutoConfigureMockMvc
class HealthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ModelInferenceClient inferenceClient;

    @BeforeEach
    void setUp() {
        reset(inferenceClient);
    }

    @Test
    void testLivenessProbe() throws Exception {
        // When & Then
        mockMvc.perform(get("/health/live"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("alive"));
    }

    @Test
    void testReadinessProbeReady() throws Exception {
        // Given
        when(inferenceClient.isInferenceServiceReady()).thenReturn(true);

        // When & Then
        mockMvc.perform(get("/health/ready"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.ready").value(true))
                .andExpect(jsonPath("$.status").value("ready"));
    }

    @Test
    void testReadinessProbeNotReady() throws Exception {
        // Given
        when(inferenceClient.isInferenceServiceReady()).thenReturn(false);

        // When & Then
        mockMvc.perform(get("/health/ready"))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.ready").value(false))
                .andExpect(jsonPath("$.status").value("not_ready"));
    }

    @Test
    void testHealthEndpoint() throws Exception {
        // Given
        when(inferenceClient.isInferenceServiceReady()).thenReturn(true);

        // When & Then
        mockMvc.perform(get("/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.ready").value(true));
    }
}
