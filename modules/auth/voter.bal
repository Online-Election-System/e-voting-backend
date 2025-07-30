import online_election.common;
import online_election.store;

import ballerina/email;
import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/persist;

public final store:Client dbClient = check new ();
email:SmtpClient smtpClient = check new (
    "smtp.gmail.com",
    "rashminkavindya2@gmail.com",
    "ktax nqmc qcre myfq"
);

public function postRegistration(VoterRegistrationRequest request) returns json|http:Forbidden|error {
    log:printInfo("Processing registration request");
    log:printInfo("Password received: " + request.chiefOccupant.passwordHash);

    // DEBUG: Log the received idCopyPath values
    log:printInfo("=== DEBUG: Received idCopyPath values ===");
    log:printInfo("Chief idCopyPath: " + (request.chiefOccupant.idCopyPath ?: "NULL"));

    log:printInfo("Number of household members: " + request.newHouseholdMembers.members.length().toString());
    foreach int i in 0 ..< request.newHouseholdMembers.members.length() {
        var member = request.newHouseholdMembers.members[i];
        log:printInfo(string `Member ${i}: ${member.fullName}, idCopyPath: ${member.idCopyPath ?: "NULL"}`);
    }

    // Print the entire request for debugging
    io:println("=== FULL REQUEST DEBUG ===");
    io:println(request);
    io:println("=== END REQUEST DEBUG ===");

    // Validate password policy
    string? passwordError = validatePasswordPolicy(request.chiefOccupant.passwordHash);
    if passwordError is string {
        return {
            statusCode: 400,
            body: {
                "status": "error",
                "code": "INVALID_PASSWORD",
                "message": passwordError,
                "requirements": {
                    "minLength": 8,
                    "requiresUppercase": true,
                    "requiresLowercase": true,
                    "requiresNumber": true,
                    "requiresSpecialChar": true,
                    "specialCharsAllowed": "@$!%*?&"
                }
            }
        };
    }

    string chiefOccupantId = common:generateId();

    // Hash the password securely
    string|error hashedPassword = hashPassword(request.chiefOccupant.passwordHash);
    if hashedPassword is error {
        log:printError("Failed to hash password: " + hashedPassword.message());
        return error("Failed to hash password: " + hashedPassword.message());
    }

    // Create chief occupant record
    store:ChiefOccupantInsert chiefOccupantInsert = {
        id: chiefOccupantId,
        fullName: request.chiefOccupant.fullName,
        nic: request.chiefOccupant.nic,
        phoneNumber: request.chiefOccupant.phoneNumber,
        dob: request.chiefOccupant.dob,
        gender: request.chiefOccupant.gender,
        civilStatus: request.chiefOccupant.civilStatus,
        passwordHash: hashedPassword,
        email: request.chiefOccupant.email,
        idCopyPath: request.chiefOccupant.idCopyPath,
        photoCopyPath: request.chiefOccupant.phophotoCopyPath,
        role: "chief_occupant"
    ,photoCopyPath: ()};

    // DEBUG: Log what we're inserting
    log:printInfo("=== DEBUG: Inserting chief occupant ===");
    log:printInfo("Chief ID: " + chiefOccupantId);
    log:printInfo("Chief idCopyPath being inserted: " + (chiefOccupantInsert.idCopyPath ?: "NULL"));

    log:printInfo("Creating chief occupant with ID: " + chiefOccupantId);
    string[]|error chiefResponse = dbClient->/chiefoccupants.post([chiefOccupantInsert]);
    if chiefResponse is error {
        log:printError("Failed to create chief occupant: " + chiefResponse.message());
        return error("Failed to create chief occupant: " + chiefResponse.message());
    }
    log:printInfo("Chief occupant created successfully");

    // Verify what was actually inserted into the database
    store:ChiefOccupant|persist:Error verifyChief = dbClient->/chiefoccupants/[chiefOccupantId].get();
    if verifyChief is store:ChiefOccupant {
        log:printInfo("=== DEBUG: Verification - Chief in DB ===");
        log:printInfo("Verified chief idCopyPath from DB: " + (verifyChief.idCopyPath ?: "NULL"));
    }
    // Send welcome email
    error? emailError = sendWelcomeEmail(request.chiefOccupant.email, request.chiefOccupant.fullName, request.chiefOccupant.passwordHash);
    if emailError is error {
        log:printError("Failed to send welcome email: " + emailError.message());
        // Don't fail the registration for email issues
    }

    // Create household details
    string householdId = common:generateId();
    store:HouseholdDetailsInsert householdInsert = {
        id: householdId,
        chiefOccupantId: chiefOccupantId,
        electoralDistrict: request.householdDetails.electoralDistrict,
        pollingDivision: request.householdDetails.pollingDivision,
        pollingDistrictNumber: request.householdDetails.pollingDistrictNumber,
        gramaNiladhariDivision: request.householdDetails.gramaNiladhariDivision,
        villageStreetEstate: request.householdDetails.villageStreetEstate,
        houseNumber: request.householdDetails.houseNumber,
        householdMemberCount: request.householdDetails.householdMemberCount
    };

    log:printInfo("Creating household details with ID: " + householdId);
    string[]|error householdResponse = dbClient->/householddetails.post([householdInsert]);
    if householdResponse is error {
        log:printError("Failed to create household: " + householdResponse.message());
        return error("Failed to create household: " + householdResponse.message());
    }
    log:printInfo("Household details created successfully");

    // Create household members
    int memberCount = request.newHouseholdMembers.members.length();
    if memberCount != request.householdDetails.householdMemberCount {
        return error("Mismatch between specified and provided household member count.");
    }

    string[] passwordList = [];
    foreach int i in 0 ..< request.newHouseholdMembers.members.length() {
        var member = request.newHouseholdMembers.members[i];

        string|error plainPassword = generatePassword();
        if plainPassword is error {
            log:printError("Failed to generate member password: " + plainPassword.message());
            return error("Failed to generate member password");
        }

        string|error memberHashedPassword = hashPassword(plainPassword);
        if memberHashedPassword is error {
            log:printError("Failed to hash member password: " + memberHashedPassword.message());
            return error("Failed to hash member password");
        }

        string memberId = common:generateId();
        store:HouseholdMembersInsert memberInsert = {
            id: memberId,
            chiefOccupantId: chiefOccupantId,
            fullName: member.fullName,
            nic: member.nic,
            relationshipWithChiefOccupant: member.relationshipWithChiefOccupant,
            dob: member.dob,
            gender: member.gender,
            approvedByChief: member.approvedByChief,
            civilStatus: member.civilStatus,
            idCopyPath: member.idCopyPath,
            photoCopyPath: member.phophotoCopyPath,
            passwordHash: memberHashedPassword,
            passwordchanged: false,
            role: "household_member"
        ,photoCopyPath: ()};

        // DEBUG: Log what we're inserting for each member
        log:printInfo(string `=== DEBUG: Inserting member ${i} ===`);
        log:printInfo("Member ID: " + memberId);
        log:printInfo("Member name: " + member.fullName);
        log:printInfo("Member idCopyPath being inserted: " + (memberInsert.idCopyPath ?: "NULL"));

        log:printInfo("Creating household member with ID: " + memberId);
        string[]|error memberResp = dbClient->/householdmembers.post([memberInsert]);
        if memberResp is error {
            log:printError("Failed to create household member: " + memberResp.message());
            return error("Failed to create household member: " + memberResp.message());
        }

        // Verify what was actually inserted for this member
        store:HouseholdMembers|persist:Error verifyMember = dbClient->/householdmembers/[memberId].get();
        if verifyMember is store:HouseholdMembers {
            log:printInfo(string `=== DEBUG: Verification - Member ${i} in DB ===`);
            log:printInfo("Verified member idCopyPath from DB: " + (verifyMember.idCopyPath ?: "NULL"));
        }

        string nic = member.nic ?: "N/A";
        passwordList.push(string `${member.fullName} (${nic}): ${plainPassword}`);
    }
    log:printInfo("All household members created successfully");

    // Send household passwords to chief
    store:ChiefOccupant|persist:Error chief = dbClient->/chiefoccupants/[chiefOccupantId].get();
    if chief is store:ChiefOccupant {
        error? passwordEmailError = sendHouseholdPasswordsToChief(smtpClient, chief.email, chief.fullName, passwordList);
        if passwordEmailError is error {
            log:printError("Failed to send household passwords email: " + passwordEmailError.message());
            // Don't fail the registration for email issues
        }
    }
    log:printInfo("Registration completed successfully");
    return {
        status: "success",
        message: "Registration completed successfully",
        chiefOccupantId: chiefOccupantId,
        householdId: householdId
    };
}

