// AUTO-GENERATED FILE. DO NOT MODIFY.

// This file is an auto-generated file by Ballerina persistence layer for model.
// It should not be modified by hand.

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

public type ElectionOptionalized record {|
    string id?;
    string election_name?;
    string description?;
    time:Date start_date?;
    time:Date enrol_ddl?;
    time:Date end_date?;
    int no_of_candidates?;
|};

public type ElectionTargetType typedesc<ElectionOptionalized>;

public type ElectionInsert Election;

public type ElectionUpdate record {|
    string election_name?;
    string description?;
    time:Date start_date?;
    time:Date enrol_ddl?;
    time:Date end_date?;
    int no_of_candidates?;
|};

