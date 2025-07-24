// AUTO-GENERATED FILE. DO NOT MODIFY.

// This file is an auto-generated file by Ballerina persistence layer for model.
// It should not be modified by hand.

import ballerina/time;

public type ChiefOccupant record {|
    readonly string id;
    string fullName;
    string nic;
    string? phoneNumber;
    string dob;
    string gender;
    string civilStatus;
    string passwordHash;
    string email;
    string? idCopyPath;
    string role;
|};

public type ChiefOccupantOptionalized record {|
    string id?;
    string fullName?;
    string nic?;
    string? phoneNumber?;
    string dob?;
    string gender?;
    string civilStatus?;
    string passwordHash?;
    string email?;
    string? idCopyPath?;
    string role?;
|};

public type ChiefOccupantTargetType typedesc<ChiefOccupantOptionalized>;

public type ChiefOccupantInsert ChiefOccupant;

public type ChiefOccupantUpdate record {|
    string fullName?;
    string nic?;
    string? phoneNumber?;
    string dob?;
    string gender?;
    string civilStatus?;
    string passwordHash?;
    string email?;
    string? idCopyPath?;
    string role?;
|};

public type HouseholdDetails record {|
    readonly string id;
    string chiefOccupantId;
    string electoralDistrict;
    string pollingDivision;
    string pollingDistrictNumber;
    string? gramaNiladhariDivision;
    string? villageStreetEstate;
    string? houseNumber;
    int householdMemberCount;
|};

public type HouseholdDetailsOptionalized record {|
    string id?;
    string chiefOccupantId?;
    string electoralDistrict?;
    string pollingDivision?;
    string pollingDistrictNumber?;
    string? gramaNiladhariDivision?;
    string? villageStreetEstate?;
    string? houseNumber?;
    int householdMemberCount?;
|};

public type HouseholdDetailsTargetType typedesc<HouseholdDetailsOptionalized>;

public type HouseholdDetailsInsert HouseholdDetails;

public type HouseholdDetailsUpdate record {|
    string chiefOccupantId?;
    string electoralDistrict?;
    string pollingDivision?;
    string pollingDistrictNumber?;
    string? gramaNiladhariDivision?;
    string? villageStreetEstate?;
    string? houseNumber?;
    int householdMemberCount?;
|};

public type HouseholdMembers record {|
    readonly string id;
    string chiefOccupantId;
    string fullName;
    string? nic;
    string dob;
    string gender;
    string civilStatus;
    string relationshipWithChiefOccupant;
    string? idCopyPath;
    boolean approvedByChief;
    string passwordHash;
    boolean passwordchanged;
    string role;
|};

public type HouseholdMembersOptionalized record {|
    string id?;
    string chiefOccupantId?;
    string fullName?;
    string? nic?;
    string dob?;
    string gender?;
    string civilStatus?;
    string relationshipWithChiefOccupant?;
    string? idCopyPath?;
    boolean approvedByChief?;
    string passwordHash?;
    boolean passwordchanged?;
    string role?;
|};

public type HouseholdMembersTargetType typedesc<HouseholdMembersOptionalized>;

public type HouseholdMembersInsert HouseholdMembers;

public type HouseholdMembersUpdate record {|
    string chiefOccupantId?;
    string fullName?;
    string? nic?;
    string dob?;
    string gender?;
    string civilStatus?;
    string relationshipWithChiefOccupant?;
    string? idCopyPath?;
    boolean approvedByChief?;
    string passwordHash?;
    boolean passwordchanged?;
    string role?;
|};

public type Election record {|
    readonly string id;
    string electionName;
    string description;
    time:Date startDate;
    time:Date enrolDdl;
    time:Date electionDate;
    time:Date endDate;
    int noOfCandidates;
    string electionType;
    time:TimeOfDay startTime;
    time:TimeOfDay endTime;
    string status;
|};

public type ElectionOptionalized record {|
    string id?;
    string electionName?;
    string description?;
    time:Date startDate?;
    time:Date enrolDdl?;
    time:Date electionDate?;
    time:Date endDate?;
    int noOfCandidates?;
    string electionType?;
    time:TimeOfDay startTime?;
    time:TimeOfDay endTime?;
    string status?;
|};

