import ballerina/uuid;
import ballerina/time;

public function generateId() returns string => uuid:createType1AsString();

public function generateTimestamp() returns string {
    time:Utc current = time:utcNow(9);
    return current.toString();
}
