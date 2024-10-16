/****************************************************************************************
  Data ETL
****************************************************************************************/
--Table: patients
DROP TABLE IF EXISTS hosp.patients;
CREATE TABLE hosp.patients (
    subject_id INT PRIMARY KEY,
	gender VARCHAR(55),
	anchor_age INT,
	anchor_year INT,
	anchor_year_group VARCHAR(55),
	dod VARCHAR(55)
);

--Table: prescriptions
DROP TABLE IF EXISTS hosp.prescriptions;
CREATE TABLE hosp.prescriptions (
	subject_id INT,
	hadm_id INT,
	ndc NUMERIC(64)
);


--Table: admissions
DROP TABLE IF EXISTS hosp.admissions;
CREATE TABLE hosp.admissions (
	subject_id INT,
	hadm_id INT,
	admittime VARCHAR(55),
	dischtime VARCHAR(55),
	deathtime VARCHAR(55),
	admission_type VARCHAR(55),
	admit_provider_id VARCHAR(55),
	admission_location VARCHAR(55),
	discharge_location VARCHAR(55),
	insurance VARCHAR(55),
	lang VARCHAR(55),
	marital_status VARCHAR(55),
	race VARCHAR(55),
	edregtime VARCHAR(55),
	edouttime VARCHAR(55),
	hospital_expire_flag INT
);

DROP TABLE IF EXISTS hosp.diagnoses_icd;
CREATE TABLE hosp.diagnoses_icd (
	subject_id INT,
	hadm_id INT,
	seq_num INT,
	icd_code VARCHAR(55),
	icd_version INT
);

--Table: icustays
DROP TABLE IF EXISTS icu.icustays;
CREATE TABLE icu.icustays (
	subject_id INT,
	hadm_id INT,
	stay_id INT,
	first_careunit VARCHAR(55),
	last_careunit VARCHAR(55),
	intime VARCHAR(55),
	outtime VARCHAR(55),
	los VARCHAR(55)
);

--Table: opioids_ndcs
DROP TABLE IF EXISTS analysis.opioids_ndcs;
CREATE TABLE analysis.opioids_ndcs (
	drug_name VARCHAR(55),
	rxcui VARCHAR(55),
	ndc NUMERIC(64)
);



