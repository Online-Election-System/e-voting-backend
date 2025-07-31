// AUTO-GENERATED FILE. DO NOT MODIFY.

// This file is an auto-generated file by Ballerina persistence layer for model.
// It should not be modified by hand.

import ballerina/jballerina.java;
import ballerina/persist;
import ballerina/sql;
import ballerinax/persist.sql as psql;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;

const CANDIDATE = "candidates";
const CHIEF_OCCUPANT = "chiefoccupants";
const HOUSEHOLD_DETAILS = "householddetails";
const HOUSEHOLD_MEMBERS = "householdmembers";
const ELECTION = "elections";
const ADMIN_USERS = "adminusers";
const ENROL_CANDIDATES = "enrolcandidates";
const VOTE = "votes";
const ENROLMENT = "enrolments";
const REGISTRATION_REVIEW = "registrationreviews";
const GRAMA_NILADHARI = "gramaniladharis";
const NOTIFICATION = "notifications";
const VOTER = "voters";
const ADD_MEMBER_REQUEST = "addmemberrequests";
const UPDATE_MEMBER_REQUEST = "updatememberrequests";
const DELETE_MEMBER_REQUEST = "deletememberrequests";
const CANDIDATE_DISTRICT_VOTE_SUMMARY = "candidatedistrictvotesummaries";

