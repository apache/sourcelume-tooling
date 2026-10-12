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

/**
 * Encapsulates an HTTP response from the Sourcelume Registry.
 */
public class SourcelumeResponse {

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

    @Override
    public String toString() {
        return "SourcelumeResponse{" +
            "statusCode=" + statusCode +
            ", body='" + body + '\'' +
            ", errorMessage='" + errorMessage + '\'' +
            '}';
    }
}
