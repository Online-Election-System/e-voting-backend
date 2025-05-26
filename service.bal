import ballerina/http;
import ballerina/crypto;
import ballerina/uuid;
import ballerina/persist;
import e_backend.data;
import ballerina/email;

listener http:Listener voterListener = new (9090);
final data:Client dbClient = check new ();
email:SmtpClient smtpClient = check new (
    "smtp.gmail.com",
    "rashminkavindya2@gmail.com",
    "ktax nqmc qcre myfq"          
);
service /voter\-registration/api/v1 on voterListener {

    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000"],
            allowCredentials: true,
            allowHeaders: ["Content-Type", "Authorization"],
            allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
        }
    }
    resource function post registration(VoterRegistrationRequest request) returns http:Created|http:Forbidden|error {
        string chiefOccupantId = generateId();
        request.householdDetails.chiefOccupantId = chiefOccupantId;
        request.newHouseholdMembers.chiefOccupantId = chiefOccupantId;
        string plainedPassword = request.chiefOccupant.passwordHash;
        string hashedPassword = crypto:hashMd5(plainedPassword.toBytes()).toBase16();
        data:ChiefOccupantInsert chiefOccupantInsert = {
            id: chiefOccupantId,
            fullName: request.chiefOccupant.fullName,
            nic: request.chiefOccupant.nic,
            phoneNumber: request.chiefOccupant.phoneNumber,
            dob: request.chiefOccupant.dob,
            gender: request.chiefOccupant.gender,
            civilStatus: request.chiefOccupant.civilStatus,
            passwordHash: hashedPassword,
            email: request.chiefOccupant.email,
            idCopyPath: request.chiefOccupant.idCopyPath
        };
        string[] | error chiefResponse = dbClient->/chiefoccupants.post([chiefOccupantInsert]);
        if chiefResponse is error {
            return chiefResponse;
        }
        check sendWelcomeEmail(request.chiefOccupant.email, request.chiefOccupant.fullName, request.chiefOccupant.passwordHash);

        // Household Details
        string householdId = generateId();
        data:HouseholdDetailsInsert householdInsert = {
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
        string[]|error householdResponse = dbClient->/householddetails.post([householdInsert]);
        if householdResponse is error {
            return householdResponse;
        }
        // Household Members
        int memberCount = request.newHouseholdMembers.members.length();
        if memberCount != request.householdDetails.householdMemberCount {
            return error("Mismatch between specified and provided household member count.");
        }
        string[] passwordList = [];
        foreach var member in request.newHouseholdMembers.members {
            string plainPassword = check generatePassword();
            string hashedMemberPassword = crypto:hashMd5(plainPassword.toBytes()).toBase16();
            string memberId = generateId();
            data:HouseholdMembersInsert memberInsert = {
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
                passwordHash: hashedMemberPassword,
                passwordchanged: false
            };
            string[]|error memberResp = dbClient->/householdmembers.post([memberInsert]);
            if memberResp is error {
                return memberResp;
            }
            string nic = member.nic ?: "N/A";
            passwordList.push(string `${member.fullName} (${nic}): ${plainPassword}`);
        }
        data:ChiefOccupant|persist:Error chief = dbClient->/chiefoccupants/[chiefOccupantId].get();
        if chief is data:ChiefOccupant {
            check sendHouseholdPasswordsToChief(smtpClient, chief.email, chief.fullName, passwordList);
        }
        return http:CREATED;
    }

    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000"],
            allowCredentials: true,
            allowHeaders: ["Content-Type", "Authorization"],
            allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
        }
    }
    resource function post login(LoginRequest loginReq) returns LoginResponse|http:Unauthorized|error {
        string hashedPassword = crypto:hashMd5(loginReq.password.toBytes()).toBase16();
        // ChiefOccupant login
        stream<data:ChiefOccupant, persist:Error?> chiefStream = dbClient->/chiefoccupants.get();
        check from data:ChiefOccupant chief in chiefStream
            where chief.nic == loginReq.nic && chief.passwordHash == hashedPassword
            do {
                check chiefStream.close();
                string|error token = generateJwt(chief.id.toString(), "chief");
                if token is error {
                    return http:UNAUTHORIZED;
                }
                return {
                    userId: chief.id,
                    userType: "chief",
                    fullName: chief.fullName,
                    message: "Login successful",
                    token: token
                };
            };
        check chiefStream.close();
        // Household members login
        stream<data:HouseholdMembers, persist:Error?> memberStream = dbClient->/householdmembers.get();
        check from data:HouseholdMembers member in memberStream
            where member.nic == loginReq.nic && member.passwordHash == hashedPassword
            do {
                check memberStream.close();
                string|error token = generateJwt(member.id.toString(), "householdMember");
                if token is error {
                    return http:UNAUTHORIZED;
                }
                return {
                    userId: member.id,
                    userType: "householdMember",
                    fullName: member.fullName,
                    message: member.passwordchanged ? "Login successful" : "First-time login. Please change your password.",
                    token: token
                };
            };
        check memberStream.close();
        return http:UNAUTHORIZED;
    }

    @http:ResourceConfig {
        cors: {
            allowOrigins: ["http://localhost:3000"],
            allowCredentials: true,
            allowHeaders: ["Content-Type", "Authorization"],
            allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
        }
    }
    resource function put changepassword(ChangePasswordRequest req) returns http:Ok|http:Unauthorized|error {
        string oldHashed = crypto:hashMd5(req.oldPassword.toBytes()).toBase16();
        string newHashed = crypto:hashMd5(req.newPassword.toBytes()).toBase16();
        if req.userType == "chief" {
            data:ChiefOccupant chief = check dbClient->/chiefoccupants/[req.userId].get();
            if chief.passwordHash != oldHashed {
                return http:UNAUTHORIZED;
            }
            data:ChiefOccupantUpdate chiefUpdate = {
                passwordHash: newHashed
            };
            _ = check dbClient->/chiefoccupants/[req.userId].put(chiefUpdate);
        } else if req.userType == "householdMember" {
            data:HouseholdMembers member = check dbClient->/householdmembers/[req.userId].get();
            if member.passwordHash != oldHashed {
                return http:UNAUTHORIZED;
            }
            data:HouseholdMembersUpdate memberUpdate = {
                passwordHash: newHashed,
                passwordchanged: true
            };
            _ = check dbClient->/householdmembers/[req.userId].put(memberUpdate);
        } else {
            return http:UNAUTHORIZED;
        }
        return http:OK;
    }
}
function generateId() returns string {
    return uuid:createType1AsString();
}