public isolated client class Client {
    *persist:AbstractPersistClient;

    private final postgresql:Client dbClient;

    private final map<psql:SQLClient> persistClients;

    private final record {|psql:SQLMetadata...;|} metadata = {
        [CANDIDATE]: {
            entityName: "Candidate",
            tableName: "Candidate",
            fieldMetadata: {
                candidateId: {columnName: "candidate_id"},
                candidateName: {columnName: "candidate_name"},
                partyName: {columnName: "party_name"},
                partySymbol: {columnName: "party_symbol"},
                partyColor: {columnName: "party_color"},
                candidateImage: {columnName: "candidate_image"},
                isActive: {columnName: "is_active"}
            },
            keyFields: ["candidateId"]
        },
        [CHIEF_OCCUPANT]: {
            entityName: "ChiefOccupant",
            tableName: "ChiefOccupant",
            fieldMetadata: {
                id: {columnName: "id"},
                fullName: {columnName: "full_name"},
                nic: {columnName: "nic"},
                phoneNumber: {columnName: "phone_number"},
                dob: {columnName: "dob"},
                gender: {columnName: "gender"},
                civilStatus: {columnName: "civil_status"},
                passwordHash: {columnName: "password_hash"},
                email: {columnName: "email"},
                idCopyPath: {columnName: "id_copy_path"},
                photoCopyPath: {columnName: "photo_copy_path"},
                role: {columnName: "role"}
            },
            keyFields: ["id"]
        },
        [HOUSEHOLD_DETAILS]: {
            entityName: "HouseholdDetails",
            tableName: "HouseholdDetails",
            fieldMetadata: {
                id: {columnName: "id"},
                chiefOccupantId: {columnName: "chief_occupant_id"},
                electoralDistrict: {columnName: "electoral_district"},
                pollingDivision: {columnName: "polling_division"},
                pollingDistrictNumber: {columnName: "polling_district_number"},
                gramaNiladhariDivision: {columnName: "grama_niladhari_division"},
                villageStreetEstate: {columnName: "village_street_estate"},
                houseNumber: {columnName: "house_number"},
                householdMemberCount: {columnName: "household_member_count"}
            },
            keyFields: ["id"]
        },
        [HOUSEHOLD_MEMBERS]: {
            entityName: "HouseholdMembers",
            tableName: "HouseholdMembers",
            fieldMetadata: {
                id: {columnName: "id"},
                chiefOccupantId: {columnName: "chief_occupant_id"},
                fullName: {columnName: "full_name"},
                nic: {columnName: "nic"},
                dob: {columnName: "dob"},
                gender: {columnName: "gender"},
                civilStatus: {columnName: "civil_status"},
                relationshipWithChiefOccupant: {columnName: "relationship_with_chief_occupant"},
                idCopyPath: {columnName: "id_copy_path"},
                photoCopyPath: {columnName: "photo_copy_path"},
                approvedByChief: {columnName: "approved_by_chief"},
                passwordHash: {columnName: "Hased_password"},
                passwordchanged: {columnName: "passwordchanged"},
                role: {columnName: "role"}
            },
            keyFields: ["id"]
        },
        [ELECTION]: {
            entityName: "Election",
            tableName: "Election",
            fieldMetadata: {
                id: {columnName: "id"},
                electionName: {columnName: "election_name"},
                description: {columnName: "description"},
                startDate: {columnName: "start_date"},
                enrolDdl: {columnName: "enrol_ddl"},
                electionDate: {columnName: "election_date"},
                endDate: {columnName: "end_date"},
                noOfCandidates: {columnName: "no_of_candidates"},
                electionType: {columnName: "election_type"},
                startTime: {columnName: "start_time"},
                endTime: {columnName: "end_time"},
                status: {columnName: "status"}
            },
            keyFields: ["id"]
        },
        [ADMIN_USERS]: {
            entityName: "AdminUsers",
            tableName: "AdminUsers",
            fieldMetadata: {
                id: {columnName: "id"},
                username: {columnName: "username"},
                email: {columnName: "email"},
                passwordHash: {columnName: "password_hash"},
                role: {columnName: "role"},
                createdAt: {columnName: "created_at"},
                isActive: {columnName: "is_active"}
            },
            keyFields: ["id"]
        },
        [ENROL_CANDIDATES]: {
            entityName: "EnrolCandidates",
            tableName: "EnrolCandidates",
            fieldMetadata: {
                electionId: {columnName: "election_id"},
                candidateId: {columnName: "candidate_id"},
                numberOfVotes: {columnName: "number_of_votes"}
            },
            keyFields: ["electionId", "candidateId"]
        },
        [VOTE]: {
            entityName: "Vote",
            tableName: "Vote",
            fieldMetadata: {
                id: {columnName: "id"},
                voterId: {columnName: "voter_id"},
                electionId: {columnName: "election_id"},
                candidateId: {columnName: "candidate_id"},
                district: {columnName: "district"},
                timestamp: {columnName: "timestamp"}
            },
            keyFields: ["id"]
        },
        [ENROLMENT]: {
            entityName: "Enrolment",
            tableName: "Enrolment",
            fieldMetadata: {
                voterId: {columnName: "voter_id"},
                electionId: {columnName: "election_id"},
                enrollementDate: {columnName: "enrollement_date"}
            },
            keyFields: ["voterId", "electionId"]
        },
        [REGISTRATION_REVIEW]: {
            entityName: "RegistrationReview",
            tableName: "RegistrationReview",
            fieldMetadata: {
                id: {columnName: "id"},
                memberNic: {columnName: "member_nic"},
                status: {columnName: "status"},
                reason: {columnName: "reason"},
                reviewedAt: {columnName: "reviewed_at"}
            },
            keyFields: ["id"]
        },
        [GRAMA_NILADHARI]: {
            entityName: "GramaNiladhari",
            tableName: "GramaNiladhari",
            fieldMetadata: {
                id: {columnName: "id"},
                fullName: {columnName: "full_name"},
                nic: {columnName: "nic"},
                dateOfBirth: {columnName: "date_of_birth"},
                email: {columnName: "email"},
                officePhone: {columnName: "office_phone"},
                mobileNumber: {columnName: "mobile_number"},
                residentialAddress: {columnName: "residential_address"},
                officialTitle: {columnName: "official_title"},
                employeeId: {columnName: "employee_id"},
                appointmentDate: {columnName: "appointment_date"},
                gnDivision: {columnName: "gn_division"},
                district: {columnName: "district"},
                province: {columnName: "province"},
                officeAddress: {columnName: "office_address"},
                qualifications: {columnName: "qualifications"},
                experience: {columnName: "experience"}
            },
            keyFields: ["id"]
        },
        [NOTIFICATION]: {
            entityName: "Notification",
            tableName: "Notification",
            fieldMetadata: {
                id: {columnName: "id"},
                title: {columnName: "title"},
                message: {columnName: "message"},
                link: {columnName: "link"},
                createdAt: {columnName: "created_at"},
                status: {columnName: "status"},
                recipientNic: {columnName: "recipient_nic"}
            },
            keyFields: ["id"]
        },
        [VOTER]: {
            entityName: "Voter",
            tableName: "Voter",
            fieldMetadata: {
                id: {columnName: "id"},
                nationalId: {columnName: "national_id"},
                name: {columnName: "name"},
                password: {columnName: "password"},
                district: {columnName: "district"},
                pollingStation: {columnName: "polling_station"},
                registrationDate: {columnName: "registration_date"},
                status: {columnName: "status"}
            },
            keyFields: ["id"]
        },
        [ADD_MEMBER_REQUEST]: {
            entityName: "AddMemberRequest",
            tableName: "AddMemberRequest",
            fieldMetadata: {
                addRequestId: {columnName: "add_request_id"},
                chiefOccupantId: {columnName: "chief_occupant_id"},
                nicNumber: {columnName: "nic_number"},
                fullName: {columnName: "full_name"},
                dateOfBirth: {columnName: "date_of_birth"},
                gender: {columnName: "gender"},
                civilStatus: {columnName: "civil_status"},
                relationshipToChief: {columnName: "relationship_to_chief"},
                chiefOccupantApproval: {columnName: "chief_occupant_approval"},
                requestStatus: {columnName: "request_status"},
                reason: {columnName: "reason"},
                nicOrBirthCertificatePath: {columnName: "nic_or_birth_certificate_path"}
            },
            keyFields: ["addRequestId"]
        },
        [UPDATE_MEMBER_REQUEST]: {
            entityName: "UpdateMemberRequest",
            tableName: "UpdateMemberRequest",
            fieldMetadata: {
                updateRequestId: {columnName: "update_request_id"},
                chiefOccupantId: {columnName: "chief_occupant_id"},
                householdMemberId: {columnName: "household_member_id"},
                newFullName: {columnName: "new_full_name"},
                newResidentArea: {columnName: "new_resident_area"},
                requestStatus: {columnName: "request_status"},
                reason: {columnName: "reason"},
                relevantCertificatePath: {columnName: "relevant_certificate_path"}
            },
            keyFields: ["updateRequestId"]
        },
        [DELETE_MEMBER_REQUEST]: {
            entityName: "DeleteMemberRequest",
            tableName: "DeleteMemberRequest",
            fieldMetadata: {
                deleteRequestId: {columnName: "delete_request_id"},
                chiefOccupantId: {columnName: "chief_occupant_id"},
                householdMemberId: {columnName: "household_member_id"},
                requestStatus: {columnName: "request_status"},
                reason: {columnName: "reason"},
                requiredDocumentPath: {columnName: "required_document_path"}
            },
            keyFields: ["deleteRequestId"]
        },
        [CANDIDATE_DISTRICT_VOTE_SUMMARY]: {
            entityName: "CandidateDistrictVoteSummary",
            tableName: "CandidateDistrictVoteSummary",
            fieldMetadata: {
                electionId: {columnName: "election_id"},
                candidateId: {columnName: "candidate_id"},
                ampara: {columnName: "ampara"},
                anuradhapura: {columnName: "anuradhapura"},
                badulla: {columnName: "badulla"},
                batticaloa: {columnName: "batticaloa"},
                colombo: {columnName: "colombo"},
                galle: {columnName: "galle"},
                gampaha: {columnName: "gampaha"},
                hambantota: {columnName: "hambantota"},
                jaffna: {columnName: "jaffna"},
                kalutara: {columnName: "kalutara"},
                kandy: {columnName: "kandy"},
                kegalle: {columnName: "kegalle"},
                kilinochchi: {columnName: "kilinochchi"},
                kurunegala: {columnName: "kurunegala"},
                mannar: {columnName: "mannar"},
                matale: {columnName: "matale"},
                matara: {columnName: "matara"},
                monaragala: {columnName: "monaragala"},
                mullaitivu: {columnName: "mullaitivu"},
                nuwaraeliya: {columnName: "nuwaraeliya"},
                polonnaruwa: {columnName: "polonnaruwa"},
                puttalam: {columnName: "puttalam"},
                ratnapura: {columnName: "ratnapura"},
                trincomalee: {columnName: "trincomalee"},
                vavuniya: {columnName: "vavuniya"},
                totals: {columnName: "totals"}
            },
            keyFields: ["electionId", "candidateId"]
        }
    };

    public isolated function init() returns persist:Error? {
        postgresql:Client|error dbClient = new (host = host, username = user, password = password, database = database, port = port, options = connectionOptions);
        if dbClient is error {
            return <persist:Error>error(dbClient.message());
        }
        self.dbClient = dbClient;
        if defaultSchema != () {
            lock {
                foreach string key in self.metadata.keys() {
                    psql:SQLMetadata metadata = self.metadata.get(key);
                    if metadata.schemaName == () {
                        metadata.schemaName = defaultSchema;
                    }
                    map<psql:JoinMetadata>? joinMetadataMap = metadata.joinMetadata;
                    if joinMetadataMap == () {
                        continue;
                    }
                    foreach [string, psql:JoinMetadata] [_, joinMetadata] in joinMetadataMap.entries() {
                        if joinMetadata.refSchema == () {
                            joinMetadata.refSchema = defaultSchema;
                        }
                    }
                }
            }
        }
        self.persistClients = {
            [CANDIDATE]: check new (dbClient, self.metadata.get(CANDIDATE).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [CHIEF_OCCUPANT]: check new (dbClient, self.metadata.get(CHIEF_OCCUPANT).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [HOUSEHOLD_DETAILS]: check new (dbClient, self.metadata.get(HOUSEHOLD_DETAILS).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [HOUSEHOLD_MEMBERS]: check new (dbClient, self.metadata.get(HOUSEHOLD_MEMBERS).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [ELECTION]: check new (dbClient, self.metadata.get(ELECTION).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [ADMIN_USERS]: check new (dbClient, self.metadata.get(ADMIN_USERS).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [ENROL_CANDIDATES]: check new (dbClient, self.metadata.get(ENROL_CANDIDATES).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [VOTE]: check new (dbClient, self.metadata.get(VOTE).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [ENROLMENT]: check new (dbClient, self.metadata.get(ENROLMENT).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [REGISTRATION_REVIEW]: check new (dbClient, self.metadata.get(REGISTRATION_REVIEW).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [GRAMA_NILADHARI]: check new (dbClient, self.metadata.get(GRAMA_NILADHARI).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [NOTIFICATION]: check new (dbClient, self.metadata.get(NOTIFICATION).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [VOTER]: check new (dbClient, self.metadata.get(VOTER).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [ADD_MEMBER_REQUEST]: check new (dbClient, self.metadata.get(ADD_MEMBER_REQUEST).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [UPDATE_MEMBER_REQUEST]: check new (dbClient, self.metadata.get(UPDATE_MEMBER_REQUEST).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [DELETE_MEMBER_REQUEST]: check new (dbClient, self.metadata.get(DELETE_MEMBER_REQUEST).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [CANDIDATE_DISTRICT_VOTE_SUMMARY]: check new (dbClient, self.metadata.get(CANDIDATE_DISTRICT_VOTE_SUMMARY).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS)
        };
    }

    isolated resource function get candidates(CandidateTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get candidates/[string candidateId](CandidateTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post candidates(CandidateInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CANDIDATE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from CandidateInsert inserted in data
            select inserted.candidateId;
    }

    isolated resource function put candidates/[string candidateId](CandidateUpdate value) returns Candidate|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CANDIDATE);
        }
        _ = check sqlClient.runUpdateQuery(candidateId, value);
        return self->/candidates/[candidateId].get();
    }

    isolated resource function delete candidates/[string candidateId]() returns Candidate|persist:Error {
        Candidate result = check self->/candidates/[candidateId].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CANDIDATE);
        }
        _ = check sqlClient.runDeleteQuery(candidateId);
        return result;
    }

    isolated resource function get chiefoccupants(ChiefOccupantTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get chiefoccupants/[string id](ChiefOccupantTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post chiefoccupants(ChiefOccupantInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CHIEF_OCCUPANT);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ChiefOccupantInsert inserted in data
            select inserted.id;
    }

    isolated resource function put chiefoccupants/[string id](ChiefOccupantUpdate value) returns ChiefOccupant|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CHIEF_OCCUPANT);
        }
        _ = check sqlClient.runUpdateQuery(id, value);
        return self->/chiefoccupants/[id].get();
    }

    isolated resource function delete chiefoccupants/[string id]() returns ChiefOccupant|persist:Error {
        ChiefOccupant result = check self->/chiefoccupants/[id].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CHIEF_OCCUPANT);
        }
        _ = check sqlClient.runDeleteQuery(id);
        return result;
    }

    isolated resource function get householddetails(HouseholdDetailsTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get householddetails/[string id](HouseholdDetailsTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post householddetails(HouseholdDetailsInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(HOUSEHOLD_DETAILS);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from HouseholdDetailsInsert inserted in data
            select inserted.id;
    }

    isolated resource function put householddetails/[string id](HouseholdDetailsUpdate value) returns HouseholdDetails|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(HOUSEHOLD_DETAILS);
        }
        _ = check sqlClient.runUpdateQuery(id, value);
        return self->/householddetails/[id].get();
    }

    isolated resource function delete householddetails/[string id]() returns HouseholdDetails|persist:Error {
        HouseholdDetails result = check self->/householddetails/[id].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(HOUSEHOLD_DETAILS);
        }
        _ = check sqlClient.runDeleteQuery(id);
        return result;
    }

    isolated resource function get householdmembers(HouseholdMembersTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get householdmembers/[string id](HouseholdMembersTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post householdmembers(HouseholdMembersInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(HOUSEHOLD_MEMBERS);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from HouseholdMembersInsert inserted in data
            select inserted.id;
    }

    isolated resource function put householdmembers/[string id](HouseholdMembersUpdate value) returns HouseholdMembers|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(HOUSEHOLD_MEMBERS);
        }
        _ = check sqlClient.runUpdateQuery(id, value);
        return self->/householdmembers/[id].get();
    }

    isolated resource function delete householdmembers/[string id]() returns HouseholdMembers|persist:Error {
        HouseholdMembers result = check self->/householdmembers/[id].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(HOUSEHOLD_MEMBERS);
        }
        _ = check sqlClient.runDeleteQuery(id);
        return result;
    }

    isolated resource function get elections(ElectionTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get elections/[string id](ElectionTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post elections(ElectionInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ELECTION);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ElectionInsert inserted in data
            select inserted.id;
    }

    isolated resource function put elections/[string id](ElectionUpdate value) returns Election|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ELECTION);
        }
        _ = check sqlClient.runUpdateQuery(id, value);
        return self->/elections/[id].get();
    }

    isolated resource function delete elections/[string id]() returns Election|persist:Error {
        Election result = check self->/elections/[id].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ELECTION);
        }
        _ = check sqlClient.runDeleteQuery(id);
        return result;
    }

    isolated resource function get adminusers(AdminUsersTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get adminusers/[string id](AdminUsersTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post adminusers(AdminUsersInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ADMIN_USERS);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from AdminUsersInsert inserted in data
            select inserted.id;
    }

    isolated resource function put adminusers/[string id](AdminUsersUpdate value) returns AdminUsers|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ADMIN_USERS);
        }
        _ = check sqlClient.runUpdateQuery(id, value);
        return self->/adminusers/[id].get();
    }

    isolated resource function delete adminusers/[string id]() returns AdminUsers|persist:Error {
        AdminUsers result = check self->/adminusers/[id].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ADMIN_USERS);
        }
        _ = check sqlClient.runDeleteQuery(id);
        return result;
    }

    isolated resource function get enrolcandidates(EnrolCandidatesTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get enrolcandidates/[string electionId]/[string candidateId](EnrolCandidatesTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post enrolcandidates(EnrolCandidatesInsert[] data) returns [string, string][]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ENROL_CANDIDATES);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from EnrolCandidatesInsert inserted in data
            select [inserted.electionId, inserted.candidateId];
    }

    isolated resource function put enrolcandidates/[string electionId]/[string candidateId](EnrolCandidatesUpdate value) returns EnrolCandidates|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ENROL_CANDIDATES);
        }
        _ = check sqlClient.runUpdateQuery({"electionId": electionId, "candidateId": candidateId}, value);
        return self->/enrolcandidates/[electionId]/[candidateId].get();
    }

    isolated resource function delete enrolcandidates/[string electionId]/[string candidateId]() returns EnrolCandidates|persist:Error {
        EnrolCandidates result = check self->/enrolcandidates/[electionId]/[candidateId].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ENROL_CANDIDATES);
        }
        _ = check sqlClient.runDeleteQuery({"electionId": electionId, "candidateId": candidateId});
        return result;
    }

    isolated resource function get votes(VoteTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get votes/[string id](VoteTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post votes(VoteInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(VOTE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from VoteInsert inserted in data
            select inserted.id;
    }

    isolated resource function put votes/[string id](VoteUpdate value) returns Vote|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(VOTE);
        }
        _ = check sqlClient.runUpdateQuery(id, value);
        return self->/votes/[id].get();
    }

    isolated resource function delete votes/[string id]() returns Vote|persist:Error {
        Vote result = check self->/votes/[id].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(VOTE);
        }
        _ = check sqlClient.runDeleteQuery(id);
        return result;
    }

    isolated resource function get enrolments(EnrolmentTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get enrolments/[string voterId]/[string electionId](EnrolmentTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post enrolments(EnrolmentInsert[] data) returns [string, string][]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ENROLMENT);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from EnrolmentInsert inserted in data
            select [inserted.voterId, inserted.electionId];
    }

    isolated resource function put enrolments/[string voterId]/[string electionId](EnrolmentUpdate value) returns Enrolment|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ENROLMENT);
        }
        _ = check sqlClient.runUpdateQuery({"voterId": voterId, "electionId": electionId}, value);
        return self->/enrolments/[voterId]/[electionId].get();
    }

    isolated resource function delete enrolments/[string voterId]/[string electionId]() returns Enrolment|persist:Error {
        Enrolment result = check self->/enrolments/[voterId]/[electionId].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ENROLMENT);
        }
        _ = check sqlClient.runDeleteQuery({"voterId": voterId, "electionId": electionId});
        return result;
    }

    isolated resource function get registrationreviews(RegistrationReviewTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get registrationreviews/[string id](RegistrationReviewTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post registrationreviews(RegistrationReviewInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(REGISTRATION_REVIEW);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from RegistrationReviewInsert inserted in data
            select inserted.id;
    }

    isolated resource function put registrationreviews/[string id](RegistrationReviewUpdate value) returns RegistrationReview|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(REGISTRATION_REVIEW);
        }
        _ = check sqlClient.runUpdateQuery(id, value);
        return self->/registrationreviews/[id].get();
    }

    isolated resource function delete registrationreviews/[string id]() returns RegistrationReview|persist:Error {
        RegistrationReview result = check self->/registrationreviews/[id].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(REGISTRATION_REVIEW);
        }
        _ = check sqlClient.runDeleteQuery(id);
        return result;
    }

    isolated resource function get gramaniladharis(GramaNiladhariTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get gramaniladharis/[string id](GramaNiladhariTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post gramaniladharis(GramaNiladhariInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(GRAMA_NILADHARI);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from GramaNiladhariInsert inserted in data
            select inserted.id;
    }

    isolated resource function put gramaniladharis/[string id](GramaNiladhariUpdate value) returns GramaNiladhari|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(GRAMA_NILADHARI);
        }
        _ = check sqlClient.runUpdateQuery(id, value);
        return self->/gramaniladharis/[id].get();
    }

    isolated resource function delete gramaniladharis/[string id]() returns GramaNiladhari|persist:Error {
        GramaNiladhari result = check self->/gramaniladharis/[id].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(GRAMA_NILADHARI);
        }
        _ = check sqlClient.runDeleteQuery(id);
        return result;
    }

    isolated resource function get notifications(NotificationTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get notifications/[string id](NotificationTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post notifications(NotificationInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(NOTIFICATION);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from NotificationInsert inserted in data
            select inserted.id;
    }

    isolated resource function put notifications/[string id](NotificationUpdate value) returns Notification|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(NOTIFICATION);
        }
        _ = check sqlClient.runUpdateQuery(id, value);
        return self->/notifications/[id].get();
    }

    isolated resource function delete notifications/[string id]() returns Notification|persist:Error {
        Notification result = check self->/notifications/[id].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(NOTIFICATION);
        }
        _ = check sqlClient.runDeleteQuery(id);
        return result;
    }

    isolated resource function get voters(VoterTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get voters/[string id](VoterTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post voters(VoterInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(VOTER);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from VoterInsert inserted in data
            select inserted.id;
    }

    isolated resource function put voters/[string id](VoterUpdate value) returns Voter|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(VOTER);
        }
        _ = check sqlClient.runUpdateQuery(id, value);
        return self->/voters/[id].get();
    }

    isolated resource function delete voters/[string id]() returns Voter|persist:Error {
        Voter result = check self->/voters/[id].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(VOTER);
        }
        _ = check sqlClient.runDeleteQuery(id);
        return result;
    }

    isolated resource function get addmemberrequests(AddMemberRequestTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get addmemberrequests/[string addRequestId](AddMemberRequestTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post addmemberrequests(AddMemberRequestInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ADD_MEMBER_REQUEST);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from AddMemberRequestInsert inserted in data
            select inserted.addRequestId;
    }

    isolated resource function put addmemberrequests/[string addRequestId](AddMemberRequestUpdate value) returns AddMemberRequest|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ADD_MEMBER_REQUEST);
        }
        _ = check sqlClient.runUpdateQuery(addRequestId, value);
        return self->/addmemberrequests/[addRequestId].get();
    }

    isolated resource function delete addmemberrequests/[string addRequestId]() returns AddMemberRequest|persist:Error {
        AddMemberRequest result = check self->/addmemberrequests/[addRequestId].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ADD_MEMBER_REQUEST);
        }
        _ = check sqlClient.runDeleteQuery(addRequestId);
        return result;
    }

    isolated resource function get updatememberrequests(UpdateMemberRequestTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get updatememberrequests/[string updateRequestId](UpdateMemberRequestTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post updatememberrequests(UpdateMemberRequestInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(UPDATE_MEMBER_REQUEST);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from UpdateMemberRequestInsert inserted in data
            select inserted.updateRequestId;
    }

    isolated resource function put updatememberrequests/[string updateRequestId](UpdateMemberRequestUpdate value) returns UpdateMemberRequest|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(UPDATE_MEMBER_REQUEST);
        }
        _ = check sqlClient.runUpdateQuery(updateRequestId, value);
        return self->/updatememberrequests/[updateRequestId].get();
    }

    isolated resource function delete updatememberrequests/[string updateRequestId]() returns UpdateMemberRequest|persist:Error {
        UpdateMemberRequest result = check self->/updatememberrequests/[updateRequestId].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(UPDATE_MEMBER_REQUEST);
        }
        _ = check sqlClient.runDeleteQuery(updateRequestId);
        return result;
    }

    isolated resource function get deletememberrequests(DeleteMemberRequestTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get deletememberrequests/[string deleteRequestId](DeleteMemberRequestTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post deletememberrequests(DeleteMemberRequestInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DELETE_MEMBER_REQUEST);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from DeleteMemberRequestInsert inserted in data
            select inserted.deleteRequestId;
    }

    isolated resource function put deletememberrequests/[string deleteRequestId](DeleteMemberRequestUpdate value) returns DeleteMemberRequest|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DELETE_MEMBER_REQUEST);
        }
        _ = check sqlClient.runUpdateQuery(deleteRequestId, value);
        return self->/deletememberrequests/[deleteRequestId].get();
    }

    isolated resource function delete deletememberrequests/[string deleteRequestId]() returns DeleteMemberRequest|persist:Error {
        DeleteMemberRequest result = check self->/deletememberrequests/[deleteRequestId].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DELETE_MEMBER_REQUEST);
        }
        _ = check sqlClient.runDeleteQuery(deleteRequestId);
        return result;
    }

    isolated resource function get candidatedistrictvotesummaries(CandidateDistrictVoteSummaryTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get candidatedistrictvotesummaries/[string electionId]/[string candidateId](CandidateDistrictVoteSummaryTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post candidatedistrictvotesummaries(CandidateDistrictVoteSummaryInsert[] data) returns [string, string][]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CANDIDATE_DISTRICT_VOTE_SUMMARY);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from CandidateDistrictVoteSummaryInsert inserted in data
            select [inserted.electionId, inserted.candidateId];
    }

    isolated resource function put candidatedistrictvotesummaries/[string electionId]/[string candidateId](CandidateDistrictVoteSummaryUpdate value) returns CandidateDistrictVoteSummary|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CANDIDATE_DISTRICT_VOTE_SUMMARY);
        }
        _ = check sqlClient.runUpdateQuery({"electionId": electionId, "candidateId": candidateId}, value);
        return self->/candidatedistrictvotesummaries/[electionId]/[candidateId].get();
    }

    isolated resource function delete candidatedistrictvotesummaries/[string electionId]/[string candidateId]() returns CandidateDistrictVoteSummary|persist:Error {
        CandidateDistrictVoteSummary result = check self->/candidatedistrictvotesummaries/[electionId]/[candidateId].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(CANDIDATE_DISTRICT_VOTE_SUMMARY);
        }
        _ = check sqlClient.runDeleteQuery({"electionId": electionId, "candidateId": candidateId});
        return result;
    }

    remote isolated function queryNativeSQL(sql:ParameterizedQuery sqlQuery, typedesc<record {}> rowType = <>) returns stream<rowType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor"
    } external;

    remote isolated function executeNativeSQL(sql:ParameterizedQuery sqlQuery) returns psql:ExecutionResult|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor"
    } external;

    public isolated function close() returns persist:Error? {
        error? result = self.dbClient.close();
        if result is error {
            return <persist:Error>error(result.message());
        }
        return result;
    }
}

