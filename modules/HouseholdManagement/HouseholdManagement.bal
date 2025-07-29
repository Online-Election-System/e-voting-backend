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
    string requestId = request.updateRequestId;
    
    log:printInfo("Processing update request with ID: " + requestId);
    log:printInfo("Chief Occupant ID: " + request.chiefOccupantId);
    
    string? actualHouseholdMemberId = ();
    
    // Check if householdMemberId is null (chief occupant update)
    if (request.householdMemberId is ()) {
        log:printInfo("Household Member ID: NULL (Chief Occupant Update)");
        actualHouseholdMemberId = (); // Keep it null for chief occupant updates
    } else {
        string providedId = request.householdMemberId.toString();
        log:printInfo("Provided Identifier: " + providedId);
        
        // Query HouseholdMembers table to find member by NIC or actual member ID
        stream<store:HouseholdMembers, persist:Error?> membersStream = dbclient->/householdmembers.get();
        store:HouseholdMembers[] matchingMembers = check from var m in membersStream
            where (m.nic is string && m.nic == providedId) || (m.id == providedId)
            select m;
        
        if (matchingMembers.length() > 0) {
            actualHouseholdMemberId = matchingMembers[0].id;
            log:printInfo("Found household member - ID: " + (actualHouseholdMemberId ?: "N/A") + ", NIC: " + (matchingMembers[0].nic ?: "N/A"));
        } else {
            log:printError("No household member found with identifier: " + providedId);
            return error("Household member not found with identifier: " + providedId);
        }
    }
    
    log:printInfo("Actual Household Member ID to use: " + (actualHouseholdMemberId ?: "NULL"));
    log:printInfo("New Full Name: " + (request.newFullName ?: "NULL"));
    log:printInfo("New Resident Area: " + (request.newResidentArea ?: "NULL"));
    log:printInfo("Request Status: " + request.requestStatus);
    log:printInfo("Certificate Path: " + (request.relevantCertificatePath ?: "NULL"));
    
    store:UpdateMemberRequestInsert insertRequest = {
        updateRequestId: requestId,
        chiefOccupantId: request.chiefOccupantId,
        householdMemberId: actualHouseholdMemberId,
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

    log:printInfo("Update member request submitted successfully with ID: " + requestId);
    return [requestId];
}
public isolated function submitDeleteMemberRequest(store:DeleteMemberRequest request) returns error|string[] {
    string newId = common:generateId();
    
    log:printInfo("Processing delete request");
    log:printInfo("Chief Occupant ID: " + request.chiefOccupantId);
    log:printInfo("Household Member ID: " + request.householdMemberId.toString());
    
    // Verify member exists
    stream<store:HouseholdMembers, persist:Error?> membersStream = dbclient->/householdmembers.get();
    store:HouseholdMembers[] matchingMembers = check from var m in membersStream
        where m.id == request.householdMemberId
        select m;
    
    if matchingMembers.length() == 0 {
        log:printError("Household member not found: " + request.householdMemberId.toString());
        return error("Household member not found");
    }
    
    store:DeleteMemberRequestInsert insertRequest = {
        deleteRequestId: newId,
        chiefOccupantId: request.chiefOccupantId,
        householdMemberId: request.householdMemberId,
        requestStatus: request.requestStatus,
        requiredDocumentPath: request.requiredDocumentPath
    };
    
    string[]|error deleteResponse = dbclient->/deletememberrequests.post([insertRequest]);
    if deleteResponse is error {
        log:printError("Failed to submit delete request: " + deleteResponse.message());
        return error("Failed to submit delete request");
    }

    log:printInfo("Delete request submitted successfully");
    return [newId];
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
            memberId: member.id, 
            memberName: member.fullName,
            fullName: member.fullName, 
            nic: member.nic ?: "N/A",
            status: "☑ Pending",
            rejectionReason: "☑ Pending",
            relationship: member.relationshipWithChiefOccupant,
            relationshipWithChiefOccupant: member.relationshipWithChiefOccupant 
        };
        memberData.push(status);
    }

    return {
        chiefOccupant: {
            memberId: chief.id, 
            fullName: chief.fullName,
            nic: chief.nic,
            status: "☑ Approved",
            role: chief.role
        },
        totalMembers: household.householdMemberCount + 1,
        members: memberData
    };
}