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
# + photoCopyPath - File Path of Image
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
    @sql:Name {value: "photo_copy_path"}
    string? photoCopyPath;
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
# + photoCopyPath - File Path of Image
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
    @sql:Name {value: "photo_copy_path"}
    string? photoCopyPath;
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

// -- Registration Reviews Table --
# Description.
#
# + id - field description  
# + memberNic - field description  
# + status - field description  
# + reason - field description  
# + reviewedAt - field description
public type RegistrationReview record {|
    readonly string id;
    @sql:Name { value: "member_nic" }
    string memberNic;
    string status; // pending, approved, rejected
    string? reason;
    @sql:Name { value: "reviewed_at" }
    time:Utc? reviewedAt;
|};


// -- Grama Niladhari Table --
public type GramaNiladhari record {|
    readonly string id;
    @sql:Name { value: "full_name" }
    string fullName;
    string nic;
    @sql:Name { value: "date_of_birth" }
    string dateOfBirth;
    string email;
    @sql:Name { value: "office_phone" }
    string officePhone;
    @sql:Name { value: "mobile_number" }
    string mobileNumber;
    @sql:Name { value: "residential_address" }
    string residentialAddress;
    @sql:Name { value: "official_title" }
    string officialTitle;
    @sql:Name { value: "employee_id" }
    string employeeId;
    @sql:Name { value: "appointment_date" }
    string appointmentDate;
    @sql:Name { value: "gn_division" }
    string gnDivision;
    string district;
    string province;
    @sql:Name { value: "office_address" }
    string officeAddress;
    string qualifications;
    string experience;
|};

// -- Notifications Table --
public type Notification record {|
    readonly string id;
    string title;
    string message;
    string? link; // e.g., to view the action
    @sql:Name { value: "created_at" }
    time:Utc createdAt;
    string status; // unread, read
    @sql:Name { value: "recipient_nic" }
    string recipientNic;
|};

# Voter entity.
#
# + id - Voter ID (Auto-incrementing Primary Key)
# + nationalId - National Identity Card Number (Unique Identifier)
# + name - Full name of the voter
# + password - Login password (hashed)
# + district - Voter's district
# + pollingStation - Voter's polling station
# + registrationDate - Registration date
# + status - ACTIVE / INACTIVE
public type Voter record {|
    readonly string id;
    @sql:Name { value: "national_id" }
    string nationalId;
    string name;
    string password;
    string district;
    @sql:Name { value: "polling_station" }
    string pollingStation;
    @sql:Name { value: "registration_date" }
    time:Date registrationDate;
    string status;
|};

# Description.
#
# + addRequestId - field description  
# + chiefOccupantId - field description  
# + nicNumber - field description  
# + fullName - field description  
# + dateOfBirth - field description  
# + gender - field description  
# + civilStatus - field description  
# + relationshipToChief - field description  
# + chiefOccupantApproval - field description  
# + requestStatus - field description  
# + reason - field description
# + nicOrBirthCertificatePath - field description
public type AddMemberRequest record {|
    @sql:Name {value: "add_request_id"}
    readonly string addRequestId;
    @sql:Name {value: "chief_occupant_id"}
    string chiefOccupantId;
    @sql:Name {value: "nic_number"}
    string nicNumber;
    @sql:Name {value: "full_name"}
    string fullName;
    @sql:Name {value: "date_of_birth"}
    string dateOfBirth;
    string gender; 
    @sql:Name {value: "civil_status"}
    string civilStatus;
    @sql:Name {value: "relationship_to_chief"}
    string relationshipToChief;
    @sql:Name {value: "chief_occupant_approval"}
    string chiefOccupantApproval; 
    @sql:Name {value: "request_status"}
    string? requestStatus;
    string? reason;
    @sql:Name {value: "nic_or_birth_certificate_path"}
    string? nicOrBirthCertificatePath;
|};

# Description.
#
# + updateRequestId - field description  
# + chiefOccupantId - field description  
# + householdMemberId - field description  
# + newFullName - field description  
# + newResidentArea - field description  
# + requestStatus - field description 
# + reason - field description  
# + relevantCertificatePath - field description
public type UpdateMemberRequest record {|
    @sql:Name {value: "update_request_id"}
    readonly string updateRequestId;
    @sql:Name {value: "chief_occupant_id"}
    string chiefOccupantId;
    @sql:Name {value: "household_member_id"}
    string? householdMemberId;
    @sql:Name {value: "new_full_name"}
    string? newFullName;
    @sql:Name {value: "new_resident_area"}
    string? newResidentArea;
    @sql:Name {value: "request_status"}
    string? requestStatus;
    string? reason;
    @sql:Name {value: "relevant_certificate_path"}
    string? relevantCertificatePath;
|};

# Description.
#
# + deleteRequestId - field description  
# + chiefOccupantId - field description  
# + householdMemberId - field description  
# + requestStatus - field description  
# + reason - field description 
# + requiredDocumentPath - field description
public type DeleteMemberRequest record {|
    @sql:Name {value: "delete_request_id"}
    readonly string deleteRequestId;
    @sql:Name {value: "chief_occupant_id"}
    string chiefOccupantId; 
    @sql:Name {value: "household_member_id"}
    string? householdMemberId; 
    @sql:Name {value: "request_status"}
    string? requestStatus;
    string? reason; 
    @sql:Name {value: "required_document_path"}
    string? requiredDocumentPath;
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
# + nuwaraeliya - field description
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
    int nuwaraeliya;
    int polonnaruwa;
    int puttalam;
    int ratnapura;
    int trincomalee;
    int vavuniya;
    int totals;
|};
