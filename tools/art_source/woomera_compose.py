"""Woomera: paint bitumen roads, the runway and clearings on the clean outback ground, and compose a preview.

    python3 tools/art_source/woomera_compose.py OUT_DIR
Inputs are in ~/craft/in/woomera (ground_clean.png and the chosen cutouts).
"""
import sys, math, json
import numpy as np
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
from scipy.ndimage import binary_dilation, gaussian_filter
I = Path.home() / "craft/in/woomera"
O = Path(sys.argv[1]); O.mkdir(parents=True, exist_ok=True)
G = np.asarray(Image.open(Path(__file__).with_name("woomera_ground_empty.png")).convert("RGB")).astype(float)
H, W = G.shape[:2]
yy, xx = np.mgrid[0:H, 0:W]

# The empty ground painting is already clean (tracks inpainted).
clean = G.copy()
Image.fromarray(np.clip(clean, 0, 255).astype(np.uint8)).save(O / "ground_clean.png")

# --- layout: bottom-centre x, base y, width --------------------------------------------
ROADS = json.loads((Path(__file__).with_name("woomera_roads_clean.json")).read_text())

def width(y): return 15 + 13 * max(0, min(1, (y - 200) / 880))

def draw_road(dd, pts, half):
    """A road as tapered segment quads plus a circle at every vertex whose radius equals
    the road's half-width there: rounded corners and ends, no mismatch lumps."""
    import math
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        dx, dy = x1 - x0, y1 - y0; m = math.hypot(dx, dy) or 1; nx, ny = -dy / m, dx / m
        h0, h1 = half(y0), half(y1)
        quad = [(x0 + nx * h0, y0 + ny * h0), (x1 + nx * h1, y1 + ny * h1), (x1 - nx * h1, y1 - ny * h1), (x0 - nx * h0, y0 - ny * h0)]
        dd.polygon([(x * K, y * K) for x, y in quad], fill=255)
    for x, y in pts:
        h = half(y); dd.ellipse([(x - h) * K, (y - h) * K, (x + h) * K, (y + h) * K], fill=255)

K = 4
# --- runway: corners taken from the user's PhotoCraft layer (2026-10-16): a slanted-ended
# strip running off the left edge and widening toward the viewer; no taxiway.
RW_QUAD = [(-20, 129), (611, 540), (525, 626), (-20, 232)]           # TL, TR, BR, BL: off the left edge (player's layer, 2026-10-16)
def _rw_mid():
    (tl, tr, br, bl) = RW_QUAD
    far = ((tl[0] + bl[0]) / 2, (tl[1] + bl[1]) / 2); near = ((tr[0] + br[0]) / 2, (tr[1] + br[1]) / 2)
    dx, dy = near[0] - far[0], near[1] - far[1]; L = math.hypot(dx, dy)
    return far, near, (dx / L, dy / L), L
def runway_poly(grow=0.0):
    cx = sum(x for x, _ in RW_QUAD) / 4; cy = sum(y for _, y in RW_QUAD) / 4
    return [(cx + (x - cx) * (1 + grow), cy + (y - cy) * (1 + grow)) for x, y in RW_QUAD]
def runway_marks(dd):
    """Centreline dashes along the midline and threshold bars across the near end."""
    far, near, d, L = _rw_mid(); (tl, tr, br, bl) = RW_QUAD
    t = 0.08
    while t < 0.86:
        a = (far[0] + d[0]*L*t, far[1] + d[1]*L*t); b = (far[0] + d[0]*L*(t + 0.035 + 0.02*t), far[1] + d[1]*L*(t + 0.035 + 0.02*t))
        dd.line([(a[0]*K, a[1]*K), (b[0]*K, b[1]*K)], fill=255, width=int((1.2 + 1.8*t)*K))
        t += 0.08 + 0.03 * t
    ex, ey = tr[0] - br[0], tr[1] - br[1]                      # the near-end edge direction
    for k in (-3, -2, -1, 1, 2, 3):
        for s in (0.925, 0.965):
            P = (far[0] + d[0]*L*s + ex*k*0.11, far[1] + d[1]*L*s + ey*k*0.11)
            Q = (P[0] + d[0]*L*0.025, P[1] + d[1]*L*0.025)
            dd.line([(P[0]*K, P[1]*K), (Q[0]*K, Q[1]*K)], fill=255, width=int(3.5*K))
TAXI = []
rw = Image.new("L", (W * K, H * K), 0); drw = ImageDraw.Draw(rw)
drw.polygon([(x*K, y*K) for x, y in runway_poly()], fill=255)
rwe = Image.new("L", (W * K, H * K), 0); drwe = ImageDraw.Draw(rwe)
drwe.polygon([(x*K, y*K) for x, y in runway_poly(0.03)], fill=255)
rwm = Image.new("L", (W * K, H * K), 0); runway_marks(ImageDraw.Draw(rwm))
road = Image.new("L", (W * K, H * K), 0); dr = ImageDraw.Draw(road)
edge = Image.new("L", (W * K, H * K), 0); de = ImageDraw.Draw(edge)
for pts in TAXI:
    for dd, extra in ((de, 3.0), (dr, 0.0)):
        draw_road(dd, pts, lambda y: width(y) * 0.85 / 2 + extra)
for item in ROADS["roads"]:
    pts = [tuple(p) for p in item["pts"]]; f = item.get("w", 1.0)
    for dd, extra in ((de, 3.0), (dr, 0.0)):
        draw_road(dd, pts, lambda y: width(y) * f / 2 + extra)
