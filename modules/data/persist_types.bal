// AUTO-GENERATED FILE. DO NOT MODIFY.

// This file is an auto-generated file by Ballerina persistence layer for model.
// It should not be modified by hand.

public type ChiefOccupant record {|
    readonly string id;
    string fullName;
    string nic;
    string? phoneNumber;
    string dob;
    string gender;
    string civilStatus;
    string passwordHash;
    string email;
    string? idCopyPath;
|};

public type ChiefOccupantOptionalized record {|
    string id?;
    string fullName?;
    string nic?;
    string? phoneNumber?;
    string dob?;
    string gender?;
    string civilStatus?;
    string passwordHash?;
    string email?;
    string? idCopyPath?;
|};

public type ChiefOccupantTargetType typedesc<ChiefOccupantOptionalized>;

public type ChiefOccupantInsert ChiefOccupant;

public type ChiefOccupantUpdate record {|
    string fullName?;
    string nic?;
    string? phoneNumber?;
    string dob?;
    string gender?;
    string civilStatus?;
    string passwordHash?;
    string email?;
    string? idCopyPath?;
|};

public type HouseholdDetails record {|
    readonly string id;
    string chiefOccupantId;
    string electoralDistrict;
    string pollingDivision;
    string pollingDistrictNumber;
    string? gramaNiladhariDivision;
    string? villageStreetEstate;
    string? houseNumber;
    int householdMemberCount;
|};

public type HouseholdDetailsOptionalized record {|
    string id?;
    string chiefOccupantId?;
    string electoralDistrict?;
    string pollingDivision?;
    string pollingDistrictNumber?;
    string? gramaNiladhariDivision?;
    string? villageStreetEstate?;
    string? houseNumber?;
    int householdMemberCount?;
|};

public type HouseholdDetailsTargetType typedesc<HouseholdDetailsOptionalized>;

public type HouseholdDetailsInsert HouseholdDetails;

public type HouseholdDetailsUpdate record {|
    string chiefOccupantId?;
    string electoralDistrict?;
    string pollingDivision?;
    string pollingDistrictNumber?;
    string? gramaNiladhariDivision?;
    string? villageStreetEstate?;
    string? houseNumber?;
    int householdMemberCount?;
|};

public type HouseholdMembers record {|
    readonly string id;
    string chiefOccupantId;
    string fullName;
    string? nic;
    string dob;
    string gender;
    string civilStatus;
    string relationshipWithChiefOccupant;
    string? idCopyPath;
    boolean approvedByChief;
    string passwordHash;
    boolean passwordchanged;
|};

public type HouseholdMembersOptionalized record {|
    string id?;
    string chiefOccupantId?;
    string fullName?;
    string? nic?;
    string dob?;
    string gender?;
    string civilStatus?;
    string relationshipWithChiefOccupant?;
    string? idCopyPath?;
    boolean approvedByChief?;
    string passwordHash?;
    boolean passwordchanged?;
|};

public type HouseholdMembersTargetType typedesc<HouseholdMembersOptionalized>;

public type HouseholdMembersInsert HouseholdMembers;

public type HouseholdMembersUpdate record {|
    string chiefOccupantId?;
    string fullName?;
    string? nic?;
    string dob?;
    string gender?;
    string civilStatus?;
    string relationshipWithChiefOccupant?;
    string? idCopyPath?;
    boolean approvedByChief?;
    string passwordHash?;
    boolean passwordchanged?;
|};

