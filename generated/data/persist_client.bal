// AUTO-GENERATED FILE. DO NOT MODIFY.

// This file is an auto-generated file by Ballerina persistence layer for model.
// It should not be modified by hand.

import ballerina/jballerina.java;
import ballerina/persist;
import ballerina/sql;
import ballerinax/persist.sql as psql;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;

const VOTER = "voters";

public isolated client class Client {
    *persist:AbstractPersistClient;

    private final postgresql:Client dbClient;

    private final map<psql:SQLClient> persistClients;

    private final record {|psql:SQLMetadata...;|} & readonly metadata = {
        [VOTER]: {
            entityName: "Voter",
            tableName: "Voter",
            fieldMetadata: {
                id: {columnName: "id"},
                nationalId: {columnName: "nationalId"},
                fullName: {columnName: "fullName"},
                mobileNumber: {columnName: "mobileNumber"},
                dob: {columnName: "dob"},
                gender: {columnName: "gender"},
                nicChiefOccupant: {columnName: "nicChiefOccupant"},
                address: {columnName: "address"},
                district: {columnName: "district"},
                householdNo: {columnName: "householdNo"},
                gramaNiladhari: {columnName: "gramaNiladhari"},
                password: {columnName: "password"}
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
        self.persistClients = {[VOTER]: check new (dbClient, self.metadata.get(VOTER), psql:POSTGRESQL_SPECIFICS)};
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

