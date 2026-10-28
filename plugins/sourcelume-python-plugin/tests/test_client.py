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

"""Tests for SourcelumeClient."""

import json

import respx
import httpx
from sourcelume.client import SourcelumeClient, SourcelumeResponse
from sourcelume.models import ProvenanceRecord, CustodyChainEntry


@respx.mock
def test_validate_record_success():
    respx.post("http://localhost:8082/records/validate").mock(
        return_value=httpx.Response(200, json={"valid": True})
    )

    client = SourcelumeClient(registry_url="http://localhost:8082", token="test-token")
    record = ProvenanceRecord(
        id="urn:test",
        added="2026-10-13T00:00:00Z",
        content_created="2026-10-13T00:00:00Z",
        origin="https://example.org",
        custody_chain=[CustodyChainEntry(agent="agent", action="act", startTime="2026-10-13T00:00:00Z")]
    )

    resp = client.validate(record)
    assert resp.is_success
    assert resp.status_code == 200
    assert not resp.is_conflict
    assert not resp.is_validation_error
    client.close()


@respx.mock
def test_publish_record_conflict():
    respx.post("http://localhost:8082/records").mock(
        return_value=httpx.Response(409, json={"error": "Record already exists"})
    )

    client = SourcelumeClient(registry_url="http://localhost:8082")
    record = ProvenanceRecord(
        id="urn:test",
        added="2026-10-13T00:00:00Z",
        content_created="2026-10-13T00:00:00Z",
        origin="https://example.org",
    )

    resp = client.publish(record)
    assert not resp.is_success
    assert resp.is_conflict
    assert resp.status_code == 409
    assert "already exists" in resp.error_message
    client.close()


@respx.mock
def test_validate_record_failure_422():
    respx.post("http://localhost:8082/records/validate").mock(
        return_value=httpx.Response(422, json={"conforms": False, "issues": [{"message": "Invalid URI"}]})
    )

    client = SourcelumeClient(registry_url="http://localhost:8082")
    record = ProvenanceRecord(
        id="urn:test",
        added="2026-10-13T00:00:00Z",
        content_created="2026-10-13T00:00:00Z",
        origin="https://example.org",
    )

    resp = client.validate(record)
    assert not resp.is_success
    assert resp.is_validation_error
    assert resp.status_code == 422
    assert "422" in resp.error_message
    client.close()


INCOMPLETE_ANSWER = {
    "qualifiedName": "urn:test",
    "recordStatus": "INCOMPLETE",
    "validationIssues": json.dumps([
        {"validatorId": "json-schema", "severity": "VIOLATION", "path": "/", "message": "required property 'license' not found"}
    ]),
}


@respx.mock
def test_publish_reports_an_incomplete_record():
    respx.post("http://localhost:8082/records").mock(return_value=httpx.Response(201, json=INCOMPLETE_ANSWER))

    client = SourcelumeClient(registry_url="http://localhost:8082")
    resp = client.publish('{"id": "urn:test"}')

    assert resp.is_success
    assert resp.is_incomplete
    assert resp.record_status == "INCOMPLETE"
    assert resp.validation_issues == ["/: required property 'license' not found"]
    client.close()


@respx.mock
def test_publish_of_a_validated_record_is_not_incomplete():
    respx.post("http://localhost:8082/records").mock(
        return_value=httpx.Response(201, json={"qualifiedName": "urn:test", "recordStatus": "VALIDATED"})
    )

    client = SourcelumeClient(registry_url="http://localhost:8082")
    resp = client.publish('{"id": "urn:test"}')

    assert resp.is_success
    assert not resp.is_incomplete
    assert resp.validation_issues == []
    client.close()


@respx.mock
def test_publish_conflict_names_the_registry_reason():
    respx.post("http://localhost:8082/records").mock(
        return_value=httpx.Response(
            409,
            json={"qualifiedName": "urn:test", "recordStatus": "VALIDATED", "reason": "The id belongs to a VALIDATED record"},
        )
    )

    client = SourcelumeClient(registry_url="http://localhost:8082")
    resp = client.publish('{"id": "urn:test"}')

    assert resp.is_conflict
    assert resp.reason == "The id belongs to a VALIDATED record"
    assert "The id belongs to a VALIDATED record" in resp.error_message
    client.close()
