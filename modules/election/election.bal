import online_election.common;
import online_election.store;

import ballerina/http;
import ballerina/persist;
import ballerina/time;
import ballerina/sql;

final store:Client dbElection = check new ();

public function getElections() returns store:Election[]|error {
    stream<store:Election, persist:Error?> electionStream = dbElection->/elections;
    store:Election[] elections = check from store:Election election in electionStream
        select election;
    return elections;
}

public function getElectionCount() returns int|error {
    store:Election[] elections = check getElections();
    return elections.length();
}

public function getElectionById(string electionId) returns store:Election|error {
    store:Election|persist:Error election = dbElection->/elections/[electionId];
    if election is persist:Error {
        return error("Election not found for ID: " + electionId);
    }
    return election;
}

public function getUpcomingElections() returns store:Election[]|error {
    time:Utc today = time:utcNow();
    

    sql:ParameterizedQuery query = `SELECT 
        id,
        election_name as "electionName",
        description,
        start_date as "startDate",
        enrol_ddl as "enrolDdl",
        election_date as "electionDate",
        end_date as "endDate",
        no_of_candidates as "noOfCandidates",
        election_type as "electionType",
        start_time as "startTime",
        end_time as "endTime",
        status
    FROM "Election" WHERE "start_date" > ${today}`;
    
    stream<store:Election, persist:Error?> resultStream = dbElection->queryNativeSQL(query);
    
    store:Election[] upcomingElections = check from store:Election election in resultStream
        select election;
    
    return upcomingElections;
}

public function createElection(ElectionConfig newElectionConfig) returns error|http:Response {
    store:ElectionInsert electionInsert = {
        id: common:generateId(),
        ...newElectionConfig
    };
    string[]|persist:Error result = dbElection->/elections.post([electionInsert]);
    if result is persist:Error {
        return error("Election not created");
    }
    store:Election createdElection = {
        id: electionInsert.id,
        ...newElectionConfig
    };
    
    http:Response res = new;
    res.setPayload(createdElection);
    return res;
}

public function updateElection(string electionId, store:ElectionUpdate updatedElection) returns error|http:Response {
    store:Election|persist:Error existingElection = dbElection->/elections/[electionId];
    if existingElection is persist:Error {
        return error("Election configuration not found");
    }
    store:Election|persist:Error result = check dbElection->/elections/[electionId].put(updatedElection);
    if result is persist:Error {
        return error("Election not created");
    }
    
    http:Response res = new;
    res.setPayload(updatedElection);
    return res;
}

public function deleteElection(string electionId) returns http:NoContent|http:Forbidden|error {
    store:Election _ = check dbElection->/elections/[electionId];
    _ = check dbElection->/elections/[electionId].delete();
    return http:NO_CONTENT;
}
