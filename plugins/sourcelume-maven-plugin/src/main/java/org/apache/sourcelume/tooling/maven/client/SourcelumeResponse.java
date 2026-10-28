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

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.ArrayList;
import java.util.List;

/**
 * Encapsulates an HTTP response from the Sourcelume Registry.
 */
public class SourcelumeResponse {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final int statusCode;
    private final String body;
    private final String errorMessage;

    public SourcelumeResponse(int statusCode, String body, String errorMessage) {
        this.statusCode = statusCode;
        this.body = body != null ? body : "";
        this.errorMessage = errorMessage;
    }

    public static SourcelumeResponse success(int statusCode, String body) {
        return new SourcelumeResponse(statusCode, body, null);
    }

    public static SourcelumeResponse error(int statusCode, String body, String errorMessage) {
        return new SourcelumeResponse(statusCode, body, errorMessage);
    }

    public int getStatusCode() {
        return statusCode;
    }

    public String getBody() {
        return body;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public boolean isSuccess() {
        return statusCode >= 200 && statusCode < 300;
    }

    public boolean isConflict() {
        return statusCode == 409;
    }

    public boolean isValidationError() {
        return statusCode == 422;
    }

    /** The {@code recordStatus} the registry answered with, or {@code null} if the body has none. */
    public String getRecordStatus() {
        return textField("recordStatus");
    }

    /** The registry stores an invalid record as INCOMPLETE and still answers 2xx. */
    public boolean isIncomplete() {
        return "INCOMPLETE".equals(getRecordStatus());
    }

    /** The {@code reason} of a 409 answer, or {@code null} if the body has none. */
    public String getReason() {
        return textField("reason");
    }

    /**
     * The validation issues as {@code path: message} lines. The registry sends
     * {@code validationIssues} as a JSON array inside a string.
     */
    public List<String> getValidationIssues() {
        String issues = textField("validationIssues");
        List<String> lines = new ArrayList<>();
        if (issues == null) {
            return lines;
        }
        JsonNode array = parse(issues);
        if (array == null || !array.isArray()) {
            lines.add(issues);
            return lines;
        }
        for (JsonNode issue : array) {
            String path = issue.path("path").asText("");
            String message = issue.path("message").asText(issue.toString());
            lines.add(path.isEmpty() ? message : path + ": " + message);
        }
        return lines;
    }

    private String textField(String name) {
        JsonNode root = parse(body);
        if (root == null || !root.isObject()) {
            return null;
        }
        JsonNode field = root.get(name);
        return field != null && field.isTextual() ? field.asText() : null;
    }

    private static JsonNode parse(String text) {
        try {
            return MAPPER.readTree(text);
        } catch (Exception e) {
            return null;
        }
    }

    @Override
    public String toString() {
        return "SourcelumeResponse{" +
            "statusCode=" + statusCode +
            ", body='" + body + '\'' +
            ", errorMessage='" + errorMessage + '\'' +
            '}';
    }
}
