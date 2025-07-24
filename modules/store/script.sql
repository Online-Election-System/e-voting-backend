-- AUTO-GENERATED FILE.

-- This file is an auto-generated file by Ballerina persistence layer for model.
-- Please verify the generated scripts and execute them against the target DB server.

DROP TABLE IF EXISTS "AdminUsers";
DROP TABLE IF EXISTS "DeleteMemberRequest";
DROP TABLE IF EXISTS "UpdateMemberRequest";
DROP TABLE IF EXISTS "ChiefOccupant";
DROP TABLE IF EXISTS "HouseholdDetails";
DROP TABLE IF EXISTS "Election";
DROP TABLE IF EXISTS "HouseholdMembers";
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

CREATE TABLE "UpdateMemberRequest" (
	"update_request_id" VARCHAR(191) NOT NULL,
	"chief_occupant_id" VARCHAR(191) NOT NULL,
	"household_member_id" VARCHAR(191) NOT NULL,
	"new_full_name" VARCHAR(191),
	"new_resident_area" VARCHAR(191),
	"request_status" VARCHAR(191) NOT NULL,
	"relevant_certificate_path" VARCHAR(191),
	PRIMARY KEY("update_request_id")
);

CREATE TABLE "DeleteMemberRequest" (
	"delete_request_id" VARCHAR(191) NOT NULL,
	"chief_occupant_id" VARCHAR(191) NOT NULL,
	"household_member_id" VARCHAR(191) NOT NULL,
	"request_status" VARCHAR(191) NOT NULL,
	"required_document_path" VARCHAR(191),
	PRIMARY KEY("delete_request_id")
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


