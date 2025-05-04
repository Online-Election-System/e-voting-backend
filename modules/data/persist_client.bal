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

public isolated client class Client {
    *persist:AbstractPersistClient;

    private final postgresql:Client dbClient;

    private final map<psql:SQLClient> persistClients;

    private final record {|psql:SQLMetadata...;|} & readonly metadata = {
        [CHIEF_OCCUPANT]: {
            entityName: "ChiefOccupant",
            tableName: "ChiefOccupant",
            fieldMetadata: {
                id: {columnName: "id"},
                fullName: {columnName: "fullName"},
                nic: {columnName: "nic"},
                phoneNumber: {columnName: "phoneNumber"},
                dob: {columnName: "dob"},
                gender: {columnName: "gender"},
                civilStatus: {columnName: "civilStatus"},
                passwordHash: {columnName: "passwordHash"},
                email: {columnName: "email"},
                idCopyPath: {columnName: "idCopyPath"}
            },
            keyFields: ["id"]
        },
        [HOUSEHOLD_DETAILS]: {
            entityName: "HouseholdDetails",
            tableName: "HouseholdDetails",
            fieldMetadata: {
                id: {columnName: "id"},
                chiefOccupantId: {columnName: "chiefOccupantId"},
                electoralDistrict: {columnName: "electoralDistrict"},
                pollingDivision: {columnName: "pollingDivision"},
                pollingDistrictNumber: {columnName: "pollingDistrictNumber"},
                gramaNiladhariDivision: {columnName: "gramaNiladhariDivision"},
                villageStreetEstate: {columnName: "villageStreetEstate"},
                houseNumber: {columnName: "houseNumber"},
                householdMemberCount: {columnName: "householdMemberCount"}
            },
            keyFields: ["id"]
        },
        [HOUSEHOLD_MEMBERS]: {
            entityName: "HouseholdMembers",
            tableName: "HouseholdMembers",
            fieldMetadata: {
                id: {columnName: "id"},
                chiefOccupantId: {columnName: "chiefOccupantId"},
                fullName: {columnName: "fullName"},
                nic: {columnName: "nic"},
                dob: {columnName: "dob"},
                gender: {columnName: "gender"},
                civilStatus: {columnName: "civilStatus"},
                relationshipWithChiefOccupant: {columnName: "relationshipWithChiefOccupant"},
                idCopyPath: {columnName: "idCopyPath"},
                approvedByChief: {columnName: "approvedByChief"},
                passwordHash: {columnName: "passwordHash"},
                passwordchanged: {columnName: "passwordchanged"}
            },
            keyFields: ["id"]
        }
    };

    public isolated function init() returns persist:Error? {
        postgresql:Client|error dbClient = new (host = host, username = user, password = password, database = database, port = port, options = connectionOptions);
        if dbClient is error {
            return <persist:Error>error(dbClient.message());
        }
        self.dbClient = dbClient;
        self.persistClients = {
            [CHIEF_OCCUPANT]: check new (dbClient, self.metadata.get(CHIEF_OCCUPANT), psql:POSTGRESQL_SPECIFICS),
            [HOUSEHOLD_DETAILS]: check new (dbClient, self.metadata.get(HOUSEHOLD_DETAILS), psql:POSTGRESQL_SPECIFICS),
            [HOUSEHOLD_MEMBERS]: check new (dbClient, self.metadata.get(HOUSEHOLD_MEMBERS), psql:POSTGRESQL_SPECIFICS)
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

