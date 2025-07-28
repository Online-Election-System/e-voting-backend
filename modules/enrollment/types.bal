import ballerina/time;
import online_election.store;

// This file defines custom data structures (view models) for the enrollment API.

// For the /voter/login endpoint
public type LoginRequest record {|
    string nationalId;
    string password;
|};

// For the voter verification form before enrolling
public type VoterVerificationRequest record {|
    string fullName;
    string nationalId;
    string password;
|};

// Represents a single election in the main list on the /elections page
public type ElectionWithEnrollment record {|
    string id;
    string title;
    string description;
    time:Date startDate;
    time:Date endDate;
    time:Date enrollmentDeadline;
    time:Date electionDate;
    int noOfCandidates;
    string electionType;
    time:TimeOfDay startTime;
    time:TimeOfDay endTime;
    string status;
    boolean enrolled; // True if the logged-in voter is enrolled
|};

// Represents the detailed view of a voter's profile on the /profile page
// public type VoterProfile record {|
//     int id;
//     string nationalId;
//     string name;
//     string district;
//     string pollingStation;
//     time:Date registrationDate;
//     string status;
//     EnrolledElection[] enrolledElections; // List of elections the user is enrolled in
// |};

public type UserProfile record {|
    // Basic Info (from ChiefOccupant or HouseholdMembers)
    string fullName;
    string nic;
    string email;
    string dob;
    string gender;
    string civilStatus;
    string role;
    
    // Address Info (from HouseholdDetails)
    string electoralDistrict;
    string pollingDivision;
    string fullAddress;

    // Voter-specific Info (will be null if the user is not an approved voter)
    string? voterStatus;
    time:Date? registrationDate;

    // Election Info (will be an empty array if the user is not an approved voter)
    EnrolledElection[] enrolledElections;
|};


// A sub-record for the VoterProfile
public type EnrolledElection record {|
    string electionId;
    string title;
    time:Date electionDate;
    string status;
    time:Utc enrollmentDate;
|};

// Represents the detailed view of an election with its candidates
public type ElectionDetailsWithCandidates record {|
    string id;
    string name;
    string description;
    time:Date startDate;
    time:Date enrolDeadline;
    time:Date electionDate;
    time:Date endDate;
    int noOfCandidates;
    string 'type;
    time:TimeOfDay startTime;
    time:TimeOfDay endTime;
    string status;
    store:Candidate[] candidates; 
|};

// A generic success/error response for the API
public type ApiResponse record {|
    boolean success;
    string message;
    json data?;
    string? voterId = ();
|};