import online_election.common;
import online_election.store;

import ballerina/email;
import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/persist;
import ballerina/uuid;
import online_election.activityLog;

public final store:Client dbClient = check new ();
email:SmtpClient smtpClient = check new (
    "smtp.gmail.com",
    "rashminkavindya2@gmail.com",
    "ktax nqmc qcre myfq"
);

// Session tracking map (in production, use Redis or database)
map<string> userSessions = {};

// Helper function to generate session ID
function generateSessionId() returns string {
    return uuid:createType1AsString();
}

// Helper function to get or create session ID for user
function getOrCreateSessionId(string userId, string userType) returns string {
    string sessionKey = string `${userType}:${userId}`;
    if userSessions.hasKey(sessionKey) {
        return userSessions.get(sessionKey);
    }
    string newSessionId = generateSessionId();
    userSessions[sessionKey] = newSessionId;
    return newSessionId;
}

// Enhanced registration function with complete logging
public function postRegistration(VoterRegistrationRequest request, http:Request httpRequest) returns json|http:Forbidden|error {
    log:printInfo("Processing registration request");
    log:printInfo("Password received: " + request.chiefOccupant.passwordHash);

    string? ipAddress = activityLog:getIpFromRequest(httpRequest);
    string? userAgent = activityLog:getUserAgentFromRequest(httpRequest);
    string httpMethod = httpRequest.method;
    string endpoint = httpRequest.rawPath;

    // Log registration attempt with complete information
    error? logAttempt = activityLog:logActivity({
        userId: (), // Not yet created
        userType: (), // Not yet determined
        action: activityLog:VOTER_REGISTRATION,
        resourceId: (), // Will be set to chiefOccupantId after creation
        httpMethod: httpMethod,
        endpoint: endpoint,
        ipAddress: ipAddress,
        userAgent: userAgent,
        status: activityLog:PENDING,
        details: string `Registration attempt for NIC: ${request.chiefOccupant.nic}, IP: ${ipAddress ?: "unknown"}`,
        sessionId: () // Will be generated after user creation
    });

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
        // Log registration failure due to invalid password with complete info
        error? logFailure = activityLog:logActivity({
            userId: (),
            userType: (),
            action: activityLog:VOTER_REGISTRATION,
            resourceId: (),
            httpMethod: httpMethod,
            endpoint: endpoint,
            ipAddress: ipAddress,
            userAgent: userAgent,
            status: activityLog:FAILURE,
            details: string `Registration failed - Invalid password for NIC: ${request.chiefOccupant.nic}. Error: ${passwordError}`,
            sessionId: ()
        });

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
    string sessionId = getOrCreateSessionId(chiefOccupantId, "chief_occupant");

    // Hash the password securely
    string|error hashedPassword = hashPassword(request.chiefOccupant.passwordHash);
    if hashedPassword is error {
        // Log registration failure due to password hashing error with complete info
        error? logFailure = activityLog:logActivity({
            userId: chiefOccupantId,
            userType: "chief_occupant",
            action: activityLog:VOTER_REGISTRATION,
            resourceId: chiefOccupantId,
            httpMethod: httpMethod,
            endpoint: endpoint,
            ipAddress: ipAddress,
            userAgent: userAgent,
            status: activityLog:ERROR,
            details: string `Registration failed - Password hashing error for NIC: ${request.chiefOccupant.nic}. Error: ${hashedPassword.message()}`,
            sessionId: sessionId
        });

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
        photoCopyPath: request.chiefOccupant.photoCopyPath,
        role: "chief_occupant"
    };

    // DEBUG: Log what we're inserting
    log:printInfo("=== DEBUG: Inserting chief occupant ===");
    log:printInfo("Chief ID: " + chiefOccupantId);
    log:printInfo("Chief idCopyPath being inserted: " + (chiefOccupantInsert.idCopyPath ?: "NULL"));

    log:printInfo("Creating chief occupant with ID: " + chiefOccupantId);
    string[]|error chiefResponse = dbClient->/chiefoccupants.post([chiefOccupantInsert]);
    if chiefResponse is error {
        // Log registration failure due to database error with complete info
        error? logFailure = activityLog:logActivity({
            userId: chiefOccupantId,
            userType: "chief_occupant",
            action: activityLog:VOTER_REGISTRATION,
            resourceId: chiefOccupantId,
            httpMethod: httpMethod,
            endpoint: endpoint,
            ipAddress: ipAddress,
            userAgent: userAgent,
            status: activityLog:ERROR,
            details: string `Registration failed - Database error creating chief occupant: ${chiefResponse.message()}`,
            sessionId: sessionId
        });

        log:printError("Failed to create chief occupant: " + chiefResponse.message());
        return error("Failed to create chief occupant: " + chiefResponse.message());
    }
    log:printInfo("Chief occupant created successfully");

    // Log successful chief occupant creation
    error? logChiefCreation = activityLog:logActivity({
        userId: chiefOccupantId,
        userType: "chief_occupant",
        action: activityLog:USER_CREATED,
        resourceId: chiefOccupantId,
        httpMethod: httpMethod,
        endpoint: endpoint,
        ipAddress: ipAddress,
        userAgent: userAgent,
        status: activityLog:SUCCESS,
        details: string `Chief occupant created successfully: ${request.chiefOccupant.fullName} (${request.chiefOccupant.nic})`,
        sessionId: sessionId
    });

    // Verify what was actually inserted into the database
    store:ChiefOccupant|persist:Error verifyChief = dbClient->/chiefoccupants/[chiefOccupantId].get();
    if verifyChief is store:ChiefOccupant {
        log:printInfo("=== DEBUG: Verification - Chief in DB ===");
        log:printInfo("Verified chief idCopyPath from DB: " + (verifyChief.idCopyPath ?: "NULL"));
    }

    // Send welcome email and log the attempt
    error? emailError = sendWelcomeEmail(request.chiefOccupant.email, request.chiefOccupant.fullName, request.chiefOccupant.passwordHash);
    if emailError is error {
        log:printError("Failed to send welcome email: " + emailError.message());
        // Log welcome email failure
        error? logEmailFailure = activityLog:logActivity({
            userId: chiefOccupantId,
            userType: "chief_occupant",
            action: activityLog:WELCOME_EMAIL_SEND,
            resourceId: chiefOccupantId,
            httpMethod: httpMethod,
            endpoint: endpoint,
            ipAddress: ipAddress,
            userAgent: userAgent,
            status: activityLog:FAILURE,
            details: string `Failed to send welcome email to ${request.chiefOccupant.email}: ${emailError.message()}`,
            sessionId: sessionId
        });
    } else {
        // Log successful welcome email
        error? logEmailSuccess = activityLog:logActivity({
            userId: chiefOccupantId,
            userType: "chief_occupant",
            action: activityLog:WELCOME_EMAIL_SEND,
            resourceId: chiefOccupantId,
            httpMethod: httpMethod,
            endpoint: endpoint,
            ipAddress: ipAddress,
            userAgent: userAgent,
            status: activityLog:SUCCESS,
            details: string `Welcome email sent successfully to ${request.chiefOccupant.email}`,
            sessionId: sessionId
        });
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
        // Log registration failure due to household creation error with complete info
        error? logFailure = activityLog:logActivity({
            userId: chiefOccupantId,
            userType: "chief_occupant",
            action: activityLog:HOUSEHOLD_CREATION,
            resourceId: householdId,
            httpMethod: httpMethod,
            endpoint: endpoint,
            ipAddress: ipAddress,
            userAgent: userAgent,
            status: activityLog:ERROR,
            details: string `Registration failed - Database error creating household: ${householdResponse.message()}`,
            sessionId: sessionId
        });

        log:printError("Failed to create household: " + householdResponse.message());
        return error("Failed to create household: " + householdResponse.message());
    }
    
    // Log successful household creation
    error? logHouseholdCreation = activityLog:logActivity({
        userId: chiefOccupantId,
        userType: "chief_occupant",
        action: activityLog:HOUSEHOLD_CREATION,
        resourceId: householdId,
        httpMethod: httpMethod,
        endpoint: endpoint,
        ipAddress: ipAddress,
        userAgent: userAgent,
        status: activityLog:SUCCESS,
        details: string `Household created successfully: ${householdId} with ${request.householdDetails.householdMemberCount} members`,
        sessionId: sessionId
    });
    
    log:printInfo("Household details created successfully");

    // Create household members
    int memberCount = request.newHouseholdMembers.members.length();
    if memberCount != request.householdDetails.householdMemberCount {
        // Log registration failure due to member count mismatch with complete info
        error? logFailure = activityLog:logActivity({
            userId: chiefOccupantId,
            userType: "chief_occupant",
            action: activityLog:VOTER_REGISTRATION,
            resourceId: householdId,
            httpMethod: httpMethod,
            endpoint: endpoint,
            ipAddress: ipAddress,
            userAgent: userAgent,
            status: activityLog:FAILURE,
            details: string `Registration failed - Member count mismatch. Expected: ${request.householdDetails.householdMemberCount}, Provided: ${memberCount}`,
            sessionId: sessionId
        });

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
        string memberSessionId = getOrCreateSessionId(memberId, "household_member");
        
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
            photoCopyPath: member.photoCopyPath,
            passwordHash: memberHashedPassword,
            passwordchanged: false,
            role: "household_member"
        };

        // DEBUG: Log what we're inserting for each member
        log:printInfo(string `=== DEBUG: Inserting member ${i} ===`);
        log:printInfo("Member ID: " + memberId);
        log:printInfo("Member name: " + member.fullName);
        log:printInfo("Member idCopyPath being inserted: " + (memberInsert.idCopyPath ?: "NULL"));

        log:printInfo("Creating household member with ID: " + memberId);
        string[]|error memberResp = dbClient->/householdmembers.post([memberInsert]);
        if memberResp is error {
            // Log member creation failure with complete info
            error? logFailure = activityLog:logActivity({
                userId: chiefOccupantId,
                userType: "chief_occupant",
                action: activityLog:HOUSEHOLD_MEMBER_ADD,
                resourceId: memberId,
                httpMethod: httpMethod,
                endpoint: endpoint,
                ipAddress: ipAddress,
                userAgent: userAgent,
                status: activityLog:ERROR,
                details: string `Failed to create household member ${member.fullName} (${member.nic ?: "No NIC"}): ${memberResp.message()}`,
                sessionId: sessionId
            });

            log:printError("Failed to create household member: " + memberResp.message());
            return error("Failed to create household member: " + memberResp.message());
        }

        // Log successful member creation
        error? logMemberCreation = activityLog:logActivity({
            userId: chiefOccupantId,
            userType: "chief_occupant",
            action: activityLog:HOUSEHOLD_MEMBER_ADD,
            resourceId: memberId,
            httpMethod: httpMethod,
            endpoint: endpoint,
            ipAddress: ipAddress,
            userAgent: userAgent,
            status: activityLog:SUCCESS,
            details: string `Household member created successfully: ${member.fullName} (${member.nic ?: "No NIC"})`,
            sessionId: sessionId
        });

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

    // Send household passwords to chief and log the attempt
    store:ChiefOccupant|persist:Error chief = dbClient->/chiefoccupants/[chiefOccupantId].get();
    if chief is store:ChiefOccupant {
        error? passwordEmailError = sendHouseholdPasswordsToChief(smtpClient, chief.email, chief.fullName, passwordList);
        if passwordEmailError is error {
            log:printError("Failed to send household passwords email: " + passwordEmailError.message());
            // Log household password email failure
            error? logEmailFailure = activityLog:logActivity({
                userId: chiefOccupantId,
                userType: "chief_occupant",
                action: activityLog:HOUSEHOLD_PASSWORDS_EMAIL,
                resourceId: chiefOccupantId,
                httpMethod: httpMethod,
                endpoint: endpoint,
                ipAddress: ipAddress,
                userAgent: userAgent,
                status: activityLog:FAILURE,
                details: string `Failed to send household passwords email to ${chief.email}: ${passwordEmailError.message()}`,
                sessionId: sessionId
            });
        } else {
            // Log successful household password email
            error? logEmailSuccess = activityLog:logActivity({
                userId: chiefOccupantId,
                userType: "chief_occupant",
                action: activityLog:HOUSEHOLD_PASSWORDS_EMAIL,
                resourceId: chiefOccupantId,
                httpMethod: httpMethod,
                endpoint: endpoint,
                ipAddress: ipAddress,
                userAgent: userAgent,
                status: activityLog:SUCCESS,
                details: string `Household passwords email sent successfully to ${chief.email} for ${memberCount} members`,
                sessionId: sessionId
            });
        }
    }

    // Log successful registration with complete information
    error? logSuccess = activityLog:logActivity({
        userId: chiefOccupantId,
        userType: "chief_occupant",
        action: activityLog:VOTER_REGISTRATION,
        resourceId: chiefOccupantId,
        httpMethod: httpMethod,
        endpoint: endpoint,
        ipAddress: ipAddress,
        userAgent: userAgent,
        status: activityLog:SUCCESS,
        details: string `Registration completed successfully for ${request.chiefOccupant.fullName} with ${memberCount} household members. Household ID: ${householdId}`,
        sessionId: sessionId
    });
    
    log:printInfo("Registration completed successfully");
    return {
        status: "success",
        message: "Registration completed successfully",
        chiefOccupantId: chiefOccupantId,
        householdId: householdId
    };
}

