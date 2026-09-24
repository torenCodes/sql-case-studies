-- ================================================================
-- University Majors ROI SQL Project — Query Log
-- Database: univ_major_payoff.db  |  Table: majors
-- Companion to: sql-hands-on-project-setup.md
-- Queries by Toren Lehrmann
-- ================================================================
--
-- About this file:
-- Once a query in DB Browser gives you a finished, correct answer,
-- it is copied here for reference and future use. 
--
-- ================================================================
-- Main queries
-- ================================================================

-- Question 1 - Which major has the best ROI?

SELECT major, ROUND(AVG(roi_pct),0) AS avg_ROI_percent, ROUND(AVG(earnings_10yr_usd / 10),0) AS avg_salary, COUNT(*) AS num_grads
FROM majors
GROUP BY major
ORDER BY avg_ROI_percent DESC
LIMIT 100;

-- Question 2 - How do internships and timely degree completions affect earnings?  Put students into achievement buckets and then compare the ROI.

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

-- Question 3 - Which major has the most debt?  Which can be paid back the fastest (cost / salary)?

SELECT major,
	ROUND(AVG(net_cost_usd), 0) AS avg_total_cost,
	ROUND(AVG(earnings_10yr_usd / 10), 0) AS avg_salary,
	ROUND(AVG(net_cost_usd), 0) / ROUND(AVG(earnings_10yr_usd / 10), 0) AS years_to_pay_back,
	COUNT(*) AS num_students
FROM majors
GROUP BY major
ORDER BY years_to_pay_back
LIMIT 100;