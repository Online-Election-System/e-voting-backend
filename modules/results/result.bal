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

    // Sum all district votes using proper field access (lowercase names)
    int totalVotes = candidate.ampara + candidate.anuradhapura + candidate.badulla + 
                    candidate.batticaloa + candidate.colombo + candidate.galle + 
                    candidate.gampaha + candidate.hambantota + candidate.jaffna + 
                    candidate.kalutara + candidate.kandy + candidate.kegalle + 
                    candidate.kilinochchi + candidate.kurunegala + candidate.mannar + 
                    candidate.matale + candidate.matara + candidate.monaragala + 
                    candidate.mullaitivu + candidate.nuwaraeliya + candidate.polonnaruwa + 
                    candidate.puttalam + candidate.ratnapura + candidate.trincomalee + 
                    candidate.vavuniya;

    // Use the correct update type from the generated client
    store:CandidateDistrictVoteSummaryUpdate updateData = {
        totals: totalVotes
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
    sql:ParameterizedQuery orderByClause = `totals DESC`;

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
            totals: candidate.totals
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
    sql:ParameterizedQuery orderByClause = `totals DESC`;

    stream<store:CandidateDistrictVoteSummary, persist:Error?> resultStream = 
        dbClient->/candidatedistrictvotesummaries.get(
            whereClause = whereClause,
            orderByClause = orderByClause
        );
    
    CandidateTotal[] candidates = [];
    error? processError = resultStream.forEach(function(store:CandidateDistrictVoteSummary candidate) {
        CandidateTotal candidateTotal = {
            candidateId: candidate.candidateId,
            totals: candidate.totals
        };
        candidates.push(candidateTotal);
    }); // Added missing closing brace and semicolon
    
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
        grandTotalVotes += candidate.totals;
    }
    
    // Create candidate summaries with percentages and ranks
    CandidateVoteSummary[] candidateSummaries = [];
    foreach int i in 0 ..< candidates.length() {
        CandidateTotal candidate = candidates[i];
        decimal percentage = 0.0;
        if grandTotalVotes > 0 {
            percentage = <decimal>candidate.totals / <decimal>grandTotalVotes * 100.0;
        }
        
        CandidateVoteSummary summary = {
            candidateId: candidate.candidateId,
            candidateName: (),
            totalVotes: candidate.totals,
            percentage: percentage,
            rank: i + 1
        };
        
        candidateSummaries.push(summary);
    }
    
    return candidateSummaries; // Return the calculated summaries instead of ()
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


