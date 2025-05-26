import ballerina/email;
import ballerina/random;
import ballerina/jwt;
import ballerina/time;
function sendWelcomeEmail(string toEmail, string fullName, string plainedPassword) returns error? {
    email:Message message = {
        to: [toEmail],
        subject: "Welcome to the Voter Registration System",
        body: string `Hi ${fullName},

Your account has been created successfully.

Here is your login password: ${plainedPassword}

Regards,
Voter Registration System Team`
    };

    check smtpClient->sendMessage(message);
}
function sendHouseholdPasswordsToChief(
    email:SmtpClient smtpClient,
    string toEmail,
    string fullName,
    string[] passwordList
) returns error? {
    string memberPasswords = joinStrings(passwordList, "\n");
    email:Message message = {
        to: [toEmail],
        subject: "Household Members Registration - Passwords",
        body: string `Dear ${fullName},

The following household members have been registered successfully:

${memberPasswords}

Please change your password after login!

Regards,
Voter Registration System Team`
    };
    check smtpClient->sendMessage(message);
}
public function generatePassword(int length = 10) returns string|error {
    string charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    string password = "";
    foreach int i in 0..<length {
        int index = check random:createIntInRange(0, charset.length());
        password += charset[index].toString();
    }
    return password;
}
function joinStrings(string[] values, string separator) returns string {
    if values.length() == 0 {
        return "";
    }
    string result = values[0];
    foreach int i in 1 ..< values.length() {
        result += separator + values[i];
    }
    return result;
}
public function generateJwt(string userId, string userType) returns string|error {
    int seconds = time:utcNow()[0];
    int expiryTime = seconds + 3600;
    jwt:IssuerConfig issuerConfig = {
        username: "ballerina",
        issuer: "wso2",
        audience: "vEwzbcasJVQm1jVYHUHCjhxZ4tYa",
        expTime: 3600,
        customClaims: {
            sub: userId,
            role: userType,
            iat: seconds,
            exp: expiryTime
        },
        signatureConfig: {
            config: {
                keyFile: "./resources/private.key", 
                keyPassword: ""                    
            }
        }
    };
    return check jwt:issue(issuerConfig);
}