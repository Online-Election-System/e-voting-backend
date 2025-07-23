import online_election.common;
import online_election.store;
import online_election.auth;

import ballerina/http;
import ballerina/persist;
import ballerina/crypto;
import ballerina/io;
import online_election.candidate;

final store:Client dbVote = check new ();

// Add the missing type
public type VoterLoginRequest record {|
    string nationalId;
    string password;
|};

// Enhanced authentication function for both user types
public function authenticateVoter(string identifier, string password) returns auth:LoginResponse|http:Unauthorized|error {
    // Create a LoginRequest object for the postLogin function
    auth:LoginRequest loginReq = {
        nic: identifier,
        password: password
    };
    
    // Call the postLogin function from auth module
    auth:LoginResponse|http:Unauthorized|error result = auth:postLogin(loginReq);
    
    if result is auth:LoginResponse {
        // Check if user is eligible to vote (only chief_occupant and household_member)
        if result.userType == "chief_occupant" || result.userType == "household_member" {
            // Modify the message to indicate this is for voting
            result.message = "Authentication successful - Ready to vote";
            io:println("Voter authenticated successfully: ", result.fullName, " (", result.userType, ")");
            return result;
        } else {
            // Block admin/government users from voting
            io:println("User type not eligible for voting: ", result.userType);
            return http:UNAUTHORIZED;
        }
    }
    
    // If authentication failed or returned error, pass it through
    if result is http:Unauthorized {
        io:println("Voter authentication failed for identifier: ", identifier);
    }
    
    return result;
}

// Get voter by ID (unified for both tables)
public function getVoterById(string voterId) returns json|persist:Error {
    // Try ChiefOccupant first
    store:ChiefOccupant|persist:Error chief = dbVote->/chiefoccupants/[voterId].get();
    if chief is store:ChiefOccupant {
        return {
            "id": chief.id,
            "fullName": chief.fullName,
            "nic": chief.nic,
            "email": chief.email,
            "userType": "chief",
            "role": chief.role,
            "dob": chief.dob,
            "gender": chief.gender,
            "phoneNumber": chief.phoneNumber,
            "civilStatus": chief.civilStatus
        };
    }
    
    // Try HouseholdMembers
    store:HouseholdMembers|persist:Error member = dbVote->/householdmembers/[voterId].get();
    if member is store:HouseholdMembers {
        return {
            "id": member.id,
            "fullName": member.fullName,
            "nic": member.nic,
            "userType": "member",
            "role": member.role,
            "chiefOccupantId": member.chiefOccupantId,
            "dob": member.dob,
            "gender": member.gender,
            "civilStatus": member.civilStatus
        };
    }
    
    return error("Voter not found");
}

// Get household details by chief occupant ID
public function getHouseholdDetailsByChiefOccupant(string chiefOccupantId) returns store:HouseholdDetails|error {
    stream<store:HouseholdDetails, persist:Error?> householdStream = dbVote->/householddetails;
    store:HouseholdDetails[] households = check from store:HouseholdDetails household in householdStream
        where household.chiefOccupantId == chiefOccupantId
        select household;
    
    if households.length() == 0 {
        return error("Household details not found for chief occupant: " + chiefOccupantId);
    }
    
    return households[0];
}

// Get household details by any voter ID (chief or member)
public function getHouseholdDetailsByVoterId(string voterId) returns store:HouseholdDetails|error {
    // First check if the voter is a chief occupant
    store:ChiefOccupant|persist:Error chief = dbVote->/chiefoccupants/[voterId].get();
    if chief is store:ChiefOccupant {
        // If it's a chief occupant, get household details directly
        return getHouseholdDetailsByChiefOccupant(voterId);
    }
    
    // If not a chief, check if it's a household member
    store:HouseholdMembers|persist:Error member = dbVote->/householdmembers/[voterId].get();
    if member is store:HouseholdMembers {
        // If it's a household member, get household details through chiefOccupantId
        return getHouseholdDetailsByChiefOccupant(member.chiefOccupantId);
    }
    
    return error("Voter not found or household details not available");
}

