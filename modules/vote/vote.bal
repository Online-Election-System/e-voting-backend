import online_election.common;
import online_election.store;

import ballerina/http;
import ballerina/persist;

final store:Client dbVote = check new ();

public function getVoterById(string voterId) returns store:Voter|persist:Error {
    return dbVote->/voters/[voterId].get();  // Added missing slash
}

public function castVote(Vote newVote) returns http:Created|http:Forbidden|error {
    // Check if voter exists
    store:Voter|persist:Error voter = getVoterById(newVote.voterId);
    if voter is persist:Error {
        return error("Voter no");
    }

    // Check if election exists
    store:Election|persist:Error election = getElectionById(newVote.electionId);
    if election is persist:Error {
        return error("Election no");
    }

    // Check for existing vote
    stream<store:Vote, persist:Error?> existingVotes = dbVote->/votes;
    var result = existingVotes.next();

    // Handle stream result
    if result is persist:Error {
        return error("Error checking existing votes", result);
    } else if result is () {
        // No vote exists - proceed
    } else {
        // Vote exists - return forbidden
        return error("Vote Exists");
    }

    // Create new vote
    store:VoteInsert voteInsert = {
        id: common:generateId(),
        ...newVote,
        timestamp: common:generateTimestamp()
    };
    string[]|persist:Error resultInsert = dbVote->/votes.post([voteInsert]);

    return resultInsert is persist:Error
        ? error("Failed to record vote")
        : http:CREATED;
}
function getElectionById(string electionId) returns store:Election|persist:Error {
    return dbVote->/elections/[electionId].get();  // Added missing slash
}



public function getVotesByVoter(string voterId) returns store:Vote[]|error {
    stream<store:Vote, persist:Error?> votesStream = dbVote->/votes;
    store:Vote[] votes = check from store:Vote vote in votesStream
        select vote;
    return votes;
}

public function getVotesByElection(string electionId) returns store:Vote[]|error {
    stream<store:Vote, persist:Error?> votesStream = dbVote->/votes;
    store:Vote[] votes = check from store:Vote vote in votesStream
        select vote;
    return votes;
}
public function deleteVote(string voteId) returns http:NoContent|http:Forbidden|error {
    _ = check dbVote->/votes/[voteId].delete();
    return http:NO_CONTENT;
}