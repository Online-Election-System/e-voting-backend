import ballerina/persist as _;
import ballerina/time;

public type Election record {|
    readonly string id;
    string election_name;
    string description;
    time:Date start_date;
    time:Date enrol_ddl;
    time:Date end_date;
    int no_of_candidates;
|};
