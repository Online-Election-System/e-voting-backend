// Common types
public type Voter record {|
   int id;
   string national_id;
    string name;
    string district;
    string polling_station;
     string registration_date;
     string status;
    string password;
|};

 public type Election record {|
     int id;
     string title;
     string description;
     string start_date;
     string end_date;
     string location;
     string status;
 |};

 public type Candidate record {|
    int id;
    string name;
    string party;
     string bio;
     string image;
    int election_id;
 |};

public type Enrollment record {|
    int voter_id;
    int election_id;
    string enrollment_date; |};

// Response type
public type ApiResponse record {|
     boolean success;
  string message;
     record {}|record {}[]|() data = ();
 |};

// Login request type
public type LoginRequest record {|
    string nationalId;
    string password; |};

 // Enrollment with election details
 public type EnrollmentWithElection record {|
     int voter_id;
   int election_id;
     string enrollment_date;
     string title;
     string start_date;
  string end_date;
     string status;
 |};

// Enrollment record type
 public type EnrollmentRecord record {|
     int election_id;
 |};

 // Election with enrollment status
 type ElectionWithEnrollment record {|
    int id;
    string title;
    string description;
    string startDate;
    string endDate;
    string enrollmentDeadline;
    string electionDate;
    int noOfCandidates;
    string electionType;
    string startTime;
    string endTime;
    string status;
    boolean enrolled;
|};
