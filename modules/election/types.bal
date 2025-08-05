import online_election.store;

import ballerina/time;

# Description for elections to be insterted.
#
# + electionName - election title
# + description - election description
# + startDate - election start date
# + enrolDdl - election enrollment deadline
# + electionDate - the date where the election is happening
# + endDate - election end date
# + noOfCandidates - election number of candidates
# + electionType - National / Regional / District / City / Local
# + startTime - election starting time
# + endTime - election ending time
# + status - Scheduled / Upcoming / Active / Completed / Cancelled
public type ElectionCreate record {|
    string electionName;
    string description;
    time:Date startDate;
    time:Date enrolDdl;
    time:Date electionDate;
    time:Date endDate;
    int noOfCandidates;
    string electionType;
    time:TimeOfDay startTime;
    time:TimeOfDay endTime;
    string status;
|};

// Updated type to include optional candidates
public type ElectionCreateWithCandidates record {|
    *ElectionCreate;
    string[]? candidateIds?;
|};

public type ElectionUpdateWithCandidates record {|
    *store:ElectionUpdate;
    string[]? candidateIds?;
|};

public type ElectionWithCandidates record {|
    *store:Election;
    EnrolledCandidateWithDetails[]? enrolledCandidates?;
    int enrolledVotersCount?;
    int votedCount?;
|};

public type EnrolledCandidateWithDetails record {|
    string electionId;
    string candidateId;
    int numberOfVotes?;
    string? candidateName?;
    string? partyName?;
|};
