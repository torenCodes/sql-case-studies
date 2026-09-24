# SQL Case Studies

Small, self-contained analyses by **Toren Lehrmann**. Each one starts from a business
question someone non-technical might actually ask, answers it in SQL, and presents the
result as a Power BI report.

The emphasis is not query syntax. It is the work around the query: choosing what to
measure, deciding what the data can't tell you, and landing on a single defensible answer.

Written up for a general audience at
**[databytoren.com/projects/sql-case-study.html](https://databytoren.com/projects/sql-case-study.html)**.

---

## Projects

### [01 — Video Game Sales](01-video-game-sales/)

*Which genres, ratings, and titles actually drive video game sales?*

Three questions against 16,719 titles released between 1980 and 2017:

| Question | Answer |
|---|---|
| Which genre is most popular in each region? | Action, in every region except Japan, which prefers Role-Playing |
| How do sales relate to critic score? | Titles rated 90 or above average more than twice the sales of the next tier, and the decline is steady from there |
| Which standalone titles compete with franchises? | Exactly one — Wii Sports |

SQLite · DB Browser for SQLite · Power BI · [read the full write-up](01-video-game-sales/)

### [02 — University Major Payoff](02-university-major-payoff/)

*Which college majors actually pay for themselves?*

Three questions against 30,000 synthetic graduates across 19 majors, calibrated to
published ROI research:

| Question | Answer |
|---|---|
| Which major has the best ROI? | Electrical engineering, at 759% and about $105,000 a year; only humanities and fine arts come out negative |
| How much do internships and finishing on time matter? | They raise the return in all 19 majors, and near the bottom of the table they decide whether a degree pays at all |
| Which degrees pay for themselves fastest? | The ones that pay the most: cost barely varies by major, so salary sets the payback order |

SQLite · DB Browser for SQLite · Power BI · [read the full write-up](02-university-major-payoff/)

---

## How to run these yourself

Every project ships the SQLite database it was built against, so the queries are
reproducible without downloading anything:

```bash
sqlite3 01-video-game-sales/data/vgsales.db < 01-video-game-sales/queries/01-top-genre-per-region.sql
```

Or open the `.db` in [DB Browser for SQLite](https://sqlitebrowser.org/) and paste a
query in. The `.pbix` files open in Power BI Desktop; each project also has a PDF export
of its dashboard for anyone who doesn't.

## A note on the data

These use public datasets, credited in each project's README. The analysis, the SQL, and
the report design are mine; the raw data is not, and is included only so the queries can
be re-run.
