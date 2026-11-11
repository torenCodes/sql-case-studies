-- 05_where_time_is_won.sql
-- HYPOTHESIS (Toren): Late-start planes that recover do it IN THE AIR:
--   flying faster, crew urgency, quicker taxi or a closer gate.
--
-- RIVAL HYPOTHESIS: they recover ON THE GROUND. If the schedule leaves extra
--   time between landing and the next departure, a late plane can use that
--   slack to "catch up" before its next flight.
--
-- A good test checks BOTH, because each points to a different fix for management:
--   in the air  -> about flight operations
--   on the ground -> about schedule buffers (turn times)
--
-- ==================================================================
-- HOW WE MEASURE IT (two kinds of "minutes won back")
--
--   air_gain    = DepDelay - ArrDelay  (one flight)
--                 Left 40 late, landed 25 late -> 15 min won in the air
--                 (this includes taxi out and taxi in, so it covers your
--                  "expedited taxi / closer gate" idea too)
--
--   ground_gain = (previous flight's ArrDelay) - (this flight's DepDelay)
--                 Landed 25 late, next flight left 10 late -> 15 min won on the ground
--
--   Positive = time won back. Negative = time LOST (the delay grew).
--
-- NEW TOOL: LAG(column) OVER (PARTITION BY ... ORDER BY ...)
--   Reaches back one row inside the group and grabs a value from the PREVIOUS
--   row. Like onion-skinning in animation: you see the frame before this one.
--   On leg 1 there's no previous row, so LAG returns NULL.
-- ==================================================================

WITH legs AS (
  SELECT
    Tail_Number,
    FlightDate,
    DepDelay,
    ArrDelay,
    ROW_NUMBER() OVER (PARTITION BY Tail_Number, FlightDate ORDER BY CRSDepTime) AS leg_num,
    COUNT(*)     OVER (PARTITION BY Tail_Number, FlightDate) AS legs_today,
    LAG(ArrDelay)    OVER (PARTITION BY Tail_Number, FlightDate ORDER BY CRSDepTime) AS prev_arr_delay
                                   -- ^ which column do we need from the previous flight?
  FROM flights
  WHERE Cancelled = 0 AND Diverted = 0 AND Tail_Number IS NOT NULL
),

plane_days AS (
  SELECT
    Tail_Number,
    FlightDate,
    legs_today,
    MAX(CASE WHEN leg_num = 1 THEN DepDelay END)          AS first_dep_delay,
    MAX(CASE WHEN leg_num = legs_today THEN ArrDelay END) AS last_arr_delay,
    SUM(DepDelay - ArrDelay)                              AS air_gain,     -- every leg
    SUM(CASE WHEN leg_num > 1 THEN prev_arr_delay - DepDelay END) AS ground_gain   -- legs 2+ only (why?)
    --- legs 2+ only because leg 1 has no previous flight to compare to
  FROM legs
  WHERE legs_today > 1
  GROUP BY Tail_Number, FlightDate
)

SELECT
  CASE WHEN last_arr_delay < 0  THEN '1: recovered (landed early)'
       WHEN last_arr_delay < 60 THEN '2: partial (0 to 59 late)'
       ELSE                          '3: snowballed (60+ late)' END AS outcome,
  COUNT(*)                         AS plane_days,
  ROUND(AVG(first_dep_delay), 1)   AS avg_first_dep_delay,
  ROUND(AVG(last_arr_delay), 1)    AS avg_last_arr_delay,
  ROUND(AVG(air_gain), 1)          AS avg_air_gain,
  ROUND(AVG(ground_gain), 1)       AS avg_ground_gain
FROM plane_days
WHERE first_dep_delay >= 15             -- late starts only (same rule as 03 and 04)
GROUP BY outcome
ORDER BY outcome;

-- ------------------------------------------------------------------
-- CHECKPOINTS
-- 1. Three rows. Plane-days: recovered 5,401 | partial 7,227 | snowballed 5,672
--    (they add to 18,300, the late-start group from 03)
-- 2. SELF-CHECK MATH (this one is neat): for every row,
--       avg_first_dep_delay - avg_last_arr_delay  =  avg_air_gain + avg_ground_gain
--    (give or take 0.1 from rounding). Why must that be true? Think about
--    how each flight's delay hands off to the next one.
-- Every minute of delay gets handed off in a chain: first departure, then arrival (air gain), then next departure (ground gain), then arrival (air gain), and so on to the last arrival. So the total change from start to finish has to equal all the air gains plus all the ground gains. Nothing can enter or leave the chain anywhere else.
--
-- QUESTIONS TO ANSWER
-- 1. For the planes that recovered: where did more of the time come back,
--    in the air or on the ground? Was your hypothesis right, partly right, or wrong?
-- 45.2 minutes gained on the ground, with 37.3 gained in the air. My hypothesis was partly right, as I thought more time would be gained in the air.
-- 2. For the planes that snowballed: where did the delay GROW?
-- Ground gain was -65.2, so things got worse on the ground.
-- 3. Compare avg_first_dep_delay across the three rows. Did the snowballed
--    group start in a deeper hole? Why does that matter for a fair comparison?
-- Yes. Snowballed planes started 108.6 min late vs about 69 for the other two groups, and ended at 170.1 (+61.5). 
-- Because they started in a deeper hole, part of their bad ending is just the bigger starting delay, not only how the day 
-- was handled. The fair comparison is recovered vs partial, which both started about 69 min late.
-- 4. Interview question: if a flight lands 15 min "faster" than scheduled, is
--    that crew urgency, or could the schedule just have extra time built in?
--    Can this data tell the difference?
-- No. A flight beating its scheduled time could be crew urgency, or the schedule could have extra minutes built in. 
-- The data only shows the result, not the reason. One clue points to built-in slack: in query 04, 44% of on-time-start 
-- planes still finished the day early, and they had nothing to catch up on.
-- ------------------------------------------------------------------
