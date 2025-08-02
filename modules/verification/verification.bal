import ballerina/persist;
import codeCrew/online_election.store;
import ballerina/time;
import ballerina/uuid;

final store:Client dbClient = check new ();

// ----- Business Logic Functions -----

public function getRegistrationApplications(string? nameOrNic, string? statusFilter) returns RegistrationApplication[]|error {
    
    // 1. Fetch all Chief Occupants and filter by role
    stream<store:ChiefOccupant, persist:Error?> chiefStream = dbClient->/chiefoccupants;
    store:ChiefOccupant[] chiefs = check from store:ChiefOccupant co in chiefStream 
        where co.role == "chief_occupant" 
        select co;

    // 2. Fetch all Household Members and filter by role
    stream<store:HouseholdMembers, persist:Error?> memberStream = dbClient->/householdmembers;
    store:HouseholdMembers[] members = check from store:HouseholdMembers hm in memberStream 
        where hm.role == "household_member" 
        select hm;

    // 3. Fetch all HouseholdDetails into map for efficient lookup
    stream<store:HouseholdDetails, persist:Error?> hhDetailsStream = dbClient->/householddetails;
    map<store:HouseholdDetails> hhDetailsMap = {};
    check from store:HouseholdDetails detail in hhDetailsStream
        do {
            hhDetailsMap[detail.chiefOccupantId] = detail;
        };

    // 4. Fetch all RegistrationReview records into map for efficient lookup
    stream<store:RegistrationReview, persist:Error?> reviewStream = dbClient->/registrationreviews;
    map<store:RegistrationReview> reviewMap = {};
    check from store:RegistrationReview review in reviewStream
        do {
            reviewMap[review.memberNic] = review;
        };

    // 5. Combine chiefs and members into a unified application list
    RegistrationApplication[] applications = [];
    
    // Process Chief Occupants
    foreach var chief in chiefs {
        // Get status from RegistrationReview table or default to "pending"
        string status = "pending";
        if reviewMap.hasKey(chief.nic) {
            status = reviewMap.get(chief.nic).status;
        }

        applications.push({
            fullName: chief.fullName,
            nic: chief.nic,
            dob: chief.dob,
            phone: chief.phoneNumber,
            address: "-",
            status: status
        });
    }

    // Process Household Members
    foreach var member in members {
        // Only process members with NIC (some might not have NIC)
        if member.nic is string && member.nic != "" {
            // Get status from RegistrationReview table or default to "pending"
            string status = "pending";
            if reviewMap.hasKey(<string>member.nic) {
                status = reviewMap.get(<string>member.nic).status;
            }

            applications.push({
                fullName: member.fullName,
                nic: <string>member.nic,
                dob: member.dob,
                phone: (), 
                address: "-",
                status: status
            });
        }
    }

    // 6. Apply filters if provided
    RegistrationApplication[] filteredApplications = applications;
    
    // Filter by name or NIC
    if nameOrNic is string && nameOrNic.trim() != "" {
        string searchTerm = string:toLowerAscii(nameOrNic.trim());
        filteredApplications = from var app in filteredApplications
            where string:toLowerAscii(app.fullName).includes(searchTerm) || 
                  string:toLowerAscii(app.nic).includes(searchTerm)
            select app;
    }

    // Filter by status
    if statusFilter is string && statusFilter != "all" && statusFilter != "All Status" {
        string statusTerm = string:toLowerAscii(statusFilter);
        filteredApplications = from var app in filteredApplications
            where string:toLowerAscii(app.status) == statusTerm
            select app;
    }

    return filteredApplications;
}

