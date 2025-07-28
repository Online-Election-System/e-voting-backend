// Define what permissions each role has
public function getRolePermissions(UserRole role) returns Permission[] {
    match role {
        ADMIN => {
            return [
                CREATE_ELECTION,
                // DELETE_ELECTION,
                UPDATE_ELECTION,
                VIEW_ELECTION,
                MANAGE_USERS,
                MANAGE_CANDIDATES,
                VERIFY_USERS,
                VIEW_RESULTS,
                VIEW_AUDIT_LOGS
            ];
        }
        GOVERNMENT_OFFICIAL => {
            return [
                MANAGE_USERS,
                VERIFY_USERS
            ];
        }
        ELECTION_COMMISSION => {
            return [
                CREATE_ELECTION,
                DELETE_ELECTION,
                UPDATE_ELECTION,
                VIEW_ELECTION,
                MANAGE_CANDIDATES,
                VERIFY_USERS,
                VIEW_RESULTS,
                VIEW_AUDIT_LOGS
            ];
        }
        CHIEF_OCCUPANT => {
            return [VIEW_ELECTION];
        }
        HOUSEHOLD_MEMBER => {
            return [VIEW_ELECTION];
        }
        POLLING_STATION => {
            return [VIEW_ELECTION, VOTE];
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

// Check if user can vote (for now, without verification requirement)
public function canVote(AuthenticatedUser user) returns boolean {
    return hasPermission(user, VOTE);
}

// Check if user can manage elections
public function canManageElections(AuthenticatedUser user) returns boolean {
    return hasPermission(user, CREATE_ELECTION) || hasPermission(user, UPDATE_ELECTION);
}

// Check if user can manage candidates
public function canManageCandidates(AuthenticatedUser user) returns boolean {
    return hasPermission(user, MANAGE_CANDIDATES);
}

// Check if user can verify other users
public function canVerifyUsers(AuthenticatedUser user) returns boolean {
    return hasPermission(user, VERIFY_USERS);
}

// Get role hierarchy level (for determining what roles can manage what)
public function getRoleLevel(UserRole role) returns int {
    match role {
        ADMIN => { return 100; }
        ELECTION_COMMISSION => { return 90; }
        GOVERNMENT_OFFICIAL => { return 80; }
        CHIEF_OCCUPANT => { return 40; }
        HOUSEHOLD_MEMBER => { return 30; }
        _ => { return 0; }
    }
}

// Check if user can manage another user based on role hierarchy
public function canManageUser(AuthenticatedUser manager, UserRole targetRole) returns boolean {
    if !hasPermission(manager, MANAGE_USERS) {
        return false;
    }
    
    return getRoleLevel(manager.role) > getRoleLevel(targetRole);
}