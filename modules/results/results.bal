// results.bal - Complete Data Types and Business Logic
import online_election.store;
import ballerina/persist;
import ballerina/crypto;
import ballerina/log;
import ballerina/time;
import ballerina/io;

final store:Client db = check new ();



// District names mapping (Sri Lankan districts)
final readonly & string[] DISTRICTS = [
    "Ampara", "Anuradhapura", "Badulla", "Batticaloa", "Colombo", 
    "Galle", "Gampaha", "Hambantota", "Jaffna", "Kalutara", 
    "Kandy", "Kegalle", "Kilinochchi", "Kurunegala", "Mannar", 
    "Matale", "Matara", "Monaragala", "Mullaitivu", "Nuwaraeliya", 
    "Polonnaruwa", "Puttalam", "Ratnapura", "Trincomalee", "Vavuniya"
];

// Function to initialize results when election starts or when needed
public function ensureElectionResultsInitialized(string electionId) returns error? {
    // Check if results already exist
    stream<store:CandidateDistrictVoteSummary, persist:Error?> existingResultsStream = db->/candidatedistrictvotesummaries;
    store:CandidateDistrictVoteSummary[] existingResults = check from store:CandidateDistrictVoteSummary result in existingResultsStream
        where result.electionId == electionId
        select result;
    
    if existingResults.length() == 0 {
        io:println("No existing results found for election: ", electionId, " - initializing...");
        return initializeElectionResults(electionId);
    } else {
        io:println("Results already initialized for election: ", electionId, " (", existingResults.length().toString(), " candidates)");
    }
}

// Function to initialize results table with all enrolled candidates (all districts = 0)
public function initializeElectionResults(string electionId) returns error? {
    io:println("Initializing election results for election: ", electionId);
    
    // Get all enrolled candidates for this election
    stream<store:EnrolCandidates, persist:Error?> enrolmentStream = db->/enrolcandidates;
    store:EnrolCandidates[] enrolments = check from store:EnrolCandidates enrolment in enrolmentStream
        where enrolment.electionId == electionId
        select enrolment;
    
    io:println("Found ", enrolments.length().toString(), " enrolled candidates");
    
    // Delete any existing results for this election first
    stream<store:CandidateDistrictVoteSummary, persist:Error?> existingResultsStream = db->/candidatedistrictvotesummaries;
    store:CandidateDistrictVoteSummary[] existingResults = check from store:CandidateDistrictVoteSummary result in existingResultsStream
        where result.electionId == electionId
        select result;
    
    foreach store:CandidateDistrictVoteSummary existingResult in existingResults {
        _ = check db->/candidatedistrictvotesummaries/[existingResult.electionId]/[existingResult.candidateId].delete();
    }
    io:println("Cleared existing results for election: ", electionId);
    
    // Create initial records for all enrolled candidates with all districts = 0
    store:CandidateDistrictVoteSummary[] initialResults = [];
    
    foreach store:EnrolCandidates enrolment in enrolments {
        store:CandidateDistrictVoteSummary initialSummary = {
            electionId: electionId,
            candidateId: enrolment.candidateId, // Use original candidate ID as key
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
            totals: 0
        };
        
        initialResults.push(initialSummary);
        io:println("Initialized candidate: ", enrolment.candidateId, " with all districts = 0");
    }
    
    // Insert all initial records
    [string, string][]|persist:Error insertResult = db->/candidatedistrictvotesummaries.post(initialResults);
    if insertResult is persist:Error {
        return error("Failed to initialize election results: " + insertResult.message());
    }
    
    io:println("✅ Successfully initialized ", initialResults.length().toString(), " candidate results for election: ", electionId);
}

// Real-time Updates Functions

