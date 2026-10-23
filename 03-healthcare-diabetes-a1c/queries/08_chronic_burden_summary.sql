-- ================================================================
-- Diabetes Care Scorecard -- Page 2: visits and cost by number of chronic conditions
-- Data: Synthea sample data, Nov 2021 release (1,163 synthetic patients), SQLite
-- Author: Toren Lehrmann
--
-- Cohort: 790 adults, aged 18 or older on 2021-12-31 and not deceased before
-- 2020-01-01. Visits and cost come from encounters in 2020 and 2021.
--
-- The LEFT JOINs matter: an inner join to the chronic conditions would silently
-- drop every adult with none, the largest group. LEFT JOIN plus COALESCE keeps
-- them at zero, and the groups reconcile back to 790.
--
-- Expect 5 rows, exported as data/chronic_burden_summary.csv:
--   chronic_group  adults  avg_visits  avg_cost
--   0              255     6.7         32,253
--   1              216     7.2         28,715
--   2              153     7.3         29,835
--   3               89     7.5         28,891
--   4+              77     13.9        76,908
-- The 4+ group is 9.7% of adults and 21.5% of the $27.48M total cost.
-- ================================================================

WITH chronic AS (
  SELECT DISTINCT PATIENT AS Patient, DESCRIPTION AS Condition
  FROM conditions c
  WHERE DESCRIPTION IN ('Hypertension', 'Diabetes', 'Prediabetes', 'Hyperlipidemia',
                        'Coronary Heart Disease', 'Stroke', 'Atrial Fibrillation',
                        'Metabolic syndrome X (disorder)', 'Osteoporosis (disorder)',
                        'Anemia (disorder)')
),
burden AS (
  SELECT p.Id AS patient_id,
         COUNT(ch.Condition) AS Num_Chronic
  FROM patients p
  LEFT JOIN chronic ch ON ch.Patient = p.Id
  WHERE (p.DEATHDATE IS NULL OR p.DEATHDATE >= '2020-01-01')
    AND (julianday('2021-12-31') - julianday(p.BIRTHDATE)) / 365.25 >= 18
  GROUP BY p.Id
),
visits AS (
  SELECT PATIENT, COUNT(*) AS num_visits, SUM(TOTAL_CLAIM_COST) AS total_cost
  FROM encounters
  WHERE START >= '2020-01-01' AND START < '2022-01-01'
  GROUP BY PATIENT
)
SELECT
  CASE WHEN b.num_chronic >= 4 THEN '4+' ELSE CAST(b.num_chronic AS TEXT) END AS chronic_group,
  COUNT(*) AS adults,
  ROUND(AVG(COALESCE(v.num_visits, 0)), 1) AS avg_visits,
  ROUND(AVG(COALESCE(v.total_cost, 0)), 0) AS avg_cost,
  ROUND(SUM(COALESCE(v.total_cost, 0)), 0) AS total_cost
FROM burden b
LEFT JOIN visits v ON v.PATIENT = b.patient_id
GROUP BY chronic_group
ORDER BY chronic_group;
