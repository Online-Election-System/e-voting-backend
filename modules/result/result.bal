// result.bal - Election results processing, analytics, and reporting functions
import ballerina/time;
import online_election.store;
import ballerina/sql;

// Result processing and analytics functions using your database schema
// Response types for API endpoints
public type ElectionSummaryResponse record {|
    string electionId;
    string electionName;
    int totalVotes;
    string lastUpdated;
    store:Candidate[] candidates;
    store:DistrictResult[] districts;
    store:ElectionSummary statistics;
    ProvinceAnalysis[]? provinces?;
    PartySummary[]? partySummaries?;
|};

public type ProvinceAnalysis record {|
    string provinceName;
    int totalVotes;
    int registeredVoters;
    decimal turnoutPercentage;
    string winningCandidateId;
    store:DistrictResult[] districts;
|};

public type PartySummary record {|
    string partyName;
    string partyColor;
    store:Candidate[] candidates;
    int totalElectoralVotes;
    int totalPopularVotes;
    decimal popularVotePercentage;
    int districtsWon;
|};

public type CandidateMetrics record {|
    string candidateId;
    string candidateName;
    int totalVotes;
    decimal voteShare;
    int districtsWon;
    int position;
    string strongestDistrict;
    string weakestDistrict;
|};

public type VictoryMargin record {|
    string marginType;
    decimal margin;
    int votes;
|};

// Module-level type definition
public type LiveElectionStatus record {
    string electionId;
    string electionName;
    string status;
    int totalVotesCast;
    int totalRegisteredVoters;
    decimal turnoutPercentage;
    string electionStatus;
    string lastUpdated;
};





// Data access functions implemented with the persistence client

// Get election by ID
# Gets an election by its ID
#
# + dbClient - The database client
# + electionId - The election ID to retrieve
# + return - The election record or an error
public function getElectionById(store:Client dbClient, string electionId) returns store:Election|error {
    return dbClient->/elections/[electionId].get();
}

// Get all candidates for an election
# Gets all active candidates for a specific election, ordered by popular votes
#
# + dbClient - The database client
# + electionId - The election ID to get candidates for
# + return - Array of candidate records or an error
public function getCandidatesByElection(store:Client dbClient, string electionId) returns store:Candidate[]|error {
    sql:ParameterizedQuery whereClause = `election_id = ${electionId} AND is_active = true`;
    sql:ParameterizedQuery orderByClause = `popular_votes DESC`;
    
    stream<store:Candidate, error?> candidateStream = dbClient->/candidates.get(
        whereClause = whereClause,
        orderByClause = orderByClause
    );
    
    store:Candidate[] candidates = [];
    check from store:Candidate candidate in candidateStream
        do {
            candidates.push(candidate);
        };
    
    return candidates;
}


// Get all district results for an election
# Gets all district results for a specific election
#
# + dbClient - The database client
# + electionId - The election ID to get district results for
# + return - Array of district result records or an error
public function getDistrictResultsByElection(store:Client dbClient, string electionId) returns store:DistrictResult[]|error {
    sql:ParameterizedQuery whereClause = `election_id = ${electionId}`;
    
    stream<store:DistrictResult, error?> districtStream = dbClient->/districtresults.get(
        whereClause = whereClause
    );
    
    store:DistrictResult[] districts = [];
    check from store:DistrictResult district in districtStream
        do {
            districts.push(district);
        };
    
    return districts;
}


// Get election summary
# Gets the election summary for a specific election
#
# + dbClient - The database client
# + electionId - The election ID to get summary for
# + return - The election summary record or an error
public function getElectionSummaryById(store:Client dbClient, string electionId) returns store:ElectionSummary|error {
    return dbClient->/electionsummaries/[electionId].get();
}

// Get candidate by ID
# Gets a candidate by their ID
#
# + dbClient - The database client
# + candidateId - The candidate ID to retrieve
# + return - The candidate record or an error
public function getCandidateById(store:Client dbClient, string candidateId) returns store:Candidate|error {
    return dbClient->/candidates/[candidateId].get();
}

// Update candidate votes
# Updates the popular votes for a candidate by adding additional votes
#
# + dbClient - The database client
# + candidateId - The candidate ID to update
# + additionalVotes - The number of additional votes to add
# + return - An error if the operation fails
public function updateCandidateVotes(store:Client dbClient, string candidateId, int additionalVotes) returns error? {
    // First get the current candidate to get existing vote count
    store:Candidate currentCandidate = check dbClient->/candidates/[candidateId].get();
    
    // Calculate new vote total
    int newVoteTotal = (currentCandidate.popularVotes ?: 0) + additionalVotes;
    
    // Update the candidate with new vote count
    store:CandidateUpdate updateData = {
        popularVotes: newVoteTotal
    };
    
    _ = check dbClient->/candidates/[candidateId].put(updateData);
}

// Additional utility functions for election result processing

// Get complete election results with analytics
# Gets comprehensive election results including candidates, districts, and analytics
#
# + dbClient - The database client
# + electionId - The election ID to get results for
# + return - Complete election summary response or an error
public function getCompleteElectionResults(store:Client dbClient, string electionId) returns ElectionSummaryResponse|error {
    // Get basic election info
    store:Election election = check getElectionById(dbClient, electionId);
    
    // Get all related data
    store:Candidate[] candidates = check getCandidatesByElection(dbClient, electionId);
    store:DistrictResult[] districts = check getDistrictResultsByElection(dbClient, electionId);
    store:ElectionSummary statistics = check getElectionSummaryById(dbClient, electionId);
    
    // Calculate total votes from candidates
    int totalVotes = candidates.reduce(function(int acc, store:Candidate candidate) returns int {
        return acc + (candidate.popularVotes ?: 0);
    }, 0);
    
    // Generate party summaries
    PartySummary[] partySummaries = check generatePartySummaries(candidates, districts);
    
    return {
        electionId: election.id,
        electionName: election.electionName,
        totalVotes: totalVotes,
        lastUpdated: time:utcToString(time:utcNow()),
        candidates: candidates,
        districts: districts,
        statistics: statistics,
        partySummaries: partySummaries
    };
}

