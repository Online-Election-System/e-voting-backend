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
type HouseholdMemberInput record {
    string fullName;
    string? nic;
    string dob;
    string gender;
    string civilStatus;
    string relationshipWithChiefOccupant;
    string? idCopyPath;
};

type HouseholdDetailsInput record {
    string chiefOccupantId;
    string electoralDistrict;
    string pollingDivision;
    string pollingDistrictNumber;
    string? gramaNiladhariDivision;
    string? villageStreetEstate;
    string? houseNumber;
    int householdMemberCount;
};

type HouseholdMembersRequest record {
    string chiefOccupantId;
    HouseholdMemberInput[] members;
};
public type ChiefOccupantQueryResult record {
    string chiefOccupantId;
};

type LoginRequest record {|
    string nic;
    string password;
|};

type LoginResponse record {|
    string userId;
    string userType; // "chief" or "householdMember"
    string fullName;
    string message;
|};

type ChangePasswordRequest record {|
    string userId;
    string oldPassword;
    string newPassword;
    string userType;
|};
