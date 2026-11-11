-- Debug Query for Cehckpoint 2
WITH legs AS (
  SELECT
    Tail_Number, FlightDate, Origin, DepDelay, CRSDepTime,
    CAST(substr(CRSDepTime, 1, 2) AS INTEGER) * 60
      + CAST(substr(CRSDepTime, 3, 2) AS INTEGER)                 AS sched_dep_min,
    LAG(CRSArrTime) OVER (PARTITION BY Tail_Number, FlightDate ORDER BY CRSDepTime) AS prev_arr_text,
    LAG(CAST(substr(CRSArrTime, 1, 2) AS INTEGER) * 60
      + CAST(substr(CRSArrTime, 3, 2) AS INTEGER))
        OVER (PARTITION BY Tail_Number, FlightDate ORDER BY CRSDepTime) AS prev_sched_arr_min,
    LAG(ArrDelay) OVER (PARTITION BY Tail_Number, FlightDate ORDER BY CRSDepTime) AS prev_arr_delay,
    LAG(Dest)     OVER (PARTITION BY Tail_Number, FlightDate ORDER BY CRSDepTime) AS prev_dest
  FROM flights
  WHERE Cancelled = 0 AND Diverted = 0
    AND Tail_Number = 'N1776R' AND FlightDate = '2026-07-15'   -- the one-plane filter
),
turns AS (
  SELECT *, sched_dep_min - prev_sched_arr_min AS sched_turn_min
  FROM legs
  WHERE prev_arr_delay IS NOT NULL AND prev_dest = Origin
)
SELECT Origin, prev_arr_text, CRSDepTime, prev_sched_arr_min, sched_dep_min, sched_turn_min
FROM turns
ORDER BY CRSDepTime;