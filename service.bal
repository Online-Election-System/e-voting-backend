import online_election.auth;
import online_election.candidate;
import online_election.election;
import online_election.results;
import online_election.vote;
import online_election.store;
import online_election.HouseholdManagement;

import ballerina/http;
import ballerina/persist;
import online_election.verification;
import online_election.enrollment;
import ballerina/log;

listener http:Listener SharedListener = new (8080);

// ==================== ADMIN SERVICE ====================
@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowHeaders: ["Content-Type", "Authorization"],
        allowMethods: ["GET", "POST", "OPTIONS"],
        allowCredentials: true
    }
}
service /admin/api/v1 on SharedListener {

    // Government Official Registration - Admin Only
    resource function post gov\-official/register(http:Request request, auth:GovernmentOfficialRegistrationRequest req)
    returns json|http:Response|error {

        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request);
        if authResult is http:Response {
            return authResult;
        }

        return check auth:registerGovernmentOfficial(req);
    }

    // Election Commission Registration - Admin Only
    resource function post election\-commission/register(http:Request request, auth:ElectionCommissionRegistrationRequest req)
    returns json|http:Response|error {

        // auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request);
        // if authResult is http:Response {
        //     return authResult;
        // }

        return check auth:registerElectionCommission(req);
    }

    // Polling Station Registration - Admin Only
    resource function post polling\-station/register(http:Request request, auth:PollingStationRegistrationRequest req)
    returns json|http:Response|error {

        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request);
        if authResult is http:Response {
            return authResult;
        }

        return check auth:registerPollingStation(req);
    }

    // Admin endpoint for token monitoring - Admin Only
    resource function get token\-stats(http:Request request) returns json|http:Response|error {
        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request);
        if authResult is http:Response {
            return authResult;
        }

        return auth:getBlacklistStats();
    }

    // Admin endpoint for manual token cleanup - Admin Only
    resource function post cleanup\-tokens(http:Request request) returns json|http:Response|error {
        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request);
        if authResult is http:Response {
            return authResult;
        }

        return auth:manualTokenCleanup();
    }
}

// ==================== VOTER REGISTRATION SERVICE ====================
@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowHeaders: ["Content-Type", "Authorization"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowCredentials: true
    }
}
service /voter\-registration/api/v1 on SharedListener {

    // Public registration endpoint
    resource function post register(auth:VoterRegistrationRequest request)
    returns json|http:Forbidden|error {
        return check auth:postRegistration(request);
    }

    // Public login endpoint
    resource function post login(auth:LoginRequest loginReq, http:Request request)
    returns http:Response|http:Unauthorized|error {

        auth:LoginResponse|http:Unauthorized loginResult = check auth:postLogin(loginReq);

        if loginResult is http:Unauthorized {
            return loginResult;
        }

        // Create response with cookies
        http:Response response = new;
        response.statusCode = 200;

        // Set authentication cookie (httpOnly)
        string|error token = auth:generateJwtWithId(loginResult.userId, auth:getUserRoleFromUserType(loginResult.userType));

        if token is error {
            return http:UNAUTHORIZED;
        }

        auth:setAuthCookie(response, token);

        // Set session info cookie (readable by frontend)
        auth:setSessionInfoCookie(response, loginResult.userId,
                loginResult.userType, loginResult.fullName);

        // Set response body without token
        response.setJsonPayload({
            "status": "success",
            "message": loginResult.message,
            "userId": loginResult.userId,
            "userType": loginResult.userType,
            "fullName": loginResult.fullName
        });

        return response;
    }
    
    resource function get profile/[string voterId]() returns json|error {
        return check vote:getCompleteVoterProfile(voterId);
    }

    // Get elections where voter is enrolled
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

    // Logout - any logged in user
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
        return check auth:putChangePassword(req);
    }
}

