# 04 — Airline Delays: The 7 a.m. Domino

**Imagine you're an airline executive reviewing schedules. Why are flights late, what is it
costing, and what can we change?**

A plane flies several legs a day. When one leg runs late, the next one can inherit that
lateness, and airlines even report it as its own delay cause, "late-arriving aircraft." This
project follows individual planes through their day by tail number to measure that domino
effect, find where it grows, and put a size on it.

Write-up: [databytoren.com/projects/airline-delays](https://databytoren.com/projects/airline-delays)

> **The data is real.** It is the U.S. Department of Transportation's on-time records for
> July 2026: every domestic flight reported by the major U.S. airlines, with tail numbers
> and delay causes. Public domain.

---

## What it showed

| Question | Answer |
|---|---|
| Why are we late? | **41.8%** of delay minutes, among flights arriving 15+ minutes late, came from a plane that was already late from its previous flight: the largest single cause |
| Does a late start ruin the day? | It makes it worse, not certain. When the first flight left 15+ min late, 30.9% of planes finished the day 1+ hour late, vs 17.8% after an on-time start (**1.7×** as likely). Yet 29.5% of late starters still landed their last flight early |
| Where do delays grow? | On the ground. Plane-days that recovered won back 37 min in the air and 45 on the ground; plane-days that snowballed gained 4 in the air and lost 65 on the ground |
| What decides it? | Scheduled time on the ground. After a 15+ min late arrival, the next flight left late **94.5%** of the time with under 45 minutes between flights, 89.2% with 45 to 59, and about half with 90 or more |
| What is it costing? | Late planes with under an hour on the ground (after a 15+ min late arrival) added **734,024 delay minutes** in July, about **$74M at stake** |
| Where should we act first? | **Atlanta (ATL)**: the most minutes added of any airport (32,110; $3.24M at stake) and the most added per turn (20.4) among the 17 busiest |

**Recommendation:** give late-arriving planes more time on the ground, but only where delays
snowball, starting with Atlanta. Blanket buffers cost flights: a plane sitting at the gate
isn't flying passengers. Denver adds a lot of minutes too, but mostly because it's so busy;
per turn it adds only 9.6.

### About the dollar figure

Minutes are converted at **$100.76 per minute**, Airlines for America's 2024 average direct
cost of aircraft block time (taxi plus airborne)
([source](https://airlines.org/dataset/u-s-passenger-carrier-delay-costs/)). It's a
yardstick, not an exact bill: these minutes are added at the gate, A4A is an industry trade
group, and a buffer wouldn't win back every minute. That's why it is "at stake," not
"lost" or "saved."

---

## How it was built

1. **Load.** `scripts/build_db.py` loads the BTS CSV into SQLite, keeping 38 of its 110
   columns. 631,970 flights; 612,038 remain after removing cancelled, diverted and
   missing-tail flights.
2. **Follow the plane.** Window functions (`ROW_NUMBER`, `LAG`, `COUNT(*) OVER`) put each
   plane's flights in order for the day and carry the previous flight's delay forward.
   A "plane-day" is one tail number on one date with two or more flights: 138,730 of them.
3. **One question per query.** Seven queries, from "what causes the most delay minutes?" to
   "which airports add the most delay on tight turns?"
4. **Checkpoints.** Each query states row counts and totals that had to match before moving
   on, and one plane's turn times were checked by hand (`06b_hand_check.sql`).
5. **Power BI.** Seven small CSV exports feed the Power BI report, exported as images.

Every judgment call, with what it gave up, is in [`DECISION_LOG.md`](DECISION_LOG.md):
the dataset, the month, the columns, the exclusions, one-flight days, aircraft swaps, the
dollar conversion and the scatter cutoff.

The database was built by Claude in a cloud workspace, because Python couldn't run on my
machine at the time. I wrote, ran and checked every query myself in DB Browser for SQLite,
with Claude explaining concepts and setting up the exercises; the query files keep those
prompts, my answers and the checkpoints.

## Caveats

- One month, July 2026, at peak travel season. These are July findings, not a full year.
- Times are local, and legs are ordered by scheduled departure, which can misorder
  red-eyes. As a check, the previous flight's destination matched the next flight's origin
  96.9% of the time.
- The turn-time results show a strong pattern, not proof that more buffer would win back
  every minute; congestion, crews and gates matter too.
- Cancellations and aircraft swaps are left out (see D4 and D6).

---

## What's in here

```
04-airline-delays/
├── DECISION_LOG.md                 every judgment call, D1 to D8
├── queries/
│   ├── 01_delay_causes.sql         delay minutes by cause: 41.8% late-arriving aircraft
│   ├── 02_number_the_legs.sql      ROW_NUMBER / COUNT OVER: each plane's legs in order
│   ├── 03_first_vs_last.sql        first departure vs last arrival, per plane-day
│   ├── 04_how_days_end.sql         how days end after a late vs on-time start (1.7×)
│   ├── 05_where_time_is_won.sql    minutes won or lost in the air vs on the ground
│   ├── 06_turn_time.sql            next flight late, by scheduled time on the ground
│   ├── 06b_hand_check.sql          one plane's turn times, checked by hand
│   └── 07_minutes_at_stake.sql     minutes and dollars at stake, by airport and in total
├── data/                           the 7 CSV exports that feed the report
├── scripts/
│   └── build_db.py                 builds the SQLite database from the BTS CSV
└── report/
    ├── Airline_Delay_Report.pbix   the Power BI report
    ├── databytoren_theme.json      the report theme
    └── frames/                     the five report pages as images, plus the summary preview
```

Each query file opens with its question and ends with its checkpoints and answers.

**No database is included.** The SQLite file is about 120 MB, over GitHub's file limit, and
the source data is free to download. To reproduce:

1. From the [BTS download page](https://www.transtats.bts.gov/DL_SelectFields.aspx?gnoyr_VQ=FGJ&QO_fu146_anzr=b0-gvzr)
   (*Reporting Carrier On-Time Performance, 1987–present*), download the prezipped file for
   **July 2026** and unzip it.
2. Build the database (needs Python with pandas):
   `python scripts/build_db.py <the unzipped CSV> flights_2026_07.db`
3. Open it in DB Browser for SQLite and run the queries in order. The scouting checksum: the
   five delay-cause columns total 13,743,367 minutes.

## Next steps

- Rerun the same SQL on a winter month and compare. The queries should run unchanged.

## Data source and license

U.S. Department of Transportation, Bureau of Transportation Statistics, *Reporting Carrier
On-Time Performance (1987–present)*, July 2026. U.S. government data, public domain. Delay
cost per minute: Airlines for America, *U.S. Passenger Carrier Delay Costs* (2024).

## Tools

SQLite · DB Browser for SQLite · Power BI
