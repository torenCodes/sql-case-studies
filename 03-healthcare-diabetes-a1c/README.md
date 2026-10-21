# 03 — Diabetes Care Scorecard

**Among adults aged 18 to 75 with diabetes, who received an A1c test in 2021, and where
are the gaps?**

Health plans track a simple quality measure for adults with diabetes: did they have an A1c
test during the year? A1c is a blood test that reflects average blood sugar over the past
few months, and the patients who miss it are the ones worth a follow-up call. This project
defines who counts, measures how many were tested, and turns the gap into a list someone
could act on.

**Live dashboard:** [Diabetes Care Scorecard, 2021 on Tableau Public](https://public.tableau.com/app/profile/toren.lehrmann/viz/Healthcare-SyntheticDiabetesAnalysis/DiabetesCareScorecard)
· Write-up: [databytoren.com](https://databytoren.com/projects/diabetes-care-scorecard.html)

> **The data is synthetic.** It is Synthea's sample data: 1,163 simulated Massachusetts
> patients, with no real person behind any record. This is a learning project, and it
> claims no healthcare experience.

---

## The measure

| | Definition |
|---|---|
| Measurement year | 2021, the last year in the data (it ends in November 2021) |
| Eligible (denominator) | A condition recorded as exactly `Diabetes` (not prediabetes) starting on or before 2021-12-31; aged 18 to 75 on 2021-12-31; not deceased before 2021-01-01 |
| Tested (numerator) | At least one A1c result, observation code `4548-4` (LOINC), dated in 2021 |

It is a care-process measure (was the test done), not a control measure (was the result
good).

## What it showed

| | Result |
|---|---|
| Diagnosed with Diabetes | 73 patients |
| Eligible | 47 |
| Tested in 2021 | 40 — **85.1%** |
| Not tested | 7, each with an A1c in 2019 or 2020 but none in 2021 |
| Latest 2021 A1c at or above 7% | 4 of the 40 tested |

By age group: 6 of 10 aged 18–44 were tested (60%), 28 of 31 aged 45–64 (90.3%), and 6 of 6
aged 65–75. Younger patients were tested less, but with groups this small that is a
direction to look into, not a conclusion.

By county (eligible / tested): Middlesex 13 / 11, Worcester 6 / 6, Suffolk 6 / 5,
Norfolk 5 / 4, Essex 5 / 3, Plymouth 3 / 3, Bristol 3 / 3, Barnstable 3 / 2, Hampden 2 / 2,
Franklin 1 / 1.

## Where the data changed the plan

- **"Poor control" (A1c over 9%) returned 0 of 40**, so the dashboard reports "at or above
  7%" instead.
- **Provider comparison wasn't viable.** The 47 eligible patients were seen across more than
  40 organizations, so most provider groups held one or two patients. County is the
  grouping used instead.

## Data quirks worth knowing

- Of 4,780 A1c readings in the whole dataset, 1,197 are under 4%, which is implausibly low;
  10 of the 40 tested patients have a latest 2021 result in that range.
- `observations.VALUE` is stored as text and has to be cast before comparing.
- Dates are plain dates in `conditions` but ISO timestamps in `observations`, so the 2021
  window is written as `DATE >= '2021-01-01' AND DATE < '2022-01-01'`.

---

## What's in here

```
03-healthcare-diabetes-a1c/
├── queries/
│   ├── 01_diabetes_patients.sql          basic join: 73 diagnosed patients
│   ├── 02_testing_rate_measure.sql       the headline measure: 47 / 40 / 85.1%
│   ├── 03_not_tested_call_list.sql       anti-join: the 7 not tested
│   ├── 04_a1c_distribution.sql           latest result per patient, bucketed
│   ├── 05_testing_rate_by_county.sql     the grouping used on the map
│   ├── 06_dashboard_export.sql           one row per eligible patient, feeds Tableau
│   └── query-log.sql                     the full working log
└── data/
    └── diabetes_a1c_2021_patients.csv    the export from query 06 (47 rows)
```

Each query file opens with what it does and the result it should return.

**No database is included.** The SQLite file built from Synthea is about 196 MB, over
GitHub's file limit, and the source data is freely available. To reproduce:

1. Download the Synthea sample CSV data, **November 2021 release**, from
   [synthetichealth.github.io/downloads](https://synthetichealth.github.io/downloads.html).
2. Load these 12 tables into SQLite: `patients`, `conditions`, `observations`,
   `encounters`, `providers`, `organizations`, `medications`, `procedures`,
   `immunizations`, `allergies`, `careplans`, `payers`. (The large `claims`,
   `claims_transactions`, `imaging_studies` and `payer_transitions` tables aren't needed.)
3. Run the queries in order; each one states its expected result.

## How I worked

I used Claude throughout, as a tutor and a second pair of hands: explaining SQL patterns,
drafting queries, and walking me through Tableau. My Windows machine's application control
policy blocked my Python install, so Claude built the SQLite database from the CSV files. I
ran every query myself in a SQLite viewer and checked as I went: row counts after every
join, totals reconciled from 73 diagnosed to 47 eligible to 40 tested, and every number on
the dashboard reproduced from the SQL.

## Next steps

- Rerun on a larger Synthea dataset, where providers have enough patients for a comparison
  to mean something. The SQL should run unchanged.
- Add a Python step: a cleaning notebook with before and after, and a significance test on
  the age-group gap (with groups this small, Fisher's exact test rather than chi-square).

## Data source and license

Synthea™ synthetic patient data, made available by The MITRE Corporation. Per Synthea, the
data "is free from cost, privacy, and security restrictions" and can be used without
restriction. Synthea's software is licensed under the Apache License 2.0. Citation:

> Jason Walonoski, Mark Kramer, Joseph Nichols, Andre Quina, Chris Moesel, Dylan Hall,
> Carlton Duffett, Kudakwashe Dube, Thomas Gallagher, Scott McLachlan. *Synthea: An
> approach, method, and software mechanism for generating synthetic patients and the
> synthetic electronic health care record.* Journal of the American Medical Informatics
> Association, Volume 25, Issue 3, March 2018, Pages 230–238.
> https://doi.org/10.1093/jamia/ocx079

## Tools

SQLite · DB Browser for SQLite · Tableau Public