// ==================== ELECTION SERVICE ====================
@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type", "Authorization"],
        allowCredentials: true
    }
}
service /election/api/v1 on SharedListener {

    // Get all elections - any logged in user
    resource function get elections(http:Request request) returns election:ElectionWithCandidates[]|http:Response|error {
        // auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request);
        // if authResult is http:Response {
        //     return authResult;
        // }

        return check election:getElections();
    }

    // Get specific election - any logged in user
    resource function get elections/[string electionId](http:Request request) returns election:ElectionWithCandidates|http:Response|error {
        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request);
        if authResult is http:Response {
            return authResult;
        }

        return check election:getElectionById(electionId);
    }

    // Check if voter is enrolled in specific election
    resource function get voter/[string voterId]/election/[string electionId]/enrolled() returns json|error {
        return vote:checkVoterEnrollment(voterId, electionId);
    }

    // Get elections for a specific voter (enrolled elections only)
    resource function get voter/[string voterId]/elections() returns store:Election[]|error {
        return check vote:getVoterEnrolledElections(voterId);
    }

    // Protected endpoint - Create election - election commission only
    resource function post elections/create(http:Request request, election:ElectionCreateWithCandidates newElectionCreate)
    returns election:ElectionWithCandidates|http:Response|error {

        auth:AuthOptions options = {
            allowedRoles: [auth:ELECTION_COMMISSION],
            requiredPermissions: [auth:CREATE_ELECTION]
        };

        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request, options);
        if authResult is http:Response {
            return authResult;
        }

        return check election:createElection(newElectionCreate);
    }

    // Update election - election commission only
    resource function put elections/[string electionId]/update(http:Request request, election:ElectionUpdateWithCandidates updatedElection)
    returns election:ElectionWithCandidates|http:Response|error {

        auth:AuthOptions options = {
            allowedRoles: [auth:ELECTION_COMMISSION],
            requiredPermissions: [auth:UPDATE_ELECTION]
        };

        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request, options);
        if authResult is http:Response {
            return authResult;
        }

        return check election:updateElection(electionId, updatedElection);
    }

    // Delete election - election commission only
    resource function delete elections/[string electionId]/delete(http:Request request)
    returns http:NoContent|http:Response|error {

        auth:AuthOptions options = {
            allowedRoles: [auth:ELECTION_COMMISSION],
            requiredPermissions: [auth:DELETE_ELECTION]
        };

        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request, options);
        if authResult is http:Response {
            return authResult;
        }

        return check election:deleteElection(electionId);
    }
}

