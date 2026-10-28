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
package org.apache.sourcelume.tooling.maven.client;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class SourcelumeResponseTest {

    @Test
    void testIncompleteAnswerListsItsIssues() {
        SourcelumeResponse response = SourcelumeResponse.success(201,
            "{\"recordStatus\":\"INCOMPLETE\",\"validationIssues\":"
                + "\"[{\\\"path\\\":\\\"/\\\",\\\"message\\\":\\\"required property 'license' not found\\\"}]\"}");

        assertThat(response.isSuccess()).isTrue();
        assertThat(response.isIncomplete()).isTrue();
        assertThat(response.getValidationIssues()).containsExactly("/: required property 'license' not found");
    }

    @Test
    void testValidatedAnswerIsNotIncomplete() {
        SourcelumeResponse response = SourcelumeResponse.success(201, "{\"recordStatus\":\"VALIDATED\"}");

        assertThat(response.getRecordStatus()).isEqualTo("VALIDATED");
        assertThat(response.isIncomplete()).isFalse();
        assertThat(response.getValidationIssues()).isEmpty();
    }

    @Test
    void testBodyWithoutJsonHasNoStatusOrReason() {
        SourcelumeResponse response = SourcelumeResponse.success(201, "created");

        assertThat(response.getRecordStatus()).isNull();
        assertThat(response.isIncomplete()).isFalse();
        assertThat(response.getReason()).isNull();
    }

    @Test
    void testConflictReason() {
        SourcelumeResponse response = SourcelumeResponse.error(409,
            "{\"recordStatus\":\"VALIDATED\",\"reason\":\"The id belongs to a VALIDATED record\"}", null);

        assertThat(response.getReason()).isEqualTo("The id belongs to a VALIDATED record");
    }
}
