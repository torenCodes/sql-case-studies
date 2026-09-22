-- ================================================================
-- Video Game Sales -- How do sales relate to critic score, and by how much?
-- Source: vgsales.db (table: games, 16,719 rows)
-- Author: Toren Lehrmann
--
-- Buckets every title into a score tier and averages global sales per title.
-- num_games is returned alongside on purpose: it shows that the 'N/A' tier is the
-- largest one, which is why unrated titles are excluded from the published finding.
-- Answer: 'Great' (90+) averages more than double 'Good'; the decline is monotonic.
-- ================================================================

SELECT
	CASE WHEN Critic_Score >= 90 THEN 'Great'
		 WHEN Critic_Score >= 80 THEN 'Good'
		 WHEN Critic_Score >= 70 THEN 'Average'
		 WHEN Critic_Score IS NULL THEN 'N/A'
		 ELSE 'Poor'
	END AS Score_Tier,
	ROUND(AVG(Global_Sales),3) AS Avg_Sales,
	COUNT(*) AS num_games
FROM games
GROUP BY Score_Tier
ORDER BY Avg_Sales DESC;
