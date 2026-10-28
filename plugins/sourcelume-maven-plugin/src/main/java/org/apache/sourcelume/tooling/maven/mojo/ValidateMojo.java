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
import org.apache.sourcelume.tooling.maven.client.SourcelumeClient;
import org.apache.sourcelume.tooling.maven.client.SourcelumeResponse;

/**
 * Validates a Sourcelume Provenance Record against the configured Sourcelume Registry.
 */
@Mojo(name = "validate", defaultPhase = LifecyclePhase.VERIFY, requiresProject = true, threadSafe = true)
public class ValidateMojo extends AbstractSourcelumeMojo {

    @Override
    public void execute() throws MojoExecutionException, MojoFailureException {
        if (skip) {
            getLog().info("Sourcelume validation is skipped.");
            return;
        }

        String json = resolveOrGenerateJson();
        String targetRegistry = resolveRegistryUrl();

        if (dryRun) {
            getLog().info("[DRY-RUN] Simulating validation against " + targetRegistry);
            getLog().info("[DRY-RUN] Record to validate:\n" + json);
            return;
        }

        getLog().info("Validating Sourcelume Provenance Record against registry: " + targetRegistry);
        SourcelumeClient client = createClient();

        try {
            SourcelumeResponse response = client.validate(json);
            if (response.isSuccess()) {
                getLog().info("Validation succeeded: " + response.getBody());
            } else {
                String errorMsg = "Registry validation failed (HTTP " + response.getStatusCode() + "): " + response.getBody();
                if (failOnError) {
                    throw new MojoFailureException(errorMsg);
                } else {
                    getLog().warn(errorMsg);
                }
            }
        } catch (MojoFailureException e) {
            throw e;
        } catch (Exception e) {
            String errorMsg = "Communication error connecting to Sourcelume Registry at " + targetRegistry + ": " + e.getMessage();
            if (failOnError) {
                throw new MojoExecutionException(errorMsg, e);
            } else {
                getLog().warn(errorMsg);
            }
        }
    }
}
