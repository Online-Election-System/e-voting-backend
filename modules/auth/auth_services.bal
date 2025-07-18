import online_election.common;
import online_election.store;

import ballerina/crypto;
import ballerina/email;
import ballerina/http;
import ballerina/jwt;
import ballerina/log;
import ballerina/time;
import ballerina/uuid;

// Enhanced login function that handles all user types
public function authenticateUser(LoginRequest loginReq, http:Request request) returns LoginResponse|http:Unauthorized|error {

    // Log login attempt
    logLoginAttempt(loginReq.nic, getClientIP(request));

    // Try to find user in different tables based on NIC
    AuthenticatedUser|error user = findUserByNIC(loginReq.nic);

    if user is error {
        logFailedLogin(loginReq.nic, "User not found", getClientIP(request));
        return http:UNAUTHORIZED;
    }

    // Check if account is locked
    if isAccountLocked(user) {
        logFailedLogin(loginReq.nic, "Account locked", getClientIP(request));
        return http:UNAUTHORIZED;
    }

    // Verify password
    boolean|error isPasswordValid = verifyUserPassword(user, loginReq.password);
    if isPasswordValid is error || !isPasswordValid {
        incrementFailedLoginAttempts(user);
        logFailedLogin(loginReq.nic, "Invalid password", getClientIP(request));
        return http:UNAUTHORIZED;
    }

    // Reset failed login attempts on successful authentication
    resetFailedLoginAttempts(user);

    // Update last login
    updateLastLogin(user);

    // Generate tokens
    string|error accessToken = generateAccessToken(user);
    if accessToken is error {
        log:printError("Failed to generate access token: " + accessToken.message());
        return http:UNAUTHORIZED;
    }

    string|error refreshToken = generateRefreshToken(user);
    if refreshToken is error {
        log:printError("Failed to generate refresh token: " + refreshToken.message());
        return http:UNAUTHORIZED;
    }

    // Create session
    string sessionId = createUserSession(user, request);

    // Log successful login
    logSuccessfulLogin(user, getClientIP(request), sessionId);

    // Determine if password change is required
    boolean requiresPasswordChange = checkPasswordChangeRequired(user);

    time:Utc expiresAt = time:utcNow();
    expiresAt = time:utcAddSeconds(expiresAt, 3600); // 1 hour

    return {
        userId: user.id,
        userType: user.userType,
        role: user.role,
        fullName: user.fullName,
        email: user.email,
        isVerified: user.isVerified,
        requiresPasswordChange: requiresPasswordChange,
        message: generateLoginMessage(user, requiresPasswordChange),
        token: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt
    };
}

// Find user by NIC across all user tables
function findUserByNIC(string nic) returns AuthenticatedUser|error {

    // Try ChiefOccupant first
    stream<store:ChiefOccupant, error?> chiefStream = dbClient->/chiefoccupants.get();
    check from store:ChiefOccupant chief in chiefStream
        where chief.nic == nic
        do {
            check chiefStream.close();
            UserRole role = determineUserRole(CHIEF_OCCUPANT, chief.isVerified);
            return {
                id: chief.id,
                fullName: chief.fullName,
                nic: chief.nic,
                email: chief.email,
                userType: CHIEF_OCCUPANT,
                role: role,
                permissions: getRolePermissions(role),
                isVerified: chief.isVerified,
                verifiedAt: chief.verifiedAt,
                verifiedBy: chief.verifiedBy,
                isActive: chief.isActive,
                lastLogin: chief.lastLogin
            };
        };
    check chiefStream.close();

    // Try HouseholdMembers
    stream<store:HouseholdMembers, error?> memberStream = dbClient->/householdmembers.get();
    check from store:HouseholdMembers member in memberStream
        where member.nic == nic
        do {
            check memberStream.close();
            UserRole role = determineUserRole(HOUSEHOLD_MEMBER, member.isVerified);
            return {
                id: member.id,
                fullName: member.fullName,
                nic: member.nic ?: "",
                email: "", // You might need to add email field
                userType: HOUSEHOLD_MEMBER,
                role: role,
                permissions: getRolePermissions(role),
                isVerified: member.isVerified,
                verifiedAt: member.verifiedAt,
                verifiedBy: member.verifiedBy,
                isActive: member.isActive,
                lastLogin: member.lastLogin
            };
        };
    check memberStream.close();

    // Try AdminUsers
    stream<store:AdminUsers, error?> adminStream = dbClient->/adminusers.get();
    check from store:AdminUsers admin in adminStream
        where admin.username == nic // Assuming admins use username instead of NIC
        do {
            check adminStream.close();
            UserRole role = admin.role == "super_admin" ? SUPER_ADMIN : ADMIN;
            return {
                id: admin.id,
                fullName: admin.username,
                nic: "",
                email: admin.email,
                userType: ADMIN,
                role: role,
                permissions: getRolePermissions(role),
                isVerified: true,
                verifiedAt: admin.createdAt,
                verifiedBy: (),
                isActive: admin.isActive,
                lastLogin: admin.lastLogin
            };
        };
    check adminStream.close();

    // Try GovernmentOfficials (if implemented)
    // Similar pattern for other user types...

    return error("User not found");
}

