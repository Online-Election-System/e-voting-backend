import ballerina/http;
import ballerina/io;
import ballerina/sql;
import ballerinax/postgresql;

// Database client configuration
configurable string host = ?;
configurable int port = ?;
configurable string user = ?;
configurable string password = ?;
configurable string database = ?;

// Server port configuration
configurable int serverPort = 8081;

// Create a singleton database client
final postgresql:Client dbClient = check new (
    username = user,
    password = password,
    host = host,
    port = port,
    database = database
);

// Create a SINGLE listener
listener http:Listener httpListener = new (8081);

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowHeaders: ["Content-Type", "Authorization"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allowCredentials: true
    }
}

service on httpListener {

// === VOTER ENDPOINTS ===
// Login endpoint
resource function post voter/login(@http:Payload LoginRequest payload) returns ApiResponse|error {
    // Validate input
    if (payload.nationalId == "" || payload.password == "") {
        return createErrorResponse("National ID and password are required");
    }

    // Hash the password for comparison
    string hashedPassword = hashPassword(payload.password);

    // Query the database for the user
    stream<record {}, sql:Error?> voterStream = dbClient->query(
        `SELECT id, national_id, name, password, district, polling_station, status 
        FROM voters WHERE national_id = ${payload.nationalId}`
    );
        
    record {}|sql:Error? result = voterStream.next();
        check voterStream.close();
        
    if (result is sql:Error) {
        return createErrorResponse("Database error: " + result.message());
    }
        
    if (result == ()) {
        return createErrorResponse("Invalid credentials");
    }
        
    map<anydata> voterMap = <map<anydata>>result;
    io:println("Available keys in result: ", voterMap.keys());
    map<anydata> rowData = <map<anydata>>voterMap.get("value");
    io:println("Keys in row data: ", rowData.keys());
        
    int id = <int>rowData.get("id");
    string national_id = <string>rowData.get("national_id");
    string name = <string>rowData.get("name");
    string password = <string>rowData.get("password");
    string district = <string>rowData.get("district");
    string _ = <string>rowData.get("polling_station");
    string _ = <string>rowData.get("status");

    // Verify password
    if (hashedPassword != password) {
        return createErrorResponse("Invalid credentials");
    }
    return {
            success: true,
            message: "Login successful",
            data: {
                "user": {
                    "id": id,
                    "nationalId": national_id,
                    "name": name,
                    "district": district
                }
            }
    };
}

// GET /voter/profile/{id}
resource function get voter/profile/[string id]() returns ApiResponse|error {
    if id == "" {
        return createErrorResponse("Voter ID is required");
    }

    int voterId = check int:fromString(id);

    // Query voter profile
    stream<record {}, sql:Error?> voterStream = dbClient->query(
        `SELECT id, national_id, name, district, polling_station, registration_date, status
         FROM voters
         WHERE id = ${voterId}`
    );

    record {}|sql:Error? result = voterStream.next();
    check voterStream.close();

    if result is sql:Error {
        return createErrorResponse("Database error: " + result.message());
    }

    if result == () {
        return createErrorResponse("Voter not found");
    }

    map<anydata> voterMap = <map<anydata>>result;
    map<anydata> row = <map<anydata>>voterMap.get("value");

    map<string|int> voterProfile = {
        id: <int>row.get("id"),
        national_id: <string>row.get("national_id"),
        name: <string>row.get("name"),
        district: <string>row.get("district"),
        polling_station: <string>row.get("polling_station"),
        registration_date: <string>row.get("registration_date"),
        status: <string>row.get("status")
    };

    // Query enrollments with election details
    stream<record {}, sql:Error?> enrollmentsStream = dbClient->query(
        `SELECT e.voter_id, e.election_id, e.enrollment_date,
         el.title, el.start_date, el.end_date, el.status
         FROM enrollments e
         JOIN elections el ON e.election_id = el.id
         WHERE e.voter_id = ${voterId}`
    );

    record {| 
        int voter_id;
        int election_id;
        string enrollment_date;
        string title;
        string start_date;
        string end_date;
        string status;
    |}[] enrollments = [];

    record {}|sql:Error? enrollmentResult = enrollmentsStream.next();
    while (enrollmentResult is record {}) {
        map<anydata> enrollmentMap = <map<anydata>>enrollmentResult;
        map<anydata> enrollmentRowData = <map<anydata>>enrollmentMap.get("value");

        enrollments.push({
            voter_id: <int>enrollmentRowData.get("voter_id"),
            election_id: <int>enrollmentRowData.get("election_id"),
            enrollment_date: <string>enrollmentRowData.get("enrollment_date"),
            title: <string>enrollmentRowData.get("title"),
            start_date: <string>enrollmentRowData.get("start_date"),
            end_date: <string>enrollmentRowData.get("end_date"),
            status: <string>enrollmentRowData.get("status")
        });

        enrollmentResult = enrollmentsStream.next();
    }
    check enrollmentsStream.close();

    if (enrollmentResult is sql:Error) {
        return createErrorResponse("Error retrieving enrollments: " + enrollmentResult.message());
    }

    // Return combined response
    return createSuccessResponse({
    id: voterProfile["id"],
    nationalId: voterProfile["national_id"],
    name: voterProfile["name"],
    district: voterProfile["district"],
    pollingStation: voterProfile["polling_station"],
    registrationDate: voterProfile["registration_date"],
    status: voterProfile["status"],
    enrolledElections: enrollments
});

}
    
// === ELECTIONS ENDPOINTS =
// Get all elections
resource function get elections(@http:Query int voterId) returns ApiResponse|error {

    // Get all elections
    stream<record {}, sql:Error?> electionsStream = dbClient->query(
        `SELECT id, election_name, description, start_date, enrol_ddl, election_date,
                end_date, no_of_candidates, election_type, start_time, end_time, status
         FROM elections
         ORDER BY start_date ASC`
    );

    record {|
        int id;
        string election_name;
        string description;
        string start_date;
        string enrol_ddl;
        string election_date;
        string end_date;
        int no_of_candidates;
        string election_type;
        string start_time;
        string end_time;
        string status;
    |}[] elections = [];

    record {}|sql:Error? electionResult = electionsStream.next();
    while (electionResult is record {}) {
        map<anydata> electionMap = <map<anydata>>electionResult;
        map<anydata> electionRowData = <map<anydata>>electionMap.get("value");

        elections.push({
            id: <int>electionRowData.get("id"),
            election_name: <string>electionRowData.get("election_name"),
            description: <string>electionRowData.get("description"),
            start_date: <string>electionRowData.get("start_date"),
            enrol_ddl: <string>electionRowData.get("enrol_ddl"),
            election_date: <string>electionRowData.get("election_date"),
            end_date: <string>electionRowData.get("end_date"),
            no_of_candidates: <int>electionRowData.get("no_of_candidates"),
            election_type: <string>electionRowData.get("election_type"),
            start_time: <string>electionRowData.get("start_time"),
            end_time: <string>electionRowData.get("end_time"),
            status: <string>electionRowData.get("status")
        });

        electionResult = electionsStream.next();
    }
    check electionsStream.close();

    if (electionResult is sql:Error) {
        return createErrorResponse("Error retrieving elections: " + electionResult.message());
    }

    // Get enrollments for this voter
    stream<record {}, sql:Error?> enrollmentsStream = dbClient->query(
        `SELECT election_id FROM enrollments WHERE voter_id = ${voterId}`
    );

    record {| int election_id; |}[] enrollmentRecords = [];

    record {}|sql:Error? enrollmentResult = enrollmentsStream.next();
    while (enrollmentResult is record {}) {
        map<anydata> enrollmentMap = <map<anydata>>enrollmentResult;
        map<anydata> enrollmentRowData = <map<anydata>>enrollmentMap.get("value");

        enrollmentRecords.push({
            election_id: <int>enrollmentRowData.get("election_id")
        });

        enrollmentResult = enrollmentsStream.next();
    }
    check enrollmentsStream.close();

    if (enrollmentResult is sql:Error) {
        return createErrorResponse("Error retrieving enrollments: " + enrollmentResult.message());
    }

    // Create a map of enrolled election IDs
    map<boolean> enrolledElections = {};
    foreach var enrollment in enrollmentRecords {
        enrolledElections[enrollment.election_id.toString()] = true;
    }

    // Add enrollment status to each election
    ElectionWithEnrollment[] electionsWithStatus = [];
    foreach var election in elections {
        boolean enrolled = enrolledElections.hasKey(election.id.toString());
        electionsWithStatus.push({
            id: election.id,
            title: election.election_name,
            description: election.description,
            startDate: election.start_date,
            endDate: election.end_date,
            enrollmentDeadline: election.enrol_ddl,
            electionDate: election.election_date,
            noOfCandidates: election.no_of_candidates,
            electionType: election.election_type,
            startTime: election.start_time,
            endTime: election.end_time,
            status: election.status,
            enrolled: enrolled
        });
    }

    return createSuccessResponse(electionsWithStatus);
}

// POST /elections/{electionId}/enroll
// Enroll in an election
resource function post elections/[int electionId]/enroll/[int voterId]() returns ApiResponse|error {

    // Check if election exists and is open for enrollment
    stream<record {}, sql:Error?> electionStream = dbClient->query(
        `SELECT id FROM elections 
         WHERE id = ${electionId} AND status = 'Open for Enrollment'`
    );

    record {}|sql:Error? result = electionStream.next();
    check electionStream.close();

    if (result is sql:Error) {
        return createErrorResponse("Database error: " + result.message());
    }

    if (result == ()) {
        return createErrorResponse("Election not found or not open for enrollment");
    }

    map<anydata> electionMap = <map<anydata>>result;
    map<anydata> electionRowData = <map<anydata>>electionMap.get("value");
    int _ = <int>electionRowData.get("id");

    // Check if already enrolled
    stream<record {}, sql:Error?> enrollmentStream = dbClient->query(
        `SELECT voter_id FROM enrollments 
         WHERE voter_id = ${voterId} AND election_id = ${electionId}`
    );

    record {}|sql:Error? enrollmentResult = enrollmentStream.next();
    check enrollmentStream.close();

    if (enrollmentResult is sql:Error) {
        return createErrorResponse("Database error: " + enrollmentResult.message());
    }

    if (enrollmentResult != ()) {
        return createErrorResponse("Already enrolled in this election");
    }

    // Create enrollment
    sql:ExecutionResult|sql:Error insertResult = dbClient->execute(`
        INSERT INTO enrollments (voter_id, election_id, enrollment_date)
        VALUES (${voterId}, ${electionId}, CURRENT_TIMESTAMP)
    `);

    if (insertResult is sql:Error) {
        return createErrorResponse("Failed to enroll: " + insertResult.message());
    }

    sql:ExecutionResult|sql:Error updateStatus = dbClient->execute(`
        UPDATE elections SET status = 'Enrolled' WHERE id = ${electionId}
    `);

    if (updateStatus is sql:Error) {
        return createErrorResponse("Enrollment successful, but failed to update election status: " + updateStatus.message());
    }

    return {
        success: true,
        message: "Successfully enrolled in the election"
    };
}

// Get candidates for an election
resource function get elections/[int electionId]/candidates() returns ApiResponse|error {

    // Check if election exists
    stream<record {}, sql:Error?> electionStream = dbClient->query(
        `SELECT id, election_name, description, start_date, enrol_ddl, 
                election_date, end_date, no_of_candidates, election_type, 
                start_time, end_time, status
         FROM elections 
         WHERE id = ${electionId}`
    );
    
    record {}|sql:Error? result = electionStream.next();
    check electionStream.close();
    
    if (result is sql:Error) {
        return createErrorResponse("Database error: " + result.message());
    }
    
    if (result == ()) {
        return createErrorResponse("Election not found");
    }
    
    map<anydata> electionMap = <map<anydata>>result;
    map<anydata> electionRowData = <map<anydata>>electionMap.get("value");
    
    // election fields
    int id = <int>electionRowData.get("id");
    string name = <string>electionRowData.get("election_name");
    string description = <string>electionRowData.get("description");
    string startDate = <string>electionRowData.get("start_date");
    string enrolDDL = <string>electionRowData.get("enrol_ddl");
    string electionDate = <string>electionRowData.get("election_date");
    string endDate = <string>electionRowData.get("end_date");
    int noOfCandidates = <int>electionRowData.get("no_of_candidates");
    string electionType = <string>electionRowData.get("election_type");
    string startTime = <string>electionRowData.get("start_time");
    string endTime = <string>electionRowData.get("end_time");
    string status = <string>electionRowData.get("status");

    // Get candidates for this election
    stream<record {}, sql:Error?> candidatesStream = dbClient->query(
        `SELECT id, name, party, bio, image, election_id
         FROM candidates
         WHERE election_id = ${electionId}`
    );
    
    record {| 
        int id;
        string name;
        string party;
        string bio;
        string image;
        int election_id;
    |}[] candidates = [];
    
    record {}|sql:Error? candidateResult = candidatesStream.next();
    while (candidateResult is record {}) {
        map<anydata> candidateMap = <map<anydata>>candidateResult;
        map<anydata> candidateRowData = <map<anydata>>candidateMap.get("value");

        candidates.push({
            id: <int>candidateRowData.get("id"),
            name: <string>candidateRowData.get("name"),
            party: <string>candidateRowData.get("party"),
            bio: <string>candidateRowData.get("bio"),
            image: <string>candidateRowData.get("image"),
            election_id: <int>candidateRowData.get("election_id")
        });

        candidateResult = candidatesStream.next();
    }
    check candidatesStream.close();
    
    if (candidateResult is sql:Error) {
        return createErrorResponse("Error retrieving candidates: " + candidateResult.message());
    }

    return {
        success: true,
        message: "Candidates retrieved successfully",
        data: {
            "election": {
                "id": id,
                "name": name,
                "description": description,
                "startDate": startDate,
                "enrolDeadline": enrolDDL,
                "electionDate": electionDate,
                "endDate": endDate,
                "noOfCandidates": noOfCandidates,
                "type": electionType,
                "startTime": startTime,
                "endTime": endTime,
                "status": status
            },
            "candidates": candidates
        }
    };
}

}

// Main function
public function main() returns error? {
    // Check database connection
    stream<record {}, sql:Error?> queryResult = dbClient->query(`SELECT 1`);
    check queryResult.close();
    io:println("Successfully connected to database");
    io:println("Election System Backend started on port " + serverPort.toString());
}
