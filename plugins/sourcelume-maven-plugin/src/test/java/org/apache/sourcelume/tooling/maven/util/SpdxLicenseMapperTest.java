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

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class SpdxLicenseMapperTest {

    @Test
    void shouldMapStandardApacheLicenseNamesAndUrls() {
        assertThat(SpdxLicenseMapper.toSpdxIri("Apache-2.0"))
            .isEqualTo("https://spdx.org/licenses/Apache-2.0.html");
        assertThat(SpdxLicenseMapper.toSpdxIri("Apache License, Version 2.0"))
            .isEqualTo("https://spdx.org/licenses/Apache-2.0.html");
        assertThat(SpdxLicenseMapper.toSpdxIri("The Apache Software License, Version 2.0"))
            .isEqualTo("https://spdx.org/licenses/Apache-2.0.html");
        assertThat(SpdxLicenseMapper.toSpdxIri("http://www.apache.org/licenses/LICENSE-2.0.txt"))
            .isEqualTo("https://spdx.org/licenses/Apache-2.0.html");
        assertThat(SpdxLicenseMapper.toSpdxIri("https://www.apache.org/licenses/LICENSE-2.0.txt"))
            .isEqualTo("https://spdx.org/licenses/Apache-2.0.html");
    }

    @Test
    void shouldMapMitAndBsdLicenses() {
        assertThat(SpdxLicenseMapper.toSpdxIri("MIT"))
            .isEqualTo("https://spdx.org/licenses/MIT.html");
        assertThat(SpdxLicenseMapper.toSpdxIri("The MIT License"))
            .isEqualTo("https://spdx.org/licenses/MIT.html");
        assertThat(SpdxLicenseMapper.toSpdxIri("BSD-3-Clause"))
            .isEqualTo("https://spdx.org/licenses/BSD-3-Clause.html");
        assertThat(SpdxLicenseMapper.toSpdxIri("BSD-2-Clause"))
            .isEqualTo("https://spdx.org/licenses/BSD-2-Clause.html");
    }

    @Test
    void shouldMapCreativeCommonsAndOpenDataLicenses() {
        assertThat(SpdxLicenseMapper.toSpdxIri("CC0-1.0"))
            .isEqualTo("https://spdx.org/licenses/CC0-1.0.html");
        assertThat(SpdxLicenseMapper.toSpdxIri("CC-BY-4.0"))
            .isEqualTo("https://spdx.org/licenses/CC-BY-4.0.html");
        assertThat(SpdxLicenseMapper.toSpdxIri("ODC-By"))
            .isEqualTo("https://spdx.org/licenses/ODC-By-1.0.html");
    }

    @Test
    void shouldHandleDirectUrlsAndUris() {
        assertThat(SpdxLicenseMapper.toSpdxIri("https://example.org/custom-license"))
            .isEqualTo("https://example.org/custom-license");
        assertThat(SpdxLicenseMapper.toSpdxIri("urn:isbn:0451450523"))
            .isEqualTo("urn:isbn:0451450523");
    }

    @Test
    void shouldFallbackGracefullyForNullOrBlank() {
        assertThat(SpdxLicenseMapper.toSpdxIri(null))
            .isEqualTo("https://spdx.org/licenses/Apache-2.0.html");
        assertThat(SpdxLicenseMapper.toSpdxIri(""))
            .isEqualTo("https://spdx.org/licenses/Apache-2.0.html");
    }
}
