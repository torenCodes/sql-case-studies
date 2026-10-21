-- ================================================================
-- Diabetes Care Scorecard -- A1c testing rate, 2021 (the headline measure)
-- Data: Synthea sample data, Nov 2021 release (1,163 synthetic patients), SQLite
-- Author: Toren Lehrmann
--
-- Denominator: Diabetes diagnosed by 2021-12-31, aged 18-75 on that date, not
-- deceased before 2021. Numerator: at least one A1c result (LOINC 4548-4) in 2021.
-- A LEFT JOIN keeps untested patients in the denominator.
-- Expect 47 eligible, 40 tested, 85.1%.
-- ================================================================

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
