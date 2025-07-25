import online_election.auth;
import online_election.candidate;
import online_election.election;
import online_election.store;

import ballerina/http;
import ballerina/persist;

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
    resource function post login(auth:LoginRequest loginReq)
    returns auth:LoginResponse|http:Unauthorized|error {
        return check auth:postLogin(loginReq);
    }

    // Logout - any logged in user
    resource function post logout(http:Request request) returns http:Response|error {
        return check auth:logout(request);
    }

    // Change Password - Public (no auth required)
    resource function put change\-password(auth:ChangePasswordRequest req)
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
        auth:AuthenticatedUser|http:Response authResult = check auth:withAuth(request);
        if authResult is http:Response {
            return authResult;
        }

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

    // Create election - election commission only
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
