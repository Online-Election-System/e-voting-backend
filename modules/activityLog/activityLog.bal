import online_election.store;
import online_election.common;

import ballerina/http;
import ballerina/time;
import ballerina/persist;
import ballerina/log;
import ballerina/io;
import ballerina/regex;

// Database client for activity logging
final store:Client activityDbClient = check new ();

// Cache for user details to avoid repeated database calls
map<string> userNameCache = {};

// CORE LOGGING FUNCTIONS

// Main function to log user activities
public function logActivity(ActivityLogInput activityInput) returns error? {
    string logId = common:generateId();
    
    store:ActivityLogInsert activityLog = {
        id: logId,
        userId: activityInput?.userId,
        userType: activityInput?.userType,
        action: activityInput.action,
        resourceId: activityInput?.resourceId,
        httpMethod: activityInput?.httpMethod,
        endpoint: activityInput.endpoint,
        ipAddress: activityInput?.ipAddress,
        userAgent: activityInput?.userAgent,
        timestamp: time:utcNow(),
        status: activityInput.status,
        details: activityInput?.details,
        sessionId: activityInput?.sessionId
    };

    string[]|persist:Error result = activityDbClient->/activitylogs.post([activityLog]);
    
    if result is persist:Error {
        log:printError("Failed to log activity", 'error = result);
        return error("Failed to log activity: " + result.message());
    }
    
    // Log to console for critical activities
    if activityInput.status.toString() == "ERROR" || activityInput.action.toString() == "UNAUTHORIZED_ACCESS" {
        string alertMessage = string `SECURITY ALERT: ${activityInput.action} by user ${activityInput?.userId ?: "UNKNOWN"} at ${time:utcToString(time:utcNow())}`;
        io:println(alertMessage);
    }
    
    return ();
}

// Convenient wrapper functions for common activities

public function logAuthenticationActivity(
    string? userId, 
    string? userType, 
    ActivityType action, 
    LogStatus status,
    http:Request? request = (),
    string? details = ()
) returns error? {
    
    ActivityLogInput logInput = {
        userId: userId,
        userType: userType,
        action: action,
        endpoint: getEndpointFromRequest(request),
        httpMethod: getMethodFromRequest(request),
        ipAddress: getIpFromRequest(request),
        userAgent: getUserAgentFromRequest(request),
        status: status,
        details: details
    };
    
    return logActivity(logInput);
}

public function logElectionActivity(
    string? userId,
    string? userType,
    ActivityType action,
    string? electionId,
    LogStatus status,
    http:Request? request = (),
    string? details = ()
) returns error? {
    
    ActivityLogInput logInput = {
        userId: userId,
        userType: userType,
        action: action,
        resourceId: electionId,
        endpoint: getEndpointFromRequest(request),
        httpMethod: getMethodFromRequest(request),
        ipAddress: getIpFromRequest(request),
        userAgent: getUserAgentFromRequest(request),
        status: status,
        details: details
    };
    
    return logActivity(logInput);
}

public function logVotingActivity(
    string? userId,
    string? userType,
    ActivityType action,
    string? electionId,
    string? candidateId,
    LogStatus status,
    http:Request? request = (),
    string? details = ()
) returns error? {
    
    string? resourceId = electionId;
    if candidateId is string && electionId is string {
        resourceId = string `${electionId}:${candidateId}`;
    }
    
    ActivityLogInput logInput = {
        userId: userId,
        userType: userType,
        action: action,
        resourceId: resourceId,
        endpoint: getEndpointFromRequest(request),
        httpMethod: getMethodFromRequest(request),
        ipAddress: getIpFromRequest(request),
        userAgent: getUserAgentFromRequest(request),
        status: status,
        details: details
    };
    
    return logActivity(logInput);
}

// ADMIN QUERY FUNCTIONS

// Get activity logs with filtering (Admin only)
public function getActivityLogs(ActivityLogFilter filter) returns ActivityLogResponse[]|error {
    // For now, use a simple approach without complex SQL building
    // You can enhance this later with proper query building
    
    stream<store:ActivityLog, persist:Error?> activityStream = activityDbClient->/activitylogs.get();
    store:ActivityLog[] allActivities = check from store:ActivityLog activity in activityStream select activity;
    
    // Apply filters programmatically
    store:ActivityLog[] filteredActivities = allActivities;
    
    // Filter by userId
    if filter?.userId is string {
        string filterUserId = filter?.userId ?: "";
        store:ActivityLog[] userFilteredActivities = [];
        foreach store:ActivityLog activity in filteredActivities {
            if activity.userId == filterUserId {
                userFilteredActivities.push(activity);
            }
        }
        filteredActivities = userFilteredActivities;
    }
    
    // Filter by userType
    if filter?.userType is string {
        string filterUserType = filter?.userType ?: "";
        store:ActivityLog[] typeFilteredActivities = [];
        foreach store:ActivityLog activity in filteredActivities {
            if activity.userType == filterUserType {
                typeFilteredActivities.push(activity);
            }
        }
        filteredActivities = typeFilteredActivities;
    }
    
    // Filter by endpoint
    if filter?.endpoint is string {
        string filterEndpoint = filter?.endpoint ?: "";
        store:ActivityLog[] endpointFilteredActivities = [];
        foreach store:ActivityLog activity in filteredActivities {
            if activity.endpoint.includes(filterEndpoint) {
                endpointFilteredActivities.push(activity);
            }
        }
        filteredActivities = endpointFilteredActivities;
    }
    
    // Sort by timestamp descending (manual sorting)
    store:ActivityLog[] sortedActivities = filteredActivities;
    // For simplicity, we'll skip complex sorting for now
    // You can implement a proper sorting algorithm if needed
    
    // Apply limit and offset
    int 'limit = filter?.'limit ?: 100;
    int offset = filter?.offset ?: 0;
    
    store:ActivityLog[] limitedActivities = [];
    int startIndex = offset;
    int endIndex = offset + 'limit;
    
    foreach int i in startIndex ..< endIndex {
        if i < sortedActivities.length() {
            limitedActivities.push(sortedActivities[i]);
        }
    }
    
    // Convert to response format with user names
    ActivityLogResponse[] responses = [];
    foreach store:ActivityLog activity in limitedActivities {
        string? userFullName = activity.userId is string ? getUserFullName(activity.userId, activity.userType) : ();
        
        responses.push({
            id: activity.id,
            userId: activity.userId,
            userType: activity.userType,
            userFullName: userFullName,
            action: activity.action,
            resourceId: activity.resourceId,
            httpMethod: activity.httpMethod,
            endpoint: activity.endpoint,
            ipAddress: activity.ipAddress,
            userAgent: activity.userAgent,
            timestamp: activity.timestamp,
            status: activity.status,
            details: activity.details,
            sessionId: activity.sessionId
        });
    }
    
    return responses;
}

// Get activity statistics for admin dashboard
public function getActivityStats(time:Utc? startTime = (), time:Utc? endTime = ()) returns ActivityStats|error {
    time:Utc end;
    if endTime is time:Utc {
        end = endTime;
    } else {
        end = time:utcNow();
    }
    
    time:Utc startT = startTime is time:Utc ? startTime : time:utcAddSeconds(end, -86400.0);

    // Get all activities and filter by time range
    stream<store:ActivityLog, persist:Error?> activityStream = activityDbClient->/activitylogs.get();
    store:ActivityLog[] allActivities = check from store:ActivityLog activity in activityStream select activity;
    
    // Filter by time range
    store:ActivityLog[] timeFilteredActivities = [];
    foreach store:ActivityLog activity in allActivities {
        // Ensure timestamp exists and compare time:Utc values
        time:Utc activityTime = activity.timestamp;
        if activityTime >= startT && activityTime <= end {
            timeFilteredActivities.push(activity);
        }
    }
    
    // Calculate basic stats
    int totalActivities = timeFilteredActivities.length();
    
    // Count unique users
    map<boolean> uniqueUserMap = {};
    foreach store:ActivityLog activity in timeFilteredActivities {
        if activity.userId is string {
            uniqueUserMap[activity.userId ?: ""] = true;
        }
    }
    int uniqueUsers = uniqueUserMap.length();
    
    // Count successful and failed actions
    int successfulActions = 0;
    int failedActions = 0;
    foreach store:ActivityLog activity in timeFilteredActivities {
        if activity.status == "SUCCESS" {
            successfulActions += 1;
        } else if activity.status == "FAILURE" || activity.status == "ERROR" {
            failedActions += 1;
        }
    }
    
    // Count today's activities (last 24 hours from now)
    time:Utc todayStart = time:utcAddSeconds(time:utcNow(), -86400.0);
    store:ActivityLog[] todayActivities = [];
    foreach store:ActivityLog activity in allActivities {
        time:Utc activityTime = activity.timestamp;
        if activityTime >= todayStart {
            todayActivities.push(activity);
        }
    }
    int todayActivitiesCount = todayActivities.length();
    
    // Count actions
    map<int> actionCounts = {};
    foreach store:ActivityLog activity in timeFilteredActivities {
        string action = activity.action;
        int currentCount = actionCounts[action] ?: 0;
        actionCounts[action] = currentCount + 1;
    }
    
    // Count user types
    map<int> userTypeCounts = {};
    foreach store:ActivityLog activity in timeFilteredActivities {
        if activity.userType is string {
            string userType = activity.userType ?: "";
            int currentCount = userTypeCounts[userType] ?: 0;
            userTypeCounts[userType] = currentCount + 1;
        }
    }
    
    // Calculate hourly activity (simplified)
    map<int> hourlyActivity = {};
    foreach store:ActivityLog activity in todayActivities {
        time:Utc activityTime = activity.timestamp;
        time:Civil civil = time:utcToCivil(activityTime);
        string hourKey = civil.hour.toString();
        int currentCount = hourlyActivity[hourKey] ?: 0;
        hourlyActivity[hourKey] = currentCount + 1;
    }
    
    return {
        totalActivities: totalActivities,
        uniqueUsers: uniqueUsers,
        successfulActions: successfulActions,
        failedActions: failedActions,
        todayActivities: todayActivitiesCount,
        actionCounts: actionCounts,
        userTypeCounts: userTypeCounts,
        hourlyActivity: hourlyActivity
    };
}

// Security monitoring functions
public function getSecurityAlerts(time:Utc? since = ()) returns SecurityAlert[]|error {
    time:Utc startT;
    if since is time:Utc {
        startT = since;
    } else {
        // Default: last hour (3600 seconds)
        startT = time:utcAddSeconds(time:utcNow(), -3600.0);
    }
    
    // Get all activities and filter by time
    stream<store:ActivityLog, persist:Error?> activityStream = activityDbClient->/activitylogs.get();
    store:ActivityLog[] allActivities = check from store:ActivityLog activity in activityStream select activity;
    
    store:ActivityLog[] recentActivities = [];
    foreach store:ActivityLog activity in allActivities {
        // Ensure timestamp exists and compare time:Utc values
        time:Utc activityTime = activity.timestamp;
        if activityTime >= startT {
            recentActivities.push(activity);
        }
    }
    
    SecurityAlert[] alerts = [];
    
    // Track failed login attempts by IP
    map<int> failedLoginsByIp = {};
    map<string?> userIdByIp = {};
    
    foreach store:ActivityLog activity in recentActivities {
        if activity.action == "LOGIN_FAILURE" && activity.ipAddress is string {
            string ip = activity.ipAddress ?: "";
            int currentCount = failedLoginsByIp[ip] ?: 0;
            failedLoginsByIp[ip] = currentCount + 1;
            userIdByIp[ip] = activity.userId;
        }
    }
    
    // Generate alerts for multiple failed logins
    foreach var [ip, attempts] in failedLoginsByIp.entries() {
        if attempts >= 5 {
            alerts.push({
                alertId: common:generateId(),
                alertType: "MULTIPLE_FAILED_LOGINS",
                userId: userIdByIp[ip],
                ipAddress: ip,
                description: string `${attempts} failed login attempts from IP ${ip}`,
                timestamp: time:utcNow(),
                severity: attempts >= 10 ? "HIGH" : "MEDIUM",
                resolved: false
            });
        }
    }
    
    // Track unauthorized access attempts
    map<int> unauthorizedByUser = {};
    map<string?> ipByUser = {};
    
    foreach store:ActivityLog activity in recentActivities {
        if activity.action == "UNAUTHORIZED_ACCESS" {
            string userId = activity.userId ?: "UNKNOWN";
            int currentCount = unauthorizedByUser[userId] ?: 0;
            unauthorizedByUser[userId] = currentCount + 1;
            ipByUser[userId] = activity.ipAddress;
        }
    }
    
    // Generate alerts for unauthorized access
    foreach var [userId, attempts] in unauthorizedByUser.entries() {
        alerts.push({
            alertId: common:generateId(),
            alertType: "UNAUTHORIZED_ACCESS",
            userId: userId == "UNKNOWN" ? () : userId,
            ipAddress: ipByUser[userId],
            description: string `${attempts} unauthorized access attempts`,
            timestamp: time:utcNow(),
            severity: "HIGH",
            resolved: false
        });
    }
    
    return alerts;
}

// HELPER FUNCTIONS

function getUserFullName(string? userId, string? userType) returns string? {
    if userId is () || userType is () {
        return ();
    }
    
    string cacheKey = string `${userType}:${userId}`;
    if userNameCache.hasKey(cacheKey) {
        return userNameCache.get(cacheKey);
    }
    
    string? fullName = ();
    
    if userType == "chief_occupant" {
        store:ChiefOccupant|persist:Error chief = activityDbClient->/chiefoccupants/[userId].get();
        if chief is store:ChiefOccupant {
            fullName = chief.fullName;
        }
    } else if userType == "household_member" {
        store:HouseholdMembers|persist:Error member = activityDbClient->/householdmembers/[userId].get();
        if member is store:HouseholdMembers {
            fullName = member.fullName;
        }
    } else if userType == "admin" || userType == "government_official" || userType == "election_commission" || userType == "polling_station" {
        store:AdminUsers|persist:Error admin = activityDbClient->/adminusers/[userId].get();
        if admin is store:AdminUsers {
            fullName = admin.username;
        }
    }
    
    if fullName is string {
        userNameCache[cacheKey] = fullName;
    }
    
    return fullName;
}

// Enhanced IP address extraction with multiple header fallbacks
public function getIpFromRequest(http:Request? request) returns string {
    if request is () {
        return "unknown";
    }
    
    // Try X-Forwarded-For header first (most common for proxies/load balancers)
    string|http:HeaderNotFoundError xForwardedFor = request.getHeader("X-Forwarded-For");
    if xForwardedFor is string {
        string trimmed = xForwardedFor.trim();
        if trimmed != "" {
            // X-Forwarded-For can have multiple IPs: "client, proxy1, proxy2"
            // Split by comma and take the first one (original client)
            string[] parts = regex:split(trimmed, ",");
            if parts.length() > 0 {
                string clientIp = parts[0].trim();
                if clientIp != "" && clientIp != "unknown" {
                    return clientIp;
                }
            }
        }
    }
    
    // Try X-Real-IP header (nginx)
    string|http:HeaderNotFoundError xRealIp = request.getHeader("X-Real-IP");
    if xRealIp is string {
        string trimmed = xRealIp.trim();
        if trimmed != "" && trimmed != "unknown" {
            return trimmed;
        }
    }
    
    // Try X-Client-IP header
    string|http:HeaderNotFoundError xClientIp = request.getHeader("X-Client-IP");
    if xClientIp is string {
        string trimmed = xClientIp.trim();
        if trimmed != "" && trimmed != "unknown" {
            return trimmed;
        }
    }
    
    // Try CF-Connecting-IP (Cloudflare)
    string|http:HeaderNotFoundError cfIp = request.getHeader("CF-Connecting-IP");
    if cfIp is string {
        string trimmed = cfIp.trim();
        if trimmed != "" && trimmed != "unknown" {
            return trimmed;
        }
    }
    
    // Debug: Log all headers to see what's available
    log:printInfo("=== DEBUG: Available headers for IP extraction ===");
    // You might need to iterate through available headers to see what's there
    
    return "unknown";
}

// Enhanced User-Agent extraction with validation
public function getUserAgentFromRequest(http:Request? request) returns string {
    if request is () {
        return "unknown";
    }
    
    string|http:HeaderNotFoundError userAgent = request.getHeader("User-Agent");
    if userAgent is string && userAgent.trim() != "" {
        // Truncate very long user agent strings (some bots send extremely long ones)
        if userAgent.length() > 500 {
            return userAgent.substring(0, 500) + "...";
        }
        return userAgent.trim();
    }
    
    return "unknown";
}

// Enhanced endpoint extraction
public function getEndpointFromRequest(http:Request? request) returns string {
    if request is () {
        return "unknown";
    }
    
    return request.rawPath;
}

// Get HTTP method with validation
public function getMethodFromRequest(http:Request? request) returns string {
    if request is () {
        return "UNKNOWN";
    }
    return request.method.toUpperAscii(); // Normalize to uppercase
}

// Extract referrer information for security analysis
public function getReferrerFromRequest(http:Request? request) returns string {
    if request is () {
        return "unknown";
    }
    
    string|http:HeaderNotFoundError referrer = request.getHeader("Referer");
    if referrer is string && referrer.trim() != "" {
        return referrer.trim();
    }
    
    return "unknown";
}

// Extract content type for request analysis
public function getContentTypeFromRequest(http:Request? request) returns string {
    if request is () {
        return "unknown";
    }
    
    string|http:HeaderNotFoundError contentType = request.getHeader("Content-Type");
    if contentType is string && contentType.trim() != "" {
        return contentType.trim();
    }
    
    return "unknown";
}

// Function to enhance details with additional context
public function enhanceDetailsWithContext(string? originalDetails, http:Request? request) returns string {
    if request is () {
        return originalDetails ?: "No additional context";
    }
    
    string[] contextParts = [];
    
    if originalDetails is string {
        contextParts.push(originalDetails);
    }
    
    // Add referrer if available and not unknown
    string referrer = getReferrerFromRequest(request);
    if referrer != "unknown" {
        contextParts.push(string `Referrer: ${referrer}`);
    }
    
    // Add content type if available and not unknown
    string contentType = getContentTypeFromRequest(request);
    if contentType != "unknown" {
        contextParts.push(string `Content-Type: ${contentType}`);
    }
    
    // Add request size if available
    string|http:HeaderNotFoundError contentLength = request.getHeader("Content-Length");
    if contentLength is string {
        contextParts.push(string `Content-Length: ${contentLength}`);
    }
    
    if contextParts.length() == 0 {
        return "No additional context";
    }
    
    // Join the context parts with separator
    string result = "";
    foreach int i in 0 ..< contextParts.length() {
        if i > 0 {
            result += " | ";
        }
        result += contextParts[i];
    }
    
    return result;
}

// Function to detect suspicious activity patterns
public function detectSuspiciousActivity(string ipAddress, string userAgent) returns boolean {
    // Simple suspicious patterns (can be enhanced)
    string[] suspiciousIPs = [
        "0.0.0.0",
        "127.0.0.1"
    ];
    
    foreach string suspiciousIP in suspiciousIPs {
        if ipAddress.includes(suspiciousIP) {
            return true;
        }
    }
    
    // Check for suspicious user agents
    if userAgent != "unknown" {
        string[] suspiciousUserAgents = [
            "bot",
            "crawler",
            "spider",
            "scraper",
            "automated"
        ];
        
        string lowercaseUserAgent = userAgent.toLowerAscii();
        foreach string suspicious in suspiciousUserAgents {
            if lowercaseUserAgent.includes(suspicious) {
                return true;
            }
        }
    }
    
    return false;
}

// Simple logging helper that captures all available context
public function logWithFullContext(
    string? userId,
    string? userType,
    string action,
    string? resourceId,
    string status,
    string? details,
    http:Request? request
) returns error? {
    
    string ipAddress = getIpFromRequest(request);
    string userAgent = getUserAgentFromRequest(request);
    string httpMethod = getMethodFromRequest(request);
    string endpoint = getEndpointFromRequest(request);
    string sessionId = common:generateId(); // Generate new session ID each time
    
    // Enhance details with context
    string enhancedDetails = enhanceDetailsWithContext(details, request);
    
    // Check for suspicious activity
    boolean isSuspicious = detectSuspiciousActivity(ipAddress, userAgent);
    if isSuspicious {
        enhancedDetails += " | SUSPICIOUS ACTIVITY DETECTED";
    }
    
    // TODO: Replace this with actual activity log insertion
    // This is a placeholder - you'll need to call your actual logging function
    io:println(string `LOG: User=${userId ?: "unknown"}, Type=${userType ?: "unknown"}, Action=${action}, Status=${status}, IP=${ipAddress}, Method=${httpMethod}, Endpoint=${endpoint}, Details=${enhancedDetails}`);
    
    return ();
}

// Function to get session info for a user (simplified version)
public function getSessionInfo(string userId, string userType) returns string {
    // In production, this would query a session store
    // For now, just generate a session ID
    return common:generateId();
}