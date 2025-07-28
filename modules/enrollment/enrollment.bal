import ballerina/http;
import ballerina/persist;
import ballerina/time;
import ballerina/crypto;
import ballerina/sql;

import codeCrew/online_election.store;

final store:Client dbClient = check new ();

// ----- Helper Functions -----

// Bcrypt hashing function for new passwords
function hashPassword(string password) returns string|error {
    return crypto:hashBcrypt(password, 12); // 12 is the work factor (cost)
}

// Fixed checkPassword function for bcrypt verification
function checkPassword(string plainPassword, string hashedPassword) returns boolean {
    // Use Ballerina's crypto module to verify bcrypt hash
    boolean|crypto:Error result = crypto:verifyBcrypt(plainPassword, hashedPassword);
    if result is boolean {
        return result;
    }
    return false;
}

// Helper to create a standardized error JSON response
function createErrorResponse(string message) returns ApiResponse {
    return { success: false, message: message };
}

// Helper to find a user in either ChiefOccupant or HouseholdMembers tables
function findUserByNic(string nic) returns store:ChiefOccupant|store:HouseholdMembers|error {
    sql:ParameterizedQuery chiefWhere = `nic = ${nic}`;
    stream<store:ChiefOccupant, persist:Error?> chiefStream = dbClient->/chiefoccupants(whereClause = chiefWhere);
    var chiefResult = chiefStream.next();
    check chiefStream.close();
    if chiefResult is record {| store:ChiefOccupant value; |} {
        return chiefResult.value;
    }

    sql:ParameterizedQuery memberWhere = `nic = ${nic}`;
    stream<store:HouseholdMembers, persist:Error?> memberStream = dbClient->/householdmembers(whereClause = memberWhere);
    var memberResult = memberStream.next();
    check memberStream.close();
    if memberResult is record {| store:HouseholdMembers value; |} {
        return memberResult.value;
    }

    return error("User with NIC " + nic + " not found.");
}

public function getUserProfile(string nic) returns UserProfile|http:NotFound|error {
    // 1. Get basic user details from ChiefOccupant or HouseholdMembers tables
    var person = findUserByNic(nic);
    if person is error {
        return http:NOT_FOUND;
    }

    string chiefOccupantId = (person is store:ChiefOccupant) ? person.id : person.chiefOccupantId;

    // 2. Get address details from HouseholdDetails table
    sql:ParameterizedQuery hhWhere = `chief_occupant_id = ${chiefOccupantId}`;
    stream<store:HouseholdDetails, persist:Error?> hhStream = dbClient->/householddetails(whereClause = hhWhere);
    var hhResult = hhStream.next();
    check hhStream.close();

    if hhResult is record {| store:HouseholdDetails value; |} {
        store:HouseholdDetails hhDetails = hhResult.value;
    
        // 3. --- Conditional Logic for Approved Voters ---
        EnrolledElection[] enrolledElections = [];
        string? voterStatus = ();
        time:Date? registrationDate = ();

        // Try to find the user in the Voter table
        sql:ParameterizedQuery voterWhere = `national_id = ${nic}`;
        stream<store:Voter, persist:Error?> voterStream = dbClient->/voters(whereClause = voterWhere);
        var voterResult = voterStream.next();
        check voterStream.close();

        // If a voter record IS found, then fetch their enrollments
        if voterResult is record {| store:Voter value; |} {
            store:Voter voter = voterResult.value;
            voterStatus = voter.status;
            registrationDate = voter.registrationDate;
        
            string voterIdStr = voter.id;
            sql:ParameterizedQuery enrolmentWhere = `voter_id = ${voterIdStr}`;
            stream<store:Enrolment, persist:Error?> enrolmentStream = dbClient->/enrolments(whereClause = enrolmentWhere);
            store:Enrolment[] enrolments = check from store:Enrolment e in enrolmentStream select e;
            
            foreach var enrolment in enrolments {
                store:Election|persist:Error election = dbClient->/elections/[enrolment.electionId];
                if election is store:Election {
                    enrolledElections.push({
                        electionId: election.id,
                        title: election.electionName,
                        electionDate: election.electionDate,
                        status: election.status,
                        enrollmentDate: enrolment.enrollementDate
                    });
                }
            }
        }
        
        // 4. Assemble and return the complete, unified profile
        return {
            fullName: person.fullName,
            nic: nic,
            email: (person is store:ChiefOccupant) ? person.email : "",
            dob: person.dob,
            gender: person.gender,
            civilStatus: person.civilStatus,
            role: person.role,
            electoralDistrict: hhDetails.electoralDistrict,
            pollingDivision: hhDetails.pollingDivision,
            fullAddress: (hhDetails.houseNumber ?: "") + ", " + (hhDetails.villageStreetEstate ?: ""),
            voterStatus: voterStatus,
            registrationDate: registrationDate,
            enrolledElections: enrolledElections
        };
    } else {
        return error("Critical: Household details not found for user NIC: " + nic);
    }
}

// ----- Election and Enrollment Logic Functions -----

