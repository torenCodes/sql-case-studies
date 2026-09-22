-- ================================================================
-- Video Game Sales -- Which genre is the most popular in each region?
-- Source: vgsales.db (table: games, 16,719 rows)
-- Author: Toren Lehrmann
--
-- Returns one row per region (NA, EU, JP, Other) with that region's highest-selling
-- genre. Built as four CTEs unioned into long format so Power BI can read it directly.
-- Answer: Action leads everywhere except Japan, which prefers Role-Playing.
-- ================================================================

WITH NA_Genre AS (
	SELECT 'NA' AS Region, Genre AS Top_Genre, SUM(NA_Sales) AS Total_Sales
	FROM games
	WHERE Genre IS NOT NULL
	GROUP BY Genre
	ORDER BY Total_Sales DESC
	LIMIT 1
),
EU_Genre AS (
	SELECT 'EU' AS Region, Genre AS Top_Genre, SUM(EU_Sales) AS Total_Sales
	FROM games
	WHERE Genre IS NOT NULL
	GROUP BY Genre
	ORDER BY Total_Sales DESC
	LIMIT 1
),
JP_Genre AS (
	SELECT 'JP' AS Region, Genre AS Top_Genre, SUM(JP_Sales) AS Total_Sales
	FROM games
	WHERE Genre IS NOT NULL
	GROUP BY Genre
	ORDER BY Total_Sales DESC
	LIMIT 1
),
Other_Genre AS (
	SELECT 'Other' AS Region, Genre AS Top_Genre, SUM(Other_Sales) AS Total_Sales
	FROM games
	WHERE Genre IS NOT NULL
	GROUP BY Genre
	ORDER BY Total_Sales DESC
	LIMIT 1
)
SELECT *
FROM NA_Genre
UNION ALL
SELECT *
FROM EU_Genre
UNION ALL
SELECT * 
FROM JP_Genre
UNION ALL
SELECT *
FROM Other_Genre;