public function getApplicationCounts() returns StatusCounts|error {
    
    // 1. Get approved count from RegistrationReview table
    stream<store:RegistrationReview, persist:Error?> approvedStream = dbClient->/registrationreviews;
    store:RegistrationReview[] approvedReviews = check from store:RegistrationReview review in approvedStream
        where review.status == "approved"
        select review;
    int approved = approvedReviews.length();
    
    // 2. Get rejected count from RegistrationReview table
    stream<store:RegistrationReview, persist:Error?> rejectedStream = dbClient->/registrationreviews;
    store:RegistrationReview[] rejectedReviews = check from store:RegistrationReview review in rejectedStream
        where review.status == "rejected"
        select review;
    int rejected = rejectedReviews.length();
    
    // 3. Get all reviewed NICs (both approved and rejected)
    stream<store:RegistrationReview, persist:Error?> allReviewStream = dbClient->/registrationreviews;
    string[] reviewedNics = [];
    check from store:RegistrationReview review in allReviewStream
        do {
            reviewedNics.push(review.memberNic);
        };
    
    // 4. Count pending: Chief Occupants with role "chief_occupant" who are NOT reviewed
    stream<store:ChiefOccupant, persist:Error?> chiefStream = dbClient->/chiefoccupants;
    store:ChiefOccupant[] pendingChiefs = check from store:ChiefOccupant co in chiefStream 
        where co.role == "chief_occupant" && reviewedNics.indexOf(co.nic) is ()
        select co;
    
    // 5. Count pending: Household Members with role "household_member" who are NOT reviewed
    stream<store:HouseholdMembers, persist:Error?> memberStream = dbClient->/householdmembers;
    store:HouseholdMembers[] pendingMembers = check from store:HouseholdMembers hm in memberStream 
        where hm.role == "household_member" && hm.nic is string && reviewedNics.indexOf(<string>hm.nic) is ()
        select hm;
    
    int pending = pendingChiefs.length() + pendingMembers.length();
    
    // 6. Calculate total
    int total = pending + approved + rejected;

    return {
        pending: pending,
        approved: approved,
        rejected: rejected,
        total: total
    };
}


// Function to get detailed registration information by NIC
public function getRegistrationDetailByNic(string nic) returns RegistrationDetail|error {
    
    // Get status from RegistrationReview table
    stream<store:RegistrationReview, persist:Error?> reviewStream = dbClient->/registrationreviews;
    store:RegistrationReview[] reviews = check from store:RegistrationReview review in reviewStream
        where review.memberNic == nic
        select review;
    
    string status = "pending"; 
    if reviews.length() > 0 {
        status = reviews[0].status;
    }

    // 1. First try to find in Chief Occupants
    stream<store:ChiefOccupant, persist:Error?> chiefStream = dbClient->/chiefoccupants;
    store:ChiefOccupant[] matchedChief = check from store:ChiefOccupant co in chiefStream 
        where co.nic == nic && co.role == "chief_occupant"
        select co;

    if matchedChief.length() > 0 {
        store:ChiefOccupant chief = matchedChief[0];
        
        // Get household details for this chief
        stream<store:HouseholdDetails, persist:Error?> hhDetailsStream = dbClient->/householddetails;
        store:HouseholdDetails[] householdDetails = check from store:HouseholdDetails hd in hhDetailsStream
            where hd.chiefOccupantId == chief.id
            select hd;
            
        if householdDetails.length() > 0 {
            store:HouseholdDetails hh = householdDetails[0];
            
            return {
                fullName: chief.fullName,
                nic: chief.nic,
                dob: chief.dob,
                phone: chief.phoneNumber,
                gender: chief.gender,
                civilStatus: chief.civilStatus,
                electoralDistrict: hh.electoralDistrict,
                pollingDivision: hh.pollingDivision,
                pollingDistrictNumber: hh.pollingDistrictNumber,
                gramaNiladhariDivision: hh.gramaNiladhariDivision,
                village: hh.villageStreetEstate,
                houseNumber: hh.houseNumber,
                address: "-",
                status: status,
                idCopyPath: chief.idCopyPath,
                photoCopyPath: chief.photoCopyPath,
                role: chief.role
            };
        } else {
            // Chief found but no household details
            return {
                fullName: chief.fullName,
                nic: chief.nic,
                dob: chief.dob,
                phone: chief.phoneNumber,
                gender: chief.gender,
                civilStatus: chief.civilStatus,
                electoralDistrict: "-",
                pollingDivision: "-",
                pollingDistrictNumber: "-",
                gramaNiladhariDivision: (),
                village: (),
                houseNumber: (),
                address: "-",
                status: status,
                idCopyPath: chief.idCopyPath,
                photoCopyPath: chief.photoCopyPath,
                role: chief.role
            };
        }
    }

    // 2. If not found in chiefs, try household members
    stream<store:HouseholdMembers, persist:Error?> memberStream = dbClient->/householdmembers;
    store:HouseholdMembers[] matchedMembers = check from store:HouseholdMembers hm in memberStream 
        where hm.nic == nic && hm.role == "household_member"
        select hm;

    if matchedMembers.length() > 0 {
        store:HouseholdMembers member = matchedMembers[0];
        
        // Get household details for this member's chief occupant
        stream<store:HouseholdDetails, persist:Error?> hhDetailsStream = dbClient->/householddetails;
        store:HouseholdDetails[] householdDetails = check from store:HouseholdDetails hd in hhDetailsStream
            where hd.chiefOccupantId == member.chiefOccupantId
            select hd;
            
        if householdDetails.length() > 0 {
            store:HouseholdDetails hh = householdDetails[0];
            
            return {
                fullName: member.fullName,
                nic: <string>member.nic,
                dob: member.dob,
                phone: (), 
                gender: member.gender,
                civilStatus: member.civilStatus,
                electoralDistrict: hh.electoralDistrict,
                pollingDivision: hh.pollingDivision,
                pollingDistrictNumber: hh.pollingDistrictNumber,
                gramaNiladhariDivision: hh.gramaNiladhariDivision,
                village: hh.villageStreetEstate,
                houseNumber: hh.houseNumber,
                address: "-",
                status: status,
                idCopyPath: member.idCopyPath,
                photoCopyPath: member.photoCopyPath,
                role: member.role
            };
        } else {
            // Member found but no household details
            return {
                fullName: member.fullName,
                nic: <string>member.nic,
                dob: member.dob,
                phone: (), 
                gender: member.gender,
                civilStatus: member.civilStatus,
                electoralDistrict: "-",
                pollingDivision: "-",
                pollingDistrictNumber: "-",
                gramaNiladhariDivision: (),
                village: (),
                houseNumber: (),
                address: "-",
                status: status,
                idCopyPath: member.idCopyPath,
                photoCopyPath: member.photoCopyPath,
                role: member.role
            };
        }
    }

    // 3. If NIC not found in either table, return error
    return error("Registration not found for NIC: " + nic);
}

