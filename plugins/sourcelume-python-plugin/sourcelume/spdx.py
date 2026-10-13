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

"""SPDX License mapping utilities."""

from typing import Optional
import re

CANONICAL_MAP = {
    # Apache Licenses
    "apache-2.0": "https://spdx.org/licenses/Apache-2.0.html",
    "apache 2.0": "https://spdx.org/licenses/Apache-2.0.html",
    "apache-2": "https://spdx.org/licenses/Apache-2.0.html",
    "apache license, version 2.0": "https://spdx.org/licenses/Apache-2.0.html",
    "apache license 2.0": "https://spdx.org/licenses/Apache-2.0.html",
    "the apache software license, version 2.0": "https://spdx.org/licenses/Apache-2.0.html",
    "the apache license, version 2.0": "https://spdx.org/licenses/Apache-2.0.html",
    "http://www.apache.org/licenses/license-2.0.txt": "https://spdx.org/licenses/Apache-2.0.html",
    "https://www.apache.org/licenses/license-2.0.txt": "https://spdx.org/licenses/Apache-2.0.html",
    "http://www.apache.org/licenses/license-2.0": "https://spdx.org/licenses/Apache-2.0.html",
    "https://www.apache.org/licenses/license-2.0": "https://spdx.org/licenses/Apache-2.0.html",
    "http://www.apache.org/licenses/license-2.0.html": "https://spdx.org/licenses/Apache-2.0.html",
    "https://www.apache.org/licenses/license-2.0.html": "https://spdx.org/licenses/Apache-2.0.html",

    # MIT
    "mit": "https://spdx.org/licenses/MIT.html",
    "mit license": "https://spdx.org/licenses/MIT.html",
    "the mit license": "https://spdx.org/licenses/MIT.html",
    "http://opensource.org/licenses/mit": "https://spdx.org/licenses/MIT.html",
    "https://opensource.org/licenses/mit": "https://spdx.org/licenses/MIT.html",

    # BSD Licenses
    "bsd-3-clause": "https://spdx.org/licenses/BSD-3-Clause.html",
    "bsd 3-clause": "https://spdx.org/licenses/BSD-3-Clause.html",
    "bsd-3": "https://spdx.org/licenses/BSD-3-Clause.html",
    "the 3-clause bsd license": "https://spdx.org/licenses/BSD-3-Clause.html",
    "revised bsd license": "https://spdx.org/licenses/BSD-3-Clause.html",
    "new bsd license": "https://spdx.org/licenses/BSD-3-Clause.html",
    "bsd-2-clause": "https://spdx.org/licenses/BSD-2-Clause.html",
    "bsd 2-clause": "https://spdx.org/licenses/BSD-2-Clause.html",
    "bsd-2": "https://spdx.org/licenses/BSD-2-Clause.html",
    "simplified bsd license": "https://spdx.org/licenses/BSD-2-Clause.html",

    # Creative Commons & Open Data
    "cc0": "https://spdx.org/licenses/CC0-1.0.html",
    "cc0-1.0": "https://spdx.org/licenses/CC0-1.0.html",
    "cc0 1.0": "https://spdx.org/licenses/CC0-1.0.html",
    "cc0 1.0 universal": "https://spdx.org/licenses/CC0-1.0.html",
    "public domain": "https://spdx.org/licenses/CC0-1.0.html",
    "cc-by-4.0": "https://spdx.org/licenses/CC-BY-4.0.html",
    "cc by 4.0": "https://spdx.org/licenses/CC-BY-4.0.html",
    "creative commons attribution 4.0": "https://spdx.org/licenses/CC-BY-4.0.html",
    "creative commons attribution 4.0 international": "https://spdx.org/licenses/CC-BY-4.0.html",
    "odc-by": "https://spdx.org/licenses/ODC-By-1.0.html",
    "odc-by-1.0": "https://spdx.org/licenses/ODC-By-1.0.html",
    "open data commons attribution license": "https://spdx.org/licenses/ODC-By-1.0.html",
    "odbl": "https://spdx.org/licenses/ODbL-1.0.html",
    "odbl-1.0": "https://spdx.org/licenses/ODbL-1.0.html",
    "open database license": "https://spdx.org/licenses/ODbL-1.0.html",

    # Eclipse Public License
    "epl-2.0": "https://spdx.org/licenses/EPL-2.0.html",
    "epl 2.0": "https://spdx.org/licenses/EPL-2.0.html",
    "eclipse public license 2.0": "https://spdx.org/licenses/EPL-2.0.html",
    "eclipse public license - v 2.0": "https://spdx.org/licenses/EPL-2.0.html",
    "epl-1.0": "https://spdx.org/licenses/EPL-1.0.html",
    "epl 1.0": "https://spdx.org/licenses/EPL-1.0.html",
    "eclipse public license 1.0": "https://spdx.org/licenses/EPL-1.0.html",
    "eclipse public license - v 1.0": "https://spdx.org/licenses/EPL-1.0.html",

    # GNU Licenses
    "gpl-3.0": "https://spdx.org/licenses/GPL-3.0-only.html",
    "gpl-3.0-only": "https://spdx.org/licenses/GPL-3.0-only.html",
    "gpl 3.0": "https://spdx.org/licenses/GPL-3.0-only.html",
    "gnu general public license v3.0": "https://spdx.org/licenses/GPL-3.0-only.html",
    "lgpl-3.0": "https://spdx.org/licenses/LGPL-3.0-only.html",
    "lgpl-3.0-only": "https://spdx.org/licenses/LGPL-3.0-only.html",
    "lgpl 3.0": "https://spdx.org/licenses/LGPL-3.0-only.html",
    "gnu lesser general public license v3.0": "https://spdx.org/licenses/LGPL-3.0-only.html",
}


def to_spdx_iri(license_input: Optional[str]) -> str:
    """Resolves an SPDX IRI from a license name, URL, or identifier."""
    if not license_input or not license_input.strip():
        return "https://spdx.org/licenses/Apache-2.0.html"

    clean_lic = license_input.strip()
    normalized = clean_lic.lower()
    if normalized in CANONICAL_MAP:
        return CANONICAL_MAP[normalized]

    # If it's already an SPDX URL format
    if clean_lic.startswith("https://spdx.org/licenses/") or clean_lic.startswith("http://spdx.org/licenses/"):
        return f"https://{clean_lic[7:]}" if clean_lic.startswith("http://") else clean_lic

    # If it starts with http://, https://, or urn:, return as valid URI
    if clean_lic.startswith("http://") or clean_lic.startswith("https://") or clean_lic.startswith("urn:"):
        return clean_lic

    # Default fallback: construct standard SPDX IRI
    spdx_id = re.sub(r"\s+", "-", clean_lic)
    return f"https://spdx.org/licenses/{spdx_id}.html"
