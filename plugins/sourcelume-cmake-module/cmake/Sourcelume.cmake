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

#[=======================================================================[.rst:
Sourcelume
----------

Apache Sourcelume CMake module for generating, validating, and submitting
canonical Sourcelume Provenance Records (JSON-LD) to a Sourcelume Registry.

Functions
^^^^^^^^^

::

  sourcelume_enable(
      [RECORD_ID <id>]
      [DATASET_IDENTIFIER <uri>]
      [DATASET_NAME <name>]
      [VERSION <version>]
      [LICENSE <license>]
      [LICENSE_CATEGORY <category>]
      [LICENSE_NOTE <note>]
      [LICENSE_SCOPE <scope>]
      [ORIGIN <origin>]
      [CREATOR_NAME <name>]
      [CREATOR_TYPE <type>]
      [CREATOR_ROLE <role>]
      [CUSTODY_AGENT <agent>]
      [CUSTODY_ACTION <action>]
      [REGISTRY_URL <url>]
      [USERNAME <username>]
      [PASSWORD <password>]
      [TOKEN <token>]
      [OUTPUT_FILE <path>]
      [FAIL_ON_ERROR <TRUE|FALSE>]
      [DRY_RUN <TRUE|FALSE>]
      [ALLOW_CONFLICT <TRUE|FALSE>]
  )

  sourcelume_generate(...)
  sourcelume_validate(...)
  sourcelume_publish(...)

Custom Targets
^^^^^^^^^^^^^^

When ``sourcelume_enable()`` is called, the following targets are defined:
- ``sourcelume_generate`` (alias: ``sourcelume-generate``)
- ``sourcelume_validate`` (alias: ``sourcelume-validate``)
- ``sourcelume_publish``  (alias: ``sourcelume-publish``)

#]=======================================================================]

cmake_minimum_required(VERSION 3.19)

# -----------------------------------------------------------------------------
# Utility: Escape JSON strings
# -----------------------------------------------------------------------------
function(_sourcelume_escape_json INPUT_STR OUTPUT_VAR)
    string(REPLACE "\\" "\\\\" _ESC "${INPUT_STR}")
    string(REPLACE "\"" "\\\"" _ESC "${_ESC}")
    string(REPLACE "\n" "\\n" _ESC "${_ESC}")
    string(REPLACE "\r" "\\r" _ESC "${_ESC}")
    string(REPLACE "\t" "\\t" _ESC "${_ESC}")
    set(${OUTPUT_VAR} "${_ESC}" PARENT_SCOPE)
endfunction()

# -----------------------------------------------------------------------------
# Utility: Format the validationIssues of a registry answer as "  - path: message"
# lines (the registry sends them as a JSON array inside a string)
# -----------------------------------------------------------------------------
function(_sourcelume_issue_lines RESP_BODY OUTPUT_VAR)
    set(_LINES "")
    string(JSON _ISSUES ERROR_VARIABLE _ERR GET "${RESP_BODY}" "validationIssues")
    if(NOT _ERR)
        string(JSON _COUNT ERROR_VARIABLE _ERR LENGTH "${_ISSUES}")
        if(_ERR)
            string(APPEND _LINES "\n  - ${_ISSUES}")
        elseif(_COUNT GREATER 0)
            math(EXPR _LAST "${_COUNT} - 1")
            foreach(_I RANGE ${_LAST})
                string(JSON _PATH ERROR_VARIABLE _PATH_ERR GET "${_ISSUES}" ${_I} "path")
                string(JSON _MESSAGE ERROR_VARIABLE _MESSAGE_ERR GET "${_ISSUES}" ${_I} "message")
                if(_PATH_ERR OR _PATH STREQUAL "")
                    string(APPEND _LINES "\n  - ${_MESSAGE}")
                else()
                    string(APPEND _LINES "\n  - ${_PATH}: ${_MESSAGE}")
                endif()
            endforeach()
        endif()
    endif()
    set(${OUTPUT_VAR} "${_LINES}" PARENT_SCOPE)
endfunction()