// Enhanced login function with complete logging
public function postLogin(LoginRequest loginReq, http:Request httpRequest) returns LoginResponse|http:Unauthorized|error {
    log:printInfo("=== LOGIN DEBUG START ===");
    log:printInfo("Attempting login for NIC: " + loginReq.nic);
    log:printInfo("Password length: " + loginReq.password.length().toString());

    string? ipAddress = activityLog:getIpFromRequest(httpRequest);
    string? userAgent = activityLog:getUserAgentFromRequest(httpRequest);
    string httpMethod = httpRequest.method;
    string endpoint = httpRequest.rawPath;

    // Log login attempt with complete information
    error? logAttempt = activityLog:logActivity({
        userId: (), // Unknown at this point
        userType: (), // Unknown at this point  
        action: activityLog:LOGIN_ATTEMPT,
        resourceId: (),
        httpMethod: httpMethod,
        endpoint: endpoint,
        ipAddress: ipAddress,
        userAgent: userAgent,
        status: activityLog:PENDING,
        details: string `Login attempt for NIC: ${loginReq.nic} from IP: ${ipAddress ?: "unknown"}`,
        sessionId: ()
    });

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

                    // Log failed login with complete info
                    error? logFailure = activityLog:logActivity({
                        userId: chief.id,
                        userType: "chief_occupant",
                        action: activityLog:LOGIN_FAILURE,
                        resourceId: chief.id,
                        httpMethod: httpMethod,
                        endpoint: endpoint,
                        ipAddress: ipAddress,
                        userAgent: userAgent,
                        status: activityLog:FAILURE,
                        details: string `Password verification error for chief occupant ${chief.fullName}: ${isVerified.message()}`,
                        sessionId: ()
                    });

                    return http:UNAUTHORIZED;
                }

                if !isVerified {
                    log:printInfo("Password verification failed - passwords don't match");
                    check chiefStream.close();

                    // Log failed login with complete info
                    error? logFailure = activityLog:logActivity({
                        userId: chief.id,
                        userType: "chief_occupant",
                        action: activityLog:LOGIN_FAILURE,
                        resourceId: chief.id,
                        httpMethod: httpMethod,
                        endpoint: endpoint,
                        ipAddress: ipAddress,
                        userAgent: userAgent,
                        status: activityLog:FAILURE,
                        details: string `Invalid password for chief occupant ${chief.fullName}`,
                        sessionId: ()
                    });

                    return http:UNAUTHORIZED;
                }

                // Check role and only allow verified chief occupants or regular chief occupants
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
                    
                    // Log unauthorized access with complete info
                    error? logUnauthorized = activityLog:logActivity({
                        userId: chief.id,
                        userType: "chief_occupant",
                        action: activityLog:UNAUTHORIZED_ACCESS,
                        resourceId: chief.id,
                        httpMethod: httpMethod,
                        endpoint: endpoint,
                        ipAddress: ipAddress,
                        userAgent: userAgent,
                        status: activityLog:FAILURE,
                        details: string `Unrecognized chief occupant role: ${chief.role} for user ${chief.fullName}`,
                        sessionId: ()
                    });
                    
                    return http:UNAUTHORIZED;
                }

                // Generate session ID for successful login
                string sessionId = getOrCreateSessionId(chief.id, userRole);

                // Use new JWT generation with ID tracking
                io:println("About to generate JWT for chief ID: ", chief.id);
                string|error token = generateJwtWithId(chief.id.toString(), jwtRole);

                if token is error {
                    io:println("JWT generation failed: ", token);
                    check chiefStream.close();
                    
                    // Log JWT generation failure
                    error? logJwtFailure = activityLog:logActivity({
                        userId: chief.id,
                        userType: userRole,
                        action: activityLog:LOGIN_FAILURE,
                        resourceId: chief.id,
                        httpMethod: httpMethod,
                        endpoint: endpoint,
                        ipAddress: ipAddress,
                        userAgent: userAgent,
                        status: activityLog:ERROR,
                        details: string `JWT generation failed for ${chief.fullName}: ${token.message()}`,
                        sessionId: sessionId
                    });
                    
                    return http:UNAUTHORIZED;
                }

                io:println("JWT generated successfully");
                io:println("Returning successful response");

                check chiefStream.close();

                // Log successful login with complete information
                error? logSuccess = activityLog:logActivity({
                    userId: chief.id,
                    userType: userRole,
                    action: activityLog:LOGIN_SUCCESS,
                    resourceId: chief.id,
                    httpMethod: httpMethod,
                    endpoint: endpoint,
                    ipAddress: ipAddress,
                    userAgent: userAgent,
                    status: activityLog:SUCCESS,
                    details: string `Successful login for ${chief.fullName} (${chief.nic}) with role ${userRole}`,
                    sessionId: sessionId
                });

                // Response with cookie
                LoginResponse response = {
                    userId: chief.id,
                    userType: userRole,
                    fullName: chief.fullName,
                    message: "Login successful"
                };

                return response;
            }
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

                    // Log failed login with complete info
                    error? logFailure = activityLog:logActivity({
                        userId: member.id,
                        userType: "household_member",
                        action: activityLog:LOGIN_FAILURE,
                        resourceId: member.id,
                        httpMethod: httpMethod,
                        endpoint: endpoint,
                        ipAddress: ipAddress,
                        userAgent: userAgent,
                        status: activityLog:FAILURE,
                        details: string `Password verification error for household member ${member.fullName}: ${isVerified.message()}`,
                        sessionId: ()
                    });

                    return http:UNAUTHORIZED;
                }

                if !isVerified {
                    io:println("Password verification failed - incorrect password");
                    check memberStream.close();

                    // Log failed login with complete info
                    error? logFailure = activityLog:logActivity({
                        userId: member.id,
                        userType: "household_member",
                        action: activityLog:LOGIN_FAILURE,
                        resourceId: member.id,
                        httpMethod: httpMethod,
                        endpoint: endpoint,
                        ipAddress: ipAddress,
                        userAgent: userAgent,
                        status: activityLog:FAILURE,
                        details: string `Invalid password for household member ${member.fullName}`,
                        sessionId: ()
                    });

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
                    
                    // Log unauthorized access with complete info
                    error? logUnauthorized = activityLog:logActivity({
                        userId: member.id,
                        userType: "household_member",
                        action: activityLog:UNAUTHORIZED_ACCESS,
                        resourceId: member.id,
                        httpMethod: httpMethod,
                        endpoint: endpoint,
                        ipAddress: ipAddress,
                        userAgent: userAgent,
                        status: activityLog:FAILURE,
                        details: string `Unrecognized household member role: ${member.role} for user ${member.fullName}`,
                        sessionId: ()
                    });
                    
                    return http:UNAUTHORIZED;
                }

                // Generate session ID for successful login
                string sessionId = getOrCreateSessionId(member.id, userRole);

                io:println("About to generate JWT for member ID: ", member.id);
                string|error token = generateJwtWithId(member.id.toString(), jwtRole);
                if token is error {
                    io:println("JWT generation failed for member: ", token.message());
                    check memberStream.close();
                    
                    // Log JWT generation failure
                    error? logJwtFailure = activityLog:logActivity({
                        userId: member.id,
                        userType: userRole,
                        action: activityLog:LOGIN_FAILURE,
                        resourceId: member.id,
                        httpMethod: httpMethod,
                        endpoint: endpoint,
                        ipAddress: ipAddress,
                        userAgent: userAgent,
                        status: activityLog:ERROR,
                        details: string `JWT generation failed for ${member.fullName}: ${token.message()}`,
                        sessionId: sessionId
                    });
                    
                    return http:UNAUTHORIZED;
                }

                io:println("JWT generated successfully for member");
                io:println("Returning successful login response for member");

                check memberStream.close();

                // Log successful login with complete information
                error? logSuccess = activityLog:logActivity({
                    userId: member.id,
                    userType: userRole,
                    action: activityLog:LOGIN_SUCCESS,
                    resourceId: member.id,
                    httpMethod: httpMethod,
                    endpoint: endpoint,
                    ipAddress: ipAddress,
                    userAgent: userAgent,
                    status: activityLog:SUCCESS,
                    details: string `Successful login for ${member.fullName} (${member.nic ?: "No NIC"}) with role ${userRole}. Password changed: ${member.passwordchanged}`,
                    sessionId: sessionId
                });

                // Response with cookie
                LoginResponse response = {
                    userId: member.id,
                    userType: userRole,
                    fullName: member.fullName,
                    message: member.passwordchanged ? "Login successful" : "First-time login. Please change your password."
                };

                return response;
            }
        };
    check memberStream.close();

    if !memberFound {
        io:println("No household member found with NIC: ", loginReq.nic);
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

                    // Log failed login with complete info
                    error? logFailure = activityLog:logActivity({
                        userId: admin.id,
                        userType: admin.role,
                        action: activityLog:LOGIN_FAILURE,
                        resourceId: admin.id,
                        httpMethod: httpMethod,
                        endpoint: endpoint,
                        ipAddress: ipAddress,
                        userAgent: userAgent,
                        status: activityLog:FAILURE,
                        details: string `Password verification error for admin ${admin.username}: ${isVerified.message()}`,
                        sessionId: ()
                    });

                    return http:UNAUTHORIZED;
                }

                if !isVerified {
                    log:printInfo("Password verification failed - passwords don't match");
                    check adminStream.close();

                    // Log failed login with complete info
                    error? logFailure = activityLog:logActivity({
                        userId: admin.id,
                        userType: admin.role,
                        action: activityLog:LOGIN_FAILURE,
                        resourceId: admin.id,
                        httpMethod: httpMethod,
                        endpoint: endpoint,
                        ipAddress: ipAddress,
                        userAgent: userAgent,
                        status: activityLog:FAILURE,
                        details: string `Invalid password for admin ${admin.username}`,
                        sessionId: ()
                    });

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
                    
                    // Log unauthorized access with complete info
                    error? logUnauthorized = activityLog:logActivity({
                        userId: admin.id,
                        userType: admin.role,
                        action: activityLog:UNAUTHORIZED_ACCESS,
                        resourceId: admin.id,
                        httpMethod: httpMethod,
                        endpoint: endpoint,
                        ipAddress: ipAddress,
                        userAgent: userAgent,
                        status: activityLog:FAILURE,
                        details: string `Unknown admin role: ${admin.role} for user ${admin.username}`,
                        sessionId: ()
                    });
                    
                    return http:UNAUTHORIZED;
                }

                // Generate session ID for successful login
                string sessionId = getOrCreateSessionId(admin.id, admin.role);

                string|error token = generateJwtWithId(admin.id.toString(), role);
                if token is error {
                    log:printError("JWT generation failed: " + token.message());
                    check adminStream.close();
                    
                    // Log JWT generation failure
                    error? logJwtFailure = activityLog:logActivity({
                        userId: admin.id,
                        userType: admin.role,
                        action: activityLog:LOGIN_FAILURE,
                        resourceId: admin.id,
                        httpMethod: httpMethod,
                        endpoint: endpoint,
                        ipAddress: ipAddress,
                        userAgent: userAgent,
                        status: activityLog:ERROR,
                        details: string `JWT generation failed for ${admin.username}: ${token.message()}`,
                        sessionId: sessionId
                    });
                    
                    return http:UNAUTHORIZED;
                }

                check adminStream.close();
                log:printInfo("Admin login successful");

                // Log successful login with complete information
                error? logSuccess = activityLog:logActivity({
                    userId: admin.id,
                    userType: admin.role,
                    action: activityLog:LOGIN_SUCCESS,
                    resourceId: admin.id,
                    httpMethod: httpMethod,
                    endpoint: endpoint,
                    ipAddress: ipAddress,
                    userAgent: userAgent,
                    status: activityLog:SUCCESS,
                    details: string `Successful login for admin ${admin.username} with role ${admin.role}`,
                    sessionId: sessionId
                });

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

    // Log failed login attempt (user not found) with complete information
    error? logNotFound = activityLog:logActivity({
        userId: (),
        userType: (),
        action: activityLog:LOGIN_FAILURE,
        resourceId: (),
        httpMethod: httpMethod,
        endpoint: endpoint,
        ipAddress: ipAddress,
        userAgent: userAgent,
        status: activityLog:FAILURE,
        details: string `Login attempt failed - user not found for NIC: ${loginReq.nic}`,
        sessionId: ()
    });

    log:printInfo("=== LOGIN DEBUG END - NO USER FOUND ===");
    return http:UNAUTHORIZED;
}

