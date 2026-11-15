# 52 / HIDEF MAPS

Maps defined by Dr Helga Ingimundardóttir

**Implementation update, 15 November 2026:** reproducible R/Leaflet HTML and separate English **WHIMBREL** / Icelandic **SPÓI** posters now use the imported SQLite observations and sensor data. [English poster](../previews/spoi/poster.png) · [Íslenskt veggspjald](../previews/spoi/poster-is.png) · [Interactive HTML](../previews/spoi/index.html). Land-constrained regional means, monochrome concentration regions and schematic journey lanes are derived and cached with provenance; stopovers and timings remain exploratory estimates. The 12-day mini-break summary refers to candidate Ireland stops. Teal, muted orange and muted magenta follow an RGB split-complementary scheme. Design inspiration is credited in this write-up, not on the poster. See [reproduction instructions, source citations and analytical limitations](spoi/README.md). The generated images and proposed interactions below are retained as design history; their “not imported” labels describe the earlier mockup stage.

[HIDEF website design preview](hidef-spoi-site-preview.png) — an AI-generated visual mockup, not a screenshot of a functioning Leaflet implementation. The disabled explorer depicts pending data access; no individual tracks are shown. Generated 14 November 2026 with `image_gen.imagegen`; exact model identifier not exposed. [Full prompt](illustrations/hidef-site-preview-prompt.txt). The input reference was `spoi-teal-poster-v2.png`.

# Spói summers in Iceland

*≈ 3 months of summer vacation.*

Spói returns to Iceland to breed, filling the short summer with its distinctive whistling call. Tracked adults typically returned in May and left in August: roughly three months in Iceland and nine months away. The non-breeding season takes them south, including to West Africa. Individual schedules vary.