// Verify password for different user types
function verifyUserPassword(AuthenticatedUser user, string password) returns boolean|error {
    match user.userType {
        CHIEF_OCCUPANT => {
            store:ChiefOccupant chief = check dbClient->/chiefoccupants/[user.id].get();
            return crypto:verifyBcrypt(password, chief.passwordHash);
        }
        HOUSEHOLD_MEMBER => {
            store:HouseholdMembers member = check dbClient->/householdmembers/[user.id].get();
            return crypto:verifyBcrypt(password, member.passwordHash);
        }
        ADMIN => {
            store:AdminUsers admin = check dbClient->/adminusers/[user.id].get();
            return crypto:verifyBcrypt(password, admin.passwordHash);
        }
        _ => {
            return error("Unsupported user type for password verification");
        }
    }
}

// Check if account is locked due to failed login attempts
function isAccountLocked(AuthenticatedUser user) returns boolean {
    match user.userType {
        CHIEF_OCCUPANT => {
            store:ChiefOccupant|error chief = dbClient->/chiefoccupants/[user.id].get();
            if chief is store:ChiefOccupant {
                if chief.accountLockedUntil is time:Utc {
                    return time:utcNow() < chief.accountLockedUntil;
                }
            }
        }
        HOUSEHOLD_MEMBER => {
            store:HouseholdMembers|error member = dbClient->/householdmembers/[user.id].get();
            if member is store:HouseholdMembers {
                if member.accountLockedUntil is time:Utc {
                    return time:utcNow() < member.accountLockedUntil;
                }
            }
        }
        ADMIN => {
            store:AdminUsers|error admin = dbClient->/adminusers/[user.id].get();
            if admin is store:AdminUsers {
                if admin.accountLockedUntil is time:Utc {
                    return time:utcNow() < admin.accountLockedUntil;
                }
            }
        }
    }
    return false;
}

// Increment failed login attempts and potentially lock account
function incrementFailedLoginAttempts(AuthenticatedUser user) {
    match user.userType {
        CHIEF_OCCUPANT => {
            store:ChiefOccupant|error chief = dbClient->/chiefoccupants/[user.id].get();
            if chief is store:ChiefOccupant {
                int newAttempts = chief.failedLoginAttempts + 1;
                time:Utc? lockUntil = newAttempts >= 5 ? time:utcAddSeconds(time:utcNow(), 1800) : (); // 30 min lock

                store:ChiefOccupantUpdate update = {
                    failedLoginAttempts: newAttempts,
                    accountLockedUntil: lockUntil,
                    updatedAt: time:utcNow()
                };
                _ = dbClient->/chiefoccupants/[user.id].put(update);
            }
        }
        HOUSEHOLD_MEMBER => {
            store:HouseholdMembers|error member = dbClient->/householdmembers/[user.id].get();
            if member is store:HouseholdMembers {
                int newAttempts = member.failedLoginAttempts + 1;
                time:Utc? lockUntil = newAttempts >= 5 ? time:utcAddSeconds(time:utcNow(), 1800) : ();

                store:HouseholdMembersUpdate update = {
                    failedLoginAttempts: newAttempts,
                    accountLockedUntil: lockUntil,
                    updatedAt: time:utcNow()
                };
                _ = dbClient->/householdmembers/[user.id].put(update);
            }
        }
        ADMIN => {
            store:AdminUsers|error admin = dbClient->/adminusers/[user.id].get();
            if admin is store:AdminUsers {
                int newAttempts = admin.failedLoginAttempts + 1;
                time:Utc? lockUntil = newAttempts >= 3 ? time:utcAddSeconds(time:utcNow(), 3600) : (); // 1 hour lock for admins

                store:AdminUsersUpdate update = {
                    failedLoginAttempts: newAttempts,
                    accountLockedUntil: lockUntil,
                    updatedAt: time:utcNow()
                };
                _ = dbClient->/adminusers/[user.id].put(update);
            }
        }
    }
}

