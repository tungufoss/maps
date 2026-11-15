# Interactive spói poster

Goal: build a real reproducible R/Leaflet poster from the journal-linked Dryad data, with SQLite as the committed data artifact.

Architecture: Python's standard library imports both source tables into SQLite, checks publisher MD5s, preserves source rows, and records explicit quality flags. R reads SQLite, draws a tile-free Natural Earth basemap, creates a Leaflet HTML widget and a static PNG from the same accepted observations. Small browser-side controls select birds, annual cycles, calendar windows and elapsed observations; no R or database server is needed to view the prepared HTML.

Files: `scripts/build_spoi_db.py`, `tests/test_spoi_db.py`, `data/spoi/spoi.sqlite`, `data/spoi/source.json`, `research/spoi/build.R`, `research/spoi/poster.css`, `research/spoi/poster.js`, `research/spoi/README.md`, `previews/spoi/index.html`, `previews/spoi/poster.png`, `.gitignore`, `.quartoignore`. Existing generated illustrations are decorative only. No weekly slot assigned; no public atlas entry or main-branch change.

Sequential tasks:

1. Completed: tested and built the validated SQLite import, retaining all rows and source checksums. Integrity and foreign keys pass; both source MD5s match.
2. Completed: generated the real R Leaflet poster, bird/year/month controls and static PNG. Four executable checks cover masked gaps, long gaps/cycles and calendar filtering. Browser selection highlights GL-YL (486 estimates in the full display); a 2014–2015 April–May filter highlights 91 of its estimates.
3. Completed: 13 Python tests and four poster JavaScript tests pass; R generates standalone HTML and a 1200 × 1500 PNG. Browser playback and reset verified, and phone-width inspection showed no horizontal overflow. Quarto renders successfully, with only the expected empty-atlas listing warning; development previews and local R libraries are excluded. Prepared artifacts are ready for the feature-branch commit.

User supplied the original Dryad ZIP after automated download encountered browser verification. Source archive files are kept out of Git; SQLite and its provenance are committed. Incomplete or uncertain observations are not silently interpolated or converted to precise GPS tracks.

15 November design revision: the interactive background now uses public OpenTopoMap raster tiles, with observations above the tile pane; tiles require internet. The static poster is designed in `poster.R` using ggplot2/ragg, the decorative bird, numbered narrative and solid/dashed candidate seasonal mean corridors. Bird-cluster bootstrap curves receive the same smoothing as the central estimate; source observations remain unchanged. The generated analysis tables and method are saved in SQLite. The gganimate export and a reproduced stopover/event analysis remain future extensions.
