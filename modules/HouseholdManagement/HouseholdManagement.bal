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
        reason: request.reason,
        nicOrBirthCertificatePath: request.nicOrBirthCertificatePath,
        photoCopyPath: request.photoCopyPath
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
    
     store:UpdateMemberRequestInsert insertRequest = {
        updateRequestId: requestId,
        chiefOccupantId: request.chiefOccupantId,
        householdMemberId: actualHouseholdMemberId,
        newFullName: request.newFullName,
        newCivilStatus: request.newCivilStatus,
        relevantCertificatePath: request.relevantCertificatePath,
        requestStatus: request.requestStatus,
        reason: request.reason
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
        requiredDocumentPath: request.requiredDocumentPath,
        reason: request.reason,
        rejectionReason: request.rejectionReason
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
// Updated getHouseholdMembers function to show existing members, add member requests, update requests, and delete requests
public function getHouseholdMembers(string chiefOccupantId) returns json|error {
    // Fetch chief occupant
    store:ChiefOccupant|persist:Error chief = dbclient->/chiefoccupants/[chiefOccupantId].get();
    if chief is persist:Error {
        return error("Chief occupant not found");
    }

    // Fetch household details
    stream<store:HouseholdDetails, persist:Error?> householdStream = dbclient->/householddetails.get();
    store:HouseholdDetails[] householdList = check from var h in householdStream
        where h.chiefOccupantId == chiefOccupantId
        select h;
    if householdList.length() == 0 {
        return error("Household details not found");
    }
    store:HouseholdDetails _ = householdList[0];
    
    // Fetch existing household members
    stream<store:HouseholdMembers, persist:Error?> membersStream = dbclient->/householdmembers.get();
    store:HouseholdMembers[] existingMembers = check from var m in membersStream
        where m.chiefOccupantId == chiefOccupantId
        select m;

    // Fetch ALL add member requests for this chief occupant
    stream<store:AddMemberRequest, persist:Error?> addRequests = dbclient->/addmemberrequests.get();
    store:AddMemberRequest[] allRequests = check from var r in addRequests
        where r.chiefOccupantId == chiefOccupantId
        select r;

    // Fetch update member requests for this chief occupant
    stream<store:UpdateMemberRequest, persist:Error?> updateRequestsStream = dbclient->/updatememberrequests.get();
    store:UpdateMemberRequest[] updateRequestsList = check from var u in updateRequestsStream
        where u.chiefOccupantId == chiefOccupantId
        select u;

    // Fetch delete member requests for this chief occupant
    stream<store:DeleteMemberRequest, persist:Error?> deleteRequestsStream = dbclient->/deletememberrequests.get();
    store:DeleteMemberRequest[] deleteRequestsList = check from var d in deleteRequestsStream
        where d.chiefOccupantId == chiefOccupantId
        select d;

    json[] memberData = [];

    // First, add existing household members with their request status
    foreach store:HouseholdMembers member in existingMembers {
        // Find the corresponding add member request
        store:AddMemberRequest? memberRequest = ();
        foreach store:AddMemberRequest request in allRequests {
            if (request.nicNumber == member.nic) {
                memberRequest = request;
                break;
            }
        }

        string status = "Approved"; // Default for existing members
        string rejectionReason = "—";
        string? requestDate = ();

        if (memberRequest is store:AddMemberRequest) {
            if (memberRequest.requestStatus == "APPROVED") {
                status = "Approved";
            } else if (memberRequest.requestStatus == "REJECTED") {
                status = "Rejected";
            } else if (memberRequest.requestStatus == "PENDING_REVIEW") {
                status = "D. Funding";
            } else {
                status = "Pending";
            }
            
            rejectionReason = memberRequest.reason ?: "—";
        }

        memberData.push({
            memberId: member.id,
            fullName: member.fullName,
            nic: member.nic ?: "N/A",
            status: status,
            rejectionReason: rejectionReason,
            relationship: member.relationshipWithChiefOccupant,
            requestDate: requestDate,
            isNewRequest: false // These are existing members
        });
    }

    // Then, add new add member requests that don't have corresponding household members yet
    foreach store:AddMemberRequest request in allRequests {
        // Check if this request already has a corresponding household member
        boolean hasExistingMember = false;
        foreach store:HouseholdMembers member in existingMembers {
            if (member.nic == request.nicNumber) {
                hasExistingMember = true;
                break;
            }
        }

        // Only add if it's a new request without existing member
        if (!hasExistingMember) {
            string status = "Pending";
            if (request.requestStatus == "APPROVED") {
                status = "Approved";
            } else if (request.requestStatus == "REJECTED") {
                status = "Rejected";
            } else if (request.requestStatus == "PENDING_REVIEW") {
                status = "D. Funding";
            }

            memberData.push({
                memberId: request.addRequestId,
                fullName: request.fullName,
                nic: request.nicNumber,
                status: status,
                rejectionReason: request.reason ?: "—",
                relationship: request.relationshipToChief,
                isNewRequest: true // These are new requests
            });
        }
    }

    // Process update requests and format them for the frontend
    json[] updateRequestsData = [];
    foreach store:UpdateMemberRequest updateReq in updateRequestsList {
        // Determine if this is a chief occupant update or member update
        boolean isChiefOccupantUpdate = updateReq.householdMemberId is ();
        
        string memberName = "";
        string memberNic = "";
        
        if (isChiefOccupantUpdate) {
            // Chief occupant update
            memberName = chief.fullName;
            memberNic = chief.nic;
        } else {
            // Find the household member
            string householdMemberId = updateReq.householdMemberId.toString();
            foreach store:HouseholdMembers member in existingMembers {
                if (member.id == householdMemberId) {
                    memberName = member.fullName;
                    memberNic = member.nic ?: "N/A";
                    break;
                }
            }
        }

        updateRequestsData.push({
            updateRequestId: updateReq.updateRequestId,
            chiefOccupantId: updateReq.chiefOccupantId,
            householdMemberId: updateReq.householdMemberId,
            memberName: memberName,
            memberNic: memberNic,
            newFullName: updateReq.newFullName,
            newCivilStatus: updateReq.newCivilStatus,
            relevantCertificatePath: updateReq.relevantCertificatePath,
            reason: updateReq.reason,
            isChiefOccupantUpdate: isChiefOccupantUpdate
        });
    }

    // Process delete requests and format them for the frontend
    json[] deleteRequestsData = [];
    foreach store:DeleteMemberRequest deleteReq in deleteRequestsList {
        string memberName = "";
        string memberNic = "";
        
        // Find the household member being deleted
        string householdMemberId = deleteReq.householdMemberId.toString();
        foreach store:HouseholdMembers member in existingMembers {
            if (member.id == householdMemberId) {
                memberName = member.fullName;
                memberNic = member.nic ?: "N/A";
                break;
            }
        }

        deleteRequestsData.push({
            deleteRequestId: deleteReq.deleteRequestId,
            chiefOccupantId: deleteReq.chiefOccupantId,
            householdMemberId: deleteReq.householdMemberId,
            memberName: memberName,
            memberNic: memberNic,
            requestStatus: deleteReq.requestStatus,
            requiredDocumentPath: deleteReq.requiredDocumentPath,
            reason: deleteReq.reason,
            rejectionReason: deleteReq.rejectionReason
        });
    }

    // Calculate total members (existing members + chief)
    int totalMembers = existingMembers.length() + 1; // +1 for chief

    return {
        chiefOccupant: {
            memberId: chief.id,
            fullName: chief.fullName,
            nic: chief.nic,
            status: "Approved",
            role: "Chief Occupant"
        },
        totalMembers: totalMembers,
        members: memberData,
        updateRequests: updateRequestsData,
        deleteRequests: deleteRequestsData 
    };
}