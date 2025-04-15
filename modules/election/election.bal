import online_election.common;
import online_election.store;

import ballerina/http;
import ballerina/persist;

final store:Client dbElection = check new ();

public function getElections() returns store:Election[]|error {
    stream<store:Election, persist:Error?> electionStream = dbElection->/elections;
    store:Election[] elections = check from store:Election election in electionStream
        select election;
    return elections;
}

public function getOneElection(string electionId) returns store:Election|error {
    store:Election|persist:Error election = dbElection->/elections/[electionId];
    if election is persist:Error {
        return error("Election not found for ID: " + electionId);
    }
    return election;
}

public function createElection(ElectionConfig newElectionConfig) returns http:Created|http:Forbidden|error {
    store:ElectionInsert electionInsert = {
        id: common:generateId(),
        ...newElectionConfig
    };
    string[]|persist:Error result = dbElection->/elections.post([electionInsert]);
    if result is persist:Error {
        return error("Election not created");
    }
    return http:CREATED;
}

public function updateElection(string electionId, store:ElectionUpdate updatedElection) returns http:Ok|http:Forbidden|error {
    store:Election|persist:Error existingElection = dbElection->/elections/[electionId];
    if existingElection is persist:Error {
        return error("Election configuration not found");
    }
    store:Election _ = check dbElection->/elections/[electionId].put(updatedElection);
    return http:OK;
}

public function deleteElection(string electionId) returns http:NoContent|http:Forbidden|error {
    store:Election _ = check dbElection->/elections/[electionId];
    _ = check dbElection->/elections/[electionId].delete();
    return http:NO_CONTENT;
}
