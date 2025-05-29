import online_election.common;
import online_election.store;

import ballerina/crypto;
import ballerina/http;
import ballerina/persist;
import ballerina/sql;

final store:Client dbClient = check new ();

public function registerVoter(store:Voter newVoter) returns http:Created|http:Forbidden|error {
    string hashedPassword = crypto:hashMd5(newVoter.password.toBytes()).toBase16();
    store:VoterInsert voterInsert = {
        id: common:generateId(),
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
    store:VoterInsert[] voterInsertArr = [voterInsert];
    string[]|error response = dbClient->/voters.post(voterInsertArr);
    if response is error {
        return response;
    }
    return http:CREATED;
}

public function loginVoter(VoterLogin loginDetails) returns http:Response|http:Unauthorized|error {
    sql:ParameterizedQuery query = `SELECT * FROM "Voter" WHERE "nationalId"::text = ${loginDetails.nationalId}`;
    stream<store:Voter, persist:Error?>|error queryResult = dbClient->queryNativeSQL(query);
    if queryResult is error {
        return error("Internal Server Error");
    }

    stream<store:Voter, persist:Error?> voterStream = queryResult;
    var voterRecord = voterStream.next();
    check voterStream.close();

    if voterRecord is record {|store:Voter value;|} {
        store:Voter voter = voterRecord.value;

        string hashedInputPassword = crypto:hashMd5(loginDetails.password.toBytes()).toBase16();
        if voter.password != hashedInputPassword {
            return http:UNAUTHORIZED;
        }

        string sessionToken = common:generateId();
        json responseBody = {"message": "Login successful", "token": sessionToken};
        http:Response response = new;
        response.statusCode = http:STATUS_OK;
        response.setJsonPayload(responseBody);
        return response;
    }

    return http:UNAUTHORIZED;
}
