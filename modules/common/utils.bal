import ballerina/uuid;
public function generateId() returns string => uuid:createType1AsString();
