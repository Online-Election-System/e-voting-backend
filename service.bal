import online_election.auth;
import online_election.election;
import online_election.store;
import ballerina/http;
import ballerina/log;
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




// Response types for API endpoints
public type ElectionSummaryResponse record {|
    string electionId;
    string electionName;
    int totalVotes;
    string lastUpdated;
    store:Candidate[] candidates;
    DistrictInfo[] districts;
    store:ElectionSummary statistics;
    ProvinceAnalysis[]? provinces?;
    PartySummary[]? partySummaries?;
|};

// Fixed district info type for frontend compatibility
public type DistrictInfo record {|
    string districtId;
    string districtName;
    string winningCandidateId;
    int totalVotes;
|};

public type ProvinceAnalysis record {|
    string provinceName;
    int totalVotes;
    int registeredVoters;
    decimal turnoutPercentage;
    string winningCandidateId;
    store:DistrictResult[] districts;
|};

public type PartySummary record {|
    string partyName;
    string partyColor;
    store:Candidate[] candidates;
    int totalElectoralVotes;
    int totalPopularVotes;
    decimal popularVotePercentage;
    int districtsWon;
|};

// Isolated function for sorting by electoral votes
isolated function getElectoralVotes(store:Candidate candidate) returns int {
    return candidate.electoralVotes ?: 0;
}

