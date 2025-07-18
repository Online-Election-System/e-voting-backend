// Define what permissions each role has
public function getRolePermissions(UserRole role) returns Permission[] {
    match role {
        ADMIN => {
            return [
                CREATE_ELECTION,
                DELETE_ELECTION,
                UPDATE_ELECTION,
                VIEW_ELECTION,
                MANAGE_USERS,
                VERIFY_USERS,
                VIEW_RESULTS
            ];
        }
        GOVERNMENT_OFFICIAL => {
            return [CREATE_ELECTION, UPDATE_ELECTION, VIEW_ELECTION, VIEW_RESULTS];
        }
        ELECTION_COMMISSION => {
            return [
                CREATE_ELECTION,
                DELETE_ELECTION,
                UPDATE_ELECTION,
                VIEW_ELECTION,
                VERIFY_USERS,
                VIEW_RESULTS
            ];
        }
        VERIFIED_CHIEF_OCCUPANT => {
            return [VOTE, VIEW_ELECTION];
        }
        VERIFIED_HOUSEHOLD_MEMBER => {
            return [VOTE, VIEW_ELECTION];
        }
        CHIEF_OCCUPANT => {
            return [VIEW_ELECTION];
        }
        HOUSEHOLD_MEMBER => {
            return [VIEW_ELECTION];
        }
        _ => {
            return [];
        }
    }
}

// Check if user has required permission
public function hasPermission(AuthenticatedUser user, Permission permission) returns boolean {
    return user.permissions.indexOf(permission) != ();
}

// Check if user has any of the required roles
public function hasRole(AuthenticatedUser user, UserRole[] allowedRoles) returns boolean {
    if allowedRoles.length() == 0 {
        return true; // No specific roles required
    }
    return allowedRoles.indexOf(user.role) != ();
}
