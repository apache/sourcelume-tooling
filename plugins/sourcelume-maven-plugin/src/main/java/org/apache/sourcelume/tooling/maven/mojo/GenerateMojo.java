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
import org.apache.sourcelume.tooling.maven.model.ProvenanceRecord;

/**
 * Generates an Apache Sourcelume Provenance Record (JSON-LD) for the current Maven project.
 */
@Mojo(name = "generate", defaultPhase = LifecyclePhase.PREPARE_PACKAGE, requiresProject = true, threadSafe = true)
public class GenerateMojo extends AbstractSourcelumeMojo {

    @Override
    public void execute() throws MojoExecutionException, MojoFailureException {
        if (skip) {
            getLog().info("Sourcelume generation is skipped.");
            return;
        }

        getLog().info("Generating Sourcelume Provenance Record for " + project.getId());
        ProvenanceRecord record = buildRecord();

        try {
            String json = objectMapper.writeValueAsString(record);
            writeOutputFile(json);
            getLog().info("Generated Sourcelume Provenance Record: " + record.getId());
            if (getLog().isDebugEnabled()) {
                getLog().debug("Record payload:\n" + json);
            }
        } catch (Exception e) {
            if (failOnError) {
                throw new MojoExecutionException("Failed to generate Sourcelume Provenance Record", e);
            } else {
                getLog().warn("Failed to generate Sourcelume Provenance Record: " + e.getMessage());
            }
        }
    }
}
