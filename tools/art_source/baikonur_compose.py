"""Baikonur: clean the ground's tracks, paint grey roads and clearings, and compose a preview.

    python3 tools/art_source/baikonur_compose.py OUT_DIR
Inputs are in ~/craft/in/baikonur (ground_6.png and the chosen cutouts).
"""
import sys, math, json
import numpy as np
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
from scipy.ndimage import binary_dilation, gaussian_filter
I = Path.home() / "craft/in/baikonur"
O = Path(sys.argv[1]); O.mkdir(parents=True, exist_ok=True)
G = np.asarray(Image.open(Path(__file__).with_name("baikonur_ground_empty.png")).convert("RGB")).astype(float)
H, W = G.shape[:2]
yy, xx = np.mgrid[0:H, 0:W]

# --- clean the painted tracks: copy texture from beside them --------------------------
lum = G.mean(2)
med = gaussian_filter(lum, 6)
light = lum > med + 6
def band(pts, half):
    m = Image.new("L", (W, H), 0); d = ImageDraw.Draw(m)
    d.line(pts, fill=255, width=int(half * 2)); return np.asarray(m) > 0
diag = band([(1333, 205), (1173, 333), (1013, 480), (853, 600), (707, 720), (600, 820), (535, 900), (415, 1000), (300, 1090)], 44)
faint = band([(0, 347), (600, 300), (1200, 240), (1333, 213)], 12) | band([(0, 278), (700, 245), (1300, 215)], 10)
er = binary_dilation((diag | faint) & light, iterations=3) | binary_dilation(diag & (lum > med + 2), iterations=2)
er |= diag & (yy > 840)
def shift(dx, dy):
    xs = np.clip(np.arange(W) + dx, 0, W - 1); ys = np.clip(np.arange(H) + dy, 0, H - 1)
    return G[ys][:, xs]
src = np.where((faint & ~diag)[..., None], shift(0, 16), np.where((yy > 760)[..., None], shift(150, 0), shift(-70, 0)))
b = gaussian_filter(er.astype(float), 1.5)[..., None]
clean = G * (1 - b) + src * b
Image.fromarray(np.clip(clean, 0, 255).astype(np.uint8)).save(O / "ground_clean.png")

# --- layout: bottom-centre x, base y, width --------------------------------------------
ROADS = json.loads((Path(__file__).with_name("baikonur_roads.json")).read_text())

def width(y): return 10 + 8 * max(0, min(1, (y - 200) / 880))

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
road = Image.new("L", (W * K, H * K), 0); dr = ImageDraw.Draw(road)
edge = Image.new("L", (W * K, H * K), 0); de = ImageDraw.Draw(edge)
for item in ROADS["roads"]:
    pts = [tuple(p) for p in item["pts"]]; f = item.get("w", 1.0)
    for dd, extra in ((de, 3.0), (dr, 0.0)):
        draw_road(dd, pts, lambda y: width(y) * f / 2 + extra)
for poly in ROADS["areas"]:
    c = (sum(p[0] for p in poly) / len(poly), sum(p[1] for p in poly) / len(poly))
    grow = [(c[0] + (x - c[0]) * 1.0 + (1.5 if x > c[0] else -1.5), c[1] + (y - c[1]) + (1.5 if y > c[1] else -1.5)) for x, y in poly]
    de.polygon([(x * K, y * K) for x, y in grow], fill=255)
    dr.polygon([(x * K, y * K) for x, y in poly], fill=255)
def down(im): return np.asarray(im.resize((W, H), Image.LANCZOS).filter(ImageFilter.GaussianBlur(0.6))).astype(float) / 255
rm, em = down(road), down(edge)
FILL = np.array([132, 140, 162.0]); EDGE = np.array([92, 98, 116.0])
noise = (np.asarray(Image.effect_noise((W, H), 20).convert("L").filter(ImageFilter.GaussianBlur(0.7))).astype(float) - 128) * 0.05
shadow = gaussian_filter(em, 2.5)[..., None] * 0.18
bg = clean * (1 - shadow)
bg = bg * (1 - em[..., None]) + EDGE * em[..., None]
bg = bg * (1 - rm[..., None]) + (FILL + noise[..., None]) * rm[..., None]
Image.fromarray(np.clip(bg, 0, 255).astype(np.uint8)).save(O / "bg_spring.png")

# --- preview composite ------------------------------------------------------------------
comp = Image.open(O / "bg_spring.png").convert("RGBA")
PL = json.loads((Path(__file__).with_name("baikonur_place.json")).read_text())
for e in sorted(PL, key=lambda e: e["y"] + e["h"]):
    t = Image.open(I / e["file"]).convert("RGBA")
    if e.get("flip"): t = t.transpose(Image.FLIP_LEFT_RIGHT)
    comp.alpha_composite(t.resize((e["w"], e["h"]), Image.LANCZOS), (e["x"], e["y"]))
comp.convert("RGB").save(O / "preview.png")
print("ok")
