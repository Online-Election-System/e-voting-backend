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
public type ElectionConfig record {|
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
