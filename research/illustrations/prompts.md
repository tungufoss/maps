# Reusable illustration prompts

Append a dated entry when an asset is created or revised. Keep the used prompt, output path, method, reference and model information together; do not guess model identifiers.

## Images

### 2026-11-14: Whimbrel flight overlay

- Output: [images/spoi-flight-ai.png](images/spoi-flight-ai.png).
- Reference: [original JPEG scan](https://upload.wikimedia.org/wikipedia/commons/a/a3/Nederlandsche_vogelen_%28KB%29_-_Numenius_phaeopus_%28304b%29.jpg), Nozeman & Sepp, public-domain source scan; [original and rights](https://commons.wikimedia.org/wiki/File:Nederlandsche_vogelen_(KB)_-_Numenius_phaeopus_(304b).jpg).
- Tool: OpenAI `image_gen.imagegen`, `transparent_background: true`. Exact underlying model/version not exposed.
- Reuse: ornamental transparent overlay in R posters and HTML. It is a generated flight interpretation, not a historical flight drawing or validated identification illustration. The reference's public-domain status does not establish the generated output's legal status.

Full submitted prompt:

```text
Create one isolated Eurasian whimbrel (spói, Numenius phaeopus) in flight, using the attached public-domain Nozeman–Sepp whimbrel plate from Nederlandsche vogelen as a reference for plumage pattern, head markings, bill shape and historical engraved linework. This is a NEW AI-generated interpretive flight pose, not a restoration, tracing, historical plate or scientifically validated reconstruction. Show a natural three-quarter side view flying toward the right, both wings extended in a shallow upward stroke, anatomically plausible long pointed wader wings, a compact streamlined body, small head with a pale crown stripe and dark lateral crown stripes, a long slender moderately downcurved bill, small dark eye, fine streaked neck and breast, mottled and barred wing feathers, short tail, and two legs tucked back with feet trailing slightly beyond the tail. European whimbrel appearance, not an osprey, gull, ibis, little whimbrel or long-billed Eurasian curlew. Keep the whole bird within the frame with generous clear margins and no clipping. Render as elegant nineteenth-century scientific copperplate-style line engraving with delicate crosshatching and careful feather detail. MONOCHROME #262626 ink only with transparent unmarked background, no brown pigment, no beige paper, no scenery, no map, no text, no labels, no border, no drop shadow. Landscape composition suitable as an ornamental illustration on a modern migration map. Use the source as visual inspiration while changing the standing pose to flight; do not imply that the flight pose was drawn by the historical illustrators.
```

## Icons

### 2026-11-15: M-shaped flying-bird marker

- Output: [icons/whimbrel-flight-marker.svg](icons/whimbrel-flight-marker.svg).
- Method: SVG path authored directly by the coding assistant; no image-generation call. Exact coding-model identifier is not available in this asset's generation metadata.
- References: the user's M-shaped flying-bird idea and the visual weight of simple solid icon families. No Font Awesome path or other icon artwork was copied. It is an original generic motif, not an official Font Awesome icon or species identification drawing.
- Reuse: `viewBox="0 0 32 32"`, `currentColor` fill and a narrow white outline. The beak points up at zero rotation. Rotate the inner SVG, preserving Leaflet's outer marker positioning transform. If consecutive observations are separated by a gap, no heading is inferred.

Design brief from the conversation:

> Create our own simple bird in flight: an M-like motif that means flying, with the simplicity and visual weight of the Font Awesome family. Use it at observed positions during month playback, pointing along the direction between consecutive estimates, with an optional fading trail capped at twelve months.
