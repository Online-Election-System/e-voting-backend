import ballerina/persist as _;
import ballerina/sql;

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
    @sql:Column { name: "id" }
    readonly int id;   // Identity field must be readonly

    @sql:Column { name: "national_id" }
    string nationalId; // Unique National ID (not optional)

    @sql:Column { name: "full_name" }
    string fullName;

    @sql:Column { name: "mobile_number" }
    string? mobileNumber; // Use `?` for nullable fields

    @sql:Column { name: "dob" }
    string? dob;

    @sql:Column { name: "gender" }
    string? gender;

    @sql:Column { name: "nic_chief_occupant" }
    string? nicChiefOccupant;

    @sql:Column { name: "address" }
    string? address;

    @sql:Column { name: "district" }
    string? district;

    @sql:Column { name: "household_no" }
    string? householdNo;

    @sql:Column { name: "grama_niladhari" }
    string? gramaNiladhari;

    @sql:Column { name: "password" }
    string password;
|};






