import ballerina/http;
import ballerina/crypto;
import ballerina/uuid;
import e_backend.data;
import ballerina/persist;
import ballerina/sql;

listener http:Listener voterListener = new (9090);

final data:Client dbClient = check new ();


public type VoterLogin record { 
    string nationalId; 
    string password; 
};

service /Voter\-registration/api/v1 on voterListener {

    // Register a new voter
    @http:ResourceConfig {}
    resource function post voters/register(@http:Payload data:Voter newVoter)
            returns http:Created|http:Forbidden|error {

        string hashedPassword = crypto:hashMd5(newVoter.password.toBytes()).toBase16();

        data:VoterInsert voterInsert = {
            id: generateId(),
            nationalId: newVoter.nationalId,
            fullName: newVoter.fullName,
            mobileNumber: newVoter.mobileNumber,
            dob: newVoter.dob,
            gender: newVoter.gender,
            nicChiefOccupant: newVoter.nicChiefOccupant,
            address: newVoter.address,
            district: newVoter.district,
            householdNo: newVoter.householdNo,
            gramaNiladhari: newVoter.gramaNiladhari,
            password: hashedPassword
        };

        data:VoterInsert[] voterInsertArr = [voterInsert];
        string[] | error response = dbClient->/voters.post(voterInsertArr);

        if response is error {
            return response;
        }
        return http:CREATED;
    }

    // Voter Login
    @http:ResourceConfig {}
    resource function post voters/login(@http:Payload VoterLogin loginDetails)
    returns http:Response|http:Unauthorized|error {
    
        
        sql:ParameterizedQuery query = `SELECT * FROM "Voter" WHERE "nationalId"::text = ${loginDetails.nationalId}`;
        
        stream<data:Voter, persist:Error?>|error queryResult = dbClient->queryNativeSQL(query);
        
        if queryResult is error {
            return error("Internal Server Error");
        }
        
        stream<data:Voter, persist:Error?> voterStream = queryResult;
        var voterRecord = voterStream.next();
        
        data:Voter? voter = ();
        
        if voterRecord is record {| data:Voter value; |} {
            voter = voterRecord.value;
        }
        
        check voterStream.close();
        
        if voter is () {
            
            return http:UNAUTHORIZED;
        }
        
        string hashedInputPassword = crypto:hashMd5(loginDetails.password.toBytes()).toBase16();
        
        
        if voter.password == hashedInputPassword {
            string sessionToken = generateId();
            json responseBody = { "message": "Login successful", "token": sessionToken };
            http:Response response = new;
            response.statusCode = http:STATUS_OK;
            response.setJsonPayload(responseBody);
            return response;
        } else {
            //log:printError("Invalid password for National ID: " + loginDetails.nationalId);
            return http:UNAUTHORIZED;
        }
    }

}

function generateId() returns string {
    return uuid:createType1AsString();
}
