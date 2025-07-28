import ballerina/crypto;
import ballerina/email;
import ballerina/io;
import ballerina/random;

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
    foreach int i in 0 ..< length {
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

// Original JWT generation function (keep for backward compatibility)
public function generateJwt(string userId, UserRole role) returns string|error {
    return generateJwtWithId(userId, role);
}

// Password hashing with bcrypt
public function hashPassword(string password) returns string|error {
    string|error hashed = crypto:hashBcrypt(password);
    if hashed is error {
        io:println("Error hashing password: ", hashed);
        return hashed;
    }
    return hashed;
}

public function verifyPassword(string password, string hashedPassword) returns boolean|error {
    // This is the correct function name for your project.
    return crypto:verifyBcrypt(password, hashedPassword);
}

public function validatePasswordPolicy(string password) returns string? {
    if password.length() < 8 {
        return "Password must be at least 8 characters long";
    }

    boolean hasUppercase = false;
    boolean hasLowercase = false;
    boolean hasNumber = false;
    boolean hasSpecialChar = false;

    string specialChars = "@$!%*?&";

    foreach string char in password {
        if char >= "A" && char <= "Z" {
            hasUppercase = true;
        } else if char >= "a" && char <= "z" {
            hasLowercase = true;
        } else if char >= "0" && char <= "9" {
            hasNumber = true;
        } else if specialChars.indexOf(char) != () {
            hasSpecialChar = true;
        }
    }

    if !hasUppercase {
        return "Password must contain at least one uppercase letter";
    }
    if !hasLowercase {
        return "Password must contain at least one lowercase letter";
    }
    if !hasNumber {
        return "Password must contain at least one number";
    }
    if !hasSpecialChar {
        return "Password must contain at least one special character (@$!%*?&)";
    }

    return (); // Valid password
}