// Function to approve registration
public function approveRegistration(string nic) returns string|error {
    // Start transaction to ensure data consistency
    transaction {
        // 1. Insert/Update RegistrationReview table
        store:RegistrationReview reviewRecord = {
            id: uuid:createType1AsString(),
            memberNic: nic,
            status: "approved",
            reason: (),
            reviewedAt: time:utcNow()
        };
        
        // Check if review already exists
        stream<store:RegistrationReview, persist:Error?> existingReviewStream = dbClient->/registrationreviews;
        store:RegistrationReview[] existingReviews = check from store:RegistrationReview review in existingReviewStream
            where review.memberNic == nic
            select review;
        
        if existingReviews.length() > 0 {
            // Update existing record
            _ = check dbClient->/registrationreviews/[existingReviews[0].id].put({
                memberNic: nic,
                status: "approved",
                reason: (),
                reviewedAt: time:utcNow()
            });
        } else {
            // Insert new record
            _ = check dbClient->/registrationreviews.post([reviewRecord]);
        }

        // 2. Get user details to add to Voter table
        RegistrationDetail userDetail = check getRegistrationDetailByNic(nic);
        
        // 3. Get password from ChiefOccupant or HouseholdMembers table in single query
        string userPassword = "";
        store:ChiefOccupant? matchedChief = ();
        store:HouseholdMembers? matchedMember = ();
        
        // Combined query to find user in both tables
        stream<store:ChiefOccupant, persist:Error?> chiefStream = dbClient->/chiefoccupants;
        store:ChiefOccupant[] chiefs = check from store:ChiefOccupant co in chiefStream 
            where co.nic == nic && co.role == "chief_occupant"
            select co;

        if chiefs.length() > 0 {
            matchedChief = chiefs[0];
            userPassword = chiefs[0].passwordHash;
        } else {
            // If not found in chiefs, try household members
            stream<store:HouseholdMembers, persist:Error?> memberStream = dbClient->/householdmembers;
            store:HouseholdMembers[] members = check from store:HouseholdMembers hm in memberStream 
                where hm.nic == nic && hm.role == "household_member"
                select hm;

            if members.length() > 0 {
                matchedMember = members[0];
                userPassword = members[0].passwordHash;
            } else {
                check commit;
                return error("User not found for NIC: " + nic);
            }
        }
        
        // 4. Check if voter already exists before creating new record
        stream<store:Voter, persist:Error?> existingVoterStream = dbClient->/voters;
        store:Voter[] existingVoters = check from store:Voter voter in existingVoterStream
            where voter.nationalId == nic
            select voter;
        
        // Only add to Voter table if doesn't exist
        if existingVoters.length() == 0 {
            store:Voter voterRecord = {
                id: uuid:createType1AsString(),
                nationalId: nic,
                name: userDetail.fullName,
                password: userPassword, 
                district: userDetail.electoralDistrict,
                pollingStation: userDetail.pollingDivision,
                registrationDate: time:utcToCivil(time:utcNow()),
                status: "Active"
            };
            _ = check dbClient->/voters.post([voterRecord]);
        }

        // 5. Update role using already retrieved data (avoid duplicate queries)
        if matchedChief is store:ChiefOccupant {
            // Update ChiefOccupant role
            _ = check dbClient->/chiefoccupants/[matchedChief.id].put({
                fullName: matchedChief.fullName,
                nic: matchedChief.nic,
                phoneNumber: matchedChief.phoneNumber,
                dob: matchedChief.dob,
                gender: matchedChief.gender,
                civilStatus: matchedChief.civilStatus,
                passwordHash: matchedChief.passwordHash,
                email: matchedChief.email,
                idCopyPath: matchedChief.idCopyPath,
                photoCopyPath: matchedChief.photoCopyPath,
                role: "verified_chief_occupant"
            });
        } else if matchedMember is store:HouseholdMembers {
            // Update HouseholdMember role
            _ = check dbClient->/householdmembers/[matchedMember.id].put({
                chiefOccupantId: matchedMember.chiefOccupantId,
                fullName: matchedMember.fullName,
                nic: matchedMember.nic,
                dob: matchedMember.dob,
                gender: matchedMember.gender,
                civilStatus: matchedMember.civilStatus,
                relationshipWithChiefOccupant: matchedMember.relationshipWithChiefOccupant,
                idCopyPath: matchedMember.idCopyPath,
                photoCopyPath: matchedMember.photoCopyPath,
                approvedByChief: matchedMember.approvedByChief,
                passwordHash: matchedMember.passwordHash,
                passwordchanged: matchedMember.passwordchanged,
                role: "verified_household_member"
            });
        }
        
        return "Registration approved successfully";
    } on fail error e {
        return error("Failed to approve registration: " + e.message());
    }
}

