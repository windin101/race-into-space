"""Assemble a side's three launch-pad sprites from generated parts.

    python3 tools/art_source/assemble_pads.py PARTS_DIR OUT_DIR --platform N --gantry N --wreck N
           [--gantry-scale 0.95] [--gantry-dx 70] [--gantry-dy -345]

Reads platform_N.png, gantry_N.png, gantry_wreck_N.png (RGBA cutouts) and writes
pad_site.png (the bare platform), pad_ok.png (platform + gantry standing on it) and
pad_damaged.png (scorched platform + the wreck). The generator attaches buildings to any
pad asked for whole, so pads are always built from parts (see docs/art-asset-list.md).
"""
import argparse
from pathlib import Path
import numpy as np
from PIL import Image, ImageEnhance

ap = argparse.ArgumentParser()
ap.add_argument("parts"); ap.add_argument("out")
ap.add_argument("--platform", type=int, required=True); ap.add_argument("--gantry", type=int, required=True)
ap.add_argument("--wreck", type=int, required=True)
ap.add_argument("--gantry-scale", type=float, default=0.95)
ap.add_argument("--gantry-dx", type=int, default=70, help="gantry foot offset from the platform centre, px")
ap.add_argument("--gantry-dy", type=int, default=-40, help="gantry foot offset from the platform centre, px")
a = ap.parse_args()
P, O = Path(a.parts), Path(a.out); O.mkdir(parents=True, exist_ok=True)

def tight(im):
    bb = im.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()
    return im.crop(bb) if bb else im

site = tight(Image.open(P / f"platform_{a.platform}.png").convert("RGBA"))
gantry = tight(Image.open(P / f"gantry_{a.gantry}.png").convert("RGBA"))
wreck = tight(Image.open(P / f"gantry_wreck_{a.wreck}.png").convert("RGBA"))
site.save(O / "pad_site.png")

def stand_on(base, part, scale, dx, dy):
    """Stand `part` with its foot at base-centre + (dx, dy); grow the canvas upward to fit."""
    part = part.resize((round(part.width * scale), round(part.height * scale)), Image.LANCZOS)
    cx, cy = base.width // 2 + dx, base.height // 2 + dy
    left, top = cx - part.width // 2, cy - part.height
    x0, y0 = min(0, left), min(0, top)
    w = max(base.width, left + part.width) - x0; h = max(base.height, cy) - y0
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    canvas.alpha_composite(base, (-x0, -y0)); canvas.alpha_composite(part, (left - x0, top - y0))
    return canvas

stand_on(site, gantry, a.gantry_scale, a.gantry_dx, a.gantry_dy).save(O / "pad_ok.png")

# scorch the platform before laying the wreck on it
arr = np.asarray(site).astype(float)
yy, xx = np.mgrid[0:site.height, 0:site.width]
r = np.hypot((xx - site.width / 2) / (site.width / 2), (yy - site.height / 2) / (site.height / 2))
dark = np.clip(1 - r, 0, 1)[..., None] * 0.55
arr[..., :3] = arr[..., :3] * (1 - dark) + np.array([30, 26, 24.0]) * dark
scorched = Image.fromarray(arr.clip(0, 255).astype(np.uint8), "RGBA")
w = wreck.resize((round(site.width * 0.85), round(wreck.height * site.width * 0.85 / wreck.width)), Image.LANCZOS)
dmg = scorched.copy(); dmg.alpha_composite(w, ((site.width - w.width) // 2, max(0, site.height // 2 - w.height // 2)))
dmg.save(O / "pad_damaged.png")
print("wrote", *(f.name for f in sorted(O.glob("pad_*.png"))))
