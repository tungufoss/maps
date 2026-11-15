# 52 / HIDEF MAPS

Maps defined by Dr Helga Ingimundardóttir

**Implementation update, 15 November 2026:** reproducible R/Leaflet HTML and separate English **WHIMBREL** / Icelandic **SPÓI** posters now use the imported SQLite observations and sensor data. [English poster](../previews/spoi/poster.png) · [Íslenskt veggspjald](../previews/spoi/poster-is.png) · [Interactive HTML](../previews/spoi/index.html). Land-constrained regional means, monochrome concentration regions and schematic journey lanes are derived and cached with provenance; stopovers and timings remain exploratory estimates. The 12-day mini-break summary refers to candidate Ireland stops. Teal, muted orange and muted magenta follow an RGB split-complementary scheme. Design inspiration is credited in this write-up, not on the poster. See [reproduction instructions, source citations and analytical limitations](spoi/README.md). The generated images and proposed interactions below are retained as design history; their “not imported” labels describe the earlier mockup stage.

## Summers in Iceland

Whimbrels in this study breed in Iceland and spend the non-breeding season on West Africa's Atlantic coast. The poster contrasts a rapid autumn journey with spring journeys that often include a stop. Chicks hatch on the breeding grounds; the tracked adults' individual natal sites are not recorded.

The current exploratory analysis rounds complete paired stays to about three months in Iceland and eight months in West Africa. These are separate estimates from different subsets, not an exhaustive twelve-month budget. The Iceland estimate uses only four birds. Candidate Ireland stops average about twelve days. See the [full method, sample sizes and limitations](spoi/README.md) before interpreting these numbers.

![English whimbrel poster rendered in R, with teal ocean, seasonal schematic routes and numbered story notes.](../previews/spoi/poster.png)

## From observations to a readable poster

The archive contains light-level geolocation estimates, not GPS flight paths. Python preserves both original tables in SQLite with source checksums and quality flags. R reads the prepared data, estimates stationary regions and candidate journeys, and renders the geography, relief, routes, labels and typography. The Leaflet preview can also show individual recorded location estimates, with gaps retained.

Regional anchors give each bird equal weight, with repeated cycles averaged within birds. An offshore regional mean is moved onto the intended land region for display; its original mean is retained. This changes the displayed Iceland anchor by about 157 km, an important indication of the limits of these noisy positions.

Routes are schematic cubic Bezier curves between those anchors. Stopover routes pass through the corresponding regional anchor. Their bends are chosen for legibility; they are not fitted flight paths. Width represents journey counts on a common scale. Autumn's thirty direct journeys are from the published paper; the spring country assignments are exploratory classifications from this project's analysis. Dark regions show location concentration and contributing bird counts, not confidence intervals or instrument accuracy.

English and Icelandic posters share one R layout. Jost is bundled under its OFL licence. A static export needs no running database server, and the prepared Leaflet HTML embeds the observations; its map tiles require internet. [Reproduction commands and dependency versions](spoi/README.md).

## Paper and dataset

Carneiro, C., Gunnarsson, T. G. & Alves, J. A. (2019). *Faster migration in autumn than in spring: seasonal migration patterns and non-breeding distribution of Icelandic whimbrels Numenius phaeopus islandicus*. Journal of Avian Biology, 50(1). [Paper and DOI](https://doi.org/10.1111/jav.01938).

Same authors (2019), [corresponding Dryad dataset](https://doi.org/10.5061/dryad.3kf35s5), CC0-1.0. The original files contain twilight timestamps and derived positions, plus temperature, wet-contact and conductivity summaries. This project does not reproduce the paper's complete manual processing and scientific analysis.

## Visual credits

Composition inspired by Warren Davison's [Drawn by Flight](https://storymaps.esri.com/stories/storyscape-resources/30-day-map-challenge/map2.png), featured in [Esri's 2025 collection](https://storyscape-esriwhere.hub.arcgis.com/pages/2025-30-day-map-challenge). Its image is not included in the final map; no reuse licence is claimed.

Land and shaded relief are from [Natural Earth](https://www.naturalearthdata.com/about/terms-of-use/), public domain. Seasonal-role inspiration also came from [Cephas's whimbrel distribution map](https://commons.wikimedia.org/wiki/File:Numenius_phaeopus_distribution_map.svg); its polygons and image are not reproduced.

The decorative bird is an AI-generated flight interpretation after a [public-domain Nozeman-Sepp plate](https://commons.wikimedia.org/wiki/File:Nederlandsche_vogelen_(KB)_-_Numenius_phaeopus_(304b).jpg) from Koninklijke Bibliotheek. It was created on 14 November 2026 using OpenAI's `image_gen.imagegen` tool. The exact model/version was not exposed. [Full used prompt, original scan and provenance](illustrations/README.md). It is not an authentic historical flight drawing or a scientifically validated reconstruction.

Only the used bird asset and its generation materials are retained. Superseded generated poster and website mockups remain in Git history. This is a branch-only story draft; no weekly slot has been assigned and nothing has been published.
