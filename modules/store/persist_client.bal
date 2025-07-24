// AUTO-GENERATED FILE. DO NOT MODIFY.

// This file is an auto-generated file by Ballerina persistence layer for model.
// It should not be modified by hand.

import ballerina/jballerina.java;
import ballerina/persist;
import ballerina/sql;
import ballerinax/persist.sql as psql;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;

const CHIEF_OCCUPANT = "chiefoccupants";
const HOUSEHOLD_DETAILS = "householddetails";
const HOUSEHOLD_MEMBERS = "householdmembers";
const ELECTION = "elections";
const ADMIN_USERS = "adminusers";
const ADD_MEMBER_REQUEST = "addmemberrequests";
const UPDATE_MEMBER_REQUEST = "updatememberrequests";
const DELETE_MEMBER_REQUEST = "deletememberrequests";

public isolated client class Client {
    *persist:AbstractPersistClient;

    private final postgresql:Client dbClient;

    private final map<psql:SQLClient> persistClients;

    private final record {|psql:SQLMetadata...;|} metadata = {
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
                requiredDocumentPath: {columnName: "required_document_path"}
            },
            keyFields: ["deleteRequestId"]
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
            [CHIEF_OCCUPANT]: check new (dbClient, self.metadata.get(CHIEF_OCCUPANT).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [HOUSEHOLD_DETAILS]: check new (dbClient, self.metadata.get(HOUSEHOLD_DETAILS).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [HOUSEHOLD_MEMBERS]: check new (dbClient, self.metadata.get(HOUSEHOLD_MEMBERS).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [ELECTION]: check new (dbClient, self.metadata.get(ELECTION).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [ADMIN_USERS]: check new (dbClient, self.metadata.get(ADMIN_USERS).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [ADD_MEMBER_REQUEST]: check new (dbClient, self.metadata.get(ADD_MEMBER_REQUEST).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [UPDATE_MEMBER_REQUEST]: check new (dbClient, self.metadata.get(UPDATE_MEMBER_REQUEST).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [DELETE_MEMBER_REQUEST]: check new (dbClient, self.metadata.get(DELETE_MEMBER_REQUEST).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS)
        };
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