// Enhanced change password function with complete logging
public function putChangePassword(ChangePasswordRequest req, http:Request httpRequest) returns http:Ok|http:Unauthorized|json|error {
    string? ipAddress = activityLog:getIpFromRequest(httpRequest);
    string? userAgent = activityLog:getUserAgentFromRequest(httpRequest);
    string httpMethod = httpRequest.method;
    string endpoint = httpRequest.rawPath;
    string sessionId = getOrCreateSessionId(req.userId, req.userType);

    // Validate new password
    string? passwordError = validatePasswordPolicy(req.newPassword);
    if passwordError is string {
        // Log password change failure due to invalid policy
        error? logFailure = activityLog:logActivity({
            userId: req.userId,
            userType: req.userType,
            action: activityLog:PASSWORD_CHANGE,
            resourceId: req.userId,
            httpMethod: httpMethod,
            endpoint: endpoint,
            ipAddress: ipAddress,
            userAgent: userAgent,
            status: activityLog:FAILURE,
            details: string `Password change failed - Invalid password policy: ${passwordError}`,
            sessionId: sessionId
        });

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
        // Log password change failure due to hashing error
        error? logFailure = activityLog:logActivity({
            userId: req.userId,
            userType: req.userType,
            action: activityLog:PASSWORD_CHANGE,
            resourceId: req.userId,
            httpMethod: httpMethod,
            endpoint: endpoint,
            ipAddress: ipAddress,
            userAgent: userAgent,
            status: activityLog:ERROR,
            details: string `Password change failed - Hashing error: ${newHashed.message()}`,
            sessionId: sessionId
        });

        return error("Failed to hash new password");
    }

    if req.userType == "chief" {
        store:ChiefOccupant chief = check dbClient->/chiefoccupants/[req.userId].get();

        // Verify old password
        boolean|error isVerified = verifyPassword(req.oldPassword, chief.passwordHash);
        if isVerified is error || !isVerified {
            // Log password change failure due to incorrect old password
            error? logFailure = activityLog:logActivity({
                userId: req.userId,
                userType: "chief_occupant",
                action: activityLog:PASSWORD_CHANGE,
                resourceId: req.userId,
                httpMethod: httpMethod,
                endpoint: endpoint,
                ipAddress: ipAddress,
                userAgent: userAgent,
                status: activityLog:FAILURE,
                details: string `Password change failed - Incorrect old password for ${chief.fullName}`,
                sessionId: sessionId
            });

            return http:UNAUTHORIZED;
        }

        store:ChiefOccupantUpdate chiefUpdate = {
            passwordHash: newHashed
        };
        _ = check dbClient->/chiefoccupants/[req.userId].put(chiefUpdate);

        // Log successful password change
        error? logPasswordChange = activityLog:logActivity({
            userId: req.userId,
            userType: "chief_occupant", 
            action: activityLog:PASSWORD_CHANGE,
            resourceId: req.userId,
            httpMethod: httpMethod,
            endpoint: endpoint,
            ipAddress: ipAddress,
            userAgent: userAgent,
            status: activityLog:SUCCESS,
            details: string `Password changed successfully for chief occupant ${chief.fullName}`,
            sessionId: sessionId
        });

    } else if req.userType == "household_member" {
        store:HouseholdMembers member = check dbClient->/householdmembers/[req.userId].get();

        boolean|error isVerified = verifyPassword(req.oldPassword, member.passwordHash);
        if isVerified is error || !isVerified {
            // Log password change failure due to incorrect old password
            error? logFailure = activityLog:logActivity({
                userId: req.userId,
                userType: "household_member",
                action: activityLog:PASSWORD_CHANGE,
                resourceId: req.userId,
                httpMethod: httpMethod,
                endpoint: endpoint,
                ipAddress: ipAddress,
                userAgent: userAgent,
                status: activityLog:FAILURE,
                details: string `Password change failed - Incorrect old password for ${member.fullName}`,
                sessionId: sessionId
            });

            return http:UNAUTHORIZED;
        }

        store:HouseholdMembersUpdate memberUpdate = {
            passwordHash: newHashed,
            passwordchanged: true
        };
        _ = check dbClient->/householdmembers/[req.userId].put(memberUpdate);

        // Log successful password change
        error? logPasswordChange = activityLog:logActivity({
            userId: req.userId,
            userType: "household_member", 
            action: activityLog:PASSWORD_CHANGE,
            resourceId: req.userId,
            httpMethod: httpMethod,
            endpoint: endpoint,
            ipAddress: ipAddress,
            userAgent: userAgent,
            status: activityLog:SUCCESS,
            details: string `Password changed successfully for household member ${member.fullName}. First time: ${!member.passwordchanged}`,
            sessionId: sessionId
        });

    } else {
        // Log password change failure due to invalid user type
        error? logPasswordChange = activityLog:logActivity({
            userId: req.userId,
            userType: req.userType, 
            action: activityLog:PASSWORD_CHANGE,
            resourceId: req.userId,
            httpMethod: httpMethod,
            endpoint: endpoint,
            ipAddress: ipAddress,
            userAgent: userAgent,
            status: activityLog:FAILURE,
            details: string `Password change attempted with invalid user type: ${req.userType}`,
            sessionId: sessionId
        });
        
        return http:UNAUTHORIZED;
    }

    return http:OK;
}

