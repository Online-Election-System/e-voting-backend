import ballerina/persist as _;
import ballerina/time;
import ballerinax/persist.sql;

# ChiefOccupant Table
#
# + id - Auto-incrementing Primary Key
# + fullName - Full Name of Chief Occupant
# + nic - National Identity Card (Unique)
# + phoneNumber - Contact Number
# + dob - Date of Birth (MM/DD/YYYY)
# + gender - Gender (Male/Female)
# + civilStatus - Marital Status
# + passwordHash - Hashed Password
# + idCopyPath - File Path of ID Copy
# + email - email of chiefoccupant
# + role - Role of the user

public type ChiefOccupant record {|
    readonly string id;
    @sql:Name {value: "full_name"}
    string fullName;
    string nic;
    @sql:Name {value: "phone_number"}
    string? phoneNumber;
    string dob;
    string gender;
    @sql:Name {value: "civil_status"}
    string civilStatus;
    @sql:Name {value: "password_hash"}
    string passwordHash;
    string email;
    @sql:Name {value: "id_copy_path"}
    string? idCopyPath;
    string role;
|};

# HouseholdDetails Table
#
# + id - Auto-incrementing Primary Key
# + chiefOccupantId - Foreign Key (ChiefOccupant)
# + electoralDistrict - District of Registration
# + pollingDivision - Polling Division Name
# + pollingDistrictNumber - Polling District Number
# + gramaNiladhariDivision - GN Division
# + villageStreetEstate - Location Information
# + houseNumber - Registered House Number
# + householdMemberCount - Number of Members (excluding Chief)

public type HouseholdDetails record {|
    readonly string id;
    @sql:Name {value: "chief_occupant_id"}
    string chiefOccupantId;
    @sql:Name {value: "electoral_district"}
    string electoralDistrict;
    @sql:Name {value: "polling_division"}
    string pollingDivision;
    @sql:Name {value: "polling_district_number"}
    string pollingDistrictNumber;
    @sql:Name {value: "grama_niladhari_division"}
    string? gramaNiladhariDivision;
    @sql:Name {value: "village_street_estate"}
    string? villageStreetEstate;
    @sql:Name {value: "house_number"}
    string? houseNumber;
    @sql:Name {value: "household_member_count"}
    int householdMemberCount;
|};

# HouseholdMembers Table
#
# + id - Auto-incrementing Primary Key
# + chiefOccupantId - Foreign Key (ChiefOccupant)
# + fullName - Full Name of Household Member
# + nic - National Identity Card (Nullable)
# + dob - Date of Birth (MM/DD/YYYY)
# + gender - Gender (Male/Female)
# + civilStatus - Marital Status
# + relationshipWithChiefOccupant - Relationship with Chief Occupant
# + idCopyPath - File Path of ID Copy
# + approvedByChief - Chief Occupant Approval Status
# + passwordHash - Hashed Password
# + passwordchanged - if the password change
# + role - Role of the user

