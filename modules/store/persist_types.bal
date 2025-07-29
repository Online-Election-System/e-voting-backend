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
    string? photoCopyPath;
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
    string? photoCopyPath?;
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
    string? photoCopyPath?;
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
    string? photoCopyPath;
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
    string? photoCopyPath?;
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
    string? photoCopyPath?;
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

public type AddMemberRequest record {|
    readonly string addRequestId;
    string chiefOccupantId;
    string nicNumber;
    string fullName;
    string dateOfBirth;
    string gender;
    string civilStatus;
    string relationshipToChief;
    string chiefOccupantApproval;
    string requestStatus;
    string? nicOrBirthCertificatePath;
|};

public type AddMemberRequestOptionalized record {|
    string addRequestId?;
    string chiefOccupantId?;
    string nicNumber?;
    string fullName?;
    string dateOfBirth?;
    string gender?;
    string civilStatus?;
    string relationshipToChief?;
    string chiefOccupantApproval?;
    string requestStatus?;
    string? nicOrBirthCertificatePath?;
|};

public type AddMemberRequestTargetType typedesc<AddMemberRequestOptionalized>;

public type AddMemberRequestInsert AddMemberRequest;

public type AddMemberRequestUpdate record {|
    string chiefOccupantId?;
    string nicNumber?;
    string fullName?;
    string dateOfBirth?;
    string gender?;
    string civilStatus?;
    string relationshipToChief?;
    string chiefOccupantApproval?;
    string requestStatus?;
    string? nicOrBirthCertificatePath?;
|};

public type UpdateMemberRequest record {|
    readonly string updateRequestId;
    string chiefOccupantId;
    string? householdMemberId;
    string? newFullName;
    string? newResidentArea;
    string requestStatus;
    string? relevantCertificatePath;
|};

public type UpdateMemberRequestOptionalized record {|
    string updateRequestId?;
    string chiefOccupantId?;
    string? householdMemberId?;
    string? newFullName?;
    string? newResidentArea?;
    string requestStatus?;
    string? relevantCertificatePath?;
|};

public type UpdateMemberRequestTargetType typedesc<UpdateMemberRequestOptionalized>;

public type UpdateMemberRequestInsert UpdateMemberRequest;

public type UpdateMemberRequestUpdate record {|
    string chiefOccupantId?;
    string? householdMemberId?;
    string? newFullName?;
    string? newResidentArea?;
    string requestStatus?;
    string? relevantCertificatePath?;
|};

public type DeleteMemberRequest record {|
    readonly string deleteRequestId;
    string chiefOccupantId;
    string? householdMemberId;
    string requestStatus;
    string? requiredDocumentPath;
|};

public type DeleteMemberRequestOptionalized record {|
    string deleteRequestId?;
    string chiefOccupantId?;
    string? householdMemberId?;
    string requestStatus?;
    string? requiredDocumentPath?;
|};

public type DeleteMemberRequestTargetType typedesc<DeleteMemberRequestOptionalized>;

public type DeleteMemberRequestInsert DeleteMemberRequest;

