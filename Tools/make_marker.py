"""Generate the printable tracking marker for Brickwise.

ARKit image detection works best on an asymmetric, high-contrast, detailed image
(not a QR code). This draws a seeded random composition so the output is reproducible.

Usage: python3 -I Tools/make_marker.py Resources/brickwise-marker.png
Print it at exactly 6 cm wide (the width in the build JSON).
"""
import random
import sys

from PIL import Image, ImageDraw

SIZE = 1200
MARGIN = 70
SEED = 7
PALETTE = ["#111111", "#111111", "#444444", "#E5483B", "#2F7A4B", "#3B82F6"]


def main(out_path):
    rng = random.Random(SEED)
    img = Image.new("RGB", (SIZE, SIZE), "white")
    draw = ImageDraw.Draw(img)

    lo, hi = MARGIN, SIZE - MARGIN
    draw.rectangle([lo, lo, hi, hi], outline="#111111", width=14)

    def center():
        return rng.randint(lo + 60, hi - 60), rng.randint(lo + 60, hi - 60)

    def near(c, spread):
        cx, cy = c
        return (
            min(max(cx + rng.randint(-spread, spread), lo + 20), hi - 20),
            min(max(cy + rng.randint(-spread, spread), lo + 20), hi - 20),
        )

    # Many small shapes (no big flat areas) give ARKit lots of corners to track.
    for _ in range(190):
        color = rng.choice(PALETTE)
        shape = rng.choice(["tri", "rect", "circle", "line"])
        c = center()
        spread = rng.randint(25, 90)
        if shape == "tri":
            draw.polygon([near(c, spread), near(c, spread), near(c, spread)], fill=color)
        elif shape == "rect":
            (x1, y1), (x2, y2) = near(c, spread), near(c, spread)
            draw.rectangle([min(x1, x2), min(y1, y2), max(x1, x2), max(y1, y2)], fill=color)
        elif shape == "circle":
            r = rng.randint(8, 40)
            draw.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], fill=color)
        else:
            draw.line([near(c, spread), near(c, spread)], fill=color, width=rng.randint(4, 10))

    # Asymmetric corner notch so orientation is unambiguous.
    draw.polygon([(lo, lo), (lo + 170, lo), (lo, lo + 170)], fill="#E5483B")

    img.save(out_path)
    print(f"wrote {out_path} ({SIZE}x{SIZE})")


main(sys.argv[1])