public function getAllElections(string? voterId = (), string? voterNic = ()) returns ElectionWithEnrollment[]|error {
    string actualVoterId;
    
    // If voterNic is provided, convert it to voter ID
    if (voterNic is string) {
        sql:ParameterizedQuery voterWhere = `national_id = ${voterNic}`;
        stream<store:Voter, persist:Error?> voterStream = dbClient->/voters(whereClause = voterWhere);
        var voterResult = voterStream.next();
        check voterStream.close();
        
        if (voterResult is record {| store:Voter value; |}) {
            actualVoterId = voterResult.value.id;
        } else {
            return error("Voter not found with NIC: " + voterNic);
        }
    } else if (voterId is string) {
        actualVoterId = voterId;
    } else {
        return error("Either voterId or voterNic must be provided");
    }
    
    // 1. Fetch all elections, sorted by start date
    sql:ParameterizedQuery orderBy = `start_date`; 
    stream<store:Election, persist:Error?> allElectionsStream = dbClient->/elections(orderByClause = orderBy);
    store:Election[] allElections = check from store:Election e in allElectionsStream select e;
    
    // 2. Fetch all of the current voter's enrollments into a map for efficient lookup
    sql:ParameterizedQuery enrolmentWhere = `voter_id = ${actualVoterId}`;
    stream<store:Enrolment, persist:Error?> enrolmentStream = dbClient->/enrolments(whereClause = enrolmentWhere);
    
    map<boolean> enrolledMap = {};
    check from store:Enrolment e in enrolmentStream
        do {
            enrolledMap[e.electionId] = true;
        };
    
    // 3. Combine the data
    ElectionWithEnrollment[] result = [];
    foreach var election in allElections {
        result.push({
            id: election.id, title: election.electionName, description: election.description,
            startDate: election.startDate, endDate: election.endDate,
            enrollmentDeadline: election.enrolDdl, electionDate: election.electionDate,
            noOfCandidates: election.noOfCandidates, electionType: election.electionType,
            startTime: election.startTime, endTime: election.endTime,
            status: election.status, enrolled: enrolledMap.hasKey(election.id)
        });
    }

    return result;
}

public function getElectionWithCandidates(string electionId) returns ElectionDetailsWithCandidates|http:NotFound|error {
    // 1. Fetch the election details
    store:Election|persist:Error election = dbClient->/elections/[electionId];
    if election is persist:Error {
        return http:NOT_FOUND;
    }

    // 2. First, get all candidate IDs for this election from the 'EnrolCandidates' linking table.
    sql:ParameterizedQuery enrolWhere = `election_id = ${electionId}`;
    stream<store:EnrolCandidates, persist:Error?> enrolStream = dbClient->/enrolcandidates(whereClause = enrolWhere);
    store:EnrolCandidates[] enrolments = check from store:EnrolCandidates ec in enrolStream select ec;
    
    string[] candidateIds = from var enrolment in enrolments select enrolment.candidateId;

    store:Candidate[] candidates = [];
    if candidateIds.length() > 0 {
        // 3. Now, fetch the full details for only those candidates from the 'Candidate' table.
        sql:ParameterizedQuery candidateWhere = `candidate_id = ANY(${candidateIds})`;
        stream<store:Candidate, persist:Error?> candidateStream = dbClient->/candidates(whereClause = candidateWhere);
        candidates = check from store:Candidate c in candidateStream select c;
    }

    // 4. Assemble and return the combined record
    return {
        id: election.id, 
        name: election.electionName, 
        description: election.description,
        startDate: election.startDate, 
        enrolDeadline: election.enrolDdl,
        electionDate: election.electionDate, 
        endDate: election.endDate,
        noOfCandidates: election.noOfCandidates, 
        'type: election.electionType,
        startTime: election.startTime, 
        endTime: election.endTime,
        status: election.status, 
        candidates: candidates
    };
}

public function enrollInElection(string electionId, VoterVerificationRequest verificationPayload) 
returns http:Created|ApiResponse|error {
    // 1. First verify the election exists and is open for enrollment
    store:Election|persist:Error election = dbClient->/elections/[electionId];
    if election is persist:Error {
        return createErrorResponse("Election not found");
    }
    if election.status != "Open for Enrollment" {
        return createErrorResponse("Election is not open for enrollment");
    }

    // 2. Get voter by national_id
    sql:ParameterizedQuery query = `national_id = ${verificationPayload.nationalId}`;
    stream<store:VoterOptionalized, persist:Error?> result = dbClient->/voters(targetType = store:VoterOptionalized, whereClause = query);
    var voterData = result.next();
    check result.close();
    
    if voterData is () {
        return createErrorResponse("Invalid credentials - user not found");
    } 
    if voterData is error {
        return error("Database error: " + voterData.message());
    }

    string? voterIdStr = voterData.value.id;
    string? storedPasswordHash = voterData.value.password;
    
    if voterIdStr is () || storedPasswordHash is () {
        return createErrorResponse("Invalid voter data");
    }
    
    // 3. Verify password
    boolean passwordValid = checkPassword(verificationPayload.password, storedPasswordHash);
    if !passwordValid {
        return createErrorResponse("Invalid credentials - wrong password");
    }
    
    string voterId = voterIdStr;

    // 4. Check existing enrollment
    sql:ParameterizedQuery enrollmentCheck = `voter_id = ${voterId} AND election_id = ${electionId}`;
    stream<store:EnrolmentOptionalized, persist:Error?> enrollmentResult = dbClient->/enrolments(targetType = store:EnrolmentOptionalized, whereClause = enrollmentCheck);
    var enrollmentCheckResult = enrollmentResult.next();
    check enrollmentResult.close();
    
    if enrollmentCheckResult is record {| anydata...; |} {
        return createErrorResponse("Already enrolled");
    }

    // 5. Create enrollment
    store:EnrolmentInsert newEnrollment = {
        voterId: voterId,
        electionId: electionId,
        enrollementDate: time:utcNow()
    };
    
    _ = check dbClient->/enrolments.post([newEnrollment]);

    return <http:Created>{
        body: {
            success: true,
            voterId: voterId,
            message: "Enrollment successful"
        }
    };
}