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
package org.apache.sourcelume.tooling.maven.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonPropertyOrder;

import java.util.ArrayList;
import java.util.List;

/**
 * Represents an Apache Sourcelume Provenance Record (0.0.1 schema).
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@JsonPropertyOrder({
    "@context",
    "id",
    "type",
    "identifier",
    "name",
    "version",
    "license",
    "licenseScope",
    "licenseCategory",
    "licenseNote",
    "licenseHistory",
    "creator",
    "created",
    "added",
    "contentCreated",
    "origin",
    "custodyChain"
})
public class ProvenanceRecord {

    @JsonProperty("@context")
    private String context = "https://sourcelume.apache.org/context/0.0.1/sourcelume.jsonld";

    @JsonProperty("id")
    private String id;

    @JsonProperty("type")
    private String type = "ProvenanceRecord";

    @JsonProperty("identifier")
    private String identifier;

    @JsonProperty("name")
    private String name;

    @JsonProperty("version")
    private String version;

    @JsonProperty("license")
    private String license;

    @JsonProperty("licenseScope")
    private String licenseScope;

    @JsonProperty("licenseCategory")
    private String licenseCategory;

    @JsonProperty("licenseNote")
    private String licenseNote;

    @JsonProperty("licenseHistory")
    private List<LicenseHistoryEntry> licenseHistory;

    @JsonProperty("creator")
    private List<Creator> creator = new ArrayList<>();

    @JsonProperty("created")
    private String created;

    @JsonProperty("added")
    private String added;

    @JsonProperty("contentCreated")
    private String contentCreated;

    @JsonProperty("origin")
    private String origin;

    @JsonProperty("custodyChain")
    private List<CustodyChainEntry> custodyChain = new ArrayList<>();

    public ProvenanceRecord() {
    }

    public String getContext() {
        return context;
    }

    public void setContext(String context) {
        this.context = context;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getIdentifier() {
        return identifier;
    }

    public void setIdentifier(String identifier) {
        this.identifier = identifier;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getVersion() {
        return version;
    }

    public void setVersion(String version) {
        this.version = version;
    }

    public String getLicense() {
        return license;
    }

    public void setLicense(String license) {
        this.license = license;
    }

    public String getLicenseScope() {
        return licenseScope;
    }

    public void setLicenseScope(String licenseScope) {
        this.licenseScope = licenseScope;
    }

    public String getLicenseCategory() {
        return licenseCategory;
    }

    public void setLicenseCategory(String licenseCategory) {
        this.licenseCategory = licenseCategory;
    }

    public String getLicenseNote() {
        return licenseNote;
    }

    public void setLicenseNote(String licenseNote) {
        this.licenseNote = licenseNote;
    }

    public List<LicenseHistoryEntry> getLicenseHistory() {
        return licenseHistory;
    }

    public void setLicenseHistory(List<LicenseHistoryEntry> licenseHistory) {
        this.licenseHistory = licenseHistory;
    }

    public List<Creator> getCreator() {
        return creator;
    }

    public void setCreator(List<Creator> creator) {
        this.creator = creator;
    }

    public String getCreated() {
        return created;
    }

    public void setCreated(String created) {
        this.created = created;
    }

    public String getAdded() {
        return added;
    }

    public void setAdded(String added) {
        this.added = added;
    }

    public String getContentCreated() {
        return contentCreated;
    }

    public void setContentCreated(String contentCreated) {
        this.contentCreated = contentCreated;
    }

    public String getOrigin() {
        return origin;
    }

    public void setOrigin(String origin) {
        this.origin = origin;
    }

    public List<CustodyChainEntry> getCustodyChain() {
        return custodyChain;
    }

    public void setCustodyChain(List<CustodyChainEntry> custodyChain) {
        this.custodyChain = custodyChain;
    }
}
