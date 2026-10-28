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

import org.apache.maven.model.Developer;
import org.apache.maven.model.License;
import org.apache.maven.model.Organization;
import org.apache.maven.model.Scm;
import org.apache.maven.project.MavenProject;
import org.apache.sourcelume.tooling.maven.model.Creator;
import org.apache.sourcelume.tooling.maven.model.CustodyChainEntry;
import org.apache.sourcelume.tooling.maven.model.ProvenanceRecord;

import java.time.Instant;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

/**
 * Builds a Sourcelume {@link ProvenanceRecord} from Maven project metadata and configuration overrides.
 */
public class SpecBuilder {

    private MavenProject project;
    private String id;
    private String identifier;
    private String name;
    private String version;
    private String license;
    private String licenseScope;
    private String licenseCategory;
    private String licenseNote;
    private String origin;
    private String creatorName;
    private String creatorType;
    private String creatorRole;
    private List<Creator> creators;
    private String custodyAgent;
    private String custodyAction;
    private String created;
    private String added;
    private String contentCreated;

    public SpecBuilder() {
    }

    public SpecBuilder withProject(MavenProject project) {
        this.project = project;
        return this;
    }

    public SpecBuilder withId(String id) {
        this.id = id;
        return this;
    }

    public SpecBuilder withIdentifier(String identifier) {
        this.identifier = identifier;
        return this;
    }

    public SpecBuilder withName(String name) {
        this.name = name;
        return this;
    }

    public SpecBuilder withVersion(String version) {
        this.version = version;
        return this;
    }

    public SpecBuilder withLicense(String license) {
        this.license = license;
        return this;
    }

    public SpecBuilder withLicenseScope(String licenseScope) {
        this.licenseScope = licenseScope;
        return this;
    }

    public SpecBuilder withLicenseCategory(String licenseCategory) {
        this.licenseCategory = licenseCategory;
        return this;
    }

    public SpecBuilder withLicenseNote(String licenseNote) {
        this.licenseNote = licenseNote;
        return this;
    }

    public SpecBuilder withOrigin(String origin) {
        this.origin = origin;
        return this;
    }

    public SpecBuilder withCreatorName(String creatorName) {
        this.creatorName = creatorName;
        return this;
    }

    public SpecBuilder withCreatorType(String creatorType) {
        this.creatorType = creatorType;
        return this;
    }

    public SpecBuilder withCreatorRole(String creatorRole) {
        this.creatorRole = creatorRole;
        return this;
    }

    public SpecBuilder withCreators(List<Creator> creators) {
        this.creators = creators;
        return this;
    }

    public SpecBuilder withCustodyAgent(String custodyAgent) {
        this.custodyAgent = custodyAgent;
        return this;
    }

    public SpecBuilder withCustodyAction(String custodyAction) {
        this.custodyAction = custodyAction;
        return this;
    }

    public SpecBuilder withCreated(String created) {
        this.created = created;
        return this;
    }

    public SpecBuilder withAdded(String added) {
        this.added = added;
        return this;
    }

    public SpecBuilder withContentCreated(String contentCreated) {
        this.contentCreated = contentCreated;
        return this;
    }

