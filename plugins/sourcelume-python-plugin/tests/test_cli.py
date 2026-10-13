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
