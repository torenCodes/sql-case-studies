-- ================================================================
-- Video Game Sales SQL Project — Query Log
-- Database: vgsales.db  |  Table: games
-- Companion to: sql-hands-on-project-setup.md
-- Queries by Toren Lehrmann
-- ================================================================
--
-- About this file:
-- Once a query in DB Browser gives you a finished, correct answer,
-- it is copied here for reference and future use. 
--
-- ================================================================
-- Warm-up queries
-- ================================================================

-- Top 10 games by Global_Sales

SELECT Name, Global_Sales
FROM games
ORDER BY Global_Sales DESC
LIMIT 10;

-- Nintendo games published after 2010

SELECT Name, Year_of_Release
FROM games
WHERE Publisher LIKE 'Nintendo' AND Year_of_Release > 2010
ORDER BY Year_of_Release;

-- Games with Critic_Score > 90 AND User_Score > 8

SELECT Name, Critic_Score, User_Score
FROM games
WHERE Critic_Score > 90 AND User_Score > 8
ORDER BY Critic_Score DESC;

-- All Wii games, sorted by Global_Sales descending

SELECT Name, Global_Sales
FROM games
WHERE Platform LIKE 'Wii'
ORDER BY Global_Sales DESC;

-- Total row count in the table

-- 16719 Rows in the table
SELECT COUNT(*)
FROM games;

-- ================================================================
-- Aggregates & grouping
-- ================================================================

-- Item 1: Total Global_Sales by Genre

SELECT Genre, SUM(Global_Sales) AS Total_Global_Sales
FROM games
WHERE Genre IS NOT NULL
GROUP BY Genre
ORDER BY Total_Global_Sales DESC;

-- Item 2: Publisher with the highest average Critic_Score (min. 20 games)

SELECT Publisher, AVG(Critic_Score) AS avg_critic_score, COUNT(*) AS num_games
FROM games
GROUP BY Publisher
HAVING num_games >= 20
ORDER BY avg_critic_score DESC;

-- Item 3: Average Critic_Score trend by Year_of_Release

SELECT Year_of_Release, ROUND(AVG(Critic_Score),2) AS avg_Critic_Score
FROM games
WHERE Critic_Score IS NOT NULL AND Year_of_Release NOT LIKE 'N/A'
GROUP BY Year_of_Release
ORDER BY Year_of_Release;

-- Item 4: NA vs. JP sales by genre

SELECT Genre, SUM(NA_Sales) AS na_total, SUM(JP_Sales) AS jp_total
FROM games
WHERE Genre IS NOT NULL
GROUP BY Genre
ORDER BY na_total DESC;

-- Item 5: Platform with the highest average Global_Sales per game

SELECT Platform, ROUND(AVG(Global_Sales),3) AS Avg_Global_Sales
FROM games
GROUP BY Platform
ORDER BY Avg_Global_Sales DESC;

-- ================================================================
-- CTEs & window functions
-- ================================================================

-- Publishers active in 3 or more genres

WITH publisher_genre_counts AS (
  SELECT Publisher, COUNT(DISTINCT Genre) AS genre_count
  FROM games
  GROUP BY Publisher
)
SELECT Publisher, genre_count
FROM publisher_genre_counts
WHERE genre_count >= 3
ORDER BY genre_count DESC;

-- Critic scores before 2010 vs. from 2010 onward

WITH pre_2010 AS (
	SELECT ROUND(AVG(Critic_Score),2) AS avg_score
	FROM games
	WHERE Year_of_Release < 2010
),
from_2010 AS (
	SELECT ROUND(AVG(Critic_Score),2) AS avg_score
	FROM games
	WHERE Year_of_Release >= 2010
)
SELECT ROUND(AVG(games.Critic_Score),2) AS avg_overall_critic, pre_2010.avg_score AS before_2010, from_2010.avg_score AS from_2010_on
FROM games, pre_2010, from_2010; 

-- Each genre's share of total NA_Sales (the CTE-only version)

WITH genre_totals AS (
  SELECT Genre, SUM(NA_Sales) AS genre_total
  FROM games
  GROUP BY Genre
),
overall_total AS (
  SELECT SUM(NA_Sales) AS grand_total
  FROM games
)
SELECT 
  genre_totals.Genre AS Genre, 
  genre_totals.genre_total AS Genre_Total_Sales,
  ROUND(genre_totals.genre_total / overall_total.grand_total * 100.0,2) AS Percent_of_Total
