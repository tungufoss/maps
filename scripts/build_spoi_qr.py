"""Build the poster QR code: one colour (the poster's near-black ink) on a transparent background,
high error correction, with the HI seal centred.

Usage: python scripts/build_spoi_qr.py [URL] [OUTPUT]
Requires: segno, cairosvg, Pillow (scripts/requirements-qr.txt).
"""
import io
import sys

import cairosvg
import segno
from PIL import Image, ImageDraw

URL = "https://tungufoss.github.io/maps/research/spoi/site.html"
LOGO = "img/hi/hi_logo.svg"
OUTPUT = "img/qr/spoi.png"
SIZE = 600          # output pixels; the poster scales it down
LOGO_SHARE = 0.24   # logo diameter / QR width; level H tolerates ~30% loss
INK = "#262626"     # the poster's text colour; the seal is recoloured to match


def build(url=URL, output=OUTPUT):
    qr = segno.make(url, error="h", micro=False)
    buffer = io.BytesIO()
    qr.save(buffer, kind="png", scale=1, border=2, dark=INK, light=None)
    code = Image.open(buffer).convert("RGBA")
    code = code.resize((SIZE, SIZE), Image.NEAREST)

    # Clear the modules behind the seal; level H recovers them.
    disc = round(SIZE * LOGO_SHARE)
    centre = SIZE // 2
    mask = Image.new("L", code.size, 0)
    ImageDraw.Draw(mask).ellipse([centre - disc // 2, centre - disc // 2,
                                  centre + disc // 2, centre + disc // 2], fill=255)
    code.paste((0, 0, 0, 0), (0, 0), mask)
    seal = round(disc * 0.92)
    with open(LOGO, encoding="utf-8") as f:
        svg = f.read().replace("#10099f", INK)
    logo = Image.open(io.BytesIO(cairosvg.svg2png(
        bytestring=svg.encode("utf-8"), output_width=seal, output_height=seal))).convert("RGBA")
    code.alpha_composite(logo, (centre - seal // 2, centre - seal // 2))
    code.save(output)
    print(f"{output}: version {qr.version}, error level {qr.error}, {url}")


if __name__ == "__main__":
    build(*sys.argv[1:3])