// Reset failed login attempts on successful login
function resetFailedLoginAttempts(AuthenticatedUser user) {
    match user.userType {
        CHIEF_OCCUPANT => {
            store:ChiefOccupantUpdate update = {
                failedLoginAttempts: 0,
                accountLockedUntil: (),
                lastLogin: time:utcNow(),
                updatedAt: time:utcNow()
            };
            _ = dbClient->/chiefoccupants/[user.id].put(update);
        }
        HOUSEHOLD_MEMBER => {
            store:HouseholdMembersUpdate update = {
                failedLoginAttempts: 0,
                accountLockedUntil: (),
                lastLogin: time:utcNow(),
                updatedAt: time:utcNow()
            };
            _ = dbClient->/householdmembers/[user.id].put(update);
        }
        ADMIN => {
            store:AdminUsersUpdate update = {
                failedLoginAttempts: 0,
                accountLockedUntil: (),
                lastLogin: time:utcNow(),
                updatedAt: time:utcNow()
            };
            _ = dbClient->/adminusers/[user.id].put(update);
        }
    }
}

// Update last login timestamp
function updateLastLogin(AuthenticatedUser user) {
    // This is handled in resetFailedLoginAttempts for efficiency
}

// Generate JWT access token
public function generateAccessToken(AuthenticatedUser user) returns string|error {
    int seconds = time:utcNow()[0];
    int expiryTime = seconds + 3600; // 1 hour

    jwt:IssuerConfig issuerConfig = {
        username: "election_system",
        issuer: "wso2",
        audience: "vEwzbcasJVQm1jVYHUHCjhxZ4tYa",
        expTime: 3600,
        customClaims: {
            sub: user.id,
            userType: user.userType.toString(),
            role: user.role.toString(),
            isVerified: user.isVerified,
            isActive: user.isActive,
            iat: seconds,
            exp: expiryTime
        },
        signatureConfig: {
            config: {
                keyFile: "./resources/private.key",
                keyPassword: ""
            }
        }
    };
    return check jwt:issue(issuerConfig);
}

// Generate refresh token (longer lived)
public function generateRefreshToken(AuthenticatedUser user) returns string|error {
    int seconds = time:utcNow()[0];
    int expiryTime = seconds + 604800; // 7 days

    jwt:IssuerConfig issuerConfig = {
        username: "election_system",
        issuer: "wso2",
        audience: "vEwzbcasJVQm1jVYHUHCjhxZ4tYa",
        expTime: 604800,
        customClaims: {
            sub: user.id,
            userType: user.userType.toString(),
            'type: "refresh",
            iat: seconds,
            exp: expiryTime
        },
        signatureConfig: {
            config: {
                keyFile: "./resources/private.key",
                keyPassword: ""
            }
        }
    };
    return check jwt:issue(issuerConfig);
}

// Create user session
function createUserSession(AuthenticatedUser user, http:Request request) returns string {
    string sessionId = uuid:createType4AsString();

    // Store session in database
    store:UserSessionsInsert sessionInsert = {
        id: sessionId,
        userId: user.id,
        userType: user.userType.toString(),
        sessionToken: sessionId,
        deviceInfo: request.getHeader("User-Agent") ?: "unknown",
        ipAddress: getClientIP(request),
        userAgent: request.getHeader("User-Agent") ?: "unknown",
        createdAt: time:utcNow(),
        lastActivity: time:utcNow(),
        expiresAt: time:utcAddSeconds(time:utcNow(), 3600),
        isActive: true
    };

    _ = dbClient->/usersessions.post([sessionInsert]);

    return sessionId;
}

// Check if password change is required
function checkPasswordChangeRequired(AuthenticatedUser user) returns boolean {
    match user.userType {
        HOUSEHOLD_MEMBER => {
            store:HouseholdMembers|error member = dbClient->/householdmembers/[user.id].get();
            if member is store:HouseholdMembers {
                return !member.passwordchanged;
            }
        }
        _ => {
            // Check if password is older than required change period
            // You can implement password age checking here
            return false;
        }
    }
    return false;
}

