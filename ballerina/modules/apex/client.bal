// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.org).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/jballerina.java;
import ballerinax/'client.config;
import ballerinax/salesforce.utils;

# Ballerina Salesforce Apex Client provides the capability to access Salesforce Apex REST API.
# This client allows you to perform operations for custom Apex REST endpoints, execute HTTP methods on these endpoints,
# and handle responses appropriately.
@display {label: "Salesforce Apex", iconPath: "icon.png"}
public isolated client class Client {
    private final http:Client salesforceClient;
    private map<string> sfLocators = {};

    # Initializes the Salesforce Apex Client. During initialization, you can pass either `http:BearerTokenConfig`
    # if you have a bearer token or `http:OAuth2RefreshTokenGrantConfig` if you have OAuth tokens.
    # Create a Salesforce account and obtain tokens following 
    # [this guide](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm).
    #
    # + config - Salesforce connector configuration
    # + return - `error` on failure of initialization or else `()`
    public isolated function init(ConnectionConfig config) returns error? {
        http:Client|http:ClientError|error httpClientResult;
        http:ClientConfiguration httpClientConfig = check config:constructHTTPClientConfig(config);
        httpClientResult = trap new (config.baseUrl, httpClientConfig);

        if httpClientResult is http:Client {
            self.salesforceClient = httpClientResult;
        } else {
            return error(INVALID_CLIENT_CONFIG);
        }
    }

    # Executes an HTTP request on a Salesforce Apex resource.
    #
    # + urlPath - URI path of the Apex resource
    # + methodType - HTTP method type (GET, POST, DELETE, PUT, PATCH)
    # + payload - Payload to be sent with the request
    # + returnType - The type of data expected to be returned after data binding
    # + return - `string|int|record{}` type if successful or else `error`
    isolated remote function apexRestExecute(string urlPath, http:Method methodType,
            record {} payload = {}, typedesc<record {}|string|int?> returnType = <>)
            returns returnType|error = @java:Method {
        'class: "io.ballerinax.salesforce.ReadOperationExecutor",
        name: "apexRestExecute"
    } external;

    private isolated function processApexExecute(typedesc<record {}|string|int?> returnType, string urlPath, http:Method methodType, record {} payload) returns record {}|string|int|error? {
        string path = utils:prepareUrl([APEX_BASE_PATH, urlPath]);
        http:Response response = new;
        match methodType {
            "GET" => {
                response = check self.salesforceClient->get(path);
            }
            "POST" => {
                response = check self.salesforceClient->post(path, payload);
            }
            "DELETE" => {
                response = check self.salesforceClient->delete(path);
            }
            "PUT" => {
                response = check self.salesforceClient->put(path, payload);
            }
            "PATCH" => {
                response = check self.salesforceClient->patch(path, payload);
            }
            _ => {
                return error("Invalid Method");
            }
        }
        if response.statusCode == 200 || response.statusCode == 201 {
            if response.getContentType() == "" {
                return;
            }
            json responsePayload = check response.getJsonPayload();
            return check responsePayload.cloneWithType(returnType);
        } else {
            json responsePayload = check response.getJsonPayload();
            return error("Error occurred while executing the apex request. ",
                httpCode = response.statusCode, details = responsePayload);
        }
    }
}
