-- ================================================================
-- Healthcare SQL Project — Query Log
-- Database: Synthea  |  Table: multiple tables
-- Companion to: sql-hands-on-project-setup.md
-- Queries by Toren Lehrmann
-- ================================================================
--
-- About this file:
-- Once a query in DB Browser gives you a finished, correct answer,
-- it is copied here for reference and future use. 
--
-- ================================================================


-- Queries 1-6

--01_diabetes_patients.sql (basic join)

SELECT p.Id, p.FIRST, p.LAST, p.BIRTHDATE, c.START AS diabetes_start
FROM patients p
JOIN conditions c ON c.PATIENT = p.Id
WHERE c.DESCRIPTION = 'Diabetes'
ORDER BY c.START;
-- expect 73 rows


-- 02_testing_rate_measure.sql (headline measure)

WITH diabetics AS (
  SELECT DISTINCT PATIENT
  FROM conditions
  WHERE DESCRIPTION = 'Diabetes'
    AND START <= '2021-12-31'
),
eligible AS (
  SELECT p.Id AS patient_id
  FROM patients p
  JOIN diabetics d ON d.PATIENT = p.Id
  WHERE (p.DEATHDATE IS NULL OR p.DEATHDATE >= '2021-01-01')
    AND (julianday('2021-12-31') - julianday(p.BIRTHDATE)) / 365.25 BETWEEN 18 AND 75
),
tested AS (
  SELECT DISTINCT PATIENT
  FROM observations
  WHERE CODE = '4548-4'
    AND DATE >= '2021-01-01' AND DATE < '2022-01-01'
)
SELECT COUNT(*) AS denominator,
       COUNT(t.PATIENT) AS numerator,
       ROUND(100.0 * COUNT(t.PATIENT) / COUNT(*), 1) AS pct_tested
FROM eligible e
LEFT JOIN tested t ON t.PATIENT = e.patient_id;
-- expect 47, 40, 85.1


-- 03_not_tested_call_list.sql (anti-join)

WITH eligible AS (
  SELECT DISTINCT p.Id AS patient_id, p.FIRST, p.LAST, p.BIRTHDATE
  FROM patients p
  JOIN conditions c ON c.PATIENT = p.Id
  WHERE c.DESCRIPTION = 'Diabetes'
    AND c.START <= '2021-12-31'
    AND (p.DEATHDATE IS NULL OR p.DEATHDATE >= '2021-01-01')
    AND (julianday('2021-12-31') - julianday(p.BIRTHDATE)) / 365.25 BETWEEN 18 AND 75
),
tested_2021 AS (
  SELECT DISTINCT PATIENT
  FROM observations
  WHERE CODE = '4548-4'
    AND DATE >= '2021-01-01' AND DATE < '2022-01-01'
)
SELECT e.FIRST, e.LAST, e.BIRTHDATE
FROM eligible e
LEFT JOIN tested_2021 t ON t.PATIENT = e.patient_id
WHERE t.PATIENT IS NULL
ORDER BY e.LAST;
-- expect 7 rows; first Cleveland582 Dach178, last Anthony633 Wehner319


-- 04_a1c_distribution.sql (CASE WHEN buckets, window function)

WITH diabetics AS (
  SELECT DISTINCT PATIENT FROM conditions
  WHERE DESCRIPTION = 'Diabetes' AND START <= '2021-12-31'
),
eligible AS (
  SELECT p.Id AS patient_id
  FROM patients p JOIN diabetics d ON d.PATIENT = p.Id
  WHERE (p.DEATHDATE IS NULL OR p.DEATHDATE >= '2021-01-01')
    AND (julianday('2021-12-31') - julianday(p.BIRTHDATE)) / 365.25 BETWEEN 18 AND 75
),
latest AS (
  SELECT PATIENT, CAST(VALUE AS REAL) AS a1c,
         ROW_NUMBER() OVER (PARTITION BY PATIENT ORDER BY DATE DESC) AS rn
  FROM observations
  WHERE CODE = '4548-4' AND DATE >= '2021-01-01' AND DATE < '2022-01-01'
)
SELECT CASE WHEN a1c < 4 THEN '1: under 4'
            WHEN a1c < 7 THEN '2: 4 to 6.9'
            WHEN a1c < 8 THEN '3: 7 to 7.9'
            ELSE '4: 8 plus' END AS bucket,
       COUNT(*) AS patients
FROM eligible e
JOIN latest l ON l.PATIENT = e.patient_id AND l.rn = 1
GROUP BY bucket
ORDER BY bucket;
-- expect 10, 26, 4


-- 05_testing_rate_by_county.sql

WITH eligible AS (
  SELECT DISTINCT p.Id AS patient_id
  FROM patients p
  JOIN conditions c ON c.PATIENT = p.Id
  WHERE c.DESCRIPTION = 'Diabetes'
    AND c.START <= '2021-12-31'
    AND (p.DEATHDATE IS NULL OR p.DEATHDATE >= '2021-01-01')
    AND (julianday('2021-12-31') - julianday(p.BIRTHDATE)) / 365.25 BETWEEN 18 AND 75
),
tested_2021 AS (
  SELECT DISTINCT PATIENT
  FROM observations
  WHERE CODE = '4548-4'
    AND DATE >= '2021-01-01' AND DATE < '2022-01-01'
)
SELECT p.COUNTY,
       COUNT(*) AS eligible_patients,
       COUNT(t.PATIENT) AS tested,
       ROUND(100.0 * COUNT(t.PATIENT) / COUNT(*), 1) AS pct_tested
FROM eligible e
JOIN patients p ON p.Id = e.patient_id
LEFT JOIN tested_2021 t ON t.PATIENT = e.patient_id
GROUP BY p.COUNTY
ORDER BY eligible_patients DESC;
-- expect totals 47 and 40


-- 06_dashboard_export.sql (one row per eligible patient, feeds Tableau)

WITH eligible AS (
  SELECT DISTINCT p.Id AS patient_id, p.GENDER, p.COUNTY,
         CAST((julianday('2021-12-31') - julianday(p.BIRTHDATE)) / 365.25 AS INTEGER) AS age
  FROM patients p
  JOIN conditions c ON c.PATIENT = p.Id
  WHERE c.DESCRIPTION = 'Diabetes'
    AND c.START <= '2021-12-31'
    AND (p.DEATHDATE IS NULL OR p.DEATHDATE >= '2021-01-01')
    AND (julianday('2021-12-31') - julianday(p.BIRTHDATE)) / 365.25 BETWEEN 18 AND 75
),
latest_a1c AS (
  SELECT PATIENT, CAST(VALUE AS REAL) AS a1c,
         ROW_NUMBER() OVER (PARTITION BY PATIENT ORDER BY DATE DESC) AS rn
  FROM observations
  WHERE CODE = '4548-4'
    AND DATE >= '2021-01-01' AND DATE < '2022-01-01'
)
SELECT e.patient_id, e.GENDER AS gender, e.COUNTY AS county, e.age,
       CASE WHEN e.age < 45 THEN '18-44'
            WHEN e.age < 65 THEN '45-64'
            ELSE '65-75' END AS age_group,
       CASE WHEN l.a1c IS NULL THEN 0 ELSE 1 END AS tested_2021,
       l.a1c AS latest_a1c_2021,
       CASE WHEN l.a1c >= 7 THEN 1 ELSE 0 END AS above_goal
FROM eligible e
LEFT JOIN latest_a1c l ON l.PATIENT = e.patient_id AND l.rn = 1
ORDER BY e.county, e.patient_id;
-- expect 47 rows, 8 columns; exported as diabetes_a1c_2021_patients.csv