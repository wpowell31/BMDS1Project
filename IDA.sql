/****************************************************************************************
Initial data analysis
****************************************************************************************/

-- Prescriptions of opioids from ICU admissions
DROP TABLE IF EXISTS analysis.opioid_users;
CREATE TABLE analysis.opioid_users AS
SELECT a.subject_id,
	   a.hadm_id,
	   a.ndc,
	   b.drug_name
FROM hosp.prescriptions a
INNER JOIN analysis.opioids_ndcs b
	ON a.ndc=b.ndc
WHERE hadm_id IN (SELECT hadm_id
				   FROM icu.icustays);

--Combine opioid users with ICU stay and patient covariates
DROP TABLE IF EXISTS analysis.opioid_patients_icu;
CREATE TABLE analysis.opioid_patients_icu AS
WITH ranked_patients AS (
    SELECT a.subject_id,
           c.hadm_id,
           a.gender,
           a.anchor_age,
           CAST(a.dod AS DATE) AS dod,
           CAST(b.outtime AS DATE) AS icu_visit_date,
           b.first_careunit,
           b.last_careunit,
           b.los,
           c.ndc,
           c.drug_name,
           CASE 
               WHEN CAST(a.dod AS DATE) - CAST(b.outtime AS DATE) BETWEEN 0 AND 30 THEN 1 ELSE 0 
           END AS died_within_30_days,
           CASE 
               WHEN CAST(a.dod AS DATE) - CAST(b.outtime AS DATE) BETWEEN 0 AND 365 THEN 1 ELSE 0 
           END AS died_within_1_year,
           ROW_NUMBER() OVER (PARTITION BY a.subject_id ORDER BY b.outtime DESC) AS rn
    FROM hosp.patients a
    INNER JOIN analysis.opioid_users c
           ON a.subject_id = c.subject_id
    INNER JOIN icu.icustays b
           ON c.hadm_id = b.hadm_id
)
SELECT subject_id,
       hadm_id,
       gender,
       anchor_age,
       dod,
       icu_visit_date,
       first_careunit,
       last_careunit,
       los,
       ndc,
       drug_name,
       died_within_30_days,
       died_within_1_year
FROM ranked_patients
WHERE rn = 1;

SELECT * FROM analysis.opioid_patients_icu;