// Function to update results when a vote is cast
public function updateResultsForVote(store:Vote vote) returns error? {
    io:println("=== DETAILED RESULTS UPDATE DEBUG ===");
    io:println("Vote ID: ", vote.id);
    io:println("Election ID: ", vote.electionId);
    io:println("Candidate ID from vote: ", vote.candidateId);
    io:println("District: ", vote.district);
    
    // Step 1: Determine if candidate ID is hashed or original
    io:println("--- Step 1: Checking Candidate ID Format ---");
    
    // Check if this looks like a hash (64 characters, hex)
    boolean looksLikeHash = vote.candidateId.length() == 64;
    string originalCandidateId = "";
    
    if looksLikeHash {
        io:println("Candidate ID appears to be hashed (64 chars), finding original...");
        string? foundOriginalId = getOriginalCandidateId(vote.candidateId, vote.electionId);
        if foundOriginalId is () {
            io:println("❌ FAILED: Could not find original candidate ID for hash: ", vote.candidateId);
            return error("Invalid candidate ID in vote: " + vote.candidateId);
        }
        originalCandidateId = foundOriginalId;
        io:println("✅ Found original candidate ID: ", originalCandidateId);
    } else {
        io:println("Candidate ID appears to be original (not hashed), using directly: ", vote.candidateId);
        originalCandidateId = vote.candidateId;
        
        // Verify this candidate is enrolled
        stream<store:EnrolCandidates, persist:Error?> enrolmentStream = db->/enrolcandidates;
        store:EnrolCandidates[] enrolments = check from store:EnrolCandidates enrolment in enrolmentStream
            where enrolment.electionId == vote.electionId && enrolment.candidateId == originalCandidateId
            select enrolment;
        
        if enrolments.length() == 0 {
            io:println("❌ FAILED: Candidate not enrolled: ", originalCandidateId);
            return error("Candidate not enrolled in election: " + originalCandidateId);
        }
        io:println("✅ Candidate is enrolled: ", originalCandidateId);
    }

    // Step 2: Normalize district name
    io:println("--- Step 2: Normalizing District ---");
    string normalizedDistrict = normalizeDistrictName(vote.district);
    io:println("Original district: ", vote.district);
    io:println("Normalized district: ", normalizedDistrict);
    
    // Step 3: Check if district is valid
    boolean isValidDistrict = false;
    foreach string district in DISTRICTS {
        if district == normalizedDistrict {
            isValidDistrict = true;
            break;
        }
    }
    io:println("District is valid: ", isValidDistrict.toString());
    
    if !isValidDistrict {
        io:println("❌ FAILED: Invalid district - ", normalizedDistrict);
        return error("Invalid district: " + normalizedDistrict);
    }

    // Step 3: Try to get existing summary
    io:println("--- Step 3: Getting Existing Summary ---");
    io:println("Looking for summary with electionId: ", vote.electionId, " and candidateId: ", originalCandidateId);
    
    store:CandidateDistrictVoteSummary|persist:Error existingSummary = 
        db->/candidatedistrictvotesummaries/[vote.electionId]/[originalCandidateId].get();
    
    if existingSummary is store:CandidateDistrictVoteSummary {
        io:println("✅ Found existing summary for candidate: ", originalCandidateId);
        io:println("Current totals: ", existingSummary.totals.toString());
        
        // Get current count for the district
        int currentCount = getDistrictCount(existingSummary, normalizedDistrict);
        io:println("Current count for ", normalizedDistrict, ": ", currentCount.toString());
        
        int newCount = currentCount + 1;
        io:println("New count will be: ", newCount.toString());
        
        // Step 4: Create update record
        io:println("--- Step 4: Creating Update Record ---");
        store:CandidateDistrictVoteSummaryUpdate updateData = createUpdateRecord(existingSummary, normalizedDistrict, newCount);
        io:println("Update record created successfully");
        
        // Step 5: Update in database
        io:println("--- Step 5: Updating Database ---");
        io:println("Updating with electionId: ", vote.electionId, " and candidateId: ", originalCandidateId);
        
        store:CandidateDistrictVoteSummary|persist:Error updateResult = db->/candidatedistrictvotesummaries/[vote.electionId]/[originalCandidateId].put(updateData);
        
        if updateResult is persist:Error {
            io:println("❌ FAILED: Database update failed");
            io:println("Error: ", updateResult.message());
            io:println("Error details: ", updateResult.toString());
            return error("Failed to update database: " + updateResult.message());
        } else {
            io:println("✅ Database update successful!");
            io:println("Updated ", normalizedDistrict, " from ", currentCount.toString(), " to ", newCount.toString());
            
            // Verify the update by reading back
            io:println("--- Step 6: Verifying Update ---");
            store:CandidateDistrictVoteSummary|persist:Error verifyResult = 
                db->/candidatedistrictvotesummaries/[vote.electionId]/[originalCandidateId].get();
            
            if verifyResult is store:CandidateDistrictVoteSummary {
                int verifyCount = getDistrictCount(verifyResult, normalizedDistrict);
                io:println("Verification - ", normalizedDistrict, " count is now: ", verifyCount.toString());
                io:println("Verification - Total votes: ", verifyResult.totals.toString());
                
                if verifyCount == newCount {
                    io:println("✅ VERIFICATION PASSED: Update was successful!");
                } else {
                    io:println("❌ VERIFICATION FAILED: Count mismatch!");
                    return error("Update verification failed");
                }
            } else {
                io:println("❌ VERIFICATION FAILED: Could not read back updated record");
                return error("Could not verify update");
            }
        }
        
    } else {
        io:println("❌ No existing summary found for candidate: ", originalCandidateId);
        io:println("Error details: ", existingSummary.message());
        io:println("--- Attempting to initialize election results ---");
        
        // Try to initialize the election results first
        error? initResult = initializeElectionResults(vote.electionId);
        if initResult is error {
            io:println("❌ FAILED: Could not initialize election results");
            io:println("Init error: ", initResult.message());
            return error("Failed to initialize election results: " + initResult.message());
        }
        
        io:println("✅ Election results initialized, retrying update...");
        // Recursive call after initialization
        return updateResultsForVote(vote);
    }
    
    io:println("=== RESULTS UPDATE COMPLETED SUCCESSFULLY ===");
}

// Helper function to get district count using match statement
function getDistrictCount(store:CandidateDistrictVoteSummary summary, string district) returns int {
    match district {
        "Ampara" => { return summary.ampara; }
        "Anuradhapura" => { return summary.anuradhapura; }
        "Badulla" => { return summary.badulla; }
        "Batticaloa" => { return summary.batticaloa; }
        "Colombo" => { return summary.colombo; }
        "Galle" => { return summary.galle; }
        "Gampaha" => { return summary.gampaha; }
        "Hambantota" => { return summary.hambantota; }
        "Jaffna" => { return summary.jaffna; }
        "Kalutara" => { return summary.kalutara; }
        "Kandy" => { return summary.kandy; }
        "Kegalle" => { return summary.kegalle; }
        "Kilinochchi" => { return summary.kilinochchi; }
        "Kurunegala" => { return summary.kurunegala; }
        "Mannar" => { return summary.mannar; }
        "Matale" => { return summary.matale; }
        "Matara" => { return summary.matara; }
        "Monaragala" => { return summary.monaragala; }
        "Mullaitivu" => { return summary.mullaitivu; }
        "Nuwaraeliya" => { return summary.nuwaraeliya; }
        "Polonnaruwa" => { return summary.polonnaruwa; }
        "Puttalam" => { return summary.puttalam; }
        "Ratnapura" => { return summary.ratnapura; }
        "Trincomalee" => { return summary.trincomalee; }
        "Vavuniya" => { return summary.vavuniya ; }
        _ => { return 0; }
    }
}

// Helper function to set district count
function setDistrictCount(store:CandidateDistrictVoteSummary summary, string district, int count) returns store:CandidateDistrictVoteSummary {
    match district {
        "Ampara" => { summary.ampara = count; }
        "Anuradhapura" => { summary.anuradhapura = count; }
        "Badulla" => { summary.badulla = count; }
        "Batticaloa" => { summary.batticaloa = count; }
        "Colombo" => { summary.colombo = count; }
        "Galle" => { summary.galle = count; }
        "Gampaha" => { summary.gampaha = count; }
        "Hambantota" => { summary.hambantota = count; }
        "Jaffna" => { summary.jaffna = count; }
        "Kalutara" => { summary.kalutara = count; }
        "Kandy" => { summary.kandy = count; }
        "Kegalle" => { summary.kegalle = count; }
        "Kilinochchi" => { summary.kilinochchi = count; }
        "Kurunegala" => { summary.kurunegala = count; }
        "Mannar" => { summary.mannar = count; }
        "Matale" => { summary.matale = count; }
        "Matara" => { summary.matara = count; }
        "Monaragala" => { summary.monaragala = count; }
        "Mullaitivu" => { summary.mullaitivu = count; }
        "Nuwaraeliya" => { summary.nuwaraeliya = count; }
        "Polonnaruwa" => { summary.polonnaruwa = count; }
        "Puttalam" => { summary.puttalam = count; }
        "Ratnapura" => { summary.ratnapura = count; }
        "Trincomalee" => { summary.trincomalee = count; }
        "Vavuniya" => { summary.vavuniya = count; }
    }
    return summary;
}

