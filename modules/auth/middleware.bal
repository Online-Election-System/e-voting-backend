import online_election.store;

import ballerina/http;
import ballerina/jwt;
import ballerina/log;

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

// Validate JWT token and extract user info
public function validateToken(string token) returns AuthenticatedUser|AuthenticationError {
    jwt:ValidatorConfig validatorConfig = {
        issuer: "wso2",
        audience: "vEwzbcasJVQm1jVYHUHCjhxZ4tYa",
        signatureConfig: {
            certFile: "./resources/public.key"
        }
    };

    jwt:Payload|jwt:Error payload = jwt:validate(token, validatorConfig);
    if payload is jwt:Error {
        log:printError("JWT validation failed: " + payload.message());
        return error AuthenticationError("Invalid or expired token");
    }

    // Extract user info from JWT payload
    string|error userId = payload.sub.toString();
    if userId is error {
        return error AuthenticationError("Invalid token payload");
    }

    // Safe way to access and convert custom claims
    anydata roleClaim = payload["role"];
    if roleClaim is () {
        return error AuthenticationError("Role claim missing in token");
    }

    string userType;
    if roleClaim is string {
        userType = roleClaim;
    } else if roleClaim is int || roleClaim is float || roleClaim is decimal {
        userType = roleClaim.toString();
    } else if roleClaim is boolean {
        userType = roleClaim.toString();
    } else if roleClaim is json {
        userType = roleClaim.toJsonString();
    } else {
        return error AuthenticationError("Invalid role claim type in token");
    }

    // Get user details from database
    AuthenticatedUser|error user = getUserFromDatabase(userId, userType);
    if user is error {
        return error AuthenticationError("User not found");
    }

    return user;
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

        return {
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

    // Validate token and get user
    AuthenticatedUser|AuthenticationError user = validateToken(token);
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
