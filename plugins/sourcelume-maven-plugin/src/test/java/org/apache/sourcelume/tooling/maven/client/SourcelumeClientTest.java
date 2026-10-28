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

import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.concurrent.atomic.AtomicReference;

import static org.assertj.core.api.Assertions.assertThat;

class SourcelumeClientTest {

    private HttpServer server;
    private String serverUrl;
    private final AtomicReference<String> lastAuthHeader = new AtomicReference<>();
    private final AtomicReference<String> lastRequestBody = new AtomicReference<>();

    @BeforeEach
    void setUp() throws Exception {
        server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/records/validate", exchange -> {
            lastAuthHeader.set(exchange.getRequestHeaders().getFirst("Authorization"));
            lastRequestBody.set(new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));

            byte[] response = "{\"valid\":true}".getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, response.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(response);
            }
        });

        server.createContext("/records", exchange -> {
            lastAuthHeader.set(exchange.getRequestHeaders().getFirst("Authorization"));
            lastRequestBody.set(new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));

            String path = exchange.getRequestURI().getPath();
            if ("/records".equals(path)) {
                if (lastRequestBody.get().contains("conflict")) {
                    byte[] response = "{\"error\":\"Record already exists\"}".getBytes(StandardCharsets.UTF_8);
                    exchange.getResponseHeaders().set("Content-Type", "application/json");
                    exchange.sendResponseHeaders(409, response.length);
                    try (OutputStream os = exchange.getResponseBody()) {
                        os.write(response);
                    }
                } else if (lastRequestBody.get().contains("invalid")) {
                    byte[] response = "{\"error\":\"Validation failed\"}".getBytes(StandardCharsets.UTF_8);
                    exchange.getResponseHeaders().set("Content-Type", "application/json");
                    exchange.sendResponseHeaders(422, response.length);
                    try (OutputStream os = exchange.getResponseBody()) {
                        os.write(response);
                    }
                } else {
                    byte[] response = "{\"status\":\"created\",\"id\":\"urn:test:1\"}".getBytes(StandardCharsets.UTF_8);
                    exchange.getResponseHeaders().set("Content-Type", "application/json");
                    exchange.sendResponseHeaders(201, response.length);
                    try (OutputStream os = exchange.getResponseBody()) {
                        os.write(response);
                    }
                }
            }
        });

        server.start();
        serverUrl = "http://localhost:" + server.getAddress().getPort();
    }

    @AfterEach
    void tearDown() {
        if (server != null) {
            server.stop(0);
        }
    }

    @Test
    void shouldValidateRecordSuccessfullyWithBearerAuth() throws Exception {
        SourcelumeClient client = SourcelumeClient.builder()
            .registryUrl(serverUrl)
            .token("secret-token-123")
            .timeout(Duration.ofSeconds(5))
            .build();

        SourcelumeResponse response = client.validate("{\"type\":\"ProvenanceRecord\"}");

        assertThat(response.isSuccess()).isTrue();
        assertThat(response.getStatusCode()).isEqualTo(200);
        assertThat(response.getBody()).contains("\"valid\":true");
        assertThat(lastAuthHeader.get()).isEqualTo("Bearer secret-token-123");
        assertThat(lastRequestBody.get()).isEqualTo("{\"type\":\"ProvenanceRecord\"}");
    }

    @Test
    void shouldPublishRecordSuccessfullyWithBasicAuth() throws Exception {
        SourcelumeClient client = SourcelumeClient.builder()
            .registryUrl(serverUrl)
            .username("admin")
            .password("password123")
            .timeout(Duration.ofSeconds(5))
            .build();

        SourcelumeResponse response = client.publish("{\"type\":\"ProvenanceRecord\",\"name\":\"test\"}");

        assertThat(response.isSuccess()).isTrue();
        assertThat(response.getStatusCode()).isEqualTo(201);
        assertThat(response.getBody()).contains("urn:test:1");
        assertThat(lastAuthHeader.get()).startsWith("Basic ");
    }

    @Test
    void shouldHandleConflictOnPublish() throws Exception {
        SourcelumeClient client = SourcelumeClient.builder()
            .registryUrl(serverUrl)
            .build();

        SourcelumeResponse response = client.publish("{\"type\":\"conflict\"}");

        assertThat(response.isSuccess()).isFalse();
        assertThat(response.isConflict()).isTrue();
        assertThat(response.getStatusCode()).isEqualTo(409);
        assertThat(response.getErrorMessage()).contains("Record already exists");
    }

    @Test
    void shouldHandleValidationErrorOnPublish() throws Exception {
        SourcelumeClient client = SourcelumeClient.builder()
            .registryUrl(serverUrl)
            .build();

        SourcelumeResponse response = client.publish("{\"type\":\"invalid\"}");

        assertThat(response.isSuccess()).isFalse();
        assertThat(response.isValidationError()).isTrue();
        assertThat(response.getStatusCode()).isEqualTo(422);
    }
}