// Function to reject registration
public function rejectRegistration(string nic, string reason) returns string|error {
    // First verify the user exists before starting transaction
    RegistrationDetail|error userDetailResult = getRegistrationDetailByNic(nic);
    if userDetailResult is error {
        return error("User not found for NIC: " + nic);
    }
    
    // Start transaction to ensure data consistency
    transaction {
        // Check if review already exists
        stream<store:RegistrationReview, persist:Error?> existingReviewStream = dbClient->/registrationreviews;
        store:RegistrationReview[] existingReviews = check from store:RegistrationReview review in existingReviewStream
            where review.memberNic == nic
            select review;
        
        if existingReviews.length() > 0 {
            // Update existing record
            store:RegistrationReviewUpdate updateRecord = {
                memberNic: nic,
                status: "rejected",
                reason: reason,
                reviewedAt: time:utcNow()
            };
            _ = check dbClient->/registrationreviews/[existingReviews[0].id].put(updateRecord);
        } else {
            // Insert new record
            store:RegistrationReview reviewRecord = {
                id: uuid:createType1AsString(),
                memberNic: nic,
                status: "rejected",
                reason: reason,
                reviewedAt: time:utcNow()
            };
            _ = check dbClient->/registrationreviews.post([reviewRecord]);
        }
        
        check commit;
        return "Registration rejected successfully";
        
    } on fail error e {
        return error("Failed to reject registration: " + e.message());
    }
}


//DELETE MEMBER REQUESTS