Chicks of the Icelandic breeding population hatch in Iceland, rather than in their African non-breeding grounds. The tracked birds were adults caught on nests in Iceland; their individual natal sites are not recorded in the dataset. [Paper: breeding and tagging methods](https://doi.org/10.1111/jav.01938).

The subtitle is playful editorial framing; the description identifies the Icelandic stay as the breeding season. The durations are approximate interpretations of typical dates in the paper, not per-bird estimates calculated from the raw position file.

## What the dataset contains

The position table contains bird ID, sex, two twilight timestamps, derived longitude/latitude and the solar-elevation calibration angle. The second table contains bird ID, time, minimum/maximum temperature, wet-contact count and conductivity. SQLite also stores traceable source row IDs, parsed display timestamps, annual cycles and explicit quality flags. The 19 birds comprise 13 males and 6 females. Exact ages are absent; the paper identifies the study birds as adults caught on nests. Stopover labels, exact departure/arrival events and per-position uncertainty bounds are not provided as columns.

## Next analysis and animation design

Keep individual bird-year journeys visible in the vintage teal poster. Add separate inbound and outbound summaries after identifying migration intervals from the positions and environmental channels using a documented method. Avoid averaging longitude/latitude by calendar date: some birds are travelling while others are stationary, and repeated years from the same bird would otherwise dominate. A representative route or density corridor plus bird-level summary statistics is preferable to an unqualified “mean path”. Report the number of birds and complete journeys contributing to each summary, and distinguish stopover counts, stopover duration and total travel duration. Paper-derived numbers must be labelled separately from newly reproduced estimates.

An R/gganimate export can reveal observed positions on a fixed map without tweening across gaps. Highlight the current bird-year season and fade older seasons as context. Within a season, recent observations can fade into a short trail. Use actual dates for chronological playback; label any optional calendar-aligned multi-year comparison. `transition_manual()` can reveal prepared date frames without inventing intermediate locations. This extension is proposed, not implemented in the current Leaflet poster.

References: [gganimate](https://gganimate.com/), [background marks](https://gganimate.com/reference/shadow_mark.html), and the paper and dataset citations below.

Editorial framing: “escaping winter” is the human storytelling hook, not a claim that the study measured birds' feelings or established a single cause of migration.

## TL;DR — meet spói

Spói, the whimbrel, is a long-distance migrant with a downcurved bill, a pale crown stripe and a distinctive whistling call. It breeds in Iceland and spends the non-breeding season farther south, including West Africa. In the tracked-adult study, departures were typically in August and returns in May: roughly **nine months away from Iceland**, and only about three months at home. Individual schedules vary. Many spring journeys included a stopover, so the trip home was not simply the outward journey in reverse.

Sources: [BTO BirdFacts — identification](https://www.bto.org/learn/about-birds/birdfacts/whimbrel); [RSPB / Fuglavernd — Icelandic bird and migration context](https://web-cdn.rspb.org.uk/whats-happening/news/whats-happening-on-the-frontline-to-help-migratory-birds); [Carneiro et al. — Table 1, seasonal dates](https://doi.org/10.1111/jav.01938). Nine months is an approximate interpretation of August-to-May timing, not a newly computed sample mean or a duration applicable to every bird or age class.

## Explore each bird — proposed interaction

Show each verified bird-year journey as a separate overlaid route, rather than showing only a schematic population pattern. Selecting an individual should highlight its journeys and dim the other birds. Offer a season/year filter, a clear reset to all birds, and a mobile-friendly time control that displays observations without implying continuous GPS tracking. Use original bird IDs, not invented names. Multiple years from one bird must remain distinguishable.

R should prepare the cartography and export a Leaflet HTML widget plus a static poster from the same validated observations. Quarto should publish the prepared outputs without a running database or R server. Preserve teal styling, with line types, labels and selection states for readability. Individual duration calculations must require identifiable departure and return events, and show “not available” for incomplete journeys.

This interaction is a proposed design, not an implemented map. No route records have been imported.

Design and story draft. No weekly slot assigned. Not published.

![Teal spói poster design with a bird engraving, schematic seasonal routes and four numbered story notes.](spoi-teal-poster-v2.png)

Poster review: this generated composition is for design discussion. Version 2 removes an incorrect south-pointing arrowhead from the dashed spring line; the solid autumn line points south, while spring arrows point north via Ireland to Iceland. Geography, relief, labels and route placement still require replacement or verification. No quantitative measurements should be taken from the image. The first concept is retained as `spoi-teal-poster.png`.

## One ocean, two seasonal strategies

For Icelandic spói, the Atlantic links breeding grounds in Iceland with non-breeding areas in West Africa. The journey changes with the season.

Carneiro and colleagues examined 56 migrations from 19 whimbrels tracked with light-level geolocators. Autumn journeys were faster and went directly to West Africa. Most spring journeys included a stopover, with Ireland among the places used. The contrast makes the return journey part of the story, rather than simply reversing the southbound line.

These are findings from the published study, not results calculated for this project. The poster currently illustrates the seasonal pattern; its routes and geography are a design concept. We have not yet imported the archived positions. Light-level geolocation carries uncertainty and should not be presented as a precise GPS flight path.

## Read the research

**Paper:** Carneiro, C., Gunnarsson, T. G. & Alves, J. A. (2019). *Faster migration in autumn than in spring: seasonal migration patterns and non-breeding distribution of Icelandic whimbrels Numenius phaeopus islandicus*. Journal of Avian Biology, 50(1). [Read the paper](https://nsojournals.onlinelibrary.wiley.com/doi/10.1111/jav.01938) · DOI: 10.1111/jav.01938.

**Data:** Carneiro, C., Gunnarsson, T. G. & Alves, J. A. (2019). *Data from: Faster migration in autumn than in spring: seasonal migration patterns and non-breeding distribution of Icelandic Whimbrels Numenius phaeopus islandicus*. Dryad. [Dataset and file list](https://datadryad.org/dataset/doi:10.5061/dryad.3kf35s5) · DOI: 10.5061/dryad.3kf35s5.

## Visual sources and generation

- Poster composition inspired by Warren Davison's [Drawn by Flight, full-size poster](https://storymaps.esri.com/stories/storyscape-resources/30-day-map-challenge/map2.png), [featured in Esri's 2025 StoryScape gallery](https://storyscape-esriwhere.hub.arcgis.com/pages/2025-30-day-map-challenge). The source poster is a visual reference; no reuse licence has been established for it. Its local reference copy is ignored by Git.
- Bird engraving: an AI-generated interpretation of a flight pose, inspired by the [public-domain Nozeman–Sepp plate](https://commons.wikimedia.org/wiki/File:Nederlandsche_vogelen_(KB)_-_Numenius_phaeopus_(304b).jpg), held by Koninklijke Bibliotheek. [Bird prompt and provenance](illustrations/README.md).
- Poster generated with OpenAI's built-in `image_gen.imagegen` tool. Exact underlying model/version is not exposed by the interface or response. [Full poster prompt](illustrations/spoi-teal-poster-prompt.txt). References: the Davison poster and the generated whimbrel engraving. Generation date: 14 November 2026.
- Version 2 used the same tool, with version 1 as its reference. [Full correction prompt](illustrations/spoi-teal-poster-v2-prompt.txt).
- The generated poster is a design artifact. Replace its geography and schematic lines with reproducible cartography before presenting a final map. Study-level counts on the poster are not position-file row counts.