# -----------------------------------------------------------------------------
# Utility: Map license input to canonical SPDX IRI
# -----------------------------------------------------------------------------
function(_sourcelume_to_spdx_iri INPUT_LIC OUTPUT_VAR)
    if(NOT INPUT_LIC OR INPUT_LIC STREQUAL "")
        set(${OUTPUT_VAR} "https://spdx.org/licenses/Apache-2.0.html" PARENT_SCOPE)
        return()
    endif()

    string(STRIP "${INPUT_LIC}" _LIC_CLEAN)
    string(TOLOWER "${_LIC_CLEAN}" _NORM)

    # Apache Licenses
    if(_NORM STREQUAL "apache-2.0" OR _NORM STREQUAL "apache 2.0" OR _NORM STREQUAL "apache-2"
        OR _NORM STREQUAL "apache license, version 2.0" OR _NORM STREQUAL "apache license 2.0"
        OR _NORM STREQUAL "the apache software license, version 2.0"
        OR _NORM STREQUAL "the apache license, version 2.0"
        OR _NORM STREQUAL "http://www.apache.org/licenses/license-2.0.txt"
        OR _NORM STREQUAL "https://www.apache.org/licenses/license-2.0.txt"
        OR _NORM STREQUAL "http://www.apache.org/licenses/license-2.0"
        OR _NORM STREQUAL "https://www.apache.org/licenses/license-2.0"
        OR _NORM STREQUAL "http://www.apache.org/licenses/license-2.0.html"
        OR _NORM STREQUAL "https://www.apache.org/licenses/license-2.0.html")
        set(${OUTPUT_VAR} "https://spdx.org/licenses/Apache-2.0.html" PARENT_SCOPE)
        return()
    endif()

    # MIT
    if(_NORM STREQUAL "mit" OR _NORM STREQUAL "mit license" OR _NORM STREQUAL "the mit license"
        OR _NORM STREQUAL "http://opensource.org/licenses/mit"
        OR _NORM STREQUAL "https://opensource.org/licenses/mit")
        set(${OUTPUT_VAR} "https://spdx.org/licenses/MIT.html" PARENT_SCOPE)
        return()
    endif()

    # BSD Licenses
    if(_NORM STREQUAL "bsd-3-clause" OR _NORM STREQUAL "bsd 3-clause" OR _NORM STREQUAL "bsd-3"
        OR _NORM STREQUAL "the 3-clause bsd license" OR _NORM STREQUAL "revised bsd license"
        OR _NORM STREQUAL "new bsd license")
        set(${OUTPUT_VAR} "https://spdx.org/licenses/BSD-3-Clause.html" PARENT_SCOPE)
        return()
    endif()

    if(_NORM STREQUAL "bsd-2-clause" OR _NORM STREQUAL "bsd 2-clause" OR _NORM STREQUAL "bsd-2"
        OR _NORM STREQUAL "simplified bsd license")
        set(${OUTPUT_VAR} "https://spdx.org/licenses/BSD-2-Clause.html" PARENT_SCOPE)
        return()
    endif()

    # Creative Commons & Open Data
    if(_NORM STREQUAL "cc0" OR _NORM STREQUAL "cc0-1.0" OR _NORM STREQUAL "cc0 1.0"
        OR _NORM STREQUAL "cc0 1.0 universal" OR _NORM STREQUAL "public domain")
        set(${OUTPUT_VAR} "https://spdx.org/licenses/CC0-1.0.html" PARENT_SCOPE)
        return()
    endif()

    if(_NORM STREQUAL "cc-by-4.0" OR _NORM STREQUAL "cc by 4.0"
        OR _NORM STREQUAL "creative commons attribution 4.0"
        OR _NORM STREQUAL "creative commons attribution 4.0 international")
        set(${OUTPUT_VAR} "https://spdx.org/licenses/CC-BY-4.0.html" PARENT_SCOPE)
        return()
    endif()

    if(_NORM STREQUAL "odc-by" OR _NORM STREQUAL "odc-by-1.0"
        OR _NORM STREQUAL "open data commons attribution license")
        set(${OUTPUT_VAR} "https://spdx.org/licenses/ODC-By-1.0.html" PARENT_SCOPE)
        return()
    endif()

    if(_NORM STREQUAL "odbl" OR _NORM STREQUAL "odbl-1.0"
        OR _NORM STREQUAL "open database license")
        set(${OUTPUT_VAR} "https://spdx.org/licenses/ODbL-1.0.html" PARENT_SCOPE)
        return()
    endif()

    # Eclipse Public License
    if(_NORM STREQUAL "epl-2.0" OR _NORM STREQUAL "epl 2.0"
        OR _NORM STREQUAL "eclipse public license 2.0"
        OR _NORM STREQUAL "eclipse public license - v 2.0")
        set(${OUTPUT_VAR} "https://spdx.org/licenses/EPL-2.0.html" PARENT_SCOPE)
        return()
    endif()

    if(_NORM STREQUAL "epl-1.0" OR _NORM STREQUAL "epl 1.0"
        OR _NORM STREQUAL "eclipse public license 1.0"
        OR _NORM STREQUAL "eclipse public license - v 1.0")
        set(${OUTPUT_VAR} "https://spdx.org/licenses/EPL-1.0.html" PARENT_SCOPE)
        return()
    endif()

    # GNU Licenses
    if(_NORM STREQUAL "gpl-3.0" OR _NORM STREQUAL "gpl-3.0-only" OR _NORM STREQUAL "gpl 3.0"
        OR _NORM STREQUAL "gnu general public license v3.0")
        set(${OUTPUT_VAR} "https://spdx.org/licenses/GPL-3.0-only.html" PARENT_SCOPE)
        return()
    endif()

    if(_NORM STREQUAL "lgpl-3.0" OR _NORM STREQUAL "lgpl-3.0-only" OR _NORM STREQUAL "lgpl 3.0"
        OR _NORM STREQUAL "gnu lesser general public license v3.0")
        set(${OUTPUT_VAR} "https://spdx.org/licenses/LGPL-3.0-only.html" PARENT_SCOPE)
        return()
    endif()

    # If already an SPDX URL
    if(_LIC_CLEAN MATCHES "^https?://spdx\\.org/licenses/")
        if(_LIC_CLEAN MATCHES "^http://")
            string(SUBSTRING "${_LIC_CLEAN}" 7 -1 _REST)
            set(${OUTPUT_VAR} "https://${_REST}" PARENT_SCOPE)
        else()
            set(${OUTPUT_VAR} "${_LIC_CLEAN}" PARENT_SCOPE)
        endif()
        return()
    endif()

    # If starts with http://, https://, or urn:
    if(_LIC_CLEAN MATCHES "^(https?://|urn:)")
        set(${OUTPUT_VAR} "${_LIC_CLEAN}" PARENT_SCOPE)
        return()
    endif()

    # Default fallback construct standard SPDX IRI
    string(REGEX REPLACE "[ \t\r\n]+" "-" _SPDX_ID "${_LIC_CLEAN}")
    set(${OUTPUT_VAR} "https://spdx.org/licenses/${_SPDX_ID}.html" PARENT_SCOPE)
