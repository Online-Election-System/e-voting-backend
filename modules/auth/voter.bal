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
        idCopyPath: null,
        role: "chief_occupant"
    };

    log:printInfo("Creating chief occupant with ID: " + chiefOccupantId);
    string[]|error chiefResponse = dbClient->/chiefoccupants.post([chiefOccupantInsert]);
    if chiefResponse is error {
        log:printError("Failed to create chief occupant: " + chiefResponse.message());
        return error("Failed to create chief occupant: " + chiefResponse.message());
    }
    log:printInfo("Chief occupant created successfully");

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
    foreach var member in request.newHouseholdMembers.members {
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
            idCopyPath: null, // Temporarily set to null
            passwordHash: memberHashedPassword,
            passwordchanged: false,
            role: "household_member"
        };

        log:printInfo("Creating household member with ID: " + memberId);
        string[]|error memberResp = dbClient->/householdmembers.post([memberInsert]);
        if memberResp is error {
            log:printError("Failed to create household member: " + memberResp.message());
            return error("Failed to create household member: " + memberResp.message());
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
    // ChiefOccupant login
    stream<store:ChiefOccupant, persist:Error?> chiefStream = dbClient->/chiefoccupants.get();
    boolean chiefFound = false;

    check from store:ChiefOccupant chief in chiefStream
        where chief.nic == loginReq.nic
        do {
            chiefFound = true;
            io:println("Chief found: ", chief.fullName);

            boolean|error isVerified = verifyPassword(loginReq.password, chief.passwordHash);
            io:println("Password verification result: ", isVerified);

            if isVerified is error || !isVerified {
                check chiefStream.close();
                return http:UNAUTHORIZED;
            }

            // Use new JWT generation with ID tracking
            io:println("About to generate JWT for chief ID: ", chief.id);
            string|error token = generateJwtWithId(chief.id.toString(), CHIEF_OCCUPANT);

            if token is error {
                io:println("JWT generation failed: ", token);
                check chiefStream.close();
                return http:UNAUTHORIZED;
            }

            io:println("JWT generated successfully");
            io:println("Returning successful response");

            check chiefStream.close();
            return {
                userId: chief.id,
                userType: "chief_occupant",
                fullName: chief.fullName,
                message: "Login successful",
                token: token
            };
        };
    check chiefStream.close();
    if !chiefFound {
        io:println("No chief found with NIC: ", loginReq.nic);
    }

    // Household members login
    stream<store:HouseholdMembers, persist:Error?> memberStream = dbClient->/householdmembers.get();
    check from store:HouseholdMembers member in memberStream
        where member.nic == loginReq.nic
        do {
            check memberStream.close();

            boolean|error isVerified = verifyPassword(loginReq.password, member.passwordHash);
            if isVerified is error || !isVerified {
                return http:UNAUTHORIZED;
            }

            string|error token = generateJwtWithId(member.id.toString(), HOUSEHOLD_MEMBER);
            if token is error {
                return http:UNAUTHORIZED;
            }
            return {
                userId: member.id,
                userType: "household_member",
                fullName: member.fullName,
                message: member.passwordchanged ? "Login successful" : "First-time login. Please change your password.",
                token: token
            };
        };
    check memberStream.close();

    // Government officials & election commission login (AdminUsers table)
    stream<store:AdminUsers, persist:Error?> adminStream = dbClient->/adminusers.get();
    check from store:AdminUsers admin in adminStream
        where admin.username == loginReq.nic
        do {
            check adminStream.close();
            boolean|error isVerified = verifyPassword(loginReq.password, admin.passwordHash);
            if isVerified is error || !isVerified {
                return http:UNAUTHORIZED;
            }

            // Map admin role to UserRole enum
            UserRole role;
            if admin.role == "government_official" {
                role = GOVERNMENT_OFFICIAL;
            } else if admin.role == "election_commission" {
                role = ELECTION_COMMISSION;
            } else if admin.role == "admin" {
                role = ADMIN;
            } else {
                return http:UNAUTHORIZED; // Unknown role
            }

            string|error token = generateJwtWithId(admin.id.toString(), role);
            if token is error {
                return http:UNAUTHORIZED;
            }
            return {
                userId: admin.id,
                userType: admin.role,
                fullName: admin.username,
                message: "Login successful",
                token: token
            };
        };
    check adminStream.close();

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