public function postLogin(LoginRequest loginReq) returns LoginResponse|http:Unauthorized|error {
    log:printInfo("=== LOGIN DEBUG START ===");
    log:printInfo("Attempting login for NIC: " + loginReq.nic);
    log:printInfo("Password length: " + loginReq.password.length().toString());

    // ChiefOccupant login
    log:printInfo("Checking ChiefOccupants table...");
    stream<store:ChiefOccupant, persist:Error?> chiefStream = dbClient->/chiefoccupants.get();
    boolean chiefFound = false;
    int chiefCount = 0;

    check from store:ChiefOccupant chief in chiefStream
        do {
            chiefFound = true;
            io:println("Chief found: ", chief.fullName);
            io:println("Chief role: ", chief.role);
            chiefCount += 1;
            log:printInfo("Checking chief #" + chiefCount.toString() + ": " + chief.nic + " vs " + loginReq.nic);

            if chief.nic == loginReq.nic {
                chiefFound = true;
                log:printInfo("Chief found: " + chief.fullName);
                log:printInfo("Stored password hash: " + chief.passwordHash);

                boolean|error isVerified = verifyPassword(loginReq.password, chief.passwordHash);
                log:printInfo("Password verification result: " + (check isVerified).toString());

                if isVerified is error {
                    log:printError("Password verification error: " + isVerified.message());
                    check chiefStream.close();
                    return http:UNAUTHORIZED;
                }

                if !isVerified {
                    log:printInfo("Password verification failed - passwords don't match");
                    check chiefStream.close();
                    return http:UNAUTHORIZED;
                }

                // MOVED: Check role and only allow verified chief occupants or regular chief occupants
                string userRole;
                UserRole jwtRole;

                if chief.role == "verified_chief_occupant" {
                    userRole = "verified_chief_occupant";
                    jwtRole = VERIFIED_CHIEF_OCCUPANT;
                    io:println("Verified chief occupant login approved");
                } else if chief.role == "chief_occupant" {
                    userRole = "chief_occupant";
                    jwtRole = CHIEF_OCCUPANT;
                    io:println("Regular chief occupant login approved");
                } else {
                    // Reject login if role is not recognized
                    io:println("Unrecognized chief occupant role: ", chief.role);
                    check chiefStream.close();
                    return http:UNAUTHORIZED;
                }

                // Use new JWT generation with ID tracking
                io:println("About to generate JWT for chief ID: ", chief.id);
                string|error token = generateJwtWithId(chief.id.toString(), jwtRole);

                if token is error {
                    io:println("JWT generation failed: ", token);
                    check chiefStream.close();
                    return http:UNAUTHORIZED;
                }

                io:println("JWT generated successfully");
                io:println("Returning successful response");

                check chiefStream.close();

                // Response with cookie
                LoginResponse response = {
                    userId: chief.id,
                    userType: userRole,
                    fullName: chief.fullName,
                    message: "Login successful"
                };

                return response;
            }
            // If NIC doesn't match, continue to next iteration without processing
        };
    check chiefStream.close();

    log:printInfo("Total chiefs checked: " + chiefCount.toString());
    if !chiefFound {
        log:printInfo("No chief found with NIC: " + loginReq.nic);
    }

    // Household members login
    log:printInfo("Checking HouseholdMembers table...");
    stream<store:HouseholdMembers, persist:Error?> memberStream = dbClient->/householdmembers.get();
    int memberCount = 0;
    boolean memberFound = false;

    check from store:HouseholdMembers member in memberStream
        do {
            memberCount += 1;

            if member.nic == loginReq.nic {
                memberFound = true;
                io:println("Household member found: ", member.fullName);
                io:println("Member role: ", member.role);
                io:println("Member ID: ", member.id);

                io:println("About to verify password for member");
                boolean|error isVerified = verifyPassword(loginReq.password, member.passwordHash);
                io:println("Password verification result for member: ", isVerified);

                if isVerified is error {
                    io:println("Password verification error: ", isVerified.message());
                    check memberStream.close();
                    return http:UNAUTHORIZED;
                }

                if !isVerified {
                    io:println("Password verification failed - incorrect password");
                    check memberStream.close();
                    return http:UNAUTHORIZED;
                }

                // Check role and only allow verified household members or regular household members
                string userRole;
                UserRole jwtRole;

                if member.role == "verified_household_member" {
                    userRole = "verified_household_member";
                    jwtRole = VERIFIED_HOUSEHOLD_MEMBER;
                    io:println("Verified household member login approved");
                } else if member.role == "household_member" {
                    userRole = "household_member";
                    jwtRole = HOUSEHOLD_MEMBER;
                    io:println("Regular household member login approved");
                } else {
                    // Reject login if role is not recognized
                    io:println("Unrecognized household member role: ", member.role);
                    check memberStream.close();
                    return http:UNAUTHORIZED;
                }

                io:println("About to generate JWT for member ID: ", member.id);
                string|error token = generateJwtWithId(member.id.toString(), jwtRole);
                if token is error {
                    io:println("JWT generation failed for member: ", token.message());
                    check memberStream.close();
                    return http:UNAUTHORIZED;
                }

                io:println("JWT generated successfully for member");
                io:println("Returning successful login response for member");

                check memberStream.close();

                // Response with cookie
                LoginResponse response = {
                    userId: member.id,
                    userType: userRole,
                    fullName: member.fullName,
                    message: member.passwordchanged ? "Login successful" : "First-time login. Please change your password."
                };

                return response;
            }
            // If NIC doesn't match, continue to next iteration
        };
    check memberStream.close();

    if !memberFound {
        io:println("No household member found with NIC: ", loginReq.nic); // ADDED: Log when no member found
    }

    log:printInfo("Total members checked: " + memberCount.toString());
    if !memberFound {
        log:printInfo("No member found with NIC: " + loginReq.nic);
    }

    // Government officials & election commission login (AdminUsers table)
    log:printInfo("Checking AdminUsers table...");
    stream<store:AdminUsers, persist:Error?> adminStream = dbClient->/adminusers.get();
    int adminCount = 0;
    boolean adminFound = false;

    check from store:AdminUsers admin in adminStream
        do {
            adminCount += 1;
            log:printInfo("Checking admin #" + adminCount.toString() + ": " + admin.username + " vs " + loginReq.nic);

            if admin.username == loginReq.nic {
                adminFound = true;
                log:printInfo("Admin found: " + admin.username);
                log:printInfo("Stored password hash: " + admin.passwordHash);

                boolean|error isVerified = verifyPassword(loginReq.password, admin.passwordHash);
                log:printInfo("Password verification result: " + (check isVerified).toString());

                if isVerified is error {
                    log:printError("Password verification error: " + isVerified.message());
                    check adminStream.close();
                    return http:UNAUTHORIZED;
                }

                if !isVerified {
                    log:printInfo("Password verification failed - passwords don't match");
                    check adminStream.close();
                    return http:UNAUTHORIZED;
                }

                UserRole role;
                if admin.role == "government_official" {
                    role = GOVERNMENT_OFFICIAL;
                } else if admin.role == "election_commission" {
                    role = ELECTION_COMMISSION;
                } else if admin.role == "polling_station" {
                    role = POLLING_STATION;
                } else if admin.role == "admin" {
                    role = ADMIN;
                } else {
                    log:printError("Unknown admin role: " + admin.role);
                    check adminStream.close();
                    return http:UNAUTHORIZED;
                }

                string|error token = generateJwtWithId(admin.id.toString(), role);
                if token is error {
                    log:printError("JWT generation failed: " + token.message());
                    check adminStream.close();
                    return http:UNAUTHORIZED;
                }

                check adminStream.close();
                log:printInfo("Admin login successful");

                // Response with cookie
                LoginResponse response = {
                    userId: admin.id,
                    userType: admin.role,
                    fullName: admin.username,
                    message: "Login successful"
                };

                return response;
            }
        };
    check adminStream.close();

    log:printInfo("Total admins checked: " + adminCount.toString());
    if !adminFound {
        log:printInfo("No admin found with username: " + loginReq.nic);
    }

    log:printInfo("=== LOGIN DEBUG END - NO USER FOUND ===");
    return http:UNAUTHORIZED;
}

