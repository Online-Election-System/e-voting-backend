// AUTO-GENERATED FILE. DO NOT MODIFY.

// This file is an auto-generated file by Ballerina persistence layer for model.
// It should not be modified by hand.

import ballerina/time;

public type Voter record {|
    readonly string id;
    string nationalId;
    string fullName;
    string? mobileNumber;
    string? dob;
    string? gender;
    string? nicChiefOccupant;
    string? address;
    string? district;
    string? householdNo;
    string? gramaNiladhari;
    string password;
|};

public type VoterOptionalized record {|
    string id?;
    string nationalId?;
    string fullName?;
    string? mobileNumber?;
    string? dob?;
    string? gender?;
    string? nicChiefOccupant?;
    string? address?;
    string? district?;
    string? householdNo?;
    string? gramaNiladhari?;
    string password?;
|};

public type VoterTargetType typedesc<VoterOptionalized>;

public type VoterInsert Voter;

public type VoterUpdate record {|
    string nationalId?;
    string fullName?;
    string? mobileNumber?;
    string? dob?;
    string? gender?;
    string? nicChiefOccupant?;
    string? address?;
    string? district?;
    string? householdNo?;
    string? gramaNiladhari?;
    string password?;
|};

public type Election record {|
    readonly string id;
    string electionName;
    string description;
    time:Date startDate;
    time:Date enrolDdl;
    time:Date endDate;
    int noOfCandidates;
|};

public type ElectionOptionalized record {|
    string id?;
    string electionName?;
    string description?;
    time:Date startDate?;
    time:Date enrolDdl?;
    time:Date endDate?;
    int noOfCandidates?;
|};

public type ElectionTargetType typedesc<ElectionOptionalized>;

public type ElectionInsert Election;

public type ElectionUpdate record {|
    string electionName?;
    string description?;
    time:Date startDate?;
    time:Date enrolDdl?;
    time:Date endDate?;
    int noOfCandidates?;
|};

