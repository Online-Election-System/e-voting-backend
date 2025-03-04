-- AUTO-GENERATED FILE.

-- This file is an auto-generated file by Ballerina persistence layer for model.
-- Please verify the generated scripts and execute them against the target DB server.

DROP TABLE IF EXISTS "Voter";

CREATE TABLE "Voter" (
	"id" INT NOT NULL,
	"nationalId" VARCHAR(191) NOT NULL,
	"fullName" VARCHAR(191) NOT NULL,
	"mobileNumber" VARCHAR(191),
	"dob" VARCHAR(191),
	"gender" VARCHAR(191),
	"nicChiefOccupant" VARCHAR(191),
	"address" VARCHAR(191),
	"district" VARCHAR(191),
	"householdNo" VARCHAR(191),
	"gramaNiladhari" VARCHAR(191),
	"password" VARCHAR(191) NOT NULL,
	PRIMARY KEY("id")
);


