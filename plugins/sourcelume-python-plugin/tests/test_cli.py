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

"""Tests for Sourcelume CLI."""

import json

from typer.testing import CliRunner
import respx
import httpx
from sourcelume.cli import app

runner = CliRunner()


def test_cli_generate_command(tmp_path):
    pyproject = tmp_path / "pyproject.toml"
    pyproject.write_text(
        """
[project]
name = "cli-test-pkg"
version = "0.1.0"
license = { text = "Apache-2.0" }
"""
    )

    result = runner.invoke(app, ["generate", str(tmp_path)])
    assert result.exit_code == 0
    assert "Successfully generated" in result.stdout

    record_file = tmp_path / "provenance-record.json"
    assert record_file.exists()


TRAINING_RECORD = {
    "type": "TrainingProvenanceRecord",
    "name": "Tiny char-LM",
    "modelUri": "tiny-lm",
    "modelVersion": "v1",
    "disclosure": "complete",
    "trainingData": [
        {
            "dataset": "https://sourcelume.apache.org/records/sample/gutenberg-alice-1865",
            "phase": "pretraining",
            "tokens": 20000,
            "share": 1.0,
        }
    ],
}


@respx.mock
def test_cli_validate_command(tmp_path):
    pyproject = tmp_path / "pyproject.toml"
    pyproject.write_text(
        """
[project]
name = "cli-test-pkg"
version = "0.1.0"
license = { text = "Apache-2.0" }
"""
    )

    # Generate first
    gen_result = runner.invoke(app, ["generate", str(tmp_path)])
    assert gen_result.exit_code == 0

    # Mock validation endpoint
    respx.post("http://localhost:8082/records/validate").mock(
        return_value=httpx.Response(200, json={"valid": True})
    )

    val_result = runner.invoke(app, ["validate", str(tmp_path), "--registry-url", "http://localhost:8082"])
    assert val_result.exit_code == 0
    assert "Validation successful!" in val_result.stdout


@respx.mock
def test_cli_publish_command(tmp_path):
    pyproject = tmp_path / "pyproject.toml"
    pyproject.write_text(
        """
[project]
name = "cli-test-pkg"
version = "0.1.0"
license = { text = "Apache-2.0" }
"""
    )

    runner.invoke(app, ["generate", str(tmp_path)])

    respx.post("http://localhost:8082/records").mock(
        return_value=httpx.Response(201, json={"status": "created", "id": "urn:test"})
    )

    pub_result = runner.invoke(app, ["publish", str(tmp_path), "--registry-url", "http://localhost:8082"])
    assert pub_result.exit_code == 0
    assert "Publication successful!" in pub_result.stdout


@respx.mock
def test_cli_publish_conflict_command(tmp_path):
    pyproject = tmp_path / "pyproject.toml"
    pyproject.write_text(
        """
[project]
name = "cli-test-pkg"
version = "0.1.0"
license = { text = "Apache-2.0" }
"""
    )

    runner.invoke(app, ["generate", str(tmp_path)])

    respx.post("http://localhost:8082/records").mock(
        return_value=httpx.Response(409, json={"error": "Conflict"})
    )

    # Without allow-conflict -> failure
    pub_result_fail = runner.invoke(app, ["publish", str(tmp_path), "--registry-url", "http://localhost:8082"])
    assert pub_result_fail.exit_code == 1
    assert "Publication failed" in (pub_result_fail.stdout + pub_result_fail.stderr)

    # With allow-conflict -> success
    pub_result_ok = runner.invoke(app, ["publish", str(tmp_path), "--registry-url", "http://localhost:8082", "--allow-conflict"])
    assert pub_result_ok.exit_code == 0
    assert "Publication successful!" in (pub_result_ok.stdout + pub_result_ok.stderr)


@respx.mock
def test_cli_validate_passes_model_records_through_untouched(tmp_path):
    (tmp_path / "provenance-record.json").write_text(json.dumps(TRAINING_RECORD))
    route = respx.post("http://localhost:8082/records/validate").mock(
        return_value=httpx.Response(200, json={"valid": True})
    )

    result = runner.invoke(app, ["validate", str(tmp_path), "--registry-url", "http://localhost:8082"])

    assert result.exit_code == 0
    assert "Validation successful!" in result.stdout
    sent = json.loads(route.calls.last.request.content)
    assert sent == TRAINING_RECORD  # verbatim: no model ever reshaped it


@respx.mock
def test_cli_publish_passes_model_records_through_untouched(tmp_path):
    (tmp_path / "provenance-record.json").write_text(json.dumps(TRAINING_RECORD))
    route = respx.post("http://localhost:8082/records").mock(
        return_value=httpx.Response(201, json={"recordStatus": "VALIDATED"})
    )

    result = runner.invoke(app, ["publish", str(tmp_path), "--registry-url", "http://localhost:8082"])

    assert result.exit_code == 0
    assert "Publication successful!" in result.stdout
    assert json.loads(route.calls.last.request.content) == TRAINING_RECORD



