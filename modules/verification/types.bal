import online_election.store;
import ballerina/time;


// This file defines custom data structures (view models) for the registration service API.
// These records shape the data sent to and received from the frontend.

// Represents a single application row in the main registration table.


public type GramaNiladhariProfile record {|
    string fullName;
    string nic;
    string dateOfBirth;
    string email;
    string officePhone;
    string mobileNumber;
    string residentialAddress;
    string officialTitle;
    string employeeId;
    string appointmentDate;
    string gnDivision;
    string district;
    string province;
    string officeAddress;
    string qualifications;
    string experience;
|};

public type RegistrationApplication record {|
    string fullName;
    string nic;
    string dob;
    string? phone;
    string address;
    string? idCopyPath;
    string? photoCopyPath;
    string status;
    string submittedDate; // Corresponds to the 'Submitted' column in the UI
|};

// Represents the complete detailed view of a single application for the details page.
public type RegistrationDetails record {|
    // Personal Information
    string fullName;
    string nic;
    string dob;
    string gender;
    string civilStatus;
    string? phone;
    // Electoral Information
    string electoralDistrict;
    string pollingDivision;
    string pollingDistrictNumber;
    // Address Information
    string? villageStreetEstate;
    string? houseNumber;
    string fullAddress;
    // Document Paths
    string? idCopyPath;
    string? photoCopyPath;
    // Application Status Details
    string status;
    time:Utc? reviewedAt;
    string? comments;
|};

// Represents the JSON payload for the approve/reject POST request.
public type ReviewRequest record {|
    "approved"|"rejected" status;
    string? comments;
|};

// Represents the data structure for the dashboard status cards.
public type StatusCounts record {|
    int pending;
    int approved;
    int rejected;
    int total;
|};

// Define the rejection request payload structure
public type RejectionRequest record {
    string reason;  // required field for rejection reason
};

// Type definitions for removal requests
public type RemovalRequest record {|
    string deleteRequestId;
    string memberName;
    string memberNic;
    string requestedBy;
    string requestedByNic;
    string reason;
    string? proofDocument;
    string submittedDate;
    string status;
|};

public type RemovalRequestCounts record {|
    int pending;
    int approved;
    int rejected;
    int total;
|};


// Response types
public type AddMemberRequestResponse record {|
    string addRequestId;
    string fullName;
    string nicNumber;
    string dateOfBirth;
    string gender;
    string relationshipToChief;
    string requestStatus;
    string? reason;
|};

public type AddMemberRequestCounts record {|
    int pending;
    int approved;
    int rejected;
    int total;
|};

public type AddMemberRequestDetail record {|
    store:AddMemberRequest request;
    store:ChiefOccupant? chiefOccupant;
    store:HouseholdDetails? householdDetails;
|};