package com.iris;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.web.client.RestTemplate;
import org.apache.hc.client5.http.classic.HttpClient;
import org.apache.hc.client5.http.impl.classic.HttpClients;
import org.springframework.http.client.HttpComponentsClientHttpRequestFactory;

import lombok.extern.slf4j.Slf4j;

/**
 * Iris Classifier API - v3 (Spring Boot)
 *
 * Enterprise ML API for Iris flower classification
 * with Kubernetes integration and Python model inference service.
 *
 * Architecture:
 * - Java/Spring Boot: API, health checks, configuration
 * - Python Service: Model inference (/predict endpoint)
 * - Kubernetes: Orchestration, scaling, monitoring
 */
@Slf4j
@SpringBootApplication
public class IrisApplication {

    public static void main(String[] args) {
        log.info("🚀 Starting Iris Classifier API v3 (Spring Boot)...");
        SpringApplication.run(IrisApplication.class, args);
        log.info("✅ Application started successfully");
    }

    /**
     * Configure RestTemplate for HTTP calls to Python inference service
     */
    @Bean
    public RestTemplate restTemplate() {
        HttpClient httpClient = HttpClients.createDefault();
        HttpComponentsClientHttpRequestFactory factory = new HttpComponentsClientHttpRequestFactory(httpClient);
        factory.setConnectTimeout(5000);
        factory.setConnectionRequestTimeout(5000);
        return new RestTemplate(factory);
    }
}