public function calculateCandidateDistrictAnalysis(string electionId, store:Client dbClient) returns CandidateDistrictAnalysis[]|error {
    
    sql:ParameterizedQuery whereClause = `election_id = ${electionId}`;

    stream<store:CandidateDistrictVoteSummary, persist:Error?> resultStream = 
        dbClient->/candidatedistrictvotesummaries.get(whereClause = whereClause);
    
    CandidateDistrictAnalysis[] analyses = [];

    error? processError = resultStream.forEach(function(store:CandidateDistrictVoteSummary candidateData) {
        string candidateId = candidateData.candidateId;
        int totalVotes = candidateData.totals;
        
        // Create district votes map (using lowercase field names)
        map<int> districtVotes = {
            "Ampara": candidateData.ampara,
            "Anuradhapura": candidateData.anuradhapura,
            "Badulla": candidateData.badulla,
            "Batticaloa": candidateData.batticaloa,
            "Colombo": candidateData.colombo,
            "Galle": candidateData.galle,
            "Gampaha": candidateData.gampaha,
            "Hambantota": candidateData.hambantota,
            "Jaffna": candidateData.jaffna,
            "Kalutara": candidateData.kalutara,
            "Kandy": candidateData.kandy,
            "Kegalle": candidateData.kegalle,
            "Kilinochchi": candidateData.kilinochchi,
            "Kurunegala": candidateData.kurunegala,
            "Mannar": candidateData.mannar,
            "Matale": candidateData.matale,
            "Matara": candidateData.matara,
            "Monaragala": candidateData.monaragala,
            "Mullaitivu": candidateData.mullaitivu,
            "NuwaraEliya": candidateData.nuwaraeliya,
            "Polonnaruwa": candidateData.polonnaruwa,
            "Puttalam": candidateData.puttalam,
            "Ratnapura": candidateData.ratnapura,
            "Trincomalee": candidateData.trincomalee,
            "Vavuniya": candidateData.vavuniya
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
        ampara: 0,
        anuradhapura: 0,
        badulla: 0,
        batticaloa: 0,
        colombo: 0,
        galle: 0,
        gampaha: 0,
        hambantota: 0,
        jaffna: 0,
        kalutara: 0,
        kandy: 0,
        kegalle: 0,
        kilinochchi: 0,
        kurunegala: 0,
        mannar: 0,
        matale: 0,
        matara: 0,
        monaragala: 0,
        mullaitivu: 0,
        nuwaraeliya: 0,
        polonnaruwa: 0,
        puttalam: 0,
        ratnapura: 0,
        trincomalee: 0,
        vavuniya: 0,
        grandTotal: 0
    };
    
    // Filter records for the specific election and sum up votes by district
    foreach CandidateDistrictVoteSummary candidate in candidateVotes {
        if (candidate.electionId == electionId) {
            districtTotals.ampara += candidate.ampara;
            districtTotals.anuradhapura += candidate.anuradhapura;
            districtTotals.badulla += candidate.badulla;
            districtTotals.batticaloa += candidate.batticaloa;
            districtTotals.colombo += candidate.colombo;
            districtTotals.galle += candidate.galle;
            districtTotals.gampaha += candidate.gampaha;
            districtTotals.hambantota += candidate.hambantota;
            districtTotals.jaffna += candidate.jaffna;
            districtTotals.kalutara += candidate.kalutara;
            districtTotals.kandy += candidate.kandy;
            districtTotals.kegalle += candidate.kegalle;
            districtTotals.kilinochchi += candidate.kilinochchi;
            districtTotals.kurunegala += candidate.kurunegala;
            districtTotals.mannar += candidate.mannar;
            districtTotals.matale += candidate.matale;
            districtTotals.matara += candidate.matara;
            districtTotals.monaragala += candidate.monaragala;
            districtTotals.mullaitivu += candidate.mullaitivu;
            districtTotals.nuwaraeliya += candidate.nuwaraeliya;
            districtTotals.polonnaruwa += candidate.polonnaruwa;
            districtTotals.puttalam += candidate.puttalam;
            districtTotals.ratnapura += candidate.ratnapura;
            districtTotals.trincomalee += candidate.trincomalee;
            districtTotals.vavuniya += candidate.vavuniya;
        }
    }
    
    // Calculate grand total
    districtTotals.grandTotal = districtTotals.ampara + districtTotals.anuradhapura + 
                               districtTotals.badulla + districtTotals.batticaloa + 
                               districtTotals.colombo + districtTotals.galle + 
                               districtTotals.gampaha + districtTotals.hambantota + 
                               districtTotals.jaffna + districtTotals.kalutara + 
                               districtTotals.kandy + districtTotals.kegalle + 
                               districtTotals.kilinochchi + districtTotals.kurunegala + 
                               districtTotals.mannar + districtTotals.matale + 
                               districtTotals.matara + districtTotals.monaragala + 
                               districtTotals.mullaitivu + districtTotals.nuwaraeliya + 
                               districtTotals.polonnaruwa + districtTotals.puttalam + 
                               districtTotals.ratnapura + districtTotals.trincomalee + 
                               districtTotals.vavuniya;
    
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
    sql:ParameterizedQuery orderByClause = `totals DESC`;

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
        grandTotalVotes += vs.totals;
    }
    
    // Process each candidate
    CandidateExportData[] exportData = [];
    
    foreach int i in 0 ..< voteSummaries.length() {
        store:CandidateDistrictVoteSummary vs = voteSummaries[i];
        string candidateId = vs.candidateId;
        int totalVotes = vs.totals;
        
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
        "Ampara" => { return vs.ampara; }
        "Anuradhapura" => { return vs.anuradhapura; }
        "Badulla" => { return vs.badulla; }
        "Batticaloa" => { return vs.batticaloa; }
        "Colombo" => { return vs.colombo; }
        "Galle" => { return vs.galle; }
        "Gampaha" => { return vs.gampaha; }
        "Hambantota" => { return vs.hambantota; }
        "Jaffna" => { return vs.jaffna; }
        "Kalutara" => { return vs.kalutara; }
        "Kandy" => { return vs.kandy; }
        "Kegalle" => { return vs.kegalle; }
        "Kilinochchi" => { return vs.kilinochchi; }
        "Kurunegala" => { return vs.kurunegala; }
        "Mannar" => { return vs.mannar; }
        "Matale" => { return vs.matale; }
        "Matara" => { return vs.matara; }
        "Monaragala" => { return vs.monaragala; }
        "Mullaitivu" => { return vs.mullaitivu; }
        "NuwaraEliya" => { return vs.nuwaraeliya; }
        "Polonnaruwa" => { return vs.polonnaruwa; }
        "Puttalam" => { return vs.puttalam; }
        "Ratnapura" => { return vs.ratnapura; }
        "Trincomalee" => { return vs.trincomalee; }
        "Vavuniya" => { return vs.vavuniya; }
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
        ampara: <int>data["ampara"],
        anuradhapura: <int>data["anuradhapura"],
        badulla: <int>data["badulla"],
        batticaloa: <int>data["batticaloa"],
        colombo: <int>data["colombo"],
        galle: <int>data["galle"],
        gampaha: <int>data["gampaha"],
        hambantota: <int>data["hambantota"],
        jaffna: <int>data["jaffna"],
        kalutara: <int>data["kalutara"],
        kandy: <int>data["kandy"],
        kegalle: <int>data["kegalle"],
        kilinochchi: <int>data["kilinochchi"],
        kurunegala: <int>data["kurunegala"],
        mannar: <int>data["mannar"],
        matale: <int>data["matale"],
        matara: <int>data["matara"],
        monaragala: <int>data["monaragala"],
        mullaitivu: <int>data["mullaitivu"],
        nuwaraeliya: <int>data["nuwaraeliya"],
        polonnaruwa: <int>data["polonnaruwa"],
        puttalam: <int>data["puttalam"],
        ratnapura: <int>data["ratnapura"],
        trincomalee: <int>data["trincomalee"],
        vavuniya: <int>data["vavuniya"],
        grandTotal: 0
    };
    
    // Calculate grand total
    districtTotals.grandTotal = districtTotals.ampara + districtTotals.anuradhapura + 
                               districtTotals.badulla + districtTotals.batticaloa + 
                               districtTotals.colombo + districtTotals.galle + 
                               districtTotals.gampaha + districtTotals.hambantota + 
                               districtTotals.jaffna + districtTotals.kalutara + 
                               districtTotals.kandy + districtTotals.kegalle + 
                               districtTotals.kilinochchi + districtTotals.kurunegala + 
                               districtTotals.mannar + districtTotals.matale + 
                               districtTotals.matara + districtTotals.monaragala + 
                               districtTotals.mullaitivu + districtTotals.nuwaraeliya + 
                               districtTotals.polonnaruwa + districtTotals.puttalam + 
                               districtTotals.ratnapura + districtTotals.trincomalee + 
                               districtTotals.vavuniya;
    
    return districtTotals;
}

public function batchUpdateCandidateTotals(string electionId, store:Client dbClient) returns error? {
    
    sql:ParameterizedQuery whereClause = `election_id = ${electionId}`;
    stream<store:CandidateDistrictVoteSummary, persist:Error?> resultStream = 
        dbClient->/candidatedistrictvotesummaries.get(whereClause = whereClause);
    
    error? processError = resultStream.forEach(function(store:CandidateDistrictVoteSummary candidate) {
        int totalVotes = candidate.ampara + candidate.anuradhapura + candidate.badulla + 
                        candidate.batticaloa + candidate.colombo + candidate.galle + 
                        candidate.gampaha + candidate.hambantota + candidate.jaffna + 
                        candidate.kalutara + candidate.kandy + candidate.kegalle + 
                        candidate.kilinochchi + candidate.kurunegala + candidate.mannar + 
                        candidate.matale + candidate.matara + candidate.monaragala + 
                        candidate.mullaitivu + candidate.nuwaraeliya + candidate.polonnaruwa + 
                        candidate.puttalam + candidate.ratnapura + candidate.trincomalee + 
                        candidate.vavuniya;
        
        if totalVotes != candidate.totals {
            // Update the total if it's different
            store:CandidateDistrictVoteSummaryUpdate updateData = { totals: totalVotes };
            var updateResult = dbClient->/candidatedistrictvotesummaries/[candidate.electionId]/[candidate.candidateId].put(updateData);
            
            // Handle the update result
            if updateResult is error {
                // You can log the error or handle it as needed
                // For now, we'll just ignore individual update errors
                // but you could also return the error to stop processing
            }
        }
    }); // Added missing closing brace and semicolon
    
    check resultStream.close();
    
    if processError is error {
        return processError;
    }
    
    return ();
}