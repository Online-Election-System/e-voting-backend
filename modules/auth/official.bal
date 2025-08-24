import online_election.common;
import online_election.store;

import ballerina/log;
import ballerina/time;
import ballerina/persist;

// Helper function to check if username already exists
function isUsernameExists(string username) returns boolean|error {
    stream<store:AdminUsers, persist:Error?> adminUsersStream = dbClient->/adminusers;
    store:AdminUsers[] existingUsers = check from store:AdminUsers admin in adminUsersStream
        where admin.username == username
        select admin;
    
    return existingUsers.length() > 0;
}

public function registerGovernmentOfficial(GovernmentOfficialRegistrationRequest request) returns json|error {
    // Validate password policy
    string? passwordError = validatePasswordPolicy(request.official.passwordHash);
    if passwordError is string {
        return {
            status: "error",
            message: passwordError
        };
    }

    // Check if username (NIC) already exists
    boolean|error usernameExists = isUsernameExists(request.official.nic);
    if usernameExists is error {
        log:printError("Failed to check username existence: " + usernameExists.message());
        return {
            status: "error",
            message: "Failed to validate user information"
        };
    }
    
    if usernameExists {
        return {
            status: "error",
            message: "User with this NIC already exists"
        };
    }

    string id = common:generateId();

    string|error hashedPassword = hashPassword(request.official.passwordHash);
    if hashedPassword is error {
        log:printError("Failed to hash password: " + hashedPassword.message());
        return {
            status: "error",
            message: "Failed to process password"
        };
    }

    store:AdminUsersInsert insertRec = {
        id: id,
        username: request.official.nic,  // use NIC as username for login
        passwordHash: hashedPassword,
        role: "government_official",
        createdAt: time:utcNow(),
        isActive: true,
        division: request.official.division // optional division field
    };

    string[]|error resp = dbClient->/adminusers.post([insertRec]);
    if resp is error {
        log:printError("Failed to create government official: " + resp.message());
        // Check if it's a unique constraint violation (in case DB has unique constraint)
        if resp.message().includes("unique") || resp.message().includes("duplicate") {
            return {
                status: "error",
                message: "User with this NIC already exists"
            };
        }
        return {
            status: "error",
            message: "Failed to create government official"
        };
    }

    return {
        status: "success",
        id: id,
        message: "Government official registered successfully"
    };
}

public function registerElectionCommission(ElectionCommissionRegistrationRequest request) returns json|error {
    // Validate password policy
    string? passwordError = validatePasswordPolicy(request.commission.passwordHash);
    if passwordError is string {
        return {
            status: "error",
            message: passwordError
        };
    }

    // Check if username (NIC) already exists
    boolean|error usernameExists = isUsernameExists(request.commission.nic);
    if usernameExists is error {
        log:printError("Failed to check username existence: " + usernameExists.message());
        return {
            status: "error",
            message: "Failed to validate user information"
        };
    }
    
    if usernameExists {
        return {
            status: "error",
            message: "User with this NIC already exists"
        };
    }

    string id = common:generateId();

    string|error hashedPassword = hashPassword(request.commission.passwordHash);
    if hashedPassword is error {
        log:printError("Failed to hash password: " + hashedPassword.message());
        return {
            status: "error",
            message: "Failed to process password"
        };
    }

    store:AdminUsersInsert insertRec = {
        id: id,
        username: request.commission.nic,  // use NIC as username for login
        passwordHash: hashedPassword,
        role: "election_commission",
        createdAt: time:utcNow(),
        isActive: true,
        division: ()
    };

    string[]|error resp = dbClient->/adminusers.post([insertRec]);
    if resp is error {
        log:printError("Failed to create election commission: " + resp.message());
        // Check if it's a unique constraint violation (in case DB has unique constraint)
        if resp.message().includes("unique") || resp.message().includes("duplicate") {
            return {
                status: "error",
                message: "User with this NIC already exists"
            };
        }
        return {
            status: "error",
            message: "Failed to create election commission"
        };
    }

    return {
        status: "success",
        id: id,
        message: "Election commission user registered successfully"
    };
}

public function registerPollingStation(PollingStationRegistrationRequest request) returns json|error {
    // Validate password policy
    string? passwordError = validatePasswordPolicy(request.station.passwordHash);
    if passwordError is string {
        return {
            status: "error",
            message: passwordError
        };
    }

    // Check if username (NIC) already exists
    boolean|error usernameExists = isUsernameExists(request.station.nic);
    if usernameExists is error {
        log:printError("Failed to check username existence: " + usernameExists.message());
        return {
            status: "error",
            message: "Failed to validate user information"
        };
    }
    
    if usernameExists {
        return {
            status: "error",
            message: "User with this NIC already exists"
        };
    }

    string id = common:generateId();

    string|error hashedPassword = hashPassword(request.station.passwordHash);
    if hashedPassword is error {
        log:printError("Failed to hash password: " + hashedPassword.message());
        return {
            status: "error",
            message: "Failed to process password"
        };
    }

    store:AdminUsersInsert insertRec = {
        id: id,
        username: request.station.nic,  // use NIC as username for login
        passwordHash: hashedPassword,
        role: "polling_station",
        createdAt: time:utcNow(),
        isActive: true,
        division: request.station.division // optional division field
    };

    string[]|error resp = dbClient->/adminusers.post([insertRec]);
    if resp is error {
        log:printError("Failed to create polling station: " + resp.message());
        // Check if it's a unique constraint violation (in case DB has unique constraint)
        if resp.message().includes("unique") || resp.message().includes("duplicate") {
            return {
                status: "error",
                message: "User with this NIC already exists"
            };
        }
        return {
            status: "error",
            message: "Failed to create polling station"
        };
    }

    return {
        status: "success",
        id: id,
        message: "Polling Station user registered successfully"
    };
}

public function getAdmins() returns store:AdminUsers[]|error {
    stream<store:AdminUsers, persist:Error?> adminUsersStream = dbClient->/adminusers;
    return check from store:AdminUsers admin in adminUsersStream
        select admin;
}
