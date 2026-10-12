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

macro(assert_spdx input expected)
    _sourcelume_to_spdx_iri("${input}" _OUT)
    if(NOT "${_OUT}" STREQUAL "${expected}")
        message(FATAL_ERROR "Assertion failed: input '${input}' mapped to '${_OUT}', expected '${expected}'")
    endif()
endmacro()

# Apache
assert_spdx("Apache-2.0" "https://spdx.org/licenses/Apache-2.0.html")
assert_spdx("apache 2.0" "https://spdx.org/licenses/Apache-2.0.html")
assert_spdx("The Apache Software License, Version 2.0" "https://spdx.org/licenses/Apache-2.0.html")
assert_spdx("http://www.apache.org/licenses/LICENSE-2.0.txt" "https://spdx.org/licenses/Apache-2.0.html")

# MIT
assert_spdx("MIT" "https://spdx.org/licenses/MIT.html")
assert_spdx("mit license" "https://spdx.org/licenses/MIT.html")

# BSD
assert_spdx("BSD-3-Clause" "https://spdx.org/licenses/BSD-3-Clause.html")
assert_spdx("BSD-2-Clause" "https://spdx.org/licenses/BSD-2-Clause.html")

# Creative Commons & Open Data
assert_spdx("CC0-1.0" "https://spdx.org/licenses/CC0-1.0.html")
assert_spdx("public domain" "https://spdx.org/licenses/CC0-1.0.html")
assert_spdx("CC-BY-4.0" "https://spdx.org/licenses/CC-BY-4.0.html")
assert_spdx("ODC-By-1.0" "https://spdx.org/licenses/ODC-By-1.0.html")
assert_spdx("ODbL-1.0" "https://spdx.org/licenses/ODbL-1.0.html")

# Custom / URL
assert_spdx("https://custom.org/license" "https://custom.org/license")
assert_spdx("Custom-License-1.0" "https://spdx.org/licenses/Custom-License-1.0.html")
assert_spdx("" "https://spdx.org/licenses/Apache-2.0.html")

message(STATUS "All SPDX mapping assertions passed!")
