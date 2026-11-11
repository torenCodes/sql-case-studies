-- 02_number_the_legs.sql
-- QUESTION: Can we line up each plane's day in order: flight 1, flight 2, flight 3...?
--
-- WHY: Everything after this (the domino) depends on knowing which flight was
-- first, second, third for each plane on each day. Think of it like numbering the
-- frames of one character's animation: same character (Tail_Number), same shot
-- (FlightDate), frames in time order (CRSDepTime).
--
-- NEW TOOL (you used it once in the diabetes project, query 04):
--   ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...)
--   * PARTITION BY = "start counting over at 1 for each group"
--   * ORDER BY     = "count in this order inside each group"
--
-- ------------------------------------------------------------------
-- DECISION FIRST (log it in DECISION_LOG.md as D4):
--   Should cancelled (Cancelled = 1) and diverted (Diverted = 1) flights get a
--   leg number? Think about it: did the plane actually make that trip?
--   Also: the 2,059 rows with no Tail_Number can't be followed at all.
-- ------------------------------------------------------------------

SELECT
  Tail_Number,
  FlightDate,
  Origin,
  Dest,
  CRSDepTime,
  DepDelay,
  ArrDelay,
  ROW_NUMBER() OVER (
    PARTITION BY Tail_Number, FlightDate     -- which two columns define "one plane's day"?
    ORDER BY CRSDepTime               -- which column puts the flights in time order?
  ) AS leg_num
FROM flights
WHERE Cancelled = 0 AND Diverted = 0 AND Tail_Number IS NOT NULL                     -- your D4 decision + drop missing tail numbers
ORDER BY Tail_Number, FlightDate, leg_num
LIMIT 50;

-- ------------------------------------------------------------------
-- CHECKPOINTS
-- 1. If you exclude cancelled, diverted AND missing-tail rows, removing the
--    LIMIT and running SELECT COUNT(*) on the same WHERE gives 612,038.
-- 2. Eyeball test: add  AND Tail_Number = 'N1776R' AND FlightDate = '2026-07-15'
--    to your WHERE. You should see 6 legs, starting at MDW at 0540 and ending
--    in SAN. Does each leg's Dest match the next leg's Origin?
-- 3. Look at that plane's DepDelay down the day. Where did it pick up a delay,
--    and did it ever win the time back?
-- ------------------------------------------------------------------
