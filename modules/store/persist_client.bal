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
const VOTE = "votes";
const CANDIDATE = "candidates";
const DISTRICT_RESULT = "districtresults";
const ELECTION_SUMMARY = "electionsummaries";
const DISTRICT = "districts";
const PROVINCE_RESULT = "provinceresults";

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
        [CANDIDATE]: {
            entityName: "Candidate",
            tableName: "Candidate",
            fieldMetadata: {
                candidateId: {columnName: "candidate_id"},
                electionId: {columnName: "election_id"},
                candidateName: {columnName: "candidate_name"},
                partyName: {columnName: "party_name"},
                partySymbol: {columnName: "party_symbol"},
                partyColor: {columnName: "party_color"},
                candidateImage: {columnName: "candidate_image"},
                popularVotes: {columnName: "popular_votes"},
                electoralVotes: {columnName: "electoral_votes"},
                position: {columnName: "position"},
                isActive: {columnName: "is_active"}
            },
            keyFields: ["candidateId"]
        },
        [DISTRICT_RESULT]: {
            entityName: "DistrictResult",
            tableName: "DistrictResult",
            fieldMetadata: {
                districtCode: {columnName: "district_code"},
                electionId: {columnName: "election_id"},
                districtName: {columnName: "district_name"},
                totalVotes: {columnName: "total_votes"},
                votesProcessed: {columnName: "votes_processed"},
                winner: {columnName: "winner"},
                status: {columnName: "status"}
            },
            keyFields: ["districtCode", "electionId"]
        },
        [ELECTION_SUMMARY]: {
            entityName: "ElectionSummary",
            tableName: "ElectionSummary",
            fieldMetadata: {
                electionId: {columnName: "electionId"},
                totalRegisteredVoters: {columnName: "total_registered_voters"},
                totalVotesCast: {columnName: "total_votes_cast"},
                totalRejectedVotes: {columnName: "total_rejected_votes"},
                turnoutPercentage: {columnName: "turnout_percentage"},
                winnerCandidateId: {columnName: "winner_candidate_id"},
                electionStatus: {columnName: "election_status"}
            },
            keyFields: ["electionId"]
        },
        [DISTRICT]: {
            entityName: "District",
            tableName: "District",
            fieldMetadata: {
                districtId: {columnName: "district_id"},
                provinceId: {columnName: "province_id"},
                districtName: {columnName: "district_name"},
                totalVoters: {columnName: "total_voters"}
            },
            keyFields: ["districtId"]
        },
        [PROVINCE_RESULT]: {
            entityName: "ProvinceResult",
            tableName: "ProvinceResult",
            fieldMetadata: {
                provinceId: {columnName: "province_id"},
                provinceName: {columnName: "province_name"},
                totalDistricts: {columnName: "total_districts"}
            },
            keyFields: ["provinceId"]
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
            [VOTE]: check new (dbClient, self.metadata.get(VOTE).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [CANDIDATE]: check new (dbClient, self.metadata.get(CANDIDATE).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [DISTRICT_RESULT]: check new (dbClient, self.metadata.get(DISTRICT_RESULT).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [ELECTION_SUMMARY]: check new (dbClient, self.metadata.get(ELECTION_SUMMARY).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [DISTRICT]: check new (dbClient, self.metadata.get(DISTRICT).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS),
            [PROVINCE_RESULT]: check new (dbClient, self.metadata.get(PROVINCE_RESULT).cloneReadOnly(), psql:POSTGRESQL_SPECIFICS)
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

    isolated resource function get districtresults(DistrictResultTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get districtresults/[string districtCode]/[string electionId](DistrictResultTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post districtresults(DistrictResultInsert[] data) returns [string, string][]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DISTRICT_RESULT);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from DistrictResultInsert inserted in data
            select [inserted.districtCode, inserted.electionId];
    }

    isolated resource function put districtresults/[string districtCode]/[string electionId](DistrictResultUpdate value) returns DistrictResult|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DISTRICT_RESULT);
        }
        _ = check sqlClient.runUpdateQuery({"districtCode": districtCode, "electionId": electionId}, value);
        return self->/districtresults/[districtCode]/[electionId].get();
    }

    isolated resource function delete districtresults/[string districtCode]/[string electionId]() returns DistrictResult|persist:Error {
        DistrictResult result = check self->/districtresults/[districtCode]/[electionId].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DISTRICT_RESULT);
        }
        _ = check sqlClient.runDeleteQuery({"districtCode": districtCode, "electionId": electionId});
        return result;
    }

    isolated resource function get electionsummaries(ElectionSummaryTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get electionsummaries/[string electionId](ElectionSummaryTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post electionsummaries(ElectionSummaryInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ELECTION_SUMMARY);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ElectionSummaryInsert inserted in data
            select inserted.electionId;
    }

    isolated resource function put electionsummaries/[string electionId](ElectionSummaryUpdate value) returns ElectionSummary|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ELECTION_SUMMARY);
        }
        _ = check sqlClient.runUpdateQuery(electionId, value);
        return self->/electionsummaries/[electionId].get();
    }

    isolated resource function delete electionsummaries/[string electionId]() returns ElectionSummary|persist:Error {
        ElectionSummary result = check self->/electionsummaries/[electionId].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(ELECTION_SUMMARY);
        }
        _ = check sqlClient.runDeleteQuery(electionId);
        return result;
    }

    isolated resource function get districts(DistrictTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get districts/[string districtId](DistrictTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post districts(DistrictInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DISTRICT);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from DistrictInsert inserted in data
            select inserted.districtId;
    }

    isolated resource function put districts/[string districtId](DistrictUpdate value) returns District|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DISTRICT);
        }
        _ = check sqlClient.runUpdateQuery(districtId, value);
        return self->/districts/[districtId].get();
    }

    isolated resource function delete districts/[string districtId]() returns District|persist:Error {
        District result = check self->/districts/[districtId].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(DISTRICT);
        }
        _ = check sqlClient.runDeleteQuery(districtId);
        return result;
    }

    isolated resource function get provinceresults(ProvinceResultTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "query"
    } external;

    isolated resource function get provinceresults/[string provinceId](ProvinceResultTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.PostgreSQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post provinceresults(ProvinceResultInsert[] data) returns string[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PROVINCE_RESULT);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from ProvinceResultInsert inserted in data
            select inserted.provinceId;
    }

    isolated resource function put provinceresults/[string provinceId](ProvinceResultUpdate value) returns ProvinceResult|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PROVINCE_RESULT);
        }
        _ = check sqlClient.runUpdateQuery(provinceId, value);
        return self->/provinceresults/[provinceId].get();
    }

    isolated resource function delete provinceresults/[string provinceId]() returns ProvinceResult|persist:Error {
        ProvinceResult result = check self->/provinceresults/[provinceId].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PROVINCE_RESULT);
        }
        _ = check sqlClient.runDeleteQuery(provinceId);
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