// ==================== CANDIDATE SERVICE ====================
@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type", "Authorization"],
        allowCredentials: true
    }
}
service /candidate/api/v1 on SharedListener {

    // Get candidates by election ID - election commission only
    resource function get elections/[string electionId]/candidates(http:Request request) returns store:Candidate[]|http:Response|error {
        auth:AuthOptions options = {
            allowedRoles: [auth:ELECTION_COMMISSION],
            requiredPermissions: []
        };

        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request, options);
        if authResult is http:Response {
            return authResult;
        }

        return check candidate:getCandidatesByElection(electionId);
    }

    // Get all candidates - any logged in user
    resource function get candidates(http:Request request, boolean? activeOnly = ()) returns store:Candidate[]|http:Response|error {
        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request);
        if authResult is http:Response {
            return authResult;
        }

        return check candidate:getCandidates(activeOnly);
    }

    // Get candidate by ID - any logged in user
    resource function get candidates/[string candidateId](http:Request request) returns store:Candidate|http:NotFound|http:Response|error {
        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request);
        if authResult is http:Response {
            return authResult;
        }

        store:Candidate|persist:Error candidateResult = check candidate:getCandidateById(candidateId);

        if candidateResult is persist:Error {
            return http:NOT_FOUND;
        }

        return candidateResult;
    }

    // Get candidates by election and party - any logged in user
    resource function get elections/[string electionId]/candidates/party/[string partyName](http:Request request) returns store:Candidate[]|http:Response|error {
        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request);
        if authResult is http:Response {
            return authResult;
        }

        return check candidate:getCandidatesByElectionAndParty(electionId, partyName);
    }

    // Check if candidate is active - any logged in user
    resource function get candidates/[string candidateId]/active(http:Request request) returns boolean|http:Response|error {
        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request);
        if authResult is http:Response {
            return authResult;
        }

        return check candidate:isCandidateActive(candidateId);
    }

    // Create candidate - election commission only
    resource function post candidates/create(http:Request request, candidate:CandidateInput candidateData)
    returns store:Candidate|http:Response|error {

        auth:AuthOptions options = {
            allowedRoles: [auth:ELECTION_COMMISSION],
            requiredPermissions: [auth:MANAGE_CANDIDATES]
        };

        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request, options);
        if authResult is http:Response {
            return authResult;
        }

        return check candidate:createCandidate(candidateData);
    }

    // Update candidate - election commission only
    resource function put candidates/[string candidateId]/update(http:Request request, store:CandidateUpdate updateData)
    returns store:Candidate|http:Response|error {

        auth:AuthOptions options = {
            allowedRoles: [auth:ELECTION_COMMISSION],
            requiredPermissions: [auth:MANAGE_CANDIDATES]
        };

        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request, options);
        if authResult is http:Response {
            return authResult;
        }

        return check candidate:updateCandidate(candidateId, updateData);
    }

    // Delete candidate - election commission only
    resource function delete candidates/[string candidateId]/delete(http:Request request)
    returns store:Candidate|http:Response|error {

        auth:AuthOptions options = {
            allowedRoles: [auth:ELECTION_COMMISSION],
            requiredPermissions: [auth:MANAGE_CANDIDATES]
        };

        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request, options);
        if authResult is http:Response {
            return authResult;
        }

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

    // Update candidate statuses - election commission only
    resource function post admin/update\-candidate\-statuses(http:Request request) returns json|http:Response|error {

        auth:AuthOptions options = {
            allowedRoles: [auth:ELECTION_COMMISSION],
            requiredPermissions: [auth:MANAGE_CANDIDATES]
        };

        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request, options);
        if authResult is http:Response {
            return authResult;
        }

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
    // NEW: Validate voter credentials without changing session
    resource function post voter/validate(http:Request request, vote:VoterValidationRequest validationReq)
    returns json|http:Unauthorized|http:Response|error {
        
    auth:AuthOptions options = {
        allowedRoles: [auth:POLLING_STATION]
    };

    auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request, options);
    if authResult is http:Response {
        return authResult;
    }

    // 🔥 Use your existing function - no duplication!
    vote:AuthResult|http:Unauthorized|error voterAuthResult = vote:authenticateVoter(
        validationReq.nationalId, 
        validationReq.password
    );
    
    if voterAuthResult is http:Unauthorized || voterAuthResult is error {
        return check voterAuthResult;
    }
    
    // Get complete voter profile
    json|error completeProfile = vote:getCompleteVoterProfile(voterAuthResult.userId);
    
    if completeProfile is error {
        return error("Failed to get voter profile: " + completeProfile.message());
    }
    
    return {
        "valid": true,
        "voterProfile": completeProfile,
        "userType": voterAuthResult.userType,
        "message": "Voter validation successful"
    };
}

    // Cast vote endpoint
    resource function post votes/cast(http:Request request, vote:Vote newVote)
    returns http:Created|http:Forbidden|error|http:Response {
        auth:AuthOptions options = {
            allowedRoles: [auth:POLLING_STATION]
        };

        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request, options);
        if authResult is http:Response {
            return authResult;
        }

        return check vote:castVote(newVote);
    }

    // Check voting eligibility (enrollment + not already voted)
    resource function get eligibility/[string voterId]/election/[string electionId](http:Request request) returns json|error|error|http:Response {
        auth:AuthOptions options = {
            allowedRoles: [auth:POLLING_STATION]
        };

        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request, options);
        if authResult is http:Response {
            return authResult;
        }
        
        return vote:checkVotingEligibility(voterId, electionId);
    }

    // Get votes by election
    resource function get votes/election/[string electionId](http:Request request)
    returns store:Vote[]|error|http:Response {
        auth:AuthOptions options = {
            allowedRoles: [auth:POLLING_STATION]
        };

        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request, options);
        if authResult is http:Response {
            return authResult;
        }

        return check vote:getVotesByElection(electionId);
    }

    // Get voter's voting history
    resource function get votes/voter/[string voterId](http:Request request)
    returns store:Vote[]|error|http:Response {
        auth:AuthOptions options = {
            allowedRoles: [auth:POLLING_STATION]
        };

        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request, options);
        if authResult is http:Response {
            return authResult;
        }

        return check vote:getVotesByVoter(voterId);
    }

    // Get votes by election and district
    resource function get votes/election/[string electionId]/district/[string district](http:Request request)
    returns store:Vote[]|error|http:Response {
        auth:AuthOptions options = {
            allowedRoles: [auth:POLLING_STATION]
        };

        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request, options);
        if authResult is http:Response {
            return authResult;
        }

        return check vote:getVotesByElectionAndDistrict(electionId, district);
    }

    // Get votes by household (new functionality)
    resource function get votes/household/[string chiefOccupantId]/election/[string electionId](http:Request request)
    returns store:Vote[]|error|http:Response {
        auth:AuthOptions options = {
            allowedRoles: [auth:POLLING_STATION]
        };

        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request, options);
        if authResult is http:Response {
            return authResult;
        }

        return check vote:getVotesByHousehold(chiefOccupantId, electionId);
    }
}

