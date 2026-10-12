# Apache Sourcelume Tooling (`sourcelume-tooling`)

> Tooling support and build system plugins to automate generating, validating, and submitting Apache Sourcelume specification records to a Sourcelume Registry.

## Overview

Apache Sourcelume Tooling simplifies the process by which projects describe their dataset provenance and submit signed metadata records to an Apache Sourcelume Registry instance.

This repository provides native plugins and modules for various build ecosystems:
- **`sourcelume-maven-plugin`** (JVM / Maven)
- **`sourcelume-cmake-module`** (C / C++ / CMake)
- **`sourcelume-gradle-plugin`** *(Roadmap - JVM / Gradle)*
- **`sourcelume-hatch-plugin`** *(Roadmap - Python / Hatch)*

---

## Sourcelume Maven Plugin (`sourcelume-maven-plugin`)

The `sourcelume-maven-plugin` extracts metadata directly from a project's `pom.xml` (coordinates, organization, developers, license, SCM repositories), generates canonical [Sourcelume 0.0.1 Provenance Records](https://sourcelume.apache.org/schema/0.0.1/sourcelume.schema.json), validates them against the registry schema, and publishes them to the registry.

### Goals

| Goal | Description | Default Lifecycle Phase |
|---|---|---|
| `sourcelume:generate` | Generates a `provenance-record.json` spec file from POM metadata. | `prepare-package` |
| `sourcelume:validate` | Validates the spec against the registry's `/records/validate` endpoint. | `verify` |
| `sourcelume:publish` | Submits the generated spec to the registry (`POST /records`). | `deploy` |
| `sourcelume:help` | Displays help and configuration options for the plugin. | - |

---

### Quickstart & Usage

#### 1. Command-Line Execution (Ad-hoc)

Submit a Maven project's provenance spec directly from the CLI:

```bash
mvn org.apache.sourcelume:sourcelume-maven-plugin:0.0.1-SNAPSHOT:publish \
  -Dregistry.url=https://registry.example.org \
  -Dregistry.username="$REGISTRY_USERNAME" \
  -Dregistry.password="$REGISTRY_PASSWORD"
```

Or with a bearer token:

```bash
mvn org.apache.sourcelume:sourcelume-maven-plugin:0.0.1-SNAPSHOT:publish \
  -Dregistry.url=https://registry.example.org \
  -Dregistry.token="$REGISTRY_TOKEN"
```

To run a dry run without submitting data:

```bash
mvn org.apache.sourcelume:sourcelume-maven-plugin:0.0.1-SNAPSHOT:publish \
  -Dsourcelume.dryRun=true
```

#### 2. Declarative POM Configuration

Add the plugin to your `pom.xml`:

```xml
<project>
  ...
  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.sourcelume</groupId>
        <artifactId>sourcelume-maven-plugin</artifactId>
        <version>0.0.1-SNAPSHOT</version>
        <configuration>
          <registryUrl>https://registry.example.org</registryUrl>
          <licenseCategory>open-source</licenseCategory>
          <licenseNote>Permissive open source training data</licenseNote>
          <!-- Optional custom overrides -->
          <!-- <datasetIdentifier>doi:10.1234/example-dataset</datasetIdentifier> -->
          <!-- <datasetName>Custom Training Dataset</datasetName> -->
        </configuration>
        <executions>
          <execution>
            <id>sourcelume-generate</id>
            <goals>
              <goal>generate</goal>
            </goals>
          </execution>
          <execution>
            <id>sourcelume-publish</id>
            <goals>
              <goal>publish</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
    </plugins>
  </build>
</project>
```

---

### Configuration Reference

