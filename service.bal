import online_election.auth;
import online_election.candidate;
import online_election.election;
import online_election.results;
import online_election.vote;
import online_election.store;
import online_election.HouseholdManagement;
import online_election.activityLog;

import ballerina/http;
import ballerina/persist;
import online_election.verification;
import online_election.enrollment;
import ballerina/time;

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

        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request);
        if authResult is http:Response {
            return authResult;
        }

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

    // Get activity logs with filtering - Admin only
    resource function get logs(
        http:Request request,
        string? userId = (),
        string? userType = (),
        string? action = (),
        string? status = (),
        string? startTime = (),
        string? endTime = (),
        string? endpoint = (),
        string? ipAddress = (),
        int 'limit = 100,
        int offset = 0
    ) returns activityLog:ActivityLogResponse[]|http:Response|error {

        // Only admin can access activity logs
        auth:AuthOptions options = {
            allowedRoles: [auth:ADMIN],
            requiredPermissions: [auth:VIEW_AUDIT_LOGS]
        };

        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request, options);
        if authResult is http:Response {
            return authResult;
        }

        // Log admin access to activity logs
        error? logAccess = activityLog:logActivity({
            userId: authResult.id,
            userType: authResult.userType,
            action: activityLog:DATA_EXPORT,
            endpoint: "/admin/activity-logs/api/v1/logs",
            httpMethod: "GET",
            status: activityLog:SUCCESS,
            details: string `Admin ${authResult.fullName} accessed activity logs`
        });

        // Build filter
        activityLog:ActivityLogFilter filter = {
            userId: userId,
            userType: userType,
            endpoint: endpoint,
            ipAddress: ipAddress,
            'limit: 'limit,
            offset: offset
        };

        // Parse time filters
        if startTime is string {
            filter.startTime = check time:utcFromString(startTime);
        }

        if endTime is string {
            filter.endTime = check time:utcFromString(endTime);
        }

        return check activityLog:getActivityLogs(filter);
    }

    // Get activity statistics - Admin only
    resource function get stats(http:Request request) returns activityLog:ActivityStats|http:Response|error {
        
        auth:AuthOptions options = {
            allowedRoles: [auth:ADMIN],
            requiredPermissions: [auth:VIEW_AUDIT_LOGS]
        };

        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request, options);
        if authResult is http:Response {
            return authResult;
        }

        // Log admin access to statistics
        error? logAccess = activityLog:logActivity({
            userId: authResult.id,
            userType: authResult.userType,
            action: activityLog:REPORT_GENERATED,
            endpoint: "/admin/activity-logs/api/v1/stats",
            httpMethod: "GET",
            status: activityLog:SUCCESS,
            details: "Activity statistics accessed"
        });

        return check activityLog:getActivityStats();
    }

    // Get security alerts - Admin only
    resource function get security\-alerts(http:Request request) returns activityLog:SecurityAlert[]|http:Response|error {
        
        auth:AuthOptions options = {
            allowedRoles: [auth:ADMIN],
            requiredPermissions: [auth:VIEW_AUDIT_LOGS]
        };

        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request, options);
        if authResult is http:Response {
            return authResult;
        }

        // Log admin access to security alerts
        error? logAccess = activityLog:logActivity({
            userId: authResult.id,
            userType: authResult.userType,
            action: activityLog:REPORT_GENERATED,
            endpoint: "/admin/activity-logs/api/v1/security-alerts",
            httpMethod: "GET",
            status: activityLog:SUCCESS,
            details: "Security alerts accessed"
        });

        return check activityLog:getSecurityAlerts();
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

    // Enhanced public registration endpoint with complete request logging
    resource function post register(auth:VoterRegistrationRequest request, http:Request httpRequest)
    returns json|http:Forbidden|error {
        return check auth:postRegistration(request, httpRequest);
    }

    // Enhanced public login endpoint with complete request logging
    resource function post login(auth:LoginRequest loginReq, http:Request httpRequest)
    returns http:Response|http:Unauthorized|error {

        auth:LoginResponse|http:Unauthorized loginResult = check auth:postLogin(loginReq, httpRequest);

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
    
    // Enhanced profile endpoint with complete request logging
    resource function get profile/[string voterId](http:Request httpRequest) returns json|error {
        // Log profile access attempt
        string? ipAddress = activityLog:getIpFromRequest(httpRequest);
        string? userAgent = activityLog:getUserAgentFromRequest(httpRequest);
        
        error? logAccess = activityLog:logActivity({
            userId: voterId,
            userType: (), // Can be extracted from JWT if needed
            action: activityLog:DATA_EXPORT,
            resourceId: voterId,
            httpMethod: httpRequest.method,
            endpoint: httpRequest.rawPath,
            ipAddress: ipAddress,
            userAgent: userAgent,
            status: activityLog:PENDING,
            details: string `Profile access attempt for voter: ${voterId}`,
            sessionId: () // Can be extracted from JWT if needed
        });
        
        json|error result = check vote:getCompleteVoterProfile(voterId);
        
        if result is json {
            // Log successful profile access
            error? logSuccess = activityLog:logActivity({
                userId: voterId,
                userType: (),
                action: activityLog:DATA_EXPORT,
                resourceId: voterId,
                httpMethod: httpRequest.method,
                endpoint: httpRequest.rawPath,
                ipAddress: ipAddress,
                userAgent: userAgent,
                status: activityLog:SUCCESS,
                details: string `Profile successfully retrieved for voter: ${voterId}`,
                sessionId: ()
            });
        } else {
            // Log failed profile access
            error? logFailure = activityLog:logActivity({
                userId: voterId,
                userType: (),
                action: activityLog:DATA_EXPORT,
                resourceId: voterId,
                httpMethod: httpRequest.method,
                endpoint: httpRequest.rawPath,
                ipAddress: ipAddress,
                userAgent: userAgent,
                status: activityLog:FAILURE,
                details: string `Profile retrieval failed for voter: ${voterId}. Error: ${result.message()}`,
                sessionId: ()
            });
        }
        
        return result;
    }

    // Enhanced elections endpoint with complete request logging
    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000"],
            allowCredentials: true,
            allowHeaders: ["Content-Type", "Authorization"],
            allowMethods: ["GET", "OPTIONS"]
        }
    }
    resource function get voter/[string voterId]/elections(http:Request httpRequest) returns store:Election[]|error {
        // Log elections access attempt
        string? ipAddress = activityLog:getIpFromRequest(httpRequest);
        string? userAgent = activityLog:getUserAgentFromRequest(httpRequest);
        
        error? logAccess = activityLog:logActivity({
            userId: voterId,
            userType: (), // Can be extracted from JWT if needed
            action: activityLog:ELECTION_VIEWED,
            resourceId: voterId,
            httpMethod: httpRequest.method,
            endpoint: httpRequest.rawPath,
            ipAddress: ipAddress,
            userAgent: userAgent,
            status: activityLog:PENDING,
            details: string `Voter elections access attempt for: ${voterId}`,
            sessionId: () // Can be extracted from JWT if needed
        });
        
        store:Election[]|error result = check vote:getVoterEnrolledElections(voterId);
        
        if result is store:Election[] {
            // Log successful elections access
            error? logSuccess = activityLog:logActivity({
                userId: voterId,
                userType: (),
                action: activityLog:ELECTION_VIEWED,
                resourceId: voterId,
                httpMethod: httpRequest.method,
                endpoint: httpRequest.rawPath,
                ipAddress: ipAddress,
                userAgent: userAgent,
                status: activityLog:SUCCESS,
                details: string `Voter elections successfully retrieved for: ${voterId}. Found ${result.length()} elections`,
                sessionId: ()
            });
        } else {
            // Log failed elections access
            error? logFailure = activityLog:logActivity({
                userId: voterId,
                userType: (),
                action: activityLog:ELECTION_VIEWED,
                resourceId: voterId,
                httpMethod: httpRequest.method,
                endpoint: httpRequest.rawPath,
                ipAddress: ipAddress,
                userAgent: userAgent,
                status: activityLog:FAILURE,
                details: string `Voter elections retrieval failed for: ${voterId}. Error: ${result.message()}`,
                sessionId: ()
            });
        }
        
        return result;
    }

    // Enhanced logout endpoint with complete request logging
    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000"],
            allowCredentials: true,
            allowHeaders: ["Content-Type", "Authorization"],
            allowMethods: ["POST", "OPTIONS"]
        }
    }
    resource function post logout(http:Request httpRequest) returns http:Response|error {
        // Extract user info from JWT before logout (if possible)
        string? userId = (); // Extract from JWT if available
        string? userType = (); // Extract from JWT if available
        string? sessionId = (); // Extract from session if available
        
        string? ipAddress = activityLog:getIpFromRequest(httpRequest);
        string? userAgent = activityLog:getUserAgentFromRequest(httpRequest);
        
        // Log logout attempt
        error? logAttempt = activityLog:logActivity({
            userId: userId,
            userType: userType,
            action: activityLog:LOGOUT,
            resourceId: userId,
            httpMethod: httpRequest.method,
            endpoint: httpRequest.rawPath,
            ipAddress: ipAddress,
            userAgent: userAgent,
            status: activityLog:PENDING,
            details: string `Logout attempt from IP: ${ipAddress ?: "unknown"}`,
            sessionId: sessionId
        });
        
        http:Response|error result = check auth:logout(httpRequest);
        
        if result is http:Response {
            // Log successful logout
            error? logSuccess = activityLog:logActivity({
                userId: userId,
                userType: userType,
                action: activityLog:LOGOUT,
                resourceId: userId,
                httpMethod: httpRequest.method,
                endpoint: httpRequest.rawPath,
                ipAddress: ipAddress,
                userAgent: userAgent,
                status: activityLog:SUCCESS,
                details: string `Successful logout for user: ${userId ?: "unknown"}`,
                sessionId: sessionId
            });
            
            // Clear session if userId is available
            if userId is string && userType is string {
                string sessionKey = string `${userType}:${userId}`;
                // Remove from session map (in production, clear from Redis/database)
                // userSessions.remove(sessionKey);
            }
        } else {
            // Log failed logout
            error? logFailure = activityLog:logActivity({
                userId: userId,
                userType: userType,
                action: activityLog:LOGOUT,
                resourceId: userId,
                httpMethod: httpRequest.method,
                endpoint: httpRequest.rawPath,
                ipAddress: ipAddress,
                userAgent: userAgent,
                status: activityLog:FAILURE,
                details: string `Logout failed for user: ${userId ?: "unknown"}. Error: ${result.message()}`,
                sessionId: sessionId
            });
        }
        
        return result;
    }

    // Enhanced change password endpoint with complete request logging
    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000"],
            allowCredentials: true,
            allowHeaders: ["Content-Type", "Authorization"],
            allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
        }
    }
    resource function put change\-password(http:Request httpRequest, auth:ChangePasswordRequest req)
    returns http:Ok|http:Unauthorized|json|error|http:Response {
        return check auth:putChangePassword(req, httpRequest);
    }

    // Enhanced password reset endpoint with complete request logging
    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000"],
            allowCredentials: true,
            allowHeaders: ["Content-Type", "Authorization"],
            allowMethods: ["POST", "OPTIONS"]
        }
    }
    resource function post reset\-password(http:Request httpRequest, auth:PasswordResetRequest req)
    returns http:Ok|http:Unauthorized|json|error {
        return check auth:postResetPassword(req, httpRequest);
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

    // // Get top performing districts for a candidate
    // resource function get election/[string electionId]/candidate/[string candidateId]/top\-districts(int 'limit = 10)
    // returns results:CandidateTopDistricts|http:NotFound|error {
    //     return check results:getCandidateTopDistricts(electionId, candidateId, 'limit);
    // }

    // // Get district rankings by total votes
    // resource function get election/[string electionId]/districts/rankings()
    // returns results:DistrictRankings|http:NotFound|error {
    //     return check results:getDistrictRankings(electionId);
    // }

    // // Get candidate standings (overall election results)
    // resource function get election/[string electionId]/candidates/standings()
    // returns results:CandidateStandings|http:NotFound|error {
    //     return check results:getCandidateStandings(electionId);
    // }

    // // Compare candidates in specific districts
    // resource function post election/[string electionId]/districts/compare(@http:Payload results:DistrictComparisonRequest request)
    // returns results:DistrictComparison|http:BadRequest|error {
    //     return check results:compareDistrictResults(electionId, request);
    // }

    // // Get vote distribution by district (pie chart data)
    // resource function get election/[string electionId]/district/[string districtId]/distribution()
    // returns results:VoteDistribution|http:NotFound|error {
    //     return check results:getVoteDistribution(electionId, districtId);
    // }

    // // Get candidate margin analysis by district
    // resource function get election/[string electionId]/candidate/[string candidateId]/margins()
    // returns results:CandidateMargins|http:NotFound|error {
    //     return check results:getCandidateMargins(electionId, candidateId);
    // }

    // // Get districts where candidate won/lost by specific margin
    // resource function get election/[string electionId]/candidate/[string candidateId]/margins/analysis(decimal marginThreshold = 5.0)
    // returns results:MarginAnalysis|http:NotFound|error {
    //     return check results:getMarginAnalysis(electionId, candidateId, marginThreshold);
    // }

    // // Get real-time results (if election is ongoing)
    // resource function get election/[string electionId]/live/results()
    // returns results:LiveResults|http:NotFound|error {
    //     return check results:getLiveResults(electionId);
    // }
}

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"], // Your frontend URL
        allowMethods: ["GET", "POST", "PUT", "DELETE"],
        allowHeaders: ["Content-Type", "Authorization"]
    }
}
service /api/v1 on SharedListener {

    // == REGISTRATION REVIEW ENDPOINTS ==

    // CORRECTED: All function calls now use the 'verification:' prefix.
    resource function get registrations/applications(string? nameOrNic, string? statusFilter) 
    returns verification:RegistrationApplication[]|error {
        return verification:getRegistrationApplications(nameOrNic, statusFilter);
    }

    resource function get registrations/counts() 
    returns verification:StatusCounts|error {
        return verification:getApplicationCounts();
    }

    resource function get registrations/applications/[string nic]() 
    returns verification:RegistrationDetails|http:NotFound|error {
        return verification:getRegistrationDetails(nic);
    }

    resource function post registrations/applications/[string nic]/review(verification:ReviewRequest reviewData) 
    returns http:Ok|http:Forbidden|error {
        return verification:reviewApplication(nic, reviewData);
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
    resource function post update\-member(HouseholdManagement:UpdateMemberRequest req)
        returns json|error {
        string[]|error result = HouseholdManagement:submitUpdateMemberRequest(req);
        if result is error {
            return { message: result.message() };
        }
        return { message: "Update member request submitted", requestId: result[0] };
    }

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
