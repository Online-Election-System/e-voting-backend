-- AUTO-GENERATED FILE.

-- This file is an auto-generated file by Ballerina persistence layer for model.
-- Please verify the generated scripts and execute them against the target DB server.

DROP TABLE IF EXISTS "Candidate";
DROP TABLE IF EXISTS "AdminUsers";
DROP TABLE IF EXISTS "Vote";
DROP TABLE IF EXISTS "EnrolCandidates";
DROP TABLE IF EXISTS "ChiefOccupant";
DROP TABLE IF EXISTS "HouseholdDetails";
DROP TABLE IF EXISTS "Enrolment";
DROP TABLE IF EXISTS "Election";
DROP TABLE IF EXISTS "HouseholdMembers";

CREATE TABLE "HouseholdMembers" (
	"id" VARCHAR(191) NOT NULL,
	"chief_occupant_id" VARCHAR(191) NOT NULL,
	"full_name" VARCHAR(191) NOT NULL,
	"nic" VARCHAR(191),
	"dob" VARCHAR(191) NOT NULL,
	"gender" VARCHAR(191) NOT NULL,
	"civil_status" VARCHAR(191) NOT NULL,
	"relationship_with_chief_occupant" VARCHAR(191) NOT NULL,
	"id_copy_path" VARCHAR(191),
	"approved_by_chief" BOOLEAN NOT NULL,
	"Hased_password" VARCHAR(191) NOT NULL,
	"passwordchanged" BOOLEAN NOT NULL,
	"role" VARCHAR(191) NOT NULL,
	PRIMARY KEY("id")
);

CREATE TABLE "Election" (
	"id" VARCHAR(191) NOT NULL,
	"election_name" VARCHAR(191) NOT NULL,
	"description" VARCHAR(191) NOT NULL,
	"start_date" DATE NOT NULL,
	"enrol_ddl" DATE NOT NULL,
	"election_date" DATE NOT NULL,
	"end_date" DATE NOT NULL,
	"no_of_candidates" INT NOT NULL,
	"election_type" VARCHAR(191) NOT NULL,
	"start_time" TIME NOT NULL,
	"end_time" TIME NOT NULL,
	"status" VARCHAR(191) NOT NULL,
	PRIMARY KEY("id")
);

CREATE TABLE "Enrolment" (
	"voter_id" VARCHAR(191) NOT NULL,
	"election_id" VARCHAR(191) NOT NULL,
	"enrollement_date" TIMESTAMP NOT NULL,
	PRIMARY KEY("voter_id","election_id")
);

CREATE TABLE "HouseholdDetails" (
	"id" VARCHAR(191) NOT NULL,
	"chief_occupant_id" VARCHAR(191) NOT NULL,
	"electoral_district" VARCHAR(191) NOT NULL,
	"polling_division" VARCHAR(191) NOT NULL,
	"polling_district_number" VARCHAR(191) NOT NULL,
	"grama_niladhari_division" VARCHAR(191),
	"village_street_estate" VARCHAR(191),
	"house_number" VARCHAR(191),
	"household_member_count" INT NOT NULL,
	PRIMARY KEY("id")
);

CREATE TABLE "ChiefOccupant" (
	"id" VARCHAR(191) NOT NULL,
	"full_name" VARCHAR(191) NOT NULL,
	"nic" VARCHAR(191) NOT NULL,
	"phone_number" VARCHAR(191),
	"dob" VARCHAR(191) NOT NULL,
	"gender" VARCHAR(191) NOT NULL,
	"civil_status" VARCHAR(191) NOT NULL,
	"password_hash" VARCHAR(191) NOT NULL,
	"email" VARCHAR(191) NOT NULL,
	"id_copy_path" VARCHAR(191),
	"role" VARCHAR(191) NOT NULL,
	PRIMARY KEY("id")
);

CREATE TABLE "EnrolCandidates" (
	"election_id" VARCHAR(191) NOT NULL,
	"candidate_id" VARCHAR(191) NOT NULL,
	"number_of_votes" INT,
	PRIMARY KEY("election_id","candidate_id")
);

CREATE TABLE "Vote" (
	"id" VARCHAR(191) NOT NULL,
	"voter_id" VARCHAR(191) NOT NULL,
	"election_id" VARCHAR(191) NOT NULL,
	"candidate_id" VARCHAR(191) NOT NULL,
	"district" VARCHAR(191) NOT NULL,
	"timestamp" VARCHAR(191) NOT NULL,
	PRIMARY KEY("id")
);

CREATE TABLE "AdminUsers" (
	"id" VARCHAR(191) NOT NULL,
	"username" VARCHAR(191) NOT NULL,
	"email" VARCHAR(191) NOT NULL,
	"password_hash" VARCHAR(191) NOT NULL,
	"role" VARCHAR(191) NOT NULL,
	"created_at" TIMESTAMP NOT NULL,
	"is_active" BOOLEAN NOT NULL,
	PRIMARY KEY("id")
);

CREATE TABLE "Candidate" (
	"candidate_id" VARCHAR(191) NOT NULL,
	"candidate_name" VARCHAR(191) NOT NULL,
	"party_name" VARCHAR(191) NOT NULL,
	"party_symbol" VARCHAR(191),
	"party_color" VARCHAR(191) NOT NULL,
	"candidate_image" VARCHAR(191),
	"is_active" BOOLEAN NOT NULL,
	PRIMARY KEY("candidate_id")
);


