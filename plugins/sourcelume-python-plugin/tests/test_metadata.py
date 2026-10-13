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

"""Tests for metadata extraction."""

import json
from sourcelume.metadata import MetadataExtractor


def test_metadata_extraction_pep621(tmp_path):
    pyproject = tmp_path / "pyproject.toml"
    pyproject.write_text(
        """
[project]
name = "my-sample-pkg"
version = "1.2.3"
description = "A sample Python package"
license = { text = "MIT" }
authors = [
    { name = "Jane Doe", email = "jane@example.com" },
    { name = "Apache Software Foundation", email = "dev@apache.org" }
]
"""
    )

    extractor = MetadataExtractor(str(tmp_path))
    record = extractor.extract()

    assert record.id == "urn:sourcelume:python:my-sample-pkg:1.2.3"
    assert record.identifier == "sourcelume://python/my-sample-pkg"
    assert record.name == "my-sample-pkg"
    assert record.version == "1.2.3"
    assert record.license == "https://spdx.org/licenses/MIT.html"
    assert record.license_category == "open-source"
    assert len(record.creator) == 2
    assert record.creator[0].name == "Jane Doe"
    assert record.creator[0].type == "schema:Person"
    assert record.creator[1].name == "Apache Software Foundation"
    assert record.creator[1].type == "schema:Organization"
    assert len(record.custody_chain) == 1
    assert record.custody_chain[0].start_time is not None
    assert record.custody_chain[0].action == "Build and package Python package my-sample-pkg:1.2.3"

    json_str = record.to_json_ld()
    data = json.loads(json_str)
    assert data["@context"] == "https://sourcelume.apache.org/context/0.0.1/sourcelume.jsonld"
    assert data["id"] == "urn:sourcelume:python:my-sample-pkg:1.2.3"
    assert data["custodyChain"][0]["startTime"] == record.custody_chain[0].start_time
    assert data["license"] == "https://spdx.org/licenses/MIT.html"


def test_metadata_extraction_poetry(tmp_path):
    pyproject = tmp_path / "pyproject.toml"
    pyproject.write_text(
        """
[tool.poetry]
name = "poetry-pkg"
version = "0.5.0"
license = "Apache-2.0"
authors = ["John Smith <john@example.com>"]
"""
    )

    extractor = MetadataExtractor(str(tmp_path))
    record = extractor.extract()

    assert record.id == "urn:sourcelume:python:poetry-pkg:0.5.0"
    assert record.name == "poetry-pkg"
    assert record.license == "https://spdx.org/licenses/Apache-2.0.html"
    assert len(record.creator) == 1
    assert record.creator[0].name == "John Smith"
    assert record.creator[0].email == "john@example.com"
    assert len(record.custody_chain) == 1


def test_metadata_extraction_fallback(tmp_path):
    extractor = MetadataExtractor(str(tmp_path))
    record = extractor.extract()

    assert record.id == "urn:sourcelume:python:unknown:0.0.0"
    assert record.license == "https://spdx.org/licenses/Apache-2.0.html"
    assert len(record.creator) == 1
    assert record.creator[0].name == "Unknown Creator"
    assert len(record.custody_chain) == 1
