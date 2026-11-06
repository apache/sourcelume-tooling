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

# Installs the module into a scratch prefix and checks that a separate project
# can load it with find_package(Sourcelume).

set(MODULE_DIR "${CMAKE_CURRENT_LIST_DIR}/..")
set(TEST_TMP_DIR "${CMAKE_CURRENT_BINARY_DIR}/tmp_test_package_install")
set(PREFIX "${TEST_TMP_DIR}/prefix")

file(REMOVE_RECURSE "${TEST_TMP_DIR}")

execute_process(
    COMMAND ${CMAKE_COMMAND} -S "${MODULE_DIR}" -B "${TEST_TMP_DIR}/module-build"
            -DBUILD_TESTING=OFF "-DCMAKE_INSTALL_PREFIX=${PREFIX}"
    RESULT_VARIABLE _rc OUTPUT_VARIABLE _out ERROR_VARIABLE _err
)
if(NOT _rc EQUAL 0)
    message(FATAL_ERROR "Configuring the module failed:\n${_out}\n${_err}")
endif()

execute_process(
    COMMAND ${CMAKE_COMMAND} --install "${TEST_TMP_DIR}/module-build"
    RESULT_VARIABLE _rc OUTPUT_VARIABLE _out ERROR_VARIABLE _err
)
if(NOT _rc EQUAL 0)
    message(FATAL_ERROR "Installing the module failed:\n${_out}\n${_err}")
endif()

file(WRITE "${TEST_TMP_DIR}/consumer/CMakeLists.txt" [=[
cmake_minimum_required(VERSION 3.19)
project(sourcelume-consumer NONE)
find_package(Sourcelume 0.0.1 REQUIRED)
if(NOT COMMAND sourcelume_enable)
    message(FATAL_ERROR "sourcelume_enable is not defined after find_package")
endif()
if(NOT Sourcelume_VERSION STREQUAL "0.0.1")
    message(FATAL_ERROR "Expected Sourcelume_VERSION 0.0.1, got '${Sourcelume_VERSION}'")
endif()
# A different minor version is not compatible (SameMinorVersion).
find_package(Sourcelume 0.1 QUIET)
if(Sourcelume_FOUND)
    message(FATAL_ERROR "find_package(Sourcelume 0.1) should not accept version 0.0.1")
endif()
message(STATUS "SOURCELUME_CONSUMER_OK")
]=])

execute_process(
    COMMAND ${CMAKE_COMMAND} -S "${TEST_TMP_DIR}/consumer" -B "${TEST_TMP_DIR}/consumer-build"
            "-DCMAKE_PREFIX_PATH=${PREFIX}"
    RESULT_VARIABLE _rc OUTPUT_VARIABLE _out ERROR_VARIABLE _err
)
if(NOT _rc EQUAL 0 OR NOT _out MATCHES "SOURCELUME_CONSUMER_OK")
    message(FATAL_ERROR "find_package(Sourcelume) failed from the installed prefix:\n${_out}\n${_err}")
endif()

file(REMOVE_RECURSE "${TEST_TMP_DIR}")
message(STATUS "Package install assertions passed!")
