-- 06_turn_time.sql
-- QUESTION: 05 showed that delays snowball ON THE GROUND. So does the amount of
--           ground time in the SCHEDULE decide whether a late plane catches up
--           or falls further behind?
--
-- KEY TERM: "scheduled turn" = minutes between a flight's scheduled arrival and
--   the same plane's next scheduled departure. This is the buffer the airline
--   chose when it built the schedule. Bigger buffer = more room to absorb delay,
--   but the plane sits idle longer (which costs money). That trade-off is the
--   business decision we're informing.
--
-- GOOD NEWS: both times are local time at the SAME airport (the plane lands at
--   X, then leaves from X), so time zones don't mess up this subtraction.
--
-- ==================================================================
-- NEW TOOL: turning "hhmm" text into minutes after midnight
--   CRSDepTime is text like '0540'. You can't subtract text, so:
--     substr(CRSDepTime, 1, 2)  -> '05'  (start at character 1, take 2)
--     substr(CRSDepTime, 3, 2)  -> '40'  (start at character 3, take 2)
--     CAST(... AS INTEGER)      -> turns '05' into the number 5
--     5 * 60 + 40               -> 340 minutes after midnight
-- ==================================================================

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
  CASE WHEN sched_turn_min < 0   THEN '0: negative (crosses midnight?)'
       WHEN sched_turn_min < 45  THEN '1: under 45 min'
       WHEN sched_turn_min < 60  THEN '2: 45 to 59'
       WHEN sched_turn_min < 90  THEN '3: 60 to 89'
       WHEN sched_turn_min < 180 THEN '4: 90 to 179'
       ELSE                           '5: 180+' END            AS turn_bucket,
  COUNT(*)                                                     AS turns,
  ROUND(AVG(ground_gain), 1)                                   AS avg_ground_gain,
  ROUND(100.0 * AVG(DepDelay >= 15), 1)                        AS pct_next_flight_late
FROM turns
WHERE prev_arr_delay >= 15  AND                       -- only turns where the plane ARRIVED 15+ min late
      sched_turn_min >= 0                           -- exclude negative turn times
GROUP BY turn_bucket
ORDER BY turn_bucket;

-- ------------------------------------------------------------------
-- NOTE on pct_next_flight_late: (DepDelay >= 15) is 1 when true, 0 when false,
-- so AVG() of it = the share of rows where it's true. A handy shortcut.
--
-- CHECKPOINTS
-- 1. Six rows. Turns: bucket 0 = 2,108 | bucket 1 = 29,239 | bucket 3 = 29,218
-- Correct, these are the results I get.
-- 2. Sanity test before trusting it: pick ONE row from turns (add a LIMIT 5
--    query on the turns CTE) and do the subtraction by hand.
-- Yes, the math checks out.  In the debug query (06b_hand_check.sql) one prev_arr_text was 0825 (hours x 60 + minutes = 8*60 + 25 = 505).
-- The CRSDepTime was 0930 (9*60 + 30 = 570). 570 - 505 = 65, which matches the sched_turn_min column.
--
-- DECISION D6: bucket 0 has NEGATIVE turn times. What's going on there
--   (hint: red-eyes, and how FlightDate is assigned)? Keep or exclude? Log it.
-- We should exclude because the flight is so late they just brought in a new plane to replace it.  This means the data is not representative.
--
-- QUESTIONS TO ANSWER
-- 1. Read avg_ground_gain from short turns to long turns. Where does it flip
--    from "delay grows" (negative) to "delay shrinks" (positive)?
-- It flips at the 90 minute mark.
-- 2. In plain English, for a manager: "When a plane lands 15+ minutes late with less than an hour on the ground, its next 
-- flight leaves late about 9 times out of 10, and the delay grows by another 9–16 minutes on the ground."
-- 3. Bigger buffers aren't free. What does the airline give up by scheduling
--    90-minute turns everywhere?
-- A blanket buffer gives too much time to flights that don't need it. A targeted approach would be better.
-- ------------------------------------------------------------------


