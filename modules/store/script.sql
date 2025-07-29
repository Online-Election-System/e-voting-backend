-- AUTO-GENERATED FILE.

-- This file is an auto-generated file by Ballerina persistence layer for model.
-- Please verify the generated scripts and execute them against the target DB server.

DROP TABLE IF EXISTS "Candidate";
DROP TABLE IF EXISTS "Vote";
DROP TABLE IF EXISTS "EnrolCandidates";
DROP TABLE IF EXISTS "Enrolment";
DROP TABLE IF EXISTS "Election";
DROP TABLE IF EXISTS "Notification";
DROP TABLE IF EXISTS "HouseholdMembers";
DROP TABLE IF EXISTS "AdminUsers";
DROP TABLE IF EXISTS "RemovalRequest";
DROP TABLE IF EXISTS "GramaNiladhari";
DROP TABLE IF EXISTS "Voter";
DROP TABLE IF EXISTS "RegistrationReview";
DROP TABLE IF EXISTS "CandidateDistrictVoteSummary";
DROP TABLE IF EXISTS "DeleteMemberRequest";
DROP TABLE IF EXISTS "UpdateMemberRequest";
DROP TABLE IF EXISTS "ChiefOccupant";
DROP TABLE IF EXISTS "HouseholdDetails";
DROP TABLE IF EXISTS "AddMemberRequest";

CREATE TABLE "AddMemberRequest" (
	"add_request_id" VARCHAR(191) NOT NULL,
	"chief_occupant_id" VARCHAR(191) NOT NULL,
	"nic_number" VARCHAR(191) NOT NULL,
	"full_name" VARCHAR(191) NOT NULL,
	"date_of_birth" VARCHAR(191) NOT NULL,
	"gender" VARCHAR(191) NOT NULL,
	"civil_status" VARCHAR(191) NOT NULL,
	"relationship_to_chief" VARCHAR(191) NOT NULL,
	"chief_occupant_approval" VARCHAR(191) NOT NULL,
	"request_status" VARCHAR(191) NOT NULL,
	"nic_or_birth_certificate_path" VARCHAR(191),
	PRIMARY KEY("add_request_id")
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
	"photo_copy_path" VARCHAR(191),
	"role" VARCHAR(191) NOT NULL,
	PRIMARY KEY("id")
);

CREATE TABLE "UpdateMemberRequest" (
	"update_request_id" VARCHAR(191) NOT NULL,
	"chief_occupant_id" VARCHAR(191) NOT NULL,
	"household_member_id" VARCHAR(191),
	"new_full_name" VARCHAR(191),
	"new_resident_area" VARCHAR(191),
	"request_status" VARCHAR(191) NOT NULL,
	"relevant_certificate_path" VARCHAR(191),
	PRIMARY KEY("update_request_id")
);

CREATE TABLE "DeleteMemberRequest" (
	"delete_request_id" VARCHAR(191) NOT NULL,
	"chief_occupant_id" VARCHAR(191) NOT NULL,
	"household_member_id" VARCHAR(191),
	"request_status" VARCHAR(191) NOT NULL,
	"required_document_path" VARCHAR(191),
	PRIMARY KEY("delete_request_id")
);

CREATE TABLE "CandidateDistrictVoteSummary" (
	"election_id" VARCHAR(191) NOT NULL,
	"candidate_id" VARCHAR(191) NOT NULL,
	"ampara" INT NOT NULL,
	"anuradhapura" INT NOT NULL,
	"badulla" INT NOT NULL,
	"batticaloa" INT NOT NULL,
	"colombo" INT NOT NULL,
	"galle" INT NOT NULL,
	"gampaha" INT NOT NULL,
	"hambantota" INT NOT NULL,
	"jaffna" INT NOT NULL,
	"kalutara" INT NOT NULL,
	"kandy" INT NOT NULL,
	"kegalle" INT NOT NULL,
	"kilinochchi" INT NOT NULL,
	"kurunegala" INT NOT NULL,
	"mannar" INT NOT NULL,
	"matale" INT NOT NULL,
	"matara" INT NOT NULL,
	"monaragala" INT NOT NULL,
	"mullaitivu" INT NOT NULL,
	"nuwaraEliya" INT NOT NULL,
	"polonnaruwa" INT NOT NULL,
	"puttalam" INT NOT NULL,
	"ratnapura" INT NOT NULL,
	"trincomalee" INT NOT NULL,
	"vavuniya" INT NOT NULL,
	"totals" INT NOT NULL,
	PRIMARY KEY("election_id","candidate_id")
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
	"photo_copy_path" VARCHAR(191),
	"approved_by_chief" BOOLEAN NOT NULL,
	"Hased_password" VARCHAR(191) NOT NULL,
	"passwordchanged" BOOLEAN NOT NULL,
	"role" VARCHAR(191) NOT NULL,
	PRIMARY KEY("id")
);

  CREATE TABLE "RegistrationReview" (
	"id" VARCHAR(191) NOT NULL,
	"member_nic" VARCHAR(191) NOT NULL,
	"reviewed_by" VARCHAR(191) NOT NULL,
	"status" VARCHAR(191) NOT NULL,
	"comments" VARCHAR(191),
	"reviewed_at" TIMESTAMP,
	PRIMARY KEY("id")
);