public type ElectionTargetType typedesc<ElectionOptionalized>;

public type ElectionInsert Election;

public type ElectionUpdate record {|
    string electionName?;
    string description?;
    time:Date startDate?;
    time:Date enrolDdl?;
    time:Date electionDate?;
    time:Date endDate?;
    int noOfCandidates?;
    string electionType?;
    time:TimeOfDay startTime?;
    time:TimeOfDay endTime?;
    string status?;
|};

public type AdminUsers record {|
    readonly string id;
    string username;
    string email;
    string passwordHash;
    string role;
    time:Utc createdAt;
    boolean isActive;
|};

public type AdminUsersOptionalized record {|
    string id?;
    string username?;
    string email?;
    string passwordHash?;
    string role?;
    time:Utc createdAt?;
    boolean isActive?;
|};

public type AdminUsersTargetType typedesc<AdminUsersOptionalized>;

public type AdminUsersInsert AdminUsers;

public type AdminUsersUpdate record {|
    string username?;
    string email?;
    string passwordHash?;
    string role?;
    time:Utc createdAt?;
    boolean isActive?;
|};

public type AddMemberRequest record {|
    readonly string addRequestId;
    string chiefOccupantId;
    string nicNumber;
    string fullName;
    string dateOfBirth;
    string gender;
    string civilStatus;
    string relationshipToChief;
    string chiefOccupantApproval;
    string requestStatus;
    string? nicOrBirthCertificatePath;
|};

public type AddMemberRequestOptionalized record {|
    string addRequestId?;
    string chiefOccupantId?;
    string nicNumber?;
    string fullName?;
    string dateOfBirth?;
    string gender?;
    string civilStatus?;
    string relationshipToChief?;
    string chiefOccupantApproval?;
    string requestStatus?;
    string? nicOrBirthCertificatePath?;
|};

public type AddMemberRequestTargetType typedesc<AddMemberRequestOptionalized>;

public type AddMemberRequestInsert AddMemberRequest;

public type AddMemberRequestUpdate record {|
    string chiefOccupantId?;
    string nicNumber?;
    string fullName?;
    string dateOfBirth?;
    string gender?;
    string civilStatus?;
    string relationshipToChief?;
    string chiefOccupantApproval?;
    string requestStatus?;
    string? nicOrBirthCertificatePath?;
|};

public type UpdateMemberRequest record {|
    readonly string updateRequestId;
    string chiefOccupantId;
    string householdMemberId;
    string? newFullName;
    string? newResidentArea;
    string requestStatus;
    string? relevantCertificatePath;
|};

public type UpdateMemberRequestOptionalized record {|
    string updateRequestId?;
    string chiefOccupantId?;
    string householdMemberId?;
    string? newFullName?;
    string? newResidentArea?;
    string requestStatus?;
    string? relevantCertificatePath?;
|};

public type UpdateMemberRequestTargetType typedesc<UpdateMemberRequestOptionalized>;

public type UpdateMemberRequestInsert UpdateMemberRequest;

public type UpdateMemberRequestUpdate record {|
    string chiefOccupantId?;
    string householdMemberId?;
    string? newFullName?;
    string? newResidentArea?;
    string requestStatus?;
    string? relevantCertificatePath?;
|};

public type DeleteMemberRequest record {|
    readonly string deleteRequestId;
    string chiefOccupantId;
    string householdMemberId;
    string requestStatus;
    string? requiredDocumentPath;
|};

public type DeleteMemberRequestOptionalized record {|
    string deleteRequestId?;
    string chiefOccupantId?;
    string householdMemberId?;
    string requestStatus?;
    string? requiredDocumentPath?;
|};

public type DeleteMemberRequestTargetType typedesc<DeleteMemberRequestOptionalized>;

public type DeleteMemberRequestInsert DeleteMemberRequest;

public type DeleteMemberRequestUpdate record {|
    string chiefOccupantId?;
    string householdMemberId?;
    string requestStatus?;
    string? requiredDocumentPath?;
|};

