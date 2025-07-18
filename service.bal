import online_election.election;
import online_election.store;
import online_election.candidate;
import ballerina/http;
import online_election.vote;
import ballerina/persist;


listener http:Listener SharedListener = new (8080);

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type", "Authorization"],
        allowCredentials: true
    }
}
service /voter\-registration/api/v1 on SharedListener {
    // Register a new voter (if you have this functionality)
    resource function post voters/register(store:Voter newVoter)
    returns http:Created|http:Forbidden|error {
        // Your registration logic here
        return http:CREATED;
    }

    // Voter Login - FIXED VERSION
    resource function post voters/login(VoterLoginRequest loginDetails)
    returns VoterResponse|http:Unauthorized|error {
        
        // Use the authentication function from vote module
        store:Voter|http:Unauthorized|error authResult = vote:authenticateVoter(loginDetails.nationalId, loginDetails.password);
        
        if authResult is http:Unauthorized {
            return http:UNAUTHORIZED; // Wrong credentials
        }
        
        if authResult is error {
            return error("Authentication failed: " + authResult.message());
        }
        
        // Authentication successful - return voter data
        store:Voter voter = authResult;
        
        VoterResponse response = {
            id: voter.id,
            nationalId: voter.nationalId,
            fullName: voter.fullName,
            district: voter.district,
            mobileNumber: voter.mobileNumber,
            dob: voter.dob,
            gender: voter.gender,
            address: voter.address,
            gramaNiladhari: voter.gramaNiladhari,
            householdNo: voter.householdNo,
            nicChiefOccupant: voter.nicChiefOccupant,
            status: "eligible" // You can add logic to determine this
        };
        
        return response;
    }
}

// Add these types
public type VoterLoginRequest record {|
    string nationalId;
    string password;
|};

public type VoterResponse record {|
    string id;
    string nationalId;
    string fullName;
    string district;
    string? mobileNumber;
    string? dob;
    string? gender;
    string? address;
    string? gramaNiladhari;
    string? householdNo;
    string? nicChiefOccupant;
    string status;
|};

// Add CORS to election service as well
@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowHeaders: ["Content-Type", "Authorization"],
        allowCredentials: true
    }
}
service /election/api/v1 on SharedListener {
    resource function get elections() returns store:Election[]|error {
        return check election:getElections();
    }

    resource function get elections/[string electionId]() returns store:Election|error {
        return check election:getElectionById(electionId);
    }

    resource function post elections/create(@http:Header string authorization, election:ElectionConfig newElectionConfig)
    returns http:Created|http:Forbidden|error {
        return check election:createElection(newElectionConfig);
    }

    resource function put elections/[string electionId]/update(@http:Header string authorization, store:ElectionUpdate updatedElection)
    returns http:Ok|http:Forbidden|error {
        return check election:updateElection(electionId, updatedElection);
    }

    resource function delete elections/[string electionId]/delete(@http:Header string authorization)
    returns http:NoContent|http:Forbidden|error {
        return check election:deleteElection(electionId);
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
    
    // Get all active candidates from database
    resource function get candidates() returns store:Candidate[]|error {
        return check candidate:getAllActiveCandidates();
    }
    
    // Get candidate by ID from database
    resource function get candidates/[string candidateId]() returns store:Candidate|http:NotFound|error {
        store:Candidate|persist:Error candidate = candidate:getCandidateById(candidateId);
        
        if candidate is persist:Error {
            return http:NOT_FOUND;
        }
        
        return candidate;
    }
    
    // Get candidates by election and party
    resource function get elections/[string electionId]/candidates/party/[string partyName]() returns store:Candidate[]|error {
        return check candidate:getCandidatesByElectionAndParty(electionId, partyName);
    }
    
    // Check if candidate is active
    resource function get candidates/[string candidateId]/active() returns boolean|error {
        return check candidate:isCandidateActive(candidateId);
    }
}