import online_election.auth;
import online_election.candidate;
import online_election.election;
import online_election.vote;
import online_election.store;
import online_election.results;
import ballerina/http;
import ballerina/persist;



listener http:Listener SharedListener = new (8080);

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowHeaders: ["Content-Type", "Authorization"],
        allowMethods: ["GET", "POST", "OPTIONS"],
        allowCredentials: true
    }
}
service /admin\-registration/api/v1 on SharedListener {

    // Government Official Registration
    resource function post gov\-official/register(auth:GovernmentOfficialRegistrationRequest req) returns json|error {
        return check auth:registerGovernmentOfficial(req);
    }

    // Election Commission Registration
    resource function post election\-commission/register(auth:ElectionCommissionRegistrationRequest req) returns json|error {
        return check auth:registerElectionCommission(req);
    }

    // Unified logout endpoint - 204 No Content response
    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000"],
            allowCredentials: true,
            allowHeaders: ["Content-Type", "Authorization"],
            allowMethods: ["POST", "OPTIONS"]
        }
    }
    resource function post logout(http:Request request) returns http:Response|error {
        return check auth:logout(request);
    }
}

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"]
    }
}
service /voter\-registration/api/v1 on SharedListener {
    // Public endpoints (no auth required)
    // Register a new voter
    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000"],
            allowCredentials: true,
            allowHeaders: ["Content-Type", "Authorization"],
            allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
        }
    }
    resource function post register(auth:VoterRegistrationRequest request)
returns json|http:Forbidden|error {
        return check auth:postRegistration(request);
    }

    // Voter Login
    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000"],
            allowCredentials: true,
            allowHeaders: ["Content-Type", "Authorization"],
            allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
        }
    }
    resource function post login(auth:LoginRequest loginReq)
