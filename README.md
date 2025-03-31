### Running the E-Voting Backend

Follow the steps below to set up and run the backend for the e-voting system:

1. **Install Ballerina**  
   Ensure that you have [Ballerina](https://ballerina.io/downloads/) installed on your machine. You can verify the installation by running the following command:
   ```bash
   bal --version
   ```

2. **Generate the Data Store**  
   Run the following command to generate the necessary datastore configuration for PostgreSQL:
   ```bash
   bal persist generate --datastore postgresql --module elections
   ```

3. **Run the Application**  
   Once the datastore is generated, start the application by running:
   ```bash
   bal run
   ```

This will initialize the backend and you should be able to interact with the e-voting system as per your project's requirements.
