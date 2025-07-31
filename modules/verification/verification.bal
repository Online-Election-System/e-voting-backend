import ballerina/persist;
import codeCrew/online_election.store;
import ballerina/time;
import ballerina/uuid;

final store:Client dbClient = check new ();

// ----- Business Logic Functions -----

// Add these types to your model.bal or at the top of verification.bal

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
        string address = "-";
        if hhDetailsMap.hasKey(chief.id) {
            store:HouseholdDetails hh = hhDetailsMap.get(chief.id);
            string houseNum = hh.houseNumber is string ? <string>hh.houseNumber : "";
            string village = hh.villageStreetEstate is string ? <string>hh.villageStreetEstate : "";
            string district = hh.electoralDistrict;
            
            // Create a meaningful address string
            string[] addressParts = [];
            if houseNum != "" {
                addressParts.push(houseNum);
            }
            if village != "" {
                addressParts.push(village);
            }
            if district != "" {
                addressParts.push(district);
            }
            
            address = addressParts.length() > 0 ? string:'join(", ", ...addressParts) : "-";
        }

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
            address: address,
            status: status
        });
    }

    // Process Household Members
    foreach var member in members {
        // Only process members with NIC (some might not have NIC)
        if member.nic is string && member.nic != "" {
            string address = "-";
            if hhDetailsMap.hasKey(member.chiefOccupantId) {
                store:HouseholdDetails hh = hhDetailsMap.get(member.chiefOccupantId);
                string houseNum = hh.houseNumber is string ? <string>hh.houseNumber : "";
                string village = hh.villageStreetEstate is string ? <string>hh.villageStreetEstate : "";
                string district = hh.electoralDistrict;
                
                // Create a meaningful address string
                string[] addressParts = [];
                if houseNum != "" {
                    addressParts.push(houseNum);
                }
                if village != "" {
                    addressParts.push(village);
                }
                if district != "" {
                    addressParts.push(district);
                }
                
                address = addressParts.length() > 0 ? string:'join(", ", ...addressParts) : "-";
            }

            // Get status from RegistrationReview table or default to "pending"
            string status = "pending";
            if reviewMap.hasKey(<string>member.nic) {
                status = reviewMap.get(<string>member.nic).status;
            }

            applications.push({
                fullName: member.fullName,
                nic: <string>member.nic,
                dob: member.dob,
                phone: (), // Household members don't have phone numbers
                address: address,
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
    // Get all applications without any filters
    RegistrationApplication[] allApps = check getRegistrationApplications((), ());
    
    int pending = 0;
    int approved = 0;
    int rejected = 0;

    // Count applications by status
    foreach var app in allApps {
        match app.status {
            "pending" => { pending += 1; }
            "approved" => { approved += 1; }
            "rejected" => { rejected += 1; }
        }
    }

    return {
        pending: pending,
        approved: approved,
        rejected: rejected,
        total: allApps.length()
    };
}

// NEW FUNCTION: Get detailed registration information by NIC
// Function to get detailed registration information by NIC
public function getRegistrationDetailByNic(string nic) returns RegistrationDetail|error {
    
    // Get status from RegistrationReview table
    stream<store:RegistrationReview, persist:Error?> reviewStream = dbClient->/registrationreviews;
    store:RegistrationReview[] reviews = check from store:RegistrationReview review in reviewStream
        where review.memberNic == nic
        select review;
    
    string status = "pending"; // Default status
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
            
            // Build address
            string[] addressParts = [];
            if hh.houseNumber is string && <string>hh.houseNumber != "" {
                addressParts.push(<string>hh.houseNumber);
            }
            if hh.villageStreetEstate is string && <string>hh.villageStreetEstate != "" {
                addressParts.push(<string>hh.villageStreetEstate);
            }
            if hh.electoralDistrict != "" {
                addressParts.push(hh.electoralDistrict);
            }
            string address = addressParts.length() > 0 ? string:'join(", ", ...addressParts) : "-";
            
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
                address: address,
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
            
            // Build address
            string[] addressParts = [];
            if hh.houseNumber is string && <string>hh.houseNumber != "" {
                addressParts.push(<string>hh.houseNumber);
            }
            if hh.villageStreetEstate is string && <string>hh.villageStreetEstate != "" {
                addressParts.push(<string>hh.villageStreetEstate);
            }
            if hh.electoralDistrict != "" {
                addressParts.push(hh.electoralDistrict);
            }
            string address = addressParts.length() > 0 ? string:'join(", ", ...addressParts) : "-";
            
            return {
                fullName: member.fullName,
                nic: <string>member.nic,
                dob: member.dob,
                phone: (), // Household members don't have phone numbers
                gender: member.gender,
                civilStatus: member.civilStatus,
                electoralDistrict: hh.electoralDistrict,
                pollingDivision: hh.pollingDivision,
                pollingDistrictNumber: hh.pollingDistrictNumber,
                gramaNiladhariDivision: hh.gramaNiladhariDivision,
                village: hh.villageStreetEstate,
                houseNumber: hh.houseNumber,
                address: address,
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
                phone: (), // Household members don't have phone numbers
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
        
        // 3. Get password from ChiefOccupant or HouseholdMembers table
        string userPassword = "";
        
        // First try to find in Chief Occupants
        stream<store:ChiefOccupant, persist:Error?> chiefStream = dbClient->/chiefoccupants;
        store:ChiefOccupant[] matchedChief = check from store:ChiefOccupant co in chiefStream 
            where co.nic == nic && co.role == "chief_occupant"
            select co;

        if matchedChief.length() > 0 {
            userPassword = matchedChief[0].passwordHash;
        } else {
            // If not found in chiefs, try household members
            stream<store:HouseholdMembers, persist:Error?> memberStream = dbClient->/householdmembers;
            store:HouseholdMembers[] matchedMembers = check from store:HouseholdMembers hm in memberStream 
                where hm.nic == nic && hm.role == "household_member"
                select hm;

            if matchedMembers.length() > 0 {
                userPassword = matchedMembers[0].passwordHash;
            } else {
                check commit;
                return error("User not found for NIC: " + nic);
            }
        }
        
        // 4. Add to Voter table with the retrieved password
        store:Voter voterRecord = {
            id: uuid:createType1AsString(),
            nationalId: nic,
            name: userDetail.fullName,
            password: userPassword, // Now using the actual password from the user's record
            district: userDetail.electoralDistrict,
            pollingStation: userDetail.pollingDivision,
            registrationDate: time:utcToCivil(time:utcNow()),
            status: "Active"
        };
        
        // Check if voter already exists
        stream<store:Voter, persist:Error?> existingVoterStream = dbClient->/voters;
        store:Voter[] existingVoters = check from store:Voter voter in existingVoterStream
            where voter.nationalId == nic
            select voter;
        
        if existingVoters.length() == 0 {
            _ = check dbClient->/voters.post([voterRecord]);
        }

        // 5. Update role in ChiefOccupant or HouseholdMembers table
        // Try ChiefOccupant first
        stream<store:ChiefOccupant, persist:Error?> chiefStreamForUpdate = dbClient->/chiefoccupants;
        store:ChiefOccupant[] matchedChiefsForUpdate = check from store:ChiefOccupant co in chiefStreamForUpdate 
            where co.nic == nic && co.role == "chief_occupant"
            select co;

        if matchedChiefsForUpdate.length() > 0 {
            // Update ChiefOccupant role
            store:ChiefOccupant chief = matchedChiefsForUpdate[0];
            _ = check dbClient->/chiefoccupants/[chief.id].put({
                fullName: chief.fullName,
                nic: chief.nic,
                phoneNumber: chief.phoneNumber,
                dob: chief.dob,
                gender: chief.gender,
                civilStatus: chief.civilStatus,
                passwordHash: chief.passwordHash,
                email: chief.email,
                idCopyPath: chief.idCopyPath,
                photoCopyPath: chief.photoCopyPath,
                role: "verified_chief_occupant"
            });
        } else {
           // Try HouseholdMembers
            stream<store:HouseholdMembers, persist:Error?> memberStreamForUpdate = dbClient->/householdmembers;
            store:HouseholdMembers[] matchedMembersForUpdate = check from store:HouseholdMembers hm in memberStreamForUpdate 
                where hm.nic == nic && hm.role == "household_member"
                select hm;

            if matchedMembersForUpdate.length() > 0 {
                // Update HouseholdMember role
                store:HouseholdMembers member = matchedMembersForUpdate[0];
                _ = check dbClient->/householdmembers/[member.id].put({
                    chiefOccupantId: member.chiefOccupantId,
                    fullName: member.fullName,
                    nic: member.nic,
                    dob: member.dob,
                    gender: member.gender,
                    civilStatus: member.civilStatus,
                    relationshipWithChiefOccupant: member.relationshipWithChiefOccupant,
                    idCopyPath: member.idCopyPath,
                    photoCopyPath: member.photoCopyPath,
                    approvedByChief: member.approvedByChief,
                    passwordHash: member.passwordHash,
                    passwordchanged: member.passwordchanged,
                    role: "verified_household_member"
                });
            } else {
                return error("User not found for NIC: " + nic);
            }
        }
        return "Registration approved successfully";
    } on fail error e {
        return error("Failed to approve registration: " + e.message());
    }
}

// Function to reject registration
// verification.bal
public function rejectRegistration(string nic, string reason) returns string|error {
    // First verify the user exists before starting transaction
    RegistrationDetail|error userDetailResult = getRegistrationDetailByNic(nic);
    if userDetailResult is error {
        return error("User not found for NIC: " + nic);
    }
    
    // Start transaction to ensure data consistency
    transaction {
        do {
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
            
            // Commit the transaction
            check commit;
            return "Registration rejected successfully";
            
        } on fail error e {
            // Rollback will happen automatically
            return error("Failed to reject registration: " + e.message());
        }
    }
}


