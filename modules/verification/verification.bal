import ballerina/persist;
import ballerina/http;
import ballerina/time;
import ballerina/log;
import ballerina/lang.'string;
import ballerina/sql;
import codeCrew/online_election.store;


// Initialize the persist client
final store:Client dbClient = check new ();

// ----- Business Logic Functions -----

public function getRegistrationApplications(string? nameOrNic, string? statusFilter) returns RegistrationApplication[]|error {
    // 1. Fetch all chiefs, members, and reviews from the database
    stream<store:ChiefOccupant, persist:Error?> chiefStream = dbClient->/chiefoccupants;
    store:ChiefOccupant[] chiefs = check from store:ChiefOccupant co in chiefStream select co;

    stream<store:HouseholdMembers, persist:Error?> memberStream = dbClient->/householdmembers;
    store:HouseholdMembers[] members = check from store:HouseholdMembers hm in memberStream select hm;

    // 2. Fetch all HouseholdDetails and reviews into maps for efficient lookup
    stream<store:HouseholdDetails, persist:Error?> hhDetailsStream = dbClient->/householddetails;
    map<store:HouseholdDetails> hhDetailsMap = {};
    check from store:HouseholdDetails detail in hhDetailsStream
        do {
            hhDetailsMap[detail.chiefOccupantId] = detail;
        };
    
    stream<store:RegistrationReview, persist:Error?> reviewStream = dbClient->/registrationreviews;
    map<store:RegistrationReview> reviewMap = {};
    check from store:RegistrationReview review in reviewStream
        do {
            reviewMap[review.memberNic] = review;
        };

    // 3. Combine chiefs and members into a unified application list
   RegistrationApplication[] applications = [];
    
    // Process Chief Occupants
    foreach var chief in chiefs {
        string currentStatus = reviewMap.hasKey(chief.nic) ? reviewMap.get(chief.nic).status : "pending";
        string submitted = reviewMap.hasKey(chief.nic) ? (reviewMap.get(chief.nic).reviewedAt ?: time:utcNow()).toString() : "N/A";
        
        string address = "-";
        if hhDetailsMap.hasKey(chief.id) {
            store:HouseholdDetails hh = hhDetailsMap.get(chief.id);
            address = (hh.houseNumber ?: "") + ", " + (hh.villageStreetEstate ?: "");
        }

        applications.push({
            fullName: chief.fullName,
            nic: chief.nic,
            dob: chief.dob,
            phone: chief.phoneNumber,
            address: address,
            idCopyPath: chief.idCopyPath,
            imagePath: chief.imagePath,
            status: currentStatus,
            submittedDate: submitted 
        });
    }

    // Process Household Members
    foreach var member in members {
        if member.nic is string {
            string currentStatus = reviewMap.hasKey(<string>member.nic) ? reviewMap.get(<string>member.nic).status : "pending";
            string submitted = reviewMap.hasKey(<string>member.nic) ? (reviewMap.get(<string>member.nic).reviewedAt ?: time:utcNow()).toString() : "N/A";

            string address = "-";
            if hhDetailsMap.hasKey(member.chiefOccupantId) {
                store:HouseholdDetails hh = hhDetailsMap.get(member.chiefOccupantId);
                address = (hh.houseNumber ?: "") + ", " + (hh.villageStreetEstate ?: "");
            }

            applications.push({
                fullName: member.fullName,
                nic: <string>member.nic,
                dob: member.dob,
                phone: (), // No phone for members
                address: address,
                idCopyPath: member.idCopyPath,
                imagePath: member.imagePath,
                status: currentStatus,
                submittedDate: submitted
            });
        }
    }

    // 4. Filter results based on query parameters if they exist
    if nameOrNic is string {
        string searchTerm = string:toLowerAscii(nameOrNic);
        applications = from var app in applications
            where string:toLowerAscii(app.fullName).includes(searchTerm) || app.nic.includes(searchTerm)
            select app;
    }

    if statusFilter is string && statusFilter != "All Status" {
        string statusTerm = string:toLowerAscii(statusFilter);
        applications = from var app in applications
            where string:toLowerAscii(app.status) == statusTerm
            select app;
    }

    return applications;
}

public function getApplicationCounts() returns StatusCounts|error {
    RegistrationApplication[] allApps = check getRegistrationApplications((), ());
    
    int pending = 0;
    int approved = 0;
    int rejected = 0;

    foreach var app in allApps {
        match app.status {
            "pending" => { pending += 1; }
            "approved" => { approved += 1; }
            "rejected" => { rejected += 1; }
        }
    }

    return {
        pending: pending,
        approved: approved,
        rejected: rejected,
        total: allApps.length()
    };
}