public function getRemovalRequests(string? search, string? status) returns RemovalRequest[]|error {
    
    // 1. Fetch all DeleteMemberRequest records
    stream<store:DeleteMemberRequest, persist:Error?> deleteRequestStream = dbClient->/deletememberrequests;
    store:DeleteMemberRequest[] deleteRequests = check from store:DeleteMemberRequest dmr in deleteRequestStream
        select dmr;

    // 2. Fetch all ChiefOccupants into map for efficient lookup BY ID
    stream<store:ChiefOccupant, persist:Error?> chiefStream = dbClient->/chiefoccupants;
    map<store:ChiefOccupant> chiefMapById = {};
    check from store:ChiefOccupant co in chiefStream
        do {
            chiefMapById[co.id] = co;
        };

    // 3. Fetch all HouseholdMembers into map for efficient lookup BY ID
    stream<store:HouseholdMembers, persist:Error?> memberStream = dbClient->/householdmembers;
    map<store:HouseholdMembers> memberMapById = {};
    check from store:HouseholdMembers hm in memberStream
        do {
            memberMapById[hm.id] = hm;
        };

    // 4. Build removal request list
    RemovalRequest[] removalRequests = [];
    
    foreach var deleteRequest in deleteRequests {
        // Get household member details using household_member_id
        string memberName = "Unknown Member";
        string memberNic = "Unknown NIC";
        
        if deleteRequest.householdMemberId is string && deleteRequest.householdMemberId != "" {
            string memberIdValue = <string>deleteRequest.householdMemberId;
            if memberMapById.hasKey(memberIdValue) {
                store:HouseholdMembers member = memberMapById.get(memberIdValue);
                memberName = member.fullName;
                memberNic = member.nic ?: "No NIC";
            }
        }

        // Get chief occupant details using chief_occupant_id
        string requestedBy = "Unknown Requester";
        string requestedByNic = "Unknown NIC";
        
        if chiefMapById.hasKey(deleteRequest.chiefOccupantId) {
            store:ChiefOccupant chief = chiefMapById.get(deleteRequest.chiefOccupantId);
            requestedBy = chief.fullName;
            requestedByNic = chief.nic;
        }

        // Determine status (default to pending if null or empty)
        string requestStatus = "pending";
        if deleteRequest.requestStatus is string && deleteRequest.requestStatus != "" {
            requestStatus = <string>deleteRequest.requestStatus;
        }

        // Create removal request object
        RemovalRequest removalReq = {
            deleteRequestId: deleteRequest.deleteRequestId,
            memberName: memberName,
            memberNic: memberNic,
            requestedBy: requestedBy,
            requestedByNic: requestedByNic,
            reason: deleteRequest.reason ?: "No reason provided",
            proofDocument: deleteRequest.requiredDocumentPath,
            submittedDate: "2024-01-15", 
            status: requestStatus
        };

        removalRequests.push(removalReq);
    }

    // 5. Apply filters if provided
    RemovalRequest[] filteredRequests = removalRequests;
    
    // Filter by search term (member name, member NIC, or requester name)
    if search is string && search.trim() != "" {
        string searchTerm = string:toLowerAscii(search.trim());
        filteredRequests = from var req in filteredRequests
            where string:toLowerAscii(req.memberName).includes(searchTerm) || 
                  string:toLowerAscii(req.memberNic).includes(searchTerm) ||
                  string:toLowerAscii(req.requestedBy).includes(searchTerm)
            select req;
    }

    // Filter by status
    if status is string && status != "all" {
        string statusTerm = string:toLowerAscii(status);
        filteredRequests = from var req in filteredRequests
            where string:toLowerAscii(req.status) == statusTerm
            select req;
    }

    return filteredRequests;
}

// Function to get removal request counts by status
public function getRemovalRequestCounts() returns RemovalRequestCounts|error {
    // Get all removal requests without any filters
    RemovalRequest[] allRequests = check getRemovalRequests((), ());
    
    int pending = 0;
    int approved = 0;
    int rejected = 0;

    // Count requests by status
    foreach var req in allRequests {
        match req.status {
            "pending" => { pending += 1; }
            "approved" => { approved += 1; }
            "rejected" => { rejected += 1; }
        }
    }

    return {
        pending: pending,
        approved: approved,
        rejected: rejected,
        total: allRequests.length()
    };
}

// Function to approve removal request