for cx, cy, rx, ry in ROADS.get("circles", []):
    de.ellipse([(cx - rx - 3) * K, (cy - ry - 3) * K, (cx + rx + 3) * K, (cy + ry + 3) * K], fill=255)
    dr.ellipse([(cx - rx) * K, (cy - ry) * K, (cx + rx) * K, (cy + ry) * K], fill=255)
for poly in ROADS["areas"]:
    c = (sum(p[0] for p in poly) / len(poly), sum(p[1] for p in poly) / len(poly))
    grow = [(c[0] + (x - c[0]) * 1.0 + (1.5 if x > c[0] else -1.5), c[1] + (y - c[1]) + (1.5 if y > c[1] else -1.5)) for x, y in poly]
    de.polygon([(x * K, y * K) for x, y in grow], fill=255)
    dr.polygon([(x * K, y * K) for x, y in poly], fill=255)
MASKP = Path(__file__).with_name("baikonur_roads_mask.png")
if False and MASKP.exists():
    _m = Image.open(MASKP).convert("L").resize((W * K, H * K), Image.LANCZOS)
    _mr = _m.point(lambda v: 255 if v > 128 else 0)
    road = Image.fromarray(np.maximum(np.asarray(road), np.asarray(_mr)))
    _me = _mr.filter(ImageFilter.MaxFilter(2 * 3 * K + 1))
    edge = Image.fromarray(np.maximum(np.asarray(edge), np.asarray(_me)))
def down(im): return np.asarray(im.resize((W, H), Image.LANCZOS).filter(ImageFilter.GaussianBlur(0.6))).astype(float) / 255
rm, em = down(road), down(edge)
rwm_, rwe_, rwk_ = down(rw), down(rwe), down(rwm)
sky = gaussian_filter((G[..., 2] > G[..., 0] + 40).astype(float), 1.5)   # keep paving off the sky
for _a in (rm, em, rwm_, rwe_, rwk_): _a *= (1 - sky)
FILL = np.array([128, 122, 118.0]); EDGE = np.array([88, 82, 78.0])
noise = (np.asarray(Image.effect_noise((W, H), 20).convert("L").filter(ImageFilter.GaussianBlur(0.7))).astype(float) - 128) * 0.05
shadow = gaussian_filter(em, 2.5)[..., None] * 0.18
RW_FILL = np.array([96, 98, 108.0]); RW_EDGE = np.array([70, 72, 82.0]); RW_MARK = np.array([222, 222, 214.0])
bg = clean * (1 - shadow - gaussian_filter(rwe_, 2.5)[..., None] * 0.18)
bg = bg * (1 - rwe_[..., None]) + RW_EDGE * rwe_[..., None]
bg = bg * (1 - rwm_[..., None]) + (RW_FILL + noise[..., None] * 1.5) * rwm_[..., None]
mk = (rwk_ * rwm_)[..., None] * 0.85
bg = bg * (1 - mk) + RW_MARK * mk
bg = bg * (1 - em[..., None]) + EDGE * em[..., None]
bg = bg * (1 - rm[..., None]) + (FILL + noise[..., None]) * rm[..., None]
Image.fromarray(np.clip(bg, 0, 255).astype(np.uint8)).save(O / "bg_spring.png")

# --- layers for hand editing in PhotoCraft: full-frame RGBA PNGs --------------------------
LAY = Path.home() / "craft/in/woomera/layers"; LAY.mkdir(parents=True, exist_ok=True)
Image.fromarray(np.clip(clean, 0, 255).astype(np.uint8)).save(LAY / "00_ground.png")
def rgba_layer(fill_m, edge_m, fill_c, edge_c, marks=None, mark_c=None):
    a = np.clip(np.maximum(fill_m, edge_m), 0, 1)
    col = edge_c * (1 - fill_m[..., None]) + fill_c * fill_m[..., None]
    if marks is not None: col = col * (1 - marks[..., None]) + mark_c * marks[..., None]
    out = np.concatenate([np.clip(col, 0, 255), a[..., None] * 255], axis=2)
    return Image.fromarray(out.astype(np.uint8), "RGBA")
rgba_layer(rm, em, FILL, EDGE).save(LAY / "01_roads.png")
rgba_layer(rwm_, rwe_, RW_FILL, RW_EDGE, (rwk_ * rwm_) * 0.85, RW_MARK).save(LAY / "01_runway.png")

# --- preview composite ------------------------------------------------------------------
comp = Image.open(O / "bg_spring.png").convert("RGBA")
PL = json.loads((Path(__file__).with_name("woomera_place.json")).read_text())
for e in PL:
    bx, by, bw, bh = e["box"]
    if not (I / e["file"]).exists():
        print("missing", e["file"]); continue
    t0 = Image.open(I / e["file"]).convert("RGBA")
    sc = min(bw / t0.width, bh / t0.height); e["w"], e["h"] = max(1, round(t0.width * sc)), max(1, round(t0.height * sc))
    e["x"], e["y"] = round(bx + (bw - e["w"]) / 2), round(by + bh - e["h"])     # sit on the box's base line
for e in sorted([e for e in PL if "w" in e], key=lambda e: e["y"] + e["h"]):
    t = Image.open(I / e["file"]).convert("RGBA")
    if e.get("flip"): t = t.transpose(Image.FLIP_LEFT_RIGHT)
    comp.alpha_composite(t.resize((e["w"], e["h"]), Image.LANCZOS), (e["x"], e["y"]))
    lay = Image.new("RGBA", (W, H), (0, 0, 0, 0)); lay.alpha_composite(t.resize((e["w"], e["h"]), Image.LANCZOS), (e["x"], e["y"]))
    lay.save(LAY / f"10_{e['id']}.png")
comp.convert("RGB").save(O / "preview.png")
print("ok")
