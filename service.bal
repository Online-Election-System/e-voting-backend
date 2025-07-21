import online_election.auth;
import online_election.election;
import online_election.store;

import ballerina/http;
import ballerina/log;
import ballerina/persist;
import online_election.result;
import ballerina/lang.array;
import ballerina/sql;
import ballerina/time;

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

// election_results_service.bal - Complete Election Results API Service


type LiveElectionStatus record {|
    
|};

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000", "http://127.0.0.1:3000", "http://localhost:3001"],
        allowCredentials: false,
        allowHeaders: ["Content-Type", "Authorization"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    }
}
service /result/api/v1 on SharedListener {

    // Initialize database client as a service-level resource
    private final store:Client dbClient;

    function init() returns error? {
        self.dbClient = check new();
    }

    // Core Election Data Endpoints

    // Get complete election summary - Main endpoint for frontend
    resource function get election/[string electionId]/summary() returns result:ElectionSummaryResponse|http:NotFound|http:InternalServerError {
        do {
            result:ElectionSummaryResponse summary = check result:getCompleteElectionResults(self.dbClient, electionId);
            return summary;
        } on fail error e {
            log:printError("Failed to get election summary", electionId = electionId, 'error = e);
            return http:INTERNAL_SERVER_ERROR;
        }
    }

    // Get election details
    resource function get election/[string electionId]() returns store:Election|http:NotFound|http:InternalServerError {
        do {
            store:Election election = check result:getElectionById(self.dbClient, electionId);
            return election;
        } on fail error e {
            log:printError("Election not found", electionId = electionId, 'error = e);
            return http:NOT_FOUND;
        }
    }

    // Get election winner (candidate with most electoral votes)
    resource function get election/[string electionId]/winner() returns store:Candidate|http:NotFound|http:InternalServerError {
        do {
            store:Candidate winner = check self.calculateElectoralWinner(electionId);
            return winner;
        } on fail error e {
            log:printError("Failed to calculate winner", electionId = electionId, 'error = e);
            return http:NOT_FOUND;
        }
    }

    // Get popular vote winner
    resource function get election/[string electionId]/popular\-winner() returns store:Candidate|http:NotFound|http:InternalServerError {
        do {
            store:Candidate winner = check self.calculatePopularVoteWinner(electionId);
            return winner;
        } on fail error e {
            log:printError("Failed to calculate popular vote winner", electionId = electionId, 'error = e);
            return http:NOT_FOUND;
        }
    }

    // Get election status with live updates
    

    // Get victory margin analysis
    resource function get election/[string electionId]/margin() returns result:VictoryMargin|http:NotFound|http:InternalServerError {
        do {
            result:VictoryMargin margin = check self.calculateVictoryMargin(electionId);
            return margin;
        } on fail error e {
            log:printError("Failed to calculate victory margin", electionId = electionId, 'error = e);
            return http:NOT_FOUND;
        }
    }

    // Get party summaries for election
    resource function get election/[string electionId]/parties() returns result:PartySummary[]|http:NotFound|http:InternalServerError {
        do {
            store:Candidate[] candidates = check result:getCandidatesByElection(self.dbClient, electionId);
            store:DistrictResult[] districts = check result:getDistrictResultsByElection(self.dbClient, electionId);
            result:PartySummary[] partySummaries = check result:generatePartySummaries(candidates, districts);
            return partySummaries;
        } on fail error e {
            log:printError("Failed to get party summaries", electionId = electionId, 'error = e);
            return http:INTERNAL_SERVER_ERROR;
        }
    }

    // Candidate Management Endpoints

    // Get all candidates for a specific election
    resource function get election/[string electionId]/candidates() returns store:Candidate[]|http:NotFound|http:InternalServerError {
        do {
            store:Candidate[] candidates = check result:getCandidatesByElection(self.dbClient, electionId);
            return candidates;
        } on fail error e {
            log:printError("Failed to get candidates", electionId = electionId, 'error = e);
            return http:NOT_FOUND;
        }
    }

    // Get specific candidate by ID
    resource function get candidates/[string candidateId]() returns store:Candidate|http:NotFound|http:InternalServerError {
        do {
            store:Candidate candidate = check result:getCandidateById(self.dbClient, candidateId);
            return candidate;
        } on fail error e {
            log:printWarn("Candidate not found", candidateId = candidateId, 'error = e);
            return http:NOT_FOUND;
        }
    }

    // Get candidate metrics and analytics
    resource function get candidates/[string candidateId]/metrics() returns result:CandidateMetrics|http:NotFound|http:InternalServerError {
        do {
            result:CandidateMetrics metrics = check result:getCandidateMetrics(self.dbClient, candidateId);
            return metrics;
        } on fail error e {
            log:printError("Failed to get candidate metrics", candidateId = candidateId, 'error = e);
            return http:NOT_FOUND;
        }
    }

    // Update candidate votes (POST endpoint for vote processing)
    //weda ne
    resource function post candidates/[string candidateId]/votes(@http:Payload json voteData) returns http:Ok|http:BadRequest|http:InternalServerError {
        do {
            json additionalVotesJson = check voteData.additionalVotes;
            int additionalVotes = check additionalVotesJson.ensureType(int);
            
            check result:updateCandidateVotes(self.dbClient, candidateId, additionalVotes);
            
            // Update election summary after vote update
            store:Candidate candidate = check result:getCandidateById(self.dbClient, candidateId);
            check result:updateElectionSummary(self.dbClient, candidate.electionId);
            
            return http:OK;
        } on fail error e {
            log:printError("Failed to update candidate votes", candidateId = candidateId, 'error = e);
            return http:INTERNAL_SERVER_ERROR;
        }
    }

    // District Management Endpoints

    // Get all districts
    resource function get districts() returns store:District[]|http:InternalServerError {
        do {
            store:District[] districts = check self.getDistrictsFromDB();
            return districts;
        } on fail error e {
            log:printError("Error fetching districts", 'error = e);
            return http:INTERNAL_SERVER_ERROR;
        }
    }

    // Get specific district by ID
    resource function get districts/[string districtId]() returns store:District|http:NotFound|http:InternalServerError {
        do {
            store:District district = check self.getDistrictByIdFromDB(districtId);
            return district;
        } on fail error e {
            log:printError("District not found", districtId = districtId, 'error = e);
            return http:NOT_FOUND;
        }
    }

    // Get district results with detailed breakdown
    //weda ne
    resource function get districts/[string districtId]/results() returns store:DistrictResult[]|http:NotFound|http:InternalServerError {
        do {
            store:DistrictResult[] results = check self.getDistrictResultsFromDB(districtId);
            return results;
        } on fail error e {
            log:printError("Failed to get district results", districtId = districtId, 'error = e);
            return http:NOT_FOUND;
        }
    }

    // Get district results for specific election
    //weda ne
    resource function get election/[string electionId]/districts() returns store:DistrictResult[]|http:NotFound|http:InternalServerError {
        do {
            store:DistrictResult[] districts = check result:getDistrictResultsByElection(self.dbClient, electionId);
            return districts;
        } on fail error e {
            log:printError("Failed to get district results for election", electionId = electionId, 'error = e);
            return http:NOT_FOUND;
        }
    }

    // Province Management Endpoints

    // Get all provinces
    resource function get provinces() returns store:ProvinceResult[]|http:InternalServerError {
        do {
            store:ProvinceResult[] provinces = check self.getProvincesFromDB();
            return provinces;
        } on fail error e {
            log:printError("Error fetching provinces", 'error = e);
            return http:INTERNAL_SERVER_ERROR;
        }
    }

    // Get specific province by ID
    resource function get provinces/[string provinceId]() returns store:ProvinceResult|http:NotFound|http:InternalServerError {
        do {
            store:ProvinceResult province = check self.getProvinceByIdFromDB(provinceId);
            return province;
        } on fail error e {
            log:printError("Province not found", provinceId = provinceId, 'error = e);
            return http:NOT_FOUND;
        }
    }

    // Get districts by province ID
    resource function get provinces/[string provinceId]/districts() returns store:District[]|http:NotFound|http:InternalServerError {
        do {
            store:District[] districts = check self.getDistrictsByProvinceFromDB(provinceId);
            if districts.length() == 0 {
                return http:NOT_FOUND;
            }
            return districts;
        } on fail error e {
            log:printError("Error fetching districts for province", provinceId = provinceId, 'error = e);
            return http:INTERNAL_SERVER_ERROR;
        }
    }

    // Election Summary Management

    // Get election summary by ID
    resource function get election/[string electionId]/summary\-stats() returns store:ElectionSummary|http:NotFound|http:InternalServerError {
        do {
            store:ElectionSummary summary = check result:getElectionSummaryById(self.dbClient, electionId);
            return summary;
        } on fail error e {
            log:printError("Failed to get election summary stats", electionId = electionId, 'error = e);
            return http:NOT_FOUND;
        }
    }

    // Update election summary (POST endpoint)
    //weda ne
    resource function post election/[string electionId]/summary\-stats() returns http:Ok|http:InternalServerError {
        do {
            check result:updateElectionSummary(self.dbClient, electionId);
            return http:OK;
        } on fail error e {
            log:printError("Failed to update election summary", electionId = electionId, 'error = e);
            return http:INTERNAL_SERVER_ERROR;
        }
    }

    // Helper methods for election calculations

    // Calculate electoral winner (candidate with most electoral votes)
    private function calculateElectoralWinner(string electionId) returns store:Candidate|error {
        store:Candidate[] candidates = check result:getCandidatesByElection(self.dbClient, electionId);
        
        store:Candidate? winner = candidates.reduce(function(store:Candidate? acc, store:Candidate c) returns store:Candidate? {
            if acc == () {
                return c;
            }
            return (c.electoralVotes ?: 0) > (acc.electoralVotes ?: 0) ? c : acc;
        }, ());
        
        if winner == () {
            return error("No winner found");
        }
        return winner;
    }

    // Calculate popular vote winner
    private function calculatePopularVoteWinner(string electionId) returns store:Candidate|error {
        store:Candidate[] candidates = check result:getCandidatesByElection(self.dbClient, electionId);
        
        store:Candidate? winner = candidates.reduce(function(store:Candidate? acc, store:Candidate c) returns store:Candidate? {
            if acc == () {
                return c;
            }
            return (c.popularVotes ?: 0) > (acc.popularVotes ?: 0) ? c : acc;
        }, ());
        
        if winner == () {
            return error("No winner found");
        }
        return winner;
    }




    // Calculate victory margin
    private function calculateVictoryMargin(string electionId) returns result:VictoryMargin|error {
        store:Candidate[] candidates = check result:getCandidatesByElection(self.dbClient, electionId);
        
        if candidates.length() < 2 {
            return {
                marginType: "INSUFFICIENT_DATA",
                margin: 0.0,
                votes: 0
            };
        }
        
        // Sort by popular votes descending
        store:Candidate[] sortedCandidates = candidates.sort(array:DESCENDING, isolated function(store:Candidate c) returns int {
    return c.popularVotes ?: 0;
});

        
        int firstPlaceVotes = sortedCandidates[0].popularVotes ?: 0;
        int secondPlaceVotes = sortedCandidates[1].popularVotes ?: 0;
        int voteDifference = firstPlaceVotes - secondPlaceVotes;
        
        int totalVotes = candidates.reduce(function(int acc, store:Candidate c) returns int {
            return acc + (c.popularVotes ?: 0);
        }, 0);
        
        decimal marginPercentage = totalVotes > 0 ? <decimal>voteDifference / <decimal>totalVotes * 100.0 : 0.0;
        
        return {
            marginType: "POPULAR_VOTE",
            margin: marginPercentage,
            votes: voteDifference
        };
    }

    // Helper functions for database operations

    private function getDistrictsFromDB() returns store:District[]|error {
        stream<store:District, persist:Error?> districtStream = self.dbClient->/districts.get();
        store:District[] districts = [];
        check from store:District district in districtStream
            do {
                districts.push(district);
            };
        return districts;
    }

    private function getDistrictByIdFromDB(string districtId) returns store:District|error {
        return self.dbClient->/districts/[districtId].get();
    }

    private function getDistrictResultsFromDB(string districtCode) returns store:DistrictResult[]|error {
    sql:ParameterizedQuery whereClause = `WHERE district_code = ${districtCode}`;
    
    stream<store:DistrictResult, persist:Error?> resultStream = 
        self.dbClient->/districtresults.get(whereClause = whereClause);
    
    store:DistrictResult[] results = [];
    check from store:DistrictResult result in resultStream
        do {
            results.push(result);
        };
        
    return results;
}


    private function getProvincesFromDB() returns store:ProvinceResult[]|error {
        stream<store:ProvinceResult, persist:Error?> provinceStream = self.dbClient->/provinceresults.get();
        store:ProvinceResult[] provinces = [];
        check from store:ProvinceResult province in provinceStream
            do {
                provinces.push(province);
            };
        return provinces;
    }

    private function getProvinceByIdFromDB(string provinceId) returns store:ProvinceResult|error {
        return self.dbClient->/provinceresults/[provinceId].get();
    }

    private function getDistrictsByProvinceFromDB(string provinceId) returns store:District[]|error {
    sql:ParameterizedQuery whereClause = `WHERE province_id = ${provinceId}`;
    
    stream<store:District, persist:Error?> districtStream = 
        self.dbClient->/districts.get(whereClause = whereClause);
    
    store:District[] districts = [];
    check from store:District district in districtStream
        do {
            districts.push(district);
        };
    
    return districts;
}


    private function getCurrentTimestamp() returns string|error {
      
        return time:utcToString(time:utcNow());
}
}