//  NEW RESULTS API SERVICE - COMPREHENSIVE ELECTION RESULTS AND ANALYTICS 

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type", "Authorization"],
        allowCredentials: true
    }
}
service /results/api/v1 on SharedListener {

    //  CANDIDATE TOTALS AND RANKINGS

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

    //  CANDIDATE VOTE SUMMARIES WITH PERCENTAGES


    // Get comprehensive candidate data for export
    resource function get elections/[string electionId]/candidates/export() returns results:CandidateExportData[]|error {
        return check results:getComprehensiveCandidateData(electionId, results:dbClient);
    }

    // Export candidate data as CSV format
    resource function get elections/[string electionId]/candidates/export/csv() returns string|error {
        return check results:exportElectionCandidateDataAsCSV(electionId, results:dbClient);
    }


    //  DISTRICT-WISE ANALYSIS

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

    //  ELECTION SUMMARY AND OVERVIEW

    //  DATA VALIDATION AND INTEGRITY

    //  SPECIFIC RESULT QUERIES

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
            "totalVotes": winner.totals,
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
                    "totalVotes": candidates[i].totals,
                    "totalCandidates": candidates.length()
                };
            }
        }
        
        return error("Candidate not found in this election");
    }

    //  ADVANCED ANALYTICS ENDPOINTS

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
        
        int marginVotes = first.totals - second.totals;
        decimal marginPercentage = first.totals > 0 ? (<decimal>marginVotes / <decimal>first.totals) * 100.0 : 0.0;
        
        return {
            "electionId": electionId,
            "winner": {
                "candidateId": first.candidateId,
                "votes": first.totals
            },
            "runnerUp": {
                "candidateId": second.candidateId,
                "votes": second.totals
            },
            "margin": {
                "votes": marginVotes,
                "percentage": marginPercentage
            }
        };
    }
    
    // // Get candidate results for a specific district
    // resource function get election/[string electionId]/district/[string districtId]/results()
    // returns results:DistrictResults|http:NotFound|error {
    //     return check results:getDistrictResults(electionId, districtId);
    // }

    // // Get results for all districts in an election
    // resource function get election/[string electionId]/districts/results()
    // returns results:ElectionDistrictResults|http:NotFound|error {
    //     return check results:getAllDistrictResults(electionId);
    // }

    // // Get candidate performance across all districts
    // resource function get election/[string electionId]/candidate/[string candidateId]/districts()
    // returns results:CandidateDistrictPerformance|http:NotFound|error {
    //     return check results:getCandidateDistrictPerformance(electionId, candidateId);
    // }

    // Get election summary with district winners
    resource function get election/[string electionId]/summary()
    returns results:ElectionSummaryies|http:NotFound|error {
        return check results:getElectionSummaryies(electionId, results:dbClient);
    }
    
    // Return in the format expected by frontend (just the array for backward compatibility)
}

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowMethods: ["GET", "POST", "PUT", "DELETE"],
        allowHeaders: ["Content-Type", "Authorization"]
    }
}
service /api/v1 on SharedListener { 

    // == REGISTRATION REVIEW ENDPOINTS ==
    
    // Get registration applications with optional filters
    resource function get registrations/applications(string? nameOrNic, string? statusFilter)
    returns verification:RegistrationApplication[]|error {
        return verification:getRegistrationApplications(nameOrNic, statusFilter);
    }

    // Get application counts by status
    resource function get registrations/counts()
    returns verification:StatusCounts|error {
        return verification:getApplicationCounts();
    }


    // NEW ENDPOINT: Get detailed registration information by NIC
// Get detailed registration information by NIC
    resource function get registrations/application/[string nic]()
    returns verification:RegistrationDetail|http:NotFound|http:InternalServerError {
        
        do {
            verification:RegistrationDetail registrationDetail = check verification:getRegistrationDetailByNic(nic);
            return registrationDetail;
        } on fail error e {
            log:printError("Error fetching registration detail for NIC: " + nic, e);
            
            // Check if it's a "not found" error
            if e.message().includes("Registration not found") {
                return http:NOT_FOUND;
            }
            
            // Otherwise, it's an internal server error
            return http:INTERNAL_SERVER_ERROR;
        }
    }

    // Approve registration endpoint
    resource function post registrations/[string nic]/approve()
    returns http:Ok|http:NotFound|http:InternalServerError {
        
        do {
            string _ = check verification:approveRegistration(nic);
            log:printInfo("Registration approved successfully for NIC: " + nic);
            return http:OK;
        } on fail error e {
            log:printError("Error approving registration for NIC: " + nic, e);
            
            if e.message().includes("not found") || e.message().includes("User not found") {
                return http:NOT_FOUND;
            }
            
            return http:INTERNAL_SERVER_ERROR;
        }
    }

    

    // Reject registration endpoint
    // service.bal
resource function post registrations/[string nic]/reject(@http:Payload json payload)
    returns http:InternalServerError & readonly|http:BadRequest & readonly|http:NotFound & readonly|http:Ok & readonly|error {
        
        // Extract reason from JSON payload
        string reason;
        do {
            if payload is map<json> {
                json reasonValue = payload["reason"];
                if reasonValue is string {
                    reason = reasonValue;
                } else {
                    log:printWarn("Invalid reason format in payload for NIC: " + nic);
                    return http:BAD_REQUEST;
                }
            } else {
                log:printWarn("Invalid payload format for NIC: " + nic);
                return http:BAD_REQUEST;
            }
        } on fail error e {
            log:printError("Error parsing payload for NIC: " + nic, e);
            return http:BAD_REQUEST;
        }
        
        // Validate rejection reason
        if reason.trim() == "" {
            log:printWarn("Rejection attempted without reason for NIC: " + nic);
            return http:BAD_REQUEST;
        }
        
        do {
            string _ = check verification:rejectRegistration(nic, reason);
            log:printInfo("Registration rejected successfully for NIC: " + nic + " with reason: " + reason);
            return http:OK;
        } on fail error e {
            log:printError("Error rejecting registration for NIC: " + nic, e);
            
            if e.message().includes("not found") || e.message().includes("User not found") {
                return http:NOT_FOUND;
            }
            
            return http:INTERNAL_SERVER_ERROR;
        }
    }



//REMOVAL REQUEST ENDPOINTS

 // Get removal requests with optional filters
 resource function get removal\-requests(string? search, string? status)
 returns verification:RemovalRequest[]|error {
     return verification:getRemovalRequests(search, status);
 }

 // Get removal request counts by status
 resource function get removal\-requests/counts()
 returns verification:RemovalRequestCounts|error {
     return verification:getRemovalRequestCounts();
 }

 // Approve removal request endpoint
 resource function post removal\-requests/[string deleteRequestId]/approve()
 returns http:Ok|http:NotFound|http:InternalServerError {

     do {
         string _ = check verification:approveRemovalRequest(deleteRequestId);
         log:printInfo("Removal request approved successfully for ID: " + deleteRequestId);
         return http:OK;
     } on fail error e {
         log:printError("Error approving removal request for ID: " + deleteRequestId, e);

         if e.message().includes("not found") || e.message().includes("Removal request not found") {
             return http:NOT_FOUND;
         }

         return http:INTERNAL_SERVER_ERROR;
          }
 }

 // Reject removal request endpoint
 resource function post removal\-requests/[string deleteRequestId]/reject(@http:Payload json payload)
     returns http:InternalServerError & readonly|http:BadRequest & readonly|http:NotFound & readonly|http:Ok & readonly|error {

     // Extract reason from JSON payload
     string reason;
     do {
         if payload is map<json> {
             json reasonValue = payload["reason"];
             if reasonValue is string {
                 reason = reasonValue;
             } else {
                 log:printWarn("Invalid reason format in payload for deletion request ID: " + deleteRequestId);
                 return http:BAD_REQUEST;
             }
         } else {
             log:printWarn("Invalid payload format for deletion request ID: " + deleteRequestId);
             return http:BAD_REQUEST;
         }
     } on fail error e {
         log:printError("Error parsing payload for deletion request ID: " + deleteRequestId, e);
         return http:BAD_REQUEST;
     }

     // Validate rejection reason
     if reason.trim() == "" {
         log:printWarn("Rejection attempted without reason for deletion request ID: " + deleteRequestId);
         return http:BAD_REQUEST;
     }

     do {
         string result = check verification:rejectRemovalRequest(deleteRequestId, reason);
         log:printInfo("Removal request rejected successfully for ID: " + deleteRequestId + " with reason: " + reason + ". Result: " + result);
         return http:OK;
     } on fail error e {
         log:printError("Error rejecting removal request for ID: " + deleteRequestId, e);

         if e.message().includes("not found") || e.message().includes("Removal request not found") {
             return http:NOT_FOUND;
         }

         return http:INTERNAL_SERVER_ERROR;
     }
 }


//add member requests endpoints

// Get all add member requests with optional filtering - Fixed to match frontend expectations
resource function get add\-member\-requests(string? search, string? status)
returns json|error {
    
    // Get requests and counts
    verification:AddMemberRequestResponse[]|error requestsResult = verification:getAddMemberRequests(search, status);
    verification:AddMemberRequestCounts|error countsResult = verification:getAddMemberRequestCounts();
    
    if requestsResult is error {
        return requestsResult;
    }
    
    if countsResult is error {
        return countsResult;
    }
    
    // Return in the format expected by frontend (just the array for backward compatibility)
    return requestsResult;
}

// Get add member request counts by status
resource function get add\-member\-requests/counts()
returns verification:AddMemberRequestCounts|error {
    return verification:getAddMemberRequestCounts();
}

// Get specific add member request details - Fixed response structure
resource function get add\-member\-requests/[string addRequestId]()
returns json|http:NotFound|error {
    verification:AddMemberRequestDetail|error result = verification:getAddMemberRequestDetail(addRequestId);
    
    if result is error {
        if result.message().includes("not found") {
            return http:NOT_FOUND;
        }
        return result;
    }
    
    // Return the structured response that matches frontend expectations
    return {
        "request": result.request,
        "chiefOccupant": result.chiefOccupant,
        "householdDetails": result.householdDetails
    };
}

// Approve add member request endpoint
resource function post add\-member\-requests/[string addRequestId]/approve()
returns http:Ok|http:NotFound|http:InternalServerError {
    
    do {
        string _ = check verification:approveAddMemberRequest(addRequestId);
        log:printInfo("Add member request approved successfully for ID: " + addRequestId);
        return http:OK;
    } on fail error e {
        log:printError("Error approving add member request for ID: " + addRequestId, e);
        
        if e.message().includes("not found") || e.message().includes("Add member request not found") {
            return http:NOT_FOUND;
        }
        
        return http:INTERNAL_SERVER_ERROR;
    }
}

// Reject add member request endpoint
resource function post add\-member\-requests/[string addRequestId]/reject(@http:Payload json payload)
returns http:InternalServerError & readonly|http:BadRequest & readonly|http:NotFound & readonly|http:Ok & readonly|error {
    
    // Extract reason from JSON payload
    string reason;
    do {
        if payload is map<json> {
            json reasonValue = payload["reason"];
            if reasonValue is string {
                reason = reasonValue;
            } else {
                log:printWarn("Invalid reason format in payload for add member request ID: " + addRequestId);
                return http:BAD_REQUEST;
            }
        } else {
            log:printWarn("Invalid payload format for add member request ID: " + addRequestId);
            return http:BAD_REQUEST;
        }
    } on fail error e {
        log:printError("Error parsing payload for add member request ID: " + addRequestId, e);
        return http:BAD_REQUEST;
    }
    
    // Validate rejection reason
    if reason.trim() == "" {
        log:printWarn("Rejection attempted without reason for add member request ID: " + addRequestId);
        return http:BAD_REQUEST;
    }
    
    do {
        string result = check verification:rejectAddMemberRequest(addRequestId, reason);
        log:printInfo("Add member request rejected successfully for ID: " + addRequestId + " with reason: " + reason + ". Result: " + result);
        return http:OK;
    } on fail error e {
        log:printError("Error rejecting add member request for ID: " + addRequestId, e);
        
        if e.message().includes("not found") || e.message().includes("Add member request not found") {
            return http:NOT_FOUND;
        }
        
        return http:INTERNAL_SERVER_ERROR;
    }
}


// UPDATE MEMBER REQUESTS REVIEW

// Get all update member requests with optional filtering
    resource function get update\-member\-requests(string? search, string? status)
    returns json|error {
        
        // Get requests 
        verification:UpdateMemberRequestResponse[]|error requestsResult = verification:getUpdateMemberRequests(search, status);
        
        if requestsResult is error {
            return requestsResult;
        }
        
        // Return the array for frontend compatibility
        return requestsResult;
    }

    // Get update member request counts by status
    resource function get update\-member\-requests/counts()
    returns verification:UpdateMemberRequestCounts|error {
        return verification:getUpdateMemberRequestCounts();
    }

    // Get specific update member request details
    resource function get update\-member\-requests/[string updateRequestId]()
    returns json|http:NotFound|error {
        verification:UpdateMemberRequestDetail|error result = verification:getUpdateMemberRequestDetail(updateRequestId);
        
        if result is error {
            if result.message().includes("not found") {
                return http:NOT_FOUND;
            }
            return result;
        }
        
        // Return the structured response that matches frontend expectations
        return {
            "updateRequest": result.updateRequest,
            "householdDetails": result.householdDetails
        };
    }

    // Approve update member request endpoint
    resource function post update\-member\-requests/[string updateRequestId]/approve()
    returns http:Ok|http:NotFound|http:InternalServerError {
        
        do {
            string _ = check verification:approveUpdateMemberRequest(updateRequestId);
            log:printInfo("Update member request approved successfully for ID: " + updateRequestId);
            return http:OK;
        } on fail error e {
            log:printError("Error approving update member request for ID: " + updateRequestId, e);
            
            if e.message().includes("not found") || e.message().includes("Update member request not found") {
                return http:NOT_FOUND;
            }
            
            return http:INTERNAL_SERVER_ERROR;
        }
    }

    // Reject update member request endpoint
    resource function post update\-member\-requests/[string updateRequestId]/reject(@http:Payload json payload)
    returns http:InternalServerError & readonly|http:BadRequest & readonly|http:NotFound & readonly|http:Ok & readonly|error {
        
        // Extract reason from JSON payload
        string reason;
        do {
            if payload is map<json> {
                json reasonValue = payload["reason"];
                if reasonValue is string {
                    reason = reasonValue;
                } else {
                    log:printWarn("Invalid reason format in payload for update member request ID: " + updateRequestId);
                    return http:BAD_REQUEST;
                }
            } else {
                log:printWarn("Invalid payload format for update member request ID: " + updateRequestId);
                return http:BAD_REQUEST;
            }
        } on fail error e {
            log:printError("Error parsing payload for update member request ID: " + updateRequestId, e);
            return http:BAD_REQUEST;
        }
        
        // Validate rejection reason
        if reason.trim() == "" {
            log:printWarn("Rejection attempted without reason for update member request ID: " + updateRequestId);
            return http:BAD_REQUEST;
        }
        
        do {
            string result = check verification:rejectUpdateMemberRequest(updateRequestId, reason);
            log:printInfo("Update member request rejected successfully for ID: " + updateRequestId + " with reason: " + reason + ". Result: " + result);
            return http:OK;
        } on fail error e {
            log:printError("Error rejecting update member request for ID: " + updateRequestId, e);
            
            if e.message().includes("not found") || e.message().includes("Update member request not found") {
                return http:NOT_FOUND;
            }
            
            return http:INTERNAL_SERVER_ERROR;
        }
    }


// Get total eligible voters count
resource function get eligible\-voters/count()
returns record {| int count; |}|error {
    return verification:getEligibleVotersCount();
}

   // MANAGE HOUSEHOLDS
   // Get all households with chief occupant details
    resource function get households(string? search, string? district, string? division) 
    returns json|error {
        
        // Get households
        verification:HouseholdResponse[]|error householdsResult = verification:getHouseholdsWithChiefOccupant(search, district, division);
        
        if householdsResult is error {
            log:printError("Error fetching households", householdsResult);
            return householdsResult;
        }
        
        log:printInfo(string `Successfully retrieved ${householdsResult.length()} households`);
        return householdsResult;
    }

    // Get household by ID with chief occupant details
    resource function get households/[string householdId]() 
    returns json|http:NotFound|error {
        
        verification:HouseholdDetailResponse|error result = verification:getHouseholdById(householdId);
        
        if result is error {
            if result.message().includes("not found") {
                log:printWarn(string `Household not found with ID: ${householdId}`);
                return http:NOT_FOUND;
            }
            log:printError(string `Error fetching household ${householdId}`, result);
            return result;
        }
        
        log:printInfo(string `Successfully retrieved household: ${householdId}`);
        return {
            "household": result.household,
            "chiefOccupant": result.chiefOccupant
        };
    }

    // Get households by electoral district
    resource function get households/district/[string electoralDistrict]() 
    returns json|error {
        
        verification:HouseholdResponse[]|error householdsResult = verification:getHouseholdsByElectoralDistrict(electoralDistrict);
        
        if householdsResult is error {
            log:printError(string `Error fetching households for district ${electoralDistrict}`, householdsResult);
            return householdsResult;
        }
        
        log:printInfo(string `Successfully retrieved ${householdsResult.length()} households for district: ${electoralDistrict}`);
        return householdsResult;
    }

    // Get households by polling division
    resource function get households/polling/[string pollingDivision]() 
    returns json|error {
        
        verification:HouseholdResponse[]|error householdsResult = verification:getHouseholdsByPollingDivision(pollingDivision);
        
        if householdsResult is error {
            log:printError(string `Error fetching households for polling division ${pollingDivision}`, householdsResult);
            return householdsResult;
        }
        
        log:printInfo(string `Successfully retrieved ${householdsResult.length()} households for polling division: ${pollingDivision}`);
        return householdsResult;
    }

    // Get household statistics
    resource function get households/statistics() 
    returns verification:HouseholdStatistics|error {
        
        verification:HouseholdStatistics|error statsResult = verification:getHouseholdStatistics();
        
        if statsResult is error {
            log:printError("Error fetching household statistics", statsResult);
            return statsResult;
        }
        
        log:printInfo("Successfully retrieved household statistics");
        return statsResult;
    }

    // Get household counts by status
    resource function get households/counts()
    returns verification:HouseholdCounts|error {
        return verification:getHouseholdCounts();
    }







        // === VOTER ENDPOINTS ===

    // resource function post voter/login(@http:Payload enrollment:LoginRequest payload) 
    // returns enrollment:ApiResponse|error {
    //     return enrollment:loginVoter(payload);
    // }

    resource function get profile/[string nic]() 
    returns enrollment:UserProfile|http:NotFound|error {
        return enrollment:getUserProfile(nic);
    }

    // === ELECTION & ENROLLMENT ENDPOINTS ===

    resource function get elections(@http:Query string? voterId = (), @http:Query string? voterNic = ()) 
    returns enrollment:ElectionWithEnrollment[]|error {
        return enrollment:getAllElections(voterId, voterNic);
    }

    resource function get elections/[string electionId]/candidates() 
    returns enrollment:ElectionDetailsWithCandidates|http:NotFound|error {
        return enrollment:getElectionWithCandidates(electionId);
    }
    
    // The verification and enrollment endpoint
   resource function post elections/[string electionId]/enroll(
            @http:Payload enrollment:VoterVerificationRequest verificationPayload
    ) returns http:Created|enrollment:ApiResponse|error {
        return enrollment:enrollInElection(electionId, verificationPayload);
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
service /household\-management/api/v1 on SharedListener {

    // Add member request
    resource function post add\-member(HouseholdManagement:AddMemberRequest req)
        returns json|error{
        string[]|error result = HouseholdManagement:submitAddMemberRequest(req);
        if result is error {
            return { message: result.message() };
        }
        return { message: "Add member request submitted", requestId: result[0] };
    }

    // Update member request
    // resource function post update\-member(HouseholdManagement:UpdateMemberRequest req)
    //     returns json|error {
    //     string[]|error result = HouseholdManagement:submitUpdateMemberRequest(req);
    //     if result is error {
    //         return { message: result.message() };
    //     }
    //     return { message: "Update member request submitted", requestId: result[0] };
    // }

    // Delete member request
    resource function post delete\-member(HouseholdManagement:DeleteMemberRequest req)
        returns json|error{
        string[]|error result = HouseholdManagement:submitDeleteMemberRequest(req);
        if result is error {
            return { message: result.message() };
        }
        return { message: "Delete member request submitted", requestId: result[0] };
    }
    // GET resource for household members
    resource function get household/[string chiefOccupantId]/members() 
        returns json|error {
        json|error result = HouseholdManagement:getHouseholdMembers(chiefOccupantId);
        if result is error {
            return error("Failed to get household members: " + result.message());
        }
        return result;
    }

    // OPTIONS resource (empty implementation)
    resource function options household/[string chiefOccupantId]/members() 
        returns http:Accepted {
        return http:ACCEPTED;
    }
}