| Parameter | System Property / CLI Flag | Environment Variable | Default Value | Description |
|---|---|---|---|---|
| `registryUrl` | `-Dregistry.url` | `SOURCELUME_REGISTRY_URL` | `http://localhost:8082` | URL of the Sourcelume Registry. |
| `username` | `-Dregistry.username` | `SOURCELUME_REGISTRY_USERNAME` | - | Registry username for HTTP Basic Auth. |
| `password` | `-Dregistry.password` | `SOURCELUME_REGISTRY_PASSWORD` | - | Registry password for HTTP Basic Auth. |
| `token` | `-Dregistry.token` | `SOURCELUME_REGISTRY_TOKEN` | - | Bearer token for authentication. |
| `dryRun` | `-Dsourcelume.dryRun` | - | `false` | If true, logs payloads without sending to the registry. |
| `failOnError` | `-Dsourcelume.failOnError` | - | `true` | If true, failures stop the Maven build. |
| `skip` | `-Dsourcelume.skip` | - | `false` | Skips plugin execution. |
| `outputFile` | `-Dsourcelume.outputFile` | - | `${project.build.directory}/sourcelume/provenance-record.json` | Path to generated JSON-LD spec. |
| `recordFile` | `-Dsourcelume.recordFile` | - | - | Path to pre-existing JSON-LD record file to submit. |
| `datasetIdentifier` | `-Dsourcelume.datasetIdentifier`| - | `sourcelume://maven/${groupId}/${artifactId}` | Dataset persistent identifier. |
| `datasetName` | `-Dsourcelume.datasetName` | - | `${project.name}` / `${artifactId}` | Dataset title or name. |
| `license` | `-Dsourcelume.license` | - | Derived from POM | License name, URL, or SPDX IRI. |
| `licenseCategory` | `-Dsourcelume.licenseCategory` | - | `open-source` | Category (e.g. `open-source`, `open-data`, `public-domain`). |

---

## Sourcelume CMake Module (`sourcelume-cmake-module`)

The `sourcelume-cmake-module` brings Sourcelume specification generation, validation, and submission support to C and C++ projects using CMake.

### Targets

| Target | Description |
|---|---|
| `sourcelume_generate` / `sourcelume-generate` | Generates a `provenance-record.json` spec file from CMake project metadata. |
| `sourcelume_validate` / `sourcelume-validate` | Validates the spec against the registry's `/records/validate` endpoint. |
| `sourcelume_publish` / `sourcelume-publish` | Submits the generated spec to the registry (`POST /records`). |

### Quickstart & Usage

Include the module in `CMakeLists.txt`:

```cmake
cmake_minimum_required(VERSION 3.19)
project(my-cpp-project VERSION 1.0.0 LANGUAGES CXX)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(Sourcelume)

sourcelume_enable(
    REGISTRY_URL "http://localhost:8082"
    LICENSE "Apache-2.0"
    LICENSE_CATEGORY "open-source"
    LICENSE_NOTE "Permissive open source dataset"
    DATASET_IDENTIFIER "sourcelume://datasets/sample-cpp-dataset-v1"
    DATASET_NAME "My C++ Training Dataset"
)
```

Run target commands:

```bash
# Configure the build directory
cmake -B build

# Generate spec
cmake --build build --target sourcelume_generate

# Dry run publish
SOURCELUME_DRY_RUN=1 cmake --build build --target sourcelume_publish

# Publish to live registry
cmake --build build --target sourcelume_publish
```

---

## Building and Testing

Prerequisites:
- Java 17+
- Maven 3.9+
- CMake 3.19+

### Maven Tooling

```bash
# Build and run all Maven tests
mvn clean test

# Install locally to test with sample Maven projects
mvn clean install
```

### CMake Module

```bash
cd plugins/sourcelume-cmake-module

# Configure build directory with testing enabled
cmake -B build -DBUILD_TESTING=ON

# Generate module provenance record
cmake --build build --target sourcelume_generate

# Run module test suite
ctest --test-dir build --output-on-failure
```

### C++ Sample Application

```bash
cd examples/helloworld-cmake-sample

# Configure and compile
cmake -B build -DBUILD_TESTING=ON
cmake --build build

# Run application tests
ctest --test-dir build --output-on-failure

# Generate sample provenance record
cmake --build build --target sourcelume_generate
```

## Running Examples & Simulation

Ready-to-run sample projects and simulation scripts are provided in the `examples/` directory:

```bash
# Run automated simulation for Maven
./examples/simulate-run.sh

# Run automated simulation for CMake
./examples/simulate-run-cmake.sh
```

Or explore the sample projects directly:
- Maven Sample: `cd examples/helloworld-sample && mvn compile sourcelume:generate`
- CMake Sample: `cd examples/helloworld-cmake-sample && cmake -B build && cmake --build build --target sourcelume_generate`

See [examples/README.md](examples/README.md) for full details and live registry verification instructions.

## License

Licensed under the [Apache License, Version 2.0](LICENSE).
