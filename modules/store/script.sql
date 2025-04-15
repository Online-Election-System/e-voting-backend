-- AUTO-GENERATED FILE.

-- This file is an auto-generated file by Ballerina persistence layer for model.
-- Please verify the generated scripts and execute them against the target DB server.

DROP TABLE IF EXISTS "Voter";
DROP TABLE IF EXISTS "Election";

CREATE TABLE "Election" (
	"id" VARCHAR(191) NOT NULL,
	"election_name" VARCHAR(191) NOT NULL,
	"description" VARCHAR(191) NOT NULL,
	"start_date" DATE NOT NULL,
	"enrol_ddl" DATE NOT NULL,
	"end_date" DATE NOT NULL,
	"no_of_candidates" INT NOT NULL,
	PRIMARY KEY("id")
);

CREATE TABLE "Voter" (
	"id" VARCHAR(191) NOT NULL,
	"national_id" VARCHAR(191) NOT NULL,
	"full_name" VARCHAR(191) NOT NULL,
	"mobile_number" VARCHAR(191),
	"dob" VARCHAR(191),
	"gender" VARCHAR(191),
	"nic_chief_occupant" VARCHAR(191),
	"address" VARCHAR(191),
	"district" VARCHAR(191),
	"household_no" VARCHAR(191),
	"grama_niladhari" VARCHAR(191),
	"password" VARCHAR(191) NOT NULL,
	PRIMARY KEY("id")
);


