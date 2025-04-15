import online_election.auth;
import online_election.election;
import online_election.store;

import ballerina/http;

listener http:Listener SharedListener = new (8080);

service /voter\-registration/api/v1 on SharedListener {
    // Register a new voter
    resource function post voters/register(store:Voter newVoter)
    returns http:Created|http:Forbidden|error {
        return check auth:registerVoter(newVoter);
    }

    // Voter Login
    resource function post voters/login(auth:VoterLogin loginDetails)
    returns http:Response|http:Unauthorized|error {
        return check auth:loginVoter(loginDetails);
    }
}

service /election/api/v1 on SharedListener {
    resource function get elections() returns store:Election[]|error {
        return check election:getElections();
    }

    resource function get elections/[string electionId]() returns store:Election|error {
        return check election:getOneElection(electionId);
    }

    // @http:ResourceConfig {
    //     auth: {
    //         scopes: ["admin"]
    //     }
    // }
    resource function post elections/create(@http:Header string authorization, election:ElectionConfig newElectionConfig)
    returns http:Created|http:Forbidden|error {
        return check election:createElection(newElectionConfig);
    }

    // @http:ResourceConfig {
    //     auth: {
    //         scopes: ["admin"]
    //     }
    // }
    resource function put elections/[string electionId]/update(@http:Header string authorization, store:ElectionUpdate updatedElection)
    returns http:Ok|http:Forbidden|error {
        return check election:updateElection(electionId, updatedElection);
    }

    // @http:ResourceConfig {
    //     auth: {
    //         scopes: ["admin"]
    //     }
    // }
    resource function delete elections/[string electionId]/delete(@http:Header string authorization)
    returns http:NoContent|http:Forbidden|error {
        return check election:deleteElection(electionId);
    }
}
