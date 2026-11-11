-- 07_minutes_at_stake.sql
-- QUESTION: Across July 2026, how many delay minutes did late planes ADD on
--           tight turns (under 60 min on the ground), what's that worth in
--           dollars, and WHICH AIRPORTS hold the most of it?
--
-- WHY: Your 06 answer said blanket buffers are wasteful and targeted ones are
-- smarter. This query tells management WHERE to target, and what's at stake.
--
-- THE MONEY: Airlines for America (A4A) puts the average direct cost of aircraft
--   block time at $100.76 per minute (2024). Source:
--   https://airlines.org/dataset/u-s-passenger-carrier-delay-costs/
--   CAVEAT (log as D7): that's a cost for taxi + airborne minutes, and we're
--   applying it to minutes added on the ground. It's a reasonable yardstick, not
--   an exact bill. Say so wherever the dollar figure appears.
--
-- WORDING MATTERS: call these "minutes / dollars AT STAKE", not "saved".
--   A buffer wouldn't win back every minute (ATL may just be congested), so the
--   honest claim is "this is the size of the problem at these airports."
-- ==================================================================

-- Paste your legs and turns CTEs from 06 here (the main ones, NOT the debug one).
WITH legs AS (
  SELECT
    Tail_Number,
    FlightDate,
    Origin,
    DepDelay,
    -- this flight's scheduled departure, in minutes (done for you):
    CAST(substr(CRSDepTime, 1, 2) AS INTEGER) * 60
      + CAST(substr(CRSDepTime, 3, 2) AS INTEGER)              AS sched_dep_min,

    -- the PREVIOUS flight's scheduled arrival, in minutes.
    -- YOUR TURN: same conversion as above, but on CRSArrTime, wrapped in LAG():
    LAG(CAST(substr(CRSArrTime, 1, 2) AS INTEGER) * 60
      + CAST(substr(CRSArrTime, 3, 2) AS INTEGER)) OVER (PARTITION BY Tail_Number, FlightDate ORDER BY CRSDepTime) AS prev_sched_arr_min,

    LAG(ArrDelay) OVER (PARTITION BY Tail_Number, FlightDate ORDER BY CRSDepTime) AS prev_arr_delay,
    LAG(Dest)     OVER (PARTITION BY Tail_Number, FlightDate ORDER BY CRSDepTime) AS prev_dest
  FROM flights
  WHERE Cancelled = 0 AND Diverted = 0 AND Tail_Number IS NOT NULL
),
turns AS (
  SELECT
    *,
    sched_dep_min - prev_sched_arr_min                  AS sched_turn_min,  -- next departure minus previous arrival
    prev_arr_delay - DepDelay    AS ground_gain      -- same formula as 05
  FROM legs
  WHERE prev_arr_delay IS NOT NULL      -- skips leg 1 (no previous flight)
    AND prev_dest = Origin              -- skips the ~3% of legs where the chain breaks
)

-- ---------------- PART A: the airport ranking ----------------
SELECT
  Origin                                        AS airport,
  COUNT(*)                                      AS tight_late_turns,
  ROUND(AVG(ground_gain), 1)                    AS avg_ground_gain,
  SUM(-ground_gain)                                     AS minutes_added,
                         -- ^ ground_gain is NEGATIVE when delay grows.
                         --   How do you flip it so "added" minutes are positive?
  ROUND(SUM(-ground_gain) * 100.76 / 1000000.0, 2)        AS usd_millions_at_stake
FROM turns
WHERE prev_arr_delay >= 15                    -- plane arrived 15+ min late
  AND sched_turn_min >= 0                    -- D6: drop the negative (aircraft-swap) turns
  AND sched_turn_min < 60                    -- tight turns only: under 60 minutes
GROUP BY Origin
ORDER BY usd_millions_at_stake DESC
LIMIT 10;

-- ---------------- PART B: the national total ----------------
WITH legs AS (
  SELECT
    Tail_Number,
    FlightDate,
    Origin,
    DepDelay,
    -- this flight's scheduled departure, in minutes (done for you):
    CAST(substr(CRSDepTime, 1, 2) AS INTEGER) * 60
      + CAST(substr(CRSDepTime, 3, 2) AS INTEGER)              AS sched_dep_min,

    -- the PREVIOUS flight's scheduled arrival, in minutes.
    -- YOUR TURN: same conversion as above, but on CRSArrTime, wrapped in LAG():
    LAG(CAST(substr(CRSArrTime, 1, 2) AS INTEGER) * 60
      + CAST(substr(CRSArrTime, 3, 2) AS INTEGER)) OVER (PARTITION BY Tail_Number, FlightDate ORDER BY CRSDepTime) AS prev_sched_arr_min,

    LAG(ArrDelay) OVER (PARTITION BY Tail_Number, FlightDate ORDER BY CRSDepTime) AS prev_arr_delay,
    LAG(Dest)     OVER (PARTITION BY Tail_Number, FlightDate ORDER BY CRSDepTime) AS prev_dest
  FROM flights
  WHERE Cancelled = 0 AND Diverted = 0 AND Tail_Number IS NOT NULL
),
turns AS (
  SELECT
    *,
    sched_dep_min - prev_sched_arr_min                  AS sched_turn_min,  -- next departure minus previous arrival
    prev_arr_delay - DepDelay    AS ground_gain      -- same formula as 05
  FROM legs
  WHERE prev_arr_delay IS NOT NULL      -- skips leg 1 (no previous flight)
    AND prev_dest = Origin              -- skips the ~3% of legs where the chain breaks
)

SELECT
  
  COUNT(*)                                      AS tight_late_turns,
  ROUND(AVG(ground_gain), 1)                    AS avg_ground_gain,
  SUM(-ground_gain)                                     AS minutes_added,
                         -- ^ ground_gain is NEGATIVE when delay grows.
                         --   How do you flip it so "added" minutes are positive?
  ROUND(SUM(-ground_gain) * 100.76 / 1000000.0, 2)        AS usd_millions_at_stake
FROM turns
WHERE prev_arr_delay >= 15                    -- plane arrived 15+ min late
  AND sched_turn_min >= 0                    -- D6: drop the negative (aircraft-swap) turns
  AND sched_turn_min < 60;                    -- tight turns only: under 60 minutes


-- ------------------------------------------------------------------
-- TIP: your viewer only shows the LAST query's result when you run the whole
-- file. Highlight one query and run just that selection (Ctrl+Return in DB Browser).
--
-- CHECKPOINTS
-- PART A: #1 airport is ATL with 1,577 tight late turns and 32,110 minutes added.
-- Correct, these are the results I get.
-- PART B: 59,452 turns in total.
-- Correct, these are the results I get.

-- QUESTIONS TO ANSWER
-- 1. PART B: total minutes added and total $ at stake for July.
-- 734024 minutes added, $74 million at stake
-- 2. What share of the national total do your top 10 airports hold?
--    (add the 10 minutes_added values, divide by PART B's total)
-- 29.7%
-- 3. ATL is #1 in total minutes. Is it #1 in avg_ground_gain too? Which
--    measure would you show a manager deciding where to add buffer, and why?
-- Rank by total minutes to find the money totals, then look at airports.  ATL is losing ground and costing the most minutes, so extra buffer could be useful here.
-- DEN planes are not losing much time, but cost is still up there.
-- 4. Write your D7 caveat in one sentence, in your own words.
-- Total expense for all airports is $74 million.  Worst individual airport contributing to this is ATL at 3.24 million.
-- ------------------------------------------------------------------
