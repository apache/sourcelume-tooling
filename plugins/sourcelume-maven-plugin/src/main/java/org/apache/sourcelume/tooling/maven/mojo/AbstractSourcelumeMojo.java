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

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.plugins.annotations.Parameter;
import org.apache.maven.project.MavenProject;
import org.apache.sourcelume.tooling.maven.client.SourcelumeClient;
import org.apache.sourcelume.tooling.maven.model.ProvenanceRecord;
import org.apache.sourcelume.tooling.maven.util.SpecBuilder;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.time.Duration;

/**
 * Base Mojo containing shared configuration parameters for Sourcelume goals.
 */
public abstract class AbstractSourcelumeMojo extends AbstractMojo {

    @Parameter(defaultValue = "${project}", readonly = true, required = true)
    protected MavenProject project;

    /**
     * URL of the Sourcelume Registry endpoint.
     */
    @Parameter(property = "registry.url", defaultValue = "http://localhost:8082")
    protected String registryUrl;

    /**
     * Username for Registry authentication.
     */
    @Parameter(property = "registry.username")
    protected String username;

    /**
     * Password for Registry authentication.
     */
    @Parameter(property = "registry.password")
    protected String password;

    /**
     * Bearer token for Registry authentication.
     */
    @Parameter(property = "registry.token")
    protected String token;

    /**
     * Skip execution of this mojo.
     */
    @Parameter(property = "sourcelume.skip", defaultValue = "false")
    protected boolean skip;

    /**
     * Fail build if validation or publish fails.
     */
    @Parameter(property = "sourcelume.failOnError", defaultValue = "true")
    protected boolean failOnError;

    /**
     * Simulate action without submitting data to the registry.
     */
    @Parameter(property = "sourcelume.dryRun", defaultValue = "false")
    protected boolean dryRun;

    /**
     * Directory where generated spec files are written.
     */
    @Parameter(property = "sourcelume.outputDirectory", defaultValue = "${project.build.directory}/sourcelume")
    protected File outputDirectory;

    /**
     * Output file path for generated ProvenanceRecord JSON-LD.
     */
    @Parameter(property = "sourcelume.outputFile", defaultValue = "${project.build.directory}/sourcelume/provenance-record.json")
    protected File outputFile;

    /**
     * Optional pre-existing record file to use instead of generating from project metadata.
     */
    @Parameter(property = "sourcelume.recordFile")
    protected File recordFile;

    /**
     * Provenance Record ID override.
     */
    @Parameter(property = "sourcelume.recordId")
    protected String recordId;

    /**
     * Dataset identifier override.
     */
    @Parameter(property = "sourcelume.datasetIdentifier")
    protected String datasetIdentifier;

    /**
     * Dataset name override.
     */
    @Parameter(property = "sourcelume.datasetName")
    protected String datasetName;

    /**
     * Dataset version override.
     */
    @Parameter(property = "sourcelume.datasetVersion")
    protected String datasetVersion;

    /**
     * License identifier or URL override.
     */
    @Parameter(property = "sourcelume.license")
    protected String license;

    /**
     * License scope override.
     */
    @Parameter(property = "sourcelume.licenseScope")
    protected String licenseScope;

    /**
     * License category override.
     */
    @Parameter(property = "sourcelume.licenseCategory")
    protected String licenseCategory;

    /**
     * License note override.
     */
    @Parameter(property = "sourcelume.licenseNote")
    protected String licenseNote;

    /**
     * Origin override.
     */
    @Parameter(property = "sourcelume.origin")
    protected String origin;

    /**
     * Creator name override.
     */
    @Parameter(property = "sourcelume.creatorName")
    protected String creatorName;

    /**
     * Creator type override (schema:Organization or schema:Person).
     */
    @Parameter(property = "sourcelume.creatorType")
    protected String creatorType;

    /**
     * Creator role override (originator, curator, distributor).
     */
    @Parameter(property = "sourcelume.creatorRole")
    protected String creatorRole;

    /**
     * Custody agent override.
     */
    @Parameter(property = "sourcelume.custodyAgent")
    protected String custodyAgent;

    /**
     * Custody action override.
     */
    @Parameter(property = "sourcelume.custodyAction")
    protected String custodyAction;

    /**
     * HTTP timeout in seconds.
     */
    @Parameter(property = "sourcelume.timeout", defaultValue = "30")
    protected int timeoutSeconds;

    protected final ObjectMapper objectMapper = createObjectMapper();

    public static ObjectMapper createObjectMapper() {
        ObjectMapper mapper = new ObjectMapper();
        mapper.setSerializationInclusion(JsonInclude.Include.NON_NULL);
        mapper.enable(SerializationFeature.INDENT_OUTPUT);
        return mapper;
    }

