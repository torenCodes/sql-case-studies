-- ================================================================
-- Diabetes Care Scorecard -- Latest 2021 A1c result, bucketed
-- Data: Synthea sample data, Nov 2021 release (1,163 synthetic patients), SQLite
-- Author: Toren Lehrmann
--
-- ROW_NUMBER() picks each tested patient's most recent 2021 result; VALUE is
-- stored as text, so it is cast to REAL before bucketing.
-- Expect 10 under 4, 26 from 4 to 6.9, 4 from 7 to 7.9, none 8 or above.
-- ================================================================

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
