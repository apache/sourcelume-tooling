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

# Apache Sourcelume CMake Module (`sourcelume-cmake-module`)

> CMake module for automating generating, validating, and submitting Apache Sourcelume specification records to a Sourcelume Registry for C/C++ projects.

## Overview

The `sourcelume-cmake-module` extracts project metadata (coordinates, project name, version, license, git origin, author/vendor), generates canonical [Sourcelume 0.0.1 Provenance Records](https://sourcelume.apache.org/schema/0.0.1/sourcelume.schema.json), validates them against the registry schema, and publishes them to the registry.

## Quickstart & Usage

### 1. In your `CMakeLists.txt`

Include the module or find package:

```cmake
cmake_minimum_required(VERSION 3.19)
project(my-cpp-project VERSION 1.0.0 LANGUAGES CXX)

# Include Sourcelume module
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(Sourcelume)

# Enable Sourcelume targets
sourcelume_enable(
    REGISTRY_URL "http://localhost:8082"
    LICENSE "Apache-2.0"
    LICENSE_CATEGORY "open-source"
    LICENSE_NOTE "Apache-2.0 verified C++ project"
    DATASET_IDENTIFIER "sourcelume://datasets/my-cpp-dataset-v1"
    DATASET_NAME "My C++ Example Dataset"
)
```

### 2. Available CMake Custom Targets

When `sourcelume_enable()` is configured, the following targets are registered in your build system:

| Target | Description |
|---|---|
| `sourcelume_generate` / `sourcelume-generate` | Generates `provenance-record.json` spec file from CMake project metadata. |
| `sourcelume_validate` / `sourcelume-validate` | Validates the spec against the registry's `/records/validate` endpoint. |
| `sourcelume_publish` / `sourcelume-publish` | Submits the generated spec to the registry (`POST /records`). |

To execute targets using CMake:

```bash
# 1. Configure build directory
cmake -B build

# 2. Generate Provenance Record
cmake --build build --target sourcelume_generate

# 3. Validate against Sourcelume Registry
cmake --build build --target sourcelume_validate

# 4. Publish to Registry
cmake --build build --target sourcelume_publish
```

### 3. Building & Testing this Module

To build and run tests for the `sourcelume-cmake-module` itself:

```bash
# Configure with testing enabled
cmake -B build -DBUILD_TESTING=ON

# Generate module provenance record
cmake --build build --target sourcelume_generate

# Execute module test suite
ctest --test-dir build --output-on-failure
```

### 4. Dry-Run & Command Line Options

You can pass options via CMake cache flags or environment variables:

```bash
# Dry run without network calls
cmake --build build --target sourcelume_publish -- -Dsourcelume.dryRun=true
# Or with environment variable
SOURCELUME_DRY_RUN=1 cmake --build build --target sourcelume_publish

# Override registry endpoint and credentials
SOURCELUME_REGISTRY_URL="https://registry.example.org" \
SOURCELUME_REGISTRY_TOKEN="<token>" \
cmake --build build --target sourcelume_publish
```

### 5. Direct Script Execution Mode

You can also run the module standalone via `cmake -P`:

```bash
cmake -DSOURCELUME_ACTION=generate \
      -DSOURCELUME_PROJECT_NAME=my-project \
      -DSOURCELUME_VERSION=1.0.0 \
      -DSOURCELUME_LICENSE=MIT \
      -DSOURCELUME_OUTPUT_FILE=build/sourcelume/provenance-record.json \
      -P cmake/Sourcelume.cmake
```

## Configuration Reference

| Parameter | Environment Variable | Default Value | Description |
|---|---|---|---|
| `REGISTRY_URL` | `SOURCELUME_REGISTRY_URL` | `http://localhost:8082` | URL of the Sourcelume Registry. |
| `USERNAME` | `SOURCELUME_REGISTRY_USERNAME` | - | Registry username for HTTP Basic Auth. |
| `PASSWORD` | `SOURCELUME_REGISTRY_PASSWORD` | - | Registry password for HTTP Basic Auth. |
| `TOKEN` | `SOURCELUME_REGISTRY_TOKEN` | - | Bearer token for authentication. |
| `DRY_RUN` | `SOURCELUME_DRY_RUN` | `FALSE` | If true, logs payloads without sending to the registry. |
| `FAIL_ON_ERROR` | `SOURCELUME_FAIL_ON_ERROR` | `TRUE` | If true, failures abort the build. |
| `OUTPUT_FILE` | `SOURCELUME_OUTPUT_FILE` | `${CMAKE_CURRENT_BINARY_DIR}/sourcelume/provenance-record.json` | Path to generated JSON-LD spec. |
| `RECORD_ID` | `SOURCELUME_RECORD_ID` | `urn:sourcelume:cmake:${PROJECT_NAME}:${PROJECT_VERSION}` | Provenance Record ID. |
| `DATASET_IDENTIFIER` | `SOURCELUME_DATASET_IDENTIFIER` | `sourcelume://cmake/${PROJECT_NAME}` | Persistent dataset identifier. |
| `DATASET_NAME` | `SOURCELUME_DATASET_NAME` | `${PROJECT_DESCRIPTION}` / `${PROJECT_NAME}` | Dataset title or name. |
| `LICENSE` | `SOURCELUME_LICENSE` | `Apache-2.0` | License name, URL, or SPDX IRI. |
| `LICENSE_CATEGORY` | `SOURCELUME_LICENSE_CATEGORY` | `open-source` | License category. |
| `LICENSE_NOTE` | `SOURCELUME_LICENSE_NOTE` | - | Note or description regarding dataset licensing. |
| `ORIGIN` | `SOURCELUME_ORIGIN` | Derived from git / `PROJECT_HOMEPAGE_URL` | Dataset or codebase origin URI. |

## License

Licensed under the [Apache License, Version 2.0](LICENSE).
