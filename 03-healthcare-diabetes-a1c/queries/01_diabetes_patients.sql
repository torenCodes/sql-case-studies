-- ================================================================
-- Diabetes Care Scorecard -- Patients with a Diabetes diagnosis
-- Data: Synthea sample data, Nov 2021 release (1,163 synthetic patients), SQLite
-- Author: Toren Lehrmann
--
-- Basic join: every patient with a condition recorded as exactly 'Diabetes'
-- (prediabetes is a separate description and is excluded).
-- Expect 73 rows, one per patient.
-- ================================================================

SELECT p.Id, p.FIRST, p.LAST, p.BIRTHDATE, c.START AS diabetes_start
FROM patients p
JOIN conditions c ON c.PATIENT = p.Id
WHERE c.DESCRIPTION = 'Diabetes'
ORDER BY c.START;