public function approveRemovalRequest(string deleteRequestId) returns string|error {
    // Start transaction to ensure data consistency
    transaction {
        // 1. Get the removal request details
        stream<store:DeleteMemberRequest, persist:Error?> deleteRequestStream = dbClient->/deletememberrequests;
        store:DeleteMemberRequest[] deleteRequests = check from store:DeleteMemberRequest dmr in deleteRequestStream
            where dmr.deleteRequestId == deleteRequestId
            select dmr;

        if deleteRequests.length() == 0 {
            check commit;
            return error("Removal request not found for ID: " + deleteRequestId);
        }

        store:DeleteMemberRequest deleteRequest = deleteRequests[0];

        // 2. Update DeleteMemberRequest status to "approved" and clear reason
        _ = check dbClient->/deletememberrequests/[deleteRequestId].put({
            chiefOccupantId: deleteRequest.chiefOccupantId,
            householdMemberId: deleteRequest.householdMemberId,
            requestStatus: "approved",
            reason: deleteRequest.reason,
            requiredDocumentPath: deleteRequest.requiredDocumentPath,
            rejectionReason: deleteRequest.rejectionReason
        });

        // 3. Get household member details using household_member_id
        if deleteRequest.householdMemberId is string && deleteRequest.householdMemberId != "" {
            string memberIdValue = <string>deleteRequest.householdMemberId;
            
            // Get household member details by ID
            stream<store:HouseholdMembers, persist:Error?> memberStream = dbClient->/householdmembers;
            store:HouseholdMembers[] members = check from store:HouseholdMembers hm in memberStream
                where hm.id == memberIdValue
                select hm;

            if members.length() > 0 {
                store:HouseholdMembers member = members[0];

                // 4. Delete from Voter table using member's NIC
                if member.nic is string && member.nic != "" {
                    stream<store:Voter, persist:Error?> voterStream = dbClient->/voters;
                    store:Voter[] voters = check from store:Voter v in voterStream
                        where v.nationalId == <string>member.nic
                        select v;

                    foreach var voter in voters {
                        _ = check dbClient->/voters/[voter.id].delete();
                    }
                }

                // 5. Delete the household member record using the member's ID
                _ = check dbClient->/householdmembers/[member.id].delete();

                // 6. Update household member count in HouseholdDetails using chief occupant ID
                stream<store:HouseholdDetails, persist:Error?> hhDetailsStream = dbClient->/householddetails;
                store:HouseholdDetails[] householdDetails = check from store:HouseholdDetails hd in hhDetailsStream
                    where hd.chiefOccupantId == deleteRequest.chiefOccupantId
                    select hd;

                if householdDetails.length() > 0 {
                    store:HouseholdDetails hh = householdDetails[0];
                    int newMemberCount = hh.householdMemberCount > 0 ? hh.householdMemberCount - 1 : 0;
                    
                    _ = check dbClient->/householddetails/[hh.id].put({
                        chiefOccupantId: hh.chiefOccupantId,
                        electoralDistrict: hh.electoralDistrict,
                        pollingDivision: hh.pollingDivision,
                        pollingDistrictNumber: hh.pollingDistrictNumber,
                        gramaNiladhariDivision: hh.gramaNiladhariDivision,
                        villageStreetEstate: hh.villageStreetEstate,
                        houseNumber: hh.houseNumber,
                        householdMemberCount: newMemberCount
                    });
                }
            } else {
                return error("Household member not found for ID: " + memberIdValue);
            }
        } else {
            return error("No household member ID provided in removal request");
        }
    } on fail error e {
        return error("Failed to approve removal request: " + e.message());
    }
    
    return "Removal request approved successfully and member removed from all systems";
}

// Function to reject removal request
public function rejectRemovalRequest(string deleteRequestId, string rejectionReason) returns string|error {
    // Start transaction to ensure data consistency
    transaction {
        // 1. Get the removal request details
        stream<store:DeleteMemberRequest, persist:Error?> deleteRequestStream = dbClient->/deletememberrequests;
        store:DeleteMemberRequest[] deleteRequests = check from store:DeleteMemberRequest dmr in deleteRequestStream
            where dmr.deleteRequestId == deleteRequestId
            select dmr;

        if deleteRequests.length() == 0 {
            check commit;
            return error("Removal request not found for ID: " + deleteRequestId);
        }

        store:DeleteMemberRequest deleteRequest = deleteRequests[0];

        // 2. Update DeleteMemberRequest status to "rejected" with rejection reason
        _ = check dbClient->/deletememberrequests/[deleteRequestId].put({
            chiefOccupantId: deleteRequest.chiefOccupantId,
            householdMemberId: deleteRequest.householdMemberId,
            requestStatus: "rejected",
            reason: deleteRequest.reason,
            requiredDocumentPath: deleteRequest.requiredDocumentPath,
            rejectionReason: rejectionReason 
        });

        return "Removal request rejected successfully";
    } on fail error e {
        return error("Failed to reject removal request: " + e.message());
    }
}


//ADD MEMEBER REQUESTS