--extract diagnosis comorbidities
DROP TABLE IF EXISTS analysis.opioid_pat_icu_diag;
CREATE TABLE analysis.opioid_pat_icu_diag AS
WITH diabetes_diagnoses AS (
    SELECT subject_id,
           MAX(CASE 
               WHEN icd_version = 9 AND icd_code LIKE '250%' THEN 1
               WHEN icd_version = 10 AND icd_code LIKE 'E1%' THEN 1
               ELSE 0
           END) AS has_diabetes
    FROM hosp.diagnoses_icd
    GROUP BY subject_id
),
obesity_diagnoses AS (
    SELECT subject_id,
           MAX(CASE 
               WHEN icd_version = 9 AND icd_code LIKE '278.0%' THEN 1
               WHEN icd_version = 10 AND icd_code LIKE 'E66%' THEN 1
               ELSE 0
           END) AS has_obesity
    FROM hosp.diagnoses_icd
    GROUP BY subject_id
),
copd_diagnoses AS (
    SELECT subject_id,
           MAX(CASE 
               WHEN icd_version = 9 AND icd_code BETWEEN '490' AND '496' THEN 1
               WHEN icd_version = 10 AND icd_code LIKE 'J4%' THEN 1
               ELSE 0
           END) AS has_copd
    FROM hosp.diagnoses_icd
    GROUP BY subject_id
),
cad_diagnoses AS (
    SELECT subject_id,
           MAX(CASE
               WHEN icd_version = 9 AND icd_code BETWEEN '410' AND '414' THEN 1
               WHEN icd_version = 10 AND icd_code BETWEEN 'I20' AND 'I25' THEN 1
               ELSE 0
           END) AS has_cad
    FROM hosp.diagnoses_icd
    GROUP BY subject_id
),
chf_diagnoses AS (
    SELECT subject_id,
           MAX(CASE
               WHEN icd_version = 9 AND icd_code = '428' THEN 1
               WHEN icd_version = 10 AND icd_code = 'I50' THEN 1
               ELSE 0
           END) AS has_chf
    FROM hosp.diagnoses_icd
    GROUP BY subject_id
),
esrd_diagnoses AS (
    SELECT subject_id,
           MAX(CASE
               WHEN icd_version = 9 AND icd_code = '585' THEN 1
               WHEN icd_version = 10 AND icd_code = 'N18.6' THEN 1
               ELSE 0
           END) AS has_esrd
    FROM hosp.diagnoses_icd
    GROUP BY subject_id
),
esld_diagnoses AS (
    SELECT subject_id,
           MAX(CASE
               WHEN icd_version = 9 AND icd_code = '572.2' THEN 1
               WHEN icd_version = 10 AND icd_code = 'K74.6' THEN 1
               ELSE 0
           END) AS has_esld
    FROM hosp.diagnoses_icd
    GROUP BY subject_id
),
stroke_diagnoses AS (
    SELECT subject_id,
           MAX(CASE
               WHEN icd_version = 9 AND icd_code BETWEEN '430' AND '438' THEN 1
               WHEN icd_version = 10 AND icd_code BETWEEN 'I60' AND 'I69' THEN 1
               ELSE 0
           END) AS has_stroke
    FROM hosp.diagnoses_icd
    GROUP BY subject_id
),
depression_diagnoses AS (
    SELECT subject_id,
           MAX(CASE
               WHEN icd_version = 9 AND icd_code IN ('296.2', '296.3', '300.4', '311') THEN 1
               WHEN icd_version = 10 AND icd_code LIKE 'F32%' THEN 1
               WHEN icd_version = 10 AND icd_code LIKE 'F33%' THEN 1
               ELSE 0
           END) AS has_depression
    FROM hosp.diagnoses_icd
    GROUP BY subject_id
)
SELECT opi.*,
       COALESCE(dd.has_diabetes, 0) AS diabetes,
       COALESCE(ob.has_obesity, 0) AS obesity,
       COALESCE(cd.has_copd, 0) AS copd,
       COALESCE(cad.has_cad, 0) AS cad,
       COALESCE(chf.has_chf, 0) AS chf,
       COALESCE(esrd.has_esrd, 0) AS esrd,
       COALESCE(esld.has_esld, 0) AS esld,
       COALESCE(sd.has_stroke, 0) AS stroke,
       COALESCE(dep.has_depression, 0) AS depression
FROM analysis.opioid_patients_icu opi
LEFT JOIN diabetes_diagnoses dd ON opi.subject_id = dd.subject_id
LEFT JOIN obesity_diagnoses ob ON opi.subject_id = ob.subject_id
LEFT JOIN copd_diagnoses cd ON opi.subject_id = cd.subject_id
LEFT JOIN cad_diagnoses cad ON opi.subject_id = cad.subject_id
LEFT JOIN chf_diagnoses chf ON opi.subject_id = chf.subject_id
LEFT JOIN esrd_diagnoses esrd ON opi.subject_id = esrd.subject_id
LEFT JOIN esld_diagnoses esld ON opi.subject_id = esld.subject_id
LEFT JOIN stroke_diagnoses sd ON opi.subject_id = sd.subject_id
LEFT JOIN depression_diagnoses dep ON opi.subject_id = dep.subject_id;

DROP TABLE IF EXISTS analysis.mimic_opioid;
CREATE TABLE analysis.mimic_opioid AS
SELECT subject_id,
	   hadm_id,
	   gender, 
	   anchor_age,
	   last_careunit,
	   los,
	   diabetes,
	   obesity,
	   copd,
	   cad,
	   chf,
	   esrd,
	   esld,
	   stroke,
	   depression,
	   drug_name,
	   died_within_30_days,
	   died_within_1_year
FROM analysis.opioid_pat_icu_diag; --40470 rows

SELECT COUNT(DISTINCT subject_id) FROM analysis.opioid_pat_icu_diag; --4



