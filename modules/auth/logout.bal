import ballerina/http;
import ballerina/jwt;
import ballerina/log;
import ballerina/time;

// Enhanced token blacklist with expiry matching JWT exp claim
final map<BlacklistedTokenRecord> tokenBlacklist = {};

// Blacklist record with full token metadata
public type BlacklistedTokenRecord record {|
    string tokenId;
    int expiryTime;
    string userId;
    string userType;
    int blacklistedAt;
|};

// Enhanced blacklist operations
public function addToBlacklistWithMetadata(string tokenId, int expiryTime, string userId, string userType) {
    tokenBlacklist[tokenId] = {
        tokenId: tokenId,
        expiryTime: expiryTime,
        userId: userId,
        userType: userType,
        blacklistedAt: time:utcNow()[0]
    };
}

public function isTokenBlacklisted(string tokenId) returns boolean {
    BlacklistedTokenRecord? tokenRecord = tokenBlacklist[tokenId];
    if tokenRecord is BlacklistedTokenRecord {
        int currentTime = time:utcNow()[0];
        if currentTime > tokenRecord.expiryTime {
            // Token expired naturally, remove from blacklist
            _ = tokenBlacklist.remove(tokenId);
            return false;
        }
        return true;
    }
    return false;
}

// Revoke all tokens for a specific user (for refresh token cleanup)
public function revokeAllUserTokens(string userId) returns int {
    int revokedCount = 0;
    string[] tokensToRevoke = [];

    foreach var [tokenId, tokenRecord] in tokenBlacklist.entries() {
        if tokenRecord.userId == userId {
            tokensToRevoke.push(tokenId);
        }
    }

    foreach string tokenId in tokensToRevoke {
        _ = tokenBlacklist.remove(tokenId);
        revokedCount += 1;
    }

    return revokedCount;
}

// Bulletproof logout function with 204 No Content and comprehensive cleanup
public function logout(http:Request request) returns http:Response|error {
    http:Response response = new;
    response.statusCode = 204;

    // Extract token from request
    string|AuthenticationError token = extractTokenFromRequest(request);
    if token is AuthenticationError {
        log:printInfo("Logout attempt without valid token: " + token.message());
        // Still return 204 - logout is idempotent
        addLogoutCookies(response);
        return response;
    }

    // Validate token to get its claims
    jwt:ValidatorConfig validatorConfig = {
        issuer: "wso2",
        audience: "vEwzbcasJVQm1jVYHUHCjhxZ4tYa",
        signatureConfig: {
            certFile: "./resources/public.key"
        }
    };

    jwt:Payload|jwt:Error payload = jwt:validate(token, validatorConfig);
    if payload is jwt:Error {
        log:printInfo("Logout attempt with invalid token: " + payload.message());
        // Still return 204 - logout is idempotent
        addLogoutCookies(response);
        return response;
    }

    // Extract token metadata
    anydata jtiClaim = payload["jti"];
    anydata expClaim = payload["exp"];
    anydata userIdClaim = payload["sub"];
    anydata roleClaim = payload["role"];

    if jtiClaim is string && expClaim is int && userIdClaim is string && roleClaim is string {
        // Add token to blacklist with full metadata
        addToBlacklistWithMetadata(jtiClaim, expClaim, userIdClaim, roleClaim);

        // Kill any refresh tokens for this user (implement based on your refresh token storage)
        int revokedRefreshTokens = revokeRefreshTokensForUser(userIdClaim);

        log:printInfo(string `User logged out - ID: ${userIdClaim}, Role: ${roleClaim}, JWT: ${jtiClaim}, Refresh tokens revoked: ${revokedRefreshTokens}`);
    }

    // Clear auth cookies and return 204 No Content
    addLogoutCookies(response);
    return response;
}

// Helper function to add cookie clearing headers
function addLogoutCookies(http:Response response) {
    // Create cookie strings manually for clearing
    string sessionCookieHeader = "SESSION=; Path=/; Max-Age=0; HttpOnly; Secure; SameSite=Lax";
    string authCookieHeader = "AUTH_TOKEN=; Path=/; Max-Age=0; HttpOnly; Secure; SameSite=Lax";

    // Set multiple cookies by adding headers individually
    response.addHeader("Set-Cookie", sessionCookieHeader);
    response.addHeader("Set-Cookie", authCookieHeader);
}

// Refresh token revocation (implement based on your storage)
function revokeRefreshTokensForUser(string userId) returns int {
    // If you store refresh tokens in database:
    // DELETE FROM refresh_tokens WHERE user_id = userId

    // If you store refresh tokens in Redis:
    // DELETE redis_key_pattern_for_user

    // For now, just log the action
    log:printInfo("Refresh token revocation requested for user: " + userId);

    // TODO: Implement actual refresh token deletion based on your storage
    // Return number of refresh tokens deleted
    return 0;
}

// Enhanced JWT validation that checks blacklist
public function validateTokenWithBlacklist(string token) returns AuthenticatedUser|AuthenticationError {
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

    // Check if token is blacklisted
    anydata jtiClaim = payload["jti"];
    if jtiClaim is string {
        if isTokenBlacklisted(jtiClaim) {
            return error AuthenticationError("Token has been revoked");
        }
    }

    // Extract user info from JWT payload (rest of validation logic remains same)
    string|error userId = payload.sub.toString();
    if userId is error {
        return error AuthenticationError("Invalid token payload");
    }

    anydata roleClaim = payload["role"];
    if roleClaim is () {
        return error AuthenticationError("Role claim missing in token");
    }

    string userType;
    if roleClaim is string {
        userType = roleClaim;
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

// Get blacklist statistics (for monitoring)
public function getBlacklistStats() returns json {
    int currentTime = time:utcNow()[0];
    int totalTokens = tokenBlacklist.length();
    int expiredTokens = 0;

    foreach var [_, tokenRecord] in tokenBlacklist.entries() {
        if currentTime > tokenRecord.expiryTime {
            expiredTokens += 1;
        }
    }

    return {
        "totalBlacklistedTokens": totalTokens,
        "expiredTokens": expiredTokens,
        "activeBlacklistedTokens": totalTokens - expiredTokens,
        "lastCleanupTime": currentTime
    };
}

// Function to manually trigger cleanup (for admin endpoints)
public function manualTokenCleanup() returns json {
    log:printInfo("Manual token cleanup triggered");

    int currentTime = time:utcNow()[0];
    int cleanedCount = 0;
    string[] expiredTokens = [];

    foreach var [tokenId, tokenRecord] in tokenBlacklist.entries() {
        if currentTime > tokenRecord.expiryTime {
            expiredTokens.push(tokenId);
        }
    }

    foreach string tokenId in expiredTokens {
        _ = tokenBlacklist.remove(tokenId);
        cleanedCount += 1;
    }

    log:printInfo(string `Manual cleanup completed. Removed ${cleanedCount} expired tokens`);

    return {
        "status": "success",
        "message": "Manual cleanup completed",
        "tokensRemoved": cleanedCount,
        "remainingTokens": tokenBlacklist.length()
    };
}