// Get all add member requests with optional filtering
public function getAddMemberRequests(string? search, string? status) returns AddMemberRequestResponse[]|error {
    
    // Fetch all AddMemberRequest records
    stream<store:AddMemberRequest, persist:Error?> addRequestStream = dbClient->/addmemberrequests;
    store:AddMemberRequest[] addRequests = check from store:AddMemberRequest amr in addRequestStream
        select amr;
    
    // Build response list
    AddMemberRequestResponse[] responses = [];
    
    foreach var addRequest in addRequests {
        // Determine status 
        string requestStatus = "pending";
        if addRequest.requestStatus != "" {
            requestStatus = addRequest.requestStatus;
        }
        
        AddMemberRequestResponse response = {
            addRequestId: addRequest.addRequestId,
            fullName: addRequest.fullName,
            nicNumber: addRequest.nicNumber,
            dateOfBirth: addRequest.dateOfBirth,
            gender: addRequest.gender,
            relationshipToChief: addRequest.relationshipToChief,
            requestStatus: requestStatus,
            reason: addRequest.reason
        };
        
        responses.push(response);
    }
    
    // Apply filters if provided
    AddMemberRequestResponse[] filteredResponses = responses;
    
    // Filter by search term (name or NIC)
    if search is string && search.trim() != "" {
        string searchTerm = string:toLowerAscii(search.trim());
        filteredResponses = from var resp in filteredResponses
            where string:toLowerAscii(resp.fullName).includes(searchTerm) || 
                  string:toLowerAscii(resp.nicNumber).includes(searchTerm)
            select resp;
    }
    
    // Filter by status
    if status is string && status != "all" {
        string statusTerm = string:toLowerAscii(status);
        filteredResponses = from var resp in filteredResponses
            where string:toLowerAscii(resp.requestStatus) == statusTerm
            select resp;
    }
    
    return filteredResponses;
}

// Get add member request counts by status
public function getAddMemberRequestCounts() returns AddMemberRequestCounts|error {
    // Get all add member requests without any filters
    AddMemberRequestResponse[] allRequests = check getAddMemberRequests((), ());
    
    int pending = 0;
    int approved = 0;
    int rejected = 0;
    
    // Count requests by status
    foreach var req in allRequests {
        match req.requestStatus {
            "pending" => { pending += 1; }
            "approved" => { approved += 1; }
            "rejected" => { rejected += 1; }
        }
    }
    
    return {
        pending: pending,
        approved: approved,
        rejected: rejected,
        total: allRequests.length()
    };
}

// Get detailed information for a specific add member request
public function getAddMemberRequestDetail(string addRequestId) returns AddMemberRequestDetail|error {
    
    // Get the add member request
    stream<store:AddMemberRequest, persist:Error?> addRequestStream = dbClient->/addmemberrequests;
    store:AddMemberRequest[] addRequests = check from store:AddMemberRequest amr in addRequestStream
        where amr.addRequestId == addRequestId
        select amr;
    
    if addRequests.length() == 0 {
        return error("Add member request not found for ID: " + addRequestId);
    }
    
    store:AddMemberRequest addRequest = addRequests[0];
    
    // Get chief occupant details
    stream<store:ChiefOccupant, persist:Error?> chiefStream = dbClient->/chiefoccupants;
    store:ChiefOccupant[] chiefOccupants = check from store:ChiefOccupant co in chiefStream
        where co.id == addRequest.chiefOccupantId
        select co;
    
    store:ChiefOccupant? chiefOccupant = chiefOccupants.length() > 0 ? chiefOccupants[0] : ();
    
    // Get household details
    stream<store:HouseholdDetails, persist:Error?> householdStream = dbClient->/householddetails;
    store:HouseholdDetails[] householdDetails = check from store:HouseholdDetails hd in householdStream
        where hd.chiefOccupantId == addRequest.chiefOccupantId
        select hd;
    
    store:HouseholdDetails? householdDetail = householdDetails.length() > 0 ? householdDetails[0] : ();
    
    return {
        request: addRequest,
        chiefOccupant: chiefOccupant,
        householdDetails: householdDetail
    };
}

