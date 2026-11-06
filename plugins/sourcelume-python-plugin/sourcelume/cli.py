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

import typer
import os
import json
from pathlib import Path
from typing import Optional
from pydantic import ValidationError
from .generator import SourcelumeGenerator
from .client import SourcelumeClient
from .models import ProvenanceRecord

app = typer.Typer(help="Apache Sourcelume Tooling CLI")

def get_record_path(project_dir: Path) -> Path:
    return project_dir / "provenance-record.json"


def load_submission(record_path: Path) -> bytes:
    """Loads a record for submission to the registry, as the file's exact bytes.

    Dataset records (`type: ProvenanceRecord`) are checked against the plugin's
    own model before they leave the machine. Every other record type — the
    spec grows them faster than a local model can — is judged by the registry,
    which is the authority anyway. Either way the file is sent as it is: the
    registry stores and hashes the bytes it receives, so re-serializing here
    would change what the record says (fields the model lacks, its defaults)
    and what a signature over the file covers.
    """
    record_data = record_path.read_bytes()
    try:
        # Decode strictly: the registry accepts only UTF-8 without a BOM, and
        # json.loads on bytes would also accept a BOM or UTF-16.
        parsed = json.loads(record_data.decode("utf-8"))
    except (json.JSONDecodeError, UnicodeDecodeError) as e:
        typer.echo(f"Error: {record_path} is not valid JSON: {e}", err=True)
        raise typer.Exit(code=1)
    if not isinstance(parsed, dict):
        typer.echo(f"Error: {record_path} is not a JSON object.", err=True)
        raise typer.Exit(code=1)
    if parsed.get("type", "ProvenanceRecord") == "ProvenanceRecord":
        try:
            ProvenanceRecord.model_validate_json(record_data)
        except ValidationError as e:
            typer.echo(f"Error: {record_path} is not a valid dataset record: {e}", err=True)
            raise typer.Exit(code=1)
    return record_data

@app.command()
def generate(
    project_dir: Path = typer.Argument(Path("."), help="Directory of the Python project"),
):
    """Generates a `provenance-record.json` from project metadata."""
    project_dir = Path(project_dir).resolve()
    if not project_dir.is_dir():
        typer.echo(f"Error: {project_dir} is not a directory.", err=True)
        raise typer.Exit(code=1)

    typer.echo(f"Generating provenance record for {project_dir}...")
    generator = SourcelumeGenerator(str(project_dir))
    record = generator.generate()

    output_path = get_record_path(project_dir)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(record.to_json_ld())

    typer.echo(f"Successfully generated: {output_path}")


@app.command()
def validate(
    project_dir: Path = typer.Argument(Path("."), help="Directory of the Python project"),
    registry_url: str = typer.Option("http://localhost:8082", "--registry-url", "-u", envvar="SOURCELUME_REGISTRY_URL"),
    token: Optional[str] = typer.Option(None, "--token", "-t", envvar="SOURCELUME_REGISTRY_TOKEN"),
    username: Optional[str] = typer.Option(None, "--username", "-n", envvar="SOURCELUME_REGISTRY_USERNAME"),
    password: Optional[str] = typer.Option(None, "--password", "-p", envvar="SOURCELUME_REGISTRY_PASSWORD"),
):
    """Validates the local `provenance-record.json` against the registry."""
    project_dir = Path(project_dir).resolve()
    record_path = get_record_path(project_dir)

    if not record_path.exists():
        typer.echo(f"Error: {record_path} not found. Run 'generate' first.", err=True)
        raise typer.Exit(code=1)

    typer.echo(f"Validating {record_path} against {registry_url}...")

    record = load_submission(record_path)

    client = SourcelumeClient(
        registry_url=registry_url,
        token=token,
        username=username,
        password=password
    )

    try:
        response = client.validate(record)
        if response.is_success:
            typer.echo("✅ Validation successful!")
        else:
            typer.echo(f"❌ Validation failed: {response.error_message}", err=True)
            raise typer.Exit(code=1)
    finally:
        client.close()


@app.command()
def publish(
    project_dir: Path = typer.Argument(Path("."), help="Directory of the Python project"),
    registry_url: str = typer.Option("http://localhost:8082", "--registry-url", "-u", envvar="SOURCELUME_REGISTRY_URL"),
    token: Optional[str] = typer.Option(None, "--token", "-t", envvar="SOURCELUME_REGISTRY_TOKEN"),
    username: Optional[str] = typer.Option(None, "--username", "-n", envvar="SOURCELUME_REGISTRY_USERNAME"),
    password: Optional[str] = typer.Option(None, "--password", "-p", envvar="SOURCELUME_REGISTRY_PASSWORD"),
    allow_conflict: bool = typer.Option(False, "--allow-conflict", "-c", envvar="SOURCELUME_ALLOW_CONFLICT"),
):
    """Submits the local `provenance-record.json` to the registry."""
    project_dir = Path(project_dir).resolve()
    record_path = get_record_path(project_dir)

    if not record_path.exists():
        typer.echo(f"Error: {record_path} not found. Run 'generate' first.", err=True)
        raise typer.Exit(code=1)

    typer.echo(f"Publishing {record_path} to {registry_url}...")

    record = load_submission(record_path)

    client = SourcelumeClient(
        registry_url=registry_url,
        token=token,
        username=username,
        password=password
    )

    try:
        response = client.publish(record)
        if response.is_success and response.is_incomplete:
            typer.echo(
                "❌ Publication incomplete: the registry stored the record as INCOMPLETE. "
                "Fix these issues and publish again:",
                err=True,
            )
            for line in response.validation_issues:
                typer.echo(f"  - {line}", err=True)
            raise typer.Exit(code=1)
        elif response.is_success:
            typer.echo("✅ Publication successful!")
        elif response.is_conflict and allow_conflict:
            typer.echo(
                f"⚠️ The registry refused the record (HTTP 409): {response.reason or response.body}. "
                "Continuing as --allow-conflict is set."
            )
            typer.echo("✅ Publication successful!")
        else:
            typer.echo(f"❌ Publication failed: {response.error_message}", err=True)
            raise typer.Exit(code=1)
    finally:
        client.close()


if __name__ == "__main__":
    app()
