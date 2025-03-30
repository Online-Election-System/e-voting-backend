import ballerina/http;
import ballerina/crypto;
import ballerina/uuid;
import e_backend.data;

listener http:Listener voterListener = new (9090);

final data:Client dbClient = check new ();

service /voter\-registration/api/v1 on voterListener {

    // Register Chief Occupant
    @http:ResourceConfig {}
    resource function post chiefoccupants/register(@http:Payload data:ChiefOccupant newChiefOccupant)
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
            idCopyPath: newChiefOccupant.idCopyPath
        };

        // Insert into database
        string[] | error chiefResponse = dbClient->/chiefoccupants.post([chiefOccupantInsert]);
        if chiefResponse is error {
            return chiefResponse;
        }
        return http:CREATED;
    }

    // Register Household Details
    @http:ResourceConfig {}
    resource function post householddetails/register2(@http:Payload data:HouseholdDetails newHousehold)
            returns http:Created|http:Forbidden|error {

        if newHousehold.chiefOccupantId == "" { 
          return error("Chief Occupant ID is required");
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

        // Insert into database
        string[] | error householdResponse = dbClient->/householddetails.post([householdInsert]);
        if householdResponse is error {
            return householdResponse;
        }

        return http:CREATED;
    }

}

function generateId() returns string {
    return uuid:createType1AsString();
}
