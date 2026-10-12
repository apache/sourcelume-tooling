/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.apache.sourcelume.tooling.maven.util;

import java.util.HashMap;
import java.util.Map;

/**
 * Utility to map Maven license names, identifiers, and URLs to canonical SPDX license IRIs.
 */
public final class SpdxLicenseMapper {

    private static final Map<String, String> CANONICAL_MAP = new HashMap<>();

    static {
        // Apache Licenses
        register("https://spdx.org/licenses/Apache-2.0.html",
            "apache-2.0",
            "apache 2.0",
            "apache-2",
            "apache license, version 2.0",
            "apache license 2.0",
            "the apache software license, version 2.0",
            "the apache license, version 2.0",
            "http://www.apache.org/licenses/license-2.0.txt",
            "https://www.apache.org/licenses/license-2.0.txt",
            "http://www.apache.org/licenses/license-2.0",
            "https://www.apache.org/licenses/license-2.0",
            "http://www.apache.org/licenses/license-2.0.html",
            "https://www.apache.org/licenses/license-2.0.html"
        );

        // MIT
        register("https://spdx.org/licenses/MIT.html",
            "mit",
            "mit license",
            "the mit license",
            "http://opensource.org/licenses/mit",
            "https://opensource.org/licenses/mit"
        );

        // BSD Licenses
        register("https://spdx.org/licenses/BSD-3-Clause.html",
            "bsd-3-clause",
            "bsd 3-clause",
            "bsd-3",
            "the 3-clause bsd license",
            "revised bsd license",
            "new bsd license"
        );
        register("https://spdx.org/licenses/BSD-2-Clause.html",
            "bsd-2-clause",
            "bsd 2-clause",
            "bsd-2",
            "simplified bsd license"
        );

        // Creative Commons & Open Data
        register("https://spdx.org/licenses/CC0-1.0.html",
            "cc0",
            "cc0-1.0",
            "cc0 1.0",
            "cc0 1.0 universal",
            "public domain"
        );
        register("https://spdx.org/licenses/CC-BY-4.0.html",
            "cc-by-4.0",
            "cc by 4.0",
            "creative commons attribution 4.0",
            "creative commons attribution 4.0 international"
        );
        register("https://spdx.org/licenses/ODC-By-1.0.html",
            "odc-by",
            "odc-by-1.0",
            "open data commons attribution license"
        );
        register("https://spdx.org/licenses/ODbL-1.0.html",
            "odbl",
            "odbl-1.0",
            "open database license"
        );

        // Eclipse Public License
        register("https://spdx.org/licenses/EPL-2.0.html",
            "epl-2.0",
            "epl 2.0",
            "eclipse public license 2.0",
            "eclipse public license - v 2.0"
        );
        register("https://spdx.org/licenses/EPL-1.0.html",
            "epl-1.0",
            "epl 1.0",
            "eclipse public license 1.0",
            "eclipse public license - v 1.0"
        );

        // GNU Licenses
        register("https://spdx.org/licenses/GPL-3.0-only.html",
            "gpl-3.0",
            "gpl-3.0-only",
            "gpl 3.0",
            "gnu general public license v3.0"
        );
        register("https://spdx.org/licenses/LGPL-3.0-only.html",
            "lgpl-3.0",
            "lgpl-3.0-only",
            "lgpl 3.0",
            "gnu lesser general public license v3.0"
        );
    }

    private SpdxLicenseMapper() {
    }

    private static void register(String canonicalIri, String... aliases) {
        for (String alias : aliases) {
            CANONICAL_MAP.put(alias.trim().toLowerCase(), canonicalIri);
        }
    }

    /**
     * Resolves an SPDX IRI from a license name, URL, or identifier.
     *
     * @param licenseInput name, URL, or identifier from POM or user config
     * @return canonical SPDX IRI or the input URL if already a valid URL
     */
    public static String toSpdxIri(String licenseInput) {
        if (licenseInput == null || licenseInput.isBlank()) {
            return "https://spdx.org/licenses/Apache-2.0.html";
        }

        String normalized = licenseInput.trim().toLowerCase();
        if (CANONICAL_MAP.containsKey(normalized)) {
            return CANONICAL_MAP.get(normalized);
        }

        // If it's already an SPDX URL format
        if (licenseInput.startsWith("https://spdx.org/licenses/") || licenseInput.startsWith("http://spdx.org/licenses/")) {
            return licenseInput.startsWith("http://") ? "https://" + licenseInput.substring(7) : licenseInput;
        }

        // If it starts with http:// or https:// or urn:, return as valid URI
        if (licenseInput.startsWith("http://") || licenseInput.startsWith("https://") || licenseInput.startsWith("urn:")) {
            return licenseInput;
        }

        // Default: construct standard SPDX IRI
        String spdxId = licenseInput.trim().replaceAll("\\s+", "-");
        return "https://spdx.org/licenses/" + spdxId + ".html";
    }
}
