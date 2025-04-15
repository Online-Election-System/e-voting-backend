import ballerina/time;

# Description for elections to be insterted.
#
# + electionName - election title
# + description - election description
# + startDate - election start date
# + enrolDdl - election enrollment deadline
# + endDate - election end date
# + noOfCandidates - election number of candidates
public type ElectionConfig record {|
    string electionName;
    string description;
    time:Date startDate;
    time:Date enrolDdl;
    time:Date endDate;
    int noOfCandidates;
|};
