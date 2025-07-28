import ballerina/sql;
import ballerina/persist;
import online_election.store;

public final store:Client dbClient = check new ();

// Import your existing types from types.bal
// These should be imported rather than redefined

public function updateCandidateTotal(string electionId, string candidateId,
                                     store:Client dbClient) returns error|int {

    // Get the candidate district vote summary using the correct composite key
    store:CandidateDistrictVoteSummary|persist:Error result = 
        dbClient->/candidatedistrictvotesummaries/[electionId]/[candidateId].get();

    if result is persist:Error {
        return error("No record found for electionId: " + electionId + " and candidateId: " + candidateId);
    }

    store:CandidateDistrictVoteSummary candidate = result;

    // Sum all district votes using proper field access
    int totalVotes = candidate.Ampara + candidate.Anuradhapura + candidate.Badulla + 
                    candidate.Batticaloa + candidate.Colombo + candidate.Galle + 
                    candidate.Gampaha + candidate.Hambantota + candidate.Jaffna + 
                    candidate.Kalutara + candidate.Kandy + candidate.Kegalle + 
                    candidate.Kilinochchi + candidate.Kurunegala + candidate.Mannar + 
                    candidate.Matale + candidate.Matara + candidate.Monaragala + 
                    candidate.Mullaitivu + candidate.NuwaraEliya + candidate.Polonnaruwa + 
                    candidate.Puttalam + candidate.Ratnapura + candidate.Trincomalee + 
                    candidate.Vavuniya;

    // Use the correct update type from the generated client
    store:CandidateDistrictVoteSummaryUpdate updateData = {
        Totals: totalVotes
    };
    
    // Update using the composite key
    store:CandidateDistrictVoteSummary|persist:Error updateResult = 
        dbClient->/candidatedistrictvotesummaries/[electionId]/[candidateId].put(updateData);

    if updateResult is persist:Error {
        return error("Update failed: " + updateResult.message());
    }

    return totalVotes;
}

public function getSortedCandidatesByTotal(string electionId,
                                           store:Client dbClient) returns error|CandidateTotal[] {

    sql:ParameterizedQuery whereClause = `election_id = ${electionId}`;
    sql:ParameterizedQuery orderByClause = `totals DESC`;  // FIXED: Changed from "Totals" to "totals"

    stream<store:CandidateDistrictVoteSummary, persist:Error?> resultStream = 
        dbClient->/candidatedistrictvotesummaries.get(
            whereClause = whereClause,
            orderByClause = orderByClause
        );

    CandidateTotal[] sortedCandidates = [];

    error? processError = resultStream.forEach(function(store:CandidateDistrictVoteSummary candidate) {
        // Convert to CandidateTotal type
        CandidateTotal candidateTotal = {
            candidateId: candidate.candidateId,
            Totals: candidate.Totals
        };
        sortedCandidates.push(candidateTotal);
    }); 

    check resultStream.close();

    if processError is error {
        return processError;
    }

    return sortedCandidates;
}

public function calculateCandidateVoteSummary(string electionId, store:Client dbClient) returns CandidateVoteSummary[]|error {
    
    sql:ParameterizedQuery whereClause = `election_id = ${electionId}`;
    sql:ParameterizedQuery orderByClause = `totals DESC`;  // FIXED: Changed from "Totals" to "totals"

    stream<store:CandidateDistrictVoteSummary, persist:Error?> resultStream = 
        dbClient->/candidatedistrictvotesummaries.get(
            whereClause = whereClause,
            orderByClause = orderByClause
        );
    
    CandidateTotal[] candidates = [];
    error? processError = resultStream.forEach(function(store:CandidateDistrictVoteSummary candidate) {
        CandidateTotal candidateTotal = {
            candidateId: candidate.candidateId,
            Totals: candidate.Totals
        };
        candidates.push(candidateTotal);
    });
    
    check resultStream.close();
    
    if processError is error {
        return processError;
    }
    
    if candidates.length() == 0 {
        return error("No candidates found for election ID: " + electionId);
    }
    
    // Calculate grand total votes
    int grandTotalVotes = 0;
    foreach CandidateTotal candidate in candidates {
        grandTotalVotes += candidate.Totals;
    }
    
    // Create candidate summaries with percentages and ranks
    CandidateVoteSummary[] candidateSummaries = [];
    foreach int i in 0 ..< candidates.length() {
        CandidateTotal candidate = candidates[i];
        decimal percentage = 0.0;
        if grandTotalVotes > 0 {
            percentage = <decimal>candidate.Totals / <decimal>grandTotalVotes * 100.0;
        }
        
        CandidateVoteSummary summary = {
            candidateId: candidate.candidateId,
            candidateName: (),
            totalVotes: candidate.Totals,
            percentage: percentage,
            rank: i + 1
        };
        
        candidateSummaries.push(summary);
    }
    
    return candidateSummaries;
}

