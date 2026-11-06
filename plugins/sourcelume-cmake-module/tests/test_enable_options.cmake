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

# Checks that DRY_RUN, FAIL_ON_ERROR and ALLOW_CONFLICT given to
# sourcelume_enable() reach the scripts the build targets run.

set(MODULE_FILE "${CMAKE_CURRENT_LIST_DIR}/../cmake/Sourcelume.cmake")
set(TEST_TMP_DIR "${CMAKE_CURRENT_BINARY_DIR}/tmp_test_enable_options")

file(REMOVE_RECURSE "${TEST_TMP_DIR}")

# Configures a project that calls sourcelume_enable(<args>) and returns the
# generated validate and publish scripts.
function(configure_with name args)
    file(WRITE "${TEST_TMP_DIR}/${name}/CMakeLists.txt"
        "cmake_minimum_required(VERSION 3.19)\n"
        "project(${name} VERSION 1.0.0 LANGUAGES NONE)\n"
        "include(\"${MODULE_FILE}\")\n"
        "sourcelume_enable(${args})\n")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -S "${TEST_TMP_DIR}/${name}" -B "${TEST_TMP_DIR}/${name}/build"
        RESULT_VARIABLE _rc OUTPUT_VARIABLE _out ERROR_VARIABLE _err
    )
    if(NOT _rc EQUAL 0)
        message(FATAL_ERROR "Configuring ${name} failed:\n${_out}\n${_err}")
    endif()
    file(READ "${TEST_TMP_DIR}/${name}/build/sourcelume/run_validate.cmake" _val)
    file(READ "${TEST_TMP_DIR}/${name}/build/sourcelume/run_publish.cmake" _pub)
    set(VAL "${_val}" PARENT_SCOPE)
    set(PUB "${_pub}" PARENT_SCOPE)
endfunction()

function(expect_in text pattern what)
    if(NOT text MATCHES "${pattern}")
        message(FATAL_ERROR "Expected ${what} to match '${pattern}', got:\n${text}")
    endif()
endfunction()

function(expect_not_in text pattern what)
    if(text MATCHES "${pattern}")
        message(FATAL_ERROR "Expected ${what} not to match '${pattern}', got:\n${text}")
    endif()
endfunction()

# 1. No options: nothing extra is passed, so the existing defaults apply.
configure_with(defaults "")
foreach(_kw DRY_RUN FAIL_ON_ERROR ALLOW_CONFLICT)
    expect_not_in("${VAL}" "${_kw}" "run_validate.cmake (defaults)")
    expect_not_in("${PUB}" "${_kw}" "run_publish.cmake (defaults)")
endforeach()

# 2. Documented form with values.
configure_with(values "DRY_RUN TRUE FAIL_ON_ERROR FALSE ALLOW_CONFLICT TRUE")
expect_in("${VAL}" "DRY_RUN" "run_validate.cmake (values)")
expect_in("${VAL}" "FAIL_ON_ERROR \"FALSE\"" "run_validate.cmake (values)")
expect_not_in("${VAL}" "ALLOW_CONFLICT" "run_validate.cmake (values)")
expect_in("${PUB}" "DRY_RUN" "run_publish.cmake (values)")
expect_in("${PUB}" "FAIL_ON_ERROR \"FALSE\"" "run_publish.cmake (values)")
expect_in("${PUB}" "ALLOW_CONFLICT" "run_publish.cmake (values)")

# 3. FALSE values pass nothing for DRY_RUN and ALLOW_CONFLICT.
configure_with(falses "DRY_RUN FALSE ALLOW_CONFLICT FALSE")
expect_not_in("${PUB}" "DRY_RUN" "run_publish.cmake (falses)")
expect_not_in("${PUB}" "ALLOW_CONFLICT" "run_publish.cmake (falses)")

# 4. A bare keyword means TRUE.
configure_with(bare "DRY_RUN ALLOW_CONFLICT")
expect_in("${PUB}" "DRY_RUN" "run_publish.cmake (bare)")
expect_in("${PUB}" "ALLOW_CONFLICT" "run_publish.cmake (bare)")

# 5. An empty value (for example an unset variable) does not turn a flag on.
configure_with(empties "DRY_RUN \"\${NOT_SET_ANYWHERE}\" ALLOW_CONFLICT \"\" FAIL_ON_ERROR \"\"")
expect_not_in("${PUB}" "DRY_RUN" "run_publish.cmake (empties)")
expect_not_in("${PUB}" "ALLOW_CONFLICT" "run_publish.cmake (empties)")
expect_not_in("${PUB}" "FAIL_ON_ERROR" "run_publish.cmake (empties)")
expect_not_in("${VAL}" "FAIL_ON_ERROR" "run_validate.cmake (empties)")

# 6. The generated publish script honours DRY_RUN: it simulates instead of
#    calling the registry.
execute_process(
    COMMAND ${CMAKE_COMMAND} -P "${TEST_TMP_DIR}/values/build/sourcelume/run_generate.cmake"
    RESULT_VARIABLE _rc OUTPUT_VARIABLE _out ERROR_VARIABLE _err
)
if(NOT _rc EQUAL 0)
    message(FATAL_ERROR "run_generate.cmake failed:\n${_out}\n${_err}")
endif()
execute_process(
    COMMAND ${CMAKE_COMMAND} -P "${TEST_TMP_DIR}/values/build/sourcelume/run_publish.cmake"
    RESULT_VARIABLE _rc OUTPUT_VARIABLE _out ERROR_VARIABLE _err
)
if(NOT _rc EQUAL 0 OR NOT "${_out}${_err}" MATCHES "\\[DRY-RUN\\] Simulating publish")
    message(FATAL_ERROR "run_publish.cmake did not dry-run:\n${_out}\n${_err}")
endif()

file(REMOVE_RECURSE "${TEST_TMP_DIR}")
message(STATUS "sourcelume_enable option assertions passed!")
