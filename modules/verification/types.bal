import online_election.store;

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
    string status;
|};

// Represents the complete detailed view of a single application for the details page.
public type RegistrationDetail record {|
    string fullName;
    string nic;
    string dob;
    string? phone;
    string gender;
    string civilStatus;
    string electoralDistrict;
    string pollingDivision;
    string pollingDistrictNumber;
    string? gramaNiladhariDivision;
    string? village;
    string? houseNumber;
    string address;
    string status;
    string? idCopyPath;
    string? photoCopyPath;
    string role;
|};

// Represents the JSON payload for the approve/reject POST request.


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

// Response types for frontend
public type UpdateMemberRequestResponse record {|
    string updateRequestId;
    string chiefOccupantId;
    string householdMemberId;
    string nic;
    string? newFullName;
    string? newCivilStatus;
    string relevantCertificatePath;
    string requestStatus;
    string? reason;
|};

public type UpdateMemberRequestCounts record {|
    int pending;
    int approved;
    int rejected;
    int total;
|};

public type UpdateMemberRequestDetailInfo record {|
    string updateRequestId;
    string chiefOccupantId;
    string householdMemberId;
    string nic;
    string currentFullName;
    string currentCivilStatus;
    string? newFullName;
    string? newCivilStatus;
    string relevantCertificatePath;
    string requestStatus;
    string? reason;
|};

public type UpdateMemberRequestDetail record {|
    UpdateMemberRequestDetailInfo updateRequest;
    store:HouseholdDetails? householdDetails;
|};

// Response types
public type HouseholdResponse record {|
    string id;
    string? houseNumber;
    string? villageStreetEstate;
    string chiefOccupantName;
    string chiefOccupantNic;
    string? chiefOccupantPhone;
    int totalMembers; // household_member_count + 1 (including chief occupant)
    string electoralDistrict;
    string pollingDivision;
    string? pollingDistrictNumber;
    string? gramaNiladhariDivision;
    string lastUpdated;
    string status;
|};

public type HouseholdDetailResponse record {|
    HouseholdDetailInfo household;
    ChiefOccupantInfo chiefOccupant;
|};

public type HouseholdDetailInfo record {|
    string id;
    string chiefOccupantId;
    string electoralDistrict;
    string pollingDivision;
    string? pollingDistrictNumber;
    string? gramaNiladhariDivision;
    string? villageStreetEstate;
    string? houseNumber;
    int householdMemberCount;
    int totalMembers;
|};

public type ChiefOccupantInfo record {|
    string id;
    string fullName;
    string nic;
    string? phoneNumber;
    string dob;
    string gender;
    string civilStatus;
    string email;
    string role;
|};

public type HouseholdStatistics record {|
    int totalHouseholds;
    int totalMembers;
    int activeHouseholds;
    int inactiveHouseholds;
    map<int> memberDistribution;
    map<int> districtDistribution;
|};

public type HouseholdCounts record {|
    int active;
    int inactive;
    int total;
|};