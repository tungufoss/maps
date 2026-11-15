# Spói: an interactive poster

This is a real R/Leaflet map of the journal-linked observations, not a generated map image. It is a branch preview, not a published weekly entry. Only the decorative bird is AI-generated; [its prompt and provenance](../illustrations/README.md) are retained.

## Reproduce from Git

The committed data artifact is [`../../data/spoi/spoi.sqlite`](../../data/spoi/spoi.sqlite). Raw ZIP/CSV downloads and installed R libraries are excluded from Git. The database includes the unmodified source fields, parsed observations, all quality flags, environmental observations, source checksums and the public-domain Natural Earth land geometry. The standalone HTML embeds its JavaScript, illustration, basemap and observations; viewing it needs neither internet nor a database server.

From the repository root, with Python 3.12+ and R 4.5+:

```r
install.packages(c("leaflet", "htmlwidgets", "htmltools", "jsonlite", "sf", "DBI", "RSQLite", "png", "base64enc"), repos = "https://cloud.r-project.org")
```

Install Quarto (which provides Pandoc) or make Pandoc available to R, then run:

```sh
Rscript research/spoi/build.R
python -m http.server 8875 --bind 127.0.0.1 --directory previews/spoi
```

Open <http://127.0.0.1:8875/>. The outputs are `previews/spoi/index.html` (standalone interactive poster) and `previews/spoi/poster.png` (1200 × 1500, drawn in R from the same display mask). Open `Open spoi poster.cmd` on Windows to launch the prepared preview. The static PNG shows all birds; it does not capture the current browser selection. Recorded package versions and R/GDAL/GEOS/PROJ details are alongside this README.

## Rebuild the data import

Obtain the original ZIP from [Dryad](https://datadryad.org/dataset/doi:10.5061/dryad.3kf35s5), linked in the [paper](https://doi.org/10.1111/jav.01938). Save its two files unchanged in `data/raw/spoi/`. Although their suffix is `.csv`, these are R-style whitespace-delimited tables with quoted fields and row names. The importer checks the publisher's MD5s and handles the occasional decimal comma in the environmental source while retaining the original text.

```sh
python scripts/build_spoi_db.py
```

This rebuilds the source and observation tables. To regenerate the basemap cache too, obtain <https://naciscdn.org/naturalearth/110m/physical/ne_110m_land.zip> and save it to `data/raw/spoi/ne_110m_land.zip`; `build.R` records its checksum and adds its geometry to SQLite. Subsequent R builds use that committed cache. Natural Earth is [public domain](https://www.naturalearthdata.com/about/terms-of-use/).

## Quality and interpretation

- Both Dryad MD5 checks match. There are **19 birds, 19,981 position rows and 67,393 environmental rows**. No source row is discarded from SQLite.
- There are **657 missing latitudes (3.3%)** and **57 reversed twilight intervals**. Temperature minima have 5,796 missing records; maxima have 5,621. No wet-contact or conductivity values are missing. These are file-level audits, not counts reported by the paper.
- The display masks missing/invalid coordinates, reversed intervals, estimates outside 0–75°N / 50°W–20°E and equinox windows approximated by ±20 days around March 20 and September 22. **14,074 positions remain**. These are conservative editorial display flags, not validated scientific outlier classifications; flags overlap.
- A masked row breaks its line. Gaps longer than 36 hours, different birds and different July–June cycles never connect. No missing values are imputed, and no flight positions are interpolated. Bird selection highlights one individual over the others; cycle and month filters retain genuine observations. Playback reveals calendar months rather than simulating continuous flight.
- Some first/last annual cycles are partial. A cycle label does not guarantee a complete migration. The application does not calculate departure dates, flight speeds or time away from these noisy raw estimates. “About nine months away” interprets typical August/May dates in the paper, not a per-bird result.
- The paper used visual twilight checks, filtering and double smoothing; this exploratory viewer does **not** reproduce that entire analysis. Raw latitude noise remains visible, especially at high latitudes. Do not equate the displayed dashed joins with GPS flight paths.
- Source timezone and coordinate datum are not specified in the table. The source time strings remain intact; an interval midpoint is used for ordering and display. WGS84 is assumed for geographic display, then Leaflet and the static poster use Web Mercator (EPSG:3857). Do not measure migration distance on that projection.
- The coastline is repaired with planar GEOS and clipped before projection; spherical ring repair changed a continental ring in this environment and is deliberately avoided. No elevation raster is used; unlike the initial generated concept, this real basemap does not depict shaded relief.

## Sources and credits

Carneiro, C., Gunnarsson, T. G. & Alves, J. A. (2019). *Faster migration in autumn than in spring: seasonal migration patterns and non-breeding distribution of Icelandic whimbrels Numenius phaeopus islandicus*. Journal of Avian Biology, 50(1). [doi:10.1111/jav.01938](https://doi.org/10.1111/jav.01938).

Same authors (2019), corresponding [Dryad dataset](https://doi.org/10.5061/dryad.3kf35s5), CC0-1.0. The usage notes appreciate contact about reuse; no message has been sent on the user's behalf.

Bird background: [BTO BirdFacts](https://www.bto.org/learn/about-birds/birdfacts/whimbrel) and [RSPB/Fuglavernd](https://web-cdn.rspb.org.uk/whats-happening/news/whats-happening-on-the-frontline-to-help-migratory-birds). These are paraphrased and linked, not treated as openly licensed image assets.

Design inspiration: Warren Davison, [Drawn by Flight](https://storymaps.esri.com/stories/storyscape-resources/30-day-map-challenge/map2.png). The osprey poster is a visual reference, not included in the prepared poster. Bird illustration: AI-generated flight interpretation after Nozeman & Sepp, *Nederlandsche vogelen*, plate 156, public-domain source from Koninklijke Bibliotheek via Wikimedia Commons. Exact generation model identifier unavailable; full prompt is recorded.

## Verification

```sh
python -m unittest discover -s tests -p test_spoi_db.py
node --test tests/spoi-poster.test.cjs
Rscript research/spoi/build.R
quarto render
```

Quarto excludes `previews/` and `.R-library/`; its public site render remains independent of R execution and SQLite. Browser checks cover individual highlighting, month/cycle filters, playback, reset and a narrow phone viewport. No main-branch push is part of this work.
