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
 * Iris API Gateway - v4 (Enterprise Template)
 *
 * Enterprise-ready API Gateway for Iris flower classification
 * designed for Azure AKS deployment with Kubernetes-native patterns.
 *
 * Architecture:
 * - Java/Spring Boot: API Gateway, health checks, request routing
 * - Python Service: Model inference (separate deployment)
 * - Azure AKS: Orchestration, scaling, monitoring
 * - Azure Blob Storage: Model versioning and storage
 */
@Slf4j
@SpringBootApplication
public class IrisApplication {

    public static void main(String[] args) {
        log.info("Starting Iris API Gateway v4 (Enterprise)...");
        SpringApplication.run(IrisApplication.class, args);
        log.info("Application started successfully");
    }

    /**
     * Configure RestTemplate for HTTP calls to Python inference service
     * with connection pooling and timeouts
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
