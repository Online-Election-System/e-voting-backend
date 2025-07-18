import online_election.common;
import online_election.store;

import ballerina/http;
import ballerina/persist;
import ballerina/crypto;

final store:Client dbVote = check new ();

// Add authentication function
public function authenticateVoter(string nationalId, string password) returns store:Voter|http:Unauthorized|error {
    // Get voter by national ID
    stream<store:Voter, persist:Error?> votersStream = dbVote->/voters;
    store:Voter[] voters = check from store:Voter voter in votersStream
        where voter.nationalId == nationalId
        select voter;
    
    if voters.length() == 0 {
        return http:UNAUTHORIZED; // Voter not found
    }
    
    store:Voter voter = voters[0];
    
    // Hash the input password using MD5 (same as registration)
    string hashedInputPassword = crypto:hashMd5(password.toBytes()).toBase16();
    // Check password
    if voter.password != hashedInputPassword {
        return http:UNAUTHORIZED; // Wrong password
    }
    
    return voter; // Authentication successful
}

public function getVoterById(string voterId) returns store:Voter|persist:Error {
    return dbVote->/voters/[voterId].get();
}

public function getVoterByNationalId(string nationalId) returns store:Voter|persist:Error? {
    stream<store:Voter, persist:Error?> votersStream = dbVote->/voters;
    store:Voter[] voters = check from store:Voter voter in votersStream
        where voter.nationalId == nationalId
        select voter;
    
    if voters.length() == 0 {
        return (); // Voter not found
    }
    
    return voters[0];
}

public function castVote(Vote newVote) returns http:Created|http:Forbidden|error {
    // Check if voter exists and get voter details
    store:Voter|persist:Error voter = getVoterById(newVote.voterId);
    if voter is persist:Error {
        return error("Voter not found");
    }

    // Check if election exists
    store:Election|persist:Error election = getElectionById(newVote.electionId);
    if election is persist:Error {
        return error("Election not found");
    }

    // Check for existing vote by this voter for this election
    stream<store:Vote, persist:Error?> existingVotes = dbVote->/votes;
    store:Vote[] votes = check from store:Vote vote in existingVotes
        where vote.voterId == newVote.voterId && vote.electionId == newVote.electionId
        select vote;
    
    if votes.length() > 0 {
        return error("Vote already exists for this voter in this election");
    }

    // Create new vote with district from voter record
    store:VoteInsert voteInsert = {
        id: common:generateId(),
        voterId: newVote.voterId,
        electionId: newVote.electionId,
        candidateId: newVote.candidateId,
        district: voter.district, // Store district from voter table
        timestamp: common:generateTimestamp()
    };
    
    string[]|persist:Error resultInsert = dbVote->/votes.post([voteInsert]);

    return resultInsert is persist:Error
        ? error("Failed to record vote")
        : http:CREATED;
}

function getElectionById(string electionId) returns store:Election|persist:Error {
    return dbVote->/elections/[electionId].get();
}

public function getVotesByVoter(string voterId) returns store:Vote[]|error {
    stream<store:Vote, persist:Error?> votesStream = dbVote->/votes;
    store:Vote[] votes = check from store:Vote vote in votesStream
        where vote.voterId == voterId
        select vote;
    return votes;
}

public function getVotesByElection(string electionId) returns store:Vote[]|error {
    stream<store:Vote, persist:Error?> votesStream = dbVote->/votes;
    store:Vote[] votes = check from store:Vote vote in votesStream
        where vote.electionId == electionId
        select vote;
    return votes;
}

public function getVotesByElectionAndDistrict(string electionId, string district) returns store:Vote[]|error {
    stream<store:Vote, persist:Error?> votesStream = dbVote->/votes;
    store:Vote[] votes = check from store:Vote vote in votesStream
        where vote.electionId == electionId && vote.district == district
        select vote;
    return votes;
}

public function deleteVote(string voteId) returns http:NoContent|http:Forbidden|error {
    _ = check dbVote->/votes/[voteId].delete();
    return http:NO_CONTENT;
}