public function calculateCandidateDistrictAnalysis(string electionId, store:Client dbClient) returns CandidateDistrictAnalysis[]|error {
    
    sql:ParameterizedQuery whereClause = `election_id = ${electionId}`;

    stream<store:CandidateDistrictVoteSummary, persist:Error?> resultStream = 
        dbClient->/candidatedistrictvotesummaries.get(whereClause = whereClause);
    
    CandidateDistrictAnalysis[] analyses = [];

    error? processError = resultStream.forEach(function(store:CandidateDistrictVoteSummary candidateData) {
        string candidateId = candidateData.candidateId;
        int totalVotes = candidateData.Totals;
        
        // Create district votes map
        map<int> districtVotes = {
            "Ampara": candidateData.Ampara,
            "Anuradhapura": candidateData.Anuradhapura,
            "Badulla": candidateData.Badulla,
            "Batticaloa": candidateData.Batticaloa,
            "Colombo": candidateData.Colombo,
            "Galle": candidateData.Galle,
            "Gampaha": candidateData.Gampaha,
            "Hambantota": candidateData.Hambantota,
            "Jaffna": candidateData.Jaffna,
            "Kalutara": candidateData.Kalutara,
            "Kandy": candidateData.Kandy,
            "Kegalle": candidateData.Kegalle,
            "Kilinochchi": candidateData.Kilinochchi,
            "Kurunegala": candidateData.Kurunegala,
            "Mannar": candidateData.Mannar,
            "Matale": candidateData.Matale,
            "Matara": candidateData.Matara,
            "Monaragala": candidateData.Monaragala,
            "Mullaitivu": candidateData.Mullaitivu,
            "NuwaraEliya": candidateData.NuwaraEliya,
            "Polonnaruwa": candidateData.Polonnaruwa,
            "Puttalam": candidateData.Puttalam,
            "Ratnapura": candidateData.Ratnapura,
            "Trincomalee": candidateData.Trincomalee,
            "Vavuniya": candidateData.Vavuniya
        };
        
        // Calculate district percentages
        map<decimal> districtPercentages = {};
        foreach var [district, votes] in districtVotes.entries() {
            decimal percentage = 0.0;
            if totalVotes > 0 {
                percentage = <decimal>votes / <decimal>totalVotes * 100.0;
            }
            districtPercentages[district] = percentage;
        }
        
        CandidateDistrictAnalysis analysis = {
            candidateId: candidateId,
            candidateName: (),
            districtVotes: districtVotes,
            districtPercentages: districtPercentages,
            totalVotes: totalVotes
        };
        
        analyses.push(analysis);
    });
    
    check resultStream.close();
    
    if processError is error {
        return processError;
    }
    
    return analyses;
}

