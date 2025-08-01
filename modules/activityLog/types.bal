import ballerina/time;

// Activity types enum for standardized logging
public enum ActivityType {
    // Authentication actions
    LOGIN_ATTEMPT = "LOGIN_ATTEMPT",
    LOGIN_SUCCESS = "LOGIN_SUCCESS", 
    LOGIN_FAILURE = "LOGIN_FAILURE",
    LOGOUT = "LOGOUT",
    PASSWORD_CHANGE = "PASSWORD_CHANGE",
    
    
    // Registration actions
    VOTER_REGISTRATION = "VOTER_REGISTRATION",
    REGISTRATION_REVIEW = "REGISTRATION_REVIEW",
    WELCOME_EMAIL_SEND = "WELCOME_EMAIL_SEND",
    HOUSEHOLD_CREATION = "HOUSEHOLD_CREATION",
    HOUSEHOLD_PASSWORDS_EMAIL = "HOUSEHOLD_PASSWORDS_EMAIL",
    
    // Election actions
    ELECTION_CREATED = "ELECTION_CREATED",
    ELECTION_UPDATED = "ELECTION_UPDATED",
    ELECTION_DELETED = "ELECTION_DELETED",
    ELECTION_VIEWED = "ELECTION_VIEWED",
    
    // Candidate actions
    CANDIDATE_CREATED = "CANDIDATE_CREATED",
    CANDIDATE_UPDATED = "CANDIDATE_UPDATED",
    CANDIDATE_DELETED = "CANDIDATE_DELETED",
    CANDIDATE_VIEWED = "CANDIDATE_VIEWED",
    
    // Voting actions
    VOTE_CAST = "VOTE_CAST",
    VOTE_ATTEMPT = "VOTE_ATTEMPT",
    VOTING_ELIGIBILITY_CHECK = "VOTING_ELIGIBILITY_CHECK",
    
    // Enrollment actions
    ELECTION_ENROLLMENT = "ELECTION_ENROLLMENT",
    ENROLLMENT_CHECK = "ENROLLMENT_CHECK",
    
    // Household management
    HOUSEHOLD_MEMBER_ADD = "HOUSEHOLD_MEMBER_ADD",
    HOUSEHOLD_MEMBER_UPDATE = "HOUSEHOLD_MEMBER_UPDATE",
    HOUSEHOLD_MEMBER_DELETE = "HOUSEHOLD_MEMBER_DELETE",
    HOUSEHOLD_VIEWED = "HOUSEHOLD_VIEWED",
    
    // Results and analytics
    RESULTS_VIEWED = "RESULTS_VIEWED",
    RESULTS_EXPORTED = "RESULTS_EXPORTED",
    
    // Administrative actions
    USER_CREATED = "USER_CREATED",
    USER_UPDATED = "USER_UPDATED",
    USER_DELETED = "USER_DELETED",
    SYSTEM_CONFIG_CHANGE = "SYSTEM_CONFIG_CHANGE",
    
    // Data access
    DATA_EXPORT = "DATA_EXPORT",
    REPORT_GENERATED = "REPORT_GENERATED",
    
    // Security events
    UNAUTHORIZED_ACCESS = "UNAUTHORIZED_ACCESS",
    TOKEN_REFRESH = "TOKEN_REFRESH",
    SESSION_EXPIRED = "SESSION_EXPIRED"
}

// Status types for logging
public enum LogStatus {
    SUCCESS = "SUCCESS",
    FAILURE = "FAILURE", 
    ERROR = "ERROR",
    PENDING = "PENDING"
}

// Activity log input for creating logs
public type ActivityLogInput record {|
    string? userId?;
    string? userType?;
    ActivityType action;
    string? resourceId?;
    string? httpMethod?;
    string endpoint;
    string? ipAddress?;
    string? userAgent?;
    LogStatus status;
    string? details?;
    string? sessionId?;
|};

// Detailed activity log for API responses
public type ActivityLogResponse record {|
    string id;
    string? userId;
    string? userType;
    string? userFullName; // Resolved from user tables
    string action;
    string? resourceId;
    string? httpMethod;
    string endpoint;
    string? ipAddress;
    string? userAgent;
    time:Utc timestamp;
    string status;
    string? details;
    string? sessionId;
|};

// Filter options for activity log queries
public type ActivityLogFilter record {|
    string? userId?;
    string? userType?;
    ActivityType[] actions?;
    LogStatus[] statuses?;
    time:Utc? startTime?;
    time:Utc? endTime?;
    string? endpoint?;
    string? ipAddress?;
    int 'limit?;
    int offset?;
|};

// Statistics for activity dashboard
public type ActivityStats record {|
    int totalActivities;
    int uniqueUsers;
    int successfulActions;
    int failedActions;
    int todayActivities;
    map<int> actionCounts; // action type -> count
    map<int> userTypeCounts; // user type -> count
    map<int> hourlyActivity; // hour -> count
|};

// Security alert types
public type SecurityAlert record {|
    string alertId;
    string alertType; // MULTIPLE_FAILED_LOGINS, SUSPICIOUS_ACTIVITY, etc.
    string? userId;
    string? ipAddress;
    string description;
    time:Utc timestamp;
    string severity; // LOW, MEDIUM, HIGH, CRITICAL
    boolean resolved;
|};
