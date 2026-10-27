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

# Publishes through a fake curl that answers like the registry, and checks
# that an INCOMPLETE record or a 409 fails the publish with the registry's
# details. Each case runs in a child cmake process so a FATAL_ERROR can be
# asserted.

if(DEFINED CASE_BODY_FILE)
    include("${CMAKE_CURRENT_LIST_DIR}/../cmake/Sourcelume.cmake")
    set(CURL_EXECUTABLE "${FAKE_CURL}")
    sourcelume_publish(
        REGISTRY_URL "http://localhost:8082"
        RECORD_FILE "${RECORD_FILE}"
        FAIL_ON_ERROR ${CASE_FAIL_ON_ERROR}
    )
    return()
endif()

if(CMAKE_HOST_WIN32)
    message(STATUS "Skipping publish outcome tests: the fake curl is a POSIX shell script")
    return()
endif()

set(TEST_TMP_DIR "${CMAKE_CURRENT_BINARY_DIR}/tmp_test_publish_outcomes")
file(REMOVE_RECURSE "${TEST_TMP_DIR}")
file(MAKE_DIRECTORY "${TEST_TMP_DIR}")
set(RECORD_FILE "${TEST_TMP_DIR}/record.json")
file(WRITE "${RECORD_FILE}" "{}")

function(run_publish NAME HTTP_CODE BODY FAIL_ON_ERROR OUT_RESULT OUT_OUTPUT)
    set(_BODY_FILE "${TEST_TMP_DIR}/${NAME}.json")
    set(_FAKE_CURL "${TEST_TMP_DIR}/${NAME}-curl.sh")
    file(WRITE "${_BODY_FILE}" "${BODY}")
    file(WRITE "${_FAKE_CURL}" "#!/bin/sh\ncat '${_BODY_FILE}'\nprintf '\\n${HTTP_CODE}'\n")
    file(CHMOD "${_FAKE_CURL}" PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE)
    execute_process(
        COMMAND "${CMAKE_COMMAND}"
            -DCASE_BODY_FILE=${_BODY_FILE}
            -DCASE_FAIL_ON_ERROR=${FAIL_ON_ERROR}
            -DFAKE_CURL=${_FAKE_CURL}
            -DRECORD_FILE=${RECORD_FILE}
            -P "${CMAKE_CURRENT_LIST_FILE}"
        RESULT_VARIABLE _RESULT
        OUTPUT_VARIABLE _OUTPUT
        ERROR_VARIABLE _OUTPUT
    )
    set(${OUT_RESULT} "${_RESULT}" PARENT_SCOPE)
    set(${OUT_OUTPUT} "${_OUTPUT}" PARENT_SCOPE)
endfunction()

# CMake wraps long messages, so whitespace runs are compared as single spaces
function(assert_contains OUTPUT EXPECTED)
    string(REGEX REPLACE "[ \t\r\n]+" " " _FLAT "${OUTPUT}")
    string(FIND "${_FLAT}" "${EXPECTED}" _POS)
    if(_POS EQUAL -1)
        message(FATAL_ERROR "Assertion failed: expected output to contain '${EXPECTED}', got:\n${OUTPUT}")
    endif()
endfunction()

set(INCOMPLETE_BODY [=[{"recordStatus":"INCOMPLETE","validationIssues":"[{\"path\":\"/\",\"message\":\"required property 'license' not found\"}]"}]=])

# 1. INCOMPLETE fails the publish and lists the issues
run_publish(incomplete 201 "${INCOMPLETE_BODY}" ON _RESULT _OUTPUT)
if(_RESULT EQUAL 0)
    message(FATAL_ERROR "Assertion failed: an INCOMPLETE record must fail the publish:\n${_OUTPUT}")
endif()
assert_contains("${_OUTPUT}" "stored the record as INCOMPLETE")
assert_contains("${_OUTPUT}" "/: required property 'license' not found")

# 2. With FAIL_ON_ERROR OFF it only warns
run_publish(incomplete-warn 201 "${INCOMPLETE_BODY}" OFF _RESULT _OUTPUT)
if(NOT _RESULT EQUAL 0)
    message(FATAL_ERROR "Assertion failed: FAIL_ON_ERROR OFF must not fail the publish:\n${_OUTPUT}")
endif()
assert_contains("${_OUTPUT}" "stored the record as INCOMPLETE")

# 3. VALIDATED succeeds
run_publish(validated 201 [=[{"recordStatus":"VALIDATED"}]=] ON _RESULT _OUTPUT)
if(NOT _RESULT EQUAL 0)
    message(FATAL_ERROR "Assertion failed: a VALIDATED record must publish:\n${_OUTPUT}")
endif()
assert_contains("${_OUTPUT}" "Successfully published")

# 4. A 409 fails with the registry's reason
run_publish(conflict 409 [=[{"recordStatus":"VALIDATED","reason":"The id belongs to a VALIDATED record"}]=] ON _RESULT _OUTPUT)
if(_RESULT EQUAL 0)
    message(FATAL_ERROR "Assertion failed: a 409 must fail the publish:\n${_OUTPUT}")
endif()
assert_contains("${_OUTPUT}" "The id belongs to a VALIDATED record")

file(REMOVE_RECURSE "${TEST_TMP_DIR}")
message(STATUS "Publish outcome assertions passed!")
