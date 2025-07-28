// AUTO-GENERATED FILE. DO NOT MODIFY.

// This file is an auto-generated file by Ballerina persistence layer for model.
// It should not be modified by hand.

import ballerina/time;

public type Candidate record {|
    readonly string candidateId;
    string candidateName;
    string partyName;
    string? partySymbol;
    string partyColor;
    string? candidateImage;
    boolean isActive;
|};

public type CandidateOptionalized record {|
    string candidateId?;
    string candidateName?;
    string partyName?;
    string? partySymbol?;
    string partyColor?;
    string? candidateImage?;
    boolean isActive?;
|};

public type CandidateTargetType typedesc<CandidateOptionalized>;

public type CandidateInsert Candidate;

public type CandidateUpdate record {|
    string candidateName?;
    string partyName?;
    string? partySymbol?;
    string partyColor?;
    string? candidateImage?;
    boolean isActive?;
|};

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
    string role;
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
    string role?;
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
    string role?;
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
    string role;
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
    string role?;
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
    string role?;
|};

public type Election record {|
    readonly string id;
    string electionName;
    string description;
    time:Date startDate;
    time:Date enrolDdl;
    time:Date electionDate;
    time:Date endDate;
    int noOfCandidates;
    string electionType;
    time:TimeOfDay startTime;
    time:TimeOfDay endTime;
    string status;
|};

public type ElectionOptionalized record {|
    string id?;
    string electionName?;
    string description?;
    time:Date startDate?;
    time:Date enrolDdl?;
    time:Date electionDate?;
    time:Date endDate?;
    int noOfCandidates?;
    string electionType?;
    time:TimeOfDay startTime?;
    time:TimeOfDay endTime?;
    string status?;
|};

public type ElectionTargetType typedesc<ElectionOptionalized>;

public type ElectionInsert Election;

public type ElectionUpdate record {|
    string electionName?;
    string description?;
    time:Date startDate?;
    time:Date enrolDdl?;
    time:Date electionDate?;
    time:Date endDate?;
    int noOfCandidates?;
    string electionType?;
    time:TimeOfDay startTime?;
    time:TimeOfDay endTime?;
    string status?;
|};

public type AdminUsers record {|
    readonly string id;
    string username;
    string email;
    string passwordHash;
    string role;
    time:Utc createdAt;
    boolean isActive;
|};

public type AdminUsersOptionalized record {|
    string id?;
    string username?;
    string email?;
    string passwordHash?;
    string role?;
    time:Utc createdAt?;
    boolean isActive?;
|};

public type AdminUsersTargetType typedesc<AdminUsersOptionalized>;

public type AdminUsersInsert AdminUsers;

public type AdminUsersUpdate record {|
    string username?;
    string email?;
    string passwordHash?;
    string role?;
    time:Utc createdAt?;
    boolean isActive?;
|};

public type EnrolCandidates record {|
    readonly string electionId;
    readonly string candidateId;
    int? numberOfVotes;
|};

public type EnrolCandidatesOptionalized record {|
    string electionId?;
    string candidateId?;
    int? numberOfVotes?;
|};

public type EnrolCandidatesTargetType typedesc<EnrolCandidatesOptionalized>;

public type EnrolCandidatesInsert EnrolCandidates;

public type EnrolCandidatesUpdate record {|
    int? numberOfVotes?;
|};

public type Vote record {|
    readonly string id;
    string voterId;
    string electionId;
    string candidateId;
    string district;
    string timestamp;
|};

public type VoteOptionalized record {|
    string id?;
    string voterId?;
    string electionId?;
    string candidateId?;
    string district?;
    string timestamp?;
|};

public type VoteTargetType typedesc<VoteOptionalized>;

public type VoteInsert Vote;

public type VoteUpdate record {|
    string voterId?;
    string electionId?;
    string candidateId?;
    string district?;
    string timestamp?;
|};

public type Enrolment record {|
    readonly string voterId;
    readonly string electionId;
    time:Utc enrollementDate;
|};

public type EnrolmentOptionalized record {|
    string voterId?;
    string electionId?;
    time:Utc enrollementDate?;
|};

public type EnrolmentTargetType typedesc<EnrolmentOptionalized>;

public type EnrolmentInsert Enrolment;

public type EnrolmentUpdate record {|
    time:Utc enrollementDate?;
|};

public type CandidateDistrictVoteSummary record {|
    readonly string electionId;
    readonly string candidateId;
    int Ampara;
    int Anuradhapura;
    int Badulla;
    int Batticaloa;
    int Colombo;
    int Galle;
    int Gampaha;
    int Hambantota;
    int Jaffna;
    int Kalutara;
    int Kandy;
    int Kegalle;
    int Kilinochchi;
    int Kurunegala;
    int Mannar;
    int Matale;
    int Matara;
    int Monaragala;
    int Mullaitivu;
    int NuwaraEliya;
    int Polonnaruwa;
    int Puttalam;
    int Ratnapura;
    int Trincomalee;
    int Vavuniya;
    int Totals;
|};

public type CandidateDistrictVoteSummaryOptionalized record {|
    string electionId?;
    string candidateId?;
    int Ampara?;
    int Anuradhapura?;
    int Badulla?;
    int Batticaloa?;
    int Colombo?;
    int Galle?;
    int Gampaha?;
    int Hambantota?;
    int Jaffna?;
    int Kalutara?;
    int Kandy?;
    int Kegalle?;
    int Kilinochchi?;
    int Kurunegala?;
    int Mannar?;
    int Matale?;
    int Matara?;
    int Monaragala?;
    int Mullaitivu?;
    int NuwaraEliya?;
    int Polonnaruwa?;
    int Puttalam?;
    int Ratnapura?;
    int Trincomalee?;
    int Vavuniya?;
    int Totals?;
|};

public type CandidateDistrictVoteSummaryTargetType typedesc<CandidateDistrictVoteSummaryOptionalized>;

public type CandidateDistrictVoteSummaryInsert CandidateDistrictVoteSummary;

public type CandidateDistrictVoteSummaryUpdate record {|
    int Ampara?;
    int Anuradhapura?;
    int Badulla?;
    int Batticaloa?;
    int Colombo?;
    int Galle?;
    int Gampaha?;
    int Hambantota?;
    int Jaffna?;
    int Kalutara?;
    int Kandy?;
    int Kegalle?;
    int Kilinochchi?;
    int Kurunegala?;
    int Mannar?;
    int Matale?;
    int Matara?;
    int Monaragala?;
    int Mullaitivu?;
    int NuwaraEliya?;
    int Polonnaruwa?;
    int Puttalam?;
    int Ratnapura?;
    int Trincomalee?;
    int Vavuniya?;
    int Totals?;
|};

