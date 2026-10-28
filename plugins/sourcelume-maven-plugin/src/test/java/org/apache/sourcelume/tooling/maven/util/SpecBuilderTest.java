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
package org.apache.sourcelume.tooling.maven.util;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.maven.model.Developer;
import org.apache.maven.model.License;
import org.apache.maven.model.Organization;
import org.apache.maven.model.Scm;
import org.apache.maven.project.MavenProject;
import org.apache.sourcelume.tooling.maven.mojo.AbstractSourcelumeMojo;
import org.apache.sourcelume.tooling.maven.model.ProvenanceRecord;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class SpecBuilderTest {

    private final ObjectMapper mapper = AbstractSourcelumeMojo.createObjectMapper();

    @Test
    void shouldBuildRecordFromMavenProjectMetadata() throws Exception {
        MavenProject project = new MavenProject();
        project.setGroupId("org.apache.sourcelume");
        project.setArtifactId("sourcelume-sample");
        project.setVersion("1.0.0");
        project.setName("Apache Sourcelume Sample");

        License lic = new License();
        lic.setName("Apache-2.0");
        lic.setUrl("https://www.apache.org/licenses/LICENSE-2.0.txt");
        project.setLicenses(List.of(lic));

        Organization org = new Organization();
        org.setName("The Apache Software Foundation");
        project.setOrganization(org);

        Developer dev = new Developer();
        dev.setName("Jane Doe");
        project.setDevelopers(List.of(dev));

        Scm scm = new Scm();
        scm.setUrl("https://github.com/apache/sourcelume-sample");
        project.setScm(scm);

        SpecBuilder builder = new SpecBuilder().withProject(project);
        ProvenanceRecord record = builder.build();

        assertThat(record.getContext()).isEqualTo("https://sourcelume.apache.org/context/0.0.1/sourcelume.jsonld");
        assertThat(record.getType()).isEqualTo("ProvenanceRecord");
        assertThat(record.getId()).isEqualTo("urn:sourcelume:maven:org.apache.sourcelume:sourcelume-sample:1.0.0");
        assertThat(record.getIdentifier()).isEqualTo("sourcelume://maven/org.apache.sourcelume/sourcelume-sample");
        assertThat(record.getName()).isEqualTo("Apache Sourcelume Sample");
        assertThat(record.getVersion()).isEqualTo("1.0.0");
        assertThat(record.getLicense()).isEqualTo("https://spdx.org/licenses/Apache-2.0.html");
        assertThat(record.getLicenseCategory()).isEqualTo("open-source");
        assertThat(record.getOrigin()).isEqualTo("https://github.com/apache/sourcelume-sample");
        assertThat(record.getCreator()).hasSize(2);
        assertThat(record.getCreator().get(0).getName()).isEqualTo("The Apache Software Foundation");
        assertThat(record.getCreator().get(0).getType()).isEqualTo("schema:Organization");
        assertThat(record.getCreator().get(1).getName()).isEqualTo("Jane Doe");
        assertThat(record.getCreator().get(1).getType()).isEqualTo("schema:Person");
        assertThat(record.getCustodyChain()).hasSize(1);
        assertThat(record.getCustodyChain().get(0).getAgent()).isEqualTo("https://github.com/apache/sourcelume-sample");

        // Verify JSON serializability and structure
        String json = mapper.writeValueAsString(record);
        JsonNode node = mapper.readTree(json);
        assertThat(node.get("@context").asText()).isEqualTo("https://sourcelume.apache.org/context/0.0.1/sourcelume.jsonld");
        assertThat(node.get("type").asText()).isEqualTo("ProvenanceRecord");
        assertThat(node.get("id").asText()).isEqualTo("urn:sourcelume:maven:org.apache.sourcelume:sourcelume-sample:1.0.0");
    }

    @Test
    void shouldHonorExplicitOverrides() {
        MavenProject project = new MavenProject();
        project.setGroupId("com.example");
        project.setArtifactId("custom-app");
        project.setVersion("2.3.4");

        SpecBuilder builder = new SpecBuilder()
            .withProject(project)
            .withId("urn:dataset:custom-123")
            .withIdentifier("doi:10.1234/5678")
            .withName("Custom Fine-Tuning Corpus")
            .withVersion("2.3.4-alpha")
            .withLicense("MIT")
            .withLicenseCategory("open-source")
            .withLicenseScope("Global")
            .withLicenseNote("Permissive training corpus")
            .withOrigin("https://data.example.org/corpus.tar.gz")
            .withCreatorName("Corpus Team")
            .withCreatorType("schema:Organization")
            .withCreatorRole("originator")
            .withCustodyAgent("https://ci.example.org/pipeline/1")
            .withCustodyAction("Aggregated dataset release")
            .withCreated("2026-10-12T00:00:00Z")
            .withAdded("2026-10-12T01:00:00Z")
            .withContentCreated("2026-10-10T00:00:00Z");

        ProvenanceRecord record = builder.build();

        assertThat(record.getId()).isEqualTo("urn:dataset:custom-123");
        assertThat(record.getIdentifier()).isEqualTo("doi:10.1234/5678");
        assertThat(record.getName()).isEqualTo("Custom Fine-Tuning Corpus");
        assertThat(record.getVersion()).isEqualTo("2.3.4-alpha");
        assertThat(record.getLicense()).isEqualTo("https://spdx.org/licenses/MIT.html");
        assertThat(record.getLicenseScope()).isEqualTo("Global");
        assertThat(record.getLicenseCategory()).isEqualTo("open-source");
        assertThat(record.getLicenseNote()).isEqualTo("Permissive training corpus");
        assertThat(record.getOrigin()).isEqualTo("https://data.example.org/corpus.tar.gz");
        assertThat(record.getCreated()).isEqualTo("2026-10-12T00:00:00Z");
        assertThat(record.getAdded()).isEqualTo("2026-10-12T01:00:00Z");
        assertThat(record.getContentCreated()).isEqualTo("2026-10-10T00:00:00Z");
        assertThat(record.getCreator()).hasSize(1);
        assertThat(record.getCreator().get(0).getName()).isEqualTo("Corpus Team");
        assertThat(record.getCreator().get(0).getRole()).isEqualTo("originator");
        assertThat(record.getCustodyChain()).hasSize(1);
        assertThat(record.getCustodyChain().get(0).getAgent()).isEqualTo("https://ci.example.org/pipeline/1");
        assertThat(record.getCustodyChain().get(0).getAction()).isEqualTo("Aggregated dataset release");
    }
}