// Get complete voter profile with household details
public function getCompleteVoterProfile(string voterId) returns json|error {
    // Get basic voter info
    json|persist:Error voterData = getVoterById(voterId);
    if voterData is persist:Error {
        return error("Voter not found");
    }
    
    // Get household details
    store:HouseholdDetails|error householdDetails = getHouseholdDetailsByVoterId(voterId);
    
    // Combine voter data with household details
    json completeProfile = voterData;
    
    if householdDetails is store:HouseholdDetails {
        // Add household details to the profile
        json householdJson = {
            "electoralDistrict": householdDetails.electoralDistrict,
            "pollingDivision": householdDetails.pollingDivision,
            "pollingDistrictNumber": householdDetails.pollingDistrictNumber,
            "gramaNiladhariDivision": householdDetails.gramaNiladhariDivision,
            "villageStreetEstate": householdDetails.villageStreetEstate,
            "houseNumber": householdDetails.houseNumber,
            "householdMemberCount": householdDetails.householdMemberCount
        };
        
        // Merge household details into the profile
        map<json> profileMap = <map<json>>completeProfile;
        map<json> householdMap = <map<json>>householdJson;
        
        foreach var [key, value] in householdMap.entries() {
            profileMap[key] = value;
        }
        
        completeProfile = profileMap;
    }
    
    return completeProfile;
}

// Get elections where voter is enrolled
public function getVoterEnrolledElections(string voterId) returns store:Election[]|error {
    // Get all enrolments for this voter
    stream<store:Enrolment, persist:Error?> enrolmentStream = dbVote->/enrolments;
    store:Enrolment[] enrolments = check from store:Enrolment enrolment in enrolmentStream
        where enrolment.voterId == voterId
        select enrolment;
    
    io:println("Found ", enrolments.length().toString(), " enrolments for voter: ", voterId);
    
    // Get election details for each enrolment
    store:Election[] elections = [];
    foreach store:Enrolment enrolment in enrolments {
        store:Election|persist:Error election = dbVote->/elections/[enrolment.electionId].get();
        if election is store:Election {
            io:println("Found election: ", election.electionName, " (", election.id, ")");
            elections.push(election);
        }
    }
    
    return elections;
}

// Check if voter is enrolled in specific election
public function isVoterEnrolledInElection(string voterId, string electionId) returns boolean|error {
    stream<store:Enrolment, persist:Error?> enrolmentStream = dbVote->/enrolments;
    store:Enrolment[] enrolments = check from store:Enrolment enrolment in enrolmentStream
        where enrolment.voterId == voterId && enrolment.electionId == electionId
        select enrolment;
    
    boolean isEnrolled = enrolments.length() > 0;
    io:println("Voter ", voterId, " enrolled in election ", electionId, ": ", isEnrolled.toString());
    
    return isEnrolled;
}

// Get district for a voter (from household details)
public function getVoterDistrict(string voterId) returns string|error {
    // Get household details which contain the district
    store:HouseholdDetails|error householdDetails = getHouseholdDetailsByVoterId(voterId);
    
    if householdDetails is error {
        return error("Could not get household details: " + householdDetails.message());
    }
    
    return householdDetails.electoralDistrict;
}

// Enhanced vote casting with enrollment check
public function castVote(Vote newVote) returns http:Created|http:Forbidden|error {
    // Check if voter exists and get voter details
    json|persist:Error voterData = getVoterById(newVote.voterId);
    if voterData is persist:Error {
        return error("Voter not found");
    }

    // Check if election exists
    store:Election|persist:Error election = getElectionById(newVote.electionId);
    if election is persist:Error {
        return error("Election not found");
    }
    
    // Check if election is active for voting
    if election.status != "Active" {
        return error("Election is not currently active for voting");
    }

    // Check if voter is enrolled in this election
    boolean|error isEnrolled = isVoterEnrolledInElection(newVote.voterId, newVote.electionId);
    if isEnrolled is error {
        return error("Failed to check enrollment status: " + isEnrolled.message());
    }
    
    if !isEnrolled {
        return error("Voter is not enrolled in this election");
    }

    // Get voter's district
    string|error district = getVoterDistrict(newVote.voterId);
    if district is error {
        return error("Could not determine voter's district: " + district.message());
    }

    // Hash the voterId before checking for existing votes
    io:println("Raw voterId: ", newVote.voterId);
    byte[] hashedVoterIdBytes = crypto:hashSha256(newVote.voterId.toBytes());
    string hashedVoterId = hashedVoterIdBytes.toBase16();
    io:println("Hashed voterId: ", hashedVoterId);

    // Check for existing vote by this voter for this election
    stream<store:Vote, persist:Error?> existingVotes = dbVote->/votes;
    store:Vote[] votes = check from store:Vote vote in existingVotes
        where vote.voterId == hashedVoterId && vote.electionId == newVote.electionId
        select vote;
    io:println("Found votes: ", votes.length().toString());

    if votes.length() > 0 {
        return error("Vote already exists for this voter in this election");
    }

    // Create new vote with district from household details
    store:VoteInsert voteInsert = {
        id: common:generateId(),
        voterId: hashedVoterId,
        electionId: newVote.electionId,
        candidateId: newVote.candidateId,
        district: district,
        timestamp: common:generateTimestamp()
    };
    
    string[]|persist:Error resultInsert = dbVote->/votes.post([voteInsert]);

    return resultInsert is persist:Error
        ? error("Failed to record vote: " + resultInsert.message())
        : http:CREATED;
}