// Helper function to create update record
function createUpdateRecord(store:CandidateDistrictVoteSummary existing, string district, int newCount) returns store:CandidateDistrictVoteSummaryUpdate {
    store:CandidateDistrictVoteSummaryUpdate updateData = {
        ampara: existing.ampara,
        anuradhapura: existing.anuradhapura,
        badulla: existing.badulla,
        batticaloa: existing.batticaloa,
        colombo: existing.colombo,
        galle: existing.galle,
        gampaha: existing.gampaha,
        hambantota: existing.hambantota,
        jaffna: existing.jaffna,
        kalutara: existing.kalutara,
        kandy: existing.kandy,
        kegalle: existing.kegalle,
        kilinochchi: existing.kilinochchi,
        kurunegala: existing.kurunegala,
        mannar: existing.mannar,
        matale: existing.matale,
        matara: existing.matara,
        monaragala: existing.monaragala,
        mullaitivu: existing.mullaitivu,
        nuwaraeliya: existing.nuwaraeliya,
        polonnaruwa: existing.polonnaruwa,
        puttalam: existing.puttalam,
        ratnapura: existing.ratnapura,
        trincomalee: existing.trincomalee,
        vavuniya: existing.vavuniya,
        totals: existing.totals + 1
    };
    
    // Update the specific district count
    match district {
        "Ampara" => { updateData.ampara = newCount; }
        "Anuradhapura" => { updateData.anuradhapura = newCount; }
        "Badulla" => { updateData.badulla = newCount; }
        "Batticaloa" => { updateData.batticaloa = newCount; }
        "Colombo" => { updateData.colombo = newCount; }
        "Galle" => { updateData.galle = newCount; }
        "Gampaha" => { updateData.gampaha = newCount; }
        "Hambantota" => { updateData.hambantota = newCount; }
        "Jaffna" => { updateData.jaffna = newCount; }
        "Kalutara" => { updateData.kalutara = newCount; }
        "Kandy" => { updateData.kandy = newCount; }
        "Kegalle" => { updateData.kegalle = newCount; }
        "Kilinochchi" => { updateData.kilinochchi = newCount; }
        "Kurunegala" => { updateData.kurunegala = newCount; }
        "Mannar" => { updateData.mannar = newCount; }
        "Matale" => { updateData.matale = newCount; }
        "Matara" => { updateData.matara = newCount; }
        "Monaragala" => { updateData.monaragala = newCount; }
        "Mullaitivu" => { updateData.mullaitivu = newCount; }
        "Nuwaraeliya" => { updateData.nuwaraeliya = newCount; }
        "Polonnaruwa" => { updateData.polonnaruwa = newCount; }
        "Puttalam" => { updateData.puttalam = newCount; }
        "Ratnapura" => { updateData.ratnapura = newCount; }
        "Trincomalee" => { updateData.trincomalee = newCount; }
        "Vavuniya" => { updateData.vavuniya = newCount; }
    }
    
    return updateData;
}

// Debug function to check current state of results table
public function debugResultsTableState(string electionId) returns json|error {
    io:println("=== DEBUGGING RESULTS TABLE STATE ===");
    io:println("Election ID: ", electionId);
    
    // Get all results for this election
    stream<store:CandidateDistrictVoteSummary, persist:Error?> resultsStream = db->/candidatedistrictvotesummaries;
    store:CandidateDistrictVoteSummary[] results = check from store:CandidateDistrictVoteSummary result in resultsStream
        where result.electionId == electionId
        select result;
    
    io:println("Found ", results.length().toString(), " result records for election: ", electionId);
    
    json[] resultDetails = [];
    foreach store:CandidateDistrictVoteSummary result in results {
        io:println("Candidate: ", result.candidateId, " | Totals: ", result.totals.toString());
        io:println("  Colombo: ", result.colombo.toString(), " | Kandy: ", result.kandy.toString(), " | Galle: ", result.galle.toString());
        
        resultDetails.push({
            "candidateId": result.candidateId,
            "totals": result.totals,
            "colombo": result.colombo,
            "kandy": result.kandy,
            "galle": result.galle
        });
    }
    
    // Also check votes in vote table
    stream<store:Vote, persist:Error?> voteStream = db->/votes;
    store:Vote[] votes = check from store:Vote vote in voteStream
        where vote.electionId == electionId
        select vote;
    
    io:println("Found ", votes.length().toString(), " votes in vote table for election: ", electionId);
    
    return {
        "electionId": electionId,
        "resultRecords": results.length(),
        "voteRecords": votes.length(),
        "details": resultDetails
    };
}

// Helper function to get original candidate ID from hash
function getOriginalCandidateId(string hashedCandidateId, string electionId) returns string? {
    io:println("Looking for original candidate ID for hash: ", hashedCandidateId);
    io:println("In election: ", electionId);
    
    stream<store:EnrolCandidates, persist:Error?> enrolmentStream = db->/enrolcandidates;
    store:EnrolCandidates[]|error enrolments = from store:EnrolCandidates enrolment in enrolmentStream
        where enrolment.electionId == electionId
        select enrolment;
    
    if enrolments is error {
        io:println("Error getting enrolments: ", enrolments.message());
        return ();
    }
    
    io:println("Found ", enrolments.length().toString(), " enrolled candidates to check");
    
    foreach store:EnrolCandidates enrolment in enrolments {
        // Hash the original candidate ID to compare with the stored hash
        byte[] candidateHash = crypto:hashSha256(enrolment.candidateId.toBytes());
        string computedHash = candidateHash.toBase16();
        
        io:println("Checking candidate: ", enrolment.candidateId);
        io:println("  Original ID: ", enrolment.candidateId);
        io:println("  Computed hash: ", computedHash);
        io:println("  Vote hash: ", hashedCandidateId);
        io:println("  Match: ", (computedHash == hashedCandidateId).toString());
        
        if computedHash == hashedCandidateId {
            io:println("✓ Found matching candidate: ", enrolment.candidateId);
            return enrolment.candidateId;
        }
    }
    
    io:println("❌ No matching candidate found for hash: ", hashedCandidateId);
    return ();
}

