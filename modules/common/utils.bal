import ballerina/uuid;
public isolated function generateId() returns string => uuid:createType1AsString();
