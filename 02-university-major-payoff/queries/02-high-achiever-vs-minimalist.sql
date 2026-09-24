-- ================================================================
-- University Major Payoff -- How much do internships and finishing on time change the return?
-- Source: univ_major_payoff.db (table: majors, 30,000 synthetic graduates)
-- Author: Toren Lehrmann
--
-- Buckets graduates into High Achievers (interned AND finished on time) and
-- Minimalists (neither), unions them into long format, and averages net ROI per major.
-- Graduates who did exactly one of the two are deliberately left out of both groups.
-- Answer: High Achievers return more in all 19 majors; near the bottom of the table
-- the gap decides whether a degree pays at all.
-- ================================================================

WITH Completionist AS (
SELECT *
FROM majors
WHERE had_internship = 1 AND completed_on_time = 1
),
Minimalist AS (
SELECT *
FROM majors
WHERE had_internship = 0 AND completed_on_time = 0
),
Combined AS (
SELECT major, net_roi_usd, 'High_Achiever' AS group_label
FROM Completionist
UNION ALL
SELECT major, net_roi_usd, 'Minimalist' AS group_label
FROM Minimalist
)

SELECT major, group_label, ROUND(AVG(net_roi_usd),0) AS avg_net_roi, COUNT(*) AS num_grads
FROM Combined
GROUP BY major, group_label;