// Scheduled Updates Functions

// Function to update results for ongoing elections
public function updateOngoingElectionResults() returns error? {
    io:println("Starting scheduled update of ongoing election results");
    
    // Get all ongoing elections
    stream<store:Election, persist:Error?> electionStream = db->/elections;
    store:Election[]|error elections = from store:Election election in electionStream
        select election;
    
    if elections is error {
        return elections;
    }
    
    time:Date today = time:utcToCivil(time:utcNow());
    
    foreach store:Election election in elections {
        // Check if election is ongoing (started but not ended)
        if !isDateAfter(today, election.startDate) || isDateAfter(today, election.endDate) {
            continue; // Skip elections that haven't started or have ended
        }
        
        io:println("Updating results for ongoing election: ", election.electionName);
        // Update results for this ongoing election
        _ = check calculateElectionResultsForOngoing(election.id);
    }
    
    io:println("Completed scheduled update of ongoing election results");
}

// Modified calculation function that works for ongoing elections
function calculateElectionResultsForOngoing(string electionId) returns store:CandidateDistrictVoteSummary[]|error {
    io:println("Calculating results for ongoing election: ", electionId);
    
    // Get all enrolled candidates for this election
    stream<store:EnrolCandidates, persist:Error?> enrolmentStream = db->/enrolcandidates;
    store:EnrolCandidates[] enrolments = check from store:EnrolCandidates enrolment in enrolmentStream
        where enrolment.electionId == electionId
        select enrolment;

    // Create map of hashed candidate IDs to original IDs
    map<string> hashedCandidateMap = {};
    foreach store:EnrolCandidates enrolment in enrolments {
        byte[] hashedId = crypto:hashSha256(enrolment.candidateId.toBytes());
        hashedCandidateMap[hashedId.toBase16()] = enrolment.candidateId;
    }

    // Get all votes for this election
    stream<store:Vote, persist:Error?> voteStream = db->/votes;
    store:Vote[] votes = check from store:Vote vote in voteStream
        where vote.electionId == electionId
        select vote;

    // Aggregate votes by candidate and district
    map<map<int>> candidateDistrictCounts = {};
    foreach store:Vote vote in votes {
        string? originalCandidateId = hashedCandidateMap[vote.candidateId];
        if originalCandidateId is () {
            log:printWarn("Vote found for non-enrolled candidate: " + vote.candidateId);
            continue;
        }

        if !candidateDistrictCounts.hasKey(originalCandidateId) {
            candidateDistrictCounts[originalCandidateId] = {};
        }

        map<int>? districtCountsOptional = candidateDistrictCounts[originalCandidateId];
        if districtCountsOptional is () {
            continue;
        }
        map<int> districtCounts = districtCountsOptional;
        
        string normalizedDistrict = normalizeDistrictName(vote.district);
        int currentCount = districtCounts.get(normalizedDistrict) is int ? districtCounts.get(normalizedDistrict) : 0;
        districtCounts[normalizedDistrict] = currentCount + 1;
    }

    // Convert to CandidateDistrictVoteSummary records
    store:CandidateDistrictVoteSummary[] results = [];
    foreach var [candidateId, districtCounts] in candidateDistrictCounts.entries() {
        store:CandidateDistrictVoteSummary summary = {
            electionId: electionId,
            candidateId: candidateId,
            ampara: 0, anuradhapura: 0, badulla: 0, batticaloa: 0, colombo: 0,
            galle: 0, gampaha: 0, hambantota: 0, jaffna: 0, kalutara: 0,
            kandy: 0, kegalle: 0, kilinochchi: 0, kurunegala: 0, mannar: 0,
            matale: 0, matara: 0, monaragala: 0, mullaitivu: 0, nuwaraeliya: 0,
            polonnaruwa: 0, puttalam: 0, ratnapura: 0, trincomalee: 0, vavuniya: 0,
            totals: 0
        };

        // Set counts for districts that have votes
        foreach var [district, count] in districtCounts.entries() {
            summary = setDistrictCount(summary, district, count);
            summary.totals += count;
        }

        results.push(summary);
    }

    // Delete old results for this election
    stream<store:CandidateDistrictVoteSummary, persist:Error?> oldSummariesStream = db->/candidatedistrictvotesummaries;
    store:CandidateDistrictVoteSummary[] oldSummaries = check from store:CandidateDistrictVoteSummary s in oldSummariesStream
        where s.electionId == electionId
        select s;

    foreach store:CandidateDistrictVoteSummary s in oldSummaries {
        _ = check db->/candidatedistrictvotesummaries/[s.electionId]/[s.candidateId].delete();
    }

    // Store new results
    [string, string][]|persist:Error insertResult = db->/candidatedistrictvotesummaries.post(results);
    if insertResult is persist:Error {
        return error("Failed to store results: " + insertResult.message());
    }

    io:println("Successfully updated results for election: ", electionId, " with ", results.length(), " candidate summaries");
    return results;
}

// // Business Logic Functions

// public function getDistrictResults(string electionId, string districtId) returns DistrictResults|error {
//     // Get election results summary
//     store:CandidateDistrictVoteSummary[]|error summaries = getElectionResults(electionId);
//     if summaries is error {
//         return error("Failed to get election results: " + summaries.message());
//     }

//     string normalizedDistrict = normalizeDistrictName(districtId);
    
//     // Validate district exists
//     if !DISTRICTS.some(d => d == normalizedDistrict) {
//         return error("Invalid district: " + districtId);
//     }

//     CandidateResult[] candidates = [];
//     int totalVotes = 0;

//     foreach store:CandidateDistrictVoteSummary summary in summaries {
//         // Get candidate details
//         store:Candidate|persist:Error candidate = db->/candidates/[summary.candidateId].get();
//         if candidate is persist:Error {
//             log:printWarn("Candidate not found", candidateId = summary.candidateId);
//             continue;
//         }

