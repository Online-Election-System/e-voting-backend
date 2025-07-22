import online_election.auth;
import online_election.election;
import online_election.store;

import ballerina/http;
import online_election.vote;
import online_election.candidate;

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

    // Check if voter is enrolled in specific election - NEW ENDPOINT
    resource function get voter/[string voterId]/election/[string electionId]/enrolled() returns json|error {
        boolean|error isEnrolled = vote:isVoterEnrolledInElection(voterId, electionId);
        
        if isEnrolled is error {
            return error("Failed to check enrollment status: " + isEnrolled.message());
        }
        
        return {
            "voterId": voterId,
            "electionId": electionId,
            "isEnrolled": isEnrolled
        };
    }

    // Get elections for a specific voter (enrolled elections only) - NEW ENDPOINT
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
        // Check enrollment
        boolean|error isEnrolled = vote:isVoterEnrolledInElection(voterId, electionId);
        if isEnrolled is error {
            return error("Failed to check enrollment status: " + isEnrolled.message());
        }

        // Check if already voted
        store:Vote[]|error existingVotes = vote:getVotesByVoter(voterId);
        boolean alreadyVoted = false;
        
        if existingVotes is store:Vote[] {
            foreach store:Vote vote in existingVotes {
                if vote.electionId == electionId {
                    alreadyVoted = true;
                    break;
                }
            }
        }

        return {
            "voterId": voterId,
            "electionId": electionId,
            "isEnrolled": isEnrolled,
            "alreadyVoted": alreadyVoted,
            "eligible": isEnrolled && !alreadyVoted
        };
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
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type", "Authorization"],
        allowCredentials: true
    }
}
service /candidate/api/v1 on SharedListener {



    // Get all candidates - No change needed
    resource function get candidates() returns store:Candidate[]|error {
        return check candidate:getCandidates();
    }

    // Get candidates by election ID - Updated to use new enrollment system
    resource function get elections/[string electionId]/candidates() returns store:Candidate[]|error {
        return check candidate:getCandidatesByElection(electionId, ()); // Pass null for activeOnly to get all
    }

    // Get active candidates by election - Updated to use new enrollment system
    resource function get elections/[string electionId]/candidates/active() returns store:Candidate[]|error {
        return check candidate:getCandidatesByElection(electionId, true); // Pass true for activeOnly
    }

    // Get candidates for elections where voter is enrolled - Updated logic
    resource function get voter/[string voterId]/candidates() returns store:Candidate[]|error {
        // Get voter's enrolled elections
        store:Election[]|error enrolledElections = vote:getVoterEnrolledElections(voterId);
        
        if enrolledElections is error {
            return error("Failed to get voter's enrolled elections: " + enrolledElections.message());
        }
        
        // Get candidates for all enrolled elections (active only)
        store:Candidate[] allCandidates = [];
        foreach store:Election election in enrolledElections {
            store:Candidate[]|error electionCandidates = candidate:getCandidatesByElection(election.id, true);
            if electionCandidates is store:Candidate[] {
                foreach store:Candidate cand in electionCandidates {
                    allCandidates.push(cand);
                }
            }
        }
        
        return allCandidates;
    }

    // Get candidates for a specific election if voter is enrolled - Updated logic
    resource function get voter/[string voterId]/election/[string electionId]/candidates() returns store:Candidate[]|error {
        // Check if voter is enrolled in this election
        boolean|error isEnrolled = vote:isVoterEnrolledInElection(voterId, electionId);
        
        if isEnrolled is error {
            return error("Failed to check enrollment: " + isEnrolled.message());
        }
        
        if !isEnrolled {
            return error("Voter is not enrolled in this election");
        }
        
        // Get active candidates for this election
        return check candidate:getCandidatesByElection(electionId, true);
    }

    // Get candidate by ID - No change needed
    resource function get candidates/[string candidateId]() returns store:Candidate|http:NotFound|error {
        store:Candidate|error candidateData = candidate:getCandidateById(candidateId);

        if candidateData is error {
            return http:NOT_FOUND;
        }

        return candidateData;
    }

    // Get candidates by party - Updated to use new structure
    resource function get candidates/party/[string partyName]() returns store:Candidate[]|error {
        return check candidate:getCandidatesByParty(partyName, true); // Get active candidates only
    }

   
   


}