import ballerina/persist as _;
import ballerina/sql;

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
    @sql:Column { name: "id" }
    readonly string id;

    @sql:Column { name: "full_name" }
    string fullName;

    @sql:Column { name: "nic" }
    string nic;

    @sql:Column { name: "phone_number" }
    string? phoneNumber;

    @sql:Column { name: "dob" }
    string dob;

    @sql:Column { name: "gender" }
    string gender;

    @sql:Column { name: "civil_status" }
    string civilStatus;

    @sql:Column { name: "password_hash" }
    string passwordHash;

    @sql:Column { name: "email" }
    string email;

    @sql:Column { name: "id_copy_path" }
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
    @sql:Column { name: "id" }
    readonly string id;

    @sql:Column { name: "chief_occupant_id" }
    string chiefOccupantId;

    @sql:Column { name: "electoral_district" }
    string electoralDistrict;

    @sql:Column { name: "polling_division" }
    string pollingDivision;

    @sql:Column { name: "polling_district_number" }
    string pollingDistrictNumber;

    @sql:Column { name: "grama_niladhari_division" }
    string? gramaNiladhariDivision;

    @sql:Column { name: "village_street_estate" }
    string? villageStreetEstate;

    @sql:Column { name: "house_number" }
    string? houseNumber;

    @sql:Column { name: "household_member_count" }
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
    @sql:Column { name: "id" }
    readonly string id;

    @sql:Column { name: "chief_occupant_id" }
    string chiefOccupantId;

    @sql:Column { name: "full_name" }
    string fullName;

    @sql:Column { name: "nic" }
    string? nic;

    @sql:Column { name: "dob" }
    string dob;

    @sql:Column { name: "gender" }
    string gender;

    @sql:Column { name: "civil_status" }
    string civilStatus;

    @sql:Column { name: "relationship_with_chief_occupant" }
    string relationshipWithChiefOccupant;

    @sql:Column { name: "id_copy_path" }
    string? idCopyPath;

    @sql:Column { name: "approved_by_chief" }
    boolean approvedByChief;

    @sql:Column {name: "Hased_password"}
    string passwordHash;

    boolean passwordchanged;
|};