returns auth:LoginResponse|http:Unauthorized|error {
        return check auth:postLogin(loginReq);
    }

        // Get complete voter profile with household details - NEW ENDPOINT
    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000"],
            allowCredentials: true,
            allowHeaders: ["Content-Type", "Authorization"],
            allowMethods: ["GET", "OPTIONS"]
        }
    }
    resource function get profile/[string voterId]() returns json|error {
        return check vote:getCompleteVoterProfile(voterId);
    }

    // Get elections where voter is enrolled - NEW ENDPOINT
    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000"],
            allowCredentials: true,
            allowHeaders: ["Content-Type", "Authorization"],
            allowMethods: ["GET", "OPTIONS"]
        }
    }
    resource function get voter/[string voterId]/elections() returns store:Election[]|error {
        return check vote:getVoterEnrolledElections(voterId);
    }


    // Unified logout endpoint - 204 No Content response
    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000"],
            allowCredentials: true,
            allowHeaders: ["Content-Type", "Authorization"],
            allowMethods: ["POST", "OPTIONS"]
        }
    }
    resource function post logout(http:Request request) returns http:Response|error {
        return check auth:logout(request);
    }

    // Protected endpoint - requires authentication
    // Change Password
    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000"],
            allowCredentials: true,
            allowHeaders: ["Content-Type", "Authorization"],
            allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
        }
    }
    resource function put change\-password(http:Request request, auth:ChangePasswordRequest req)
    returns http:Ok|http:Unauthorized|json|error|http:Response {

        // Check authentication
        auth:AuthenticatedUser|http:Response authResult = auth:withAuth(request);
        if authResult is http:Response {
            return authResult; // Return error response
        }

        return check auth:putChangePassword(req);
    }
}

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type", "Authorization"],
        allowCredentials: true
    }
}
service /election/api/v1 on SharedListener {
    // Public endpoints
    resource function get elections() returns election:ElectionWithCandidates[]|error {
        return check election:getElections();
    }

    resource function get elections/[string electionId]() returns election:ElectionWithCandidates|error {
        return check election:getElectionById(electionId);
    }

       // Check if voter is enrolled in specific election - NEW ENDPOINT
resource function get voter/[string voterId]/election/[string electionId]/enrolled() returns json|error {
    return vote:checkVoterEnrollment(voterId, electionId);
}

    // Get elections for a specific voter (enrolled elections only) - NEW ENDPOINT
    resource function get voter/[string voterId]/elections() returns store:Election[]|error {
        return check vote:getVoterEnrolledElections(voterId);
    }

    // Protected endpoint - admin/government officials only
    resource function post elections/create(http:Request request, election:ElectionCreateWithCandidates newElectionCreate)
    returns election:ElectionWithCandidates|error|http:Response {

        // Check authorization
        // auth:AuthOptions options = {
        //     allowedRoles: [auth:ADMIN, auth:ELECTION_COMMISSION],
        //     requiredPermissions: [auth:CREATE_ELECTION]
        // };

        // auth:AuthenticatedUser|http:Response authResult = auth:withAuth(request, options);
        // if authResult is http:Response {
        //     return authResult;
        // }

        return check election:createElection(newElectionCreate);
    }

    resource function put elections/[string electionId]/update(@http:Header string authorization, election:ElectionUpdateWithCandidates updatedElection)
    returns election:ElectionWithCandidates|error|http:Response {
        return check election:updateElection(electionId, updatedElection);
    }

    // Protected endpoint - admin only
    resource function delete elections/[string electionId]/delete(http:Request request)
    returns http:NoContent|http:Forbidden|error|http:Response {

        auth:AuthOptions options = {
            allowedRoles: [auth:ADMIN],
            requiredPermissions: [auth:DELETE_ELECTION]
        };

        auth:AuthenticatedUser|http:Response authResult = auth:withAuth(request, options);
        if authResult is http:Response {
            return authResult;
        }

        return check election:deleteElection(electionId);
    }

    // Admin endpoint for token monitoring
    resource function get admin/token\-stats(http:Request request) returns json|http:Response|error {
        auth:AuthOptions options = {
            allowedRoles: [auth:ADMIN],
            requiredPermissions: [auth:MANAGE_USERS]
        };

        auth:AuthenticatedUser|http:Response authResult = auth:withAuth(request, options);
        if authResult is http:Response {
            return authResult;
        }

        return auth:getBlacklistStats();
    }

    // Admin endpoint for manual token cleanup
    resource function post admin/cleanup\-tokens(http:Request request) returns json|http:Response|error {
        auth:AuthOptions options = {
            allowedRoles: [auth:ADMIN],
            requiredPermissions: [auth:MANAGE_USERS]
        };

        auth:AuthenticatedUser|http:Response authResult = auth:withAuth(request, options);
        if authResult is http:Response {
            return authResult;
        }

        return auth:manualTokenCleanup();
    }
}

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type", "Authorization"],
        allowCredentials: true
    }
}
service /candidate/api/v1 on SharedListener {

    // Get candidates by election ID from database
    resource function get elections/[string electionId]/candidates() returns store:Candidate[]|error {
        return check candidate:getCandidatesByElection(electionId);
    }

    // Get all candidates from database (with optional activeOnly filter)
    resource function get candidates(boolean? activeOnly = ()) returns store:Candidate[]|error {
        return check candidate:getCandidates(activeOnly);
    }

    // Get candidate by ID from database
    resource function get candidates/[string candidateId]() returns store:Candidate|http:NotFound|error {
        store:Candidate|persist:Error candidateResult = check candidate:getCandidateById(candidateId);

        if candidateResult is persist:Error {
            return http:NOT_FOUND;
        }

        return candidateResult;
    }

    // Get candidates by election and party
    resource function get elections/[string electionId]/candidates/party/[string partyName]() returns store:Candidate[]|error {
        return check candidate:getCandidatesByElectionAndParty(electionId, partyName);
    }

    // Check if candidate is active
    resource function get candidates/[string candidateId]/active() returns boolean|error {
        return check candidate:isCandidateActive(candidateId);
    }

    // CREATE new candidate endpoint
    resource function post candidates/create(http:Request request, candidate:CandidateInput candidateData) 
    returns store:Candidate|error|http:Response {
        
        // Optional: Add authentication for candidate creation
        // auth:AuthOptions options = {
        //     allowedRoles: [auth:ADMIN, auth:ELECTION_COMMISSION],
        //     requiredPermissions: [auth:MANAGE_CANDIDATES]
        // };

        // auth:AuthenticatedUser|http:Response authResult = auth:withAuth(request, options);
        // if authResult is http:Response {
        //     return authResult;
        // }

        return check candidate:createCandidate(candidateData);
    }

    // UPDATE existing candidate endpoint
    resource function put candidates/[string candidateId]/update(http:Request request, store:CandidateUpdate updateData)
    returns store:Candidate|error|http:Response {
        
        // Optional: Add authentication for candidate updates
        // auth:AuthOptions options = {
        //     allowedRoles: [auth:ADMIN, auth:ELECTION_COMMISSION],
        //     requiredPermissions: [auth:MANAGE_CANDIDATES]
        // };

        // auth:AuthenticatedUser|http:Response authResult = auth:withAuth(request, options);
        // if authResult is http:Response {
        //     return authResult;
        // }

        return check candidate:updateCandidate(candidateId, updateData);
    }

    // DELETE candidate endpoint
    resource function delete candidates/[string candidateId]/delete(http:Request request)
    returns store:Candidate|error|http:Response {
        
        // Optional: Add authentication for candidate deletion
        // auth:AuthOptions options = {
        //     allowedRoles: [auth:ADMIN],
        //     requiredPermissions: [auth:MANAGE_CANDIDATES]
        // };

        // auth:AuthenticatedUser|http:Response authResult = auth:withAuth(request, options);
        // if authResult is http:Response {
        //     return authResult;
        // }

        return check candidate:deleteCandidate(candidateId);
    }

    // Get active candidates by election - Updated to use new enrollment system
    resource function get elections/[string electionId]/candidates/active() returns store:Candidate[]|error {
        return check candidate:getCandidatesByElection(electionId, true); // Pass true for activeOnly
    }

    // Get candidates for elections where voter is enrolled - Updated logic
  resource function get voter/[string voterId]/candidates() returns store:Candidate[]|error {
    return vote:getCandidatesForVoter(voterId);
}


    // Get candidates for a specific election if voter is enrolled - Updated logic
resource function get voter/[string voterId]/election/[string electionId]/candidates() returns store:Candidate[]|error {
    return vote:getEligibleCandidatesForElection(voterId, electionId);
}

        // Get candidates by party - Updated to use new structure
    resource function get candidates/party/[string partyName]() returns store:Candidate[]|error {
        return check candidate:getCandidatesByParty(partyName, true); // Get active candidates only
    }


    // Admin endpoint for updating candidate statuses
    resource function post admin/update\-candidate\-statuses(http:Request request) returns json|http:Response|error {
        // auth:AuthOptions options = {
        //     allowedRoles: [auth:ADMIN, auth:ELECTION_COMMISSION],
        //     requiredPermissions: [auth:MANAGE_CANDIDATES]
        // };

        // auth:AuthenticatedUser|http:Response authResult = auth:withAuth(request, options);
        // if authResult is http:Response {
        //     return authResult;
        // }

        error? updateResult = candidate:updateCandidateStatusesBasedOnElections();
        if updateResult is error {
            return error("Failed to update candidate statuses: " + updateResult.message());
        }

        return {
            "message": "Candidate statuses updated successfully based on current elections"
        };
    }
}

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type", "Authorization"],
        allowCredentials: true
    }
}
service /vote/api/v1 on SharedListener {
    // Cast vote endpoint
    resource function post votes/cast(vote:Vote newVote)
    returns http:Created|http:Forbidden|error {
        return check vote:castVote(newVote);
    }

    // Check voting eligibility (enrollment + not already voted) - NEW ENDPOINT
    resource function get eligibility/[string voterId]/election/[string electionId]() returns json|error {
        return vote:checkVotingEligibility(voterId, electionId);
    }

    // Get votes by election
    resource function get votes/election/[string electionId]()
    returns store:Vote[]|error {
        return check vote:getVotesByElection(electionId);
    }

    // Get voter's voting history
    resource function get votes/voter/[string voterId]()
    returns store:Vote[]|error {
        return check vote:getVotesByVoter(voterId);
    }

    // Get votes by election and district
    resource function get votes/election/[string electionId]/district/[string district]()
    returns store:Vote[]|error {
        return check vote:getVotesByElectionAndDistrict(electionId, district);
    }

    // Get votes by household (new functionality)
    resource function get votes/household/[string chiefOccupantId]/election/[string electionId]()
    returns store:Vote[]|error {
        return check vote:getVotesByHousehold(chiefOccupantId, electionId);
    }
}