@respx.mock
def test_cli_publish_fails_when_the_registry_stores_the_record_as_incomplete(tmp_path):
    (tmp_path / "provenance-record.json").write_text(json.dumps(TRAINING_RECORD))
    respx.post("http://localhost:8082/records").mock(
        return_value=httpx.Response(
            201,
            json={
                "recordStatus": "INCOMPLETE",
                "validationIssues": json.dumps([{"path": "/", "message": "required property 'license' not found"}]),
            },
        )
    )

    result = runner.invoke(app, ["publish", str(tmp_path), "--registry-url", "http://localhost:8082"])

    assert result.exit_code == 1
    assert "Publication successful!" not in result.output
    assert "INCOMPLETE" in result.output
    assert "/: required property 'license' not found" in result.output


@respx.mock
def test_cli_publish_allow_conflict_shows_the_registry_reason(tmp_path):
    (tmp_path / "provenance-record.json").write_text(json.dumps(TRAINING_RECORD))
    respx.post("http://localhost:8082/records").mock(
        return_value=httpx.Response(409, json={"reason": "The id belongs to a VALIDATED record"})
    )

    result = runner.invoke(
        app, ["publish", str(tmp_path), "--registry-url", "http://localhost:8082", "--allow-conflict"]
    )

    assert result.exit_code == 0
    assert "The id belongs to a VALIDATED record" in result.output

def test_cli_rejects_broken_json_with_a_clean_error(tmp_path):
    (tmp_path / "provenance-record.json").write_text("{not json")

    result = runner.invoke(app, ["validate", str(tmp_path), "--registry-url", "http://localhost:8082"])

    assert result.exit_code == 1
    assert "not valid JSON" in result.output


# A valid dataset record whose content the plugin's model would change if it
# re-serialized it: a field the model doesn't have (contentCreatedEnd), a
# creator without a role, no licenseCategory, plus CRLF line ends and
# non-ASCII text that a re-encoding would not keep byte for byte.
DATASET_RECORD_BYTES = (
    '{\r\n'
    '  "@context": "https://sourcelume.apache.org/context/0.0.1/sourcelume.jsonld",\r\n'
    '  "id": "https://example.org/records/bytes-test",\r\n'
    '  "type": "ProvenanceRecord",\r\n'
    '  "identifier": "https://example.org/datasets/bytes-test",\r\n'
    '  "name": "Æblegrød – bytes test",\r\n'
    '  "license": "https://spdx.org/licenses/CC0-1.0.html",\r\n'
    '  "creator": [{"type": "schema:Organization", "name": "Example Org"}],\r\n'
    '  "created": "2026-11-06T00:00:00Z",\r\n'
    '  "added": "2026-11-06T00:00:00Z",\r\n'
    '  "contentCreated": "2020-01-01T00:00:00Z",\r\n'
    '  "contentCreatedEnd": "2020-12-31T00:00:00Z",\r\n'
    '  "origin": "Collected for the test",\r\n'
    '  "custodyChain": [{"agent": "https://example.org/agents/a", "action": "collected", "startTime": "2020-01-01T00:00:00Z"}]\r\n'
    '}\r\n'
).encode("utf-8")


@respx.mock
def test_cli_validate_sends_dataset_records_byte_for_byte(tmp_path):
    (tmp_path / "provenance-record.json").write_bytes(DATASET_RECORD_BYTES)
    route = respx.post("http://localhost:8082/records/validate").mock(
        return_value=httpx.Response(200, json={"valid": True})
    )

    result = runner.invoke(app, ["validate", str(tmp_path), "--registry-url", "http://localhost:8082"])

    assert result.exit_code == 0
    assert route.calls.last.request.content == DATASET_RECORD_BYTES


@respx.mock
def test_cli_publish_sends_dataset_records_byte_for_byte(tmp_path):
    (tmp_path / "provenance-record.json").write_bytes(DATASET_RECORD_BYTES)
    route = respx.post("http://localhost:8082/records").mock(
        return_value=httpx.Response(201, json={"recordStatus": "VALIDATED"})
    )

    result = runner.invoke(app, ["publish", str(tmp_path), "--registry-url", "http://localhost:8082"])

    assert result.exit_code == 0
    assert route.calls.last.request.content == DATASET_RECORD_BYTES


def test_cli_rejects_json_that_is_not_an_object(tmp_path):
    (tmp_path / "provenance-record.json").write_text("[1, 2]")

    result = runner.invoke(app, ["validate", str(tmp_path), "--registry-url", "http://localhost:8082"])

    assert result.exit_code == 1
    assert "not a JSON object" in result.output


@respx.mock
def test_cli_rejects_a_record_that_is_not_plain_utf8_before_sending(tmp_path):
    route = respx.post("http://localhost:8082/records").mock(
        return_value=httpx.Response(201, json={"recordStatus": "VALIDATED"})
    )
    model = json.dumps(TRAINING_RECORD)
    for name, raw in [("bom", b"\xef\xbb\xbf" + model.encode("utf-8")), ("utf16", model.encode("utf-16"))]:
        (tmp_path / "provenance-record.json").write_bytes(raw)

        result = runner.invoke(app, ["publish", str(tmp_path), "--registry-url", "http://localhost:8082"])

        assert result.exit_code == 1, name
        assert "not valid JSON" in result.output, name
    assert not route.called
