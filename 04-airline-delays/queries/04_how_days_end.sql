-- 04_how_days_end.sql
-- QUESTION: The averages say on-time-start planes end the day 30.5 min late.
--           Is that what a TYPICAL plane's day looks like, or are a few
--           disasters dragging the average up?
--
-- WHY: An average works like a seesaw. One 400-minute meltdown can outweigh
-- dozens of planes that landed early. Before 58.2 vs 30.5 goes on the site, we
-- need to see the whole shape: how many days end early, a bit late, very late.
--
-- THE PLAN: Reuse 03's first two CTEs unchanged, then sort every plane-day into
-- delay "buckets" (same CASE WHEN bucket idea as diabetes query 04).
--
-- ==================================================================
-- NEW TOOL: a percent-of-group column
--   ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY start_group), 1)
--   * COUNT(*)                 = plane-days in THIS bucket
--   * SUM(COUNT(*)) OVER (...) = plane-days in this bucket's WHOLE GROUP
--   So each row says "this bucket is X% of the late-start (or on-time) group."
--   It's written for you below; just know what it's doing.
-- ==================================================================

WITH legs AS (
  SELECT
    Tail_Number,
    FlightDate,
    DepDelay,
    ArrDelay,
    ROW_NUMBER() OVER (PARTITION BY Tail_Number, FlightDate ORDER BY CRSDepTime) AS leg_num,
    COUNT(*)     OVER (PARTITION BY Tail_Number, FlightDate) AS legs_today      -- same two as above
  FROM flights
  WHERE Cancelled = 0 AND Diverted = 0 AND Tail_Number IS NOT NULL
),

plane_days AS (
  SELECT
    Tail_Number,
    FlightDate,
    legs_today,
    MAX(CASE WHEN leg_num = 1 THEN DepDelay END) AS first_dep_delay,   -- done for you
    MAX(CASE WHEN leg_num = legs_today THEN ArrDelay END) AS last_arr_delay     -- your turn
  FROM legs
  WHERE legs_today > 1
  GROUP BY Tail_Number, FlightDate
),

labeled AS (
  SELECT
    CASE WHEN first_dep_delay >= 15 THEN 'late start'
         ELSE 'on-time start' END AS start_group,
    CASE WHEN last_arr_delay < 0 THEN '1: early'
         WHEN last_arr_delay < 15 THEN '2: 0 to 14'
         WHEN last_arr_delay < 60 THEN '3: 15 to 59'
         WHEN last_arr_delay < 180 THEN '4: 60 to 179'
         ELSE '5: 180+' END AS end_bucket
  FROM plane_days
)

SELECT
  start_group,
  end_bucket,
  COUNT(*) AS plane_days,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY start_group), 1) AS pct_of_group
FROM labeled
GROUP BY start_group, end_bucket
ORDER BY start_group, end_bucket;

-- ------------------------------------------------------------------
-- CHECKPOINTS
-- 1. You should get 10 rows (2 groups x 5 buckets).
-- 2. 'on-time start' / '1: early'  = 53,019 plane-days
-- 3. 'late start'    / '5: 180+'   = 1,454 plane-days
-- 4. pct_of_group should add to 100 within each group.
--
-- QUESTIONS TO ANSWER
-- 1. For on-time starts: what % of days end early or under 15 min late
--    (buckets 1 + 2)? Does "30.5 min late on average" describe them fairly?
-- Yeah, 30 mins is far.  60.8% on time start end the day 15 mins or under.
-- 2. For late starts: what % of days end EARLY? Did you expect that?
-- 30%, no I did not expect that.  I would have thought that late starts would end the day late.
-- 3. Compare bucket 4 + 5 (60+ min late) between the groups. This may be a
--    better headline than the averages. Why?
-- 30.9% of late start planes end the day 60+ mins late, while only 17.8% of on-time start planes end the day 60+ mins late.
-- This is a better headline because it shows that late start planes are more likely to end the day late than on-time start planes.
-- ------------------------------------------------------------------
