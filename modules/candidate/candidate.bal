import online_election.common;
import online_election.store;

import ballerina/log;
import ballerina/persist;
import ballerina/time;

final store:Client dbCandidate = check new ();

// Create a new candidate - defaults to inactive
public function createCandidate(CandidateInput candidate) returns store:Candidate|error {
    store:CandidateInsert newCandidate = {
        candidateId: common:generateId(),
        candidateName: candidate.candidateName,
        partyName: candidate.partyName,
        partySymbol: candidate?.partySymbol ?: candidate?.partySymbol,
        partyColor: candidate.partyColor,
        candidateImage: candidate?.candidateImage ?: candidate?.candidateImage,
        isActive: false // Always start as inactive
    };

    string[]|persist:Error result = dbCandidate->/candidates.post([newCandidate]);
    if result is persist:Error {
        return error("Failed to create candidate");
    }

    // Return the created candidate by fetching it
    return getCandidateById(newCandidate.candidateId);
}

// Get candidates with optional filtering
public function getCandidates(boolean? activeOnly = ()) returns store:Candidate[]|error {
    stream<store:Candidate, persist:Error?> candidatesStream = dbCandidate->/candidates;

    if activeOnly is boolean {
        return check from store:Candidate candidate in candidatesStream
            where candidate.isActive is boolean && candidate.isActive == activeOnly
            select candidate;
    }

    return check from store:Candidate candidate in candidatesStream
        select candidate;
}

// Get a candidate by ID
public function getCandidateById(string candidateId) returns store:Candidate|error {
    store:Candidate|persist:Error candidate = dbCandidate->/candidates/[candidateId].get();
    if candidate is persist:Error {
        return error("Candidate not found");
    }
    return candidate;
}

// Update a candidate
public function updateCandidate(string candidateId, store:CandidateUpdate updates) returns store:Candidate|error {
    // Get existing candidate first
    store:Candidate existing = check getCandidateById(candidateId);

    store:CandidateUpdate updateData = {
        candidateName: updates.candidateName ?: existing.candidateName,
        partyName: updates.partyName ?: existing.partyName,
        partySymbol: updates?.partySymbol ?: existing?.partySymbol,
        partyColor: updates.partyColor ?: existing?.partyColor,
        candidateImage: updates?.candidateImage ?: existing?.candidateImage,
        isActive: existing.isActive // Preserve existing active status - system managed
    };

    store:Candidate|persist:Error result = dbCandidate->/candidates/[candidateId].put(updateData);
    if result is persist:Error {
        return error("Failed to update candidate");
    }
    return result;
}

// Delete a candidate
public function deleteCandidate(string candidateId) returns store:Candidate|error {
    store:Candidate|persist:Error candidate = dbCandidate->/candidates/[candidateId].delete();
    if candidate is persist:Error {
        return error("Failed to delete candidate");
    }
    return candidate;
}

// SYSTEM MANAGED ACTIVATION FUNCTIONS---------------------------------------

