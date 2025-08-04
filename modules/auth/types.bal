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
    VIEW_RESULTS = "view_results",
    VIEW_AUDIT_LOGS = "view_audit_logs"
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
    string? photoCopyPath;
|};

public type HouseholdMemberInput record {
    string fullName;
    string? nic;
    string dob;
    string gender;
    string civilStatus;
    string relationshipWithChiefOccupant;
    string? idCopyPath;
    string? photoCopyPath;
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
    string? photoCopyPath;
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
    string? photoCopyPath;
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
    string nic;
    string passwordHash;
|};

public type PollingStationInput record {|
    string nic;
    string passwordHash;
|};

public type GovernmentOfficialRegistrationRequest record {|
    GovernmentOfficialInput official;
|};

public type ElectionCommissionRegistrationRequest record {|
    ElectionCommissionInput commission;
|};

public type PollingStationRegistrationRequest record {|
    PollingStationInput station;
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

public type VoterLogin record {
    string nationalId;
    string password;
};

public type RequestMetadata record {
    string? ipAddress;
    string? userAgent;
    string? sessionId;
};