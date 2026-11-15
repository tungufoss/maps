# Whimbrel / Spói: reproducible bilingual posters

This is a real R/Leaflet map of the journal-linked observations, not a generated map image. It is a branch preview, not a published weekly entry. Only the decorative bird is AI-generated; [its prompt and provenance](../illustrations/README.md) are retained.

## Reproduce from Git

The committed data artifact is [`../../data/spoi/spoi.sqlite`](../../data/spoi/spoi.sqlite). Raw ZIP/CSV downloads and installed R libraries are excluded from Git. The database includes the unmodified source fields, parsed observations, all quality flags, environmental observations, source checksums and the public-domain Natural Earth land geometry used by the static export. The interactive poster uses ready-made OpenTopoMap raster tiles below the bird tracks. Its HTML embeds the code, illustration and observations; the basemap tiles need internet, but no database or R server is needed.

From the repository root, with Python 3.12+ and R 4.5+:

```r
install.packages(c("leaflet", "htmlwidgets", "htmltools", "jsonlite", "sf", "DBI", "RSQLite", "png", "base64enc", "ggplot2", "ragg", "boot", "terra", "systemfonts", "isoband"), repos = "https://cloud.r-project.org")
```

Install Quarto (which provides Pandoc) or make Pandoc available to R, then run:

```sh
Rscript research/spoi/build.R
python -m http.server 8875 --bind 127.0.0.1 --directory previews/spoi
```

Open <http://127.0.0.1:8875/>. The outputs are `previews/spoi/index.html` (interactive poster), `previews/spoi/poster.png` (1200 × 1800, matching the reference composition) and `previews/spoi/poster-linkedin.png` (1200 × 1500, teal side margins preserve the poster proportions). The static poster is designed in R/ggplot2/grid with solid/dashed schematic journey lanes and monochrome concentration regions. The same R layout also writes `poster-is.png` and `poster-is-linkedin.png`, with Icelandic text; the default PNGs use the English common name WHIMBREL. Open `Open spoi poster.cmd` on Windows to launch the prepared preview. The static PNG summarizes the study sample; it does not capture the current browser selection. The interactive preview starts with the region/lane summary, then switches to observations when a bird is selected. Annual-cycle and playback controls are disabled in summary view, because the aggregate estimates cover all years. Recorded package versions and R/GDAL/GEOS/PROJ details are alongside this README. All typography is Jost, using the bundled OFL fonts in `styles/fonts/`; no system-font substitution or external font request is needed.

For a fast interaction/style rebuild without regenerating the static PNG: `Rscript research/spoi/build.R --html-only`. OpenTopoMap is a modern topographic basemap, not a historical map scan. OpenTopoMap/OpenStreetMap attribution remains visible. The static PNG retains its reproducible Natural Earth background.

For the designed static poster alone: `Rscript research/spoi/poster.R`. This also writes the derived estimates and full method to SQLite (`corridor_estimates`, `corridor_curves`, `corridor_bird_bins`, `corridor_cycle_bins`, `analysis_methods`) and exports human-readable CSV/JSON alongside the R source.

The reference-matched design uses a 15-degree oblique Mercator view, 1:50m Natural Earth coastlines and real Gray Earth shaded relief. `cartography.R` stores the prepared geography in `poster_geography` and a compressed projected relief GeoTIFF plus source/checksum/processing metadata in `poster_relief`. A clone of the committed SQLite database needs no new geographic download to reproduce the poster. If rebuilding those caches from scratch, save these original public-domain archives in `data/raw/spoi/` first:

- https://naciscdn.org/naturalearth/50m/physical/ne_50m_land.zip
- https://naciscdn.org/naturalearth/50m/raster/GRAY_50M_SR_W.zip

Reference: `research/spoi-teal-poster.png` is used for composition, not as a geographic background. The R render preserves the newer HIDEF branding, summer title and Jost typography. The route lanes join the shared, land-constrained breeding/winter means and candidate stopover means. Their curves are schematic, not estimated flight trajectories. Direction arrows show the seasonal direction. Previous latitude-binned corridor estimates remain archived in SQLite/CSV and are not drawn on the current poster. Terrain comes from the real Natural Earth raster, lightened to match the paper-like reference palette.

