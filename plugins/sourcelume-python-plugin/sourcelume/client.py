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
from typing import Optional, Union
from .models import ProvenanceRecord


class SourcelumeResponse:
    def __init__(self, status_code: int, body: str = "", error_message: Optional[str] = None):
        self.status_code = status_code
        self.body = body or ""
        self.error_message = error_message
        self.is_success = 200 <= status_code < 300
        self.is_conflict = status_code == 409
        self.is_validation_error = status_code == 422

    @classmethod
    def success(cls, status_code: int, body: str = "") -> "SourcelumeResponse":
        return cls(status_code, body)

    @classmethod
    def error(cls, status_code: int, body: str = "", error_message: str = "") -> "SourcelumeResponse":
        return cls(status_code, body, error_message)


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
                return SourcelumeResponse.error(
                    response.status_code,
                    response.text,
                    f"Record already exists in registry (HTTP 409): {response.text}",
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
