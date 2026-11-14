# 52 Weeks of Maps

A Quarto atlas for one data-driven map per week in 2027. Python → PostGIS → R → Quarto, with open methods and a separate LinkedIn export.

## Local preview

```powershell
quarto preview
```

Build the static site with `quarto render`. No R, Python, or database execution is required to render the starter. Weekly analyses run separately; commit the publishable figures and explain their reproduction steps. Enable evaluation explicitly only for reviewed, self-contained page code.

## Start a week

Ask the agent to use `new-map-week`, or copy `maps/_template` to `maps/2027-W01`. Update both metadata and page front matter. Add the real map and sources, then remove `draft: true` when ready. Do not publish the template as a completed investigation.

## GitHub Pages

The intended repository is `tungufoss/maps`. Push this project to its `main` branch and select **GitHub Actions** under repository Settings → Pages. The included workflow renders and deploys `_site` to https://tungufoss.github.io/maps/.

This local setup does not create the GitHub repository or enable Pages remotely.

## Design provenance

`styles/hi-site.scss` is reused from [quarto-hi](https://github.com/tungufoss/quarto-hi), with its MIT notice retained in `styles/quarto-hi-LICENSE.txt`. `styles.css` adds the map gallery and responsive hero layout. The site loads Jost and uses the shared theme’s blue navigation/footer, turquoise accents, headings, tables, code, and callouts. No University logos are copied.
