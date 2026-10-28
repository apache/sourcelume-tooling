#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include("${CMAKE_CURRENT_LIST_DIR}/../cmake/Sourcelume.cmake")

set(TEST_TMP_DIR "${CMAKE_CURRENT_BINARY_DIR}/tmp_test_record_gen")
set(OUT_FILE "${TEST_TMP_DIR}/test-provenance-record.json")

file(REMOVE_RECURSE "${TEST_TMP_DIR}")

sourcelume_generate(
    PROJECT_NAME "test-cpp-dataset"
    VERSION "2.4.0"
    OUTPUT_FILE "${OUT_FILE}"
    RECORD_ID "urn:sourcelume:cmake:org.apache.sourcelume:test-cpp-dataset:2.4.0"
    DATASET_IDENTIFIER "sourcelume://datasets/test-cpp-corpus-v2"
    DATASET_NAME "Test C++ Dataset Corpus"
    LICENSE "Apache-2.0"
    LICENSE_CATEGORY "open-source"
    LICENSE_NOTE "Permissive open-source C++ test dataset"
    ORIGIN "https://github.com/apache/sourcelume-tooling.git"
    CREATOR_NAME "The Apache Software Foundation"
    CREATOR_TYPE "schema:Organization"
    CREATOR_ROLE "originator"
    CUSTODY_AGENT "https://sourcelume.apache.org/agents/cmake-module"
    CUSTODY_ACTION "cmake_build_and_provenance_generation"
    CREATED "2026-10-12T12:00:00Z"
)

if(NOT EXISTS "${OUT_FILE}")
    message(FATAL_ERROR "Output file was not created: ${OUT_FILE}")
endif()

file(READ "${OUT_FILE}" RECORD_CONTENT)

# Validate JSON structure using string(JSON)
string(JSON CONTEXT GET "${RECORD_CONTENT}" "@context")
if(NOT CONTEXT STREQUAL "https://sourcelume.apache.org/context/0.0.1/sourcelume.jsonld")
    message(FATAL_ERROR "@context mismatch: ${CONTEXT}")
endif()

string(JSON REC_ID GET "${RECORD_CONTENT}" "id")
if(NOT REC_ID STREQUAL "urn:sourcelume:cmake:org.apache.sourcelume:test-cpp-dataset:2.4.0")
    message(FATAL_ERROR "id mismatch: ${REC_ID}")
endif()

string(JSON REC_TYPE GET "${RECORD_CONTENT}" "type")
if(NOT REC_TYPE STREQUAL "ProvenanceRecord")
    message(FATAL_ERROR "type mismatch: ${REC_TYPE}")
endif()

string(JSON REC_IDENTIFIER GET "${RECORD_CONTENT}" "identifier")
if(NOT REC_IDENTIFIER STREQUAL "sourcelume://datasets/test-cpp-corpus-v2")
    message(FATAL_ERROR "identifier mismatch: ${REC_IDENTIFIER}")
endif()

string(JSON REC_NAME GET "${RECORD_CONTENT}" "name")
if(NOT REC_NAME STREQUAL "Test C++ Dataset Corpus")
    message(FATAL_ERROR "name mismatch: ${REC_NAME}")
endif()

string(JSON REC_VERSION GET "${RECORD_CONTENT}" "version")
if(NOT REC_VERSION STREQUAL "2.4.0")
    message(FATAL_ERROR "version mismatch: ${REC_VERSION}")
endif()

string(JSON REC_LICENSE GET "${RECORD_CONTENT}" "license")
if(NOT REC_LICENSE STREQUAL "https://spdx.org/licenses/Apache-2.0.html")
    message(FATAL_ERROR "license mismatch: ${REC_LICENSE}")
endif()

string(JSON CREATOR_NAME GET "${RECORD_CONTENT}" "creator" 0 "name")
if(NOT CREATOR_NAME STREQUAL "The Apache Software Foundation")
    message(FATAL_ERROR "creator name mismatch: ${CREATOR_NAME}")
endif()

string(JSON CUSTODY_AGENT GET "${RECORD_CONTENT}" "custodyChain" 0 "agent")
if(NOT CUSTODY_AGENT STREQUAL "https://sourcelume.apache.org/agents/cmake-module")
    message(FATAL_ERROR "custody agent mismatch: ${CUSTODY_AGENT}")
endif()

file(REMOVE_RECURSE "${TEST_TMP_DIR}")
message(STATUS "Provenance record generation assertions passed!")
