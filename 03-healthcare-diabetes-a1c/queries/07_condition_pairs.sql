-- ================================================================
-- Diabetes Care Scorecard -- Page 2: which chronic conditions occur together
-- Data: Synthea sample data, Nov 2021 release (1,163 synthetic patients), SQLite
-- Author: Toren Lehrmann
--
-- A self-join: each patient's chronic conditions joined to themselves, so every
-- pair of conditions a patient has becomes one row, then counted per pair.
-- Feeds the heat map on page 2 of the dashboard.
--
-- The ten conditions are a hand-picked list, because the conditions table also
-- holds social findings and situations that are not diseases.
-- Counts every patient in the dataset; it is not limited to the 790 adults
-- in query 08.
--
-- Expect 100 rows (10 x 10), exported as data/condition_pairs.csv. The diagonal
-- (condition_a = condition_b) is each condition's total, from Prediabetes 341
-- down to Atrial Fibrillation 44; Tableau blanks it out. The largest pair is
-- Anemia + Prediabetes, 275.
-- ================================================================

WITH chronic AS (
  SELECT DISTINCT PATIENT AS patient_id, DESCRIPTION AS condition
  FROM conditions
  WHERE DESCRIPTION IN ('Hypertension', 'Diabetes', 'Prediabetes', 'Hyperlipidemia',
                        'Coronary Heart Disease', 'Stroke', 'Atrial Fibrillation',
                        'Metabolic syndrome X (disorder)', 'Osteoporosis (disorder)',
                        'Anemia (disorder)')
)
SELECT a.condition AS condition_a,
       b.condition AS condition_b,
       COUNT(*) AS patients_with_both
FROM chronic a
JOIN chronic b
  ON b.patient_id = a.patient_id
-- AND a.condition < b.condition would keep each pair once; leaving it out
-- returns the whole grid, which the heat map needs
GROUP BY a.condition, b.condition
ORDER BY a.condition, b.condition;