//         // Get votes for this district
//         int votes = getDistrictCount(summary, normalizedDistrict);
//         totalVotes += votes;

//         if votes > 0 {
//             candidates.push({
//                 candidate_id: summary.candidateId,
//                 candidate_name: candidate.candidateName,
//                 party: candidate.partyName,
//                 party_symbol: candidate.partySymbol,
//                 party_color: candidate.partyColor,
//                 votes: votes,
//                 percentage: 0.0d, // Will be calculated after sorting
//                 rank: 0 // Will be set after sorting
//             });
//         }
//     }

//     // Calculate percentages and sort
//     candidates = sortCandidatesByVotes(candidates, totalVotes);

//     return {
//         election_id: electionId,
//         district_id: districtId,
//         district_name: normalizedDistrict,
//         total_votes: totalVotes,
//         candidates: candidates
//     };
// }

// public function getAllDistrictResults(string electionId) returns ElectionDistrictResults|error {
//     map<DistrictResults> districtResults = {};
//     int totalElectionVotes = 0;

//     foreach string district in DISTRICTS {
//         DistrictResults|error result = getDistrictResults(electionId, district);
//         if result is DistrictResults {
//             districtResults[district] = result;
//             totalElectionVotes += result.total_votes;
//         }
//     }

//     return {
//         election_id: electionId,
//         districts: districtResults,
//         total_districts: districtResults.length(),
//         total_votes: totalElectionVotes
//     };
// }

// public function getCandidateDistrictPerformance(string electionId, string candidateId) returns CandidateDistrictPerformance|error {
//     // Get candidate details
//     store:Candidate|persist:Error candidate = db->/candidates/[candidateId].get();
//     if candidate is persist:Error {
//         return error("Candidate not found: " + candidateId);
//     }

//     // Get candidate's vote summary
//     store:CandidateDistrictVoteSummary|persist:Error summary = 
//         db->/candidatedistrictvotesummaries/[electionId]/[candidateId].get();
//     if summary is persist:Error {
//         return error("Results not found for candidate: " + candidateId);
//     }

//     DistrictPerformance[] districts = [];
//     int districtsWon = 0;
//     int districtsSecond = 0;
//     int districtsThird = 0;

//     foreach string district in DISTRICTS {
//         // Get district results to determine rank
//         DistrictResults|error districtResult = getDistrictResults(electionId, district);
//         if districtResult is error {
//             continue;
//         }

//         // Get candidate votes for this district
//         int votes = getDistrictCount(summary, district);

//         if votes > 0 {
//             // Find candidate's rank in this district
//             int rank = 1;
//             decimal percentage = 0.0d;
//             boolean won = false;

//             foreach CandidateResult c in districtResult.candidates {
//                 if c.candidate_id == candidateId {
//                     rank = c.rank;
//                     percentage = c.percentage;
//                     won = rank == 1;
//                     break;
//                 }
//             }

//             districts.push({
//                 district_id: district,
//                 district_name: district,
//                 votes: votes,
//                 percentage: percentage,
//                 rank: rank,
//                 total_district_votes: districtResult.total_votes,
//                 won: won
//             });

//             // Count performance
//             if rank == 1 {
//                 districtsWon += 1;
//             } else if rank == 2 {
//                 districtsSecond += 1;
//             } else if rank == 3 {
//                 districtsThird += 1;
//             }
//         }
//     }

//     return {
//         election_id: electionId,
//         candidate_id: candidateId,
//         candidate_name: candidate.candidateName,
//         party: candidate.partyName,
//         districts: districts,
//         districts_won: districtsWon,
//         districts_second: districtsSecond,
//         districts_third: districtsThird
//     };
// }

// public function getElectionSummary(string electionId) returns ElectionSummary|error {
//     // Get all district results
//     ElectionDistrictResults|error allResults = getAllDistrictResults(electionId);
//     if allResults is error {
//         return error("Failed to get district results: " + allResults.message());
//     }

//     // Get election results with candidate details
//     map<json>[]|error detailedResults = getElectionResultsWithDetails(electionId);
//     if detailedResults is error {
//         return error("Failed to get detailed results: " + detailedResults.message());
//     }

//     // Build candidate overall results
//     CandidateOverall[] candidates = [];
//     DistrictSummary[] districtSummaries = [];

//     foreach map<json> result in detailedResults {
//         int totalVotes = result["Totals"] is int ? <int>result["Totals"] : 0;
//         decimal percentage = allResults.total_votes > 0 ? 
//             <decimal>totalVotes / <decimal>allResults.total_votes * 100.0d : 0.0d;

//         // Get district performance
//         CandidateDistrictPerformance|error performance = 
//             getCandidateDistrictPerformance(electionId, result["candidateId"].toString());
        
//         int won = 0;
//         int second = 0; 
//         int third = 0;
//         if performance is CandidateDistrictPerformance {
//             won = performance.districts_won;
//             second = performance.districts_second;
//             third = performance.districts_third;
//         }

//         candidates.push({
//             candidate_id: result["candidateId"].toString(),
//             candidate_name: result["candidateName"].toString(),
//             party: result["partyName"].toString(),
//             party_symbol: result["partySymbol"].toString(),
//             party_color: result["partyColor"].toString(),
//             total_votes: totalVotes,
//             percentage: percentage,
//             districts_won: won,
//             districts_second: second,
//             districts_third: third,
//             rank: 0 // Will be set after sorting
//         });
//     }

//     // Sort candidates by total votes and set ranks
//     candidates = sortCandidatesOverallByVotes(candidates);

//     // Create district summaries
//     foreach var [districtId, districtResult] in allResults.districts.entries() {
//         CandidateResult winner = districtResult.candidates.length() > 0 ? 
//             districtResult.candidates[0] : 
//             {candidate_id: "", candidate_name: "", votes: 0, percentage: 0.0d, rank: 1};

//         decimal margin = districtResult.candidates.length() > 1 ? 
//             districtResult.candidates[0].percentage - districtResult.candidates[1].percentage : 
//             100.0d;

//         districtSummaries.push({
//             district_id: districtId,
//             district_name: districtResult.district_name,
//             total_votes: districtResult.total_votes,
//             winner: winner,
//             margin_of_victory: margin,
//             declared: true // Assuming all results are declared
//         });
//     }

