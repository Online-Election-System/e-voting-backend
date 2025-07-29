// Define all possible roles in your system
public enum UserRole {
    ADMIN = "admin",
    CHIEF_OCCUPANT = "chief_occupant",
    VERIFIED_CHIEF_OCCUPANT = "verified_chief_occupant",
    HOUSEHOLD_MEMBER = "household_member",
    VERIFIED_HOUSEHOLD_MEMBER = "verified_household_member",
    GOVERNMENT_OFFICIAL = "government_official",
    ELECTION_COMMISSION = "election_commission",
    POLLING_STATION = "polling_station"
}

// Define permissions for different operations
public enum Permission {
    CREATE_ELECTION = "create_election",
    DELETE_ELECTION = "delete_election",
    UPDATE_ELECTION = "update_election",
    VIEW_ELECTION = "view_election",
    MANAGE_USERS = "manage_users",
    MANAGE_CANDIDATES = "manage_candidates",
    VOTE = "vote",
    VERIFY_USERS = "verify_users",
    VIEW_RESULTS = "view_results"
}

// Authorization options for middleware
public type AuthOptions record {|
    boolean requireAuth = true;
    UserRole[] allowedRoles = [];
    Permission[] requiredPermissions = [];
|};

// Enhanced user type with roles
public type AuthenticatedUser record {|
    string id;
    string fullName;
    string userType;
    UserRole role;
    Permission[] permissions;
|};

// Blacklist record with full token metadata
public type BlacklistedTokenRecord record {|
    string tokenId;
    int expiryTime;
    string userId;
    string userType;
    int blacklistedAt;
|};

// Error types
public type AuthenticationError distinct error;

public type AuthorizationError distinct error;

// Request/Response types
public type LoginRequest record {|
    string nic;
    string password;
|};

public type LoginResponse record {|
    string userId;
    string userType;
    string fullName;
    string message;
    int expiresAt?; // Unix timestamp
    int expiresIn?; // Seconds until expiry
|};

public type ChangePasswordRequest record {|
    string userId;
    string oldPassword;
    string newPassword;
    string userType;
|};

// Registration types
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

public type VoterRegistrationRequest record {
    ChiefOccupantInput chiefOccupant;
    HouseholdDetailsInput householdDetails;
    HouseholdMembersRequest newHouseholdMembers;
};

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

// Additional types
public type PasswordResetRequest record {
    string email;
    string token;
    string newPassword;
};

public type LogoutResponse record {|
    string status;
    string message;
|};

public type VoterLogin record {
    string nationalId;
    string password;
};
