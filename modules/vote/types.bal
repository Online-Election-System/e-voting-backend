# Represents a vote cast in an election.
#
# + voterId - voter table voter ID (foreign key)
# + electionId - election table election ID (foreign key)
# + candidateId - candidate table candidate ID (foreign key)
# + district - voter district
# + timestamp - vote timestamp
public type Vote record {|
    string voterId;
    string electionId;
    string candidateId;
    string district;
    string timestamp;
|};
