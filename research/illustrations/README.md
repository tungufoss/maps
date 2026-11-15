# Spói illustration provenance

Prepared 14 November 2026 on `feature/iceland-bird-migration`.

## Reference plate

- Subject: whimbrel, *Numenius phaeopus*; not explicitly an Icelandic subspecies portrait.
- Work: Nozeman & Sepp, *Nederlandsche vogelen* (1770–1829), plate 156, file 304b.
- Collection: Koninklijke Bibliotheek, National Library of the Netherlands.
- [Source and rights record](https://commons.wikimedia.org/wiki/File:Nederlandsche_vogelen_(KB)_-_Numenius_phaeopus_(304b).jpg).
- [Original scan](https://upload.wikimedia.org/wikipedia/commons/a/a3/Nederlandsche_vogelen_%28KB%29_-_Numenius_phaeopus_%28304b%29.jpg).
- Retrieved 14 November 2026; local file: `inspiration/whimbrel-nozeman-sepp-reference.jpg` (ignored local copy).
- The Commons record identifies the image as public domain, with a Public Domain Mark and an expired-copyright statement. This describes the source scan, not a legal status assigned to the generated output.

## Generated flight interpretation

- Output: [spoi-flight-ai.png](images/spoi-flight-ai.png), generated 14 November 2026. This is the decorative bird used in the current R posters and Leaflet preview.
- Tool: OpenAI's built-in `image_gen.imagegen`, accessed in Codex as `image_gen__imagegen`.
- Model identifier/version: **not exposed by the tool interface or returned metadata**. Do not infer it from the Codex chat model or CLI defaults.
- Full submitted prompt: [prompts.md, Images](prompts.md#images).
- Reference supplied to the tool: `inspiration/whimbrel-nozeman-sepp-reference.jpg` (ignored local copy).
- Setting: `transparent_background: true`.
- This is a newly generated flight pose, not an authentic historical illustration. The standing reference does not establish the correctness of the wing or flight anatomy. Ornithological review is still needed before treating it as a reliable identification drawing.
- Do not describe the generated image as public domain merely because its reference is public domain.

Suggested credit: **AI-generated whimbrel flight illustration, inspired by Nozeman & Sepp, Nederlandsche vogelen, plate 156; public-domain reference from Koninklijke Bibliotheek via Wikimedia Commons. Created with OpenAI image generation; exact model identifier unavailable. Prompt and provenance supplied.**

## Retained assets

Only the used bird illustration and its prompt are retained in Git; reference images are linked by source URL. Superseded AI poster and website mockups and their prompts were removed; earlier versions remain in Git history. The final map, routes, typography and layout are rendered in R.