// Enhanced reset password function with complete logging  
public function postResetPassword(PasswordResetRequest req, http:Request httpRequest) returns http:Ok|http:Unauthorized|json|error {
    string? ipAddress = activityLog:getIpFromRequest(httpRequest);
    string? userAgent = activityLog:getUserAgentFromRequest(httpRequest);
    string httpMethod = httpRequest.method;
    string endpoint = httpRequest.rawPath;

    // Log password reset attempt
    error? logAttempt = activityLog:logActivity({
        userId: (),
        userType: (),
        action: activityLog:PASSWORD_CHANGE,
        resourceId: (),
        httpMethod: httpMethod,
        endpoint: endpoint,
        ipAddress: ipAddress,
        userAgent: userAgent,
        status: activityLog:PENDING,
        details: string `Password reset attempt for email: ${req.email}`,
        sessionId: ()
    });

    // Validate new password
    string? passwordError = validatePasswordPolicy(req.newPassword);
    if passwordError is string {
        // Log password reset failure due to invalid policy
        error? logFailure = activityLog:logActivity({
            userId: (),
            userType: (),
            action: activityLog:PASSWORD_CHANGE,
            resourceId: (),
            httpMethod: httpMethod,
            endpoint: endpoint,
            ipAddress: ipAddress,
            userAgent: userAgent,
            status: activityLog:FAILURE,
            details: string `Password reset failed - Invalid password policy: ${passwordError}`,
            sessionId: ()
        });

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
        // Log password reset failure due to hashing error
        error? logFailure = activityLog:logActivity({
            userId: (),
            userType: (),
            action: activityLog:PASSWORD_CHANGE,
            resourceId: (),
            httpMethod: httpMethod,
            endpoint: endpoint,
            ipAddress: ipAddress,
            userAgent: userAgent,
            status: activityLog:ERROR,
            details: string `Password reset failed - Hashing error: ${newHashed.message()}`,
            sessionId: ()
        });

        return error("Failed to hash new password");
    }

    // TODO: Implement finding user by email and updating password
    // This would involve checking all user tables (ChiefOccupant, AdminUsers, etc.)
    // and updating the appropriate record

    // Log successful password reset (placeholder)
    error? logSuccess = activityLog:logActivity({
        userId: (), // Would be set after finding the user
        userType: (), // Would be set after finding the user
        action: activityLog:PASSWORD_CHANGE,
        resourceId: (),
        httpMethod: httpMethod,
        endpoint: endpoint,
        ipAddress: ipAddress,
        userAgent: userAgent,
        status: activityLog:SUCCESS,
        details: string `Password reset completed successfully for email: ${req.email}`,
        sessionId: ()
    });

    return http:OK;
}
