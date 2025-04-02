import election_config.elections;

import ballerina/http;
import ballerina/persist;

listener http:Listener ElectionConfigListener = new (8080);
elections:Client dbElection = check new ();

service /electionConfig/api/v1 on ElectionConfigListener {

    resource function get elections() returns elections:Election[]|error {
        stream<elections:Election, persist:Error?> electionStream = dbElection->/elections;
        elections:Election[] elections = check from elections:Election election in electionStream
            select election;

        return elections;
    }

    resource function get elections/[string electionId]() returns elections:Election|error {

        elections:Election|persist:Error election = check dbElection->/elections/[electionId];
        return election;

    }

    // @http:ResourceConfig {
    //     auth: {
    //         scopes: ["admin"]
    //     }
    // }
    resource function post elections/create(@http:Header string authorization, ElectionConfig newElectionConfig)
        returns http:Created|http:Forbidden|error {

        elections:ElectionInsert electionInsert = {
            id: generateId(),
            ...newElectionConfig
        };

        string[]|persist:Error result = dbElection->/elections.post([electionInsert]);

        return http:CREATED;
    }

    // @http:ResourceConfig {
    //     auth: {
    //         scopes: ["admin"]
    //     }
    // }
    resource function put elections/[string electionId]/update(@http:Header string authorization, elections:ElectionUpdate updatedElection)
        returns http:Ok|http:Forbidden|error {

        elections:Election|persist:Error existingElection = dbElection->/elections/[electionId];

        if existingElection is elections:Election {
            elections:Election updated = check dbElection->/elections/[electionId].put(updatedElection);
            return http:OK;
        } else {
            return error("Election configuration not found");
        }
    }

    // @http:ResourceConfig {
    //     auth: {
    //         scopes: ["admin"]
    //     }
    // }
    resource function delete elections/[string electionId]/delete(@http:Header string authorization)
            returns http:NoContent|http:Forbidden|error {
        // string userId = check getUserId(authorization);
        elections:Election election = check dbElection->/elections/[electionId];
        _ = check dbElection->/elections/[electionId].delete();
        return http:NO_CONTENT;
    }
}
