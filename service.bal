import online_election.auth;
import online_election.candidate;
import online_election.election;
import online_election.store;

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
