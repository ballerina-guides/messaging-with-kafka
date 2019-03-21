// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/log;
import wso2/kafka;
import ballerinax/kubernetes;

// Constants to store admin credentials
final string ADMIN_USERNAME = "Admin";
final string ADMIN_PASSWORD = "Admin";

// Kafka producer configurations
kafka:ProducerConfig producerConfigs = {
    bootstrapServers: "localhost:9092",
    clientID: "basic-producer",
    acks: "all",
    noRetries: 3
};

kafka:SimpleProducer kafkaProducer = new(producerConfigs);

@kubernetes:Ingress {
    hostname:"ballerina.guides.io",
    name:"ballerina-guides-product-admin-portal",
    path:"/"
}
@kubernetes:Service {
    serviceType:"NodePort",
    name:"ballerina-guides-product-admin-portal"
}

@kubernetes:Deployment {
    image:"ballerina.guides.io/product_admin_portal:v1.0",
    name:"ballerina-guides-product-admin-portal",
    copyFiles:[{target:"/ballerina/runtime/bre/lib",
        source:<path_to_kafka_connector_jars>}],
    username:"<USERNAME>",
    password:"<PASSWORD>",
    push:true,
    imagePullPolicy:"Always"
}

// HTTP service endpoint
listener http:Listener httpListener = new(9090);

@http:ServiceConfig { basePath: "/product" }
service productAdminService on httpListener {

    @http:ResourceConfig { methods: ["POST"], consumes: ["application/json"], produces: ["application/json"] }
    resource function updatePrice(http:Caller caller, http:Request request) {
        http:Response response = new;
        float newPriceAmount = 0.0;
        json|error reqPayload = request.getJsonPayload();

        if (reqPayload is error) {
            response.statusCode = 400;
            response.setJsonPayload({ "Message": "Invalid payload - Not a valid JSON payload" });
            var result = caller->respond(response);
            if (result is error) {
                log:printError("Failed to send response", err = result);
            }
        } else {
            response.statusCode = 200;
            response.setJsonPayload(reqPayload);
            var result = caller->respond(response);
            if (result is error) {
                log:printError("Failed to send response", err = result);
            }
            return;
        }
    }
}
