#!/usr/bin/env python3
"""Side-by-side review sheet: procedural source vs generated art, for judging a batch.

    python3 -I tools/art_review_sheet.py portraits --out /tmp/portraits_review.png
    python3 -I tools/art_review_sheet.py hardware  --out /tmp/hardware_review.png
"""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "reference" / "art_source"
OUT = ROOT / "game" / "assets" / "art"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("kind", choices=["portraits", "hardware"])
    ap.add_argument("--out", required=True, type=Path)
    ap.add_argument("--cols", type=int, default=4)
    a = ap.parse_args()
    if a.kind == "portraits":
        generated = sorted((OUT / "portraits").glob("*.png"))
        pairs = [(SOURCE / "portraits" / g.name, g) for g in generated]
        tile = (168, 200)
    else:
        generated = sorted((OUT / "hardware").glob("*/*.png"))
        pairs = [(SOURCE / "hardware" / g.parent.name / g.name, g) for g in generated]
        tile = (200, 200)
    if not pairs:
        raise SystemExit("nothing generated yet")
    cols = a.cols
    rows = (len(pairs) + cols - 1) // cols
    cell_w = tile[0] * 2 + 12
    cell_h = tile[1] + 28
    sheet = Image.new("RGB", (cell_w * cols, cell_h * rows), (27, 39, 64))
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype(str(ROOT / "game" / "assets" / "fonts" / "SourceSans3-Semibold.otf"), 16)
    except OSError:
        font = ImageFont.load_default()
    for i, (src, gen) in enumerate(pairs):
        x = (i % cols) * cell_w
        y = (i // cols) * cell_h
        for j, path in enumerate([src, gen]):
            if path.exists():
                im = Image.open(path).convert("RGBA")
                im.thumbnail(tile)
                bg = Image.new("RGBA", tile, (16, 24, 40, 255))
                bg.paste(im, ((tile[0] - im.width) // 2, (tile[1] - im.height) // 2), im)
                sheet.paste(bg.convert("RGB"), (x + j * (tile[0] + 12), y))
        label = gen.stem if a.kind == "portraits" else f"{gen.parent.name}/{gen.stem}"
        draw.text((x + 4, y + tile[1] + 6), label, fill=(233, 228, 214), font=font)
    sheet.save(a.out)
    print(f"wrote {a.out} with {len(pairs)} pairs")


if __name__ == "__main__":
    main()
