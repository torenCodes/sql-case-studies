-- 03_first_vs_last.sql
-- QUESTION: When a plane's FIRST flight of the day leaves late, how late is its
--           LAST flight of the day, compared with planes that start on time?
--
-- WHY: This is the domino test. If a late start doesn't make the end of the day
-- worse, there's no story. If it does, the gap between the two groups is the
-- first draft of the headline.
--
-- THE PLAN (three CTEs, like three passes in a render):
--   A. legs        -> every flight, numbered (your 02 query) + "how many legs today"
--   B. plane_days  -> squash each plane's day into ONE row: first delay, last delay
--   C. final       -> split plane-days into "late start" vs "on-time start", compare
--
-- ==================================================================
-- NEW TOOL 1: COUNT(*) OVER (PARTITION BY ...)
--   Same window idea as ROW_NUMBER, but instead of numbering 1, 2, 3 it writes
--   the TOTAL count on every row. So every leg of N1776R on July 15 would show
--   legs_today = 6. That tells us which leg is the last one: leg_num = legs_today.
--
-- NEW TOOL 2: MAX(CASE WHEN ... THEN ... END) with GROUP BY  ("the mask trick")
--   CASE WHEN leg_num = 1 THEN DepDelay END  gives DepDelay on leg 1 and NULL
--   on every other leg. MAX() ignores NULLs, so it returns the one real value.
--   It works like a mask in Substance: only the pixel you masked passes through.
-- ==================================================================

WITH legs AS (
  SELECT
    Tail_Number,
    FlightDate,
    DepDelay,
    ArrDelay,
    ROW_NUMBER() OVER (PARTITION BY Tail_Number, FlightDate ORDER BY CRSDepTime) AS leg_num,
    COUNT(*)     OVER (PARTITION BY Tail_Number, FlightDate) AS legs_today      
  FROM flights
  WHERE Cancelled = 0 AND Diverted = 0 AND Tail_Number IS NOT NULL
),

plane_days AS (
  SELECT
    Tail_Number,
    FlightDate,
    legs_today,
    MAX(CASE WHEN leg_num = 1 THEN DepDelay END) AS first_dep_delay,   
    MAX(CASE WHEN leg_num = legs_today THEN ArrDelay END) AS last_arr_delay    
  FROM legs
  WHERE legs_today > 1                   
  GROUP BY Tail_Number, FlightDate
)

SELECT
  CASE WHEN first_dep_delay >= 15 THEN 'late start'
       ELSE 'on-time start' END        AS start_group,
  COUNT(*)                             AS plane_days,
  ROUND(AVG(last_arr_delay), 1)        AS avg_last_arr_delay,
  ROUND(AVG(legs_today), 1) AS avg_legs
FROM plane_days
GROUP BY start_group;

-- ------------------------------------------------------------------
-- CHECKPOINTS (if you keep only days with 2+ legs)
-- 1. Total plane_days across both groups: 138,730
-- 2. The 'late start' group: 18,300 plane-days
--
-- QUESTIONS TO ANSWER (tell Claude, then log anything that's a decision)
-- 1. What's the gap between the two groups' average last-flight delay?
-- 27.7 minutes
-- 2. Look at the on-time-start number by itself. Does it surprise you?
-- Yes, it is a large number and I thought there would be more delayed flights at the start of the day.
-- 3. Is this a fair fight? Check avg_legs for each group. If one group
--    flies more legs, what does that do to the comparison?
-- It's mostly fair.  On-time start planes average 4.4 while late start planes average 3.7.  On-time has more chances to make errors, which shows a late start has a big impact.
-- ------------------------------------------------------------------
