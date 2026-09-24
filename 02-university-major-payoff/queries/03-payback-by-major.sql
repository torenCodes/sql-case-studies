-- ================================================================
-- University Major Payoff -- Which degrees pay for themselves fastest?
-- Source: univ_major_payoff.db (table: majors, 30,000 synthetic graduates)
-- Author: Toren Lehrmann
--
-- Cost of the degree divided by average yearly salary, per major.
-- Answer: payback order follows salary almost exactly, because cost barely varies
-- between majors. Electrical engineering fastest, fine arts slowest.
-- ================================================================

SELECT major,
	ROUND(AVG(net_cost_usd), 0) AS avg_total_cost,
	ROUND(AVG(earnings_10yr_usd / 10), 0) AS avg_salary,
	ROUND(AVG(net_cost_usd), 0) / ROUND(AVG(earnings_10yr_usd / 10), 0) AS years_to_pay_back,
	COUNT(*) AS num_students
FROM majors
GROUP BY major
ORDER BY years_to_pay_back
LIMIT 100;