// Approve add member request
public function approveAddMemberRequest(string addRequestId) returns string|error {
    
    transaction {
        // Get the add member request details
        stream<store:AddMemberRequest, persist:Error?> addRequestStream = dbClient->/addmemberrequests;
        store:AddMemberRequest[] addRequests = check from store:AddMemberRequest amr in addRequestStream
            where amr.addRequestId == addRequestId
            select amr;
        
        if addRequests.length() == 0 {
            check commit;
            return error("Add member request not found for ID: " + addRequestId);
        }
        
        store:AddMemberRequest addRequest = addRequests[0];
        
        
        _ = check dbClient->/addmemberrequests/[addRequestId].put({
            chiefOccupantId: addRequest.chiefOccupantId,
            nicNumber: addRequest.nicNumber,
            fullName: addRequest.fullName,
            dateOfBirth: addRequest.dateOfBirth,
            gender: addRequest.gender,
            civilStatus: addRequest.civilStatus,
            relationshipToChief: addRequest.relationshipToChief,
            chiefOccupantApproval: addRequest.chiefOccupantApproval,
            requestStatus: "approved",
            reason: (), 
            nicOrBirthCertificatePath: addRequest.nicOrBirthCertificatePath,
            photoCopyPath: addRequest.photoCopyPath
        });
        
        // Generate unique ID for household member
        string householdMemberId = uuid:createType1AsString();
        
        // Add to HouseholdMembers table
        store:HouseholdMembers newHouseholdMember = {
            id: householdMemberId,
            chiefOccupantId: addRequest.chiefOccupantId,
            fullName: addRequest.fullName,
            nic: addRequest.nicNumber,
            dob: addRequest.dateOfBirth,
            gender: addRequest.gender,
            civilStatus: addRequest.civilStatus,
            relationshipWithChiefOccupant: addRequest.relationshipToChief,
            idCopyPath: addRequest.nicOrBirthCertificatePath,
            photoCopyPath: addRequest.photoCopyPath,
            approvedByChief: true,
            passwordHash: "", 
            passwordchanged: false,
            role: "verified_household_member"
        };
        
        _ = check dbClient->/householdmembers.post([newHouseholdMember]);
        
        // Generate unique ID for voter
        string voterId = uuid:createType1AsString();
        
        // Get household details for district and polling station info
        stream<store:HouseholdDetails, persist:Error?> householdStream = dbClient->/householddetails;
        store:HouseholdDetails[] householdDetails = check from store:HouseholdDetails hd in householdStream
            where hd.chiefOccupantId == addRequest.chiefOccupantId
            select hd;
        
        string district = "Unknown";
        string pollingStation = "Unknown";
        
        if householdDetails.length() > 0 {
            store:HouseholdDetails hh = householdDetails[0];
            district = hh.electoralDistrict;
            pollingStation = hh.pollingDivision;
            
            // Update household member count
            int newMemberCount = hh.householdMemberCount + 1;
            _ = check dbClient->/householddetails/[hh.id].put({
                chiefOccupantId: hh.chiefOccupantId,
                electoralDistrict: hh.electoralDistrict,
                pollingDivision: hh.pollingDivision,
                pollingDistrictNumber: hh.pollingDistrictNumber,
                gramaNiladhariDivision: hh.gramaNiladhariDivision,
                villageStreetEstate: hh.villageStreetEstate,
                houseNumber: hh.houseNumber,
                householdMemberCount: newMemberCount
            });
        }
        
        // Add to Voter table
        store:Voter newVoter = {
            id: voterId,
            nationalId: addRequest.nicNumber,
            name: addRequest.fullName,
            password: "", 
            district: district,
            pollingStation: pollingStation,
            registrationDate: {year: 2024, month: 1, day: 1}, 
            status: "Active"
        };
        
        _ = check dbClient->/voters.post([newVoter]);
        
    } on fail error e {
        return error("Failed to approve add member request: " + e.message());
    }
    
    return "Add member request approved successfully and member added to all systems";
}

// Reject add member request
public function rejectAddMemberRequest(string addRequestId, string rejectionReason) returns string|error {
    
    transaction {
        // Get the add member request details
        stream<store:AddMemberRequest, persist:Error?> addRequestStream = dbClient->/addmemberrequests;
        store:AddMemberRequest[] addRequests = check from store:AddMemberRequest amr in addRequestStream
            where amr.addRequestId == addRequestId
            select amr;
        
        if addRequests.length() == 0 {
            check commit;
            return error("Add member request not found for ID: " + addRequestId);
        }
        
        store:AddMemberRequest addRequest = addRequests[0];
        
        _ = check dbClient->/addmemberrequests/[addRequestId].put({
            chiefOccupantId: addRequest.chiefOccupantId,
            nicNumber: addRequest.nicNumber,
            fullName: addRequest.fullName,
            dateOfBirth: addRequest.dateOfBirth,
            gender: addRequest.gender,
            civilStatus: addRequest.civilStatus,
            relationshipToChief: addRequest.relationshipToChief,
            chiefOccupantApproval: addRequest.chiefOccupantApproval,
            requestStatus: "rejected",
            reason: rejectionReason, 
            nicOrBirthCertificatePath: addRequest.nicOrBirthCertificatePath,
            photoCopyPath: addRequest.photoCopyPath
        });
        
        return "Add member request rejected successfully";
    } on fail error e {
        return error("Failed to reject add member request: " + e.message());
    }
}