// Function to calculate total votes per district for a given election
public function calculateDistrictVoteTotals(string electionId, CandidateDistrictVoteSummary[] candidateVotes) returns DistrictVoteTotals|error {
    
    // Initialize district totals
    DistrictVoteTotals districtTotals = {
        electionId: electionId,
        Ampara: 0,
        Anuradhapura: 0,
        Badulla: 0,
        Batticaloa: 0,
        Colombo: 0,
        Galle: 0,
        Gampaha: 0,
        Hambantota: 0,
        Jaffna: 0,
        Kalutara: 0,
        Kandy: 0,
        Kegalle: 0,
        Kilinochchi: 0,
        Kurunegala: 0,
        Mannar: 0,
        Matale: 0,
        Matara: 0,
        Monaragala: 0,
        Mullaitivu: 0,
        NuwaraEliya: 0,
        Polonnaruwa: 0,
        Puttalam: 0,
        Ratnapura: 0,
        Trincomalee: 0,
        Vavuniya: 0,
        GrandTotal: 0
    };
    
    // Filter records for the specific election and sum up votes by district
    foreach CandidateDistrictVoteSummary candidate in candidateVotes {
        if (candidate.electionId == electionId) {
            districtTotals.Ampara += candidate.Ampara;
            districtTotals.Anuradhapura += candidate.Anuradhapura;
            districtTotals.Badulla += candidate.Badulla;
            districtTotals.Batticaloa += candidate.Batticaloa;
            districtTotals.Colombo += candidate.Colombo;
            districtTotals.Galle += candidate.Galle;
            districtTotals.Gampaha += candidate.Gampaha;
            districtTotals.Hambantota += candidate.Hambantota;
            districtTotals.Jaffna += candidate.Jaffna;
            districtTotals.Kalutara += candidate.Kalutara;
            districtTotals.Kandy += candidate.Kandy;
            districtTotals.Kegalle += candidate.Kegalle;
            districtTotals.Kilinochchi += candidate.Kilinochchi;
            districtTotals.Kurunegala += candidate.Kurunegala;
            districtTotals.Mannar += candidate.Mannar;
            districtTotals.Matale += candidate.Matale;
            districtTotals.Matara += candidate.Matara;
            districtTotals.Monaragala += candidate.Monaragala;
            districtTotals.Mullaitivu += candidate.Mullaitivu;
            districtTotals.NuwaraEliya += candidate.NuwaraEliya;
            districtTotals.Polonnaruwa += candidate.Polonnaruwa;
            districtTotals.Puttalam += candidate.Puttalam;
            districtTotals.Ratnapura += candidate.Ratnapura;
            districtTotals.Trincomalee += candidate.Trincomalee;
            districtTotals.Vavuniya += candidate.Vavuniya;
        }
    }
    
    // Calculate grand total
    districtTotals.GrandTotal = districtTotals.Ampara + districtTotals.Anuradhapura + 
                               districtTotals.Badulla + districtTotals.Batticaloa + 
                               districtTotals.Colombo + districtTotals.Galle + 
                               districtTotals.Gampaha + districtTotals.Hambantota + 
                               districtTotals.Jaffna + districtTotals.Kalutara + 
                               districtTotals.Kandy + districtTotals.Kegalle + 
                               districtTotals.Kilinochchi + districtTotals.Kurunegala + 
                               districtTotals.Mannar + districtTotals.Matale + 
                               districtTotals.Matara + districtTotals.Monaragala + 
                               districtTotals.Mullaitivu + districtTotals.NuwaraEliya + 
                               districtTotals.Polonnaruwa + districtTotals.Puttalam + 
                               districtTotals.Ratnapura + districtTotals.Trincomalee + 
                               districtTotals.Vavuniya;
    
    return districtTotals;
}

// Enhanced function that gets candidate details and vote summary
// Add this record type definition at the top of your file or in a separate types file
public type CandidateExportData record {
    string candidateId;
    string? candidateImage;
    int position;
    string candidateName;
    string partyName;
    string partyColor;
    int totalVotes;
    decimal percentage;
    int districtsWon;
    string? partySymbol;
    boolean isActive;
};

