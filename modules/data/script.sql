-- AUTO-GENERATED FILE.

-- This file is an auto-generated file by Ballerina persistence layer for model.
-- Please verify the generated scripts and execute them against the target DB server.

DROP TABLE IF EXISTS "ChiefOccupant";
DROP TABLE IF EXISTS "HouseholdDetails";
DROP TABLE IF EXISTS "HouseholdMembers";

CREATE TABLE "HouseholdMembers" (
	"id" VARCHAR(191) NOT NULL,
	"chiefOccupantId" VARCHAR(191) NOT NULL,
	"fullName" VARCHAR(191) NOT NULL,
	"nic" VARCHAR(191),
	"dob" VARCHAR(191) NOT NULL,
	"gender" VARCHAR(191) NOT NULL,
	"civilStatus" VARCHAR(191) NOT NULL,
	"relationshipWithChiefOccupant" VARCHAR(191) NOT NULL,
	"idCopyPath" VARCHAR(191),
	"approvedByChief" BOOLEAN NOT NULL,
	"passwordHash" VARCHAR(191) NOT NULL,
	"passwordchanged" BOOLEAN NOT NULL,
	PRIMARY KEY("id")
);

CREATE TABLE "HouseholdDetails" (
	"id" VARCHAR(191) NOT NULL,
	"chiefOccupantId" VARCHAR(191) NOT NULL,
	"electoralDistrict" VARCHAR(191) NOT NULL,
	"pollingDivision" VARCHAR(191) NOT NULL,
	"pollingDistrictNumber" VARCHAR(191) NOT NULL,
	"gramaNiladhariDivision" VARCHAR(191),
	"villageStreetEstate" VARCHAR(191),
	"houseNumber" VARCHAR(191),
	"householdMemberCount" INT NOT NULL,
	PRIMARY KEY("id")
);

CREATE TABLE "ChiefOccupant" (
	"id" VARCHAR(191) NOT NULL,
	"fullName" VARCHAR(191) NOT NULL,
	"nic" VARCHAR(191) NOT NULL,
	"phoneNumber" VARCHAR(191),
	"dob" VARCHAR(191) NOT NULL,
	"gender" VARCHAR(191) NOT NULL,
	"civilStatus" VARCHAR(191) NOT NULL,
	"passwordHash" VARCHAR(191) NOT NULL,
	"email" VARCHAR(191) NOT NULL,
	"idCopyPath" VARCHAR(191),
	PRIMARY KEY("id")
);


