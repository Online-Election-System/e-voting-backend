import online_election.store;
import online_election.common;
import ballerina/log;
import ballerina/persist;

final store:Client dbclient = check new ();
public isolated function submitAddMemberRequest(store:AddMemberRequest request) returns error|string[] {
    string newId = common:generateId();
    store:AddMemberRequestInsert insertRequest = {
        addRequestId: newId,
        chiefOccupantId: request.chiefOccupantId,
        nicNumber: request.nicNumber,
        fullName: request.fullName,
        dateOfBirth: request.dateOfBirth,
        gender: request.gender,
        civilStatus: request.civilStatus,
        relationshipToChief: request.relationshipToChief,
        chiefOccupantApproval: request.chiefOccupantApproval,
        requestStatus: request.requestStatus,
        nicOrBirthCertificatePath: request.nicOrBirthCertificatePath
    };
    string[]|error addResponse = dbclient->/addmemberrequests.post([insertRequest]);
    if addResponse is error {
        log:printError("Failed to submit add member request: " + addResponse.message());
        return error("Failed to submit add member request: " + addResponse.message());
    }

    log:printInfo("Add member request submitted successfully");
    return addResponse;
}
public isolated function submitUpdateMemberRequest(store:UpdateMemberRequest request) returns error|string[] {
    string newId = common:generateId();
    store:UpdateMemberRequestInsert insertRequest = {
        updateRequestId: newId,
        chiefOccupantId: request.chiefOccupantId,
        householdMemberId: request.householdMemberId,
        newFullName: request.newFullName,
        newResidentArea: request.newResidentArea,
        requestStatus: request.requestStatus,
        relevantCertificatePath: request.relevantCertificatePath
    };
    string[]|error updateResponse = dbclient->/updatememberrequests.post([insertRequest]);
    if updateResponse is error {
        log:printError("Failed to submit update member request: " + updateResponse.message());
        return error("Failed to submit update member request: " + updateResponse.message());
    }

    log:printInfo("Update member request submitted successfully");
    return updateResponse;
}
public isolated function submitDeleteMemberRequest(store:DeleteMemberRequest request) returns error|string[] {
    string newId = common:generateId();
    store:DeleteMemberRequestInsert insertRequest = {
        deleteRequestId: newId,
        chiefOccupantId: request.chiefOccupantId,
        householdMemberId: request.householdMemberId,
        requestStatus: request.requestStatus,
        requiredDocumentPath: request.requiredDocumentPath
    };
    string[]|error deleteResponse = dbclient->/deletememberrequests.post([insertRequest]);
    if deleteResponse is error {
        log:printError("Failed to submit delete member request: " + deleteResponse.message());
        return error("Failed to submit delete member request: " + deleteResponse.message());
    }
    log:printInfo("Delete member request submitted successfully");
    return deleteResponse;
}

// --- Get Household Members ---
public function getHouseholdMembers(string chiefOccupantId) returns json|error {
    // Fetch chief occupant
    store:ChiefOccupant|persist:Error chief = dbclient->/chiefoccupants/[chiefOccupantId].get();
    if chief is persist:Error {
        return error("Chief occupant not found");
    }

    // Fetch household details (all) and filter by chiefOccupantId
    stream<store:HouseholdDetails, persist:Error?> householdStream = dbclient->/householddetails.get();
    store:HouseholdDetails[] householdList = check from var h in householdStream
        where h.chiefOccupantId == chiefOccupantId
        select h;
    if householdList.length() == 0 {
        return error("Household details not found");
    }
    store:HouseholdDetails household = householdList[0];

    // Fetch household members (all) and filter by chiefOccupantId
    stream<store:HouseholdMembers, persist:Error?> membersStream = dbclient->/householdmembers.get();
    store:HouseholdMembers[] members = check from var m in membersStream
        where m.chiefOccupantId == chiefOccupantId
        select m;

    json[] memberData = [];

    foreach store:HouseholdMembers member in members {
        json status = {
            memberName: member.fullName,
            nic: member.nic ?: "N/A",
            status: "☑ Pending",
            rejectionReason: "☑ Pending",
            relationship: member.relationshipWithChiefOccupant
        };
        memberData.push(status);
    }

    return {
        chiefOccupant: {
            fullName: chief.fullName,
            nic: chief.nic,
            status: "☑ Approved",
            role: chief.role
        },
        totalMembers: household.householdMemberCount + 1,
        members: memberData
    };
}