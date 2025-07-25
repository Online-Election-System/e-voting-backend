import online_election.common;
import online_election.store;
import ballerina/http;
import ballerina/jwt;
import ballerina/file;
import ballerina/time;
import ballerina/log;

// Extract and validate JWT token from request
public function extractTokenFromRequest(http:Request request) returns string|AuthenticationError {
    // Try to get token from cookie first
    http:Cookie[] cookies = request.getCookies();
    
    foreach http:Cookie cookie in cookies {
        if cookie.name == "AUTH_TOKEN" {
            return cookie.value;
        }
    }
    
    // Fallback to Authorization header for backward compatibility (optional)
    string|http:HeaderNotFoundError authHeader = request.getHeader("Authorization");
    if authHeader is string && authHeader.startsWith("Bearer ") {
        return authHeader.substring(7);
    }
    
    return error AuthenticationError("Authentication token not found in cookies or headers");
}

// Get user from database and determine role/permissions
function getUserFromDatabase(string userId, string userType) returns AuthenticatedUser|error {
    log:printInfo("Getting user from database - userId: " + userId + ", userType: " + userType);
    
    if userType == "chief_occupant" {
        store:ChiefOccupant|error chief = dbClient->/chiefoccupants/[userId].get();
        if chief is error {
            log:printError("Chief occupant not found: " + chief.message());
            return error("Chief occupant not found");
        }

        UserRole role = CHIEF_OCCUPANT;
        
        return {
            id: chief.id,
            fullName: chief.fullName,
            userType: "chief_occupant",
            role: role,
            permissions: getRolePermissions(role)
        };
        
    } else if userType == "household_member" {
        store:HouseholdMembers|error member = dbClient->/householdmembers/[userId].get();
        if member is error {
            log:printError("Household member not found: " + member.message());
            return error("Household member not found");
        }

        UserRole role = HOUSEHOLD_MEMBER;
        
        return {
            id: member.id,
            fullName: member.fullName,
            userType: "household_member",
            role: role,
            permissions: getRolePermissions(role)
        };
        
    } else if userType == "government_official" {
        store:AdminUsers|error admin = dbClient->/adminusers/[userId].get();
        if admin is error {
            log:printError("Government official not found: " + admin.message());
            return error("Government official not found");
        }

        UserRole role = GOVERNMENT_OFFICIAL;
        
        return {
            id: admin.id,
            fullName: admin.username,
            userType: "government_official",
            role: role,
            permissions: getRolePermissions(role)
        };
        
    } else if userType == "election_commission" {
        store:AdminUsers|error admin = dbClient->/adminusers/[userId].get();
        if admin is error {
            log:printError("Election commission user not found: " + admin.message());
            return error("Election commission user not found");
        }

        UserRole role = ELECTION_COMMISSION;
        
        return {
            id: admin.id,
            fullName: admin.username,
            userType: "election_commission",
            role: role,
            permissions: getRolePermissions(role)
        };
        
    } else if userType == "admin" {
        store:AdminUsers|error admin = dbClient->/adminusers/[userId].get();
        if admin is error {
            log:printError("Admin user not found: " + admin.message());
            return error("Admin user not found");
        }

        UserRole role = ADMIN;
        
        return {
            id: admin.id,
            fullName: admin.username,
            userType: "admin",
            role: role,
            permissions: getRolePermissions(role)
        };
    }

    log:printError("Unsupported user type: " + userType);
    return error("Unsupported user type: " + userType);
}

// Main authorization middleware
public function withAuth(
        http:Request request,
        AuthOptions options = {}
) returns AuthenticatedUser|http:Response|file:Error|AuthenticationError {

    // Extract token
    string|AuthenticationError token = extractTokenFromRequest(request);
    if token is AuthenticationError {
        return createErrorResponse(401, "Authentication required: " + token.message());
    }

    // Validate token with blacklist check
    AuthenticatedUser|AuthenticationError user = check validateTokenWithBlacklist(token);
    if user is AuthenticationError {
        return createErrorResponse(401, "Invalid token: " + user.message());
    }

    // Check role authorization
    if !hasRole(user, options.allowedRoles) {
        return createErrorResponse(403, "Insufficient permissions - role not allowed");
    }

    // Check permission authorization
    foreach Permission permission in options.requiredPermissions {
        if !hasPermission(user, permission) {
            return createErrorResponse(403, "Insufficient permissions - missing: " + permission);
        }
    }

    return user;
}

// Helper function to create error responses
function createErrorResponse(int statusCode, string message) returns http:Response {
    http:Response response = new;
    response.statusCode = statusCode;
    response.setJsonPayload({
        "error": message,
        "statusCode": statusCode
    });
    return response;
}

// JWT generation with crypto key handling
public function generateJwtWithId(string userId, UserRole role) returns string|error {
    log:printInfo("=== JWT GENERATION START ===");
    log:printInfo("Generating JWT for userId: " + userId + ", role: " + role.toString());
    
    int seconds = time:utcNow()[0];
    int expiryTime = seconds + 3600; // 1 hour
    string jti = common:generateId();

    // Map role to userType string for consistency
    string userType;
    match role {
        ADMIN => { userType = "admin"; }
        CHIEF_OCCUPANT => { userType = "chief_occupant"; }
        HOUSEHOLD_MEMBER => { userType = "household_member"; }
        GOVERNMENT_OFFICIAL => { userType = "government_official"; }
        ELECTION_COMMISSION => { userType = "election_commission"; }
        _ => { userType = "unknown"; }
    }

    jwt:IssuerConfig issuerConfig = {
        username: "online-election-system",
        issuer: "election-authority",
        audience: "election-clients",
        expTime: 3600,
        customClaims: {
            sub: userId,
            role: role.toString(),
            userType: userType,
            iat: seconds,
            exp: expiryTime,
            jti: jti
        },
        signatureConfig: {
            config: {
                keyFile: "./resources/private_key.pem",
                keyPassword: ""  // Empty for unencrypted key
            }
        }
    };
    
    string|jwt:Error tokenResult = jwt:issue(issuerConfig);
    if tokenResult is jwt:Error {
        log:printError("JWT generation failed: " + tokenResult.message());
        return error("JWT generation failed: " + tokenResult.message());
    }
    
    log:printInfo("JWT generated successfully");
    log:printInfo("=== JWT GENERATION END ===");
    return tokenResult;
}
