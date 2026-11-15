# Map inspiration reviewer

## Open online

Visit <https://tungufoss.github.io/maps/inspiration/>. No installation or account is needed. A small link appears on the challenge page; it is not in the header navigation, atlas, search index or sitemap. The page requests that search engines do not index it. This is a public URL, not a password-protected page.

Select a collection on the left to open its original website on the right. Scroll the left pane to record Positive, Neutral or Negative, explain why, and tag features you might borrow. Sites that block embedding can be opened with **Open in new tab**. On phones, the panes stack; **View beside review** jumps to the original collection.

Your notes and reactions stay in this browser's local storage. Nothing uploads them to GitHub or to collection creators. The original websites load directly and may use their usual cookies and network requests. Reviews are tied to the browser and origin; they do not automatically synchronise across devices, browsers, or localhost and GitHub Pages. Other pages on the same GitHub Pages origin can technically access that origin's local storage; do not use it for sensitive information.

## Move existing reviews online, or between devices

1. Open the old reviewer in the browser where you wrote the notes, such as <http://127.0.0.1:8874/>.
2. Select **Export review backup** and keep the JSON file.
3. Open the online reviewer (or the other device), choose **Import backup**, and select the JSON file.
4. Import merges reviews, keeping the newer timestamp for each collection. Export regularly: clearing browser data removes local reviews.

**Export design brief** downloads a readable Markdown summary for planning future maps. Neither export is uploaded automatically. Do not commit personal backups to Git.

## Run locally

On Windows with Python 3 installed, double-click **Open map reviews.cmd** in the repository root. This starts or reuses the loopback-only server at <http://127.0.0.1:8874/>.

Alternatively, from the repository root:

```powershell
py -3 -m http.server 8874 --bind 127.0.0.1 --directory tools/collection-review
```

On macOS/Linux, use `python3` in place of `py -3`. Keep the terminal open and visit the address above. Press Ctrl+C to stop it. No R, PostgreSQL or Quarto is needed to run this tool locally. If port 8874 is occupied, use another port, remembering that a different port uses a different local-storage origin.

## Publish and verify

```sh
node --test tests/collection_review.test.cjs
quarto render
```

Quarto's post-render script copies exactly five public files into `_site/inspiration/`: `index.html`, `review.css`, `review.js`, `model.js` and `catalog.js`. It does not copy this folder wholesale or read browser storage. The normal GitHub Pages workflow deploys `_site` on pushes to `main`. Catalogue source and refresh instructions are in [data/community/README.md](../../data/community/README.md).