//     return {
//         election_id: electionId,
//         total_votes: allResults.total_votes,
//         total_districts: allResults.total_districts,
//         districts_declared: allResults.total_districts,
//         candidates: candidates,
//         district_summaries: districtSummaries
//     };
// }

// public function getCandidateTopDistricts(string electionId, string candidateId, int 'limit) returns CandidateTopDistricts|error {
//     CandidateDistrictPerformance|error performance = getCandidateDistrictPerformance(electionId, candidateId);
//     if performance is error {
//         return performance;
//     }

//     // Sort districts by percentage and limit
//     DistrictPerformance[] sortedDistricts = from DistrictPerformance district in performance.districts
//         order by district.percentage descending
//         select district;

//     DistrictPerformance[] topDistricts = [];
//     int count = 0;
//     foreach DistrictPerformance district in sortedDistricts {
//         if count >= 'limit {
//             break;
//         }
//         topDistricts.push(district);
//         count += 1;
//     }

//     return {
//         election_id: electionId,
//         candidate_id: candidateId,
//         candidate_name: performance.candidate_name,
//         top_districts: topDistricts
//     };
// }

// public function getDistrictRankings(string electionId) returns DistrictRankings|error {
//     ElectionDistrictResults|error allResults = getAllDistrictResults(electionId);
//     if allResults is error {
//         return allResults;
//     }

//     DistrictRanking[] rankings = [];
//     foreach var [districtId, districtResult] in allResults.districts.entries() {
//         rankings.push({
//             district_id: districtId,
//             district_name: districtResult.district_name,
//             total_votes: districtResult.total_votes,
//             rank: 0 // Will be set after sorting
//         });
//     }

//     // Sort by total votes and set ranks
//     DistrictRanking[] sortedRankings = from DistrictRanking ranking in rankings
//         order by ranking.total_votes descending
//         select ranking;

//     foreach int i in 0 ..< sortedRankings.length() {
//         sortedRankings[i].rank = i + 1;
//     }

//     return {
//         election_id: electionId,
//         rankings: sortedRankings
//     };
// }

// public function getCandidateStandings(string electionId) returns CandidateStandings|error {
//     ElectionSummary|error summary = getElectionSummary(electionId);
//     if summary is error {
//         return summary;
//     }

//     return {
//         election_id: electionId,
//         standings: summary.candidates,
//         final_results: summary.districts_declared == summary.total_districts
//     };
// }

// public function compareDistrictResults(string electionId, DistrictComparisonRequest request) returns DistrictComparison|error {
//     map<DistrictResults> comparison = {};
//     int totalVotesCompared = 0;
//     int maxVotes = 0;
//     int minVotes = int:MAX_VALUE;
//     string strongestDistrict = "";
//     string weakestDistrict = "";

//     foreach string districtId in request.district_ids {
//         DistrictResults|error result = getDistrictResults(electionId, districtId);
//         if result is DistrictResults {
//             // Filter by candidate IDs if specified
//             if request.candidate_ids is string[] {
//                 string[] candidateIds = <string[]>request.candidate_ids;
//                 CandidateResult[] filteredCandidates = [];
//                 foreach CandidateResult candidate in result.candidates {
//                     boolean found = false;
//                     foreach string id in candidateIds {
//                         if id == candidate.candidate_id {
//                             found = true;
//                             break;
//                         }
//                     }
//                     if found {
//                         filteredCandidates.push(candidate);
//                     }
//                 }
//                 result.candidates = sortCandidatesByVotes(filteredCandidates, result.total_votes);
//             }

//             comparison[districtId] = result;
//             totalVotesCompared += result.total_votes;

//             if result.total_votes > maxVotes {
//                 maxVotes = result.total_votes;
//                 strongestDistrict = districtId;
//             }
//             if result.total_votes < minVotes {
//                 minVotes = result.total_votes;
//                 weakestDistrict = districtId;
//             }
//         }
//     }

//     decimal averageTurnout = comparison.length() > 0 ? 
//         <decimal>totalVotesCompared / <decimal>comparison.length() : 0.0d;

//     return {
//         election_id: electionId,
//         district_ids: request.district_ids,
//         candidate_ids: request.candidate_ids,
//         comparison: comparison,
//         summary: {
//             strongest_district: strongestDistrict,
//             weakest_district: weakestDistrict,
//             average_turnout: averageTurnout,
//             total_votes_compared: totalVotesCompared
//         }
//     };
// }

// public function getVoteDistribution(string electionId, string districtId) returns VoteDistribution|error {
//     DistrictResults|error result = getDistrictResults(electionId, districtId);
//     if result is error {
//         return result;
//     }

//     DistributionData[] distribution = [];
//     foreach CandidateResult candidate in result.candidates {
//         distribution.push({
//             candidate_id: candidate.candidate_id,
//             candidate_name: candidate.candidate_name,
//             party: candidate.party,
//             party_symbol: candidate.party_symbol,
//             party_color: candidate.party_color,
//             votes: candidate.votes,
//             percentage: candidate.percentage,
//             color: candidate.party_color
//         });
//     }

//     return {
//         election_id: electionId,
//         district_id: districtId,
//         district_name: result.district_name,
//         total_votes: result.total_votes,
//         distribution: distribution
//     };
// }

// public function getCandidateMargins(string electionId, string candidateId) returns CandidateMargins|error {
//     CandidateDistrictPerformance|error performance = getCandidateDistrictPerformance(electionId, candidateId);
//     if performance is error {
//         return performance;
//     }

//     MarginData[] margins = [];
//     decimal totalMargin = 0.0d;
//     int closeRaces = 0;

//     foreach DistrictPerformance district in performance.districts {
//         // Get district results to find closest competitor
//         DistrictResults|error districtResult = getDistrictResults(electionId, district.district_id);
//         if districtResult is error {
//             continue;
//         }

//         string closestCompetitor = "";
//         decimal margin = 0.0d;

//         if districtResult.candidates.length() > 1 {
//             if district.rank == 1 && districtResult.candidates.length() > 1 {
//                 // Won - margin against second place
//                 margin = district.percentage - districtResult.candidates[1].percentage;
//                 closestCompetitor = districtResult.candidates[1].candidate_name;
//             } else if district.rank > 1 {
//                 // Lost - margin against winner
//                 margin = districtResult.candidates[0].percentage - district.percentage;
//                 closestCompetitor = districtResult.candidates[0].candidate_name;
//             }
//         }

