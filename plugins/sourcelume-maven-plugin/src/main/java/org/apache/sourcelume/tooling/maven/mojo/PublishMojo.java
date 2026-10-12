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

import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.plugin.MojoFailureException;
import org.apache.maven.plugins.annotations.LifecyclePhase;
import org.apache.maven.plugins.annotations.Mojo;
import org.apache.maven.plugins.annotations.Parameter;
import org.apache.sourcelume.tooling.maven.client.SourcelumeClient;
import org.apache.sourcelume.tooling.maven.client.SourcelumeResponse;

/**
 * Generates and publishes (submits) an Apache Sourcelume Provenance Record to the configured Sourcelume Registry.
 */
@Mojo(name = "publish", defaultPhase = LifecyclePhase.DEPLOY, requiresProject = true, threadSafe = true)
public class PublishMojo extends AbstractSourcelumeMojo {

    /**
     * Treat HTTP 409 Conflict as a non-fatal warning (when record already exists in registry).
     */
    @Parameter(property = "sourcelume.allowConflict", defaultValue = "false")
    protected boolean allowConflict;

    @Override
    public void execute() throws MojoExecutionException, MojoFailureException {
        if (skip) {
            getLog().info("Sourcelume publishing is skipped.");
            return;
        }

        String json = resolveOrGenerateJson();
        String targetRegistry = resolveRegistryUrl();

        if (dryRun) {
            getLog().info("[DRY-RUN] Simulating publish to Sourcelume Registry: " + targetRegistry);
            getLog().info("[DRY-RUN] Record to submit:\n" + json);
            return;
        }

        getLog().info("Submitting Sourcelume Provenance Record to registry: " + targetRegistry);
        SourcelumeClient client = createClient();

        try {
            SourcelumeResponse response = client.publish(json);
            if (response.isSuccess()) {
                getLog().info("Successfully published record to Sourcelume Registry! Status: " + response.getStatusCode());
                if (!response.getBody().isBlank()) {
                    getLog().info("Registry response: " + response.getBody());
                }
            } else if (response.isConflict() && allowConflict) {
                getLog().warn("Record already exists in Sourcelume Registry (HTTP 409 Conflict). Continuing as allowConflict=true.");
            } else {
                String errorMsg = "Failed to publish record to Sourcelume Registry (HTTP " + response.getStatusCode() + "): " + response.getBody();
                if (failOnError) {
                    throw new MojoFailureException(errorMsg);
                } else {
                    getLog().warn(errorMsg);
                }
            }
        } catch (MojoFailureException e) {
            throw e;
        } catch (Exception e) {
            String errorMsg = "Communication error publishing to Sourcelume Registry at " + targetRegistry + ": " + e.getMessage();
            if (failOnError) {
                throw new MojoExecutionException(errorMsg, e);
            } else {
                getLog().warn(errorMsg);
            }
        }
    }

    public void setAllowConflict(boolean allowConflict) {
        this.allowConflict = allowConflict;
    }
}
