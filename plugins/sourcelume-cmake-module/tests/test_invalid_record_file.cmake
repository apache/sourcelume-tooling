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
set(TEST_TMP_DIR "${CMAKE_CURRENT_BINARY_DIR}/tmp_test_invalid_record_file")
set(DIR_AS_RECORD "${TEST_TMP_DIR}/not-a-file")
set(MISSING_RECORD "${TEST_TMP_DIR}/does-not-exist.json")

file(REMOVE_RECURSE "${TEST_TMP_DIR}")
file(MAKE_DIRECTORY "${DIR_AS_RECORD}")

foreach(ACTION validate publish)
    execute_process(
        COMMAND ${CMAKE_COMMAND}
            -DSOURCELUME_ACTION=${ACTION}
            -DSOURCELUME_RECORD_FILE=${MISSING_RECORD}
            -P "${MODULE_FILE}"
        RESULT_VARIABLE RES
        OUTPUT_VARIABLE OUT
        ERROR_VARIABLE ERR
    )
    if(RES EQUAL 0)
        message(FATAL_ERROR "Expected ${ACTION} to fail for missing record file")
    endif()
    if(NOT ERR MATCHES "Provenance Record file not found")
        message(FATAL_ERROR "Expected 'not found' error for ${ACTION}, got: ${ERR}")
    endif()

    execute_process(
        COMMAND ${CMAKE_COMMAND}
            -DSOURCELUME_ACTION=${ACTION}
            -DSOURCELUME_RECORD_FILE=${DIR_AS_RECORD}
            -P "${MODULE_FILE}"
        RESULT_VARIABLE RES
        OUTPUT_VARIABLE OUT
        ERROR_VARIABLE ERR
    )
    if(RES EQUAL 0)
        message(FATAL_ERROR "Expected ${ACTION} to fail when record path is a directory")
    endif()
    if(NOT ERR MATCHES "Provenance Record path is not a file")
        message(FATAL_ERROR "Expected 'not a file' error for ${ACTION}, got: ${ERR}")
    endif()
endforeach()

file(REMOVE_RECURSE "${TEST_TMP_DIR}")
message(STATUS "Invalid record file assertions passed!")