//         margins.push({
//             district_id: district.district_id,
//             district_name: district.district_name,
//             margin_percentage: margin,
//             margin_votes: <int>(margin * <decimal>district.total_district_votes / 100.0d),
//             won: district.won,
//             closest_competitor: closestCompetitor
//         });

//         totalMargin += margin;
//         if margin < 5.0d {
//             closeRaces += 1;
//         }
//     }

//     decimal averageMargin = margins.length() > 0 ? totalMargin / <decimal>margins.length() : 0.0d;

//     return {
//         election_id: electionId,
//         candidate_id: candidateId,
//         candidate_name: performance.candidate_name,
//         margins: margins,
//         average_margin: averageMargin,
//         close_races: closeRaces
//     };
// }

// public function getMarginAnalysis(string electionId, string candidateId, decimal marginThreshold) returns MarginAnalysis|error {
//     CandidateMargins|error margins = getCandidateMargins(electionId, candidateId);
//     if margins is error {
//         return margins;
//     }

//     string[] narrowWins = [];
//     string[] narrowLosses = [];
//     int safeDistricts = 0;
//     int competitiveDistricts = 0;
//     decimal totalWinningMargin = 0.0d;
//     decimal totalLosingMargin = 0.0d;
//     int winCount = 0;
//     int lossCount = 0;

//     foreach MarginData margin in margins.margins {
//         if margin.margin_percentage <= marginThreshold {
//             competitiveDistricts += 1;
//             if margin.won {
//                 narrowWins.push(margin.district_id);
//             } else {
//                 narrowLosses.push(margin.district_id);
//             }
//         } else {
//             safeDistricts += 1;
//         }

//         if margin.won {
//             totalWinningMargin += margin.margin_percentage;
//             winCount += 1;
//         } else {
//             totalLosingMargin += margin.margin_percentage;
//             lossCount += 1;
//         }
//     }

//     decimal averageWinningMargin = winCount > 0 ? totalWinningMargin / <decimal>winCount : 0.0d;
//     decimal averageLosingMargin = lossCount > 0 ? totalLosingMargin / <decimal>lossCount : 0.0d;

//     return {
//         election_id: electionId,
//         candidate_id: candidateId,
//         margin_threshold: marginThreshold,
//         narrow_wins: narrowWins,
//         narrow_losses: narrowLosses,
//         safe_districts: safeDistricts,
//         competitive_districts: competitiveDistricts,
//         average_winning_margin: averageWinningMargin,
//         average_losing_margin: averageLosingMargin
//     };
// }

// public function getLiveResults(string electionId) returns LiveResults|error {
//     // For now, return the final results as "live" results
//     // In a real implementation, you might check election status and return partial results
//     ElectionSummary|error summary = getElectionSummary(electionId);
//     if summary is error {
//         return summary;
//     }

//     RecentUpdate[] recentUpdates = [];
//     // In a real implementation, you would track when districts were last updated

//     return {
//         election_id: electionId,
//         last_updated: getCurrentTimestamp(),
//         districts_declared: summary.districts_declared,
//         total_districts: summary.total_districts,
//         completion_percentage: summary.total_districts > 0 ? 
//             <decimal>summary.districts_declared / <decimal>summary.total_districts * 100.0d : 0.0d,
//         current_standings: summary.candidates,
//         recent_updates: recentUpdates
//     };
// }

// // Helper Functions

// function sortCandidatesByVotes(CandidateResult[] candidates, int totalVotes) returns CandidateResult[] {
//     // Calculate percentages
//     foreach CandidateResult candidate in candidates {
//         candidate.percentage = totalVotes > 0 ? 
//             <decimal>candidate.votes / <decimal>totalVotes * 100.0d : 0.0d;
//     }

//     // Sort by votes in descending order
//     CandidateResult[] sorted = from CandidateResult candidate in candidates
//         order by candidate.votes descending
//         select candidate;

//     // Set ranks
//     foreach int i in 0 ..< sorted.length() {
//         sorted[i].rank = i + 1;
//     }

//     return sorted;
// }

// function sortCandidatesOverallByVotes(CandidateOverall[] candidates) returns CandidateOverall[] {
//     CandidateOverall[] sorted = from CandidateOverall candidate in candidates
//         order by candidate.total_votes descending
//         select candidate;

//     foreach int i in 0 ..< sorted.length() {
//         sorted[i].rank = i + 1;
//     }

//     return sorted;
// }

function getCurrentTimestamp() returns string {
    time:Utc now = time:utcNow();
    return time:utcToString(now);
}

function normalizeDistrictName(string district) returns string {
    // Use regexp to remove spaces and hyphens
    string:RegExp spacePattern = re ` `;
    string:RegExp hyphenPattern = re `-`;
    
    string withoutSpaces = spacePattern.replaceAll(district, "");
    return hyphenPattern.replaceAll(withoutSpaces, "");
}

// Batch Processing Functions (Original)

