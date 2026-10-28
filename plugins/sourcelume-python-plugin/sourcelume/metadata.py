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

import os
import datetime
import subprocess
import re
from typing import Optional, Any
import tomlkit
from .models import ProvenanceRecord, Creator, CustodyChainEntry
from .spdx import to_spdx_iri


class MetadataExtractor:
    def __init__(self, project_dir: str):
        self.project_dir = project_dir
        self.pyproject_path = os.path.join(project_dir, "pyproject.toml")

    def extract(self) -> ProvenanceRecord:
        """Extracts metadata from pyproject.toml and returns a ProvenanceRecord."""
        record_data: dict[str, Any] = {}

        # Try to load pyproject.toml
        if os.path.exists(self.pyproject_path):
            with open(self.pyproject_path, "r", encoding="utf-8") as f:
                try:
                    data = tomlkit.parse(f.read())
                    self._apply_toml_metadata(data, record_data)
                except Exception:
                    pass

        # Apply fallbacks/defaults if necessary
        self._apply_fallbacks(record_data)

        # Set timestamps (UTC ISO-8601 with Z)
        now_iso = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        record_data["added"] = now_iso
        record_data["content_created"] = now_iso
        record_data["created"] = now_iso

        # Set origin if not already set
        if "origin" not in record_data or not record_data["origin"]:
            try:
                origin = subprocess.check_output(
                    ["git", "remote", "get-url", "origin"],
                    cwd=self.project_dir,
                    text=True,
                    stderr=subprocess.DEVNULL,
                ).strip()
                record_data["origin"] = origin
            except Exception:
                record_data["origin"] = f"https://sourcelume.apache.org/python/{record_data.get('name', 'unknown')}"

        # Initialize custody chain with creation event
        agent = record_data.get("origin") or "https://sourcelume.apache.org/agents/python-plugin"
        if not (agent.startswith("http://") or agent.startswith("https://") or agent.startswith("urn:")):
            clean_agent = re.sub(r"[^a-zA-Z0-9.-]", "_", agent)
            agent = f"urn:sourcelume:agent:{clean_agent}"

        pkg_name = record_data.get("name", "unknown")
        pkg_version = record_data.get("version", "0.0.1")
        action = f"Build and package Python package {pkg_name}:{pkg_version}"

        record_data["custody_chain"] = [
            CustodyChainEntry(
                agent=agent,
                action=action,
                start_time=now_iso
            )
        ]

        return ProvenanceRecord(**record_data)

    def _apply_toml_metadata(self, data: tomlkit.TOMLDocument, record_data: dict[str, Any]):
        # Extract core project metadata
        project = data.get("tool", {}).get("poetry", {})
        if not project:
            # Try standard PEP 621
            project = data.get("project", {})

        if project.get("name"):
            record_data["name"] = project["name"]

        if project.get("version"):
            record_data["version"] = project["version"]

        # Handle license
        license_info = project.get("license")
        license_val = None
        if isinstance(license_info, dict):
            # PEP 621 / Poetry style: {text = "MIT", file = "LICENSE"}
            license_val = license_info.get("text")
        elif isinstance(license_info, str):
            license_val = license_info

        # Also check classifiers for license if not explicitly set
        if not license_val and "classifiers" in project:
            for classifier in project.get("classifiers", []):
                if classifier.startswith("License ::"):
                    parts = classifier.split("::")
                    license_val = parts[-1].strip()
                    break

        record_data["license"] = to_spdx_iri(license_val)
        record_data["license_category"] = "open-source"

        # Handle authors/creators
        authors = project.get("authors", [])
        creators = []
        for author in authors:
            if isinstance(author, dict):
                name = author.get("name", "")
                email = author.get("email")
                org_type = "schema:Organization" if "foundation" in name.lower() or "group" in name.lower() or "team" in name.lower() else "schema:Person"
                creators.append(Creator(type=org_type, name=name, role="originator", email=email))
            elif isinstance(author, str):
                if "<" in author and ">" in author:
                    name_part = author.split("<")[0].strip()
                    email_part = author.split("<")[1].split(">")[0].strip()
                    org_type = "schema:Organization" if "foundation" in name_part.lower() or "group" in name_part.lower() or "team" in name_part.lower() else "schema:Person"
                    creators.append(Creator(type=org_type, name=name_part, role="originator", email=email_part))
                else:
                    org_type = "schema:Organization" if "foundation" in author.lower() or "group" in author.lower() or "team" in author.lower() else "schema:Person"
                    creators.append(Creator(type=org_type, name=author, role="originator"))
            else:
                creators.append(Creator(name=str(author), role="originator"))

        if creators:
            record_data["creator"] = creators

    def _apply_fallbacks(self, record_data: dict[str, Any]):
        name = record_data.get("name")
        version = record_data.get("version")

        if name and version:
            slug_name = name.lower().replace(" ", "-")
            record_data["identifier"] = f"sourcelume://python/{slug_name}"
            record_data["id"] = f"urn:sourcelume:python:{slug_name}:{version}"
        else:
            if not record_data.get("id"):
                record_data["id"] = "urn:sourcelume:python:unknown:0.0.0"
            if not record_data.get("identifier"):
                record_data["identifier"] = "sourcelume://python/unknown"

        if not record_data.get("license"):
            record_data["license"] = to_spdx_iri(None)

        if not record_data.get("license_category"):
            record_data["license_category"] = "open-source"

        if not record_data.get("creator"):
            record_data["creator"] = [Creator(name="Unknown Creator", role="originator")]
