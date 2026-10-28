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

cmake_minimum_required(VERSION 3.19)
project(sourcelume-helloworld-cmake-sample
    VERSION 1.0.0
    DESCRIPTION "Apache Sourcelume C++ Hello World Sample"
    HOMEPAGE_URL "https://sourcelume.apache.org/examples/helloworld-cmake"
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# CPACK & Metadata
set(CPACK_PACKAGE_VENDOR "The Apache Software Foundation")
set(CPACK_PACKAGE_CONTACT "dev@sourcelume.apache.org")

# Include Sourcelume CMake Module
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../plugins/sourcelume-cmake-module/cmake")
include(Sourcelume)

# Application Executable
add_executable(helloworld_app
    src/main.cpp
    src/hello.cpp
)
target_include_directories(helloworld_app PRIVATE src)

# Enable Testing
include(CTest)
if(BUILD_TESTING)
    add_executable(test_hello
        test/test_hello.cpp
        src/hello.cpp
    )
    target_include_directories(test_hello PRIVATE src)
    add_test(NAME hello_test COMMAND test_hello)
endif()

# Enable Sourcelume Provenance Tooling
sourcelume_enable(
    REGISTRY_URL "http://localhost:8082"
    RECORD_ID "urn:sourcelume:cmake:org.apache.sourcelume.examples:sourcelume-helloworld-cmake-sample:1.0.0"
    DATASET_IDENTIFIER "sourcelume://datasets/sample-helloworld-cmake-corpus-v1"
    DATASET_NAME "Sourcelume Hello World C++ Example Dataset"
    LICENSE "Apache-2.0"
    LICENSE_CATEGORY "open-source"
    LICENSE_NOTE "Apache-2.0 verified C++ example dataset & code"
    ORIGIN "https://github.com/apache/sourcelume-tooling/tree/main/examples/helloworld-cmake-sample"
    CREATOR_NAME "The Apache Software Foundation"
    CREATOR_TYPE "schema:Organization"
    CREATOR_ROLE "originator"
)