endfunction()

# -----------------------------------------------------------------------------
# Core Function: Generate Sourcelume Provenance Record JSON
# -----------------------------------------------------------------------------
function(sourcelume_generate)
    set(options FAIL_ON_ERROR DRY_RUN)
    set(oneValueArgs
        TARGET_NAME
        PROJECT_NAME
        OUTPUT_FILE
        RECORD_ID
        DATASET_IDENTIFIER
        DATASET_NAME
        VERSION
        LICENSE
        LICENSE_CATEGORY
        LICENSE_NOTE
        LICENSE_SCOPE
        ORIGIN
        CREATOR_NAME
        CREATOR_TYPE
        CREATOR_ROLE
        CUSTODY_AGENT
        CUSTODY_ACTION
        CREATED
        ADDED
        CONTENT_CREATED
    )
    cmake_parse_arguments(SL "${options}" "${oneValueArgs}" "" ${ARGN})

    # Resolve Project / Target name
    if(NOT SL_PROJECT_NAME)
        if(CMAKE_PROJECT_NAME)
            set(SL_PROJECT_NAME "${CMAKE_PROJECT_NAME}")
        elseif(PROJECT_NAME)
            set(SL_PROJECT_NAME "${PROJECT_NAME}")
        else()
            set(SL_PROJECT_NAME "unknown-cmake-project")
        endif()
    endif()

    # Resolve Version
    if(NOT SL_VERSION)
        if(PROJECT_VERSION)
            set(SL_VERSION "${PROJECT_VERSION}")
        elseif(CMAKE_PROJECT_VERSION)
            set(SL_VERSION "${CMAKE_PROJECT_VERSION}")
        else()
            set(SL_VERSION "0.0.1")
        endif()
    endif()

    # Output File
    if(NOT SL_OUTPUT_FILE)
        if(CMAKE_CURRENT_BINARY_DIR)
            set(SL_OUTPUT_FILE "${CMAKE_CURRENT_BINARY_DIR}/sourcelume/provenance-record.json")
        else()
            set(SL_OUTPUT_FILE "${CMAKE_BINARY_DIR}/sourcelume/provenance-record.json")
        endif()
    endif()

    # Record ID
    if(NOT SL_RECORD_ID)
        set(SL_RECORD_ID "urn:sourcelume:cmake:${SL_PROJECT_NAME}:${SL_VERSION}")
    endif()

    # Dataset Identifier
    if(NOT SL_DATASET_IDENTIFIER)
        set(SL_DATASET_IDENTIFIER "sourcelume://cmake/${SL_PROJECT_NAME}")
    endif()

    # Dataset Name
    if(NOT SL_DATASET_NAME)
        if(PROJECT_DESCRIPTION AND NOT PROJECT_DESCRIPTION STREQUAL "")
            set(SL_DATASET_NAME "${PROJECT_DESCRIPTION}")
        else()
            set(SL_DATASET_NAME "${SL_PROJECT_NAME}")
        endif()
    endif()

    # License
    if(NOT SL_LICENSE)
        set(SL_LICENSE "Apache-2.0")
    endif()
    _sourcelume_to_spdx_iri("${SL_LICENSE}" SL_RESOLVED_LICENSE)

    # License Category
    if(NOT SL_LICENSE_CATEGORY)
        set(SL_LICENSE_CATEGORY "open-source")
    endif()

    # Timestamps (ISO-8601 UTC)
    if(NOT SL_CREATED)
        string(TIMESTAMP _NOW_UTC "%Y-%m-%dT%H:%M:%SZ" UTC)
        set(SL_CREATED "${_NOW_UTC}")
    endif()
    if(NOT SL_ADDED)
        set(SL_ADDED "${SL_CREATED}")
    endif()
    if(NOT SL_CONTENT_CREATED)
        set(SL_CONTENT_CREATED "${SL_CREATED}")
    endif()

    # Origin
    if(NOT SL_ORIGIN)
        if(PROJECT_HOMEPAGE_URL AND NOT PROJECT_HOMEPAGE_URL STREQUAL "")
            set(SL_ORIGIN "${PROJECT_HOMEPAGE_URL}")
        else()
            # Try git remote url if available
            find_package(Git QUIET)
            if(Git_FOUND AND CMAKE_CURRENT_SOURCE_DIR)
                execute_process(
                    COMMAND "${GIT_EXECUTABLE}" config --get remote.origin.url
                    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                    OUTPUT_VARIABLE _GIT_ORIGIN
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    ERROR_QUIET
                )
                if(_GIT_ORIGIN AND NOT _GIT_ORIGIN STREQUAL "")
                    set(SL_ORIGIN "${_GIT_ORIGIN}")
                endif()
            endif()
        endif()
        if(NOT SL_ORIGIN)
            set(SL_ORIGIN "https://sourcelume.apache.org/cmake/${SL_PROJECT_NAME}")
        endif()
    endif()

    # Creator
    if(NOT SL_CREATOR_NAME)
        if(CPACK_PACKAGE_VENDOR AND NOT CPACK_PACKAGE_VENDOR STREQUAL "")
            set(SL_CREATOR_NAME "${CPACK_PACKAGE_VENDOR}")
            set(SL_CREATOR_TYPE "schema:Organization")
        elseif(CPACK_PACKAGE_CONTACT AND NOT CPACK_PACKAGE_CONTACT STREQUAL "")
            set(SL_CREATOR_NAME "${CPACK_PACKAGE_CONTACT}")
            set(SL_CREATOR_TYPE "schema:Person")
        else()
            set(SL_CREATOR_NAME "The Apache Software Foundation")
            set(SL_CREATOR_TYPE "schema:Organization")
        endif()
    endif()
    if(NOT SL_CREATOR_TYPE)
        set(SL_CREATOR_TYPE "schema:Organization")
    endif()
    if(NOT SL_CREATOR_ROLE)
        set(SL_CREATOR_ROLE "originator")
    endif()

    # Custody Chain
    if(NOT SL_CUSTODY_AGENT)
        set(SL_CUSTODY_AGENT "https://sourcelume.apache.org/agents/cmake-module")
    endif()
    if(NOT SL_CUSTODY_ACTION)
        set(SL_CUSTODY_ACTION "cmake_build_and_provenance_generation")
    endif()

    # Escape JSON strings
    _sourcelume_escape_json("${SL_RECORD_ID}" ESC_ID)
    _sourcelume_escape_json("${SL_DATASET_IDENTIFIER}" ESC_IDENTIFIER)
    _sourcelume_escape_json("${SL_DATASET_NAME}" ESC_NAME)
    _sourcelume_escape_json("${SL_VERSION}" ESC_VERSION)
    _sourcelume_escape_json("${SL_RESOLVED_LICENSE}" ESC_LICENSE)
    _sourcelume_escape_json("${SL_LICENSE_CATEGORY}" ESC_LICENSE_CAT)
    _sourcelume_escape_json("${SL_CREATOR_TYPE}" ESC_CREATOR_TYPE)
    _sourcelume_escape_json("${SL_CREATOR_NAME}" ESC_CREATOR_NAME)
    _sourcelume_escape_json("${SL_CREATOR_ROLE}" ESC_CREATOR_ROLE)
    _sourcelume_escape_json("${SL_CREATED}" ESC_CREATED)
    _sourcelume_escape_json("${SL_ADDED}" ESC_ADDED)
    _sourcelume_escape_json("${SL_CONTENT_CREATED}" ESC_CONTENT_CREATED)
    _sourcelume_escape_json("${SL_ORIGIN}" ESC_ORIGIN)
    _sourcelume_escape_json("${SL_CUSTODY_AGENT}" ESC_CUSTODY_AGENT)
    _sourcelume_escape_json("${SL_CUSTODY_ACTION}" ESC_CUSTODY_ACTION)

    # Build JSON Record
    set(RECORD_JSON "{\n")
    string(APPEND RECORD_JSON "  \"@context\": \"https://sourcelume.apache.org/context/0.0.1/sourcelume.jsonld\",\n")
    string(APPEND RECORD_JSON "  \"id\": \"${ESC_ID}\",\n")
    string(APPEND RECORD_JSON "  \"type\": \"ProvenanceRecord\",\n")
    string(APPEND RECORD_JSON "  \"identifier\": \"${ESC_IDENTIFIER}\",\n")
    string(APPEND RECORD_JSON "  \"name\": \"${ESC_NAME}\",\n")
    string(APPEND RECORD_JSON "  \"version\": \"${ESC_VERSION}\",\n")
    string(APPEND RECORD_JSON "  \"license\": \"${ESC_LICENSE}\",\n")
    string(APPEND RECORD_JSON "  \"licenseCategory\": \"${ESC_LICENSE_CAT}\"")

    if(SL_LICENSE_NOTE)
        _sourcelume_escape_json("${SL_LICENSE_NOTE}" ESC_LICENSE_NOTE)
        string(APPEND RECORD_JSON ",\n  \"licenseNote\": \"${ESC_LICENSE_NOTE}\"")
    endif()

    if(SL_LICENSE_SCOPE)
        _sourcelume_escape_json("${SL_LICENSE_SCOPE}" ESC_LICENSE_SCOPE)
        string(APPEND RECORD_JSON ",\n  \"licenseScope\": \"${ESC_LICENSE_SCOPE}\"")
    endif()

    string(APPEND RECORD_JSON ",\n  \"creator\": [\n")
    string(APPEND RECORD_JSON "    {\n")
    string(APPEND RECORD_JSON "      \"type\": \"${ESC_CREATOR_TYPE}\",\n")
    string(APPEND RECORD_JSON "      \"name\": \"${ESC_CREATOR_NAME}\",\n")
    string(APPEND RECORD_JSON "      \"role\": \"${ESC_CREATOR_ROLE}\"\n")
    string(APPEND RECORD_JSON "    }\n")
    string(APPEND RECORD_JSON "  ],\n")
    string(APPEND RECORD_JSON "  \"created\": \"${ESC_CREATED}\",\n")
    string(APPEND RECORD_JSON "  \"added\": \"${ESC_ADDED}\",\n")
    string(APPEND RECORD_JSON "  \"contentCreated\": \"${ESC_CONTENT_CREATED}\",\n")
    string(APPEND RECORD_JSON "  \"origin\": \"${ESC_ORIGIN}\",\n")
    string(APPEND RECORD_JSON "  \"custodyChain\": [\n")
    string(APPEND RECORD_JSON "    {\n")
    string(APPEND RECORD_JSON "      \"agent\": \"${ESC_CUSTODY_AGENT}\",\n")
    string(APPEND RECORD_JSON "      \"action\": \"${ESC_CUSTODY_ACTION}\",\n")
    string(APPEND RECORD_JSON "      \"startTime\": \"${ESC_ADDED}\"\n")
    string(APPEND RECORD_JSON "    }\n")
    string(APPEND RECORD_JSON "  ]\n")
    string(APPEND RECORD_JSON "}\n")

    # Write output file
    get_filename_component(_OUT_DIR "${SL_OUTPUT_FILE}" DIRECTORY)
    file(MAKE_DIRECTORY "${_OUT_DIR}")
    file(WRITE "${SL_OUTPUT_FILE}" "${RECORD_JSON}")

    message(STATUS "[Sourcelume] Generated Provenance Record: ${SL_RECORD_ID}")
    message(STATUS "[Sourcelume] Record file written to: ${SL_OUTPUT_FILE}")
