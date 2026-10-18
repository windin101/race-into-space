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
ap.add_argument("--wreck", type=int, default=-1, help="-1: topple the gantry across the scorched platform instead")
ap.add_argument("--unslab", action="store_true", help="key out a sand slab under the gantry")
ap.add_argument("--gantry-scale", type=float, default=0.95)
ap.add_argument("--gantry-dx", type=int, default=70, help="gantry foot offset from the platform centre, px")
ap.add_argument("--gantry-dy", type=int, default=-40, help="gantry foot offset from the platform centre, px")
a = ap.parse_args()
P, O = Path(a.parts), Path(a.out); O.mkdir(parents=True, exist_ok=True)

def tight(im):
    bb = im.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()
    return im.crop(bb) if bb else im

def defire(im):
    """The generator lights every flame pit: repaint the fire and its outline as the pit's dark grey."""
    import cv2
    arr = np.asarray(im).astype(int); r, g, b = arr[..., 0], arr[..., 1], arr[..., 2]
    fire = ((r > 150) & (r - b > 90) & (arr[..., 3] > 0)).astype(np.uint8)
    near = cv2.dilate(fire, np.ones((9, 9), np.uint8)) > 0
    dark = arr[..., :3].max(-1) < 200
    arr[(fire > 0) | (near & dark), :3] = (52, 54, 60)
    return Image.fromarray(arr.astype(np.uint8), "RGBA")

def unslab(im):
    """Keep only the tower: white and grey girders (neutral or cool) and red bands. Drops the sand
    slab, its outline and the warm shadow the generator stands every tower on."""
    import cv2
    arr = np.asarray(im).copy(); c = arr[..., :3].astype(int); r, g, b = c[..., 0], c[..., 1], c[..., 2]
    mx, mn = c.max(-1), c.min(-1)
    girder = ((mx - mn < 40) & (b >= g - 8) & (mx > 110)) | ((mn > 195) & (mx - mn < 45))   # grey steel, lit white paint
    red = (r > 140) & (r - g > 60)
    keep = ((girder | red) & (arr[..., 3] > 40)).astype(np.uint8)
    keep = cv2.morphologyEx(keep, cv2.MORPH_CLOSE, np.ones((5, 5), np.uint8))
    n, lab, st, _ = cv2.connectedComponentsWithStats(keep)
    if n > 1:
        keep = (lab == 1 + int(np.argmax(st[1:, 4]))).astype(np.uint8)
    alpha = cv2.GaussianBlur(cv2.dilate(keep, np.ones((3, 3), np.uint8)).astype(np.float32), (3, 3), 0)
    arr[..., 3] = (np.minimum(arr[..., 3], alpha * 255)).astype(np.uint8)
    return Image.fromarray(arr, "RGBA")

site = defire(tight(Image.open(P / f"platform_{a.platform}.png").convert("RGBA")))
gantry = tight(Image.open(P / f"gantry_{a.gantry}.png").convert("RGBA"))
if a.unslab:
    gantry = tight(unslab(gantry))
wreck = None if a.wreck < 0 else tight(Image.open(P / f"gantry_wreck_{a.wreck}.png").convert("RGBA"))
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
if wreck is None:
    # the tower fallen across the pad: rotated nearly flat, darkened, laid along the diagonal
    fallen = gantry.resize((round(gantry.width * a.gantry_scale), round(gantry.height * a.gantry_scale)), Image.LANCZOS)
    fallen = fallen.rotate(-72, resample=Image.BICUBIC, expand=True)
    fallen = ImageEnhance.Brightness(fallen).enhance(0.62)
    sc = min(1.0, site.width * 1.05 / fallen.width); fallen = fallen.resize((round(fallen.width * sc), round(fallen.height * sc)), Image.LANCZOS)
    w = fallen
else:
    w = wreck.resize((round(site.width * 0.85), round(wreck.height * site.width * 0.85 / wreck.width)), Image.LANCZOS)
dmg = scorched.copy(); dmg.alpha_composite(w, ((site.width - w.width) // 2, max(0, site.height // 2 - w.height // 2)))
dmg.save(O / "pad_damaged.png")
print("wrote", *(f.name for f in sorted(O.glob("pad_*.png"))))