CREATE TABLE "Voter" (
	"id" VARCHAR(191) NOT NULL,
	"national_id" VARCHAR(191) NOT NULL,
	"name" VARCHAR(191) NOT NULL,
	"password" VARCHAR(191) NOT NULL,
	"district" VARCHAR(191) NOT NULL,
	"polling_station" VARCHAR(191) NOT NULL,
	"registration_date" DATE NOT NULL,
	"status" VARCHAR(191) NOT NULL,
	PRIMARY KEY("id")
);

CREATE TABLE "GramaNiladhari" (
	"id" VARCHAR(191) NOT NULL,
	"full_name" VARCHAR(191) NOT NULL,
	"nic" VARCHAR(191) NOT NULL,
	"date_of_birth" VARCHAR(191) NOT NULL,
	"email" VARCHAR(191) NOT NULL,
	"office_phone" VARCHAR(191) NOT NULL,
	"mobile_number" VARCHAR(191) NOT NULL,
	"residential_address" VARCHAR(191) NOT NULL,
	"official_title" VARCHAR(191) NOT NULL,
	"employee_id" VARCHAR(191) NOT NULL,
	"appointment_date" VARCHAR(191) NOT NULL,
	"gn_division" VARCHAR(191) NOT NULL,
	"district" VARCHAR(191) NOT NULL,
	"province" VARCHAR(191) NOT NULL,
	"office_address" VARCHAR(191) NOT NULL,
	"qualifications" VARCHAR(191) NOT NULL,
	"experience" VARCHAR(191) NOT NULL,
	PRIMARY KEY("id")
);

CREATE TABLE "Enrolment" (
	"voter_id" VARCHAR(191) NOT NULL,
	"election_id" VARCHAR(191) NOT NULL,
	"enrollement_date" TIMESTAMP NOT NULL,
	PRIMARY KEY("voter_id","election_id")
);

CREATE TABLE "EnrolCandidates" (
	"election_id" VARCHAR(191) NOT NULL,
	"candidate_id" VARCHAR(191) NOT NULL,
	"number_of_votes" INT,
	PRIMARY KEY("election_id","candidate_id")
);
  
  CREATE TABLE "RemovalRequest" (
	"id" VARCHAR(191) NOT NULL,
	"member_name" VARCHAR(191) NOT NULL,
	"nic" VARCHAR(191) NOT NULL,
	"requested_by" VARCHAR(191) NOT NULL,
	"reason" VARCHAR(191) NOT NULL,
	"proof_document" VARCHAR(191) NOT NULL,
	"status" VARCHAR(191) NOT NULL,
	PRIMARY KEY("id")
);

CREATE TABLE "Notification" (
	"id" VARCHAR(191) NOT NULL,
	"title" VARCHAR(191) NOT NULL,
	"message" VARCHAR(191) NOT NULL,
	"link" VARCHAR(191),
	"created_at" TIMESTAMP NOT NULL,
	"status" VARCHAR(191) NOT NULL,
	"recipient_nic" VARCHAR(191) NOT NULL,
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

CREATE TABLE "Vote" (
	"id" VARCHAR(191) NOT NULL,
	"voter_id" VARCHAR(191) NOT NULL,
	"election_id" VARCHAR(191) NOT NULL,
	"candidate_id" VARCHAR(191) NOT NULL,
	"district" VARCHAR(191) NOT NULL,
	"timestamp" VARCHAR(191) NOT NULL,
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


