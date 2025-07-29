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