public function getRegistrationDetails(string nic) returns RegistrationDetails|http:NotFound|error {
    var person = findPersonByNic(nic);
    if person is error {
        return http:NOT_FOUND;
    }

    string chiefOccupantId;
    string fullName; string dob; string gender; string civilStatus;
    string? phone; string? idCopyPath; string? imagePath;

    if person is store:ChiefOccupant {
        chiefOccupantId = person.id;
        fullName = person.fullName;
        dob = person.dob;
        gender = person.gender;
        civilStatus = person.civilStatus;
        phone = person.phoneNumber;
        idCopyPath = person.idCopyPath;
        imagePath = person.imagePath;
    } else if person is store:HouseholdMember {
        chiefOccupantId = person.chiefOccupantId;
        fullName = person.fullName;
        dob = person.dob;
        gender = person.gender;
        civilStatus = person.civilStatus;
        idCopyPath = person.idCopyPath;
        imagePath = person.imagePath;
        phone = ();
    } else {
        return error("Invalid person type for NIC: " + nic);
    }
    
    // Fetch household details
    sql:ParameterizedQuery hhWhereClause = `WHERE chief_occupant_id = '${chiefOccupantId}'`;
    stream<store:HouseholdDetails, persist:Error?> hhStream = dbClient->/householddetails(whereClause = hhWhereClause);

    store:HouseholdDetails|error? hhDetailsResult = from hhStream select hhStream;

    if hhDetailsResult is error {
        log:printError("Error fetching household details: " + hhDetailsResult.message());
        return hhDetailsResult;
    } else if hhDetailsResult is () {
        return error("Household details not found for chief occupant: " + chiefOccupantId);
    }

    store:HouseholdDetails hhDetails = <store:HouseholdDetails>hhDetailsResult;
    _ = hhStream.close();

    // Fetch registration review
    sql:ParameterizedQuery reviewWhereClause = `WHERE member_nic = '${nic}'`;
    stream<store:RegistrationReview, persist:Error?> reviewStream = dbClient->/registrationreviews(whereClause = reviewWhereClause);
    
    store:RegistrationReview? review = from reviewStream select reviewStream limit 1;
    _ = reviewStream.close();

    // Construct response
    return {
        fullName: fullName, 
        nic: nic, 
        dob: dob, 
        gender: gender, 
        civilStatus: civilStatus, 
        phone: phone,
        electoralDistrict: hhDetails.electoralDistrict, 
        pollingDivision: hhDetails.pollingDivision, 
        pollingDistrictNumber: hhDetails.pollingDistrictNumber,
        villageStreetEstate: hhDetails.villageStreetEstate, 
        houseNumber: hhDetails.houseNumber, 
        fullAddress: (hhDetails.houseNumber ?: "") + ", " + (hhDetails.villageStreetEstate ?: ""),
        idCopyPath: idCopyPath, 
        imagePath: imagePath, 
        status: review is () ? "pending" : review.status,
        reviewedAt: review?.reviewedAt, 
        comments: review?.comments
    };
}


public function reviewApplication(string nic, ReviewRequest reviewData) returns http:Ok|http:Forbidden|error {
    var person = findPersonByNic(nic);
    if person is error { 
        return error("Cannot review: Person not found for NIC: " + nic); 
    }

    string chiefId = (person is store:ChiefOccupant) ? person.id : person.chiefOccupantId;

    // Correctly query for the household details
    sql:ParameterizedQuery hhWhereClause = `chief_occupant_id = ${chiefId}`;
    stream<store:HouseholdDetails, persist:Error?> hhStream = dbClient->/householddetails(whereClause = hhWhereClause);

    var hhDetailsResult = hhStream.next();
    store:HouseholdDetails hhDetails;

    if hhDetailsResult is () {
        return error("Cannot review: Household details not found for NIC: " + nic);
    } else if hhDetailsResult is error {
        return hhDetailsResult;
    } else {
        // Safely access the value after the type check
        hhDetails = hhDetailsResult.value;
    }
    
    // Create the review record for insertion
    store:RegistrationReviewInsert reviewInsert = {
        memberNic: nic,
        reviewedBy: "grama_niladhari_user_id", // Placeholder
        status: reviewData.status,
        comments: reviewData.comments,
        reviewedAt: time:utcNow()
    ,id: 0};
    // The .post method expects an array of records
    _ = check dbClient->/registrationreviews.post([reviewInsert]);

    // If approved, create a new record in the Voter table
    if reviewData.status == "approved" {
        // Correctly convert time:Utc to time:Date
        time:Utc now = time:utcNow();
        time:Civil civilTime = time:utcToCivil(now);
        time:Date registrationDate = {year: civilTime.year, month: civilTime.month, day: civilTime.day};
        
        store:VoterInsert voterInsert = {
            nationalId: nic,
            name: person.fullName,
            password: person.passwordHash,
            district: hhDetails.electoralDistrict,
            pollingStation: hhDetails.pollingDivision,
            registrationDate: registrationDate,
            status: "active"
        };
        _ = check dbClient->/voters.post([voterInsert]);
        log:printInfo("Successfully created voter for NIC: " + nic);
    }
    
    return http:OK;
}

function findPersonByNic(string nic) returns store:ChiefOccupant|store:HouseholdMembers|error {
    // Construct and execute the query for ChiefOccupant
    sql:ParameterizedQuery chiefWhereClause = `nic = ${nic}`;
    stream<store:ChiefOccupant, persist:Error?> chiefStream = dbClient->/chiefoccupants(whereClause = chiefWhereClause);
    
    var chiefResult = chiefStream.next();
    if chiefResult is record {| store:ChiefOccupant value; |} {
        return chiefResult.value;
    } else if chiefResult is error {
        // Log the error or handle it as needed before proceeding
        log:printError("Error when querying ChiefOccupant by NIC", chiefResult);
    }

    // If not found, construct and execute the query for HouseholdMembers
    sql:ParameterizedQuery memberWhereClause = `nic = ${nic}`;
    stream<store:HouseholdMembers, persist:Error?> memberStream = dbClient->/householdmembers(whereClause = memberWhereClause);
    
    var memberResult = memberStream.next();
    if memberResult is record {| store:HouseholdMembers value; |} {
        return memberResult.value;
    } else if memberResult is error {
        // Log the error or handle it as needed
        log:printError("Error when querying HouseholdMembers by NIC", memberResult);
    }

    // If not found in either table after checking both
    return error("Person with NIC " + nic + " not found in either table.");
}