public type HouseholdMembers record {|
    readonly string id;
    @sql:Name {value: "chief_occupant_id"}
    string chiefOccupantId;
    @sql:Name {value: "full_name"}
    string fullName;
    string? nic;
    string dob;
    string gender;
    @sql:Name {value: "civil_status"}
    string civilStatus;
    @sql:Name {value: "relationship_with_chief_occupant"}
    string relationshipWithChiefOccupant;
    @sql:Name {value: "id_copy_path"}
    string? idCopyPath;
    @sql:Name {value: "approved_by_chief"}
    boolean approvedByChief;
    @sql:Name {value: "Hased_password"}
    string passwordHash;
    boolean passwordchanged;
    string role;
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

public type AdminUsers record {|
    readonly string id;
    string username;
    string email;
    @sql:Name {value: "password_hash"}
    string passwordHash;
    string role;
    @sql:Name {value: "created_at"}
    time:Utc createdAt;
    @sql:Name {value: "is_active"}
    boolean isActive;
|};

# Description for votes to be inserted.
#
# + id - Vote ID (Primary Key)
# + voterId - Voter ID (foreign key) - can reference either ChiefOccupant or HouseholdMembers
# + electionId - Election ID (foreign key)
# + candidateId - Candidate ID (foreign key)
# + timestamp - Vote timestamp
# + district - Voter's district

public type Vote record {|
    readonly string id;
    @sql:Name { value: "voter_id" }
    string voterId;
    @sql:Name { value: "election_id" }
    string electionId;
    @sql:Name { value: "candidate_id" }
    string candidateId;
    string district;
    string timestamp;
|};

# Description for candidates
#
# + candidateId - Candidate ID (primary key)
# + electionId - Election ID (foreign key)
# + candidateName - Candidate name
# + partyName - Party name
# + partySymbol - Party symbol
# + partyColor - Party color
# + candidateImage - Candidate image
# + popularVotes - Popular votes
# + electoralVotes - Electoral votes
# + position - Position
# + isActive - Whether candidate is active

public type Candidate record {|
    @sql:Name { value: "candidate_id" } 
    readonly string candidateId;
    @sql:Name { value: "election_id" } 
    string electionId;
    @sql:Name { value: "candidate_name" } 
    string candidateName;
    @sql:Name { value: "party_name" } 
    string partyName;
    @sql:Name { value: "party_symbol" } 
    string? partySymbol;
    @sql:Name { value: "party_color" } 
    string partyColor;
    @sql:Name { value: "candidate_image" } 
    string? candidateImage;
    @sql:Name { value: "popular_votes" } 
    int? popularVotes;
    @sql:Name { value: "electoral_votes" } 
    int? electoralVotes;
    int? position;
    @sql:Name { value: "is_active" } 
    boolean isActive;
|};

# Description for district-level election results.
#
# + districtCode - Unique code identifying the district (Primary Key)
# + electionId - ID of the election associated with the result (Foreign Key)
# + districtName - Name of the district
# + totalVotes - Total number of votes expected or registered in the district
# + votesProcessed - Number of votes that have been counted so far
# + winner - Name or ID of the winning candidate in the district (optional)
# + status - Current processing status of the district result (e.g., "in progress", "completed")


public type DistrictResult record {|
    @sql:Name { value: "district_code" } readonly string districtCode;
    @sql:Name { value: "election_id" } readonly string electionId;
    @sql:Name { value: "district_name" } string districtName;
    @sql:Name { value: "total_votes" } int totalVotes;
    @sql:Name { value: "votes_processed" } int votesProcessed;
    string? winner;
    string status;
|};

# Description for overall election summary results.
#
# + electionId - Unique ID of the election (Primary Key)
# + totalRegisteredVoters - Total number of registered voters for the election
# + totalVotesCast - Number of votes that were successfully cast
# + totalRejectedVotes - Number of votes rejected due to errors or invalidity
# + turnoutPercentage - Voter turnout as a percentage of registered voters
# + winnerCandidateId - ID of the candidate who won the election (optional)
# + electionStatus - Status of the election (e.g., "ongoing", "completed", "cancelled")


public type ElectionSummary record {|
    @sql:Name { value: "election_id" }readonly string electionId;
    @sql:Name { value: "total_registered_voters" } int totalRegisteredVoters;
    @sql:Name { value: "total_votes_cast" } int totalVotesCast;
    @sql:Name { value: "total_rejected_votes" } int totalRejectedVotes;
    @sql:Name { value: "turnout_percentage" } decimal turnoutPercentage;
    @sql:Name { value: "winner_candidate_id" } string? winnerCandidateId;
    @sql:Name { value: "election_status" } string electionStatus;
|};


public type District record {|
    @sql:Name { value: "district_id" } readonly string districtId;
    @sql:Name { value: "province_id" } string provinceId;
    @sql:Name { value: "district_name" } string districtName;
    @sql:Name { value: "total_voters" } int totalVoters;
    
|};

public type ProvinceResult record {|
    @sql:Name { value: "province_id" } readonly string provinceId;
    @sql:Name { value: "province_name" } string provinceName;
    @sql:Name { value: "total_districts" } int totalDistricts;
|};

