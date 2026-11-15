# Spói: an interactive poster

This is a real R/Leaflet map of the journal-linked observations, not a generated map image. It is a branch preview, not a published weekly entry. Only the decorative bird is AI-generated; [its prompt and provenance](../illustrations/README.md) are retained.

## Reproduce from Git

The committed data artifact is [`../../data/spoi/spoi.sqlite`](../../data/spoi/spoi.sqlite). Raw ZIP/CSV downloads and installed R libraries are excluded from Git. The database includes the unmodified source fields, parsed observations, all quality flags, environmental observations, source checksums and the public-domain Natural Earth land geometry used by the static export. The interactive poster uses ready-made OpenTopoMap raster tiles below the bird tracks. Its HTML embeds the code, illustration and observations; the basemap tiles need internet, but no database or R server is needed.

From the repository root, with Python 3.12+ and R 4.5+:

```r
install.packages(c("leaflet", "htmlwidgets", "htmltools", "jsonlite", "sf", "DBI", "RSQLite", "png", "base64enc", "ggplot2", "ragg", "boot", "terra", "systemfonts"), repos = "https://cloud.r-project.org")
```

Install Quarto (which provides Pandoc) or make Pandoc available to R, then run:

```sh
Rscript research/spoi/build.R
python -m http.server 8875 --bind 127.0.0.1 --directory previews/spoi
```

Open <http://127.0.0.1:8875/>. The outputs are `previews/spoi/index.html` (interactive poster), `previews/spoi/poster.png` (1200 × 1800, matching the reference composition) and `previews/spoi/poster-linkedin.png` (1200 × 1500, teal side margins preserve the poster proportions). The static poster is designed in R/ggplot2/grid with solid/dashed seasonal summaries and bootstrap shading. Open `Open spoi poster.cmd` on Windows to launch the prepared preview. The static PNG summarizes the seasonal location corridors of all birds; it does not capture the current browser selection. Recorded package versions and R/GDAL/GEOS/PROJ details are alongside this README. All typography is Jost, using the bundled OFL fonts in `styles/fonts/`; no system-font substitution or external font request is needed.

For a fast interaction/style rebuild without regenerating the static PNG: `Rscript research/spoi/build.R --html-only`. OpenTopoMap is a modern topographic basemap, not a historical map scan. OpenTopoMap/OpenStreetMap attribution remains visible. The static PNG retains its reproducible Natural Earth background.

For the designed static poster alone: `Rscript research/spoi/poster.R`. This also writes the derived estimates and full method to SQLite (`corridor_estimates`, `corridor_curves`, `corridor_bird_bins`, `corridor_cycle_bins`, `analysis_methods`) and exports human-readable CSV/JSON alongside the R source.

The reference-matched design uses a 15-degree oblique Mercator view, 1:50m Natural Earth coastlines and real Gray Earth shaded relief. `cartography.R` stores the prepared geography in `poster_geography` and a compressed projected relief GeoTIFF plus source/checksum/processing metadata in `poster_relief`. A clone of the committed SQLite database needs no new geographic download to reproduce the poster. If rebuilding those caches from scratch, save these original public-domain archives in `data/raw/spoi/` first:

- https://naciscdn.org/naturalearth/50m/physical/ne_50m_land.zip
- https://naciscdn.org/naturalearth/50m/raster/GRAY_50M_SR_W.zip

Reference: `research/spoi-teal-poster.png` is used for composition, not as a geographic background. The R render preserves the newer HIDEF branding, summer title and Jost typography. The estimated lines/bands are displayed between 11°N and 63.8°N to frame the broad winter/breeding corridor; complete latitude estimates remain in SQLite/CSV. Direction arrows show the seasonal direction. Terrain comes from the real Natural Earth raster, lightened to match the paper-like reference palette.

## Candidate seasonal corridors and their bands

Solid lines summarize the July–September location window; dashed lines summarize April–May. These calendar windows are **not** independently identified migration events. For every 2.5-degree latitude bin, take the median longitude within each bird/cycle, average cycles within a bird, then give birds equal weight. Require at least five contributing birds; the actual data support 7–19 birds per bin. Smooth the bin means with a cubic smoothing spline (`spar = 0.65`) within contiguous supported latitude runs.

Resample bird IDs as clusters 1,000 times (seed 2027), recomputing the means and applying the same smoother to each bootstrap curve. Shading is the pointwise 2.5th–97.5th percentile range of those curves. It describes the **estimated smoothed mean corridor**, not individual route spread, instrument accuracy, a simultaneous confidence region, or the probability that a bird flew through the band. Binning loses temporal order, and stationary/migrating locations can mix; missingness and geolocator errors remain limitations. This is an exploratory visual summary, not a reconstruction of the paper's flight paths or stopover analysis. The un-smoothed bin estimates remain available for audit.

Numbered notes and the 30 autumn / 26 spring migration totals come from the paper. No new layover counts or durations are claimed from this corridor calculation. The bird engraving and small offset coastline shadow are decorative; the terrain itself is real shaded relief. Static poster projection is oblique Mercator, separate from Leaflet's Web Mercator.

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
- Source timezone and coordinate datum are not specified in the table. The source time strings remain intact; an interval midpoint is used for ordering and display. WGS84 is assumed for geographic display; Leaflet uses Web Mercator (EPSG:3857), while the designed static poster uses the oblique Mercator projection specified in `poster.R`. Do not measure migration distance from either graphic.
- The coastline is repaired with planar GEOS and clipped before projection; spherical ring repair changed a continental ring in this environment and is deliberately avoided. The designed static poster uses real Natural Earth Gray Earth shaded relief; the interactive poster uses the default tiled topographic provider.
- Leaflet's raster tile pane stays beneath observed routes and points at z-index 450, with labels at the normal marker level. There is no custom SVG land layer in the interactive poster.

## Sources and credits

Carneiro, C., Gunnarsson, T. G. & Alves, J. A. (2019). *Faster migration in autumn than in spring: seasonal migration patterns and non-breeding distribution of Icelandic whimbrels Numenius phaeopus islandicus*. Journal of Avian Biology, 50(1). [doi:10.1111/jav.01938](https://doi.org/10.1111/jav.01938).

Same authors (2019), corresponding [Dryad dataset](https://doi.org/10.5061/dryad.3kf35s5), CC0-1.0. The usage notes appreciate contact about reuse; no message has been sent on the user's behalf.

Bird background: [BTO BirdFacts](https://www.bto.org/learn/about-birds/birdfacts/whimbrel) and [RSPB/Fuglavernd](https://web-cdn.rspb.org.uk/whats-happening/news/whats-happening-on-the-frontline-to-help-migratory-birds). These are paraphrased and linked, not treated as openly licensed image assets.

Design inspiration: Warren Davison, [Drawn by Flight](https://storymaps.esri.com/stories/storyscape-resources/30-day-map-challenge/map2.png). The osprey poster is a visual reference, not included in the prepared poster. Bird illustration: AI-generated flight interpretation after Nozeman & Sepp, *Nederlandsche vogelen*, plate 156, public-domain source from Koninklijke Bibliotheek via Wikimedia Commons. Exact generation model identifier unavailable; full prompt is recorded.

## Verification

```sh
python -m unittest discover -s tests -p test_spoi_db.py
node --test tests/spoi-poster.test.cjs
Rscript tests/test_spoi_corridors.R
Rscript research/spoi/build.R
quarto render
```

Quarto excludes `previews/` and `.R-library/`; its public site render remains independent of R execution and SQLite. Browser checks cover individual highlighting, month/cycle filters, playback, reset and a narrow phone viewport. No main-branch push is part of this work.