FROM genre_totals, overall_total
WHERE Genre IS NOT NULL
ORDER BY Percent_of_Total DESC;

-- ================================================================
-- MINI-BOSS CHALLENGES — Power BI dashboard content
-- ================================================================

-- Mini-Boss 1: Each region's favorite genre
-- For NA, EU, JP, and Other, which single genre has the highest total sales in that region?
-- This produces a "long format" output via UNION ALL
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

-- Mini-Boss 2: Sequel survivorship (standalone vs. franchise titles)

WITH Colon_Stripped AS (
    SELECT 
        Name,
        Global_Sales,
        CASE 
            WHEN INSTR(Name, ':') > 0 
                THEN TRIM(SUBSTR(Name, 1, INSTR(Name, ':') - 1))
            ELSE Name
        END AS Pre_Numeral_Title
    FROM games
),
Base_Titles AS (
    SELECT 
        Name,
        Global_Sales,
        CASE 
            WHEN Pre_Numeral_Title LIKE '% XV'   THEN SUBSTR(Pre_Numeral_Title, 1, LENGTH(Pre_Numeral_Title) - 3)
            WHEN Pre_Numeral_Title LIKE '% XIV'  THEN SUBSTR(Pre_Numeral_Title, 1, LENGTH(Pre_Numeral_Title) - 4)
            WHEN Pre_Numeral_Title LIKE '% XIII' THEN SUBSTR(Pre_Numeral_Title, 1, LENGTH(Pre_Numeral_Title) - 5)
            WHEN Pre_Numeral_Title LIKE '% XII'  THEN SUBSTR(Pre_Numeral_Title, 1, LENGTH(Pre_Numeral_Title) - 4)
            WHEN Pre_Numeral_Title LIKE '% XI'   THEN SUBSTR(Pre_Numeral_Title, 1, LENGTH(Pre_Numeral_Title) - 3)
            WHEN Pre_Numeral_Title LIKE '% X'    THEN SUBSTR(Pre_Numeral_Title, 1, LENGTH(Pre_Numeral_Title) - 2)
            WHEN Pre_Numeral_Title LIKE '% IX'   THEN SUBSTR(Pre_Numeral_Title, 1, LENGTH(Pre_Numeral_Title) - 3)
            WHEN Pre_Numeral_Title LIKE '% VIII' THEN SUBSTR(Pre_Numeral_Title, 1, LENGTH(Pre_Numeral_Title) - 5)
            WHEN Pre_Numeral_Title LIKE '% VII'  THEN SUBSTR(Pre_Numeral_Title, 1, LENGTH(Pre_Numeral_Title) - 4)
            WHEN Pre_Numeral_Title LIKE '% VI'   THEN SUBSTR(Pre_Numeral_Title, 1, LENGTH(Pre_Numeral_Title) - 3)
            WHEN Pre_Numeral_Title LIKE '% V'    THEN SUBSTR(Pre_Numeral_Title, 1, LENGTH(Pre_Numeral_Title) - 2)
            WHEN Pre_Numeral_Title LIKE '% IV'   THEN SUBSTR(Pre_Numeral_Title, 1, LENGTH(Pre_Numeral_Title) - 3)
            WHEN Pre_Numeral_Title LIKE '% III'  THEN SUBSTR(Pre_Numeral_Title, 1, LENGTH(Pre_Numeral_Title) - 4)
            WHEN Pre_Numeral_Title LIKE '% II'   THEN SUBSTR(Pre_Numeral_Title, 1, LENGTH(Pre_Numeral_Title) - 3)
            ELSE TRIM(RTRIM(Pre_Numeral_Title, '0123456789'))
        END AS Base_Title
    FROM Colon_Stripped
),
Counter AS (
	SELECT Base_Title, COUNT(DISTINCT Name) AS Distinct_Name_Count, SUM(Global_Sales) AS Total_Global_Sales
	FROM Base_Titles
	GROUP BY Base_Title
)

SELECT Base_Title, Distinct_Name_Count, Total_Global_Sales
FROM Counter
ORDER BY Total_Global_Sales DESC
LIMIT 100;

-- Mini-Boss 3: Does critic score predict sales? (score tiers)

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

-- Bonus Mini-Boss: Platform peak year (post–Step 7)