endfunction()

# -----------------------------------------------------------------------------
# Core Function: Validate Provenance Record against Sourcelume Registry
# -----------------------------------------------------------------------------
function(sourcelume_validate)
    set(options DRY_RUN)
    set(oneValueArgs
        REGISTRY_URL
        USERNAME
        PASSWORD
        TOKEN
        RECORD_FILE
        FAIL_ON_ERROR
    )
    cmake_parse_arguments(SL "${options}" "${oneValueArgs}" "" ${ARGN})

    # Resolve Registry URL
    if(NOT SL_REGISTRY_URL)
        if(DEFINED ENV{SOURCELUME_REGISTRY_URL})
            set(SL_REGISTRY_URL "$ENV{SOURCELUME_REGISTRY_URL}")
        else()
            set(SL_REGISTRY_URL "http://localhost:8082")
        endif()
    endif()
    string(REGEX REPLACE "/+$" "" SL_REGISTRY_URL "${SL_REGISTRY_URL}")

    # Resolve Record File
    if(NOT SL_RECORD_FILE)
        if(CMAKE_CURRENT_BINARY_DIR)
            set(SL_RECORD_FILE "${CMAKE_CURRENT_BINARY_DIR}/sourcelume/provenance-record.json")
        else()
            set(SL_RECORD_FILE "${CMAKE_BINARY_DIR}/sourcelume/provenance-record.json")
        endif()
    endif()

    if(NOT EXISTS "${SL_RECORD_FILE}")
        message(FATAL_ERROR "[Sourcelume] Provenance Record file not found: ${SL_RECORD_FILE}. Run 'sourcelume_generate' first.")
    endif()

    # Resolve Auth
    if(NOT SL_TOKEN AND DEFINED ENV{SOURCELUME_REGISTRY_TOKEN})
        set(SL_TOKEN "$ENV{SOURCELUME_REGISTRY_TOKEN}")
    endif()
    if(NOT SL_USERNAME AND DEFINED ENV{SOURCELUME_REGISTRY_USERNAME})
        set(SL_USERNAME "$ENV{SOURCELUME_REGISTRY_USERNAME}")
    endif()
    if(NOT SL_PASSWORD AND DEFINED ENV{SOURCELUME_REGISTRY_PASSWORD})
        set(SL_PASSWORD "$ENV{SOURCELUME_REGISTRY_PASSWORD}")
    endif()

    if(SL_DRY_RUN OR SOURCELUME_DRY_RUN OR "$ENV{SOURCELUME_DRY_RUN}")
        message(STATUS "[Sourcelume] [DRY-RUN] Simulating validation with registry: ${SL_REGISTRY_URL}/records/validate")
        file(READ "${SL_RECORD_FILE}" _RECORD_CONTENT)
        message(STATUS "[Sourcelume] [DRY-RUN] Record content:\n${_RECORD_CONTENT}")
        return()
    endif()

    message(STATUS "[Sourcelume] Validating Provenance Record against registry: ${SL_REGISTRY_URL}/records/validate")

    # Build curl arguments
    find_program(CURL_EXECUTABLE curl)
    if(NOT CURL_EXECUTABLE)
        message(FATAL_ERROR "[Sourcelume] 'curl' command is required for registry communication.")
    endif()

    set(CURL_CMD "${CURL_EXECUTABLE}" -s -S -w "\n%{http_code}" -X POST "${SL_REGISTRY_URL}/records/validate"
        -H "Content-Type: application/json"
        -H "Accept: application/json"
        -d "@${SL_RECORD_FILE}"
    )

    if(SL_TOKEN AND NOT SL_TOKEN STREQUAL "")
        list(APPEND CURL_CMD -H "Authorization: Bearer ${SL_TOKEN}")
    elseif(SL_USERNAME AND NOT SL_USERNAME STREQUAL "")
        list(APPEND CURL_CMD -u "${SL_USERNAME}:${SL_PASSWORD}")
    endif()

    execute_process(
        COMMAND ${CURL_CMD}
        OUTPUT_VARIABLE _RESP_RAW
        ERROR_VARIABLE _CURL_ERR
        RESULT_VARIABLE _CURL_RES
    )

    if(NOT _CURL_RES EQUAL 0)
        set(_ERR_MSG "[Sourcelume] Failed to connect to registry at ${SL_REGISTRY_URL}: ${_CURL_ERR}")
        if(SL_FAIL_ON_ERROR OR NOT DEFINED SL_FAIL_ON_ERROR)
            message(FATAL_ERROR "${_ERR_MSG}")
        else()
            message(WARNING "${_ERR_MSG}")
            return()
        endif()
    endif()

    # Split response body and status code
    string(REGEX MATCH "([0-9]+)$" _HTTP_CODE "${_RESP_RAW}")
    string(REGEX REPLACE "\n?[0-9]+$" "" _RESP_BODY "${_RESP_RAW}")

    if(_HTTP_CODE GREATER_EQUAL 200 AND _HTTP_CODE LESS 300)
        message(STATUS "[Sourcelume] Validation succeeded (HTTP ${_HTTP_CODE}): ${_RESP_BODY}")
    else()
        set(_ERR_MSG "[Sourcelume] Validation failed with HTTP ${_HTTP_CODE}: ${_RESP_BODY}")
        if(SL_FAIL_ON_ERROR OR NOT DEFINED SL_FAIL_ON_ERROR)
            message(FATAL_ERROR "${_ERR_MSG}")
        else()
            message(WARNING "${_ERR_MSG}")
        endif()
    endif()
