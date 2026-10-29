<!--
  Licensed to the Apache Software Foundation (ASF) under one
  or more contributor license agreements.  See the NOTICE file
  distributed with this work for additional information regarding
  copyright ownership.  The ASF licenses this file to You under the
  Apache License, Version 2.0 (the "License"); you may not use this
  file except in compliance with the License.  You may obtain a copy
  of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->

# Apache Sourcelume Tooling — Examples

This folder provides ready-to-use sample projects and simulation scripts to demonstrate how projects can automatically extract provenance metadata, generate canonical Sourcelume 0.0.1 Provenance Records, validate them against schema definitions, and publish them to a Sourcelume Registry.

## Contents

- **`helloworld-sample/`**: A sample Java/Maven Hello World project configured with `sourcelume-maven-plugin`.
- **`helloworld-cmake-sample/`**: A sample C++/CMake Hello World project configured with `sourcelume-cmake-module`.
- **`simulate-run.sh`**: Automated simulation runner for Maven projects.
- **`simulate-run-cmake.sh`**: Automated simulation runner for CMake projects.

---

## Quick Simulation

Make sure the tooling plugin is installed in your local Maven repository (`~/.m2/repository`):

```bash
# From repository root
mvn clean install
```

Run the end-to-end simulation runner:

```bash
chmod +x examples/simulate-run.sh
./examples/simulate-run.sh
```

---

## Manual Execution Walkthrough

You can test individual goals directly in `examples/helloworld-sample`:

```bash
cd examples/helloworld-sample
```

### 1. Compile & Generate Provenance Record

Generates `${project.build.directory}/sourcelume/provenance-record.json` based on POM coordinates, developers, and license metadata:

```bash
mvn compile sourcelume:generate
```

You can inspect the generated JSON-LD spec file:

```bash
cat target/sourcelume/provenance-record.json
```

Example output:

```json
{
  "@context": "https://sourcelume.apache.org/context/0.0.1/sourcelume.jsonld",
  "id": "https://sourcelume.apache.org/records/rec-maven-org.apache.sourcelume.examples-sourcelume-helloworld-sample-1.0.0-SNAPSHOT",
  "type": "ProvenanceRecord",
  "identifier": "sourcelume://datasets/sample-helloworld-corpus-v1",
  "name": "Sourcelume Hello World Example Dataset",
  "version": "1.0.0-SNAPSHOT",
  "license": "https://spdx.org/licenses/Apache-2.0.html",
  "licenseCategory": "open-source",
  "licenseNote": "Apache-2.0 verified example dataset & code",
  "creator": [
    {
      "type": "schema:Organization",
      "name": "The Apache Software Foundation",
      "role": "originator"
    },
    {
      "type": "schema:Person",
      "name": "Sourcelume Example Contributor",
      "role": "originator"
    }
  ],
  "created": "2026-10-12T09:49:00Z",
  "added": "2026-10-12T09:49:00Z",
  "contentCreated": "2026-10-12T09:49:00Z",
  "origin": "Curated metadata from Maven POM: org.apache.sourcelume.examples:sourcelume-helloworld-sample:1.0.0-SNAPSHOT",
  "custodyChain": [
    {
      "agent": "https://sourcelume.apache.org/agents/maven-plugin",
      "action": "maven_build_and_provenance_generation",
      "startTime": "2026-10-12T09:49:00Z"
    }
  ]
}
```

### 2. Dry-Run Submission (Simulation Mode)

Simulate publishing without sending network traffic:

```bash
mvn sourcelume:publish -Dsourcelume.dryRun=true
```

### 3. Live Registry Validation & Submission (Localhost)

When running Apache Sourcelume Registry locally (`http://localhost:8082`):

```bash
# Validate against registry SHACL & JSON Schema validator
mvn sourcelume:validate -Dregistry.url=http://localhost:8082

# Publish record to registry
mvn sourcelume:publish -Dregistry.url=http://localhost:8082
```

Authentication flags can also be passed if required:

```bash
mvn sourcelume:publish \
  -Dregistry.url=http://localhost:8082 \
  -Dregistry.username=admin \
  -Dregistry.password=admin
```

---

## Manual Execution Walkthrough (CMake / C++)

You can also test the CMake module workflow directly in `examples/helloworld-cmake-sample`:

```bash
cd examples/helloworld-cmake-sample

# Build and generate provenance record
cmake -B build -DBUILD_TESTING=ON
cmake --build build
cmake --build build --target sourcelume_generate

# Dry-run publish
SOURCELUME_DRY_RUN=1 cmake --build build --target sourcelume_publish

# Live validation & publishing (when registry is running at localhost:8082)
cmake --build build --target sourcelume_validate
cmake --build build --target sourcelume_publish
```

---

## Verifying in Sourcelume Registry & Apache Atlas

Once published, you can query the record from the registry API or Apache Atlas:

```bash
# Query record by ID
curl -s http://localhost:8082/records/urn%3Asourcelume%3Amaven%3Aorg.apache.sourcelume.examples%3Asourcelume-helloworld-sample%3A1.0.0-SNAPSHOT | jq .

# Or query dataset in Atlas
curl -s "http://localhost:8082/api/v1/datasets?qualifiedName=urn%3Asourcelume%3Amaven%3Aorg.apache.sourcelume.examples%3Asourcelume-helloworld-sample%3A1.0.0-SNAPSHOT" | jq .
```
