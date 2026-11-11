# Decision Log: The 7 a.m. Domino

One entry per judgment call. Format: **what I decided**, **why**, **what I gave up**. The goal: be able to explain any choice here without opening the files.

---

## D1. Dataset: BTS on-time data (Nov 6, 2026)
- **Decided:** U.S. government flight records, not a Kaggle dataset.
- **Why:** It's real, required by federal rule, and has the two fields this question needs: tail number (to follow a plane) and "late-arriving aircraft" delay minutes.
- **Considered and passed on:** Citi Bike (no public cost per truck move, so the $ figure would be guesswork), Uber/Lyft trip records (very large files, and the topic is tied up in a labor-politics debate), Amazon reviews (a review isn't a return, and sorting text is fuzzy), Olist (overused), Steam (keep the portfolio out of games).

## D2. Time window: July 2026 (Nov 6, 2026)
- **Decided:** One month, July 2026.
- **Why:** Peak travel plus summer storms means the most knock-on delays to study. One month (~632K flights) is enough to measure, and small enough to run in a SQLite viewer.
- **Gave up:** Year-round picture. Possible upgrade: rerun the same SQL on a winter month and compare.

## D3. Columns kept: 38 of 110 (Nov 6, 2026)
- **Decided:** Dropped the Div1 to Div5 diversion-detail columns and redundant geography/ID codes.
- **Why:** Smaller, faster database. Nothing in the question needs diversion routing.
- **Gave up:** Diversion deep-dives (can re-add from the original zip).

## D4. Consider cancelled or diverted flights? (Nov 6, 2026)
- **Decided:** Dropped cancelled, diverted, and flights with NULL tail number.
- **Why:** Want clean data with flights that left and arrived at their originally scheduled locations, even if the time differed.
- **Gave up:** Cancellations are part of the damage a delay chain can cause, and this analysis doesn’t count them.

## D5. Planes need to fly twice in a day to be counted.
- **Decided:** Dropped planes that only flew once per day.
- **Why:** Wanted clean data with planes that were the first or last, not the first and last flight. 
    On a one-flight day, the first flight is also the last, so there’s no later flight to pass a delay to. Including those days would compare a flight with itself.
- **Gave up:** Potential data points - About 10,000 one-flight plane days.

## D6. Excluding airplane swaps
- **Decided:** exclude negative scheduled turns (2,108 late-arrival turns).
- **Why:** the next flight was scheduled to leave before this plane was scheduled to land, which points to an aircraft swap, so it doesn’t measure a planned buffer.
- **Gave up:** swaps are themselves a way airlines fight delays; that’s worth noting as a caveat.

## D7. Turning minutes into dollars (Nov 10, 2026)
- **Decided:** Convert minutes added on the ground into dollars at $100.76 per minute, and call the result money "at stake" (not "saved" or "cost").
- **Why:** $100.76 is Airlines for America's 2024 average direct cost of aircraft block time (taxi plus airborne). It's the most widely quoted public per-minute figure, and it comes from the industry, not from me. Source: https://airlines.org/dataset/u-s-passenger-carrier-delay-costs/
- **Gave up:** Precision. Our minutes are added at the gate, not in taxi or flight, so less fuel is burned (crew and aircraft ownership costs still run). A4A is a trade group with a reason to make delays look expensive. A buffer also wouldn't win back every minute. So $74M is the size of the problem in July, not an exact bill or a guaranteed saving.

## D8. Which airports go on the scatter
- **Decided:** Only airports with 100 or more tight late turns (111 of 334 airports).
- **Why:** At an airport with a handful of tight late turns, one bad afternoon can produce an extreme average. The cutoff keeps the per-turn averages meaningful.
- **Gave up:** The other 223 airports. Together they hold about 11% of the minutes added (5,679 turns), so they stay in the national total but not on the chart.
---

## Recommendation (draft)
- Some airports are bottlenecks for late planes on tight turns. That supports adding turn buffer selectively at the worst offenders, not everywhere.
- Start where an airport ranks high on BOTH total minutes added and average minutes added per turn (ATL first). A high total with a mild average (DEN) points to volume, not a turnaround problem.
- Blanket buffers cost aircraft time: a plane at the gate isn't flying paying passengers.

## Open decisions (yours to make as we go)
- [*] **Cancelled and diverted flights:** Exclude them.
- [*] **What counts as "the first flight of the day"?** Earliest scheduled departure per tail per date.
- [*] **What counts as "late"?** 15-minutes or more
- [*] **How to turn minutes into dollars,** and how to word the caveat honestly.

## Findings
- 41.8% of delay minutes (among flights arriving 15+ min late) are due to late planes
- 30.9% of late start planes are 60+ mins late vs 17.8% for on time planes
- 30% of late start planes recover and actually land early
- While time can be made up in both the air or on the ground, delays snowball on the ground more.
- When a plane arrives late with less than an hour of turn, its next flight leaves late about 90% of the time.
- Late planes on tight turns (under 60 min) added 734,024 delay minutes in July, about $74 million at stake (see D7). ATL is the worst offender at $3.24 million.