endfunction()

# -----------------------------------------------------------------------------
# Core Function: Publish Provenance Record to Sourcelume Registry
# -----------------------------------------------------------------------------
function(sourcelume_publish)
    set(options DRY_RUN ALLOW_CONFLICT)
    set(oneValueArgs
        REGISTRY_URL
        USERNAME
        PASSWORD
        TOKEN
        RECORD_FILE
        FAIL_ON_ERROR
    )
    cmake_parse_arguments(SL "${options}" "${oneValueArgs}" "" ${ARGN})

    # Resolve Registry URL
    if(NOT SL_REGISTRY_URL)
        if(DEFINED ENV{SOURCELUME_REGISTRY_URL})
            set(SL_REGISTRY_URL "$ENV{SOURCELUME_REGISTRY_URL}")
        else()
            set(SL_REGISTRY_URL "http://localhost:8082")
        endif()
    endif()
    string(REGEX REPLACE "/+$" "" SL_REGISTRY_URL "${SL_REGISTRY_URL}")

    # Resolve Record File
    if(NOT SL_RECORD_FILE)
        if(CMAKE_CURRENT_BINARY_DIR)
            set(SL_RECORD_FILE "${CMAKE_CURRENT_BINARY_DIR}/sourcelume/provenance-record.json")
        else()
            set(SL_RECORD_FILE "${CMAKE_BINARY_DIR}/sourcelume/provenance-record.json")
        endif()
    endif()

    if(NOT EXISTS "${SL_RECORD_FILE}")
        message(FATAL_ERROR "[Sourcelume] Provenance Record file not found: ${SL_RECORD_FILE}. Run 'sourcelume_generate' first.")
    endif()

    # Resolve Auth
    if(NOT SL_TOKEN AND DEFINED ENV{SOURCELUME_REGISTRY_TOKEN})
        set(SL_TOKEN "$ENV{SOURCELUME_REGISTRY_TOKEN}")
    endif()
    if(NOT SL_USERNAME AND DEFINED ENV{SOURCELUME_REGISTRY_USERNAME})
        set(SL_USERNAME "$ENV{SOURCELUME_REGISTRY_USERNAME}")
    endif()
    if(NOT SL_PASSWORD AND DEFINED ENV{SOURCELUME_REGISTRY_PASSWORD})
        set(SL_PASSWORD "$ENV{SOURCELUME_REGISTRY_PASSWORD}")
    endif()

    if(SL_DRY_RUN OR SOURCELUME_DRY_RUN OR "$ENV{SOURCELUME_DRY_RUN}")
        message(STATUS "[Sourcelume] [DRY-RUN] Simulating publish to Sourcelume Registry: ${SL_REGISTRY_URL}/records")
        file(READ "${SL_RECORD_FILE}" _RECORD_CONTENT)
        message(STATUS "[Sourcelume] [DRY-RUN] Record to submit:\n${_RECORD_CONTENT}")
        return()
    endif()

    message(STATUS "[Sourcelume] Submitting Provenance Record to registry: ${SL_REGISTRY_URL}/records")

    find_program(CURL_EXECUTABLE curl)
    if(NOT CURL_EXECUTABLE)
        message(FATAL_ERROR "[Sourcelume] 'curl' command is required for registry communication.")
    endif()

    set(CURL_CMD "${CURL_EXECUTABLE}" -s -S -w "\n%{http_code}" -X POST "${SL_REGISTRY_URL}/records"
        -H "Content-Type: application/json"
        -H "Accept: application/json"
        -d "@${SL_RECORD_FILE}"
    )

    if(SL_TOKEN AND NOT SL_TOKEN STREQUAL "")
        list(APPEND CURL_CMD -H "Authorization: Bearer ${SL_TOKEN}")
    elseif(SL_USERNAME AND NOT SL_USERNAME STREQUAL "")
        list(APPEND CURL_CMD -u "${SL_USERNAME}:${SL_PASSWORD}")
    endif()

    execute_process(
        COMMAND ${CURL_CMD}
        OUTPUT_VARIABLE _RESP_RAW
        ERROR_VARIABLE _CURL_ERR
        RESULT_VARIABLE _CURL_RES
    )

    if(NOT _CURL_RES EQUAL 0)
        set(_ERR_MSG "[Sourcelume] Failed to connect to registry at ${SL_REGISTRY_URL}: ${_CURL_ERR}")
        if(SL_FAIL_ON_ERROR OR NOT DEFINED SL_FAIL_ON_ERROR)
            message(FATAL_ERROR "${_ERR_MSG}")
        else()
            message(WARNING "${_ERR_MSG}")
            return()
        endif()
    endif()

    # Split response body and status code
    string(REGEX MATCH "([0-9]+)$" _HTTP_CODE "${_RESP_RAW}")
    string(REGEX REPLACE "\n?[0-9]+$" "" _RESP_BODY "${_RESP_RAW}")

    # The registry stores an invalid record as INCOMPLETE and still answers 2xx
    string(JSON _RECORD_STATUS ERROR_VARIABLE _JSON_ERR GET "${_RESP_BODY}" "recordStatus")
    if(_HTTP_CODE GREATER_EQUAL 200 AND _HTTP_CODE LESS 300 AND _RECORD_STATUS STREQUAL "INCOMPLETE")
        _sourcelume_issue_lines("${_RESP_BODY}" _ISSUE_LINES)
        set(_ERR_MSG "[Sourcelume] The registry stored the record as INCOMPLETE; fix these issues and publish again:${_ISSUE_LINES}")
        if(SL_FAIL_ON_ERROR OR NOT DEFINED SL_FAIL_ON_ERROR)
            message(FATAL_ERROR "${_ERR_MSG}")
        else()
            message(WARNING "${_ERR_MSG}")
        endif()
    elseif(_HTTP_CODE GREATER_EQUAL 200 AND _HTTP_CODE LESS 300)
        message(STATUS "[Sourcelume] Successfully published record to Sourcelume Registry! Status: ${_HTTP_CODE}")
        message(STATUS "[Sourcelume] Registry response: ${_RESP_BODY}")
    elseif(_HTTP_CODE EQUAL 409)
        string(JSON _REASON ERROR_VARIABLE _JSON_ERR GET "${_RESP_BODY}" "reason")
        if(_JSON_ERR)
            set(_REASON "${_RESP_BODY}")
        endif()
        if(SL_ALLOW_CONFLICT OR DEFINED SOURCELUME_ALLOW_CONFLICT AND SOURCELUME_ALLOW_CONFLICT)
            message(STATUS "[Sourcelume] The registry refused the record (HTTP 409): ${_REASON}. Continuing as requested.")
        else()
            set(_ERR_MSG "[Sourcelume] The registry refused the record (HTTP 409): ${_REASON}")
            if(SL_FAIL_ON_ERROR OR NOT DEFINED SL_FAIL_ON_ERROR)
                message(FATAL_ERROR "${_ERR_MSG}")
            else()
                message(WARNING "${_ERR_MSG}")
            endif()
        endif()
    else()
        set(_ERR_MSG "[Sourcelume] Publish failed with HTTP ${_HTTP_CODE}: ${_RESP_BODY}")
        if(SL_FAIL_ON_ERROR OR NOT DEFINED SL_FAIL_ON_ERROR)
            message(FATAL_ERROR "${_ERR_MSG}")
        else()
            message(WARNING "${_ERR_MSG}")
        endif()
    endif()
