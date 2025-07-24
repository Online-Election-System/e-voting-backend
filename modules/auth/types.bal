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
    ChiefOccupantInput chiefOccupant;
    HouseholdDetailsInput householdDetails;
    HouseholdMembersRequest newHouseholdMembers;
};

public type ChiefOccupantInsert record {| // Added role, isVerified, verifiedAt, verifiedBy fields
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
    string role = "chief_occupant";
|};

public type HouseholdMembersInsert record {| // Added role, isVerified, verifiedAt, verifiedBy fields
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
    string passwordHash;
    boolean passwordchanged;
    string role = "household_member";
|};

# -- Government official & election commission registration types --
#
# + fullName - Full Name
# + nic - National Identity Card Number
# + email - Email
# + passwordHash - Account Password
public type GovernmentOfficialInput record {|
    string fullName;
    string nic;
    string email;
    string passwordHash;
|};

public type ElectionCommissionInput record {|
    string fullName;
    string nic;
    string email;
    string passwordHash;
|};

public type GovernmentOfficialRegistrationRequest record {|
    GovernmentOfficialInput official;
|};

public type ElectionCommissionRegistrationRequest record {|
    ElectionCommissionInput commission;
|};

public type PasswordResetRequest record {
    string email;
    string token;
    string newPassword;
};

// Additional types for logout functionality

public type LogoutResponse record {|
    string status;
    string message;
|};

public type LogoutRequest record {|
    // Token is extracted from Authorization header, no body needed
    // But you can add additional fields if needed for audit logging
    string? deviceInfo?;
    string? reason?;
|};

// Enhanced LoginResponse to include token expiry info
public type EnhancedLoginResponse record {|
    string userId;
    string userType;
    string fullName;
    string message;
    string token;
    int expiresAt?; // Unix timestamp
    int expiresIn?; // Seconds until expiry
|};

