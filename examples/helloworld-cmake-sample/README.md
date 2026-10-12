# Apache Sourcelume C++ Hello World Sample

This sample demonstrates how a C / C++ CMake project can integrate `sourcelume-cmake-module` to automatically generate, validate, and publish canonical Sourcelume 0.0.1 Provenance Records to a Sourcelume Registry.

## Project Structure

```
helloworld-cmake-sample/
├── CMakeLists.txt
├── README.md
├── src/
│   ├── hello.hpp
│   ├── hello.cpp
│   └── main.cpp
└── test/
    └── test_hello.cpp
```

## Quickstart

### 1. Build and Test the Application

```bash
# Configure build directory
cmake -B build -DBUILD_TESTING=ON

# Compile executable and test binary
cmake --build build

# Run unit tests
ctest --test-dir build --output-on-failure
```

### 2. Generate Provenance Record

Generates `${CMAKE_CURRENT_BINARY_DIR}/sourcelume/provenance-record.json` based on CMake project coordinates, license, origin, and custody metadata:

```bash
cmake --build build --target sourcelume_generate
```

You can inspect the generated JSON-LD spec file:

```bash
cat build/sourcelume/provenance-record.json
```

Example output:

```json
{
  "@context": "https://sourcelume.apache.org/context/0.0.1/sourcelume.jsonld",
  "id": "urn:sourcelume:cmake:org.apache.sourcelume.examples:sourcelume-helloworld-cmake-sample:1.0.0",
  "type": "ProvenanceRecord",
  "identifier": "sourcelume://datasets/sample-helloworld-cmake-corpus-v1",
  "name": "Sourcelume Hello World C++ Example Dataset",
  "version": "1.0.0",
  "license": "https://spdx.org/licenses/Apache-2.0.html",
  "licenseCategory": "open-source",
  "licenseNote": "Apache-2.0 verified C++ example dataset & code",
  "creator": [
    {
      "type": "schema:Organization",
      "name": "The Apache Software Foundation",
      "role": "originator"
    }
  ],
  "created": "2026-10-12T12:00:00Z",
  "added": "2026-10-12T12:00:00Z",
  "contentCreated": "2026-10-12T12:00:00Z",
  "origin": "https://github.com/apache/sourcelume-tooling/tree/main/examples/helloworld-cmake-sample",
  "custodyChain": [
    {
      "agent": "https://sourcelume.apache.org/agents/cmake-module",
      "action": "cmake_build_and_provenance_generation",
      "startTime": "2026-10-12T12:00:00Z"
    }
  ]
}
```

### 3. Dry-Run Submission (Simulation Mode)

Simulate publishing without making network calls:

```bash
SOURCELUME_DRY_RUN=1 cmake --build build --target sourcelume_publish
```

### 4. Live Validation & Registry Submission

When running Apache Sourcelume Registry locally (`http://localhost:8082`):

```bash
# Validate against registry SHACL & JSON Schema validator
cmake --build build --target sourcelume_validate

# Publish record to registry
cmake --build build --target sourcelume_publish
```

Authentication flags can also be passed via environment variables or CMake properties:

```bash
SOURCELUME_REGISTRY_URL="http://localhost:8082" \
SOURCELUME_REGISTRY_USERNAME="admin" \
SOURCELUME_REGISTRY_PASSWORD="admin" \
cmake --build build --target sourcelume_publish
```
