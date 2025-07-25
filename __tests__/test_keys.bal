import ballerina/crypto;
import ballerina/io;

public function main() returns error? {
    // Test private key loading
    crypto:PrivateKey|error privateKey = crypto:decodeRsaPrivateKeyFromKeyFile(
        "./resources/private_key.pem", 
        ""
    );
    
    if privateKey is error {
        io:println("Private key loading failed: " + privateKey.message());
        return;
    }
    io:println("Private key loaded successfully");
    
    // Test public key loading
    crypto:PublicKey|error publicKey = crypto:decodeRsaPublicKeyFromCertFile(
        "./resources/certificate.crt"
    );
    
    if publicKey is error {
        io:println("Public key loading failed: " + publicKey.message());
        return;
    }
    io:println("Public key loaded successfully");
    
    io:println("All keys are working correctly!");
}
