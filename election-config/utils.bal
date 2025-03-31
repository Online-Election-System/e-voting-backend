import ballerina/uuid;
function generateId() returns string => uuid:createType1AsString();