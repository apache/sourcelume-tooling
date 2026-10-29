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

# Apache Sourcelume Tooling (`sourcelume-tooling`)

> Tooling support and build system plugins to automate generating, validating, and submitting Apache Sourcelume specification records to a Sourcelume Registry.

## Overview

Apache Sourcelume Tooling simplifies the process by which projects describe their dataset provenance and submit signed metadata records to an Apache Sourcelume Registry instance.

This repository provides native plugins and modules for various build ecosystems:
- **`sourcelume-maven-plugin`** (JVM / Maven)
- **`sourcelume-cmake-module`** (C / C++ / CMake)
- **`sourcelume-python-plugin`** (Python)
- **`sourcelume-gradle-plugin`** *(Roadmap - JVM / Gradle)*
- **`sourcelume-hatch-plugin`** *(Roadmap - Python / Hatch)*

---

## Sourcelume Python Plugin (`sourcelume-python-plugin`)

The `sourcelume-python-plugin` extracts metadata directly from a project's `pyproject.toml` (coordinates, organization, developers, license), generates canonical [Sourcelume 0.0.1 Provenance Records](https://sourcelume.apache.org/schema/0.0.1/sourcelume.schema.json), validates them against the registry schema, and publishes them to the registry.

### Goals

| Goal | Description | Default Lifecycle Phase |
|---|---|---|
| `sourcelume generate` | Generates a `provenance-record.json` spec file from project metadata. | - |
| `sourcelume validate` | Validates the spec against the registry's `/records/validate` endpoint. | - |
| `sourcelume publish` | Submits the generated spec to the registry (`POST /records`). | - |
| `sourcelume help` | Displays help and configuration options for the plugin. | - |

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

## Sourcelume CMake Module (`sourcelume-cmake-module`)

The `sourcelume-cmake-module` brings Sourcelume specification generation, validation, and submission support to C and C++ projects using CMake.

### Targets

| Target | Description |
|---|---|
| `sourcelume_generate` / `sourcelume-generate` | Generates a `provenance-record.json` spec file from CMake project metadata. |
| `sourcelume_validate` / `sourcelume-validate` | Validates the spec against the registry's `/records/validate` endpoint. |
| `sourcelume_publish` / `sourcelume-publish` | Submits the generated spec to the registry (`POST /records`). |

---

## Building and Testing

Prerequisites:
- Java 17+
- Maven 3.9+
- CMake 3.19+
- Python 3.9+

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

### Python Plugin
```bash
cd plugins/sourcelume-python-plugin

# Install the plugin
pip install .

# Run tests
pytest
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
- Python Sample: `cd examples/helloworld-python-sample && sourcelume generate .`

## License

Licensed under the [Apache License, Version 2.0](LICENSE).
