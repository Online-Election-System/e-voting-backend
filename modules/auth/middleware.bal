import ballerina/http;
import ballerina/jwt;

public function authorize(http:Request req, UserRole[] allowedRoles) returns string|error {
    string|error authHeader = req.getHeader("Authorization");

    if authHeader is error {
        return error("Authorization header missing");
    }

    string token = authHeader.replace("Bearer ", "");

    jwt:Payload|error payload = jwt:decode(token);
    if payload is error {
        return error("Invalid token");
    }

    // Check token expiration
    int? exp = payload.exp;
    if exp is () || exp < time:utcNow()[0] {
        return error("Token expired");
    }

    // Get user role from JWT
    string|error role = payload.role.toString();
    if role is error {
        return error("Invalid role in token");
    }

    // Check if user has required role
    boolean isAllowed = false;
    foreach var allowedRole in allowedRoles {
        if role == allowedRole {
            isAllowed = true;
            break;
        }
    }

    if !isAllowed {
        return error("Insufficient permissions");
    }

    return payload.sub.toString();
}
