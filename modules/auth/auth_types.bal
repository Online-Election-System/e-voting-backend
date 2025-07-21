// Define all possible roles in your system
public enum UserRole {
    ADMIN = "admin",
    CHIEF_OCCUPANT = "chief_occupant",
    // VERIFIED_CHIEF_OCCUPANT = "verified_chief_occupant",
    HOUSEHOLD_MEMBER = "household_member",
    // VERIFIED_HOUSEHOLD_MEMBER = "verified_household_member",
    GOVERNMENT_OFFICIAL = "government_official",
    ELECTION_COMMISSION = "election_commission"
}

// Define permissions for different operations
public enum Permission {
    CREATE_ELECTION = "create_election",
    DELETE_ELECTION = "delete_election",
    UPDATE_ELECTION = "update_election",
    VIEW_ELECTION = "view_election",
    MANAGE_USERS = "manage_users",
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

// Error types
public type AuthenticationError distinct error;

public type AuthorizationError distinct error;