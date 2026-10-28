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
project(sourcelume-cmake-module VERSION 0.0.1 LANGUAGES NONE)

if(NOT DEFINED CMAKE_INSTALL_LIBDIR)
    set(CMAKE_INSTALL_LIBDIR "lib" CACHE PATH "Library installation directory")
endif()
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

set(SOURCELUME_CMAKE_FILES
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/Sourcelume.cmake"
)

# Installation targets for CMake package/module usage
install(FILES ${SOURCELUME_CMAKE_FILES}
    DESTINATION "${CMAKE_INSTALL_DATADIR}/cmake/Modules"
)

install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/cmake/SourcelumeConfig.cmake"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/Sourcelume"
)

# Enable Sourcelume provenance generation targets for the module itself
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/Sourcelume.cmake")
sourcelume_enable(
    LICENSE "Apache-2.0"
    LICENSE_CATEGORY "open-source"
    LICENSE_NOTE "Apache-2.0 verified Sourcelume CMake module"
    DATASET_NAME "Apache Sourcelume CMake Module"
)

# Optional testing
include(CTest)
if(BUILD_TESTING)
    add_subdirectory(tests)
endif()
