import online_election.candidate;
import online_election.common;
import online_election.store;

import ballerina/http;
import ballerina/log;
import ballerina/persist;
import ballerina/time;

final store:Client dbElection = check new ();

public function getElections() returns ElectionWithCandidates[]|error {
    stream<store:Election, persist:Error?> electionStream = dbElection->/elections;
    store:Election[] elections = check from store:Election election in electionStream
        select election;

    // Convert each election to ElectionWithCandidates with enrolled candidate details
    ElectionWithCandidates[] electionsWithCandidates = [];

    foreach store:Election election in elections {
        // Get enrolled candidates with details for each election
        EnrolledCandidateWithDetails[]|error enrolledCandidates = getCandidatesForElection(election.id);

        // Get enrolled voters count for each election
        int|error votersCount = getEnrolledVotersCount(election.id);
        if votersCount is error {
            log:printWarn("Failed to get enrolled voters count", electionId = election.id, 'error = votersCount);
            votersCount = 0; // Default to 0 if error
        }

        // Get voted count for each election
        int|error votesCount = getVotedCount(election.id);
        if votesCount is error {
            log:printWarn("Failed to get enrolled voters count", electionId = election.id, 'error = votesCount);
            votesCount = 0; // Default to 0 if error
        }

        ElectionWithCandidates electionWithCandidates = {
            ...election,
            enrolledCandidates: check enrolledCandidates,
            enrolledVotersCount: check votersCount,
            votedCount: check votesCount
        };

        electionsWithCandidates.push(electionWithCandidates);
    }

    return electionsWithCandidates;
}

public function getElectionById(string electionId) returns ElectionWithCandidates|error {
    log:printInfo("Fetching election with ID: " + electionId);

    store:Election|persist:Error election = dbElection->/elections/[electionId];
    if election is persist:Error {
        log:printError("Election not found", electionId = electionId, 'error = election);
        return error("Election not found for ID: " + electionId);
    }

    // Get enrolled candidates with details for this election
    EnrolledCandidateWithDetails[]|error enrolledCandidates = getCandidatesForElection(electionId);
    if enrolledCandidates is error {
        log:printWarn("Failed to fetch candidates for election", electionId = electionId, 'error = enrolledCandidates);
        enrolledCandidates = [];
    }

    // Get enrolled voters count for this election
    int|error votersCount = getEnrolledVotersCount(electionId);
    if votersCount is error {
        log:printWarn("Failed to get enrolled voters count", electionId = electionId, 'error = votersCount);
        votersCount = 0; // Default to 0 if error
    }

    // Get voted count for each election
    int|error votesCount = getVotedCount(election.id);
    if votesCount is error {
        log:printWarn("Failed to get enrolled voters count", electionId = election.id, 'error = votesCount);
        votesCount = 0; // Default to 0 if error
    }

    ElectionWithCandidates response = {
        ...election,
        enrolledCandidates: check enrolledCandidates,
        enrolledVotersCount: check votersCount,
        votedCount: check votesCount
    };

    return response;
}

public function createElection(ElectionCreateWithCandidates newElectionCreate) returns ElectionWithCandidates|error {
    // Generate ID for the election
    string electionId = common:generateId();

    // Create the election first
    store:ElectionInsert electionInsert = {
        id: electionId,
        electionName: newElectionCreate.electionName,
        description: newElectionCreate.description,
        startTime: newElectionCreate.startTime,
        endTime: newElectionCreate.endTime,
        endDate: newElectionCreate.endDate,
        electionDate: newElectionCreate.electionDate,
        noOfCandidates: newElectionCreate.noOfCandidates,
        electionType: newElectionCreate.electionType,
        enrolDdl: newElectionCreate.enrolDdl,
        startDate: newElectionCreate.startDate,
        status: newElectionCreate.status
    };

    string[]|persist:Error result = dbElection->/elections.post([electionInsert]);
    if result is persist:Error {
        log:printError("Failed to create election", 'error = result);
        return error("Election not created: " + result.message());
    }

    log:printInfo("Election created successfully", electionId = electionId);

    // If candidates are provided, enroll them
    string[]? candidateIds = newElectionCreate?.candidateIds;
    if candidateIds is string[] && candidateIds.length() > 0 {
        log:printInfo("Enrolling candidates in election", electionId = electionId, candidateCount = candidateIds.length());

        error? enrollResult = enrollCandidatesInElection(electionId, candidateIds);
        if enrollResult is error {
            // Rollback election creation if candidate enrollment fails
            log:printError("Candidate enrollment failed, rolling back election", electionId = electionId, 'error = enrollResult);
            _ = check dbElection->/elections/[electionId].delete();
            return error("Failed to enroll candidates: " + enrollResult.message());
        }

        log:printInfo("Candidates enrolled successfully", electionId = electionId);
    }

    // Return the created election with enrolled candidates
    return getElectionById(electionId);
}

public function updateElection(string electionId, ElectionUpdateWithCandidates updatedElection) returns ElectionWithCandidates|error {
    log:printInfo("Updating election", electionId = electionId);

    store:Election|persist:Error existingElection = dbElection->/elections/[electionId];
    if existingElection is persist:Error {
        log:printError("Election not found for update", electionId = electionId);
        return error("Election not found for ID: " + electionId);
    }

    // Extract candidateIds from the update request
    string[]? candidateIds = updatedElection?.candidateIds;

    // Update election details (excluding candidateIds which is not a database field)
    store:ElectionUpdate electionUpdate = {
        electionName: updatedElection.electionName ?: existingElection.electionName,
        electionType: updatedElection.electionType ?: existingElection.electionType,
        description: updatedElection.description ?: existingElection.description,
        startTime: updatedElection.startTime ?: existingElection.startTime,
        endTime: updatedElection.endTime ?: existingElection.endTime,
        status: updatedElection.status ?: existingElection.status,
        electionDate: updatedElection.electionDate ?: existingElection.electionDate,
        startDate: updatedElection.startDate ?: existingElection.startDate,
        endDate: updatedElection.endDate ?: existingElection.endDate,
        enrolDdl: updatedElection.enrolDdl ?: existingElection.enrolDdl,
        noOfCandidates: updatedElection.noOfCandidates ?: existingElection.noOfCandidates
    };

    store:Election|persist:Error result = dbElection->/elections/[electionId].put(electionUpdate);
    if result is persist:Error {
        log:printError("Failed to update election", electionId = electionId, 'error = result);
        return error("Election not updated: " + result.message());
    }

    log:printInfo("Election details updated successfully", electionId = electionId);

    // If candidates are provided, update candidate enrollment
    if candidateIds is string[] {
        log:printInfo("Updating candidate enrollments", electionId = electionId, candidateCount = candidateIds.length());

        // Remove existing candidate enrollments
        error? removeResult = removeAllCandidatesFromElection(electionId);
        if removeResult is error {
            log:printError("Failed to remove existing candidates", electionId = electionId, 'error = removeResult);
            return error("Failed to remove existing candidates: " + removeResult.message());
        }

        // Enroll new candidates (only if the array is not empty)
        if candidateIds.length() > 0 {
            error? enrollResult = enrollCandidatesInElection(electionId, candidateIds);
            if enrollResult is error {
                log:printError("Failed to enroll new candidates", electionId = electionId, 'error = enrollResult);
                return error("Failed to enroll new candidates: " + enrollResult.message());
            }
        }

        log:printInfo("Candidate enrollments updated successfully", electionId = electionId);
    }

    // Return updated election with enrolled candidates
    return getElectionById(electionId);
}

public function deleteElection(string electionId) returns http:NoContent|error {
    log:printInfo("Deleting election", electionId = electionId);

    // Check if election exists
    store:Election|persist:Error existingElection = dbElection->/elections/[electionId];
    if existingElection is persist:Error {
        log:printError("Election not found for deletion", electionId = electionId);
        return error("Election not found for ID: " + electionId);
    }

    // Remove all candidate enrollments first
    error? removeResult = removeAllCandidatesFromElection(electionId);
    if removeResult is error {
        log:printWarn("Failed to remove candidates before deleting election", electionId = electionId, 'error = removeResult);
        // Continue with deletion even if candidate removal fails
    }

    store:Election|persist:Error deleteResult = dbElection->/elections/[electionId].delete();
    if deleteResult is persist:Error {
        log:printError("Failed to delete election", electionId = electionId, 'error = deleteResult);
        return error("Failed to delete election: " + deleteResult.message());
    }

    log:printInfo("Election deleted successfully", electionId = electionId);
    return http:NO_CONTENT;
}

// ===== HELPER FUNCTIONS =====

// Helper function to enroll multiple candidates in an election
function enrollCandidatesInElection(string electionId, string[] candidateIds) returns error? {
    if candidateIds.length() == 0 {
        return; // Nothing to enroll
    }

    log:printInfo("Enrolling candidates in election", electionId = electionId, candidateCount = candidateIds.length());

    store:EnrolCandidatesInsert[] candidateInserts = [];

    foreach string candidateId in candidateIds {
        store:EnrolCandidatesInsert candidateInsert = {
            electionId: electionId,
            candidateId: candidateId,
            numberOfVotes: 0 // Initialize with 0 votes
        };
        candidateInserts.push(candidateInsert);
    }

    [string, string][]|persist:Error result = dbElection->/enrolcandidates.post(candidateInserts);
    if result is persist:Error {
        return error("Failed to enroll candidates: " + result.message());
    }

    log:printInfo("Candidates enrolled successfully, now activating them", electionId = electionId);

    // IMPORTANT: Activate candidates immediately when they are enrolled
    // They stay active until the election end date passes
    error? activationResult = candidate:activateCandidatesForElection(candidateIds);
    if activationResult is error {
        log:printError("Failed to activate candidates after enrollment", electionId = electionId, 'error = activationResult);
        // Don't fail the enrollment, but this is a serious issue
        return error("Candidates enrolled but failed to activate: " + activationResult.message());
    }

    log:printInfo("Candidates enrolled and activated successfully", electionId = electionId);
    return;
}

// Helper function to remove all candidates from an election
function removeAllCandidatesFromElection(string electionId) returns error? {
    log:printInfo("Removing all candidates from election", electionId = electionId);

    // Get all enrolled candidates for this election BEFORE removing them
    stream<store:EnrolCandidates, persist:Error?> candidateStream = dbElection->/enrolcandidates;
    store:EnrolCandidates[] enrolledCandidates = check from store:EnrolCandidates candidate in candidateStream
        where candidate.electionId == electionId
        select candidate;

    string[] candidateIds = enrolledCandidates.map(function(store:EnrolCandidates e) returns string {
        return e.candidateId;
    });

    if candidateIds.length() == 0 {
        log:printInfo("No candidates to remove from election", electionId = electionId);
        return;
    }

    // Delete each enrollment
    foreach store:EnrolCandidates candidate in enrolledCandidates {
        store:EnrolCandidates|persist:Error deleteResult = dbElection->/enrolcandidates/[candidate.electionId]/[candidate.candidateId].delete();
        if deleteResult is persist:Error {
            return error("Failed to remove candidate: " + candidate.candidateId + " - " + deleteResult.message());
        }
    }

    log:printInfo("Enrollment records removed, now checking candidate deactivation",
            electionId = electionId, candidateCount = candidateIds.length());

    // IMPORTANT: Check if candidates should be deactivated after removal
    // Only deactivate if they're not enrolled in any other elections with future end dates
    error? deactivationResult = checkAndDeactivateCandidatesAfterRemoval(candidateIds);
    if deactivationResult is error {
        log:printWarn("Failed to check/deactivate candidates after removal", 'error = deactivationResult);
        // Don't fail the removal, just log the warning
    }

    return;
}

// Helper function to get candidates for an election with candidate details
public function getCandidatesForElection(string electionId) returns EnrolledCandidateWithDetails[]|error {
    // Get enrolled candidates for this election
    stream<store:EnrolCandidates, persist:Error?> enrolmentStream = dbElection->/enrolcandidates;
    store:EnrolCandidates[] enrolments = check from store:EnrolCandidates enrolment in enrolmentStream
        where enrolment.electionId == electionId
        select enrolment;

    // Get candidate details for each enrolled candidate
    EnrolledCandidateWithDetails[] candidatesWithDetails = [];

    foreach store:EnrolCandidates enrolment in enrolments {
        // Fetch candidate details from candidate table
        store:Candidate|persist:Error candidateResult = dbElection->/candidates/[enrolment.candidateId];

        EnrolledCandidateWithDetails candidateWithDetails = {
            electionId: enrolment.electionId,
            candidateId: enrolment.candidateId,
            numberOfVotes: enrolment.numberOfVotes
        };

        // Add candidate details if found
        if candidateResult is store:Candidate {
            candidateWithDetails.candidateName = candidateResult.candidateName;
            candidateWithDetails.partyName = candidateResult.partyName;
        } else {
            log:printWarn("Candidate details not found", candidateId = enrolment.candidateId);
            // Set default values if candidate not found
            candidateWithDetails.candidateName = ();
            candidateWithDetails.partyName = ();
        }

        candidatesWithDetails.push(candidateWithDetails);
    }

    return candidatesWithDetails;
}

// Function for individual candidate enrollment (keeping for backward compatibility)
public function addCandidatesToElection(store:EnrolCandidatesInsert newCandidate) returns http:Response|error {
    [string, string][]|persist:Error result = dbElection->/enrolcandidates.post([newCandidate]);
    if result is persist:Error {
        return error("Failed to enroll candidate: " + result.message());
    }

    http:Response res = new;
    res.setPayload(newCandidate);
    return res;
}

// Additional utility functions

public function removeCandidateFromElection(string electionId, string candidateId) returns http:NoContent|error {
    store:EnrolCandidates|persist:Error deleteResult = dbElection->/enrolcandidates/[electionId]/[candidateId].delete();
    if deleteResult is persist:Error {
        return error("Failed to remove candidate from election: " + deleteResult.message());
    }
    return http:NO_CONTENT;
}

public function updateCandidateVotes(string electionId, string candidateId, int votes) returns store:EnrolCandidates|error {
    store:EnrolCandidatesUpdate voteUpdate = {numberOfVotes: votes};
    store:EnrolCandidates|persist:Error result = dbElection->/enrolcandidates/[electionId]/[candidateId].put(voteUpdate);
    if result is persist:Error {
        return error("Failed to update candidate votes: " + result.message());
    }
    return result;
}

// Enhanced function to check if candidates should be deactivated after removal from election
function checkAndDeactivateCandidatesAfterRemoval(string[] candidateIds) returns error? {
    time:Date today = time:utcToCivil(time:utcNow());

    foreach string candidateId in candidateIds {
        log:printInfo("Checking deactivation for candidate", candidateId = candidateId);

        // Check if candidate is enrolled in any other elections
        stream<store:EnrolCandidates, persist:Error?> enrolmentStream = dbElection->/enrolcandidates;
        store:EnrolCandidates[] otherEnrollments = check from store:EnrolCandidates enrollment in enrolmentStream
            where enrollment.candidateId == candidateId
            select enrollment;

        if otherEnrollments.length() == 0 {
            // No other enrollments - deactivate immediately
            log:printInfo("No other enrollments found, deactivating candidate", candidateId = candidateId);
            error? deactivateResult = candidate:deactivateCandidatesForElection([candidateId]);
            if deactivateResult is error {
                log:printError("Failed to deactivate candidate", candidateId = candidateId, 'error = deactivateResult);
            }
            continue;
        }

        // Check if any other enrollments are in elections that haven't ended yet
        boolean hasActiveOrFutureElection = false;

        foreach store:EnrolCandidates enrollment in otherEnrollments {
            // Get the election details
            store:Election|persist:Error election = dbElection->/elections/[enrollment.electionId];
            if election is store:Election {
                // Check if this election hasn't ended yet (end date is today or in the future)
                if !candidate:isDateAfter(today, election.endDate) {
                    hasActiveOrFutureElection = true;
                    log:printInfo("Candidate has enrollment in future/current election",
                            candidateId = candidateId, electionId = election.id, endDate = election.endDate);
                    break;
                }
            }
        }

        // Only deactivate if no active or future elections
        if !hasActiveOrFutureElection {
            log:printInfo("No active/future elections found, deactivating candidate", candidateId = candidateId);
            error? deactivateResult = candidate:deactivateCandidatesForElection([candidateId]);
            if deactivateResult is error {
                log:printError("Failed to deactivate candidate after checking enrollments",
                        candidateId = candidateId, 'error = deactivateResult);
            }
        } else {
            log:printInfo("Candidate remains active due to other enrollments", candidateId = candidateId);
        }
    }

    return;
}

// Enhanced function to handle election date changes and candidate status updates
public function updateElectionWithStatusManagement(string electionId, ElectionUpdateWithCandidates updatedElection) returns ElectionWithCandidates|error {
    log:printInfo("Updating election with status management", electionId = electionId);

    store:Election|persist:Error existingElection = dbElection->/elections/[electionId];
    if existingElection is persist:Error {
        log:printError("Election not found for update", electionId = electionId);
        return error("Election not found for ID: " + electionId);
    }

    // Store the old end date for comparison
    time:Date oldEndDate = existingElection.endDate;

    // Extract candidateIds from the update request
    string[]? candidateIds = updatedElection?.candidateIds;

    // Update election details (excluding candidateIds which is not a database field)
    store:ElectionUpdate electionUpdate = {
        electionName: updatedElection.electionName ?: existingElection.electionName,
        electionType: updatedElection.electionType ?: existingElection.electionType,
        description: updatedElection.description ?: existingElection.description,
        startTime: updatedElection.startTime ?: existingElection.startTime,
        endTime: updatedElection.endTime ?: existingElection.endTime,
        status: updatedElection.status ?: existingElection.status,
        electionDate: updatedElection.electionDate ?: existingElection.electionDate,
        startDate: updatedElection.startDate ?: existingElection.startDate,
        endDate: updatedElection.endDate ?: existingElection.endDate,
        enrolDdl: updatedElection.enrolDdl ?: existingElection.enrolDdl,
        noOfCandidates: updatedElection.noOfCandidates ?: existingElection.noOfCandidates
    };

    store:Election|persist:Error result = dbElection->/elections/[electionId].put(electionUpdate);
    if result is persist:Error {
        log:printError("Failed to update election", electionId = electionId, 'error = result);
        return error("Election not updated: " + result.message());
    }

    log:printInfo("Election details updated successfully", electionId = electionId);

    // Check if end date changed to the past and handle candidate deactivation
    time:Date newEndDate = electionUpdate.endDate ?: existingElection.endDate;
    time:Date today = time:utcToCivil(time:utcNow());

    // If election end date changed and is now in the past, check candidate deactivation
    if !isDateEqual(oldEndDate, newEndDate) && candidate:isDateAfter(today, newEndDate) {
        log:printInfo("Election end date changed to past, checking candidate deactivation",
                electionId = electionId, oldEndDate = oldEndDate, newEndDate = newEndDate);

        // Get current enrolled candidates
        string[] currentCandidateIds = [];
        EnrolledCandidateWithDetails[]|error currentEnrollments = getCandidatesForElection(electionId);
        if currentEnrollments is EnrolledCandidateWithDetails[] {
            currentCandidateIds = currentEnrollments.map(function(EnrolledCandidateWithDetails e) returns string {
                return e.candidateId;
            });
        }

        if currentCandidateIds.length() > 0 {
            error? deactivationResult = checkAndDeactivateCandidatesAfterRemoval(currentCandidateIds);
            if deactivationResult is error {
                log:printWarn("Failed to deactivate candidates after election end date change",
                        electionId = electionId, 'error = deactivationResult);
            }
        }
    }

    // If candidates are provided, update candidate enrollment
    if candidateIds is string[] {
        log:printInfo("Updating candidate enrollments", electionId = electionId, candidateCount = candidateIds.length());

        // Remove existing candidate enrollments (this will check deactivation)
        error? removeResult = removeAllCandidatesFromElection(electionId);
        if removeResult is error {
            log:printError("Failed to remove existing candidates", electionId = electionId, 'error = removeResult);
            return error("Failed to remove existing candidates: " + removeResult.message());
        }

        // Enroll new candidates (only if the array is not empty)
        if candidateIds.length() > 0 {
            error? enrollResult = enrollCandidatesInElection(electionId, candidateIds);
            if enrollResult is error {
                log:printError("Failed to enroll new candidates", electionId = electionId, 'error = enrollResult);
                return error("Failed to enroll new candidates: " + enrollResult.message());
            }
        }

        log:printInfo("Candidate enrollments updated successfully", electionId = electionId);
    }

    // Return updated election with enrolled candidates
    return getElectionById(electionId);
}

// Daily scheduled job to check and deactivate candidates from ended elections
public function deactivateCandidatesFromEndedElections() returns error? {
    log:printInfo("Starting scheduled deactivation of candidates from ended elections");

    time:Date today = time:utcToCivil(time:utcNow());

    // Get all elections that ended before today
    stream<store:Election, persist:Error?> electionStream = dbElection->/elections;
    store:Election[] endedElections = check from store:Election election in electionStream
        where candidate:isDateAfter(today, election.endDate)
        select election;

    foreach store:Election election in endedElections {
        log:printInfo("Processing ended election", electionId = election.id, endDate = election.endDate);

        // Get enrolled candidates for this ended election
        EnrolledCandidateWithDetails[]|error enrolledCandidates = getCandidatesForElection(election.id);
        if enrolledCandidates is error {
            log:printWarn("Failed to get candidates for ended election", electionId = election.id, 'error = enrolledCandidates);
            continue;
        }

        string[] candidateIds = enrolledCandidates.map(function(EnrolledCandidateWithDetails e) returns string {
            return e.candidateId;
        });

        if candidateIds.length() > 0 {
            // Check and deactivate candidates (only if they have no other active enrollments)
            error? deactivationResult = checkAndDeactivateCandidatesAfterRemoval(candidateIds);
            if deactivationResult is error {
                log:printError("Failed to deactivate candidates from ended election",
                        electionId = election.id, 'error = deactivationResult);
            } else {
                log:printInfo("Processed candidate deactivation for ended election",
                        electionId = election.id, candidateCount = candidateIds.length());
            }
        }
    }

    log:printInfo("Completed scheduled deactivation of candidates from ended elections");
    return;
}

// Helper function to check if two dates are equal
function isDateEqual(time:Date date1, time:Date date2) returns boolean {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
}

public function getEnrolledVotersCount(string electionId) returns int|error {
    stream<store:Enrolment, persist:Error?> enrolmentStream = dbElection->/enrolments;
    store:Enrolment[] enrolments = check from store:Enrolment enrolment in enrolmentStream
        where enrolment.electionId == electionId
        select enrolment;

    return enrolments.length();
}

public function getVotedCount(string electionId) returns int|error {
    stream<store:Vote, persist:Error?> voteStream = dbElection->/votes;
    store:Vote[] votes = check from store:Vote vote in voteStream
        where vote.electionId == electionId
        select vote;

    return votes.length();
}
