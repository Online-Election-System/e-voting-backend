import online_election.common;
import online_election.store;

import ballerina/log;
import ballerina/time;

public function registerGovernmentOfficial(GovernmentOfficialRegistrationRequest request) returns json|error {
    // Validate password policy
    string? passwordError = validatePasswordPolicy(request.official.passwordHash);
    if passwordError is string {
        return {
            status: "error",
            message: passwordError
        };
    }

    string id = common:generateId();

    string|error hashedPassword = hashPassword(request.official.passwordHash);
    if hashedPassword is error {
        log:printError("Failed to hash password: " + hashedPassword.message());
        return error("Failed to hash password");
    }

    store:AdminUsersInsert insertRec = {
        id: id,
        username: request.official.nic,  // use NIC as username for login
        passwordHash: hashedPassword,
        role: "government_official",
        createdAt: time:utcNow(),
        isActive: true
    };

    string[]|error resp = dbClient->/adminusers.post([insertRec]);
    if resp is error {
        log:printError("Failed to create government official: " + resp.message());
        return error("Failed to create government official");
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

    string id = common:generateId();

    string|error hashedPassword = hashPassword(request.commission.passwordHash);
    if hashedPassword is error {
        log:printError("Failed to hash password: " + hashedPassword.message());
        return error("Failed to hash password");
    }

    store:AdminUsersInsert insertRec = {
        id: id,
        username: request.commission.nic,  // use NIC as username for login
        passwordHash: hashedPassword,
        role: "election_commission",
        createdAt: time:utcNow(),
        isActive: true
    };

    string[]|error resp = dbClient->/adminusers.post([insertRec]);
    if resp is error {
        log:printError("Failed to create election commission: " + resp.message());
        return error("Failed to create election commission");
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

    string id = common:generateId();

    string|error hashedPassword = hashPassword(request.station.passwordHash);
    if hashedPassword is error {
        log:printError("Failed to hash password: " + hashedPassword.message());
        return error("Failed to hash password");
    }

    store:AdminUsersInsert insertRec = {
        id: id,
        username: request.station.nic,  // use NIC as username for login
        passwordHash: hashedPassword,
        role: "polling_station",
        createdAt: time:utcNow(),
        isActive: true
    };

    string[]|error resp = dbClient->/adminusers.post([insertRec]);
    if resp is error {
        log:printError("Failed to create polling station: " + resp.message());
        return error("Failed to create polling station");
    }

    return {
        status: "success",
        id: id,
        message: "Polling Station user registered successfully"
    };
}