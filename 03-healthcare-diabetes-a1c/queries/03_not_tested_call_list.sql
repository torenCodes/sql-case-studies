-- ================================================================
-- Diabetes Care Scorecard -- Eligible patients with no A1c test in 2021
-- Data: Synthea sample data, Nov 2021 release (1,163 synthetic patients), SQLite
-- Author: Toren Lehrmann
--
-- Anti-join (LEFT JOIN ... WHERE t.PATIENT IS NULL): the follow-up list.
-- Names are Synthea's generated names, not real people.
-- Expect 7 rows; each had an A1c in 2019 or 2020, none in 2021.
-- ================================================================

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
