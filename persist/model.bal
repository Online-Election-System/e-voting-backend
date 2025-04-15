import ballerina/persist as _;
import ballerinax/persist.sql;
import ballerina/time;

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
    @sql:Name { value: "national_id" }
    string nationalId;
    @sql:Name { value: "full_name" }
    string fullName;
    @sql:Name { value: "mobile_number" }
    string? mobileNumber;
    string? dob;
    string? gender;
    @sql:Name { value: "nic_chief_occupant" }
    string? nicChiefOccupant;
    string? address;
    string? district;
    @sql:Name { value: "household_no" }
    string? householdNo;
    @sql:Name { value: "grama_niladhari" }
    string? gramaNiladhari;
    string password;
|};

# Description for elections to be insterted.
#
# + id - election id (Primary Key)
# + electionName - election title
# + description - election description
# + startDate - election start date
# + enrolDdl - election enrollment deadline
# + endDate - election end date
# + noOfCandidates - election number of candidates

public type Election record {|
    readonly string id;
    @sql:Name {value: "election_name"}
    string electionName;
    string description;
    @sql:Name {value: "start_date"}
    time:Date startDate;
    @sql:Name {value: "enrol_ddl"}
    time:Date enrolDdl;
    @sql:Name {value: "end_date"}
    time:Date endDate;
    @sql:Name {value: "no_of_candidates"}
    int noOfCandidates;
|};
