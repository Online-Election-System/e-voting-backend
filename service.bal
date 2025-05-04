import ballerina/http;
import ballerina/crypto;
import ballerina/uuid;
import ballerina/persist;
import e_backend.data;
import ballerina/log;
import ballerina/email;

listener http:Listener voterListener = new (9090);

final data:Client dbClient = check new ();

email:SmtpClient smtpClient = check new (
    "smtp.gmail.com",
    "rashminkavindya2@gmail.com",
    "ktax nqmc qcre myfq"          
);

service /voter\-registration/api/v1 on voterListener {
    // Register Chief Occupant
    resource function post chiefoccupants/register(ChiefOccupantInput newChiefOccupant)
            returns http:Created|http:Forbidden|error {

        string hashedPassword = crypto:hashMd5(newChiefOccupant.passwordHash.toBytes()).toBase16();
        string chiefOccupantId = generateId();
        data:ChiefOccupantInsert chiefOccupantInsert = {
            id: chiefOccupantId,
            fullName: newChiefOccupant.fullName,
            nic: newChiefOccupant.nic,
            phoneNumber: newChiefOccupant.phoneNumber,
            dob: newChiefOccupant.dob,
            gender: newChiefOccupant.gender,
            civilStatus: newChiefOccupant.civilStatus,
            passwordHash: hashedPassword,
            email : newChiefOccupant.email,
            idCopyPath: newChiefOccupant.idCopyPath
        };
        string[] | error chiefResponse = dbClient->/chiefoccupants.post([chiefOccupantInsert]);
        if chiefResponse is error {
            return chiefResponse;
        }
        check sendWelcomeEmail(newChiefOccupant.email, newChiefOccupant.fullName, newChiefOccupant.passwordHash);
        return http:CREATED;
    }
   // Register Household Details
    resource function post householddetails/register(HouseholdDetailsInput newHousehold)
            returns http:Created|error {

        if newHousehold.chiefOccupantId == "" {
            return error("Chief Occupant ID is required");
        }
        data:ChiefOccupant|persist:Error chiefOccupant = dbClient->/chiefoccupants/[newHousehold.chiefOccupantId].get();
        if chiefOccupant is persist:Error {
            return error("Chief Occupant not found");
        }
        stream<data:HouseholdDetails, persist:Error?> householdStream = dbClient->/householddetails.get();
        boolean householdExists = false;

        check from data:HouseholdDetails household in householdStream
            where household.chiefOccupantId == newHousehold.chiefOccupantId
            do {
                householdExists = true;
            };
        check householdStream.close();

        if householdExists {
            return error("This Chief Occupant already has a Household registered.");
        }
        string householdId = generateId();
        data:HouseholdDetailsInsert householdInsert = {
            id: householdId,
            chiefOccupantId: newHousehold.chiefOccupantId,
            electoralDistrict: newHousehold.electoralDistrict,
            pollingDivision: newHousehold.pollingDivision,
            pollingDistrictNumber: newHousehold.pollingDistrictNumber,
            gramaNiladhariDivision: newHousehold.gramaNiladhariDivision,
            villageStreetEstate: newHousehold.villageStreetEstate,
            houseNumber: newHousehold.houseNumber,
            householdMemberCount: newHousehold.householdMemberCount
        };
        string[]|error householdResponse = dbClient->/householddetails.post([householdInsert]);
        if householdResponse is error {
            return householdResponse;
        }
        return http:CREATED;
    }
    // Register Household Members based on the provided count
   resource function post householdmembers/register(HouseholdMembersRequest newHouseholdMembers)
        returns http:Created|http:Forbidden|error {

        log:printInfo("Received registration payload", payload = newHouseholdMembers);

        if newHouseholdMembers.chiefOccupantId == "" {
            return error("Chief Occupant ID is required");
        }
        stream<data:HouseholdDetails, persist:Error?> resultStream =
            dbClient->/householddetails.get();
        data:HouseholdDetails? householdDetails = ();
        check from data:HouseholdDetails household in resultStream
            where household.chiefOccupantId == newHouseholdMembers.chiefOccupantId
            do {
                householdDetails = household;
            };
        check resultStream.close();
        if householdDetails is () {
            return error("Household details not found for the given Chief Occupant ID");
        }
        int householdMemberLimit = householdDetails.householdMemberCount;
        stream<data:HouseholdMembers, persist:Error?> existingMembersStream = dbClient->/householdmembers.get();
        int currentMemberCount = 0;
        check from data:HouseholdMembers member in existingMembersStream
            where member.chiefOccupantId == householdDetails.chiefOccupantId

            do {
                currentMemberCount += 1;
            };
        check existingMembersStream.close();
        int newMembersCount = newHouseholdMembers.members.length();
        int totalMembersAfterInsert = currentMemberCount + newMembersCount;
        if totalMembersAfterInsert > householdMemberLimit {
            return error("Total members cannot exceed the defined household member count.");
        } else if totalMembersAfterInsert < householdMemberLimit {
            return error("Please register the exact number of household members as specified.");
        }
        string[] passwordList = [];
       foreach var member in newHouseholdMembers.members {
            string plainPassword = check generatePassword();
            string hashedPassword = crypto:hashMd5(plainPassword.toBytes()).toBase16();
            string memberId = generateId();
            data:HouseholdMembersInsert memberInsert = {
                id: memberId,
                chiefOccupantId: householdDetails.chiefOccupantId,
                fullName: member.fullName,
                nic: member.nic,
                relationshipWithChiefOccupant: member.relationshipWithChiefOccupant,
                dob: member.dob,
                gender: member.gender,
                approvedByChief: false,
                civilStatus: member.civilStatus,
                idCopyPath: member.idCopyPath,
                passwordHash: hashedPassword,
                passwordchanged: false
            };
            string[] | error householdMemberResponse = dbClient->/householdmembers.post([memberInsert]);
            if householdMemberResponse is error {
                return householdMemberResponse;
            }
            string nic = member.nic ?: "N/A";
            passwordList.push(string `${member.fullName} (${nic}): ${plainPassword}`);
        }
        data:ChiefOccupant|persist:Error chief = dbClient->/chiefoccupants/[householdDetails.chiefOccupantId].get();
        if chief is data:ChiefOccupant {
            check sendHouseholdPasswordsToChief(smtpClient, chief.email, chief.fullName, passwordList);
        }
        return http:CREATED;
    }
    // User Login - Chief Occupant or Household Member
    resource function post login(LoginRequest loginReq) 
    returns LoginResponse|http:Unauthorized|error {
        string hashedPassword = crypto:hashMd5(loginReq.password.toBytes()).toBase16();

        // Try Chief Occupant login
        stream<data:ChiefOccupant, persist:Error?> chiefStream = dbClient->/chiefoccupants.get();
        check from data:ChiefOccupant chief in chiefStream
            where chief.nic == loginReq.nic && chief.passwordHash == hashedPassword
            do {
                check chiefStream.close();
                return {
                    userId: chief.id,
                    userType: "chief",
                    fullName: chief.fullName,
                    message: "Login successful"
                };
            };
        check chiefStream.close();

        // Try Household Member login
        stream<data:HouseholdMembers, persist:Error?> memberStream = dbClient->/householdmembers.get();
        check from data:HouseholdMembers member in memberStream
            where member.nic == loginReq.nic && member.passwordHash == hashedPassword
            do {
                check memberStream.close();

                if !member.passwordchanged {
                    return {
                        userId: member.id,
                        userType: "householdMember",
                        fullName: member.fullName,
                        message: "First-time login. Please change your password."
                    };
                } else {
                    return {
                        userId: member.id,
                        userType: "householdMember",
                        fullName: member.fullName,
                        message: "Login successful"
                    };
                }
            };
        check memberStream.close();

        return http:UNAUTHORIZED;
    }
    // Password Change Endpoint
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

            return http:OK;

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
            return http:OK;
        }

        return http:UNAUTHORIZED;
    }
}
function generateId() returns string {
    return uuid:createType1AsString();
}