// Activate candidates when enrolled in an election
public function activateCandidatesForElection(string[] candidateIds) returns error? {
    foreach string candidateId in candidateIds {
        store:Candidate|error existing = getCandidateById(candidateId);
        if existing is error {
            log:printWarn("Cannot activate candidate - not found", candidateId = candidateId);
            continue;
        }

        store:CandidateUpdate activationUpdate = {
            candidateName: existing.candidateName,
            partyName: existing.partyName,
            partySymbol: existing?.partySymbol,
            partyColor: existing?.partyColor,
            candidateImage: existing?.candidateImage,
            isActive: true // Activate the candidate
        };

        store:Candidate|persist:Error result = dbCandidate->/candidates/[candidateId].put(activationUpdate);
        if result is persist:Error {
            log:printError("Failed to activate candidate", candidateId = candidateId, 'error = result);
            return error("Failed to activate candidate: " + candidateId);
        }

        log:printInfo("Candidate activated", candidateId = candidateId);
    }
}

// Deactivate candidates when election ends
public function deactivateCandidatesForElection(string[] candidateIds) returns error? {
    foreach string candidateId in candidateIds {
        store:Candidate|error existing = getCandidateById(candidateId);
        if existing is error {
            log:printWarn("Cannot deactivate candidate - not found", candidateId = candidateId);
            continue;
        }

        store:CandidateUpdate deactivationUpdate = {
            candidateName: existing.candidateName,
            partyName: existing.partyName,
            partySymbol: existing?.partySymbol,
            partyColor: existing?.partyColor,
            candidateImage: existing?.candidateImage,
            isActive: false // Deactivate the candidate
        };

        store:Candidate|persist:Error result = dbCandidate->/candidates/[candidateId].put(deactivationUpdate);
        if result is persist:Error {
            log:printError("Failed to deactivate candidate", candidateId = candidateId, 'error = result);
            return error("Failed to deactivate candidate: " + candidateId);
        }

        log:printInfo("Candidate deactivated", candidateId = candidateId);
    }
}

// Check and update candidate statuses based on election dates
public function updateCandidateStatusesBasedOnElections() returns error? {
    log:printInfo("Starting candidate status update based on elections");

    // This function now primarily handles deactivation of candidates from ended elections
    // Activation happens immediately when candidates are enrolled
    return deactivateCandidatesFromEndedElections();
}

// Helper function specifically for deactivating candidates from ended elections
function deactivateCandidatesFromEndedElections() returns error? {
    log:printInfo("Checking for candidates in ended elections to deactivate");

    time:Date today = time:utcToCivil(time:utcNow());

    // Get all elections that have ended
    stream<store:Election, persist:Error?> electionStream = dbCandidate->/elections;
    store:Election[] endedElections = check from store:Election election in electionStream
        where isDateAfter(today, election.endDate)
        select election;

    log:printInfo("Found ended elections", count = endedElections.length());

    foreach store:Election election in endedElections {
        // Get enrolled candidates for this ended election
        stream<store:EnrolCandidates, persist:Error?> enrolmentStream = dbCandidate->/enrolcandidates;
        store:EnrolCandidates[] enrollments = check from store:EnrolCandidates enrollment in enrolmentStream
            where enrollment.electionId == election.id
            select enrollment;

        string[] candidateIds = enrollments.map(function(store:EnrolCandidates e) returns string {
            return e.candidateId;
        });

        if candidateIds.length() == 0 {
            continue; // No candidates in this election
        }

        log:printInfo("Processing ended election for candidate deactivation", 
            electionId = election.id, candidateCount = candidateIds.length(), endDate = election.endDate);

        // For each candidate, check if they should be deactivated
        foreach string candidateId in candidateIds {
            // Check if this candidate is enrolled in any other elections that haven't ended
            stream<store:EnrolCandidates, persist:Error?> allEnrolmentsStream = dbCandidate->/enrolcandidates;
            store:EnrolCandidates[] allEnrollments = check from store:EnrolCandidates enrollment in allEnrolmentsStream
                where enrollment.candidateId == candidateId
                select enrollment;

            boolean hasActiveElection = false;

            foreach store:EnrolCandidates enrollment in allEnrollments {
                if enrollment.electionId == election.id {
                    continue; // Skip the current ended election
                }

                // Check the other election's end date
                store:Election|persist:Error otherElection = dbCandidate->/elections/[enrollment.electionId];
                if otherElection is store:Election {
                    // If this other election hasn't ended yet, keep candidate active
                    if !isDateAfter(today, otherElection.endDate) {
                        hasActiveElection = true;
                        break;
                    }
                }
            }

            // Only deactivate if no other active elections
            if !hasActiveElection {
                log:printInfo("Deactivating candidate - no active elections remaining", candidateId = candidateId);
                error? deactivateResult = deactivateCandidatesForElection([candidateId]);
                if deactivateResult is error {
                    log:printError("Failed to deactivate candidate from ended election", 
                        candidateId = candidateId, electionId = election.id, 'error = deactivateResult);
                }
            } else {
                log:printInfo("Keeping candidate active - has other active elections", candidateId = candidateId);
            }
        }
    }

    log:printInfo("Completed candidate status update based on elections");
    return;
}

// Helper function to check if date1 is after date2
public function isDateAfter(time:Date date1, time:Date date2) returns boolean {
    if date1.year > date2.year {
        return true;
    } else if date1.year == date2.year {
        if date1.month > date2.month {
            return true;
        } else if date1.month == date2.month {
            return date1.day > date2.day;
        }
    }
    return false;
}

// Helper function to check if date is between start and end dates
function isDateBetween(time:Date date, time:Date startDate, time:Date endDate) returns boolean {
    return !isDateAfter(startDate, date) && !isDateAfter(date, endDate);
}

// Get candidates by election with optional status filtering
public function getCandidatesByElection(string electionId, boolean? activeOnly = true) returns store:Candidate[]|error {
    // Get enrolled candidates for this election
    stream<store:EnrolCandidates, persist:Error?> enrolmentStream = dbCandidate->/enrolcandidates;
    store:EnrolCandidates[] enrolments = check from store:EnrolCandidates enrolment in enrolmentStream
        where enrolment.electionId == electionId
        select enrolment;

    string[] candidateIds = enrolments.map(function(store:EnrolCandidates e) returns string {
        return e.candidateId;
    });

    // Get candidate details with optional status filter
    stream<store:Candidate, persist:Error?> candidatesStream = dbCandidate->/candidates;
    store:Candidate[] candidates;

    if activeOnly is boolean {
        candidates = check from store:Candidate candidate in candidatesStream
            where candidate.isActive is boolean && candidate.isActive == activeOnly
            select candidate;
    } else {
        candidates = check from store:Candidate candidate in candidatesStream
            select candidate;
    }

    // Filter by enrolled candidate IDs
    return candidates.filter(function(store:Candidate c) returns boolean {
        return candidateIds.indexOf(c.candidateId) != -1;
    });
}

// Get candidate by composite key (election + candidate)
public function getCandidateByCompositeKey(string candidateId, string electionId) returns store:Candidate|error {
    // Verify candidate enrollment
    store:EnrolCandidates|persist:Error enrolment = dbCandidate->/enrolcandidates/[electionId]/[candidateId].get();
    if enrolment is persist:Error {
        return error("Candidate not enrolled in election");
    }

    // Get candidate details
    return getCandidateById(candidateId);
}

// Get candidates by election and party
public function getCandidatesByElectionAndParty(string electionId, string partyName, boolean? activeOnly = true) returns store:Candidate[]|error {
    // Get candidates by party with optional status filter
    stream<store:Candidate, persist:Error?> candidatesStream = dbCandidate->/candidates;
    store:Candidate[] partyCandidates;

    if activeOnly is boolean {
        partyCandidates = check from store:Candidate candidate in candidatesStream
            where candidate.partyName == partyName && candidate.isActive is boolean && candidate.isActive == activeOnly
            select candidate;
    } else {
        partyCandidates = check from store:Candidate candidate in candidatesStream
            where candidate.partyName == partyName
            select candidate;
    }

    // Get enrolled candidates for this election
    stream<store:EnrolCandidates, persist:Error?> enrolmentStream = dbCandidate->/enrolcandidates;
    store:EnrolCandidates[] enrolments = check from store:EnrolCandidates enrolment in enrolmentStream
        where enrolment.electionId == electionId
        select enrolment;

    string[] enrolledIds = enrolments.map(function(store:EnrolCandidates e) returns string {
        return e.candidateId;
    });

    // Filter party candidates by enrollment
    return partyCandidates.filter(function(store:Candidate c) returns boolean {
        return enrolledIds.indexOf(c.candidateId) != -1;
    });
}

// Check if candidate is active
public function isCandidateActive(string candidateId) returns boolean|error {
    store:Candidate|persist:Error result = dbCandidate->/candidates/[candidateId].get();
    if result is persist:Error {
        return false;
    }
    return result.isActive is boolean ? result.isActive : false; // Handle nullable boolean
}

// Get candidates by party (utility function)
public function getCandidatesByParty(string partyName, boolean? activeOnly = true) returns store:Candidate[]|error {
    stream<store:Candidate, persist:Error?> candidatesStream = dbCandidate->/candidates;

    if activeOnly is boolean {
        return check from store:Candidate candidate in candidatesStream
            where candidate.partyName == partyName && candidate.isActive is boolean && candidate.isActive == activeOnly
            select candidate;
    }

    return check from store:Candidate candidate in candidatesStream
        where candidate.partyName == partyName
        select candidate;
}