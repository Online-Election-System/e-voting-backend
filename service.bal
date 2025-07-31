import online_election.auth;
import online_election.candidate;
import online_election.election;
import online_election.vote;
import online_election.store;
import ballerina/http;
import ballerina/persist;
import online_election.verification;
import online_election.enrollment;
import ballerina/log;

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


// == REMOVAL REQUEST ENDPOINTS ==
    
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