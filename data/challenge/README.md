# Historical 30DayMapChallenge prompts

Open `30daymapchallenge.sqlite` in any SQLite client. It is about 88 KiB and needs no server or extensions. This is a small reference database alongside the project's spatial workflow; PostGIS remains the shared spatial analysis database.

## Scope and provenance

The database contains all **240 announced daily prompts from 2019–2026**, taken from the [official repository](https://github.com/tjukanovt/30DayMapChallenge) at commit `aaf2e251d929cc61cc8d5620a4b749f304f5b67a`. Each year has exactly 30 records. Original titles, descriptions (Markdown), source line numbers, source URLs, retrieval timestamps, and snapshot SHA-256 checksums are retained. The source tables and their MIT licence are in `sources/`; `sources.json` records their provenance.

The snapshot date is **14 November 2026**. The 2026 edition is ongoing: all 30 announced prompts are included, including the 16 dates still ahead. `past_edition_theme_frequency` counts only 2019–2025; `prompt_details.schedule_status` distinguishes upcoming dates. A date having been reached does not mean a map was submitted.

This describes **prompts, not participant entries, popularity, or actual mapping activity**.

## Exact repeats versus grouped themes

There are **158 distinct exact titles**, of which **32 recur in more than one year**. Exact matching preserves spelling, case, punctuation, and prefixes.

`taxonomy.json` maps those titles into **132 grouped themes**, of which **39 recur across years**. Groupings and categories are editorial additions for this atlas, not official challenge classifications. Each alias has an explicit rationale. For example:

- `Data challenge 1: OpenStreetMap`, `Data: OpenStreetMap`, and `OpenStreetMap` share a theme.
- `A new tool`, `Map with a new tool`, and `New tool` share a theme.
- Analog/manual variants share a theme, while their exact wording remains available.
- Five-minute and ten-minute challenges share the **Timed mapping** theme (2022, 2023, 2025, 2026). Their original titles and descriptions preserve the precise time limit.
- Monochrome and Black & white, Points and Dot, and Historical map and Vintage style remain separate.

Each grouped theme receives **one primary category**. Prompts often span multiple ideas, so these totals are a simple lens rather than an exhaustive tagging system. Edit the taxonomy and rebuild to revise them.

| Primary category | Prompt occurrences |
|---|---:|
| Geometry and data models | 44 |
| Society and culture | 36 |
| Geography and environment | 34 |
| Concepts and storytelling | 32 |
| Colour and visual style | 30 |
| Cartographic methods | 24 |
| Tools and working process | 21 |
| Data sources | 19 |

Across all eight editions, **Points, Lines, Polygons, Hexagons, and Raster each occur eight times**. Grouped Analog mapping and OpenStreetMap each occur in six years; 3D and New tool each occur in five.

## Tables and views

| Object | Purpose |
|---|---|
| `sources` | One pinned, checksummed source per year |
| `prompts` | Original year/day/title/description and source line |
| `aliases` | Original titles, grouped theme links, and grouping rationales |
| `themes`, `categories` | Editorial theme names and primary categories |
| `metadata` | Snapshot date, taxonomy version, scope |
| `prompt_details` | Joined records, source links, edition and schedule status |
| `exact_repeats` | Repeated original titles, without semantic merging |
| `theme_frequency`, `repeated_themes` | Grouped frequency, years, first/last occurrence |
| `category_frequency`, `category_by_year` | Category totals and yearly mix |
| `past_edition_theme_frequency` | Grouped frequencies excluding ongoing 2026 |

```sql
SELECT theme, year_count, years
FROM repeated_themes
ORDER BY year_count DESC, theme;

SELECT year, day, original_title, grouping_rationale, source_line_url
FROM prompt_details
WHERE theme = 'OpenStreetMap'
ORDER BY year, day;
```

More examples are in `queries.sql`. Counts are prompt occurrences and distinct years, not an estimate of how many maps were made. Original theme `NULL` is literal text, not a missing title. No descriptions were invented for the 2019 table, which contains titles only.

## Rebuild and verify

From the repository root, using Python 3.10 or newer and its standard library only:

```powershell
python scripts/build_challenge_db.py
python -m unittest discover -s tests -v
```

The builder operates offline, checks source hashes and complete day sequences, rejects missing classifications, checks foreign keys and SQLite integrity, then replaces the database. It also exports `prompt_details.csv`, `theme_frequency.csv`, and `category_frequency.csv` next to the database. The CSVs offer an easy way to inspect the same data in a spreadsheet or R.

To update the history, add reviewed official source snapshots and provenance, extend the taxonomy, and update the builder's edition range and snapshot date. Do not infer prompt lists from participant galleries.
