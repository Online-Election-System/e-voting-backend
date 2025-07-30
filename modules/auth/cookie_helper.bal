import ballerina/http;
import ballerina/log;

// Set secure authentication cookie with all security attributes
public function setAuthCookie(http:Response response, string token) {
    string cookieHeader = string `AUTH_TOKEN=${token}; Path=/; Max-Age=3600; HttpOnly; Secure; SameSite=Lax`;
    response.addHeader("Set-Cookie", cookieHeader);
}

// Clear authentication cookie
public function clearAuthCookie(http:Response response) {
    string cookieHeader = "AUTH_TOKEN=; Path=/; Max-Age=0; HttpOnly; Secure; SameSite=Lax";
    response.addHeader("Set-Cookie", cookieHeader);
}

// Set session info cookie (readable by frontend)
public function setSessionInfoCookie(http:Response response, string userId, string userType, string fullName) {
    string sessionInfo = string `{"userId":"${userId}","userType":"${userType}","fullName":"${fullName}"}`;
    string cookieHeader = string `SESSION_INFO=${sessionInfo}; Path=/; Max-Age=3600; Secure; SameSite=Lax`;
    response.addHeader("Set-Cookie", cookieHeader);
}

// Clear session info cookie
public function clearSessionInfoCookie(http:Response response) {
    string cookieHeader = "SESSION_INFO=; Path=/; Max-Age=0; Secure; SameSite=Lax";
    response.addHeader("Set-Cookie", cookieHeader);
}

// Clear all auth-related cookies
function clearAllAuthCookies(http:Response response) {
    // Clear AUTH_TOKEN cookie
    string authCookieHeader = "AUTH_TOKEN=; Path=/; Max-Age=0; HttpOnly; Secure; SameSite=Lax";
    response.addHeader("Set-Cookie", authCookieHeader);
    
    // Clear SESSION_INFO cookie  
    string sessionCookieHeader = "SESSION_INFO=; Path=/; Max-Age=0; Secure; SameSite=Lax";
    response.addHeader("Set-Cookie", sessionCookieHeader);
    
    // Clear any legacy cookies
    string legacyCookieHeader = "SESSION=; Path=/; Max-Age=0";
    response.addHeader("Set-Cookie", legacyCookieHeader);
    
    log:printInfo("All authentication cookies cleared");
}
