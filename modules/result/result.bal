// result.bal - Election results processing, analytics, and reporting functions

import ballerina/time;
import ballerina/log;
import ballerina/lang.'decimal;
import online_election.store;

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

// Data access functions (to be implemented with your database)

// Get election by ID
public function getElectionById(string electionId) returns store:Election|error {
    // TODO: Implement database query
    // SELECT * FROM elections WHERE id = ?
    return error("Not implemented - connect to your database");
}

// Get all candidates for an election
public function getCandidatesByElection(string electionId) returns store:Candidate[]|error {
    // TODO: Implement database query
    // SELECT * FROM candidates WHERE election_id = ? AND is_active = true ORDER BY popular_votes DESC
    return error("Not implemented - connect to your database");
}

// Get all district results for an election
public function getDistrictResultsByElection(string electionId) returns store:DistrictResult[]|error {
    // TODO: Implement database query
    // SELECT * FROM district_results WHERE election_id = ?
    return error("Not implemented - connect to your database");
}

// Get election summary
public function getElectionSummaryById(string electionId) returns store:ElectionSummary|error {
    // TODO: Implement database query
    // SELECT * FROM election_summary WHERE election_id = ?
    return error("Not implemented - connect to your database");
}

// Get candidate by ID
public function getCandidateById(string candidateId) returns store:Candidate|error {
    // TODO: Implement database query
    // SELECT * FROM candidates WHERE candidate_id = ?
    return error("Not implemented - connect to your database");
}

// Update candidate votes
public function updateCandidateVotes(string candidateId, int additionalVotes) returns error? {
    // TODO: Implement database update
    // UPDATE candidates SET popular_votes = popular_votes + ? WHERE candidate_id = ?
    return error("Not implemented - connect to your database");
}

// Business logic functions

// Generate comprehensive election summary
public function generateElectionSummary(string electionId) returns ElectionSummaryResponse|error {
    store:Election election = check getElectionById(electionId);
    store:Candidate[] candidates = check getCandidatesByElection(electionId);
    store:DistrictResult[] districts = check getDistrictResultsByElection(electionId);
    store:ElectionSummary summary = check getElectionSummaryById(electionId);
    
    PartySummary[] partySummaries = generatePartySummaries(candidates);
    ProvinceAnalysis[] provinces = generateProvinceAnalysis(districts, candidates);

    return {
        electionId: election.id,
        electionName: election.electionName,
        totalVotes: summary.totalVotesCast,
        lastUpdated: getCurrentTimestamp(),
        candidates: candidates,
        districts: districts,
        statistics: summary,
        provinces: provinces,
        partySummaries: partySummaries
    };
}

// Calculate winner by electoral votes
public function calculateElectoralWinner(string electionId) returns store:Candidate|error {
    store:Candidate[] candidates = check getCandidatesByElection(electionId);
    
    if (candidates.length() == 0) {
        return error("No candidates found for election: " + electionId);
    }
    
    store:Candidate winner = candidates[0];
    foreach store:Candidate candidate in candidates {
        if (candidate.electoralVotes > winner.electoralVotes) {
            winner = candidate;
        }
    }
    
    return winner;
}

// Calculate winner by popular vote
public function calculatePopularVoteWinner(string electionId) returns store:Candidate|error {
    store:Candidate[] candidates = check getCandidatesByElection(electionId);
    
    if (candidates.length() == 0) {
        return error("No candidates found for election: " + electionId);
    }
    
    store:Candidate winner = candidates[0];
    foreach store:Candidate candidate in candidates {
        if (candidate.popularVotes > winner.popularVotes) {
            winner = candidate;
        }
    }
    
    return winner;
}

