import ballerina/http;
import ballerina/persist;
import ballerina/time;
import ballerina/crypto;
import ballerina/log;
import ballerina/sql;

// Correctly import the persist store and the new types module
import codeCrew/online_election.store;

// Initialize the persist client
final store:Client dbClient = check new ();

// ----- Helper Functions -----

// A simple hashing function (replace with a secure one like bcrypt in production)
function hashPassword(string password) returns string {
    return crypto:hashSha256(password.toBytes()).toBase16();
}

// Helper to create a standardized error JSON response
function createErrorResponse(string message) returns ApiResponse {
    return { success: false, message: message };
}


// ----- Voter Logic Functions -----

public function loginVoter(LoginRequest payload) returns ApiResponse|error {
    // 1. Find the voter by their national ID
    sql:ParameterizedQuery whereClause = `national_id = ${payload.nationalId}`;
    stream<store:Voter, persist:Error?> voterStream = dbClient->/voters(whereClause = whereClause);
    
    var voterResult = voterStream.next();
    check voterStream.close();
    
    // Proper type checking before field access
    if voterResult is () {
        return createErrorResponse("Invalid credentials nic");
    } else if voterResult is error {
        return createErrorResponse("Database error: " + voterResult.message());
    } else if voterResult is record {| store:Voter value; |} {
        store:Voter voter = voterResult.value;

        // 2. Verify the password
        if hashPassword(payload.password) != voter.password {
            return createErrorResponse("Invalid credentials pw");
        }

        // 3. Return success response
        return {
            success: true,
            message: "Login successful",
            data: { 
                user: { 
                    id: voter.id, 
                    nationalId: voter.nationalId, 
                    name: voter.name, 
                    district: voter.district 
                } 
            }
        };
    }
}

public function getVoterProfile(int voterId) returns VoterProfile|http:NotFound|error {
    // 1. Get the voter's main profile details
    store:Voter|persist:Error voter = dbClient->/voters/[voterId];
    if voter is persist:Error {
        return http:NOT_FOUND;
    }

    // 2. Get all elections the voter is enrolled in
    string voterIdStr = voterId.toString();
    sql:ParameterizedQuery enrolmentWhere = `voter_id = ${voterIdStr}`;
    stream<store:Enrolment, persist:Error?> enrolmentStream = dbClient->/enrolments(whereClause = enrolmentWhere);
    store:Enrolment[] enrolments = check from store:Enrolment e in enrolmentStream select e;
    
    // 3. Fetch details for each enrolled election
    EnrolledElection[] enrolledElections = [];
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
    
    // 4. Assemble and return the complete profile
    return {
        id: voter.id, nationalId: voter.nationalId, name: voter.name,
        district: voter.district, pollingStation: voter.pollingStation,
        registrationDate: voter.registrationDate, status: voter.status,
        enrolledElections: enrolledElections
    };
}

// ----- Election and Enrollment Logic Functions -----

public function getAllElections(int voterId) returns ElectionWithEnrollment[]|error {
    // 1. Fetch all elections, sorted by start date
    // CORRECTED: The "ORDER BY" keyword is removed. 
    // The persist client only needs the column name.
    sql:ParameterizedQuery orderBy = `start_date`; 
    stream<store:Election, persist:Error?> allElectionsStream = dbClient->/elections(orderByClause = orderBy);
    store:Election[] allElections = check from store:Election e in allElectionsStream select e;
    
    // 2. Fetch all of the current voter's enrollments into a map for efficient lookup
    string voterIdStr = voterId.toString();
    sql:ParameterizedQuery enrolmentWhere = `voter_id = ${voterIdStr}`;
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
        sql:ParameterizedQuery candidateWhere = `candidate_id IN (${candidateIds})`;
        stream<store:Candidate, persist:Error?> candidateStream = dbClient->/candidates(whereClause = candidateWhere);
        candidates = check from store:Candidate c in candidateStream select c;
    }

    // 4. Assemble and return the combined record
    return {
        id: election.id, name: election.electionName, description: election.description,
        startDate: election.startDate, enrolDeadline: election.enrolDdl,
        electionDate: election.electionDate, endDate: election.endDate,
        noOfCandidates: election.noOfCandidates, 'type: election.electionType,
        startTime: election.startTime, endTime: election.endTime,
        status: election.status, candidates: candidates
    };
}

public function enrollInElection(string electionId, VoterVerificationRequest verificationPayload) returns http:Created|ApiResponse|error {
    // 1. Verify Voter Credentials
    sql:ParameterizedQuery whereClause = `national_id = ${verificationPayload.nationalId}`;
    stream<store:Voter, persist:Error?> voterStream = dbClient->/voters(whereClause = whereClause);

    var voterResult = voterStream.next();
    check voterStream.close();

    // Proper type checking before field access
    if voterResult is () {
        return createErrorResponse("Verification Failed: Voter with this National ID not found.");
    } else if voterResult is error {
        return createErrorResponse("Database error during verification: " + voterResult.message());
    } else if voterResult is record {| store:Voter value; |} {
        store:Voter voter = voterResult.value;

        // --- All subsequent logic is now safely nested inside this block ---

        if voter.name != verificationPayload.fullName {
            return createErrorResponse("Verification Failed: Full name does not match.");
        }
        if hashPassword(verificationPayload.password) != voter.password {
            return createErrorResponse("Verification Failed: Invalid password.");
        }

        // 2. Check if election is open for enrollment
        store:Election|persist:Error election = dbClient->/elections/[electionId];
        if election is persist:Error || election.status != "Open for Enrollment" {
            return createErrorResponse("Election not found or not currently open for enrollment.");
        }

        // 3. Check if voter is already enrolled
        string voterIdStr = voter.id.toString();
        store:Enrolment|persist:Error existingEnrolment = dbClient->/enrolments/[voterIdStr]/[electionId];
        if existingEnrolment is store:Enrolment {
            return createErrorResponse("You are already enrolled in this election.");
        }
        
        // 4. Create new enrollment record
        store:EnrolmentInsert newEnrolment = {
            voterId: voterIdStr,
            electionId: electionId,
            enrollementDate: time:utcNow()
        };
        _ = check dbClient->/enrolments.post([newEnrolment]);

        // 5. Update election status to 'Enrolled'
        store:ElectionUpdate electionUpdate = {
            status: "Enrolled"
        };
        _ = check dbClient->/elections/[electionId].put(electionUpdate);

        log:printInfo("Enrollment successful for voter " + voterIdStr + " in election " + electionId);
        return http:CREATED;
    }
    
}