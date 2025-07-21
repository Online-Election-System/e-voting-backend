import ballerina/log;
import ballerina/task;
import ballerina/time;

// Cleanup configuration
const decimal CLEANUP_INTERVAL_MINUTES = 30.0; // Run cleanup every 30 minutes

// Initialize cleanup scheduler
public function initializeTokenCleanup() returns error? {
    task:JobId cleanupJobId = check task:scheduleJobRecurByFrequency(new TokenCleanupJob(), CLEANUP_INTERVAL_MINUTES);
    log:printInfo("Token cleanup scheduler initialized with job ID: " + cleanupJobId.toString());
}

// Job class for token cleanup
class TokenCleanupJob {
    *task:Job;

    public function execute() {
        log:printInfo("Starting token blacklist cleanup...");

        int currentTime = time:utcNow()[0];
        int cleanedCount = 0;
        string[] expiredTokens = [];

        // Collect expired tokens - access the blacklist from logout.bal
        foreach var [tokenId, tokenRecord] in tokenBlacklist.entries() {
            if currentTime > tokenRecord.expiryTime {
                expiredTokens.push(tokenId);
            }
        }

        // Remove expired tokens
        foreach string tokenId in expiredTokens {
            _ = tokenBlacklist.remove(tokenId);
            cleanedCount += 1;
        }

        log:printInfo(string `Token cleanup completed. Removed ${cleanedCount} expired tokens. Active blacklisted tokens: ${tokenBlacklist.length()}`);
    }
}

// Function to clean up expired tokens manually
public function cleanupExpiredTokens() {
    int currentTime = time:utcNow()[0];
    string[] expiredTokens = [];

    // Collect expired tokens
    foreach var [tokenId, tokenRecord] in tokenBlacklist.entries() {
        if currentTime > tokenRecord.expiryTime {
            expiredTokens.push(tokenId);
        }
    }

    // Remove expired tokens
    foreach string tokenId in expiredTokens {
        _ = tokenBlacklist.remove(tokenId);
    }

    log:printInfo(string `Manual cleanup completed. Removed ${expiredTokens.length()} expired tokens`);
}
