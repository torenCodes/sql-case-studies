-- ================================================================
-- Diabetes Care Scorecard -- Testing rate by Massachusetts county
-- Data: Synthea sample data, Nov 2021 release (1,163 synthetic patients), SQLite
-- Author: Toren Lehrmann
--
-- The grouping used instead of providers: the 47 patients spread across too
-- many organizations for provider groups to hold more than one or two people.
-- Expect totals of 47 eligible and 40 tested.
-- ================================================================

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
