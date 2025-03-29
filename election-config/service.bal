import ballerina/http;

listener http:Listener ElectionConfigListener = new (8080);

// In-memory storage for demonstration purposes
map<ElectionConfig> ElectionConfigs = {};

service /electionConfig/api/v1 on ElectionConfigListener {

    resource function get elections() returns ElectionConfig[]|error {
        return ElectionConfigs.toArray();
    }

    // @http:ResourceConfig {
    //     auth: {
    //         scopes: ["admin"]
    //     }
    // }
    resource function post elections/create(@http:Header string authorization, ElectionConfig newElectionConfig)
            returns http:Created|http:Forbidden|error {
        string id = "election_" + (ElectionConfigs.length() + 1).toString();
        ElectionConfigs[id] = newElectionConfig;
        return http:CREATED;
    }

    // @http:ResourceConfig {
    //     auth: {
    //         scopes: ["admin"]
    //     }
    // }
    resource function put elections/[string electionId]/update(@http:Header string authorization, ElectionConfig updatedConfig)
            returns http:Ok|http:Forbidden|error {
        if ElectionConfigs.hasKey(electionId) {
            ElectionConfigs[electionId] = updatedConfig;
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
        if ElectionConfigs.hasKey(electionId) {
            _ = ElectionConfigs.remove(electionId);
            return http:NO_CONTENT;
        } else {
            return {body: "Election configuration not found"};
        }
    }
}

type ElectionConfig record {
    string election_name;
    string description;
    string start_date;
    string end_date;
    int no_of_candidates;
};
