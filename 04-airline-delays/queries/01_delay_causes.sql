-- 01_delay_causes.sql
-- QUESTION: In July 2026, what share of all delay minutes came from each cause?
--           Is "late-arriving aircraft" (the domino effect) a big deal or a footnote?
--
-- WHY THIS FIRST: Before we chase planes through their day, we need proof the
-- problem is worth chasing. This one number is the "hook" for the whole project.
--
-- THE FIVE CAUSE COLUMNS (minutes):
--   CarrierDelay, WeatherDelay, NASDelay, SecurityDelay, LateAircraftDelay
--
-- ------------------------------------------------------------------
-- STEP 1: Total minutes per cause. One is done for you; add the other four.
-- ------------------------------------------------------------------
SELECT
	SUM(CarrierDelay) AS carrier_minutes,
	SUM(WeatherDelay) AS weather_minutes,
	SUM(NASDelay) AS  natsys_minutes,
	SUM(SecurityDelay) AS security_minutes,
	SUM(LateAircraftDelay) AS lateplane_minutes
FROM flights;

-- Numbers totaled 13,743,367.

-- ------------------------------------------------------------------
-- STEP 2: Turn each total into a percent of all delay minutes.
-- ------------------------------------------------------------------
-- Hint 1: percent = 100.0 * (one cause) / (all five added together)
-- Hint 2: Why 100.0 and not 100? Same trick as the diabetes project:
--         the decimal forces real division instead of whole-number division.
-- Hint 3: ROUND(value, 1) keeps it to one decimal place.
-- Hint 4: Your five percents should add to (about) 100.

-- Write STEP 2 here:

WITH FlightDelays AS(
SELECT
	SUM(CarrierDelay) AS carrier_minutes,
	SUM(WeatherDelay) AS weather_minutes,
	SUM(NASDelay) AS  natsys_minutes,
	SUM(SecurityDelay) AS security_minutes,
	SUM(LateAircraftDelay) AS lateplane_minutes,
	SUM(CarrierDelay) + SUM(WeatherDelay) + SUM(NASDelay) + SUM(SecurityDelay) + SUM(LateAircraftDelay) AS total_delay_minutes
FROM flights
)
SELECT 
	ROUND(100.0 * carrier_minutes / total_delay_minutes, 2) AS carrier_percent_of_delay,
	ROUND(100.0 * weather_minutes / total_delay_minutes, 2) AS weather_percent_of_delay,
	ROUND(100.0 * natsys_minutes / total_delay_minutes, 2) AS natsys_percent_of_delay,
	ROUND(100.0 * security_minutes / total_delay_minutes, 2) AS security_percent_of_delay,
	ROUND(100.0 * lateplane_minutes / total_delay_minutes, 2) AS lateplane_percent_of_delay
FROM FlightDelays;
	

-- ------------------------------------------------------------------
-- WHEN YOU'RE DONE: add a line to DECISION_LOG.md, or just tell Claude:
--   * Which cause is #1, and its share
--   * Did it surprise you? Why or why not?
-- ------------------------------------------------------------------
