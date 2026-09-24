# 02 — University Major Payoff

**Which college majors actually pay for themselves?**

The questions a student and their family weigh before choosing a major: which degrees pay
off, how much the effort around the degree matters, and how quickly each one pays for
itself.

Source: [College Major ROI](https://www.kaggle.com/datasets/sergionefedov/college-major-roi)
(Kaggle, `sergionefedov`, CC0) — **30,000 graduates across 19 majors**, each with the net
cost of their degree, the debt they took on, ten years of earnings, and whether they
interned and finished on time. Loaded into SQLite as `data/univ_major_payoff.db`, table
`majors`.

> **The data is synthetic.** The records are generated rather than drawn from real
> students, calibrated to published ROI research from Georgetown's Center on Education and
> the Workforce, FREOPP, and the College Scorecard. The findings below describe the
> patterns that research reports, not new evidence about real graduates.

---

## What it showed

### Which major has the best return on investment?

Electrical engineering, with the highest average salary in the set — about $105,000 a year
across the first ten years — and a return of 759% on the cost of the degree. Engineering,
computer science, and business analytics hold the top of the table, and only two majors
come out negative on average: humanities (−7%) and fine arts (−40%).

→ [`queries/01-roi-by-major.sql`](queries/01-roi-by-major.sql)

### How much do internships and finishing on time change the return?

Graduates who did both — the High Achievers — earned a higher return than those who did
neither — the Minimalists — in all 19 majors. The gap matters most at the bottom of the
table, where it decides whether a degree pays at all: Criminal Justice minimalists roughly
broke even, at about $1,600 over ten years, while high achievers in the same major
returned over $62,000. Fine arts is the one major the extra effort can't rescue, still
about −$28,000 at best, even though it costs only a few thousand dollars less than an
electrical engineering degree.

One caution: the dataset was generated with internships and on-time completion already
raising earnings and lowering cost, so the effect itself is an input rather than a
discovery. What the analysis adds is *where* it is decisive. Near the top of the table it
adds to a return that was already large; near the bottom it decides whether the degree
pays for itself at all.

→ [`queries/02-high-achiever-vs-minimalist.sql`](queries/02-high-achiever-vs-minimalist.sql)

### Which degrees pay for themselves fastest?

The ones that pay the most. Average cost barely moves from one major to the next, so how
quickly a degree earns back what it cost is set almost entirely by salary. The payback
order follows the salary table almost exactly: electrical engineering fastest, fine arts
slowest. An electrical engineering degree costs less than one year of its graduates'
average salary; a fine arts degree costs more than two.

→ [`queries/03-payback-by-major.sql`](queries/03-payback-by-major.sql)

---

## What's in here

```
02-university-major-payoff/
├── queries/
│   ├── 01-roi-by-major.sql                 the three dashboard queries,
│   ├── 02-high-achiever-vs-minimalist.sql    one per question above
│   ├── 03-payback-by-major.sql
│   └── query-log.sql                        the full working log
├── data/
│   ├── univ_major_payoff.db                 SQLite, table `majors`, 30,000 rows
│   └── *.csv                                the three query results, as fed to Power BI
└── report/
    ├── university-major-payoff.pbix         the Power BI report
    └── university-major-payoff-dashboard.pdf
```

## Tools

SQLite · [DB Browser for SQLite](https://sqlitebrowser.org/) · Power BI Desktop