// ============================================================================================
// 🔥 NEW RESULTS API SERVICE - COMPREHENSIVE ELECTION RESULTS AND ANALYTICS 🔥
// ============================================================================================

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type", "Authorization"],
        allowCredentials: true
    }
}
service /results/api/v1 on SharedListener {

    // ============================================================================
    // 📊 CANDIDATE TOTALS AND RANKINGS
    // ============================================================================

    // Get candidate total votes for an election (sorted by highest votes)
    resource function get elections/[string electionId]/candidates/totals() returns results:CandidateTotal[]|error {
        return check results:getSortedCandidatesByTotal(electionId, results:dbClient);
    }

    // Batch update all candidate totals for an election
    resource function post elections/[string electionId]/candidates/batch\-update\-totals() returns json|error {
        error? result = results:batchUpdateCandidateTotals(electionId, results:dbClient);
        if result is error {
            return result;
        }
        return { "electionId": electionId, "message": "All candidate totals updated successfully" };
    }

    // ============================================================================
    // 📈 CANDIDATE VOTE SUMMARIES WITH PERCENTAGES
    // ============================================================================

    // Get candidate vote summaries with percentages and rankings
    resource function get elections/[string electionId]/candidates/summary() returns results:CandidateVoteSummary[]|error {
        return check results:calculateCandidateVoteSummary(electionId, results:dbClient);
    }

    // Get comprehensive candidate data for export
    resource function get elections/[string electionId]/candidates/export() returns results:CandidateExportData[]|error {
        return check results:getComprehensiveCandidateData(electionId, results:dbClient);
    }

    // Export candidate data as CSV format
    resource function get elections/[string electionId]/candidates/export/csv() returns string|error {
        return check results:exportElectionCandidateDataAsCSV(electionId, results:dbClient);
    }

    // ============================================================================
    // 🗺️ DISTRICT-WISE ANALYSIS
    // ============================================================================

    // Get district-wise vote analysis for all candidates
    resource function get elections/[string electionId]/districts/analysis() returns results:CandidateDistrictAnalysis[]|error {
        return check results:calculateCandidateDistrictAnalysis(electionId, results:dbClient);
    }

    // Get total votes per district for an election
    resource function get elections/[string electionId]/districts/totals() returns results:DistrictVoteTotals|error {
        return check results:calculateDistrictVoteTotalsFromDB(electionId, results:dbClient);
    }

    // Get district winners analysis with margins
    resource function get elections/[string electionId]/districts/winners() returns json|error {
        return check results:getDistrictWinnerAnalysis(electionId, results:dbClient);
    }

    // ============================================================================
    // 🎯 ELECTION SUMMARY AND OVERVIEW
    // ============================================================================

    // Get comprehensive election summary
    resource function get elections/[string electionId]/summary() returns json|error {
        return check results:getElectionSummary(electionId, results:dbClient);
    }

    // ============================================================================
    // 🔍 DATA VALIDATION AND INTEGRITY
    // ============================================================================

    // Validate election data integrity
    resource function get elections/[string electionId]/validate() returns json|error {
        return check results:validateElectionDataIntegrity(electionId, results:dbClient);
    }

    // ============================================================================
    // 🏆 SPECIFIC RESULT QUERIES
    // ============================================================================

    // Get winner of the election
    resource function get elections/[string electionId]/winner() returns json|error {
        results:CandidateTotal[]|error candidates = results:getSortedCandidatesByTotal(electionId, results:dbClient);
        if candidates is error {
            return candidates;
        }
        if candidates.length() == 0 {
            return error("No candidates found for this election");
        }
        
        results:CandidateTotal winner = candidates[0];
        return {
            "electionId": electionId,
            "winnerCandidateId": winner.candidateId,
            "totalVotes": winner.Totals,
            "message": "Election winner determined"
        };
    }

    // Get top N candidates
    resource function get elections/[string electionId]/candidates/top/[int count]() returns results:CandidateTotal[]|error {
        results:CandidateTotal[]|error allCandidates = results:getSortedCandidatesByTotal(electionId, results:dbClient);
        if allCandidates is error {
            return allCandidates;
        }
        
        int maxCount = allCandidates.length() > count ? count : allCandidates.length();
        results:CandidateTotal[] topCandidates = [];
        foreach int i in 0 ..< maxCount {
            topCandidates.push(allCandidates[i]);
        }
        return topCandidates;
    }

    // Get candidate ranking by total votes
    resource function get elections/[string electionId]/candidates/[string candidateId]/rank() returns json|error {
        results:CandidateTotal[]|error candidates = results:getSortedCandidatesByTotal(electionId, results:dbClient);
        if candidates is error {
            return candidates;
        }
        
        foreach int i in 0 ..< candidates.length() {
            if candidates[i].candidateId == candidateId {
                return {
                    "candidateId": candidateId,
                    "rank": i + 1,
                    "totalVotes": candidates[i].Totals,
                    "totalCandidates": candidates.length()
                };
            }
        }
        
        return error("Candidate not found in this election");
    }

    // ============================================================================
    // 📊 ADVANCED ANALYTICS ENDPOINTS
    // ============================================================================

    // Get vote distribution statistics
    resource function get elections/[string electionId]/statistics/distribution() returns json|error {
        results:CandidateVoteSummary[]|error summaries = results:calculateCandidateVoteSummary(electionId, results:dbClient);
        if summaries is error {
            return summaries;
        }
        
        if summaries.length() == 0 {
            return error("No data available for analysis");
        }
        
        // Calculate statistics
        int totalVotes = 0;  // FIXED: Changed from decimal to int
        decimal maxPercentage = 0.0;
        decimal minPercentage = 100.0;
        
        foreach results:CandidateVoteSummary summary in summaries {
            totalVotes += summary.totalVotes;  // FIXED: Direct int addition
            if summary.percentage > maxPercentage {
                maxPercentage = summary.percentage;
            }
            if summary.percentage < minPercentage {
                minPercentage = summary.percentage;
            }
        }
        
        // FIXED: Corrected average percentage calculation
        decimal averagePercentage = summaries.length() > 0 ? 100.0d / <decimal>summaries.length() : 0.0d;
        
        return {
            "electionId": electionId,
            "totalCandidates": summaries.length(),
            "totalVotes": totalVotes,  // FIXED: Now returns int directly
            "maxPercentage": maxPercentage,
            "minPercentage": minPercentage,
            "averagePercentage": averagePercentage,
            "competitivenessIndex": maxPercentage - minPercentage
        };
    }

    // Get margin analysis between top candidates
    resource function get elections/[string electionId]/statistics/margins() returns json|error {
        results:CandidateTotal[]|error candidates = results:getSortedCandidatesByTotal(electionId, results:dbClient);
        if candidates is error {
            return candidates;
        }
        
        if candidates.length() < 2 {
            return error("Need at least 2 candidates for margin analysis");
        }
        
        results:CandidateTotal first = candidates[0];
        results:CandidateTotal second = candidates[1];
        
        int marginVotes = first.Totals - second.Totals;
        decimal marginPercentage = first.Totals > 0 ? (<decimal>marginVotes / <decimal>first.Totals) * 100.0 : 0.0;
        
        return {
            "electionId": electionId,
            "winner": {
                "candidateId": first.candidateId,
                "votes": first.Totals
            },
            "runnerUp": {
                "candidateId": second.candidateId,
                "votes": second.Totals
            },
            "margin": {
                "votes": marginVotes,
                "percentage": marginPercentage
            }
        };
    }
}