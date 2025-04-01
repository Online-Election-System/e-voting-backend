import ballerina/time;

# Description for elections to be insterted.
#
# + election_name - election title
# + description - election description
# + start_date - election start date
# + enrol_ddl - election enrollment deadline
# + end_date - election end date
# + no_of_candidates - election number of candidates
public type ElectionConfig record {|
    string election_name;
    string description;
    time:Date start_date;
    time:Date enrol_ddl;
    time:Date end_date;
    int no_of_candidates;
|};
