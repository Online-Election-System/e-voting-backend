import ballerina/persist as _;
import ballerina/time;
import ballerinax/persist.sql;

# + candidateId - candidateId (primary key)
# + candidateName - candidateName
# + partyName - partyName
# + partySymbol - partySymbol
# + partyColor - partyColor
# + candidateImage - candidateImage
# + isActive - isActive

public type Candidate record {|
    @sql:Name {value: "candidate_id"}
    readonly string candidateId;
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
    @sql:Name {value: "is_active"}
    boolean isActive;
|};

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
# + chiefOccupantId - Foreign Key (ChiefOccupant)https://claude.ai/new
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

# Description.
#
# + id - field description  
# + username - field description  
# + email - field description  
# + passwordHash - field description  
# + role - field description  
# + createdAt - field description  
# + isActive - field description
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

# Description.
#
# + electionId - election id
# + candidateId - candidate id
# + numberOfVotes - number of votes the candidate got for the specific election
public type EnrolCandidates record {|
    @sql:Name {value: "election_id"}
    readonly string electionId;
    @sql:Name {value: "candidate_id"}
    readonly string candidateId;
    @sql:Name {value: "number_of_votes"}
    int? numberOfVotes;
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

# Description for enrol to be inserted.

# + voterId - Voter ID (foreign key) - can reference either ChiefOccupant or HouseholdMembers
# + electionId - Election ID (foreign key)
# + enrollementDate - Date of enrolment

public type Enrolment record {|

    @sql:Name { value: "voter_id" }
    readonly string voterId;
    @sql:Name { value: "election_id" }
    readonly string electionId;
    @sql:Name {value: "enrollement_date"}
    time:Utc enrollementDate;
|};

# Description.
#
# + electionId - foreign key reference to the Election record
# + candidateId - foreign key reference to the Candidate record
# + ampara - number of votes in the Ampara district
# + anuradhapura - number of votes in the Anuradhapura district
# + badulla - number of votes in the Badulla district
# + batticaloa - number of votes in the Batticaloa district
# + colombo - field description
# + galle - field description
# + gampaha - field description
# + hambantota - field description
# + jaffna - field description
# + kalutara - field description
# + kandy - field description
# + kegalle - field description
# + kilinochchi - field description
# + kurunegala - field description
# + mannar - field description
# + matale - field description
# + matara - field description
# + monaragala - field description
# + mullaitivu - field description
# + nuwaraEliya - field description
# + polonnaruwa - field description
# + puttalam - field description
# + ratnapura - field description
# + trincomalee - field description
# + vavuniya - field description
# + totals - field description
public type CandidateDistrictVoteSummary record {|
    @sql:Name { value: "election_id" }
    readonly string electionId;

    @sql:Name { value: "candidate_id" }
    readonly string candidateId;
    int ampara;
    int anuradhapura;
    int badulla;
    int batticaloa;
    int colombo;
    int galle;
    int gampaha;
    int hambantota;
    int jaffna;
    int kalutara;
    int kandy;
    int kegalle;
    int kilinochchi;
    int kurunegala;
    int mannar;
    int matale;
    int matara;
    int monaragala;
    int mullaitivu;
    int nuwaraEliya;
    int polonnaruwa;
    int puttalam;
    int ratnapura;
    int trincomalee;
    int vavuniya;
    int totals;
|};