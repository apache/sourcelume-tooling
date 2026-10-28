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

set(MODULE_FILE "${CMAKE_CURRENT_LIST_DIR}/../cmake/Sourcelume.cmake")
set(TEST_TMP_DIR "${CMAKE_CURRENT_BINARY_DIR}/tmp_test_script_mode")
set(OUT_FILE "${TEST_TMP_DIR}/script-record.json")

file(REMOVE_RECURSE "${TEST_TMP_DIR}")
file(MAKE_DIRECTORY "${TEST_TMP_DIR}")

# Test direct script execution: generate
execute_process(
    COMMAND ${CMAKE_COMMAND}
        -DSOURCELUME_ACTION=generate
        -DSOURCELUME_PROJECT_NAME=script-mode-proj
        -DSOURCELUME_VERSION=3.0.0
        -DSOURCELUME_OUTPUT_FILE=${OUT_FILE}
        -DSOURCELUME_LICENSE=MIT
        -P "${MODULE_FILE}"
    RESULT_VARIABLE _RES_GEN
)

if(NOT _RES_GEN EQUAL 0)
    message(FATAL_ERROR "Script mode generation failed with exit code: ${_RES_GEN}")
endif()

if(NOT EXISTS "${OUT_FILE}")
    message(FATAL_ERROR "Output file not found after script mode generation: ${OUT_FILE}")
endif()

file(READ "${OUT_FILE}" _GEN_JSON)
string(JSON REC_LIC GET "${_GEN_JSON}" "license")
if(NOT REC_LIC STREQUAL "https://spdx.org/licenses/MIT.html")
    message(FATAL_ERROR "Expected MIT license IRI, got: ${REC_LIC}")
endif()

file(REMOVE_RECURSE "${TEST_TMP_DIR}")
message(STATUS "Script mode execution assertions passed!")
