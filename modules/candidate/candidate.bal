import online_election.common;
import online_election.store;

import ballerina/http;
import ballerina/persist;


final store:Client dbCandidate = check new ();

// Create a new candidate
public function createCandidate(store:Candidate newCandidate) returns http:Created|http:Forbidden|error {
    store:CandidateInsert candidateInsert = {
        candidateId: common:generateId(),
        electionId: newCandidate.electionId,
        candidateName: newCandidate.candidateName,
        partyName: newCandidate.partyName,
        partySymbol: newCandidate.partySymbol,
        partyColor: newCandidate.partyColor,
        candidateImage: newCandidate.candidateImage,
        popularVotes: newCandidate.popularVotes,
        electoralVotes: newCandidate.electoralVotes,
        position: newCandidate.position,
        isActive: newCandidate.isActive
    };
    
    string[]|persist:Error result = dbCandidate->/candidates.post([candidateInsert]);
    if result is persist:Error {
        return error("Candidate not created");
    }
    return http:CREATED;
}

// Get all candidates
public function getCandidates() returns store:Candidate[]|error {
    stream<store:Candidate, persist:Error?> candidateStream = dbCandidate->/candidates;
    store:Candidate[] candidates = check from store:Candidate candidate in candidateStream
        select candidate;
    return candidates;
}

// Get candidate by ID
public function getCandidateById(string candidateId) returns store:Candidate|error {
    store:Candidate|persist:Error candidate = dbCandidate->/candidates/[candidateId].get();
    if candidate is persist:Error {
        return error("Candidate not found for ID: " + candidateId);
    }
    return candidate;
    
}

// Get candidates by election ID
public function getCandidatesByElection(string electionId) returns store:Candidate[]|error {
    stream<store:Candidate, persist:Error?> candidateStream = dbCandidate->/candidates;
    store:Candidate[] candidates = check from store:Candidate candidate in candidateStream
        where candidate.electionId == electionId
        select candidate;
    return candidates;
}

// Get active candidates for an election
public function getActiveCandidatesByElection(string electionId) returns store:Candidate[]|error {
    stream<store:Candidate, persist:Error?> candidateStream = dbCandidate->/candidates;
    store:Candidate[] candidates = check from store:Candidate candidate in candidateStream
        where candidate.electionId == electionId && candidate.isActive == true
        select candidate;
    return candidates;
}

// Get candidates by party
public function getCandidatesByParty(string partyName) returns store:Candidate[]|error {
    stream<store:Candidate, persist:Error?> candidateStream = dbCandidate->/candidates;
    store:Candidate[] candidates = check from store:Candidate candidate in candidateStream
        where candidate.partyName == partyName
        select candidate;
    return candidates;
}

// Update candidate information
public function updateCandidate(string candidateId, store:CandidateUpdate updatedCandidate) returns http:Ok|http:Forbidden|error {
    store:Candidate|persist:Error existingCandidate = dbCandidate->/candidates/[candidateId].get();
    if existingCandidate is persist:Error {
        return error("Candidate not found");
    }
    
    store:Candidate _ = check dbCandidate->/candidates/[candidateId].put(updatedCandidate);
    return http:OK;
}

// Update candidate vote counts
public function updateCandidateVotes(string candidateId, int? popularVotes, int? electoralVotes) returns http:Ok|http:Forbidden|error {
    store:Candidate|persist:Error existingCandidate = dbCandidate->/candidates/[candidateId].get();
    if existingCandidate is persist:Error {
        return error("Candidate not found");
    }
    
    store:CandidateUpdate voteUpdate = {
        popularVotes: popularVotes,
        electoralVotes: electoralVotes
    };
    
    _ = check dbCandidate->/candidates/[candidateId].put(voteUpdate);
    return http:OK;
}