    public ProvenanceRecord build() {
        ProvenanceRecord record = new ProvenanceRecord();

        String groupId = project != null ? project.getGroupId() : "unknown";
        String artifactId = project != null ? project.getArtifactId() : "unknown";
        String projVersion = project != null ? project.getVersion() : "0.0.1";

        // ID
        if (id != null && !id.isBlank()) {
            record.setId(id);
        } else {
            record.setId("urn:sourcelume:maven:" + groupId + ":" + artifactId + ":" + projVersion);
        }

        // Dataset Identifier
        if (identifier != null && !identifier.isBlank()) {
            record.setIdentifier(identifier);
        } else {
            record.setIdentifier("sourcelume://maven/" + groupId + "/" + artifactId);
        }

        // Name
        if (name != null && !name.isBlank()) {
            record.setName(name);
        } else if (project != null && project.getName() != null && !project.getName().isBlank()) {
            record.setName(project.getName());
        } else {
            record.setName(artifactId);
        }

        // Version
        if (version != null && !version.isBlank()) {
            record.setVersion(version);
        } else {
            record.setVersion(projVersion);
        }

        // License
        if (license != null && !license.isBlank()) {
            record.setLicense(SpdxLicenseMapper.toSpdxIri(license));
        } else if (project != null && project.getLicenses() != null && !project.getLicenses().isEmpty()) {
            License pomLicense = project.getLicenses().get(0);
            String candidate = pomLicense.getUrl() != null && !pomLicense.getUrl().isBlank()
                ? pomLicense.getUrl()
                : pomLicense.getName();
            record.setLicense(SpdxLicenseMapper.toSpdxIri(candidate));
        } else {
            record.setLicense("https://spdx.org/licenses/Apache-2.0.html");
        }

        // License qualifiers
        if (licenseScope != null && !licenseScope.isBlank()) {
            record.setLicenseScope(licenseScope);
        }
        if (licenseCategory != null && !licenseCategory.isBlank()) {
            record.setLicenseCategory(licenseCategory);
        } else {
            record.setLicenseCategory("open-source");
        }
        if (licenseNote != null && !licenseNote.isBlank()) {
            record.setLicenseNote(licenseNote);
        }

        // Timestamps (ISO-8601 UTC)
        String now = DateTimeFormatter.ISO_INSTANT.format(Instant.now());
        record.setCreated(created != null && !created.isBlank() ? created : now);
        record.setAdded(added != null && !added.isBlank() ? added : now);
        record.setContentCreated(contentCreated != null && !contentCreated.isBlank() ? contentCreated : now);

        // Origin
        if (origin != null && !origin.isBlank()) {
            record.setOrigin(origin);
        } else if (project != null) {
            Scm scm = project.getScm();
            if (scm != null && scm.getUrl() != null && !scm.getUrl().isBlank()) {
                record.setOrigin(scm.getUrl());
            } else if (project.getUrl() != null && !project.getUrl().isBlank()) {
                record.setOrigin(project.getUrl());
            } else {
                record.setOrigin("https://repo1.maven.org/maven2/" + groupId.replace('.', '/') + "/" + artifactId + "/" + projVersion);
            }
        } else {
            record.setOrigin("https://sourcelume.apache.org");
        }

        // Creators
        List<Creator> resolvedCreators = new ArrayList<>();
        if (creators != null && !creators.isEmpty()) {
            resolvedCreators.addAll(creators);
        } else if (creatorName != null && !creatorName.isBlank()) {
            String type = creatorType != null && !creatorType.isBlank() ? creatorType : "schema:Organization";
            String role = creatorRole != null && !creatorRole.isBlank() ? creatorRole : "originator";
            resolvedCreators.add(new Creator(type, creatorName, role));
        } else if (project != null) {
            Organization org = project.getOrganization();
            if (org != null && org.getName() != null && !org.getName().isBlank()) {
                resolvedCreators.add(new Creator("schema:Organization", org.getName(), "originator"));
            }

            if (project.getDevelopers() != null) {
                for (Developer dev : project.getDevelopers()) {
                    if (dev.getName() != null && !dev.getName().isBlank()) {
                        resolvedCreators.add(new Creator("schema:Person", dev.getName(), "originator"));
                    }
                }
            }

            if (resolvedCreators.isEmpty()) {
                resolvedCreators.add(new Creator("schema:Organization", groupId, "originator"));
            }
        } else {
            resolvedCreators.add(new Creator("schema:Organization", "Apache Sourcelume", "originator"));
        }
        record.setCreator(resolvedCreators);

        // Custody Chain
        List<CustodyChainEntry> custodyChain = new ArrayList<>();
        String agent = custodyAgent != null && !custodyAgent.isBlank() ? custodyAgent : record.getOrigin();
        if (!agent.startsWith("http://") && !agent.startsWith("https://") && !agent.startsWith("urn:")) {
            agent = "urn:sourcelume:agent:" + agent.replaceAll("[^a-zA-Z0-9.-]", "_");
        }

        String action = custodyAction != null && !custodyAction.isBlank()
            ? custodyAction
            : "Build and package Maven artifact " + groupId + ":" + artifactId + ":" + projVersion;

        custodyChain.add(new CustodyChainEntry(agent, action, record.getAdded()));
        record.setCustodyChain(custodyChain);

        return record;
    }
}