// Calculate margin of victory
public function calculateVictoryMargin(string electionId) returns VictoryMargin|error {
    store:Candidate[] candidates = check getCandidatesByElection(electionId);
    
    if (candidates.length() < 2) {
        return {marginType: "uncontested", margin: 100.0d, votes: 0};
    }
    
    // Sort by popular votes descending
    store:Candidate[] sortedCandidates = candidates.clone().sort(key = candidate => candidate.popularVotes, direction = "descending");
    
    store:Candidate winner = sortedCandidates[0];
    store:Candidate runnerUp = sortedCandidates[1];
    
    int popularMargin = winner.popularVotes - runnerUp.popularVotes;
    int totalVotes = calculateTotalVotes(candidates);
    decimal popularMarginPercentage = totalVotes > 0 ? <decimal>popularMargin / <decimal>totalVotes * 100.0d : 0.0d;
    
    string marginType = "close";
    if (popularMarginPercentage > 10.0d) {
        marginType = "comfortable";
    } else if (popularMarginPercentage > 20.0d) {
        marginType = "landslide";
    }
    
    return {
        marginType: marginType,
        margin: popularMarginPercentage,
        votes: popularMargin
    };
}

// Generate party summaries
function generatePartySummaries(store:Candidate[] candidates) returns PartySummary[] {
    map<PartySummary> partyMap = {};
    int totalVotes = calculateTotalVotes(candidates);
    
    foreach store:Candidate candidate in candidates {
        string partyName = candidate.partyName;
        
        if (!partyMap.hasKey(partyName)) {
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
        
        PartySummary party = partyMap.get(partyName);
        party.candidates.push(candidate);
        party.totalElectoralVotes += candidate.electoralVotes;
        party.totalPopularVotes += candidate.popularVotes;
        party.popularVotePercentage = totalVotes > 0 ? <decimal>party.totalPopularVotes / <decimal>totalVotes * 100.0 : 0.0;
        
        partyMap[partyName] = party;
    }
    
    return partyMap.toArray();
}

// Generate province analysis
function generateProvinceAnalysis(store:DistrictResult[] districts, store:Candidate[] candidates) returns ProvinceAnalysis[] {
    // Group districts by province
    map<store:DistrictResult[]> provinceDistricts = {};
    
    foreach store:DistrictResult district in districts {
        string province = getProvinceFromDistrict(district.districtName);
        if (!provinceDistricts.hasKey(province)) {
            provinceDistricts[province] = [];
        }
        store:DistrictResult[] currentDistricts = provinceDistricts.get(province);
        currentDistricts.push(district);
        provinceDistricts[province] = currentDistricts;
    }
    
    ProvinceAnalysis[] provinces = [];
    foreach string provinceName in provinceDistricts.keys() {
        store:DistrictResult[] provinceDistrictList = provinceDistricts.get(provinceName);
        
        int totalVotes = 0;
        int registeredVoters = 0;
        map<int> candidateVotes = {};
        
        foreach store:DistrictResult district in provinceDistrictList {
            totalVotes += district.votesProcessed;
            registeredVoters += district.totalVotes;
            
            // Find winner for this district and count votes
            string? winner = district.winner;
            if (winner is string) {
                int currentVotes = candidateVotes[winner] ?: 0;
                candidateVotes[winner] = currentVotes + district.votesProcessed;
            }
        }
        
        // Find province winner
        string winningCandidateId = "";
        int maxVotes = 0;
        foreach string candidateId in candidateVotes.keys() {
            int votes = candidateVotes.get(candidateId);
            if (votes > maxVotes) {
                maxVotes = votes;
                winningCandidateId = candidateId;
            }
        }
        
        decimal turnoutPercentage = registeredVoters > 0 ? <decimal>totalVotes / <decimal>registeredVoters * 100.0 : 0.0;
        
        provinces.push({
            provinceName: provinceName,
            totalVotes: totalVotes,
            registeredVoters: registeredVoters,
            turnoutPercentage: turnoutPercentage,
            winningCandidateId: winningCandidateId,
            districts: provinceDistrictList
        });
    }
    
    return provinces;
}

// Get candidate performance metrics
public function getCandidateMetrics(string candidateId, string electionId) returns CandidateMetrics|error {
    store:Candidate candidate = check getCandidateById(candidateId);
    store:Candidate[] allCandidates = check getCandidatesByElection(electionId);
    store:DistrictResult[] districts = check getDistrictResultsByElection(electionId);
    
    int totalVotes = calculateTotalVotes(allCandidates);
    decimal voteShare = totalVotes > 0 ? <decimal>candidate.popularVotes / <decimal>totalVotes * 100.0 : 0.0;
    
    int districtsWon = 0;
    string strongestDistrict = "";
    string weakestDistrict = "";
    
    foreach store:DistrictResult district in districts {
        if (district.winner == candidateId) {
            districtsWon += 1;
        }
    }
    
    // Find strongest and weakest districts (simplified - would need more detailed vote data)
    if (districts.length() > 0) {
        strongestDistrict = districts[0].districtName;
        weakestDistrict = districts[0].districtName;
    }
    
    return {
        candidateId: candidate.candidateId,
        candidateName: candidate.candidateName,
        totalVotes: candidate.popularVotes,
        voteShare: voteShare,
        districtsWon: districtsWon,
        position: candidate.position ?: 0,
        strongestDistrict: strongestDistrict,
        weakestDistrict: weakestDistrict
    };
}

// Generate district-wise results report
public function generateDistrictResultsReport(string electionId) returns map<json>|error {
    store:DistrictResult[] districts = check getDistrictResultsByElection(electionId);
    store:Candidate[] candidates = check getCandidatesByElection(electionId);
    
    map<json> report = {};
    
    foreach store:DistrictResult district in districts {
        store:Candidate? winner = ();
        if (district.winner is string) {
            foreach store:Candidate candidate in candidates {
                if (candidate.candidateId == district.winner) {
                    winner = candidate;
                    break;
                }
            }
        }
        
        string winnerName = winner is store:Candidate ? winner.candidateName : "Unknown";
        string winnerParty = winner is store:Candidate ? winner.partyName : "Unknown";
        
        decimal turnout = district.totalVotes > 0 ? <decimal>district.votesProcessed / <decimal>district.totalVotes * 100.0 : 0.0;
        
        json districtReport = {
            "districtCode": district.districtCode,
            "districtName": district.districtName,
            "totalVotes": district.totalVotes,
            "votesProcessed": district.votesProcessed,
            "turnoutPercentage": turnout,
            "status": district.status,
            "winner": {
                "candidateId": district.winner,
                "candidateName": winnerName,
                "partyName": winnerParty
            }
        };
        
        report[district.districtCode] = districtReport;
    }
    
    return report;
}

// Generate turnout analysis
public function generateTurnoutAnalysis(string electionId) returns json|error {
    store:DistrictResult[] districts = check getDistrictResultsByElection(electionId);
    store:ElectionSummary summary = check getElectionSummaryById(electionId);
    
    decimal totalTurnout = 0.0;
    decimal highestTurnout = 0.0;
    decimal lowestTurnout = 100.0;
    string highestTurnoutDistrict = "";
    string lowestTurnoutDistrict = "";
    int validDistricts = 0;
    
    foreach store:DistrictResult district in districts {
        if (district.totalVotes > 0) {
            decimal turnout = <decimal>district.votesProcessed / <decimal>district.totalVotes * 100.0;
            totalTurnout += turnout;
            validDistricts += 1;
            
            if (turnout > highestTurnout) {
                highestTurnout = turnout;
                highestTurnoutDistrict = district.districtName;
            }
            
            if (turnout < lowestTurnout) {
                lowestTurnout = turnout;
                lowestTurnoutDistrict = district.districtName;
            }
        }
    }
    
    decimal averageTurnout = validDistricts > 0 ? totalTurnout / <decimal>validDistricts : 0.0;
    
    return {
        "overallTurnout": summary.turnoutPercentage,
        "averageDistrictTurnout": averageTurnout,
        "highestTurnout": {
            "percentage": highestTurnout,
            "district": highestTurnoutDistrict
        },
        "lowestTurnout": {
            "percentage": lowestTurnout,
            "district": lowestTurnoutDistrict
        },
        "totalRegisteredVoters": summary.totalRegisteredVoters,
        "totalVotesCast": summary.totalVotesCast,
        "rejectedVotes": summary.totalRejectedVotes
    };
}

// Generate executive summary
public function generateExecutiveSummary(string electionId) returns json|error {
    store:Candidate winner = check calculateElectoralWinner(electionId);
    store:Candidate popularWinner = check calculatePopularVoteWinner(electionId);
    VictoryMargin victoryMargin = check calculateVictoryMargin(electionId);
    store:ElectionSummary summary = check getElectionSummaryById(electionId);
    
    return {
        "electionId": electionId,
        "electoralWinner": winner.candidateName,
        "popularVoteWinner": popularWinner.candidateName,
        "victoryMargin": victoryMargin,
        "totalVotes": summary.totalVotesCast,
        "turnout": summary.turnoutPercentage,
        "electionStatus": summary.electionStatus,
        "totalRegisteredVoters": summary.totalRegisteredVoters,
        "rejectedVotes": summary.totalRejectedVotes,
        "timestamp": getCurrentTimestamp()
    };
}

// Helper functions

function calculateTotalVotes(store:Candidate[] candidates) returns int {
    int total = 0;
    foreach store:Candidate candidate in candidates {
        total += candidate.popularVotes;
    }
    return total;
}

public function getDistrictsByProvince(string provinceId) returns store:District[]|error {
    // TODO: Implement database query
    // SELECT * FROM districts WHERE province_id = ?
    return error("Not implemented - connect to your database");
}

public function getDistrictsByProvince(string provinceId) returns store:District[]|error {
    // TODO: Implement database query
    // SELECT * FROM districts WHERE province_id = ?
    return error("Not implemented - connect to your database");
}

function getProvinceFromDistrict(string districtName) returns string {
    // Map district names to provinces - you should implement this based on your data
    match districtName.toLowerAscii() {
        "colombo"|"gampaha"|"kalutara" => { return "Western"; }
        "kandy"|"matale"|"nuwara eliya" => { return "Central"; }
        "galle"|"matara"|"hambantota" => { return "Southern"; }
        "jaffna"|"kilinochchi"|"mannar"|"vavuniya"|"mullaitivu" => { return "Northern"; }
        "batticaloa"|"ampara"|"trincomalee" => { return "Eastern"; }
        "kurunegala"|"puttalam" => { return "North Western"; }
        "anuradhapura"|"polonnaruwa" => { return "North Central"; }
        "badulla"|"moneragala" => { return "Uva"; }
        "ratnapura"|"kegalle" => { return "Sabaragamuwa"; }
        _ => { return "Unknown"; }
    }
}

function getCurrentTimestamp() returns string {
    time:Utc currentTime = time:utcNow();
    return time:utcToString(currentTime);
}

// Real-time update functions

public function processVoteUpdate(string candidateId, int additionalVotes) returns json|error {
    error? updateResult = updateCandidateVotes(candidateId, additionalVotes);
    if (updateResult is error) {
        return updateResult;
    }
    
    store:Candidate updatedCandidate = check getCandidateById(candidateId);
    
    return {
        "success": true,
        "message": "Vote count updated successfully",
        "candidateId": candidateId,
        "newVoteCount": updatedCandidate.popularVotes,
        "timestamp": getCurrentTimestamp()
    };
}

// Get live election status
public function getLiveElectionStatus(string electionId) returns json|error {
    store:DistrictResult[] districts = check getDistrictResultsByElection(electionId);
    
    int totalDistricts = districts.length();
    int completedDistricts = 0;
    
    foreach store:DistrictResult district in districts {
        if (district.status == "completed") {
            completedDistricts += 1;
        }
    }
    
    decimal completionPercentage = totalDistricts > 0 ? <decimal>completedDistricts / <decimal>totalDistricts * 100.0d : 0.0d;
    
    json payload = {
        "electionId": electionId,
        "totalDistricts": totalDistricts,
        "completedDistricts": completedDistricts,
        "completionPercentage": completionPercentage,
        "isLive": completionPercentage < 100.0d,
        "lastUpdated": getCurrentTimestamp()
    };
    return payload;
}