import online_election.auth;
import online_election.candidate;
import online_election.election;
import online_election.store;

import ballerina/http;
import ballerina/persist;

listener http:Listener SharedListener = new (8080);

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"]
    }
}
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

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type", "Authorization"],
        allowCredentials: true
    }
}
service /election/api/v1 on SharedListener {
    resource function get elections() returns store:Election[]|error {
        return check election:getElections();
    }

    resource function get elections/[string electionId]() returns store:Election|error {
        return check election:getElectionById(electionId);
    }

    resource function post elections/create(@http:Header string authorization, election:ElectionConfig newElectionConfig)
    returns error|http:Response {
        return check election:createElection(newElectionConfig);
    }

    resource function put elections/[string electionId]/update(@http:Header string authorization, store:ElectionUpdate updatedElection)
    returns error|http:Response {
        return check election:updateElection(electionId, updatedElection);
    }

    resource function delete elections/[string electionId]/delete(@http:Header string authorization)
    returns http:NoContent|http:Forbidden|error {
        return check election:deleteElection(electionId);
    }
}

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type", "Authorization"],
        allowCredentials: true
    }
}
service /candidate/api/v1 on SharedListener {

    // Get candidates by election ID from database
    resource function get elections/[string electionId]/candidates() returns store:Candidate[]|error {
        return check candidate:getCandidatesByElection(electionId);
    }

    // Get all active candidates from database
    resource function get candidates() returns store:Candidate[]|error {
        return check candidate:getAllActiveCandidates();
    }

    // Get candidate by ID from database
    resource function get candidates/[string candidateId]() returns store:Candidate|http:NotFound|error {
        store:Candidate|persist:Error candidate = check candidate:getCandidateById(candidateId);

        if candidate is persist:Error {
            return http:NOT_FOUND;
        }

        return candidate;
    }

    // Get candidates by election and party
    resource function get elections/[string electionId]/candidates/party/[string partyName]() returns store:Candidate[]|error {
        return check candidate:getCandidatesByElectionAndParty(electionId, partyName);
    }

    // Check if candidate is active
    resource function get candidates/[string candidateId]/active() returns boolean|error {
        return check candidate:isCandidateActive(candidateId);
    }
}
