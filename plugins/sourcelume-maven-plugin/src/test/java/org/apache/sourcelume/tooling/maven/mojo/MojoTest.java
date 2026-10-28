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
package org.apache.sourcelume.tooling.maven.mojo;

import com.sun.net.httpserver.HttpServer;
import org.apache.maven.plugin.MojoFailureException;
import org.apache.maven.project.MavenProject;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.File;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class MojoTest {

    private HttpServer server;
    private String serverUrl;
    private MavenProject project;

    @TempDir
    Path tempDir;

    @BeforeEach
    void setUp() throws Exception {
        project = new MavenProject();
        project.setGroupId("org.apache.sourcelume");
        project.setArtifactId("test-artifact");
        project.setVersion("0.1.0");

        server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/records/validate", exchange -> {
            byte[] response = "{\"valid\":true}".getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, response.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(response);
            }
        });
        server.createContext("/records", exchange -> {
            byte[] response = "{\"status\":\"created\",\"id\":\"urn:test\"}".getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(201, response.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(response);
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
    void testGenerateMojo() throws Exception {
        File outputFile = tempDir.resolve("target/sourcelume/provenance-record.json").toFile();

        GenerateMojo mojo = new GenerateMojo();
        mojo.setProject(project);
        mojo.setOutputFile(outputFile);

        mojo.execute();

        assertThat(outputFile).exists();
        String content = Files.readString(outputFile.toPath());
        assertThat(content).contains("urn:sourcelume:maven:org.apache.sourcelume:test-artifact:0.1.0");
        assertThat(content).contains("sourcelume://maven/org.apache.sourcelume/test-artifact");
    }

    @Test
    void testValidateMojo() throws Exception {
        File outputFile = tempDir.resolve("target/sourcelume/provenance-record.json").toFile();

        ValidateMojo mojo = new ValidateMojo();
        mojo.setProject(project);
        mojo.setOutputFile(outputFile);
        mojo.setRegistryUrl(serverUrl);

        mojo.execute();
        assertThat(outputFile).exists();
    }

    @Test
    void testPublishMojoDryRun() throws Exception {
        File outputFile = tempDir.resolve("target/sourcelume/provenance-record.json").toFile();

        PublishMojo mojo = new PublishMojo();
        mojo.setProject(project);
        mojo.setOutputFile(outputFile);
        mojo.setRegistryUrl(serverUrl);
        mojo.setDryRun(true);

        mojo.execute();
        assertThat(outputFile).exists();
    }

    @Test
    void testPublishMojoLive() throws Exception {
        File outputFile = tempDir.resolve("target/sourcelume/provenance-record.json").toFile();

        PublishMojo mojo = new PublishMojo();
        mojo.setProject(project);
        mojo.setOutputFile(outputFile);
        mojo.setRegistryUrl(serverUrl);
        mojo.setUsername("user");
        mojo.setPassword("pass");

        mojo.execute();
        assertThat(outputFile).exists();
    }

    @Test
    void testPublishMojoFailsWhenTheRecordIsStoredAsIncomplete() throws Exception {
        serveIncomplete();

        PublishMojo mojo = publishTo(serverUrl + "/incomplete");
        mojo.setFailOnError(true);

        assertThatThrownBy(mojo::execute)
            .isInstanceOf(MojoFailureException.class)
            .hasMessageContaining("INCOMPLETE")
            .hasMessageContaining("/: required property 'license' not found");
    }

    @Test
    void testPublishMojoOnlyWarnsAboutAnIncompleteRecordWithoutFailOnError() throws Exception {
        serveIncomplete();

        PublishMojo mojo = publishTo(serverUrl + "/incomplete");
        mojo.setFailOnError(false);

        mojo.execute();
    }

    private void serveIncomplete() {
        server.createContext("/incomplete", exchange -> {
            byte[] response = ("{\"recordStatus\":\"INCOMPLETE\",\"validationIssues\":"
                + "\"[{\\\"path\\\":\\\"/\\\",\\\"message\\\":\\\"required property 'license' not found\\\"}]\"}")
                .getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(201, response.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(response);
            }
        });
    }

    private PublishMojo publishTo(String registryUrl) {
        PublishMojo mojo = new PublishMojo();
        mojo.setProject(project);
        mojo.setOutputFile(tempDir.resolve("target/sourcelume/provenance-record.json").toFile());
        mojo.setRegistryUrl(registryUrl);
        return mojo;
    }

    @Test
    void testPublishMojoFailureWhenServerReturnsError() throws Exception {
        server.createContext("/records-error", exchange -> {
            byte[] response = "{\"error\":\"invalid\"}".getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(500, response.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(response);
            }
        });

        File outputFile = tempDir.resolve("target/sourcelume/provenance-record.json").toFile();

        PublishMojo mojo = new PublishMojo();
        mojo.setProject(project);
        mojo.setOutputFile(outputFile);
        mojo.setRegistryUrl(serverUrl + "/records-error");
        mojo.setFailOnError(true);

        assertThatThrownBy(mojo::execute)
            .isInstanceOf(Exception.class);
    }
}