public function getComprehensiveCandidateData(string electionId, store:Client dbClient) returns CandidateExportData[]|error {
    
    // Get vote summaries first
    sql:ParameterizedQuery whereClause = `election_id = ${electionId}`;
    sql:ParameterizedQuery orderByClause = `totals DESC`;  // FIXED: Changed from "Totals" to "totals"

    stream<store:CandidateDistrictVoteSummary, persist:Error?> voteStream = 
        dbClient->/candidatedistrictvotesummaries.get(
            whereClause = whereClause,
            orderByClause = orderByClause
        );
    
    store:CandidateDistrictVoteSummary[] voteSummaries = [];
    error? voteProcessError = voteStream.forEach(function(store:CandidateDistrictVoteSummary vs) {
        voteSummaries.push(vs);
    });
    
    check voteStream.close();
    
    if voteProcessError is error {
        return voteProcessError;
    }
    
    if voteSummaries.length() == 0 {
        return error("No vote summaries found for election ID: " + electionId);
    }
    
    // Calculate total votes across all candidates for percentage calculation
    int grandTotalVotes = 0;
    foreach store:CandidateDistrictVoteSummary vs in voteSummaries {
        grandTotalVotes += vs.Totals;
    }
    
    // Process each candidate
    CandidateExportData[] exportData = [];
    
    foreach int i in 0 ..< voteSummaries.length() {
        store:CandidateDistrictVoteSummary vs = voteSummaries[i];
        string candidateId = vs.candidateId;
        int totalVotes = vs.Totals;
        
        // Get candidate details
        store:Candidate|persist:Error candidateResult = dbClient->/candidates/[candidateId].get();
        
        // Default values in case candidate details are not found
        string candidateName = "Unknown";
        string partyName = "Unknown";
        string partyColor = "#000000";
        string? candidateImage = ();
        string? partySymbol = ();
        boolean isActive = true;
        
        if candidateResult is store:Candidate {
            candidateName = candidateResult.candidateName;
            partyName = candidateResult.partyName;
            partyColor = candidateResult.partyColor;
            candidateImage = candidateResult.candidateImage;
            partySymbol = candidateResult.partySymbol;
            isActive = candidateResult.isActive;
        }
        
        // Calculate percentage
        decimal percentage = 0.0d;
        if grandTotalVotes > 0 {
            percentage = <decimal>totalVotes / <decimal>grandTotalVotes * 100.0d;
        }
        
        // Calculate districts won
        int districtsWon = calculateDistrictsWonFromVoteSummaries(candidateId, voteSummaries);
        
        CandidateExportData exportRecord = {
            candidateId: candidateId,
            candidateImage: candidateImage,
            position: i + 1,
            candidateName: candidateName,
            partyName: partyName,
            partyColor: partyColor,
            totalVotes: totalVotes,
            percentage: percentage,
            districtsWon: districtsWon,
            partySymbol: partySymbol,
            isActive: isActive
        };
        
        exportData.push(exportRecord);
    }
    
    return exportData;
}

function calculateDistrictsWonFromVoteSummaries(string candidateId, store:CandidateDistrictVoteSummary[] allVoteSummaries) returns int {
    
    // List of all districts
    string[] districts = [
        "Ampara", "Anuradhapura", "Badulla", "Batticaloa", "Colombo",
        "Galle", "Gampaha", "Hambantota", "Jaffna", "Kalutara",
        "Kandy", "Kegalle", "Kilinochchi", "Kurunegala", "Mannar",
        "Matale", "Matara", "Monaragala", "Mullaitivu", "NuwaraEliya",
        "Polonnaruwa", "Puttalam", "Ratnapura", "Trincomalee", "Vavuniya"
    ];
    
    int districtsWon = 0;
    
    // Check each district
    foreach string district in districts {
        int maxVotesInDistrict = 0;
        string winnerInDistrict = "";
        
        // Find the candidate with highest votes in this district
        foreach store:CandidateDistrictVoteSummary vs in allVoteSummaries {
            int votesInDistrict = getDistrictVotesFromSummary(vs, district);
            if votesInDistrict > maxVotesInDistrict {
                maxVotesInDistrict = votesInDistrict;
                winnerInDistrict = vs.candidateId;
            }
        }
        
        // If this candidate won this district, increment count
        if winnerInDistrict == candidateId && maxVotesInDistrict > 0 {
            districtsWon += 1;
        }
    }
    
    return districtsWon;
}

