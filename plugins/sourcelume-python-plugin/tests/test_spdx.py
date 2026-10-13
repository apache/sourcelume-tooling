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

"""Tests for SPDX license mapping."""

from sourcelume.spdx import to_spdx_iri


def test_standard_apache_licenses():
    assert to_spdx_iri("Apache-2.0") == "https://spdx.org/licenses/Apache-2.0.html"
    assert to_spdx_iri("Apache License, Version 2.0") == "https://spdx.org/licenses/Apache-2.0.html"
    assert to_spdx_iri("The Apache Software License, Version 2.0") == "https://spdx.org/licenses/Apache-2.0.html"
    assert to_spdx_iri("http://www.apache.org/licenses/LICENSE-2.0.txt") == "https://spdx.org/licenses/Apache-2.0.html"
    assert to_spdx_iri("https://www.apache.org/licenses/LICENSE-2.0.txt") == "https://spdx.org/licenses/Apache-2.0.html"


def test_mit_and_bsd_licenses():
    assert to_spdx_iri("MIT") == "https://spdx.org/licenses/MIT.html"
    assert to_spdx_iri("The MIT License") == "https://spdx.org/licenses/MIT.html"
    assert to_spdx_iri("BSD-3-Clause") == "https://spdx.org/licenses/BSD-3-Clause.html"
    assert to_spdx_iri("BSD-2-Clause") == "https://spdx.org/licenses/BSD-2-Clause.html"


def test_creative_commons_and_open_data():
    assert to_spdx_iri("CC0-1.0") == "https://spdx.org/licenses/CC0-1.0.html"
    assert to_spdx_iri("CC-BY-4.0") == "https://spdx.org/licenses/CC-BY-4.0.html"
    assert to_spdx_iri("ODC-By") == "https://spdx.org/licenses/ODC-By-1.0.html"
    assert to_spdx_iri("ODbL-1.0") == "https://spdx.org/licenses/ODbL-1.0.html"


def test_direct_urls_and_uris():
    assert to_spdx_iri("https://example.org/custom-license") == "https://example.org/custom-license"
    assert to_spdx_iri("urn:isbn:0451450523") == "urn:isbn:0451450523"


def test_fallback_gracefully():
    assert to_spdx_iri(None) == "https://spdx.org/licenses/Apache-2.0.html"
    assert to_spdx_iri("") == "https://spdx.org/licenses/Apache-2.0.html"
    assert to_spdx_iri("Custom-License-1.0") == "https://spdx.org/licenses/Custom-License-1.0.html"