// Update candidate position/ranking
public function updateCandidatePosition(string candidateId, int position) returns http:Ok|http:Forbidden|error {
    store:Candidate|persist:Error existingCandidate = dbCandidate->/candidates/[candidateId].get();
    if existingCandidate is persist:Error {
        return error("Candidate not found");
    }
    
    store:CandidateUpdate positionUpdate = {
        position: position
    };
    
    _ = check dbCandidate->/candidates/[candidateId].put(positionUpdate);
    return http:OK;
}

// Activate/Deactivate candidate
public function toggleCandidateStatus(string candidateId, boolean isActive) returns http:Ok|http:Forbidden|error {
    store:Candidate|persist:Error existingCandidate = dbCandidate->/candidates/[candidateId].get();
    if existingCandidate is persist:Error {
        return error("Candidate not found");
    }
    
    store:CandidateUpdate statusUpdate = {
        isActive: isActive
    };
    
    _ = check dbCandidate->/candidates/[candidateId].put(statusUpdate);
    return http:OK;
}

// Delete candidate
public function deleteCandidate(string candidateId) returns http:NoContent|http:Forbidden|error {
    store:Candidate _ = check dbCandidate->/candidates/[candidateId].get();
    _ = check dbCandidate->/candidates/[candidateId].delete();
    return http:NO_CONTENT;
}

// Get candidates ranked by popular votes for an election
public function getCandidatesByPopularVotes(string electionId) returns store:Candidate[]|error {
    stream<store:Candidate, persist:Error?> candidateStream = dbCandidate->/candidates;
    store:Candidate[] candidates = check from store:Candidate candidate in candidateStream
        where candidate.electionId == electionId && candidate.isActive == true
        order by candidate.popularVotes descending
        select candidate;
    return candidates;
}

// Get candidates ranked by electoral votes for an election
public function getCandidatesByElectoralVotes(string electionId) returns store:Candidate[]|error {
    stream<store:Candidate, persist:Error?> candidateStream = dbCandidate->/candidates;
    store:Candidate[] candidates = check from store:Candidate candidate in candidateStream
        where candidate.electionId == electionId && candidate.isActive == true
        order by candidate.electoralVotes descending
        select candidate;
    return candidates;
}

// Get winning candidate for an election (highest popular votes)
public function getWinningCandidate(string electionId) returns store:Candidate|error {
    store:Candidate[] candidates = check getCandidatesByPopularVotes(electionId);
    
    if candidates.length() == 0 {
        return error("No candidates found for election");
    }
    
    return candidates[0]; // First candidate has highest votes due to ordering
}

// Calculate and update all candidate positions for an election based on popular votes
public function updateCandidateRankings(string electionId) returns http:Ok|error {
    store:Candidate[] candidates = check getCandidatesByPopularVotes(electionId);
    
    int position = 1;
    foreach store:Candidate candidate in candidates {
        _ = check updateCandidatePosition(candidate.candidateId, position);
        position += 1;
    }
    
    return http:OK;
}

// Get election results summary
public function getElectionResults(string electionId) returns json|error {
    store:Candidate[] candidates = check getCandidatesByPopularVotes(electionId);
    
    json[] results = [];
    foreach store:Candidate candidate in candidates {
        json candidateResult = {
            "candidateId": candidate.candidateId,
            "candidateName": candidate.candidateName,
            "partyName": candidate.partyName,
            "popularVotes": candidate.popularVotes,
            "electoralVotes": candidate.electoralVotes,
            "position": candidate.position,
            "partyColor": candidate.partyColor,
            "partySymbol": candidate.partySymbol
        };
        results.push(candidateResult);
    }
    
    json summary = {
        "electionId": electionId,
        "totalCandidates": candidates.length(),
        "results": results
    };
    
    if candidates.length() > 0 {
        json winner = {
            "candidateId": candidates[0].candidateId,
            "candidateName": candidates[0].candidateName,
            "partyName": candidates[0].partyName,
            "popularVotes": candidates[0].popularVotes
        };
        summary = check summary.mergeJson({"winner": winner});
    }
    
    return summary;
}