// Helper function to get votes for a specific district from vote summary
function getDistrictVotesFromSummary(store:CandidateDistrictVoteSummary vs, string district) returns int {
    match district {
        "Ampara" => { return vs.Ampara; }
        "Anuradhapura" => { return vs.Anuradhapura; }
        "Badulla" => { return vs.Badulla; }
        "Batticaloa" => { return vs.Batticaloa; }
        "Colombo" => { return vs.Colombo; }
        "Galle" => { return vs.Galle; }
        "Gampaha" => { return vs.Gampaha; }
        "Hambantota" => { return vs.Hambantota; }
        "Jaffna" => { return vs.Jaffna; }
        "Kalutara" => { return vs.Kalutara; }
        "Kandy" => { return vs.Kandy; }
        "Kegalle" => { return vs.Kegalle; }
        "Kilinochchi" => { return vs.Kilinochchi; }
        "Kurunegala" => { return vs.Kurunegala; }
        "Mannar" => { return vs.Mannar; }
        "Matale" => { return vs.Matale; }
        "Matara" => { return vs.Matara; }
        "Monaragala" => { return vs.Monaragala; }
        "Mullaitivu" => { return vs.Mullaitivu; }
        "NuwaraEliya" => { return vs.NuwaraEliya; }
        "Polonnaruwa" => { return vs.Polonnaruwa; }
        "Puttalam" => { return vs.Puttalam; }
        "Ratnapura" => { return vs.Ratnapura; }
        "Trincomalee" => { return vs.Trincomalee; }
        "Vavuniya" => { return vs.Vavuniya; }
        _ => { return 0; }
    }
}

public function exportElectionCandidateDataAsCSV(string electionId, store:Client dbClient) returns string|error {
    
    CandidateExportData[] candidates = check getComprehensiveCandidateData(electionId, dbClient);
    
    // CSV Header
    string csvContent = "Position,Candidate Name,Party Name,Party Color,Total Votes,Percentage,Districts Won,Candidate Image,Party Symbol,Is Active,Candidate ID\n";
    
    // Add data rows
    foreach CandidateExportData candidate in candidates {
        string candidateImage = candidate.candidateImage is () ? "" : <string>candidate.candidateImage;
        string partySymbol = candidate.partySymbol is () ? "" : <string>candidate.partySymbol;
        string isActive = candidate.isActive ? "Yes" : "No";
        
        csvContent += string `${candidate.position},"${candidate.candidateName}","${candidate.partyName}","${candidate.partyColor}",${candidate.totalVotes},${candidate.percentage},${candidate.districtsWon},"${candidateImage}","${partySymbol}","${isActive}","${candidate.candidateId}"` + "\n";
    }
    
    return csvContent;
}

public function getElectionSummary(string electionId, store:Client dbClient) returns record {|
    string electionId;
    int totalCandidates;
    int totalVotes;
    string winner;
    decimal winnerPercentage;
    int totalDistrictsConsidered;
|} |error {
    
    CandidateExportData[] candidates = check getComprehensiveCandidateData(electionId, dbClient);
    
    if candidates.length() == 0 {
        return error("No candidates found for election");
    }
    
    // Calculate summary statistics
    int totalVotes = 0;
    foreach CandidateExportData candidate in candidates {
        totalVotes += candidate.totalVotes;
    }
    
    // Winner is the first candidate (highest votes)
    CandidateExportData winner = candidates[0];
    
    return {
        electionId: electionId,
        totalCandidates: candidates.length(),
        totalVotes: totalVotes,
        winner: winner.candidateName,
        winnerPercentage: winner.percentage,
        totalDistrictsConsidered: 25 // All Sri Lankan districts
    };
}