// Function to calculate and store election results by district
public function calculateElectionResults(string electionId) returns store:CandidateDistrictVoteSummary[]|error {
    // 1. Verify the election exists and is ended
    store:Election|persist:Error election = db->/elections/[electionId].get();
    if election is persist:Error {
        return error("Election not found: " + electionId);
    }

    time:Date today = time:utcToCivil(time:utcNow());
    if !isDateAfter(today, election.endDate) {
        return error("Election hasn't ended yet");
    }

    // 2. Get all enrolled candidates for this election
    stream<store:EnrolCandidates, persist:Error?> enrolmentStream = db->/enrolcandidates;
    store:EnrolCandidates[] enrolments = check from store:EnrolCandidates enrolment in enrolmentStream
        where enrolment.electionId == electionId
        select enrolment;

    // Create map of hashed candidate IDs to original IDs
    map<string> hashedCandidateMap = {};
    foreach store:EnrolCandidates enrolment in enrolments {
        byte[] hashedId = crypto:hashSha256(enrolment.candidateId.toBytes());
        hashedCandidateMap[hashedId.toBase16()] = enrolment.candidateId;
    }

    // 3. Get all votes for this election
    stream<store:Vote, persist:Error?> voteStream = db->/votes;
    store:Vote[] votes = check from store:Vote vote in voteStream
        where vote.electionId == electionId
        select vote;

    // 4. Aggregate votes by candidate and district
    map<map<int>> candidateDistrictCounts = {};
    foreach store:Vote vote in votes {
        string? originalCandidateId = hashedCandidateMap[vote.candidateId];
        if originalCandidateId is () {
            log:printWarn("Vote found for non-enrolled candidate: " + vote.candidateId);
            continue;
        }

        if !candidateDistrictCounts.hasKey(originalCandidateId) {
            candidateDistrictCounts[originalCandidateId] = {};
        }

        map<int>? districtCountsOptional = candidateDistrictCounts[originalCandidateId];
        if districtCountsOptional is () {
            continue; // Skip if null (shouldn't happen but safety check)
        }
        map<int> districtCounts = districtCountsOptional;
        
        string normalizedDistrict = normalizeDistrictName(vote.district);
        int currentCount = districtCounts.get(normalizedDistrict) is int ? districtCounts.get(normalizedDistrict) : 0;
        districtCounts[normalizedDistrict] = currentCount + 1;
    }

    // 5. Convert to CandidateDistrictVoteSummary records
    store:CandidateDistrictVoteSummary[] results = [];
    foreach var [candidateId, districtCounts] in candidateDistrictCounts.entries() {
        store:CandidateDistrictVoteSummary summary = {
            electionId: electionId,
            candidateId: candidateId,
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
            totals: 0
        };

        // Set counts for districts that have votes
        foreach var [district, count] in districtCounts.entries() {
            summary = setDistrictCount(summary, district, count);
            summary.totals += count;
        }

        results.push(summary);
    }

    // 6. Delete old results for this election
    stream<store:CandidateDistrictVoteSummary, persist:Error?> oldSummariesStream = db->/candidatedistrictvotesummaries;
    store:CandidateDistrictVoteSummary[] oldSummaries = check from store:CandidateDistrictVoteSummary s in oldSummariesStream
        where s.electionId == electionId
        select s;

    foreach store:CandidateDistrictVoteSummary s in oldSummaries {
        _ = check db->/candidatedistrictvotesummaries/[s.electionId]/[s.candidateId].delete();
    }

    // 7. Store new results
    [string, string][]|persist:Error insertResult = db->/candidatedistrictvotesummaries.post(results);
    if insertResult is persist:Error {
        return error("Failed to store results: " + insertResult.message());
    }

    return results;
}

// Helper function to check if date1 is after date2
public function isDateAfter(time:Date date1, time:Date date2) returns boolean {
    if date1.year > date2.year {
        return true;
    } else if date1.year == date2.year {
        if date1.month > date2.month {
            return true;
        } else if date1.month == date2.month {
            return date1.day > date2.day;
        }
    }
    return false;
}

// Function to get verified candidate with hash check
public function getCandidateWithHashVerification(string hashedCandidateId, string electionId) 
    returns store:Candidate|error {
    
    // Get all enrolled candidates for this election
    stream<store:EnrolCandidates, persist:Error?> enrolmentStream = db->/enrolcandidates;
    store:EnrolCandidates[] enrolments = check from store:EnrolCandidates enrolment in enrolmentStream
        where enrolment.electionId == electionId
        select enrolment;

    // Find matching candidate by comparing hashes
    foreach store:EnrolCandidates enrolment in enrolments {
        byte[] candidateHash = crypto:hashSha256(enrolment.candidateId.toBytes());
        if candidateHash.toBase16() == hashedCandidateId {
            store:Candidate|persist:Error candidate = db->/candidates/[enrolment.candidateId].get();
            if candidate is persist:Error {
                return error("Candidate not found: " + enrolment.candidateId);
            }
            return candidate;
        }
    }

    return error("No enrolled candidate matches the hashed ID");
}

// Function to get election results
public function getElectionResults(string electionId) returns store:CandidateDistrictVoteSummary[]|error {
    stream<store:CandidateDistrictVoteSummary, persist:Error?> resultsStream = 
        db->/candidatedistrictvotesummaries;
    
    return check from store:CandidateDistrictVoteSummary result in resultsStream
        where result.electionId == electionId
        select result;
}

// Function to get election results with candidate details
public function getElectionResultsWithDetails(string electionId) returns map<json>[]|error {
    // Get the basic vote summaries
    store:CandidateDistrictVoteSummary[]|error summaries = getElectionResults(electionId);
    if summaries is error {
        return error("Failed to get results: " + summaries.message());
    }

    // Get candidate details for each summary
    map<json>[] results = [];
    foreach store:CandidateDistrictVoteSummary summary in summaries {
        store:Candidate|persist:Error candidate = db->/candidates/[summary.candidateId].get();
        if candidate is persist:Error {
            log:printWarn("Candidate details not found", candidateId = summary.candidateId);
            continue;
        }

        // Combine vote summary with candidate details
        map<json> result = {
            electionId: summary.electionId,
            candidateId: summary.candidateId,
            candidateName: candidate.candidateName,
            partyName: candidate.partyName,
            partySymbol: candidate.partySymbol,
            partyColor: candidate.partyColor,
            // Include all district vote counts
            ampara: summary.ampara,
            anuradhapura: summary.anuradhapura,
            badulla: summary.badulla,
            batticaloa: summary.batticaloa,
            colombo: summary.colombo,
            galle: summary.galle,
            gampaha: summary.gampaha,
            hambantota: summary.hambantota,
            jaffna: summary.jaffna,
            kalutara: summary.kalutara,
            kandy: summary.kandy,
            kegalle: summary.kegalle,
            kilinochchi: summary.kilinochchi,
            kurunegala: summary.kurunegala,
            mannar: summary.mannar,
            matale: summary.matale,
            matara: summary.matara,
            monaragala: summary.monaragala,
            mullaitivu: summary.mullaitivu,
            nuwaraeliya: summary.nuwaraeliya,
            polonnaruwa: summary.polonnaruwa,
            puttalam: summary.puttalam,
            ratnapura: summary.ratnapura,
            trincomalee: summary.trincomalee,
            vavuniya: summary.vavuniya,
            totals: summary.totals
        };

        results.push(result);
    }

    return results;
}