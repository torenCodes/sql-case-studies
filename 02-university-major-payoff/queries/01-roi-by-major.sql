-- ================================================================
-- University Major Payoff -- Which major has the best return on investment?
-- Source: univ_major_payoff.db (table: majors, 30,000 synthetic graduates)
-- Author: Toren Lehrmann
--
-- Average ROI percent and average yearly salary (10-year earnings / 10) per major.
-- Answer: electrical engineering, at 759% and about $105,000 a year. Only humanities
-- and fine arts come out negative on average.
-- ================================================================

SELECT major, ROUND(AVG(roi_pct),0) AS avg_ROI_percent, ROUND(AVG(earnings_10yr_usd / 10),0) AS avg_salary, COUNT(*) AS num_grads
FROM majors
GROUP BY major
ORDER BY avg_ROI_percent DESC
LIMIT 100;
