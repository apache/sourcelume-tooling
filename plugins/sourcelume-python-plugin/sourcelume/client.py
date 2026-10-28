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

import httpx
import base64
import json
from typing import Any, Optional, Union
from .models import ProvenanceRecord


class SourcelumeResponse:
    def __init__(self, status_code: int, body: str = "", error_message: Optional[str] = None):
        self.status_code = status_code
        self.body = body or ""
        self.error_message = error_message
        self.is_success = 200 <= status_code < 300
        self.is_conflict = status_code == 409
        self.is_validation_error = status_code == 422
        fields = _json_object(self.body)
        # The registry stores an invalid record as INCOMPLETE and still answers 2xx.
        self.record_status: Optional[str] = fields.get("recordStatus")
        self.is_incomplete = self.record_status == "INCOMPLETE"
        self.reason: Optional[str] = fields.get("reason")
        self.validation_issues = _issue_lines(fields.get("validationIssues"))

    @classmethod
    def success(cls, status_code: int, body: str = "") -> "SourcelumeResponse":
        return cls(status_code, body)

    @classmethod
    def error(cls, status_code: int, body: str = "", error_message: str = "") -> "SourcelumeResponse":
        return cls(status_code, body, error_message)


def _json_object(text: str) -> dict[str, Any]:
    try:
        value = json.loads(text)
    except ValueError:
        return {}
    return value if isinstance(value, dict) else {}


def _issue_lines(issues: Any) -> list[str]:
    """The registry sends validationIssues as a JSON array inside a string."""
    if isinstance(issues, str):
        try:
            issues = json.loads(issues)
        except ValueError:
            return [issues]
    if not isinstance(issues, list):
        return []
    lines = []
    for issue in issues:
        if isinstance(issue, dict):
            path = issue.get("path")
            message = issue.get("message", "")
            lines.append(f"{path}: {message}" if path else str(message))
        else:
            lines.append(str(issue))
    return lines


class SourcelumeClient:
    def __init__(
        self,
        registry_url: str = "http://localhost:8082",
        username: Optional[str] = None,
        password: Optional[str] = None,
        token: Optional[str] = None,
        timeout: float = 30.0,
    ):
        self.registry_url = registry_url.rstrip("/")
        self.username = username
        self.password = password
        self.token = token
        self.timeout = timeout
        self.client = httpx.Client(timeout=timeout)

    def _get_auth_headers(self) -> dict[str, str]:
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
        }
        if self.token:
            headers["Authorization"] = f"Bearer {self.token.strip()}"
        elif self.username:
            auth_str = f"{self.username}:{self.password or ''}"
            encoded_auth = base64.b64encode(auth_str.encode("utf-8")).decode("ascii")
            headers["Authorization"] = f"Basic {encoded_auth}"
        return headers

    def validate(self, record: Union[ProvenanceRecord, str]) -> SourcelumeResponse:
        url = f"{self.registry_url}/records/validate"
        payload = record.to_json_ld() if isinstance(record, ProvenanceRecord) else record
        try:
            response = self.client.post(
                url,
                content=payload,
                headers=self._get_auth_headers(),
            )
            if response.is_success:
                return SourcelumeResponse.success(response.status_code, response.text)
            else:
                return SourcelumeResponse.error(
                    response.status_code,
                    response.text,
                    f"Validation failed with HTTP {response.status_code}: {response.text}",
                )
        except httpx.RequestError as exc:
            return SourcelumeResponse.error(0, "", f"Network error occurred: {exc}")

    def publish(self, record: Union[ProvenanceRecord, str]) -> SourcelumeResponse:
        url = f"{self.registry_url}/records"
        payload = record.to_json_ld() if isinstance(record, ProvenanceRecord) else record
        try:
            response = self.client.post(
                url,
                content=payload,
                headers=self._get_auth_headers(),
            )
            if response.is_success:
                return SourcelumeResponse.success(response.status_code, response.text)
            elif response.status_code == 409:
                reason = _json_object(response.text).get("reason") or response.text
                return SourcelumeResponse.error(
                    response.status_code,
                    response.text,
                    f"The registry refused the record (HTTP 409): {reason}",
                )
            else:
                return SourcelumeResponse.error(
                    response.status_code,
                    response.text,
                    f"Publish failed with HTTP {response.status_code}: {response.text}",
                )
        except httpx.RequestError as exc:
            return SourcelumeResponse.error(0, "", f"Network error occurred: {exc}")

    def close(self):
        self.client.close()
