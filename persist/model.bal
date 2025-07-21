import ballerina/persist as _;
import ballerina/time;
import ballerinax/persist.sql;

# Description.
#
# + id - Voter ID (Auto-incrementing Primary Key)
# + nationalId - National Identity Card Number (Unique Identifier)
# + fullName - Full Name of the voter
# + mobileNumber - Contact Number (Nullable)
# + dob - Date of Birth (Stored as String MM/DD/YYYY)
# + gender - Gender (Male/Female - Nullable)
# + nicChiefOccupant - NIC of Chief Occupant (Nullable)
# + address - Registered Address of the voter
# + district - Voter's District
# + householdNo - Household Number (Nullable)
# + gramaNiladhari - Grama Niladhari Division (Nullable)
# + password - Hashed Password for Authentication

public type Voter record {|
    readonly string id;
    @sql:Name {value: "national_id"}
    string nationalId;
    @sql:Name {value: "full_name"}
    string fullName;
    @sql:Name {value: "mobile_number"}
    string? mobileNumber;
    string? dob;
    string? gender;
    @sql:Name {value: "nic_chief_occupant"}
    string? nicChiefOccupant;
    string? address;
    string? district;
    @sql:Name {value: "household_no"}
    string? householdNo;
    @sql:Name {value: "grama_niladhari"}
    string? gramaNiladhari;
    string password;
|};

# Description for elections to be insterted.
#
# + id - election id (Primary Key)
# + electionName - election title
# + description - election description
# + startDate - the date where election should start being visible
# + enrolDdl - election enrollment deadline
# + electionDate - the date of the election happening
# + endDate - election end date
# + noOfCandidates - election number of candidates
# + electionType - National / Regional / District / City / Local
# + startTime - election starting time
# + endTime - election ending time
# + status - Scheduled / Upcoming / Active / Completed / Cancelled

public type Election record {|
    readonly string id;
    @sql:Name {value: "election_name"}
    string electionName;
    string description;
    @sql:Name {value: "start_date"}
    time:Date startDate;
    @sql:Name {value: "enrol_ddl"}
    time:Date enrolDdl;
    @sql:Name {value: "election_date"}
    time:Date electionDate;
    @sql:Name {value: "end_date"}
    time:Date endDate;
    @sql:Name {value: "no_of_candidates"}
    int noOfCandidates;
    @sql:Name {value: "election_type"}
    string electionType;
    @sql:Name {value: "start_time"}
    time:TimeOfDay startTime;
    @sql:Name {value: "end_time"}
    time:TimeOfDay endTime;
    string status;
|};

# + candidateId - candidateId (primary key)
# + electionId - electionId(forign key)
# + candidateName - candidateName
# + partyName - partyName
# + partySymbol - partySymbol
# + partyColor - partyColor
# + candidateImage - candidateImage
# + popularVotes - popularVotes
# + electoralVotes - electoralVotes
# + position - position
# + isActive - isActive

public type Candidate record {|
    @sql:Name {value: "candidate_id"}
    readonly string candidateId;
    @sql:Name {value: "election_id"}
    string electionId;
    @sql:Name {value: "candidate_name"}
    string candidateName;
    @sql:Name {value: "party_name"}
    string partyName;
    @sql:Name {value: "party_symbol"}
    string? partySymbol;
    @sql:Name {value: "party_color"}
    string partyColor;
    @sql:Name {value: "candidate_image"}
    string? candidateImage;
    @sql:Name {value: "popular_votes"}
    int? popularVotes;
    @sql:Name {value: "electoral_votes"}
    int? electoralVotes;
    int? position;
    @sql:Name {value: "is_active"}
    boolean isActive;
|};
