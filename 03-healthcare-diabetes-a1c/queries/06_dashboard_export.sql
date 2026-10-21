-- ================================================================
-- Diabetes Care Scorecard -- One row per eligible patient, the Tableau source
-- Data: Synthea sample data, Nov 2021 release (1,163 synthetic patients), SQLite
-- Author: Toren Lehrmann
--
-- Adds age, age group, tested flag, latest 2021 A1c and an at-or-above-7% flag.
-- Exported as data/diabetes_a1c_2021_patients.csv.
-- Expect 47 rows, 8 columns.
-- ================================================================

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