// CRITICAL FIX: Native SQL query using lowercase column names
public function calculateDistrictVoteTotalsFromDB(string electionId, store:Client dbClient) returns DistrictVoteTotals|error {
    
    sql:ParameterizedQuery sqlQuery = `
        SELECT 
            election_id,
            SUM(ampara) as ampara,
            SUM(anuradhapura) as anuradhapura,
            SUM(badulla) as badulla,
            SUM(batticaloa) as batticaloa,
            SUM(colombo) as colombo,
            SUM(galle) as galle,
            SUM(gampaha) as gampaha,
            SUM(hambantota) as hambantota,
            SUM(jaffna) as jaffna,
            SUM(kalutara) as kalutara,
            SUM(kandy) as kandy,
            SUM(kegalle) as kegalle,
            SUM(kilinochchi) as kilinochchi,
            SUM(kurunegala) as kurunegala,
            SUM(mannar) as mannar,
            SUM(matale) as matale,
            SUM(matara) as matara,
            SUM(monaragala) as monaragala,
            SUM(mullaitivu) as mullaitivu,
            SUM(nuwaraeliya) as nuwaraeliya,
            SUM(polonnaruwa) as polonnaruwa,
            SUM(puttalam) as puttalam,
            SUM(ratnapura) as ratnapura,
            SUM(trincomalee) as trincomalee,
            SUM(vavuniya) as vavuniya
        FROM "CandidateDistrictVoteSummary" 
        WHERE election_id = ${electionId}
        GROUP BY election_id
    `;
    
    stream<record {}, persist:Error?> resultStream = dbClient->queryNativeSQL(sqlQuery);
    record {|record {} value;|}? result = check resultStream.next();
    check resultStream.close();
    
    if (result is ()) {
        return error("No data found for election ID: " + electionId);
    }
    
    record {} data = result.value;
    
    // Extract data and calculate grand total
    DistrictVoteTotals districtTotals = {
        electionId: electionId,
        Ampara: <int>data["ampara"],
        Anuradhapura: <int>data["anuradhapura"],
        Badulla: <int>data["badulla"],
        Batticaloa: <int>data["batticaloa"],
        Colombo: <int>data["colombo"],
        Galle: <int>data["galle"],
        Gampaha: <int>data["gampaha"],
        Hambantota: <int>data["hambantota"],
        Jaffna: <int>data["jaffna"],
        Kalutara: <int>data["kalutara"],
        Kandy: <int>data["kandy"],
        Kegalle: <int>data["kegalle"],
        Kilinochchi: <int>data["kilinochchi"],
        Kurunegala: <int>data["kurunegala"],
        Mannar: <int>data["mannar"],
        Matale: <int>data["matale"],
        Matara: <int>data["matara"],
        Monaragala: <int>data["monaragala"],
        Mullaitivu: <int>data["mullaitivu"],
        NuwaraEliya: <int>data["nuwaraeliya"],
        Polonnaruwa: <int>data["polonnaruwa"],
        Puttalam: <int>data["puttalam"],
        Ratnapura: <int>data["ratnapura"],
        Trincomalee: <int>data["trincomalee"],
        Vavuniya: <int>data["vavuniya"],
        GrandTotal: 0
    };
    
    // Calculate grand total
    districtTotals.GrandTotal = districtTotals.Ampara + districtTotals.Anuradhapura + 
                               districtTotals.Badulla + districtTotals.Batticaloa + 
                               districtTotals.Colombo + districtTotals.Galle + 
                               districtTotals.Gampaha + districtTotals.Hambantota + 
                               districtTotals.Jaffna + districtTotals.Kalutara + 
                               districtTotals.Kandy + districtTotals.Kegalle + 
                               districtTotals.Kilinochchi + districtTotals.Kurunegala + 
                               districtTotals.Mannar + districtTotals.Matale + 
                               districtTotals.Matara + districtTotals.Monaragala + 
                               districtTotals.Mullaitivu + districtTotals.NuwaraEliya + 
                               districtTotals.Polonnaruwa + districtTotals.Puttalam + 
                               districtTotals.Ratnapura + districtTotals.Trincomalee + 
                               districtTotals.Vavuniya;
    
    return districtTotals;
}

