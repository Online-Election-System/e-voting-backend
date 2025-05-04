import ballerina/email;
import ballerina/random;
function sendWelcomeEmail(string toEmail, string fullName, string plainPassword) returns error? {
    email:Message message = {
        to: [toEmail],
        subject: "Welcome to the Voter Registration System",
        body: string `Hi ${fullName},

Your account has been created successfully.

Here is your login password: ${plainPassword}

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

Please keep these passwords safe.

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