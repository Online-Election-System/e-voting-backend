import online_election.common;
import online_election.store;

import ballerina/http;
import ballerina/jwt;
import ballerina/time;

// Extract and validate JWT token from request
public function extractTokenFromRequest(http:Request request) returns string|AuthenticationError {
    string|http:HeaderNotFoundError authHeader = request.getHeader("Authorization");
    if authHeader is http:HeaderNotFoundError {
        return error AuthenticationError("Authorization header not found");
    }

    if !authHeader.startsWith("Bearer ") {
        return error AuthenticationError("Invalid authorization header format");
    }

    return authHeader.substring(7); // Remove "Bearer " prefix
}

// Get user from database and determine role/permissions
function getUserFromDatabase(string userId, string userType) returns AuthenticatedUser|error {
    // This is a simplified version - you'll need to adapt based on your DB structure
    if userType == "chief" {
        store:ChiefOccupant|error chief = dbClient->/chiefoccupants/[userId].get();
        if chief is error {
            return error("Chief occupant not found");
        }

        // Determine role based on verification status (you'll need to add this to your DB)
        UserRole role = CHIEF_OCCUPANT; // Default
        // You can add logic here to check if user is verified
        // if (chief.isVerified) { role = VERIFIED_CHIEF_OCCUPANT; }

        return  {
            id: chief.id,
            fullName: chief.fullName,
            userType: "chief",
            role: role,
            permissions: getRolePermissions(role)
        };
    } else if userType == "householdMember" {
        store:HouseholdMembers|error member = dbClient->/householdmembers/[userId].get();
        if member is error {
            return error("Household member not found");
        }

        UserRole role = HOUSEHOLD_MEMBER; // Default
        // Add verification logic here

        return {
            id: member.id,
            fullName: member.fullName,
            userType: "householdMember",
            role: role,
            permissions: getRolePermissions(role)
        };
    }

    return error("Unsupported user type");
}

// Main authorization middleware
public function withAuth(
        http:Request request,
        AuthOptions options = {}
) returns AuthenticatedUser|http:Response {

    // Extract token
    string|AuthenticationError token = extractTokenFromRequest(request);
    if token is AuthenticationError {
        return createErrorResponse(401, "Authentication required: " + token.message());
    }

    // Validate token with blacklist check
    AuthenticatedUser|AuthenticationError user = validateTokenWithBlacklist(token);
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

// Enhanced JWT generation with JTI (JWT ID) for tracking
public function generateJwtWithId(string userId, UserRole role) returns string|error {
    int seconds = time:utcNow()[0];
    int expiryTime = seconds + 3600;

    // Generate unique JWT ID for this token
    string jti = common:generateId();

    jwt:IssuerConfig issuerConfig = {
        username: "ballerina",
        issuer: "wso2",
        audience: "vEwzbcasJVQm1jVYHUHCjhxZ4tYa",
        expTime: 3600,
        customClaims: {
            sub: userId,
            role: role,
            userRole: role,
            iat: seconds,
            exp: expiryTime,
            jti: jti // Add JWT ID for tracking
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
