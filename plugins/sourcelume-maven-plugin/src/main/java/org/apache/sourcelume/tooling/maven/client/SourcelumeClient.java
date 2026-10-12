/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.apache.sourcelume.tooling.maven.client;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Base64;

/**
 * HTTP client for communicating with an Apache Sourcelume Registry instance.
 */
public class SourcelumeClient {

    private final String registryUrl;
    private final String username;
    private final String password;
    private final String token;
    private final Duration timeout;
    private final HttpClient httpClient;

    public SourcelumeClient(String registryUrl, String username, String password, String token, Duration timeout, HttpClient httpClient) {
        this.registryUrl = sanitizeUrl(registryUrl);
        this.username = username;
        this.password = password;
        this.token = token;
        this.timeout = timeout != null ? timeout : Duration.ofSeconds(30);
        this.httpClient = httpClient != null ? httpClient : HttpClient.newBuilder()
            .connectTimeout(this.timeout)
            .build();
    }

    public static Builder builder() {
        return new Builder();
    }

    private static String sanitizeUrl(String url) {
        if (url == null || url.isBlank()) {
            return "http://localhost:8082";
        }
        String trimmed = url.trim();
        return trimmed.endsWith("/") ? trimmed.substring(0, trimmed.length() - 1) : trimmed;
    }

    public String getRegistryUrl() {
        return registryUrl;
    }

    /**
     * Validates a Sourcelume ProvenanceRecord payload against the registry.
     *
     * @param recordJson JSON-LD record payload
     * @return response from registry
     * @throws IOException          if network error occurs
     * @throws InterruptedException if request is interrupted
     */
    public SourcelumeResponse validate(String recordJson) throws IOException, InterruptedException {
        String endpoint = registryUrl + "/records/validate";
        HttpRequest request = buildPostRequest(endpoint, recordJson);
        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));

        int statusCode = response.statusCode();
        String body = response.body();

        if (statusCode >= 200 && statusCode < 300) {
            return SourcelumeResponse.success(statusCode, body);
        } else {
            return SourcelumeResponse.error(statusCode, body, "Validation failed with HTTP " + statusCode + ": " + body);
        }
    }

    /**
     * Publishes (submits) a Sourcelume ProvenanceRecord payload to the registry.
     *
     * @param recordJson JSON-LD record payload
     * @return response from registry
     * @throws IOException          if network error occurs
     * @throws InterruptedException if request is interrupted
     */
    public SourcelumeResponse publish(String recordJson) throws IOException, InterruptedException {
        String endpoint = registryUrl + "/records";
        HttpRequest request = buildPostRequest(endpoint, recordJson);
        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));

        int statusCode = response.statusCode();
        String body = response.body();

        if (statusCode >= 200 && statusCode < 300) {
            return SourcelumeResponse.success(statusCode, body);
        } else if (statusCode == 409) {
            return SourcelumeResponse.error(statusCode, body, "Record already exists in registry (HTTP 409): " + body);
        } else {
            return SourcelumeResponse.error(statusCode, body, "Publish failed with HTTP " + statusCode + ": " + body);
        }
    }

    private HttpRequest buildPostRequest(String endpoint, String jsonPayload) {
        HttpRequest.Builder builder = HttpRequest.newBuilder()
            .uri(URI.create(endpoint))
            .timeout(timeout)
            .header("Content-Type", "application/json")
            .header("Accept", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString(jsonPayload, StandardCharsets.UTF_8));

        // Apply Authentication
        if (token != null && !token.isBlank()) {
            builder.header("Authorization", "Bearer " + token.trim());
        } else if (username != null && !username.isBlank()) {
            String pass = password != null ? password : "";
            String auth = username + ":" + pass;
            String encoded = Base64.getEncoder().encodeToString(auth.getBytes(StandardCharsets.UTF_8));
            builder.header("Authorization", "Basic " + encoded);
        }

        return builder.build();
    }

    public static class Builder {
        private String registryUrl = "http://localhost:8082";
        private String username;
        private String password;
        private String token;
        private Duration timeout = Duration.ofSeconds(30);
        private HttpClient httpClient;

        public Builder registryUrl(String registryUrl) {
            this.registryUrl = registryUrl;
            return this;
        }

        public Builder username(String username) {
            this.username = username;
            return this;
        }

        public Builder password(String password) {
            this.password = password;
            return this;
        }

        public Builder token(String token) {
            this.token = token;
            return this;
        }

        public Builder timeout(Duration timeout) {
            this.timeout = timeout;
            return this;
        }

        public Builder httpClient(HttpClient httpClient) {
            this.httpClient = httpClient;
            return this;
        }

        public SourcelumeClient build() {
            return new SourcelumeClient(registryUrl, username, password, token, timeout, httpClient);
        }
    }
}