## Archived candidate seasonal corridors and their bands

These exploratory curves are retained for audit and reproducibility, but are **not displayed on the current poster**. The journey-lane method below replaces them in the visual.

Solid lines summarize the July–September location window; dashed lines summarize April–May. These calendar windows are **not** independently identified migration events. For every 2.5-degree latitude bin, take the median longitude within each bird/cycle, average cycles within a bird, then give birds equal weight. Require at least five contributing birds; the actual data support 7–19 birds per bin. Smooth the bin means with a cubic smoothing spline (`spar = 0.65`) within contiguous supported latitude runs.

Resample bird IDs as clusters 1,000 times (seed 2027), recomputing the means and applying the same smoother to each bootstrap curve. Shading is the pointwise 2.5th–97.5th percentile range of those curves. It describes the **estimated smoothed mean corridor**, not individual route spread, instrument accuracy, a simultaneous confidence region, or the probability that a bird flew through the band. Binning loses temporal order, and stationary/migrating locations can mix; missingness and geolocator errors remain limitations. This is an exploratory visual summary, not a reconstruction of the paper's flight paths or stopover analysis. The un-smoothed bin estimates remain available for audit.

The study card and 30 autumn / 26 spring published migration totals come from the paper. The archived corridor calculation does not infer layover counts or durations. The current poster uses the separate exploratory journey analysis below. The bird engraving and small offset coastline shadow are decorative; the terrain itself is real shaded relief. Static poster projection is oblique Mercator, separate from Leaflet's Web Mercator.

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
- Some first/last annual cycles are partial. A cycle label does not guarantee a complete migration. The observation viewer does not calculate flight speeds or time away. The separate journey analysis estimates approximate event times, with the limitations below. “About nine months away” interprets typical August/May dates in the paper, not a per-bird result.
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
Rscript tests/test_spoi_journeys.R
Rscript research/spoi/build.R
quarto render
```

Quarto excludes `previews/` and `.R-library/`; its public site render remains independent of R execution and SQLite. Browser checks cover individual highlighting, month/cycle filters, playback, reset and a narrow phone viewport. No main-branch push is part of this work.


## Current region and journey analysis

`journeys.R` aligns both original source tables by bird and time. The sensor table supplies temperature/wet-contact/conductivity evidence; it has no independent coordinates and is never averaged into a geographic mean. `poster.R` saves the results in SQLite: `journey_journeys`, `journey_stops`, `journey_summary`, `journey_anchors`, `journey_density`, `journey_lanes`, `journey_methods` and `country_geography`. CSV audit tables and `journey-method.json` are alongside the R source. Every original record is retained.

Regional means use a projected arithmetic mean with equal weight to each bird, and equal weight to cycles within a bird. Iceland uses June/July estimates within 58–70°N / 30–10°W; winter uses November–February estimates south of 30°N / 25°W–5°E. Both migration directions share exactly the same displayed endpoint. If the mean falls outside the target land polygon, its displayed marker is moved to the nearest point on a 1 km inset of that polygon. This is a cartographic constraint, **not a corrected observation**. Raw/displayed means and displacement remain in `journey_anchors`. In this sample the unconstrained Iceland mean is about 157 km offshore: that is an important indication of raw geolocation bias/noise, not evidence that the birds breed at sea. West Africa's mean already lies on land. Neither precise natal sites nor breeding territories can be inferred from these estimates.

Concentration is a weighted Gaussian kernel in the poster projection, with fixed bandwidths of 90 km for breeding/stopovers and 160 km for winter. The 20 km evaluation grid is masked to the relevant countries, normalized to its on-land mass, and contoured at 50/75/95%. Country polygons are cached from [Natural Earth 1:50m admin-0](https://naciscdn.org/naturalearth/50m/cultural/ne_50m_admin_0_countries.zip), public domain, retrieved 2026-11-15 with checksum retained. These are **conditional concentration regions of uncertain estimates**, not the species' range, instrument-error ellipses, confidence bounds, or validated habitat boundaries. The illustrative bandwidths are not fitted error models. All regions are monochrome with no contour outlines. Nested-layer alpha is .42/.20/.08 for 50/75/95%, multiplied by contributing birds / 19. Thus one-bird France/Portugal estimates are much fainter than eleven-bird Ireland or nineteen-bird Iceland/West Africa. Repeated journeys increase a lane's journey count but do not increase a region's bird count.

Journeys use ordered, display-eligible fixes, median-smoothed within ±0.8 days. Broad origin/destination states require at least four fixes spanning 1.5 days: Iceland ≥60°N / 35–8°W, Africa ≤32°N / 30°W–5°E. Search windows are 20 July–1 September and 10 April–25 May. The midpoint of the adjacent fixes brackets each broad-region crossing. Candidate European stops require at least three days and four fixes in 35–60°N / 15°W–5°E, longitude IQR ≤4° and latitude IQR ≤5°. At least half the fixes need sensor coverage and average land evidence ≥0.5. Land evidence within ±6h of a light-interval midpoint is wet contacts >0, conductivity >15, or a temperature range ≥8°C. These thresholds are analyst choices, not a calibrated reproduction of the authors' classification. A stop's median is assigned the nearest country only when the distance is ≤200 km and, for offshore medians, the margin over the next country is ≥30 km. Otherwise it remains unresolved. Country assignments are approximate; United Kingdom includes Northern Ireland. No country is forced merely to fill a lane.

A local two-regime change-point model refines departure/arrival from standardized temperature minima/maxima and log1p wet contacts/conductivity. It minimizes within-segment squared deviations in a search interval near each coarse region crossing. Departure candidates range from four days before to half a day after; arrival candidates range from half a day before to four days after southbound, or 1.5 days before to two days after northbound. Boundary optima and sensor gaps >12h are rejected. Only journeys with both sensor refinements contribute to mean elapsed time; location-only durations remain in the audit table. Source timezone is unspecified, so UTC is used only for deterministic parsing, not asserted as source metadata. The resulting event estimates remain heuristic; we do not claim the paper's four-hour accuracy. Elapsed journey time includes stopovers and excludes the pre-departure fuelling model used in the paper's total migration duration.

The run finds 30 complete autumn and 26 complete spring candidate journeys. Spring classes are Ireland 13/26 (50%), UK 5/26 (19%), direct 5/26 (19%), France 1/26 (4%), Portugal 1/26 (4%) and unresolved country 1/26 (4%). A direct classification means **no detected stop of at least three days** with location gaps ≤36h and sensor coverage ≥50%; short or missed stops remain possible. All 26 complete spring journeys, including the unresolved case, form the percentage denominator. Autumn classifications are 28 direct and two unresolved; the paper reports all 30 as direct. The exact 56 total is coverage agreement, not independent validation of our event timings or countries. An incomplete journey stays in the audit table when the available window supports recognizing it; deployment-only or truncated summer snippets do not enter the denominator.

Sensor-refined averages are about 4.5 days southbound (28 timed journeys), 4.7 days direct northbound (5), and 15.7 days via Ireland (13). Candidate Ireland stops average 12.3 days. France/Portugal each have only one contributing bird and should not be generalized; the Portugal journey has no accepted sensor-refined total and is explicitly left without a total-time estimate. The main poster uses unboxed, everyday text beside its four numbered story points. It describes approximate durations and uses **a stop on the way home** / **viðkoma á leiðinni heim**, including around 12 days in Ireland. The possible benefit of building reserves and adjusting arrival to conditions in Iceland is explicitly conditional, following the authors’ discussion rather than asserting a measured purpose. The width explanation is in the ocean text area. The study card describes the small leg-mounted loggers; sex is retained in the source data but omitted from the poster and bird-picker labels. The underlying numerical audit remains available. These exploratory numbers differ from some published timings because our automated method has not been validated against the authors' manually checked, filtered events. Do not report them as reproduced paper findings.

The lanes are schematic cubic links between regional means. All widths now share one count scale: 0.13 mm per journey in the static poster. The southbound lane uses the paper’s 30 confirmed direct autumn migrations, rather than forcing the two unresolved automated classifications to be certain. The northbound lanes use the exploratory spring counts (13, 5, 5, 1, 1), so the southbound lane is 30/13 times as wide as the Ireland lane. The unresolved spring country has no invented route. Count source is explicit in the saved lane geometry and interactive popups. These are solid lines with direction arrows and labels as well as colour. The selected ocean is teal `#2DD2C0`. The two route colours are calculated from an RGB split-complementary relationship: +210 degrees for muted orange south (`#D1783F`) and +150 degrees for muted magenta north (`#A64B82`). They flank teal’s exact complementary hue by 30 degrees. Saturation/value are reduced to calm the large map background. This follows the user’s colour-wheel direction and is not restricted to the HÍ route palette. `spoi_palette()` is the shared source of truth for both poster languages, saved geometry, legends and the browser. White edge halos improve separation from the teal ocean; the coloured stroke widths themselves carry the count encoding. The previous bootstrap corridors remain archived but their confidence bands are not attached to these new schematic lanes.

