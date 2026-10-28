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

set(TEST_TMP_DIR "${CMAKE_CURRENT_BINARY_DIR}/tmp_test_dry_run")
set(OUT_FILE "${TEST_TMP_DIR}/test-record.json")

file(REMOVE_RECURSE "${TEST_TMP_DIR}")

# 1. Generate
sourcelume_generate(
    PROJECT_NAME "dry-run-sample"
    VERSION "1.0.0"
    OUTPUT_FILE "${OUT_FILE}"
)

# 2. Dry-run validate
sourcelume_validate(
    REGISTRY_URL "http://localhost:8082"
    RECORD_FILE "${OUT_FILE}"
    DRY_RUN
)

# 3. Dry-run publish
sourcelume_publish(
    REGISTRY_URL "http://localhost:8082"
    RECORD_FILE "${OUT_FILE}"
    DRY_RUN
)

file(REMOVE_RECURSE "${TEST_TMP_DIR}")
message(STATUS "Dry-run validation and publishing assertions passed!")
