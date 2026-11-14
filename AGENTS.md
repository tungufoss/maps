# 52 Weeks of Maps

This repository is a Quarto website for a personal 2027 weekly mapping project. Topics follow the author's interests; historical challenge prompts are retrospective tags, not assignments.

## Architecture

Python prepares data; one shared PostgreSQL/PostGIS database supports spatial analysis; R creates maps; Quarto publishes prepared assets to GitHub Pages. Keep the site render independent of a running database and credentials. A simple map may use files directly.

Use shared `raw`, `staging`, and `shared` schemas and a weekly schema such as `w2027_01`. Store reproducible SQL with the weekly investigation. Record source URLs, retrieval dates, licences, coverage, limitations, CRS, and dependency versions. Keep credentials in environment variables and large or restricted datasets out of Git.

## Weekly entries

Use `.agents/skills/new-map-week/SKILL.md` to start a week. Copy `maps/_template/` into `maps/2027-WNN/`. Keep unfinished pages `draft: true`. The atlas uses Quarto listings; published pages require a real title, date, description, categories, and map image. Categories support subject and technique filtering. Keep historical prompt year/day/text in structured metadata, verifying matches against their original source.

Every entry needs the map, a concise interpretation, provenance, method, reproducibility instructions, and a LinkedIn link when available. Make limitations explicit. Do not invent findings, historical coverage counts, maps, or source licences.

## Verification and publication

Run `quarto render` before reporting a site change complete. Review navigation, mobile layout, accessible colours, alternative text, and gallery draft exclusion. Map QA includes projection suitability, units, geometry validity, legends, labels, source attribution, and an export sized for LinkedIn. Public publishing is a separate action from drafting a post; do not post to LinkedIn without an explicit request.

The GitHub Pages workflow renders committed pages and assets from `main`. Keep all shared instructions and starter templates out of the rendered atlas. Preserve the visual independence from University branding.