Seasonal-role inspiration: Cephas (2020), [Whimbrel distribution map on Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Numenius_phaeopus_distribution_map.svg), [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). We consulted its distinction between breeding, migration and non-breeding. Its image, colours and range polygons are not copied into these posters. Our regions come from this Icelandic study sample and Natural Earth; this is not a map of the global species distribution.


## Palette review

`Rscript research/spoi/palette-options.R` renders colour studies without overwriting the selected posters. Earlier HÍ-only studies were superseded by the user's request for teal plus two colour-wheel companions. The selected result uses a split-complementary RGB hue scheme, not gold or coral. `previews/spoi/palette-wheel-comparison.png` retains the comparison with triadic and nearby-hue alternatives. The ocean remains teal. Design inspiration credits stay in this write-up rather than on the poster; the poster keeps scientific/data/geographic and illustration provenance. Country names remain short geographic labels, and the numerical 1/11/19-bird opacity legend has been removed. The bird is lower near the title, and the English title is close to its subtitle.


## Public poster copy and prepared-data render

`Rscript research/spoi/render-prepared.R` re-renders both language PNGs and their LinkedIn companions from the committed derived tables without recomputing the exploratory analysis. Use `build.R` for the complete rebuild. The fast renderer checks that the Mauritania label at 12°W / 20.5°N lies within Mauritania, and that title/subtitle text widths match within 0.01 inch in the actual Jost/ragg render. Both start at the same left margin. Short place names remain, but the return-journey box and per-stop numerical annotations are absent.

