# Official map collection catalogue

This tracks **every entry** in the official [30DayMapChallenge collection directory](https://30daymapchallenge.com/galleries/) at the source revision recorded in `source.json`.

| Year | Listings |
|---|---:|
| 2019 | 12 |
| 2020 | 21 |
| 2021 | 61 |
| 2022 | 58 |
| 2023 | 21 |
| 2024 | 21 |
| 2025 | 29 |
| Total | 223 |

There are **222 distinct collection URLs** and **183 distinct creator labels**. Creator labels are retained exactly, not reconciled identities. One URL is listed in two years; the private review tool shows that collection once, with both years. Different pages from the same creator remain separate. The snapshot has no 2026 collection section.

`collections.sqlite` has `source`, `collections`, and `listings` tables, plus `collection_tracker` and `yearly_counts` views. `collection_tracker.csv` and `collections.json` provide portable exports. The original YAML and MIT licence are in `sources/`, with the commit, retrieval date and SHA-256 checksum in `source.json`.

“Not reviewed” describes the starting state of the user's personal reviews. Inclusion in the official directory is not a quality rating or proof that a destination still works. Two source pages were inspected during discovery: Jyoti's 2025 page (17 map references with LinkedIn links) and Jere's 2025 page (five completed entries). That source inspection does not supply personal opinions on their work. No participation totals, dates, likes, or share counts are inferred from a collection listing.

## Personal reviews

Double-click **Open map reviews.cmd** in the project root. It starts or reuses a server bound only to `127.0.0.1:8874` and opens the private browser tool. The tool has no external dependencies and makes no background calls to the creators' sites. The source links open only when chosen.

For each collection, record **Positive / Neutral / Negative** and a freeform explanation. Optional feature tags, a specific map URL, and an idea for your own map can help turn opinions into an inspiration brief. All 222 collections begin without personal opinions.

Reviews save in browser local storage, **not in this database or the public website**. Use the same browser and address each time; browser data is device-specific and can be cleared. Use **Export review backup** regularly. Import validates the backup and keeps the newer review for each collection. Unknown collection IDs are rejected rather than silently discarded.

**Export design brief** makes a Markdown summary of positive examples, recurring feature tags, ideas, sources, and neutral/negative counterexamples. Share an exported backup or brief in the chat when ready to use those preferences for future maps. Exports are not uploaded automatically. Files matching the export naming patterns and the local `review-data/` directory are ignored by Git. The app itself is excluded from Quarto publication.

## Reproduce the catalogue

Python 3.10+ and PyYAML 6.x are required (PyYAML was already installed on this machine):

```powershell
python -m pip install -r scripts/requirements-community.txt
python scripts/build_collection_tracker.py
python -m unittest discover -s tests -v
node --test tests/collection_review.test.cjs
```

The builder verifies the source checksum, imports every listing without synthesising descriptions, creates the SQLite/CSV/JSON catalogue, and updates the browser's local `catalog.js`. It does not read, change, or publish personal reviews. The exact URL determines each stable review ID.