// Generate appropriate login message
function generateLoginMessage(AuthenticatedUser user, boolean requiresPasswordChange) returns string {
    if requiresPasswordChange {
        return "First-time login. Please change your password.";
    }
    if !user.isVerified {
        return "Login successful. Account verification pending.";
    }
    return "Login successful";
}

// Enhanced password change function
public function changeUserPassword(ChangePasswordRequest req, string requesterId) returns http:Ok|http:Unauthorized|json|error {

    // Validate new password
    string? passwordError = validatePasswordPolicy(req.newPassword);
    if passwordError is string {
        return {
            statusCode: 400,
            body: {
                "status": "error",
                "code": "INVALID_PASSWORD",
                "message": passwordError,
                "requirements": getPasswordRequirements()
            }
        };
    }

    // Verify requester has permission to change this password
    if req.userId != requesterId {
        return http:UNAUTHORIZED;
    }

    // Hash the new password
    string|error newHashed = hashPassword(req.newPassword);
    if newHashed is error {
        return error("Failed to hash new password");
    }

    match req.userType {
        CHIEF_OCCUPANT => {
            store:ChiefOccupant chief = check dbClient->/chiefoccupants/[req.userId].get();

            // Verify old password
            boolean|error isVerified = crypto:verifyBcrypt(req.oldPassword, chief.passwordHash);
            if isVerified is error || !isVerified {
                return http:UNAUTHORIZED;
            }

            store:ChiefOccupantUpdate chiefUpdate = {
                passwordHash: newHashed,
                passwordChangedAt: time:utcNow(),
                updatedAt: time:utcNow()
            };
            _ = check dbClient->/chiefoccupants/[req.userId].put(chiefUpdate);
        }
        HOUSEHOLD_MEMBER => {
            store:HouseholdMembers member = check dbClient->/householdmembers/[req.userId].get();

            boolean|error isVerified = crypto:verifyBcrypt(req.oldPassword, member.passwordHash);
            if isVerified is error || !isVerified {
                return http:UNAUTHORIZED;
            }

            store:HouseholdMembersUpdate memberUpdate = {
                passwordHash: newHashed,
                passwordchanged: true,
                passwordChangedAt: time:utcNow(),
                updatedAt: time:utcNow()
            };
            _ = check dbClient->/householdmembers/[req.userId].put(memberUpdate);
        }
        ADMIN => {
            store:AdminUsers admin = check dbClient->/adminusers/[req.userId].get();

            boolean|error isVerified = crypto:verifyBcrypt(req.oldPassword, admin.passwordHash);
            if isVerified is error || !isVerified {
                return http:UNAUTHORIZED;
            }

            store:AdminUsersUpdate adminUpdate = {
                passwordHash: newHashed,
                passwordChangedAt: time:utcNow(),
                updatedAt: time:utcNow()
            };
            _ = check dbClient->/adminusers/[req.userId].put(adminUpdate);
        }
        _ => {
            return http:UNAUTHORIZED;
        }
    }

    // Log password change
    logPasswordChange(req.userId, req.userType.toString());

    return http:OK;
}

// Utility functions for logging
function logLoginAttempt(string nic, string ipAddress) {
    log:printInfo(string `Login attempt for NIC: ${nic} from IP: ${ipAddress}`);
}

function logFailedLogin(string nic, string reason, string ipAddress) {
    log:printWarn(string `Failed login for NIC: ${nic}, Reason: ${reason}, IP: ${ipAddress}`);
}

function logSuccessfulLogin(AuthenticatedUser user, string ipAddress, string sessionId) {
    log:printInfo(string `Successful login for user: ${user.id} (${user.role}) from IP: ${ipAddress}, Session: ${sessionId}`);
}

function logPasswordChange(string userId, string userType) {
    log:printInfo(string `Password changed for user: ${userId} (${userType})`);
}

function getPasswordRequirements() returns record {|
    int minLength;
    boolean requiresUppercase;
    boolean requiresLowercase;
    boolean requiresNumber;
    boolean requiresSpecialChar;
    string specialCharsAllowed;
|} {
    return {
        minLength: 8,
        requiresUppercase: true,
        requiresLowercase: true,
        requiresNumber: true,
        requiresSpecialChar: true,
        specialCharsAllowed: "@$!%*?&"
    };
}
