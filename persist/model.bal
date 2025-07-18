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
