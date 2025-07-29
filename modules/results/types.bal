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

// Data Types
public type DistrictResults record {
    string election_id;
    string district_id;
    string district_name;
    int total_votes;
    CandidateResult[] candidates;
    decimal turnout_percentage?;
};

public type CandidateResult record {
    string candidate_id;
    string candidate_name;
    string party?;
    string party_symbol?;
    string party_color?;
    int votes;
    decimal percentage;
    int rank;
};

public type ElectionDistrictResults record {
    string election_id;
    map<DistrictResults> districts;
    int total_districts;
    int total_votes;
};

public type CandidateDistrictPerformance record {
    string election_id;
    string candidate_id;
    string candidate_name;
    string party?;
    DistrictPerformance[] districts;
    int districts_won;
    int districts_second;
    int districts_third;
};

public type DistrictPerformance record {
    string district_id;
    string district_name;
    int votes;
    decimal percentage;
    int rank;
    int total_district_votes;
    boolean won;
};

public type ElectionSummary record {
    string election_id;
    int total_votes;
    int total_districts;
    int districts_declared;
    CandidateOverall[] candidates;
    DistrictSummary[] district_summaries;
    decimal overall_turnout?;
};

public type CandidateOverall record {
    string candidate_id;
    string candidate_name;
    string party?;
    string party_symbol?;
    string party_color?;
    int total_votes;
    decimal percentage;
    int districts_won;
    int districts_second;
    int districts_third;
    int rank;
};

public type DistrictSummary record {
    string district_id;
    string district_name;
    int total_votes;
    CandidateResult winner;
    decimal margin_of_victory;
    boolean declared;
};

public type CandidateTopDistricts record {
    string election_id;
    string candidate_id;
    string candidate_name;
    DistrictPerformance[] top_districts;
};

public type DistrictRankings record {
    string election_id;
    DistrictRanking[] rankings;
};

public type DistrictRanking record {
    string district_id;
    string district_name;
    int total_votes;
    int registered_voters?;
    decimal turnout_percentage?;
    int rank;
};

public type CandidateStandings record {
    string election_id;
    CandidateOverall[] standings;
    boolean final_results;
};

public type DistrictComparisonRequest record {
    string[] district_ids;
    string[] candidate_ids?; // Optional: compare specific candidates only
};

public type DistrictComparison record {
    string election_id;
    string[] district_ids;
    string[] candidate_ids?;
    map<DistrictResults> comparison;
    ComparisonSummary summary;
};

public type ComparisonSummary record {
    string strongest_district;
    string weakest_district;
    decimal average_turnout;
    int total_votes_compared;
};

public type VoteDistribution record {
    string election_id;
    string district_id;
    string district_name;
    int total_votes;
    DistributionData[] distribution;
};

public type DistributionData record {
    string candidate_id;
    string candidate_name;
    string party?;
    string party_symbol?;
    string party_color?;
    int votes;
    decimal percentage;
    string color?; // For chart visualization
};

public type CandidateMargins record {
    string election_id;
    string candidate_id;
    string candidate_name;
    MarginData[] margins;
    decimal average_margin;
    int close_races; // Races won/lost by < 5%
};

public type MarginData record {
    string district_id;
    string district_name;
    decimal margin_percentage;
    int margin_votes;
    boolean won;
    string closest_competitor?;
};

public type MarginAnalysis record {
    string election_id;
    string candidate_id;
    decimal margin_threshold;
    string[] narrow_wins;
    string[] narrow_losses;
    int safe_districts;
    int competitive_districts;
    decimal average_winning_margin;
    decimal average_losing_margin;
};

public type LiveResults record {
    string election_id;
    string last_updated;
    int districts_declared;
    int total_districts;
    decimal completion_percentage;
    CandidateOverall[] current_standings;
    RecentUpdate[] recent_updates;
};

public type RecentUpdate record {
    string district_id;
    string district_name;
    string timestamp;
    string update_type; // "declared", "updated", "recount"
    CandidateResult winner?;
};