public function batchUpdateCandidateTotals(string electionId, store:Client dbClient) returns error? {
    
    sql:ParameterizedQuery whereClause = `election_id = ${electionId}`;
    stream<store:CandidateDistrictVoteSummary, persist:Error?> resultStream = 
        dbClient->/candidatedistrictvotesummaries.get(whereClause = whereClause);
    
    error? processError = resultStream.forEach(function(store:CandidateDistrictVoteSummary candidate) {
        int totalVotes = candidate.Ampara + candidate.Anuradhapura + candidate.Badulla + 
                        candidate.Batticaloa + candidate.Colombo + candidate.Galle + 
                        candidate.Gampaha + candidate.Hambantota + candidate.Jaffna + 
                        candidate.Kalutara + candidate.Kandy + candidate.Kegalle + 
                        candidate.Kilinochchi + candidate.Kurunegala + candidate.Mannar + 
                        candidate.Matale + candidate.Matara + candidate.Monaragala + 
                        candidate.Mullaitivu + candidate.NuwaraEliya + candidate.Polonnaruwa + 
                        candidate.Puttalam + candidate.Ratnapura + candidate.Trincomalee + 
                        candidate.Vavuniya;
        
        if totalVotes != candidate.Totals {
            // Update the total if it's different
            store:CandidateDistrictVoteSummaryUpdate updateData = { Totals: totalVotes };
            var updateResult = dbClient->/candidatedistrictvotesummaries/[candidate.electionId]/[candidate.candidateId].put(updateData);
            
            // Handle the update result
            if updateResult is error {
                // You can log the error or handle it as needed
                // For now, we'll just ignore individual update errors
                // but you could also return the error to stop processing
            }
        }
    });
    
    check resultStream.close();
    
    if processError is error {
        return processError;
    }
    
    return ();
}

// Function to get detailed district-wise winner analysis
public function getDistrictWinnerAnalysis(string electionId, store:Client dbClient) returns record {|
    string electionId;
    map<record {| string candidateId; string candidateName; int votes; |}> districtWinners;
    map<decimal> marginPercentages;
|} |error {
    
    sql:ParameterizedQuery whereClause = `election_id = ${electionId}`;
    stream<store:CandidateDistrictVoteSummary, persist:Error?> resultStream = 
        dbClient->/candidatedistrictvotesummaries.get(whereClause = whereClause);
    
    store:CandidateDistrictVoteSummary[] allCandidates = [];
    error? processError = resultStream.forEach(function(store:CandidateDistrictVoteSummary candidate) {
        allCandidates.push(candidate);
    });
    
    check resultStream.close();
    
    if processError is error {
        return processError;
    }
    
    string[] districts = [
        "Ampara", "Anuradhapura", "Badulla", "Batticaloa", "Colombo",
        "Galle", "Gampaha", "Hambantota", "Jaffna", "Kalutara",
        "Kandy", "Kegalle", "Kilinochchi", "Kurunegala", "Mannar",
        "Matale", "Matara", "Monaragala", "Mullaitivu", "NuwaraEliya",
        "Polonnaruwa", "Puttalam", "Ratnapura", "Trincomalee", "Vavuniya"
    ];
    
    map<record {| string candidateId; string candidateName; int votes; |}> districtWinners = {};
    map<decimal> marginPercentages = {};
    
    foreach string district in districts {
        int maxVotes = 0;
        int secondMaxVotes = 0;
        string winnerCandidateId = "";
        
        // Find winner and runner-up in this district
        foreach store:CandidateDistrictVoteSummary candidate in allCandidates {
            int votes = getDistrictVotesFromSummary(candidate, district);
            if votes > maxVotes {
                secondMaxVotes = maxVotes;
                maxVotes = votes;
                winnerCandidateId = candidate.candidateId;
            } else if votes > secondMaxVotes {
                secondMaxVotes = votes;
            }
        }
        
        if winnerCandidateId != "" && maxVotes > 0 {
            // Get candidate name
            store:Candidate|persist:Error candidateResult = dbClient->/candidates/[winnerCandidateId].get();
            string candidateName = candidateResult is store:Candidate ? candidateResult.candidateName : "Unknown";
            
            districtWinners[district] = {
                candidateId: winnerCandidateId,
                candidateName: candidateName,
                votes: maxVotes
            };
            
            // Calculate margin percentage
            decimal marginPercentage = 0.0;
            if maxVotes > 0 && secondMaxVotes > 0 {
                marginPercentage = <decimal>(maxVotes - secondMaxVotes) / <decimal>maxVotes * 100.0;
            }
            marginPercentages[district] = marginPercentage;
        }
    }
    
    return {
        electionId: electionId,
        districtWinners: districtWinners,
        marginPercentages: marginPercentages
    };
}

