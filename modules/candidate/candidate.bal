import online_election.store;
import ballerina/persist;

// Use the same database client as vote.bal
final store:Client dbCandidate = check new ();

// Get all candidates for a specific election
public function getCandidatesByElection(string electionId) returns store:Candidate[]|error {
    stream<store:Candidate, persist:Error?> candidatesStream = dbCandidate->/candidates;
    store:Candidate[] candidates = check from store:Candidate candidate in candidatesStream
        where candidate.electionId == electionId && candidate.isActive == true
        select candidate;
    return candidates;
}

// Get all active candidates
public function getAllActiveCandidates() returns store:Candidate[]|error {
    stream<store:Candidate, persist:Error?> candidatesStream = dbCandidate->/candidates;
    store:Candidate[] candidates = check from store:Candidate candidate in candidatesStream
        where candidate.isActive == true
        select candidate;
    return candidates;
}

// Get candidate by composite key (candidateId and electionId)
public function getCandidateByCompositeKey(string candidateId, string electionId) returns store:Candidate|persist:Error {
    stream<store:Candidate, persist:Error?> candidatesStream = dbCandidate->/candidates;
    store:Candidate[] candidates = check from store:Candidate candidate in candidatesStream
        where candidate.candidateId == candidateId && candidate.electionId == electionId
        select candidate;
    
    if candidates.length() == 0 {
        return error persist:Error("Candidate not found");
    }
    
    return candidates[0];
}

// Get candidate by ID from any election (returns first match)
public function getCandidateById(string candidateId) returns store:Candidate|persist:Error {
    stream<store:Candidate, persist:Error?> candidatesStream = dbCandidate->/candidates;
    store:Candidate[] candidates = check from store:Candidate candidate in candidatesStream
        where candidate.candidateId == candidateId
        select candidate;
    
    if candidates.length() == 0 {
        return error persist:Error("Candidate not found");
    }
    
    return candidates[0];
}

// Get candidates by party name for an election
public function getCandidatesByElectionAndParty(string electionId, string partyName) returns store:Candidate[]|error {
    stream<store:Candidate, persist:Error?> candidatesStream = dbCandidate->/candidates;
    store:Candidate[] candidates = check from store:Candidate candidate in candidatesStream
        where candidate.electionId == electionId && candidate.partyName == partyName && candidate.isActive == true
        select candidate;
    return candidates;
}

// Check if candidate exists and is active
public function isCandidateActive(string candidateId) returns boolean|error {
    stream<store:Candidate, persist:Error?> candidatesStream = dbCandidate->/candidates;
    store:Candidate[] candidates = check from store:Candidate candidate in candidatesStream
        where candidate.candidateId == candidateId && candidate.isActive == true
        select candidate;
    
    return candidates.length() > 0;
}

// Get candidates by multiple criteria
public function getCandidatesByElectionAndStatus(string electionId, boolean isActive) returns store:Candidate[]|error {
    stream<store:Candidate, persist:Error?> candidatesStream = dbCandidate->/candidates;
    store:Candidate[] candidates = check from store:Candidate candidate in candidatesStream
        where candidate.electionId == electionId && candidate.isActive == isActive
        select candidate;
    return candidates;
}