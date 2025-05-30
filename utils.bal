import ballerina/crypto;

 //Helper function to create error response
public function createErrorResponse(string message) returns ApiResponse {
    return {
        success: false,
        message: message
    };
}

// Function to hash password
public function hashPassword(string password) returns string {
    byte[] hash = crypto:hashSha256(password.toBytes());
    return hash.toBase16();
 }

// Function to create a success response
public function createSuccessResponse(anydata data) returns ApiResponse {
    return {
        success: true,
        data: <record {|anydata...;|}|record {|anydata...;|}[]|()>data
    ,message: ""};
}