function getElectionById(string electionId) returns store:Election|persist:Error {
    return dbVote->/elections/[electionId].get();
}

public function getVotesByVoter(string voterId) returns store:Vote[]|error {
    // Hash the voterId before querying
    byte[] hashedVoterIdBytes = crypto:hashSha256(voterId.toBytes());
    string hashedVoterId = hashedVoterIdBytes.toBase16();
    stream<store:Vote, persist:Error?> votesStream = dbVote->/votes;
    store:Vote[] votes = check from store:Vote vote in votesStream
        where vote.voterId == hashedVoterId
        select vote;
    return votes;
}

public function getVotesByElection(string electionId) returns store:Vote[]|error {
    stream<store:Vote, persist:Error?> votesStream = dbVote->/votes;
    store:Vote[] votes = check from store:Vote vote in votesStream
        where vote.electionId == electionId
        select vote;
    return votes;
}

public function getVotesByElectionAndDistrict(string electionId, string district) returns store:Vote[]|error {
    stream<store:Vote, persist:Error?> votesStream = dbVote->/votes;
    store:Vote[] votes = check from store:Vote vote in votesStream
        where vote.electionId == electionId && vote.district == district
        select vote;
    return votes;
}

public function deleteVote(string voteId) returns http:NoContent|http:Forbidden|error {
    _ = check dbVote->/votes/[voteId].delete();
    return http:NO_CONTENT;
}

// Get votes by household (useful for household-level analytics)
public function getVotesByHousehold(string chiefOccupantId, string electionId) returns store:Vote[]|error {
    // Get all household members
    stream<store:HouseholdMembers, persist:Error?> membersStream = dbVote->/householdmembers;
    store:HouseholdMembers[] members = check from store:HouseholdMembers member in membersStream
        where member.chiefOccupantId == chiefOccupantId
        select member;
    
    // Collect all voter IDs (including chief)
    string[] voterIds = [chiefOccupantId];
    foreach store:HouseholdMembers member in members {
        voterIds.push(member.id);
    }
    
    // Hash all voter IDs
    string[] hashedVoterIds = [];
    foreach string voterId in voterIds {
        byte[] hashedVoterIdBytes = crypto:hashSha256(voterId.toBytes());
        string hashedVoterId = hashedVoterIdBytes.toBase16();
        hashedVoterIds.push(hashedVoterId);
    }
    
    // Get votes for all household members
    stream<store:Vote, persist:Error?> votesStream = dbVote->/votes;
    store:Vote[] householdVotes = [];
    
    check from store:Vote vote in votesStream
        where vote.electionId == electionId
        do {
            foreach string hashedVoterId in hashedVoterIds {
                if vote.voterId == hashedVoterId {
                    householdVotes.push(vote);
                    break;
                }
            }
        };
    
    return householdVotes;
}

public function checkVotingEligibility(string voterId, string electionId) returns json|error {
    // Check enrollment
    boolean|error isEnrolled = isVoterEnrolledInElection(voterId, electionId);
    if isEnrolled is error {
        return error("Failed to check enrollment status: " + isEnrolled.message());
    }

    // Check if already voted
    store:Vote[]|error existingVotes = getVotesByVoter(voterId);
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

public function checkVoterEnrollment(string voterId, string electionId) returns json|error {
    boolean|error isEnrolled = isVoterEnrolledInElection(voterId, electionId);

    if isEnrolled is error {
        return error("Failed to check enrollment status: " + isEnrolled.message());
    }

    return {
        "voterId": voterId,
        "electionId": electionId,
        "isEnrolled": isEnrolled
    };
}

public function getEligibleCandidatesForElection(string voterId, string electionId) returns store:Candidate[]|error {
    // Check if voter is enrolled
    boolean|error isEnrolled = isVoterEnrolledInElection(voterId, electionId);
    
    if isEnrolled is error {
        return error("Failed to check enrollment: " + isEnrolled.message());
    }

    if !isEnrolled {
        return error("Voter is not enrolled in this election");
    }

    // Get active candidates
    return candidate:getCandidatesByElection(electionId, true);
}

public function getCandidatesForVoter(string voterId) returns store:Candidate[]|error {
    // Get voter's enrolled elections
    store:Election[]|error enrolledElections = getVoterEnrolledElections(voterId);
    
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


