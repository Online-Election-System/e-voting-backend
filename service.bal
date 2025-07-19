import online_election.auth;
import online_election.election;
import online_election.store;

import ballerina/http;
import ballerina/log;
import online_election.result;

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
    resource function get elections() returns store:Election[]|error {
        return check election:getElections();
    }

    resource function get count() returns int|error {
        return check election:getElectionCount();
    }

    resource function get elections/[string electionId]() returns store:Election|error {
        return check election:getElectionById(electionId);
    }

    resource function get elections/upcoming() returns store:Election[]|error {
        return check election:getUpcomingElections();
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

    // Protected endpoint - admin/government officials only
    resource function post elections/create(http:Request request, election:ElectionConfig newElectionConfig)
    returns error|http:Response {

        // Check authorization
        auth:AuthOptions options = {
            allowedRoles: [auth:ADMIN, auth:ELECTION_COMMISSION],
            requiredPermissions: [auth:CREATE_ELECTION]
        };

        auth:AuthenticatedUser|http:Response authResult = auth:withAuth(request, options);
        if authResult is http:Response {
            return authResult;
        }

        return check election:createElection(newElectionConfig);
    }

    // @http:ResourceConfig {
    //     auth: {
    //         scopes: ["admin"]
    //     }
    // }
    resource function put elections/[string electionId]/update(@http:Header string authorization, store:ElectionUpdate updatedElection)
    returns error|http:Response {
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
        allowOrigins: ["http://localhost:3000", "http://127.0.0.1:3000", "http://localhost:3001"],
        allowCredentials: false,
        allowHeaders: ["Content-Type", "Authorization"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    }
}
service /result/api/v1 on SharedListener {

    // Core Election Data Endpoints

    // Get complete election summary - Main endpoint for frontend
    resource function get election/[string electionId]/summary() returns result:ElectionSummaryResponse|http:NotFound|http:InternalServerError {
        result:ElectionSummaryResponse|error summary = result:generateElectionSummary(electionId);
        if summary is result:ElectionSummaryResponse {
            return summary;
        }
        log:printError("Election not found", electionId = electionId);
        return http:NOT_FOUND;
    }

    // Get election winner
    resource function get election/[string electionId]/winner() returns store:Candidate|http:NotFound|http:InternalServerError {
        store:Candidate|error winner = result:calculateElectoralWinner(electionId);
        if winner is store:Candidate {
            return winner;
        }
        return http:NOT_FOUND;
    }

    // Get popular vote winner
    resource function get election/[string electionId]/popular\-winner() returns store:Candidate|http:NotFound|http:InternalServerError {
        store:Candidate|error winner = result:calculatePopularVoteWinner(electionId);
        if winner is store:Candidate {
            return winner;
        }
        return http:NOT_FOUND;
    }

    // Get election status
    resource function get election/[string electionId]/status() returns json|http:NotFound|http:InternalServerError {
        json|error status = result:getLiveElectionStatus(electionId);
        if status is json {
            return status;
        }
        return http:NOT_FOUND;
    }

    // Get victory margin
    resource function get election/[string electionId]/margin() returns result:VictoryMargin|http:NotFound|http:InternalServerError {
        result:VictoryMargin|error margin = result:calculateVictoryMargin(electionId);
        if margin is result:VictoryMargin {
            return margin;
        }
        return http:NOT_FOUND;
    }

    // Candidate Management Endpoints

    // Get all candidates for a specific election
    resource function get election/[string electionId]/candidates() returns store:Candidate[]|http:NotFound|http:InternalServerError {
        store:Candidate[]|error candidates = result:getCandidatesByElection(electionId);
        if candidates is store:Candidate[] {
            return candidates;
        }
        return http:NOT_FOUND;
    }

    // Get specific candidate by ID
    resource function get candidates/[string candidateId]() returns store:Candidate|http:NotFound|http:InternalServerError {
        store:Candidate|error candidate = result:getCandidateById(candidateId);
        if candidate is store:Candidate {
            return candidate;
        }
        log:printWarn("Candidate not found", candidateId = candidateId);
        return http:NOT_FOUND;
    }

    // Get candidate metrics and analytics
    resource function get candidates/[string candidateId]/metrics(string electionId) returns result:CandidateMetrics|http:NotFound|http:InternalServerError {
        result:CandidateMetrics|error metrics = result:getCandidateMetrics(candidateId, electionId);
        if metrics is result:CandidateMetrics {
            return metrics;
        }
        return http:NOT_FOUND;
    }

    // District Management Endpoints

    // Get all districts
    resource function get districts() returns store:District[]|http:InternalServerError {
        return store:districtsStore.toArray();
    }

    // Get specific district by ID
    resource function get districts/[string districtId]() returns store:District|http:NotFound|http:InternalServerError {
        if (store:districtsStore.hasKey(districtId)) {
            return store:districtsStore.get(districtId);
        }
        return http:NOT_FOUND;
    }

    // Get district results with detailed breakdown
    resource function get districts/[string districtId]/results() returns store:DistrictResult[]|http:NotFound|http:InternalServerError {
        if (!store:districtsStore.hasKey(districtId)) {
            return http:NOT_FOUND;
        }
        
        store:District district = store:districtsStore.get(districtId);
        store:DistrictResult[]? results = district.results;
        return results ?: [];
    }

    // Province Management Endpoints

    // Get all provinces
    resource function get provinces() returns store:ProvinceResult[]|http:InternalServerError {
        return store:provincesStore.toArray();
    }

    // Get specific province by ID
    resource function get provinces/[string provinceId]() returns store:ProvinceResult|http:NotFound|http:InternalServerError {
        if (store:provincesStore.hasKey(provinceId)) {
            return store:provincesStore.get(provinceId);
        }
        return http:NOT_FOUND;
    }

    // Get districts by province
    resource function get provinces/[string provinceId]/districts() returns store:District[]|http:NotFound|http:InternalServerError {
        store:District[]|error districts = result:getDistrictsByProvince(provinceId);
        if districts is store:District[] {
            return districts;
        }
        return http:NOT_FOUND;
    }
}