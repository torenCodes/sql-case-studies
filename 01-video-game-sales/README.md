# 01 — Video Game Sales

**Which genres, ratings, and titles actually drive video game sales?**

A publisher's planning team asks a version of this before greenlighting anything: where
does each genre sell, does a strong review actually translate into copies, and is a brand
new title ever worth as much as another entry in a series that already sells?

The dataset is a public Kaggle set of video game titles with genre, platform, critic and
user scores, and unit sales broken out by region. **16,719 titles released between 1980
and 2017.**

Source: [Video Game Sales with Ratings](https://www.kaggle.com/datasets/rush4ratio/video-game-sales-with-ratings)
(Kaggle, `rush4ratio`) — loaded into SQLite as `data/vgsales.db`, table `games`.

---

## What it showed

### Which genre is the most popular in each region?

Action leads in every region except Japan, which prefers RPGs.

| Region | Top genre | Percent of sales |
|---|---|---|
| Japan | Role-Playing | 27.4% |
| Other | Action | 23.3% |
| Europe | Action | 21.4% |
| North America | Action | 20.0% |

→ [`queries/01-top-genre-per-region.sql`](queries/01-top-genre-per-region.sql)

### How do sales relate to critic score, and by how much?

Titles rated "Great", a critic score of 90 or above, sell best, averaging more than twice
as many copies as "Good" titles. From there the decline is steady: the lower the rating,
the lower the sales.

One caveat worth stating up front: **51% of titles in the dataset have no critic score at
all**, including many early NES classics. Those are excluded rather than counted as zero,
so this describes the rated half of the catalogue.

→ [`queries/02-critic-score-vs-sales.sql`](queries/02-critic-score-vs-sales.sql)

### Which standalone titles compete with or outperform franchises?

Only one. Wii Sports, still a standalone title when the data was published, is the only
non-franchise game whose sales compete with series like Call of Duty and Grand Theft Auto:
it sold about a third as much as every Call of Duty title combined, and about 18% more than
the entire Final Fantasy franchise.

The interesting part is the method rather than the answer. There is no "franchise" column
in the data, so the query builds one: strip anything after a colon, trim trailing Roman
numerals and digits, and count distinct titles that collapse onto the same base name.

→ [`queries/03-standalone-vs-franchise.sql`](queries/03-standalone-vs-franchise.sql)

---

## What's in here

```
01-video-game-sales/
├── queries/
│   ├── 01-top-genre-per-region.sql      the three dashboard queries,
│   ├── 02-critic-score-vs-sales.sql       one per question above
│   ├── 03-standalone-vs-franchise.sql
│   └── query-log.sql                     the full working log, warm-ups included
├── data/
│   ├── vgsales.db                        SQLite, table `games`, 16,719 rows
│   └── *.csv                             the three query results, as fed to Power BI
└── report/
    ├── video-game-sales.pbix             the Power BI report
    └── video-game-sales-dashboard.pdf    a PDF export, for anyone without Power BI
```

`query-log.sql` is kept deliberately. It is the actual working file — warm-up queries,
aggregates, CTE practice — and it shows how the three final queries were arrived at
rather than presenting them as though they arrived finished.

## Tools

SQLite · [DB Browser for SQLite](https://sqlitebrowser.org/) · Power BI Desktop