public type DeleteMemberRequestUpdate record {|
    string chiefOccupantId?;
    string? householdMemberId?;
    string requestStatus?;
    string? requiredDocumentPath?;
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

public type RemovalRequest record {|
    readonly string id;
    string memberName;
    string nic;
    string requestedBy;
    string reason;
    string proofDocument;
    string status;
|};

public type RemovalRequestOptionalized record {|
    string id?;
    string memberName?;
    string nic?;
    string requestedBy?;
    string reason?;
    string proofDocument?;
    string status?;
|};

public type RemovalRequestTargetType typedesc<RemovalRequestOptionalized>;

public type RemovalRequestInsert RemovalRequest;

public type RemovalRequestUpdate record {|
    string memberName?;
    string nic?;
    string requestedBy?;
    string reason?;
    string proofDocument?;
    string status?;
|};

public type RegistrationReview record {|
    readonly string id;
    string memberNic;
    string reviewedBy;
    string status;
    string? comments;
    time:Utc? reviewedAt;
|};

public type RegistrationReviewOptionalized record {|
    string id?;
    string memberNic?;
    string reviewedBy?;
    string status?;
    string? comments?;
    time:Utc? reviewedAt?;
|};

public type RegistrationReviewTargetType typedesc<RegistrationReviewOptionalized>;

public type RegistrationReviewInsert RegistrationReview;

public type RegistrationReviewUpdate record {|
    string memberNic?;
    string reviewedBy?;
    string status?;
    string? comments?;
    time:Utc? reviewedAt?;
|};

public type GramaNiladhari record {|
    readonly string id;
    string fullName;
    string nic;
    string dateOfBirth;
    string email;
    string officePhone;
    string mobileNumber;
    string residentialAddress;
    string officialTitle;
    string employeeId;
    string appointmentDate;
    string gnDivision;
    string district;
    string province;
    string officeAddress;
    string qualifications;
    string experience;
|};

public type GramaNiladhariOptionalized record {|
    string id?;
    string fullName?;
    string nic?;
    string dateOfBirth?;
    string email?;
    string officePhone?;
    string mobileNumber?;
    string residentialAddress?;
    string officialTitle?;
    string employeeId?;
    string appointmentDate?;
    string gnDivision?;
    string district?;
    string province?;
    string officeAddress?;
    string qualifications?;
    string experience?;
|};

public type GramaNiladhariTargetType typedesc<GramaNiladhariOptionalized>;

public type GramaNiladhariInsert GramaNiladhari;

public type GramaNiladhariUpdate record {|
    string fullName?;
    string nic?;
    string dateOfBirth?;
    string email?;
    string officePhone?;
    string mobileNumber?;
    string residentialAddress?;
    string officialTitle?;
    string employeeId?;
    string appointmentDate?;
    string gnDivision?;
    string district?;
    string province?;
    string officeAddress?;
    string qualifications?;
    string experience?;
|};

public type Notification record {|
    readonly string id;
    string title;
    string message;
    string? link;
    time:Utc createdAt;
    string status;
    string recipientNic;
|};

public type NotificationOptionalized record {|
    string id?;
    string title?;
    string message?;
    string? link?;
    time:Utc createdAt?;
    string status?;
    string recipientNic?;
|};

public type NotificationTargetType typedesc<NotificationOptionalized>;

public type NotificationInsert Notification;

public type NotificationUpdate record {|
    string title?;
    string message?;
    string? link?;
    time:Utc createdAt?;
    string status?;
    string recipientNic?;
|};

public type Voter record {|
    readonly string id;
    string nationalId;
    string name;
    string password;
    string district;
    string pollingStation;
    time:Date registrationDate;
    string status;
|};

public type VoterOptionalized record {|
    string id?;
    string nationalId?;
    string name?;
    string password?;
    string district?;
    string pollingStation?;
    time:Date registrationDate?;
    string status?;
|};

public type VoterTargetType typedesc<VoterOptionalized>;

public type VoterInsert Voter;

public type VoterUpdate record {|
    string nationalId?;
    string name?;
    string password?;
    string district?;
    string pollingStation?;
    time:Date registrationDate?;
    string status?;
|};

public type CandidateDistrictVoteSummary record {|
    readonly string electionId;
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

public type CandidateDistrictVoteSummaryOptionalized record {|
    string electionId?;
    string candidateId?;
    int ampara?;
    int anuradhapura?;
    int badulla?;
    int batticaloa?;
    int colombo?;
    int galle?;
    int gampaha?;
    int hambantota?;
    int jaffna?;
    int kalutara?;
    int kandy?;
    int kegalle?;
    int kilinochchi?;
    int kurunegala?;
    int mannar?;
    int matale?;
    int matara?;
    int monaragala?;
    int mullaitivu?;
    int nuwaraeliya?;
    int polonnaruwa?;
    int puttalam?;
    int ratnapura?;
    int trincomalee?;
    int vavuniya?;
    int totals?;
|};

public type CandidateDistrictVoteSummaryTargetType typedesc<CandidateDistrictVoteSummaryOptionalized>;

public type CandidateDistrictVoteSummaryInsert CandidateDistrictVoteSummary;

public type CandidateDistrictVoteSummaryUpdate record {|
    int ampara?;
    int anuradhapura?;
    int badulla?;
    int batticaloa?;
    int colombo?;
    int galle?;
    int gampaha?;
    int hambantota?;
    int jaffna?;
    int kalutara?;
    int kandy?;
    int kegalle?;
    int kilinochchi?;
    int kurunegala?;
    int mannar?;
    int matale?;
    int matara?;
    int monaragala?;
    int mullaitivu?;
    int nuwaraeliya?;
    int polonnaruwa?;
    int puttalam?;
    int ratnapura?;
    int trincomalee?;
    int vavuniya?;
    int totals?;
|};

