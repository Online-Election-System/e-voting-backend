# Description for candidate total votes.
#
# + candidateId - candidate ID
# + totals - total votes for the candidate
public type CandidateTotal record {|
    string candidateId;
    int totals;  // Changed from 'Totals' to 'totals'
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
# + ampara - number of votes in the Ampara district
# + anuradhapura - number of votes in the Anuradhapura district
# + badulla - number of votes in the Badulla district
# + batticaloa - number of votes in the Batticaloa district
# + colombo - number of votes in the Colombo district
# + galle - number of votes in the Galle district
# + gampaha - number of votes in the Gampaha district
# + hambantota - number of votes in the Hambantota district
# + jaffna - number of votes in the Jaffna district
# + kalutara - number of votes in the Kalutara district
# + kandy - number of votes in the Kandy district
# + kegalle - number of votes in the Kegalle district
# + kilinochchi - number of votes in the Kilinochchi district
# + kurunegala - number of votes in the Kurunegala district
# + mannar - number of votes in the Mannar district
# + matale - number of votes in the Matale district
# + matara - number of votes in the Matara district
# + monaragala - number of votes in the Monaragala district
# + mullaitivu - number of votes in the Mullaitivu district
# + nuwaraeliya - number of votes in the Nuwara Eliya district
# + polonnaruwa - number of votes in the Polonnaruwa district
# + puttalam - number of votes in the Puttalam district
# + ratnapura - number of votes in the Ratnapura district
# + trincomalee - number of votes in the Trincomalee district
# + vavuniya - number of votes in the Vavuniya district
# + totals - total votes for this candidate across all districts
public type CandidateDistrictVoteSummary record {|
    string electionId;
    string candidateId;
    int ampara;        // Changed from 'Ampara' to 'ampara'
    int anuradhapura;  // Changed from 'Anuradhapura' to 'anuradhapura'
    int badulla;       // Changed from 'Badulla' to 'badulla'
    int batticaloa;    // Changed from 'Batticaloa' to 'batticaloa'
    int colombo;       // Changed from 'Colombo' to 'colombo'
    int galle;         // Changed from 'Galle' to 'galle'
    int gampaha;       // Changed from 'Gampaha' to 'gampaha'
    int hambantota;    // Changed from 'Hambantota' to 'hambantota'
    int jaffna;        // Changed from 'Jaffna' to 'jaffna'
    int kalutara;      // Changed from 'Kalutara' to 'kalutara'
    int kandy;         // Changed from 'Kandy' to 'kandy'
    int kegalle;       // Changed from 'Kegalle' to 'kegalle'
    int kilinochchi;   // Changed from 'Kilinochchi' to 'kilinochchi'
    int kurunegala;    // Changed from 'Kurunegala' to 'kurunegala'
    int mannar;        // Changed from 'Mannar' to 'mannar'
    int matale;        // Changed from 'Matale' to 'matale'
    int matara;        // Changed from 'Matara' to 'matara'
    int monaragala;    // Changed from 'Monaragala' to 'monaragala'
    int mullaitivu;    // Changed from 'Mullaitivu' to 'mullaitivu'
    int nuwaraeliya;   // Changed from 'NuwaraEliya' to 'nuwaraeliya'
    int polonnaruwa;   // Changed from 'Polonnaruwa' to 'polonnaruwa'
    int puttalam;      // Changed from 'Puttalam' to 'puttalam'
    int ratnapura;     // Changed from 'Ratnapura' to 'ratnapura'
    int trincomalee;   // Changed from 'Trincomalee' to 'trincomalee'
    int vavuniya;      // Changed from 'Vavuniya' to 'vavuniya'
    int totals;        // Changed from 'Totals' to 'totals'
|};

# Description for district-wise vote totals across all candidates for an election.
#
# + electionId - the election ID
# + ampara - total votes in Ampara district
# + anuradhapura - total votes in Anuradhapura district
# + badulla - total votes in Badulla district
# + batticaloa - total votes in Batticaloa district
# + colombo - total votes in Colombo district
# + galle - total votes in Galle district
# + gampaha - total votes in Gampaha district
# + hambantota - total votes in Hambantota district
# + jaffna - total votes in Jaffna district
# + kalutara - total votes in Kalutara district
# + kandy - total votes in Kandy district
# + kegalle - total votes in Kegalle district
# + kilinochchi - total votes in Kilinochchi district
# + kurunegala - total votes in Kurunegala district
# + mannar - total votes in Mannar district
# + matale - total votes in Matale district
# + matara - total votes in Matara district
# + monaragala - total votes in Monaragala district
# + mullaitivu - total votes in Mullaitivu district
# + nuwaraeliya - total votes in Nuwara Eliya district
# + polonnaruwa - total votes in Polonnaruwa district
# + puttalam - total votes in Puttalam district
# + ratnapura - total votes in Ratnapura district
# + trincomalee - total votes in Trincomalee district
# + vavuniya - total votes in Vavuniya district
# + grandTotal - sum of votes across all districts
public type DistrictVoteTotals record {|
    string electionId;
    int ampara;        // Changed from 'Ampara' to 'ampara'
    int anuradhapura;  // Changed from 'Anuradhapura' to 'anuradhapura'
    int badulla;       // Changed from 'Badulla' to 'badulla'
    int batticaloa;    // Changed from 'Batticaloa' to 'batticaloa'
    int colombo;       // Changed from 'Colombo' to 'colombo'
    int galle;         // Changed from 'Galle' to 'galle'
    int gampaha;       // Changed from 'Gampaha' to 'gampaha'
    int hambantota;    // Changed from 'Hambantota' to 'hambantota'
    int jaffna;        // Changed from 'Jaffna' to 'jaffna'
    int kalutara;      // Changed from 'Kalutara' to 'kalutara'
    int kandy;         // Changed from 'Kandy' to 'kandy'
    int kegalle;       // Changed from 'Kegalle' to 'kegalle'
    int kilinochchi;   // Changed from 'Kilinochchi' to 'kilinochchi'
    int kurunegala;    // Changed from 'Kurunegala' to 'kurunegala'
    int mannar;        // Changed from 'Mannar' to 'mannar'
    int matale;        // Changed from 'Matale' to 'matale'
    int matara;        // Changed from 'Matara' to 'matara'
    int monaragala;    // Changed from 'Monaragala' to 'monaragala'
    int mullaitivu;    // Changed from 'Mullaitivu' to 'mullaitivu'
    int nuwaraeliya;   // Changed from 'NuwaraEliya' to 'nuwaraeliya'
    int polonnaruwa;   // Changed from 'Polonnaruwa' to 'polonnaruwa'
    int puttalam;      // Changed from 'Puttalam' to 'puttalam'
    int ratnapura;     // Changed from 'Ratnapura' to 'ratnapura'
    int trincomalee;   // Changed from 'Trincomalee' to 'trincomalee'
    int vavuniya;      // Changed from 'Vavuniya' to 'vavuniya'
    int grandTotal;    // Changed from 'GrandTotal' to 'grandTotal'
|};