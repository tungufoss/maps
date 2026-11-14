---
name: new-map-week
description: Start or develop a weekly map investigation in this 52 Weeks of Maps repository, from a current interest through data preparation, R cartography, Quarto page, and LinkedIn draft.
---

# Start a map week

Begin with what interests the author this week. Use an interest already supplied; otherwise ask for it. The idea bank and historical prompts are optional inspiration, never the next compulsory assignment.

Read the repository AGENTS.md and inspect adjacent weekly entries. Clarify the research question, geographic scope, and available time when they affect feasibility. Find real datasets and check provenance, licence, coverage, freshness, and limitations before committing to a cartographic approach.

Copy `maps/_template/` to an unused `maps/YYYY-WNN/` folder. Confirm the intended year/week, preserve existing work, and update metadata and page front matter. Keep `draft: true` until a real map and explanation are ready.

Prepare data in Python, use the shared PostGIS database when useful, keep weekly queries in the corresponding schema, and make the map in R. Record actual commands, packages, coordinate reference systems, and assumptions. Do not make publication depend on database access.

Export a web figure and a 1200 × 1200 or 1200 × 1500 LinkedIn PNG. Inspect labels, legend, projection, colour accessibility, source attribution, geometry, and the strength of the claimed finding. Write a 100–200 word interpretation and document methods and reproducibility. Prepare a LinkedIn draft; posting requires explicit authorization.

Set subject and technique categories. Verify exact historical year/day/prompt matches separately from loose thematic relationships. Update page and metadata consistently. Add a genuine source-code link and the LinkedIn URL when available.

Run `quarto render`, inspect the resulting page and atlas entry, and verify unpublished work remains excluded. Report the files and preview, verification performed, and any remaining data or publication decisions.