    /**
     * Resolves the registry URL taking into account environment variables and system properties.
     */
    protected String resolveRegistryUrl() {
        String env = System.getenv("SOURCELUME_REGISTRY_URL");
        if (env != null && !env.isBlank()) {
            return env;
        }
        return registryUrl != null && !registryUrl.isBlank() ? registryUrl : "http://localhost:8082";
    }

    /**
     * Resolves username with environment variable fallback.
     */
    protected String resolveUsername() {
        String env = System.getenv("SOURCELUME_REGISTRY_USERNAME");
        if (env != null && !env.isBlank()) {
            return env;
        }
        return username;
    }

    /**
     * Resolves password with environment variable fallback.
     */
    protected String resolvePassword() {
        String env = System.getenv("SOURCELUME_REGISTRY_PASSWORD");
        if (env != null && !env.isBlank()) {
            return env;
        }
        return password;
    }

    /**
     * Resolves token with environment variable fallback.
     */
    protected String resolveToken() {
        String env = System.getenv("SOURCELUME_REGISTRY_TOKEN");
        if (env != null && !env.isBlank()) {
            return env;
        }
        return token;
    }

    protected SourcelumeClient createClient() {
        return SourcelumeClient.builder()
            .registryUrl(resolveRegistryUrl())
            .username(resolveUsername())
            .password(resolvePassword())
            .token(resolveToken())
            .timeout(Duration.ofSeconds(timeoutSeconds > 0 ? timeoutSeconds : 30))
            .build();
    }

    /**
     * Resolves an existing record JSON or generates a new one from project metadata.
     *
     * @return Generated or loaded JSON-LD string
     * @throws MojoExecutionException on serialization or I/O failure
     */
    protected String resolveOrGenerateJson() throws MojoExecutionException {
        if (recordFile != null && recordFile.exists() && recordFile.isFile()) {
            try {
                getLog().info("Using existing Sourcelume record file: " + recordFile.getAbsolutePath());
                return Files.readString(recordFile.toPath());
            } catch (IOException e) {
                throw new MojoExecutionException("Failed to read record file: " + recordFile, e);
            }
        }

        ProvenanceRecord record = buildRecord();
        try {
            String json = objectMapper.writeValueAsString(record);
            writeOutputFile(json);
            return json;
        } catch (IOException e) {
            throw new MojoExecutionException("Failed to serialize Sourcelume ProvenanceRecord", e);
        }
    }

    protected ProvenanceRecord buildRecord() {
        return new SpecBuilder()
            .withProject(project)
            .withId(recordId)
            .withIdentifier(datasetIdentifier)
            .withName(datasetName)
            .withVersion(datasetVersion)
            .withLicense(license)
            .withLicenseScope(licenseScope)
            .withLicenseCategory(licenseCategory)
            .withLicenseNote(licenseNote)
            .withOrigin(origin)
            .withCreatorName(creatorName)
            .withCreatorType(creatorType)
            .withCreatorRole(creatorRole)
            .withCustodyAgent(custodyAgent)
            .withCustodyAction(custodyAction)
            .build();
    }

    protected void writeOutputFile(String json) throws MojoExecutionException {
        if (outputFile == null) {
            return;
        }
        try {
            File parent = outputFile.getParentFile();
            if (parent != null && !parent.exists()) {
                parent.mkdirs();
            }
            Files.writeString(outputFile.toPath(), json);
            getLog().info("Sourcelume record written to: " + outputFile.getAbsolutePath());
        } catch (IOException e) {
            throw new MojoExecutionException("Failed to write Sourcelume record to " + outputFile, e);
        }
    }

    // Setters for unit testing / programmatic usage
    public void setProject(MavenProject project) {
        this.project = project;
    }

    public void setRegistryUrl(String registryUrl) {
        this.registryUrl = registryUrl;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public void setSkip(boolean skip) {
        this.skip = skip;
    }

    public void setFailOnError(boolean failOnError) {
        this.failOnError = failOnError;
    }

    public void setDryRun(boolean dryRun) {
        this.dryRun = dryRun;
    }

    public void setOutputFile(File outputFile) {
        this.outputFile = outputFile;
    }

    public void setRecordFile(File recordFile) {
        this.recordFile = recordFile;
    }

    public void setLicense(String license) {
        this.license = license;
    }

    public void setDatasetIdentifier(String datasetIdentifier) {
        this.datasetIdentifier = datasetIdentifier;
    }

    public void setDatasetName(String datasetName) {
        this.datasetName = datasetName;
    }

    public void setOrigin(String origin) {
        this.origin = origin;
    }
}
