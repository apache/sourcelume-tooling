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
from .generator import SourcelumeGenerator
from .client import SourcelumeClient
from .models import ProvenanceRecord

app = typer.Typer(help="Apache Sourcelume Tooling CLI")

def get_record_path(project_dir: Path) -> Path:
    return project_dir / "provenance-record.json"

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

    with open(record_path, "r", encoding="utf-8") as f:
        record_data = f.read()

    client = SourcelumeClient(
        registry_url=registry_url,
        token=token,
        username=username,
        password=password
    )

    try:
        response = client.validate(ProvenanceRecord.model_validate_json(record_data))
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

    with open(record_path, "r", encoding="utf-8") as f:
        record_data = f.read()

    client = SourcelumeClient(
        registry_url=registry_url,
        token=token,
        username=username,
        password=password
    )

    try:
        response = client.publish(ProvenanceRecord.model_validate_json(record_data))
        if response.is_success:
            typer.echo("✅ Publication successful!")
        elif response.is_conflict and allow_conflict:
            typer.echo("⚠️ Record already exists in registry (HTTP 409). Continuing as --allow-conflict is set.")
            typer.echo("✅ Publication successful!")
        else:
            typer.echo(f"❌ Publication failed: {response.error_message}", err=True)
            raise typer.Exit(code=1)
    finally:
        client.close()


if __name__ == "__main__":
    app()
