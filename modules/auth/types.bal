# Description for elections to be insterted.
#
# + nationalId - National Identity Card Number
# + password - Account Password
public type VoterLogin record {
    string nationalId;
    string password;
};

public type ChiefOccupantInput record {|
    string fullName;
    string nic;
    string phoneNumber;
    string dob;
    string gender;
    string civilStatus;
    string email;
    string passwordHash;
    string? idCopyPath;
|};

public type HouseholdMemberInput record {
    string fullName;
    string? nic;
    string dob;
    string gender;
    string civilStatus;
    string relationshipWithChiefOccupant;
    string? idCopyPath;
    boolean approvedByChief;

};

public type HouseholdDetailsInput record {
    string? chiefOccupantId?;
    string electoralDistrict;
    string pollingDivision;
    string pollingDistrictNumber;
    string? gramaNiladhariDivision;
    string? villageStreetEstate;
    string? houseNumber;
    int householdMemberCount;

};

public type HouseholdMembersRequest record {
    string? chiefOccupantId?;
    HouseholdMemberInput[] members;

};

public type ChiefOccupantQueryResult record {
    string chiefOccupantId;
};

public type LoginRequest record {|
    string nic;
    string password;

|};

public type LoginResponse record {|
    string userId;
    string userType;
    string fullName;
    string message;
    string token;

|};

public type ChangePasswordRequest record {|
    string userId;
    string oldPassword;
    string newPassword;
    string userType;

|};

public type VoterRegistrationRequest record {
    ChiefOccupantInput chiefOccupant
;
    HouseholdDetailsInput householdDetails;
    HouseholdMembersRequest newHouseholdMembers;
};

public type ChiefOccupantInsert record {|
    string id;
    string fullName;
    string nic;
    string phoneNumber;
    string dob;
    string gender;
    string civilStatus;
    string passwordHash;
    string email;
    string? idCopyPath;
|};

public type HouseholdMembersInsert record {|
    string id;
    string chiefOccupantId;
    string fullName;
    string nic;
    string relationshipWithChiefOccupant;
    string dob;
    string gender;
    boolean approvedByChief;
    string civilStatus;
    string? idCopyPath;
    string hasedPassword;
    boolean passwordchanged;
|};

public type PasswordResetRequest record {
    string email;
    string token;
    string newPassword;
};