// Isolated function for sorting by popular votes
isolated function getPopularVotes(store:Candidate candidate) returns int {
    return candidate.popularVotes ?: 0;
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

    private final store:Client dbClient;

    function init() returns error? {
        self.dbClient = check new();
        log:printInfo("Election Results API service started successfully");
    }

    // MAIN ENDPOINT: Get complete election summary
    resource function get election/[string electionId]/summary() returns ElectionSummaryResponse|http:NotFound|http:InternalServerError {
        do {
            log:printInfo("Fetching election summary", electionId = electionId);
            
            store:Election election = check self.getElectionById(electionId);
            store:Candidate[] candidates = check self.getCandidatesByElection(electionId);
            store:DistrictResult[] districtResults = check self.getDistrictResultsByElection(electionId);
            store:ElectionSummary statistics = check self.getElectionSummaryById(electionId);
            
            DistrictInfo[] districts = districtResults.map(function(store:DistrictResult dr) returns DistrictInfo {
                return {
                    districtId: dr.districtCode,
                    districtName: dr.districtName,
                    winningCandidateId: dr.winner ?: "",
                    totalVotes: dr.totalVotes
                };
            });
            
            int totalVotes = candidates.reduce(function(int acc, store:Candidate c) returns int {
                return acc + (c.popularVotes ?: 0);
            }, 0);
            
            ElectionSummaryResponse response = {
                electionId: election.id,
                electionName: election.electionName,
                totalVotes: totalVotes,
                lastUpdated: time:utcToString(time:utcNow()),
                candidates: candidates,
                districts: districts,
                statistics: statistics
            };
            
            log:printInfo("Successfully fetched election summary", electionId = electionId);
            return response;
            
        } on fail error e {
            log:printError("Failed to get election summary", electionId = electionId, 'error = e);
            return http:INTERNAL_SERVER_ERROR;
        }
    }

    resource function get election/[string electionId]() returns store:Election|http:NotFound|http:InternalServerError {
        do {
            store:Election election = check self.getElectionById(electionId);
            return election;
        } on fail error e {
            log:printError("Election not found", electionId = electionId, 'error = e);
            return http:NOT_FOUND;
        }
    }

    resource function get election/[string electionId]/candidates() returns store:Candidate[]|http:NotFound|http:InternalServerError {
        do {
            store:Candidate[] candidates = check self.getCandidatesByElection(electionId);
            return candidates;
        } on fail error e {
            log:printError("Failed to get candidates", electionId = electionId, 'error = e);
            return http:NOT_FOUND;
        }
    }

    resource function get election/[string electionId]/winner() returns store:Candidate|http:NotFound|http:InternalServerError {
        do {
            store:Candidate winner = check self.calculateElectoralWinner(electionId);
            return winner;
        } on fail error e {
            log:printError("Failed to calculate winner", electionId = electionId, 'error = e);
            return http:NOT_FOUND;
        }
    }

    resource function get election/[string electionId]/districts() returns store:DistrictResult[]|http:NotFound|http:InternalServerError {
        do {
            store:DistrictResult[] districts = check self.getDistrictResultsByElection(electionId);
            return districts;
        } on fail error e {
            log:printError("Failed to get district results for election", electionId = electionId, 'error = e);
            return http:NOT_FOUND;
        }
    }

    resource function get election/[string electionId]/summary\-stats() returns store:ElectionSummary|http:NotFound|http:InternalServerError {
        do {
            store:ElectionSummary summary = check self.getElectionSummaryById(electionId);
            return summary;
        } on fail error e {
            log:printError("Failed to get election summary stats", electionId = electionId, 'error = e);
            return http:NOT_FOUND;
        }
    }

    resource function get districts() returns store:District[]|http:InternalServerError {
        do {
            store:District[] districts = check self.getDistrictsFromDB();
            return districts;
        } on fail error e {
            log:printError("Error fetching districts", 'error = e);
            return http:INTERNAL_SERVER_ERROR;
        }
    }

    resource function options [string... path]() returns http:Ok {
        return http:OK;
    }

    resource function get health() returns json {
        return {
            "status": "healthy",
            "service": "election-results-api",
            "timestamp": time:utcToString(time:utcNow())
        };
    }

    // Helper methods

    private function getElectionById(string electionId) returns store:Election|error {
        return self.dbClient->/elections/[electionId].get();
    }

    private function getCandidatesByElection(string electionId) returns store:Candidate[]|error {
        stream<store:Candidate, error?> candidateStream = self.dbClient->/candidates.get();
        
        store:Candidate[] candidates = [];
        check from store:Candidate candidate in candidateStream
            where candidate.electionId == electionId && candidate.isActive == true
            do {
                candidates.push(candidate);
            };
        
        // Try using isolated function - if this doesn't work, use the manual sorting version
        store:Candidate[] sortedCandidates = candidates.clone();
        
        // Manual sorting by electoral votes (descending)
        int n = sortedCandidates.length();
        foreach int i in 0 ..< n - 1 {
            foreach int j in 0 ..< n - i - 1 {
                int currentVotes = sortedCandidates[j].electoralVotes ?: 0;
                int nextVotes = sortedCandidates[j + 1].electoralVotes ?: 0;
                
                if currentVotes < nextVotes {
                    store:Candidate temp = sortedCandidates[j];
                    sortedCandidates[j] = sortedCandidates[j + 1];
                    sortedCandidates[j + 1] = temp;
                }
            }
        }
        
        return sortedCandidates;
    }

    private function getDistrictResultsByElection(string electionId) returns store:DistrictResult[]|error {
        stream<store:DistrictResult, error?> districtStream = self.dbClient->/districtresults.get();
        
        store:DistrictResult[] districts = [];
        check from store:DistrictResult district in districtStream
            where district.electionId == electionId
            do {
                districts.push(district);
            };
        
        return districts;
    }

    private function getElectionSummaryById(string electionId) returns store:ElectionSummary|error {
        return self.dbClient->/electionsummaries/[electionId].get();
    }

    private function getDistrictsFromDB() returns store:District[]|error {
        stream<store:District, error?> districtStream = self.dbClient->/districts.get();
        store:District[] districts = [];
        check from store:District district in districtStream
            do {
                districts.push(district);
            };
        return districts;
    }

    private function calculateElectoralWinner(string electionId) returns store:Candidate|error {
        store:Candidate[] candidates = check self.getCandidatesByElection(electionId);
        
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
}