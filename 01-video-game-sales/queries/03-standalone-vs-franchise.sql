-- ================================================================
-- Video Game Sales -- Which standalone titles compete with or outperform franchises?
-- Source: vgsales.db (table: games, 16,719 rows)
-- Author: Toren Lehrmann
--
-- Normalises every title to a base name -- first by stripping anything after a colon,
-- then by trimming trailing Roman numerals and digits -- so that sequels collapse onto
-- their franchise. Counting distinct names per base title then separates one-off
-- releases from series.
-- Answer: Wii Sports is the only standalone in franchise sales territory.
-- ================================================================

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
