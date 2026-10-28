#!/usr/bin/env bash
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

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_DIR="${SCRIPT_DIR}/helloworld-sample"
REGISTRY_URL="${SOURCELUME_REGISTRY_URL:-http://localhost:8082}"

# Ensure Maven is on PATH if in IntelliJ or standard locations
if ! command -v mvn >/dev/null 2>&1; then
  if [ -d "/Users/jgoodyear/Library/Application Support/JetBrains/IntelliJIdea2026.2/plugins/maven-plugin/lib/maven3/bin" ]; then
    export PATH="/Users/jgoodyear/Library/Application Support/JetBrains/IntelliJIdea2026.2/plugins/maven-plugin/lib/maven3/bin:$PATH"
  fi
fi

# Styling
BOLD="\033[1m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
RESET="\033[0m"

echo -e "${BOLD}${CYAN}========================================================================${RESET}"
echo -e "${BOLD}${CYAN}   Apache Sourcelume Tooling — Example Simulation Runner                ${RESET}"
echo -e "${BOLD}${CYAN}========================================================================${RESET}"
echo -e "Target Project:  ${BOLD}${SAMPLE_DIR}${RESET}"
echo -e "Target Registry: ${BOLD}${REGISTRY_URL}${RESET}\n"

# Step 1: Build sample project and execute sourcelume:generate
echo -e "${BOLD}${BLUE}[Step 1/5] Building Sample and Generating Provenance Record...${RESET}"
cd "${SAMPLE_DIR}"
mvn clean compile org.apache.sourcelume:sourcelume-maven-plugin:0.0.1-SNAPSHOT:generate

SPEC_FILE="${SAMPLE_DIR}/target/sourcelume/provenance-record.json"
if [ -f "${SPEC_FILE}" ]; then
  echo -e "\n${GREEN}✓ Generated Provenance Spec at:${RESET} ${SPEC_FILE}"
  echo -e "${YELLOW}---------------- Payload Preview ----------------${RESET}"
  cat "${SPEC_FILE}"
  echo -e "\n${YELLOW}-------------------------------------------------${RESET}\n"
else
  echo -e "Error: Expected spec file not found at ${SPEC_FILE}" >&2
  exit 1
fi

# Step 2: Simulate Dry-Run Publish
echo -e "${BOLD}${BLUE}[Step 2/5] Simulating Dry-Run Submission (no network call)...${RESET}"
mvn org.apache.sourcelume:sourcelume-maven-plugin:0.0.1-SNAPSHOT:publish \
  -Dsourcelume.dryRun=true \
  -Dregistry.url="${REGISTRY_URL}"

# Step 3: Attempt Live Validation with Local Sourcelume Registry
echo -e "\n${BOLD}${BLUE}[Step 3/5] Attempting Live Validation with Local Sourcelume Registry...${RESET}"
echo -e "Target URL: ${BOLD}${REGISTRY_URL}/records/validate${RESET}"
if mvn org.apache.sourcelume:sourcelume-maven-plugin:0.0.1-SNAPSHOT:validate \
  -Dregistry.url="${REGISTRY_URL}"; then
  echo -e "${GREEN}✓ Live schema and SHACL validation succeeded against local Sourcelume Registry!${RESET}"
else
  VALIDATE_EXIT=$?
  echo -e "\n${YELLOW}Notice: Could not validate against local Sourcelume Registry (Exit code: ${VALIDATE_EXIT}).${RESET}"
  echo -e "Ensure Sourcelume Registry is running locally on ${REGISTRY_URL}:"
  echo -e "  cd ../sourcelume-registry && mvn -pl sourcelume-registry-runtime-quarkus quarkus:dev"
fi

# Step 4: Attempt Live Submission to Local Sourcelume Registry
echo -e "\n${BOLD}${BLUE}[Step 4/5] Attempting Live Submission to Local Sourcelume Registry...${RESET}"
echo -e "Target URL: ${BOLD}${REGISTRY_URL}/records${RESET}"
if mvn org.apache.sourcelume:sourcelume-maven-plugin:0.0.1-SNAPSHOT:publish \
  -Dregistry.url="${REGISTRY_URL}" \
  -Dsourcelume.allowConflict=true; then
  echo -e "${GREEN}✓ Successfully published sample provenance record to local Sourcelume Registry!${RESET}"
else
  PUBLISH_EXIT=$?
  echo -e "\n${YELLOW}Notice: Live submission attempt failed or registry unavailable (Exit code: ${PUBLISH_EXIT}).${RESET}"
fi

# Step 5: Query Live Registry to Verify Ingestion
echo -e "\n${BOLD}${BLUE}[Step 5/5] Querying Local Sourcelume Registry for Ingested Record...${RESET}"
RECORD_ID="urn:sourcelume:maven:org.apache.sourcelume.examples:sourcelume-helloworld-sample:1.0.0-SNAPSHOT"
ENCODED_ID="urn%3Asourcelume%3Amaven%3Aorg.apache.sourcelume.examples%3Asourcelume-helloworld-sample%3A1.0.0-SNAPSHOT"

if command -v curl >/dev/null 2>&1; then
  RECORD_RESP=$(curl -s -f "${REGISTRY_URL}/records/${ENCODED_ID}" 2>/dev/null || true)
  if [ -n "${RECORD_RESP}" ]; then
    echo -e "${GREEN}✓ Ingested record verified in registry at:${RESET} ${REGISTRY_URL}/records/${ENCODED_ID}"
    echo -e "${YELLOW}---------------- Registry Record View ----------------${RESET}"
    if command -v jq >/dev/null 2>&1; then
      echo "${RECORD_RESP}" | jq .
    else
      echo "${RECORD_RESP}"
    fi
    echo -e "${YELLOW}------------------------------------------------------${RESET}"
  else
    echo -e "${YELLOW}Record lookup skipped or not found (registry may not be active).${RESET}"
  fi
fi

echo -e "\n${BOLD}${CYAN}========================================================================${RESET}"
echo -e "${BOLD}${GREEN}   Simulation Run Finished Successfully!                               ${RESET}"
echo -e "${BOLD}${CYAN}========================================================================${RESET}"
