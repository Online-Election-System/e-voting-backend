# Description for candidate total votes.
#
# + candidateId - candidate ID
# + Totals - total votes for the candidate
public type CandidateTotal record {|
    string candidateId;
    int Totals;
|};

public type DistrictVoteTotal record {|
    string district;
    int totalVotes;
|};


# Description for district-wise analysis of a specific candidate.
#
# + candidateId - candidate ID
# + candidateName - candidate name (optional, for display)
# + districtVotes - votes received in each district
# + districtPercentages - percentage of candidate's total votes from each district
# + totalVotes - candidate's total votes across all districts
public type CandidateDistrictAnalysis record {|
    string candidateId;
    string? candidateName;
    map<int> districtVotes;
    map<decimal> districtPercentages;
    int totalVotes;
|};

# Description for candidate-wise vote summary with percentages.
#
# + candidateId - candidate ID
# + candidateName - candidate name (optional, for display)
# + totalVotes - total votes received by this candidate
# + percentage - percentage of total votes this candidate received
# + rank - rank based on vote count (1 = highest votes)
public type CandidateVoteSummary record {|
    string candidateId;
    string? candidateName;
    int totalVotes;
    decimal percentage;
    int rank;
|};

# Description.
#
# + electionId - foreign key reference to the Election record
# + candidateId - foreign key reference to the Candidate record
# + Ampara - number of votes in the Ampara district
# + Anuradhapura - number of votes in the Anuradhapura district
# + Badulla - number of votes in the Badulla district
# + Batticaloa - number of votes in the Batticaloa district
# + Colombo - number of votes in the Colombo district
# + Galle - number of votes in the Galle district
# + Gampaha - number of votes in the Gampaha district
# + Hambantota - number of votes in the Hambantota district
# + Jaffna - number of votes in the Jaffna district
# + Kalutara - number of votes in the Kalutara district
# + Kandy - number of votes in the Kandy district
# + Kegalle - number of votes in the Kegalle district
# + Kilinochchi - number of votes in the Kilinochchi district
# + Kurunegala - number of votes in the Kurunegala district
# + Mannar - number of votes in the Mannar district
# + Matale - number of votes in the Matale district
# + Matara - number of votes in the Matara district
# + Monaragala - number of votes in the Monaragala district
# + Mullaitivu - number of votes in the Mullaitivu district
# + NuwaraEliya - number of votes in the Nuwara Eliya district
# + Polonnaruwa - number of votes in the Polonnaruwa district
# + Puttalam - number of votes in the Puttalam district
# + Ratnapura - number of votes in the Ratnapura district
# + Trincomalee - number of votes in the Trincomalee district
# + Vavuniya - number of votes in the Vavuniya district
# + Totals - total votes for this candidate across all districts
public type CandidateDistrictVoteSummary record {|
     string electionId;
     string candidateId;
    int Ampara;
    int Anuradhapura;
    int Badulla;
    int Batticaloa;
    int Colombo;
    int Galle;
    int Gampaha;
    int Hambantota;
    int Jaffna;
    int Kalutara;
    int Kandy;
    int Kegalle;
    int Kilinochchi;
    int Kurunegala;
    int Mannar;
    int Matale;
    int Matara;
    int Monaragala;
    int Mullaitivu;
    int NuwaraEliya;
    int Polonnaruwa;
    int Puttalam;
    int Ratnapura;
    int Trincomalee;
    int Vavuniya;
    int Totals;
|};

# Description for district-wise vote totals across all candidates for an election.
#
# + electionId - the election ID
# + Ampara - total votes in Ampara district
# + Anuradhapura - total votes in Anuradhapura district
# + Badulla - total votes in Badulla district
# + Batticaloa - total votes in Batticaloa district
# + Colombo - total votes in Colombo district
# + Galle - total votes in Galle district
# + Gampaha - total votes in Gampaha district
# + Hambantota - total votes in Hambantota district
# + Jaffna - total votes in Jaffna district
# + Kalutara - total votes in Kalutara district
# + Kandy - total votes in Kandy district
# + Kegalle - total votes in Kegalle district
# + Kilinochchi - total votes in Kilinochchi district
# + Kurunegala - total votes in Kurunegala district
# + Mannar - total votes in Mannar district
# + Matale - total votes in Matale district
# + Matara - total votes in Matara district
# + Monaragala - total votes in Monaragala district
# + Mullaitivu - total votes in Mullaitivu district
# + NuwaraEliya - total votes in Nuwara Eliya district
# + Polonnaruwa - total votes in Polonnaruwa district
# + Puttalam - total votes in Puttalam district
# + Ratnapura - total votes in Ratnapura district
# + Trincomalee - total votes in Trincomalee district
# + Vavuniya - total votes in Vavuniya district
# + GrandTotal - sum of votes across all districts
public type DistrictVoteTotals record {|
    string electionId;
    int Ampara;
    int Anuradhapura;
    int Badulla;
    int Batticaloa;
    int Colombo;
    int Galle;
    int Gampaha;
    int Hambantota;
    int Jaffna;
    int Kalutara;
    int Kandy;
    int Kegalle;
    int Kilinochchi;
    int Kurunegala;
    int Mannar;
    int Matale;
    int Matara;
    int Monaragala;
    int Mullaitivu;
    int NuwaraEliya;
    int Polonnaruwa;
    int Puttalam;
    int Ratnapura;
    int Trincomalee;
    int Vavuniya;
    int GrandTotal;
|};