// Generate party-wise summary
# Generates summary statistics grouped by political party
#
# + candidates - Array of candidates
# + districts - Array of district results
# + return - Array of party summaries or an error
public function generatePartySummaries(store:Candidate[] candidates, store:DistrictResult[] districts) returns PartySummary[]|error {
    map<PartySummary> partyMap = {};
    
    // Group candidates by party
    foreach store:Candidate candidate in candidates {
        string partyName = candidate.partyName;
        
        if !partyMap.hasKey(partyName) {
            partyMap[partyName] = {
                partyName: partyName,
                partyColor: candidate.partyColor,
                candidates: [],
                totalElectoralVotes: 0,
                totalPopularVotes: 0,
                popularVotePercentage: 0.0,
                districtsWon: 0
            };
        }
        
        PartySummary partySummary = partyMap.get(partyName);
        partySummary.candidates.push(candidate);
        partySummary.totalPopularVotes += (candidate.popularVotes ?: 0);
        partySummary.totalElectoralVotes += (candidate.electoralVotes ?: 0);
        
        partyMap[partyName] = partySummary;
    }
    
    // Count districts won by each party
    foreach store:DistrictResult district in districts {
        string? winner = district.winner;
        if winner != () {
            // Find the party of the winning candidate
            store:Candidate[] matchingCandidates = candidates.filter(function(store:Candidate c) returns boolean {
    return c.candidateId == winner;
});

if matchingCandidates.length() > 0 {
    store:Candidate winningCandidate = matchingCandidates[0];
    string partyName = winningCandidate.partyName;
    if partyMap.hasKey(partyName) {
        PartySummary partySummary = partyMap.get(partyName);
        partySummary.districtsWon += 1;
        partyMap[partyName] = partySummary;
    }
}

            
            
        }
    }
    
    // Calculate percentages
    int totalVotes = partyMap.toArray().reduce(function(int acc, PartySummary party) returns int {
        return acc + party.totalPopularVotes;
    }, 0);
    
    foreach string partyName in partyMap.keys() {
        PartySummary partySummary = partyMap.get(partyName);
        if totalVotes > 0 {
            partySummary.popularVotePercentage = <decimal>partySummary.totalPopularVotes / <decimal>totalVotes * 100.0;
        }
        partyMap[partyName] = partySummary;
    }
    
    return partyMap.toArray();
}

// Get candidate performance metrics
# Calculates detailed performance metrics for a candidate
#
# + dbClient - The database client
# + candidateId - The candidate ID to analyze
# + return - Candidate metrics or an error
public function getCandidateMetrics(store:Client dbClient, string candidateId) returns CandidateMetrics|error {
    store:Candidate candidate = check getCandidateById(dbClient, candidateId);
    
    // Get district results for this candidate's election to calculate metrics
    store:DistrictResult[] districts = check getDistrictResultsByElection(dbClient, candidate.electionId);
    
    // Calculate districts won
    int districtsWon = districts.filter(function(store:DistrictResult d) returns boolean {
        return d.winner == candidateId;
    }).length();
    
    // Get all candidates in the same election for vote share calculation
    store:Candidate[] allCandidates = check getCandidatesByElection(dbClient, candidate.electionId);
    int totalVotes = allCandidates.reduce(function(int acc, store:Candidate c) returns int {
        return acc + (c.popularVotes ?: 0);
    }, 0);
    
    decimal voteShare = totalVotes > 0 ? <decimal>(candidate.popularVotes ?: 0) / <decimal>totalVotes * 100.0 : 0.0;
    
    return {
        candidateId: candidate.candidateId,
        candidateName: candidate.candidateName,
        totalVotes: candidate.popularVotes ?: 0,
        voteShare: voteShare,
        districtsWon: districtsWon,
        position: candidate.position ?: 0,
        strongestDistrict: "TBD", // Would need vote breakdown by district
        weakestDistrict: "TBD"    // Would need vote breakdown by district
    };
}

// Update election summary after vote counting
# Updates the election summary with current totals
#
# + dbClient - The database client
# + electionId - The election ID to update summary for
# + return - An error if the operation fails
public function updateElectionSummary(store:Client dbClient, string electionId) returns error? {
    // Get current candidates to calculate totals
    store:Candidate[] candidates = check getCandidatesByElection(dbClient, electionId);
    
    // Calculate totals
    int totalVotesCast = candidates.reduce(function(int acc, store:Candidate c) returns int {
        return acc + (c.popularVotes ?: 0);
    }, 0);
    
    // Find winner (candidate with most popular votes)
    store:Candidate? winner = candidates.reduce(function(store:Candidate? acc, store:Candidate c) returns store:Candidate? {
        if acc == () {
            return c;
        }
        return (c.popularVotes ?: 0) > (acc.popularVotes ?: 0) ? c : acc;
    }, ());
    
    // Calculate turnout percentage (would need total registered voters)
    // For now, using a placeholder calculation
    decimal turnoutPercentage = 0.0; // Would calculate based on registered voters
    
    store:ElectionSummaryUpdate summaryUpdate = {
        totalVotesCast: totalVotesCast,
        turnoutPercentage: turnoutPercentage,
        winnerCandidateId: winner?.candidateId,
        electionStatus: "IN_PROGRESS" // or "COMPLETED" based on business logic
    };

    
    
    _ = check dbClient->/electionsummaries/[electionId].put(summaryUpdate);
}