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

from __future__ import annotations

from typing import List, Optional
from pydantic import BaseModel, Field, ConfigDict


class Creator(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    type: str = Field(default="schema:Organization", alias="type")
    name: str
    role: Optional[str] = "originator"
    email: Optional[str] = None


class LicenseHistoryEntry(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    iri: str
    effective_date: Optional[str] = Field(default=None, alias="effectiveDate")


class CustodyChainEntry(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    agent: str
    action: str
    start_time: str = Field(alias="startTime")


class ProvenanceRecord(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    context: str = Field(
        default="https://sourcelume.apache.org/context/0.0.1/sourcelume.jsonld",
        alias="@context"
    )
    id: Optional[str] = None
    type: str = "ProvenanceRecord"
    identifier: Optional[str] = None
    name: Optional[str] = None
    version: Optional[str] = None
    license: Optional[str] = None
    license_scope: Optional[str] = Field(default=None, alias="licenseScope")
    license_category: Optional[str] = Field(default="open-source", alias="licenseCategory")
    license_note: Optional[str] = Field(default=None, alias="licenseNote")
    license_history: Optional[List[LicenseHistoryEntry]] = Field(default=None, alias="licenseHistory")
    creator: List[Creator] = Field(default_factory=list)
    created: Optional[str] = None
    added: str
    content_created: str = Field(alias="contentCreated")
    origin: str
    custody_chain: List[CustodyChainEntry] = Field(default_factory=list, alias="custodyChain")

    def to_json_ld(self) -> str:
        """Serializes the record to a JSON-LD string using the correct aliases."""
        return self.model_dump_json(by_alias=True, exclude_none=True)
