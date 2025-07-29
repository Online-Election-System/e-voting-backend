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

public type UpdateMemberRequest record {|
    readonly string updateRequestId;
    string chiefOccupantId;
    string householdMemberId;
    string? newFullName;
    string? newResidentArea;
    string requestStatus;
    string? relevantCertificatePath;
|};

public type DeleteMemberRequest record {|
    readonly string deleteRequestId;
    string chiefOccupantId;
    string householdMemberId;
    string requestStatus;
    string? requiredDocumentPath;
|};