public function putChangePassword(ChangePasswordRequest req) returns http:Ok|http:Unauthorized|json|error {
    // Validate new password
    string? passwordError = validatePasswordPolicy(req.newPassword);
    if passwordError is string {
        return {
            statusCode: 400,
            body: {
                "status": "error",
                "code": "INVALID_PASSWORD",
                "message": passwordError,
                "requirements": {
                    "minLength": 8,
                    "requiresUppercase": true,
                    "requiresLowercase": true,
                    "requiresNumber": true,
                    "requiresSpecialChar": true,
                    "specialCharsAllowed": "@$!%*?&"
                }
            }
        };
    }

    // Hash the new password
    string|error newHashed = hashPassword(req.newPassword);
    if newHashed is error {
        return error("Failed to hash new password");
    }

    if req.userType == "chief" {
        store:ChiefOccupant chief = check dbClient->/chiefoccupants/[req.userId].get();

        // Verify old password
        boolean|error isVerified = verifyPassword(req.oldPassword, chief.passwordHash);
        if isVerified is error || !isVerified {
            return http:UNAUTHORIZED;
        }

        store:ChiefOccupantUpdate chiefUpdate = {
            passwordHash: newHashed
        };
        _ = check dbClient->/chiefoccupants/[req.userId].put(chiefUpdate);
    } else if req.userType == "household_member" {
        store:HouseholdMembers member = check dbClient->/householdmembers/[req.userId].get();

        boolean|error isVerified = verifyPassword(req.oldPassword, member.passwordHash);
        if isVerified is error || !isVerified {
            return http:UNAUTHORIZED;
        }

        store:HouseholdMembersUpdate memberUpdate = {
            passwordHash: newHashed,
            passwordchanged: true
        };
        _ = check dbClient->/householdmembers/[req.userId].put(memberUpdate);
    } else {
        return http:UNAUTHORIZED;
    }

    return http:OK;
}

public function postResetPassword(PasswordResetRequest req) returns http:Ok|http:Unauthorized|json|error {
    // Validate new password
    string? passwordError = validatePasswordPolicy(req.newPassword);
    if passwordError is string {
        return {
            statusCode: 400,
            body: {
                "status": "error",
                "code": "INVALID_PASSWORD",
                "message": passwordError,
                "requirements": {
                    "minLength": 8,
                    "requiresUppercase": true,
                    "requiresLowercase": true,
                    "requiresNumber": true,
                    "requiresSpecialChar": true,
                    "specialCharsAllowed": "@$!%*?&"
                }
            }
        };
    }

    // Hash the new password
    string|error newHashed = hashPassword(req.newPassword);
    if newHashed is error {
        return error("Failed to hash new password");
    }

    // Find user by email (implementation depends on your schema)
    // Then update their password similar to changePassword function

    return http:OK;

}