The four public story points are: approximately three months at home in Iceland for nesting/raising chicks; a direct autumn journey of roughly four to five days; about eight months by the West African coast; and a spring return often including a stop, with roughly twelve days in Ireland, sixteen days total via Ireland or five directly. All new times are rounded exploratory estimates, not a claim of exact reproduction of the authors' events. The possible role of reserves/weather is a conditional interpretation from [the paper's Discussion](https://doi.org/10.1111/jav.01938), not an observed reason for every stop or evidence of birds 'getting their bearings'.

`poster_story_facts()` pairs accepted sensor-refined arrivals with subsequent departures for the same bird. Within-bird stays are averaged first, then birds have equal weight. Partial stays are excluded. Iceland's observed mean is 94.72 days / 3.11 months, based on eight complete stays from only four birds. West Africa's is 251.55 days / 8.26 months, based on 24 complete stays from 17 birds. The small summer sample is an important limit; these are approximate sample summaries, not a population-wide schedule. Months use 30.4375 days; captions round to whole months. SQLite `poster_residence`, `poster-residence.csv` and `poster-story-facts.json` preserve the values and sample sizes. A synthetic test checks correct same-bird/year pairing and prevents repeatedly tracked birds from dominating the estimate. The three/nine-month Iceland/away framing is also consistent with the paper's typical May–August dates; the eight-month West African stay excludes migration/stopover time.


The latest composition places the autumn story (2) above the bird, with the bird and title/research block lower. The public legend reads “Appelsínugult suðurflug; fjólubleikt norðurflug” / “Orange southbound; magenta northbound.” Only layout and descriptive wording change; the analytical route geometry and proportional widths remain the same.