// Function to validate election data integrity
public function validateElectionDataIntegrity(string electionId, store:Client dbClient) returns record {|
    boolean isValid;
    string[] errors;
    record {|
        int candidatesWithMismatchedTotals;
        int candidatesWithNegativeVotes;
        int candidatesWithMissingData;
    |} statistics;
|} |error {
    
    string[] errors = [];
    int candidatesWithMismatchedTotals = 0;
    int candidatesWithNegativeVotes = 0;
    int candidatesWithMissingData = 0;
    
    sql:ParameterizedQuery whereClause = `election_id = ${electionId}`;
    stream<store:CandidateDistrictVoteSummary, persist:Error?> resultStream = 
        dbClient->/candidatedistrictvotesummaries.get(whereClause = whereClause);
    
    error? processError = resultStream.forEach(function(store:CandidateDistrictVoteSummary candidate) {
        // Calculate actual total from district votes
        int calculatedTotal = candidate.Ampara + candidate.Anuradhapura + candidate.Badulla + 
                             candidate.Batticaloa + candidate.Colombo + candidate.Galle + 
                             candidate.Gampaha + candidate.Hambantota + candidate.Jaffna + 
                             candidate.Kalutara + candidate.Kandy + candidate.Kegalle + 
                             candidate.Kilinochchi + candidate.Kurunegala + candidate.Mannar + 
                             candidate.Matale + candidate.Matara + candidate.Monaragala + 
                             candidate.Mullaitivu + candidate.NuwaraEliya + candidate.Polonnaruwa + 
                             candidate.Puttalam + candidate.Ratnapura + candidate.Trincomalee + 
                             candidate.Vavuniya;
        
        // Check for mismatched totals
        if calculatedTotal != candidate.Totals {
            candidatesWithMismatchedTotals += 1;
            errors.push(string `Candidate ${candidate.candidateId}: Total mismatch - calculated: ${calculatedTotal}, stored: ${candidate.Totals}`);
        }
        
        // Check for negative votes
        int[] districtVotes = [
            candidate.Ampara, candidate.Anuradhapura, candidate.Badulla, candidate.Batticaloa, 
            candidate.Colombo, candidate.Galle, candidate.Gampaha, candidate.Hambantota, 
            candidate.Jaffna, candidate.Kalutara, candidate.Kandy, candidate.Kegalle, 
            candidate.Kilinochchi, candidate.Kurunegala, candidate.Mannar, candidate.Matale, 
            candidate.Matara, candidate.Monaragala, candidate.Mullaitivu, candidate.NuwaraEliya, 
            candidate.Polonnaruwa, candidate.Puttalam, candidate.Ratnapura, candidate.Trincomalee, 
            candidate.Vavuniya, candidate.Totals
        ];
        
        foreach int votes in districtVotes {
            if votes < 0 {
                candidatesWithNegativeVotes += 1;
                errors.push(string `Candidate ${candidate.candidateId}: Negative votes detected`);
                break;
            }
        }
        
        // Check for missing candidate data
        store:Candidate|persist:Error candidateResult = dbClient->/candidates/[candidate.candidateId].get();
        if candidateResult is persist:Error {
            candidatesWithMissingData += 1;
            errors.push(string `Candidate ${candidate.candidateId}: Missing candidate details`);
        }
    });
    
    check resultStream.close();
    
    if processError is error {
        return processError;
    }
    
    boolean isValid = errors.length() == 0;
    
    return {
        isValid: isValid,
        errors: errors,
        statistics: {
            candidatesWithMismatchedTotals: candidatesWithMismatchedTotals,
            candidatesWithNegativeVotes: candidatesWithNegativeVotes,
            candidatesWithMissingData: candidatesWithMissingData
        }
    };
}