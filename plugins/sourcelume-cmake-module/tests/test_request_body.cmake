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

# Checks that validate and publish hand the record file to curl with
# --data-binary. curl's -d strips carriage returns and newlines from a file,
# so the registry would store and hash different bytes than the file holds.

if(CMAKE_HOST_WIN32)
    message(STATUS "Skipping request body tests: the fake curl is a POSIX shell script")
    return()
endif()

include("${CMAKE_CURRENT_LIST_DIR}/../cmake/Sourcelume.cmake")

set(TEST_TMP_DIR "${CMAKE_CURRENT_BINARY_DIR}/tmp_test_request_body")
file(REMOVE_RECURSE "${TEST_TMP_DIR}")
file(MAKE_DIRECTORY "${TEST_TMP_DIR}")
set(RECORD_FILE "${TEST_TMP_DIR}/record.json")
file(WRITE "${RECORD_FILE}" "{\n  \"type\": \"ProvenanceRecord\"\n}\n")

# The fake curl writes each argument on its own line and answers 200.
set(ARGS_FILE "${TEST_TMP_DIR}/curl-args.txt")
set(FAKE_CURL "${TEST_TMP_DIR}/curl.sh")
file(WRITE "${FAKE_CURL}" "#!/bin/sh\nprintf '%s\\n' \"$@\" > '${ARGS_FILE}'\nprintf '{}\\n200'\n")
file(CHMOD "${FAKE_CURL}" PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE)
set(CURL_EXECUTABLE "${FAKE_CURL}")

function(assert_sends_file_binary WHAT)
    file(STRINGS "${ARGS_FILE}" _ARGS)
    list(FIND _ARGS "--data-binary" _POS)
    if(_POS EQUAL -1)
        message(FATAL_ERROR "${WHAT}: curl was not given --data-binary. Arguments:\n${_ARGS}")
    endif()
    math(EXPR _NEXT "${_POS} + 1")
    list(GET _ARGS ${_NEXT} _VALUE)
    if(NOT _VALUE STREQUAL "@${RECORD_FILE}")
        message(FATAL_ERROR "${WHAT}: expected --data-binary @${RECORD_FILE}, got '${_VALUE}'")
    endif()
    foreach(_flag -d --data --data-ascii)
        if(_flag IN_LIST _ARGS)
            message(FATAL_ERROR "${WHAT}: curl was given ${_flag}, which alters the file's bytes")
        endif()
    endforeach()
endfunction()

sourcelume_validate(REGISTRY_URL "http://localhost:8082" RECORD_FILE "${RECORD_FILE}")
assert_sends_file_binary("validate")

file(REMOVE "${ARGS_FILE}")
sourcelume_publish(REGISTRY_URL "http://localhost:8082" RECORD_FILE "${RECORD_FILE}")
assert_sends_file_binary("publish")

file(REMOVE_RECURSE "${TEST_TMP_DIR}")
message(STATUS "Request body assertions passed!")