endfunction()

# -----------------------------------------------------------------------------
# Target Setup Function: sourcelume_enable / sourcelume_add_targets
# -----------------------------------------------------------------------------
function(sourcelume_enable)
    set(options DRY_RUN FAIL_ON_ERROR ALLOW_CONFLICT)
    set(oneValueArgs
        TARGET_NAME
        PROJECT_NAME
        OUTPUT_FILE
        RECORD_ID
        DATASET_IDENTIFIER
        DATASET_NAME
        VERSION
        LICENSE
        LICENSE_CATEGORY
        LICENSE_NOTE
        LICENSE_SCOPE
        ORIGIN
        CREATOR_NAME
        CREATOR_TYPE
        CREATOR_ROLE
        CUSTODY_AGENT
        CUSTODY_ACTION
        REGISTRY_URL
        USERNAME
        PASSWORD
        TOKEN
    )
    cmake_parse_arguments(SL "${options}" "${oneValueArgs}" "" ${ARGN})

    # Capture project context defaults at configuration time
    if(NOT SL_PROJECT_NAME)
        if(PROJECT_NAME)
            set(SL_PROJECT_NAME "${PROJECT_NAME}")
        elseif(CMAKE_PROJECT_NAME)
            set(SL_PROJECT_NAME "${CMAKE_PROJECT_NAME}")
        endif()
    endif()
    if(NOT SL_VERSION)
        if(PROJECT_VERSION)
            set(SL_VERSION "${PROJECT_VERSION}")
        elseif(CMAKE_PROJECT_VERSION)
            set(SL_VERSION "${CMAKE_PROJECT_VERSION}")
        endif()
    endif()
    if(NOT SL_ORIGIN)
        if(PROJECT_HOMEPAGE_URL)
            set(SL_ORIGIN "${PROJECT_HOMEPAGE_URL}")
        endif()
    endif()
    if(NOT SL_DATASET_NAME)
        if(PROJECT_DESCRIPTION)
            set(SL_DATASET_NAME "${PROJECT_DESCRIPTION}")
        elseif(SL_PROJECT_NAME)
            set(SL_DATASET_NAME "${SL_PROJECT_NAME}")
        endif()
    endif()

    if(NOT SL_OUTPUT_FILE)
        set(SL_OUTPUT_FILE "${CMAKE_CURRENT_BINARY_DIR}/sourcelume/provenance-record.json")
    endif()

    set(MODULE_FILE "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Sourcelume.cmake")
    if(NOT EXISTS "${MODULE_FILE}")
        set(MODULE_FILE "${CMAKE_CURRENT_LIST_FILE}")
    endif()

    # Generate helper script
    set(GEN_SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/sourcelume/run_generate.cmake")
    set(VAL_SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/sourcelume/run_validate.cmake")
    set(PUB_SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/sourcelume/run_publish.cmake")

    file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/sourcelume")

    # Generate Script
    file(WRITE "${GEN_SCRIPT}" "
include(\"${MODULE_FILE}\")
sourcelume_generate(
    PROJECT_NAME \"${SL_PROJECT_NAME}\"
    OUTPUT_FILE \"${SL_OUTPUT_FILE}\"
    RECORD_ID \"${SL_RECORD_ID}\"
    DATASET_IDENTIFIER \"${SL_DATASET_IDENTIFIER}\"
    DATASET_NAME \"${SL_DATASET_NAME}\"
    VERSION \"${SL_VERSION}\"
    LICENSE \"${SL_LICENSE}\"
    LICENSE_CATEGORY \"${SL_LICENSE_CATEGORY}\"
    LICENSE_NOTE \"${SL_LICENSE_NOTE}\"
    LICENSE_SCOPE \"${SL_LICENSE_SCOPE}\"
    ORIGIN \"${SL_ORIGIN}\"
    CREATOR_NAME \"${SL_CREATOR_NAME}\"
    CREATOR_TYPE \"${SL_CREATOR_TYPE}\"
    CREATOR_ROLE \"${SL_CREATOR_ROLE}\"
    CUSTODY_AGENT \"${SL_CUSTODY_AGENT}\"
    CUSTODY_ACTION \"${SL_CUSTODY_ACTION}\"
)
")

    # Validate Script
    file(WRITE "${VAL_SCRIPT}" "
include(\"${MODULE_FILE}\")
sourcelume_validate(
    REGISTRY_URL \"${SL_REGISTRY_URL}\"
    USERNAME \"${SL_USERNAME}\"
    PASSWORD \"${SL_PASSWORD}\"
    TOKEN \"${SL_TOKEN}\"
    RECORD_FILE \"${SL_OUTPUT_FILE}\"
)
")

    # Publish Script
    file(WRITE "${PUB_SCRIPT}" "
include(\"${MODULE_FILE}\")
sourcelume_publish(
    REGISTRY_URL \"${SL_REGISTRY_URL}\"
    USERNAME \"${SL_USERNAME}\"
    PASSWORD \"${SL_PASSWORD}\"
    TOKEN \"${SL_TOKEN}\"
    RECORD_FILE \"${SL_OUTPUT_FILE}\"
)
")

    # Define custom targets
    if(NOT TARGET sourcelume_generate)
        add_custom_target(sourcelume_generate
            COMMAND ${CMAKE_COMMAND} -P "${GEN_SCRIPT}"
            COMMENT "[Sourcelume] Generating Provenance Record JSON..."
            VERBATIM
        )
        add_custom_target(sourcelume-generate DEPENDS sourcelume_generate)
    endif()

    if(NOT TARGET sourcelume_validate)
        add_custom_target(sourcelume_validate
            COMMAND ${CMAKE_COMMAND} -P "${VAL_SCRIPT}"
            DEPENDS sourcelume_generate
            COMMENT "[Sourcelume] Validating Provenance Record with registry..."
            VERBATIM
        )
        add_custom_target(sourcelume-validate DEPENDS sourcelume_validate)
    endif()

    if(NOT TARGET sourcelume_publish)
        add_custom_target(sourcelume_publish
            COMMAND ${CMAKE_COMMAND} -P "${PUB_SCRIPT}"
            DEPENDS sourcelume_generate
            COMMENT "[Sourcelume] Publishing Provenance Record to registry..."
            VERBATIM
        )
        add_custom_target(sourcelume-publish DEPENDS sourcelume_publish)
    endif()
endfunction()

# Alias
macro(sourcelume_add_targets)
    sourcelume_enable(${ARGN})
endmacro()

# -----------------------------------------------------------------------------
# Direct Script Execution Mode (cmake -DSOURCELUME_ACTION=... -P Sourcelume.cmake)
# -----------------------------------------------------------------------------
if(DEFINED SOURCELUME_ACTION)
    if(SOURCELUME_ACTION STREQUAL "generate")
        sourcelume_generate(
            PROJECT_NAME "${SOURCELUME_PROJECT_NAME}"
            VERSION "${SOURCELUME_VERSION}"
            OUTPUT_FILE "${SOURCELUME_OUTPUT_FILE}"
            RECORD_ID "${SOURCELUME_RECORD_ID}"
            DATASET_IDENTIFIER "${SOURCELUME_DATASET_IDENTIFIER}"
            DATASET_NAME "${SOURCELUME_DATASET_NAME}"
            LICENSE "${SOURCELUME_LICENSE}"
            LICENSE_CATEGORY "${SOURCELUME_LICENSE_CATEGORY}"
            LICENSE_NOTE "${SOURCELUME_LICENSE_NOTE}"
            ORIGIN "${SOURCELUME_ORIGIN}"
            CREATOR_NAME "${SOURCELUME_CREATOR_NAME}"
            CREATOR_TYPE "${SOURCELUME_CREATOR_TYPE}"
            CREATOR_ROLE "${SOURCELUME_CREATOR_ROLE}"
        )
    elseif(SOURCELUME_ACTION STREQUAL "validate")
        sourcelume_validate(
            REGISTRY_URL "${SOURCELUME_REGISTRY_URL}"
            RECORD_FILE "${SOURCELUME_RECORD_FILE}"
            USERNAME "${SOURCELUME_USERNAME}"
            PASSWORD "${SOURCELUME_PASSWORD}"
            TOKEN "${SOURCELUME_TOKEN}"
        )
    elseif(SOURCELUME_ACTION STREQUAL "publish")
        sourcelume_publish(
            REGISTRY_URL "${SOURCELUME_REGISTRY_URL}"
            RECORD_FILE "${SOURCELUME_RECORD_FILE}"
            USERNAME "${SOURCELUME_USERNAME}"
            PASSWORD "${SOURCELUME_PASSWORD}"
            TOKEN "${SOURCELUME_TOKEN}"
        )
    else()
        message(FATAL_ERROR "[Sourcelume] Unknown SOURCELUME_ACTION: '${SOURCELUME_ACTION}'. Expected generate, validate, or publish.")
    endif()
endif()
