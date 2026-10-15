#!/usr/bin/env python3
"""Lay out the spaceport buildings on each side's painting so they sit on clear ground,
beside the roads, at a size that matches their depth in the scene.

    python3 -I tools/spaceport_layout.py            # write the per-side layout + previews
    python3 -I tools/spaceport_layout.py --preview-only

For each side it reads the spring background and every building cutout, builds a mask of
what a building's base must not stand on (roads, tracks, water, sky, the foreground and
the UI bars), then places buildings in priority order: each starts at an intended spot
(INTENT below, hand-chosen per painting) and moves to the nearest valid position, scored
for staying close to that intent and close to (but off) a road. Width shrinks toward the
horizon; height comes from the cutout's own aspect, so the hotspot box and the drawn
building agree exactly. Output: the "sides" block of game/data/ui/spaceport_layout.json
(x, y, w, h per building id, as canvas fractions) and preview PNGs in the scratch folder
given by --preview-dir (default reference/layout_preview/).
"""

import argparse
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "game"
LAYOUT = GAME / "data" / "ui" / "spaceport_layout.json"
W, H = 960, 540                      # analysis resolution (half the design canvas)

# Width at the front of the scene, as a fraction of the canvas width. Shrinks with depth.
BASE_W = {
    "administration": 0.165, "programs": 0.155, "research": 0.115,
    "astronaut_complex": 0.165, "training": 0.135, "vab": 0.175,
    "mission_control": 0.13, "museum": 0.155, "intelligence": 0.095,
    "pad_1": 0.17, "pad_2": 0.17, "pad_3": 0.17, "runway": 0.22,
}
# Placement order: big and fussy first.
ORDER = ["pad_1", "pad_2", "pad_3", "vab", "mission_control", "administration", "research",
         "programs", "astronaut_complex", "training", "museum", "intelligence", "runway"]

# Intended spot per side: (x, bottom-y) as canvas fractions, chosen by looking at the
# paintings. The solver moves each building to the nearest clear ground.
INTENT = {
    # Cape Canaveral. The main road runs from the west edge down to the crossroads at the
    # bottom right; the HQ campus straddles it, operations sit inland of the launch field,
    # the pads march up the coast, the museum faces the crossroads.
    "usa": {
        "pad_1": (0.58, 0.555), "pad_2": (0.72, 0.60), "pad_3": (0.86, 0.645),
        "vab": (0.62, 0.69), "mission_control": (0.47, 0.775),
        "administration": (0.17, 0.72), "research": (0.31, 0.655), "programs": (0.30, 0.835),
        "astronaut_complex": (0.12, 0.925), "training": (0.45, 0.93),
        "museum": (0.88, 0.915), "intelligence": (0.72, 0.84),
        "runway": (0.72, 0.70),
    },
    # Baikonur. A dirt track crosses the steppe; the paved road runs from the town out to
    # the east. Town on the left, assembly and control by the road, pads out on the plain.
    "ussr": {
        "pad_1": (0.55, 0.535), "pad_2": (0.70, 0.55), "pad_3": (0.85, 0.565),
        "vab": (0.62, 0.69), "mission_control": (0.40, 0.765),
        "administration": (0.15, 0.62), "research": (0.33, 0.605), "programs": (0.25, 0.80),
        "astronaut_complex": (0.11, 0.835), "training": (0.56, 0.835),
        "museum": (0.81, 0.745), "intelligence": (0.95, 0.70),
        "runway": (0.60, 0.53),
    },
    # Woomera. Two dirt roads cross in the middle of the red plain, a salt lake beyond.
    # Pads stand in a line out toward the lake behind the crossroads; offices in the left
    # quarter, assembly and control in the right, crew facilities and museum in front.
    "cwth": {
        "pad_1": (0.45, 0.62), "pad_2": (0.57, 0.575), "pad_3": (0.68, 0.535),
        "vab": (0.76, 0.70), "mission_control": (0.91, 0.69),
        "administration": (0.12, 0.70), "research": (0.25, 0.64), "programs": (0.37, 0.725),
        "astronaut_complex": (0.40, 0.90), "training": (0.62, 0.90),
        "museum": (0.84, 0.91), "intelligence": (0.95, 0.60),
    },
}
# Hand-placed positions that bypass the solver: (centre x, centre y of the cutout) as canvas
# fractions. Cape pads 2 and 3 stand in an evenly spaced line behind pad 1 up the coast,
# as marked by the player on the painting.
FIXED = {
    "usa": {"pad_2": (0.726, 0.457), "pad_3": (0.887, 0.420)},
    "ussr": {},
    "cwth": {},
}
# Hand-placed boxes that replace the solver for a whole side: (x, y, w, h) as canvas
# fractions, each the full trimmed cutout. All three sites follow the player's mock-ups of
# 2026-10-13/14 (the Cape redone at one camera angle on 2026-10-15) (measured by template-matching the cutouts in them), with buildings that
# fell under the bottom bar lifted to end at 0.945; "flag" moves the flag.
MANUAL = {
    "usa": {
        "vab": (0.3682, 0.1741, 0.1313, 0.1861),
        "mission_control": (0.5911, 0.4491, 0.1000, 0.1259),
        "administration": (0.4448, 0.5769, 0.1307, 0.1509),
        "research": (0.5911, 0.6907, 0.1260, 0.1685),
        "programs": (0.3297, 0.6139, 0.0891, 0.1028),
        "astronaut_complex": (0.0813, 0.6139, 0.1469, 0.1694),
        "training": (0.2302, 0.4056, 0.1208, 0.1333),
        "museum": (0.2745, 0.7880, 0.1260, 0.1537),
        "intelligence": (0.4865, 0.4352, 0.0729, 0.0972),
        "memorial": (0.5443, 0.8926, 0.0370, 0.0500),
        "pad_1": (0.6453, 0.3380, 0.0917, 0.1213),
        "pad_2": (0.7464, 0.4602, 0.0969, 0.1278),
        "pad_3": (0.8406, 0.6139, 0.1021, 0.1352),
        "runway": (0.1349, 0.2380, 0.0792, 0.0833),
        "flag": (0.5016, 0.8213, 0.0312, 0.0537),
        "capital": (0.6776, 0.1647, 0.0302, 0.0409),
        "moon": (0.0781, 0.0370, 0.0448, 0.0796),
    },
    "ussr": {
        "pad_1": (0.0073, 0.3916, 0.1158, 0.1579),
        "pad_2": (0.1601, 0.3879, 0.1158, 0.1579),
        "pad_3": (0.3073, 0.3869, 0.1158, 0.1579),
        "vab": (0.4778, 0.5065, 0.1690, 0.1813),
        "mission_control": (0.5509, 0.7364, 0.0720, 0.1318),
        "administration": (0.8273, 0.6374, 0.1721, 0.1682),
        "research": (0.6427, 0.8009, 0.0438, 0.0888),
        "programs": (-0.0141, 0.7178, 0.1977, 0.1364),
        "astronaut_complex": (0.0861, 0.5729, 0.1455, 0.1271),
        "training": (0.2295, 0.6374, 0.1142, 0.1206),
        "museum": (0.6875, 0.6112, 0.1299, 0.1318),
        "intelligence": (0.8826, 0.7786, 0.1017, 0.1664),
        "runway": (0.8148, 0.4664, 0.1534, 0.1776),
        "flag": (0.6886, 0.4692, 0.0939, 0.1645),
        "moon": (0.6200, 0.1300, 0.0450, 0.0800),
        "memorial": (0.4000, 0.7216, 0.0400, 0.0784),
        "capital": (0.8710, 0.3574, 0.0280, 0.0946),
    },
    "cwth": {
        "pad_1": (0.5838, 0.3638, 0.1044, 0.1297),
        "pad_2": (0.7269, 0.3629, 0.0950, 0.1175),
        "pad_3": (0.8559, 0.3629, 0.0841, 0.1045),
        "vab": (0.4470, 0.4235, 0.1561, 0.1875),
        "mission_control": (0.4736, 0.7136, 0.1044, 0.1800),
        "administration": (0.7890, 0.6297, 0.1546, 0.1828),
        "research": (0.6650, 0.7540, 0.1150, 0.1505),
        "programs": (0.2351, 0.4595, 0.1679, 0.1267),
        "astronaut_complex": (0.0120, 0.6325, 0.1561, 0.1474),
        "training": (0.2131, 0.5914, 0.1044, 0.1362),
        "museum": (0.6679, 0.6119, 0.1044, 0.1054),
        "intelligence": (0.8977, 0.4813, 0.0935, 0.1250),
        "runway": (0.0000, 0.3703, 0.1608, 0.2332),
        "flag": (0.5692, 0.7211, 0.0919, 0.1576),
        "moon": (0.3000, 0.1100, 0.0450, 0.0800),
        "memorial": (0.6175, 0.5241, 0.0350, 0.0779),
        "capital": (0.2000, 0.2619, 0.0300, 0.1001),
    },
}
# Sites painted as one scene: an unbuilt building shows bare ground, not a plot outline.
NO_PLOTS = {"usa"}
FRONT_Y = {"usa": 0.93, "ussr": 0.84, "cwth": 0.93}    # below this is foreground (dunes, scrub mound)
GAP = 8                                 # pixels at analysis scale between buildings


def avoid_mask(side: str, img: np.ndarray, horizon: float) -> np.ndarray:
    r, g, b = img[..., 0], img[..., 1], img[..., 2]
    mx, mn = img.max(-1), img.min(-1)
    sat = mx - mn
    road = (sat < 22) & (mx > 150)
    if side == "ussr":
        road |= (r > g) & (g > b) & (r - b > 35) & (r - b < 90) & (mx > 170)
        road |= (r > g + 10) & (g > b) & (mx < 150) & (r - b > 30)   # brown earth
    if side == "cwth":
        road |= _pale_track(r, g, b)
    water = (b > r + 25) & (b > g)
    m = road | water
    ys = np.arange(H)[:, None] / H
    m |= ys < horizon + 0.03
    m |= ys > FRONT_Y[side]
    m |= ys > (1080 - 56) / 1080 - 0.005          # bottom bar
    return m


def road_only(side: str, img: np.ndarray) -> np.ndarray:
    r, g, b = img[..., 0], img[..., 1], img[..., 2]
    mx, mn = img.max(-1), img.min(-1)
    road = ((mx - mn) < 22) & (mx > 150)
    if side == "ussr":
        road |= (r > g) & (g > b) & (r - b > 35) & (r - b < 90) & (mx > 170)
    if side == "cwth":
        road |= _pale_track(r, g, b)
    return road


def _pale_track(r, g, b):
    """Woomera's dirt roads: pale peach against the red earth."""
    return (r > 225) & (g > 170) & (b > 140) & (r - b > 30)


def horizon_of(img: np.ndarray) -> float:
    r, g, b = img[..., 0], img[..., 1], img[..., 2]
    sky = (b > r + 25) & (b > g)
    rows = sky.mean(1)
    for i, v in enumerate(rows):
        if v < 0.5:
            return i / H
    return 0.4


def distance_to(mask: np.ndarray) -> np.ndarray:
    """Cheap Euclidean-ish distance transform (two-pass chamfer)."""
    INF = 10 ** 6
    d = np.where(mask, 0, INF).astype(np.int64)
    h, w = d.shape
    for y in range(h):
        row = d[y]
        if y > 0:
            row = np.minimum(row, d[y - 1] + 3)
        for x in range(1, w):
            if row[x - 1] + 3 < row[x]:
                row[x] = row[x - 1] + 3
        d[y] = row
    for y in range(h - 1, -1, -1):
        row = d[y]
        if y < h - 1:
            row = np.minimum(row, d[y + 1] + 3)
        for x in range(w - 2, -1, -1):
            if row[x + 1] + 3 < row[x]:
                row[x] = row[x + 1] + 3
        d[y] = row
    return d / 3.0


def cutout_for(side: str, bid: str) -> Image.Image:
    if bid == "moon":                     # shared with the mission diagrams
        return Image.open(GAME / "assets" / "art" / "diagram" / "moon.png").convert("RGBA")
    name = "pad_ok" if bid.startswith("pad_") else "building_" + bid
    return Image.open(GAME / "assets" / "art" / "spaceport" / side / f"{name}.png").convert("RGBA")


def size_at(side: str, bid: str, bottom: float, horizon: float, aspect: float) -> tuple:
    t = (bottom - horizon) / (FRONT_Y[side] - horizon)
    s = 0.30 + 0.70 * min(max(t, 0.0), 1.0) ** 0.9
    w = BASE_W[bid] * s
    h = w * aspect * (1920 / 1080)
    return w, h


def solve(side: str) -> dict:
    if side in MANUAL:
        bg = Image.open(GAME / "assets" / "art" / "spaceport" / side / "background_spring.png").convert("RGB").resize((W, H))
        boxes = {k: {"x": v[0], "y": v[1], "w": v[2], "h": v[3]} for k, v in MANUAL[side].items()}
        flag = boxes.pop("flag", None)
        out = {"horizon": round(horizon_of(np.asarray(bg).astype(int)), 3), "buildings": boxes}
        if flag:
            out["flag"] = flag
        return out
    bg = Image.open(GAME / "assets" / "art" / "spaceport" / side / "background_spring.png").convert("RGB").resize((W, H))
    img = np.asarray(bg).astype(int)
    horizon = horizon_of(img)
    avoid = avoid_mask(side, img, horizon)
    road_d = distance_to(road_only(side, img) & (np.arange(H)[:, None] / H > horizon + 0.02))
    taken = np.zeros((H, W), dtype=bool)
    out = {}
    for bid in ORDER:
        cut = cutout_for(side, bid)
        bbox = cut.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()
        cw, chh = (bbox[2] - bbox[0], bbox[3] - bbox[1]) if bbox else cut.size
        aspect = chh / cw
        ix, iy = INTENT[side][bid]
        if bid in FIXED[side]:
            fx, fy = FIXED[side][bid]
            by = fy
            for _ in range(6):                     # base y and size depend on each other
                w, h = size_at(side, bid, by, horizon, aspect)
                by = fy + h / 2
            x0, y0 = fx - w / 2, by - h
            taken[max(0, int(y0 * H)):int(by * H), max(0, int(x0 * W)):int((x0 + w) * W)] = True
            out[bid] = {"x": round(x0, 4), "y": round(y0, 4), "w": round(w, 4), "h": round(h, 4)}
            continue
        best = None
        # Widen the search in stages, then allow the building to shrink a little, rather
        # than ever falling back onto a neighbour.
        for rx, ry, shrink in [(0.05, 0.035, 1.0), (0.09, 0.06, 0.92), (0.14, 0.08, 0.84), (0.20, 0.10, 0.76)]:
            for dy in np.linspace(-ry, ry, 31):
                for dx in np.linspace(-rx, rx, 41):
                    cx, by = ix + dx, iy + dy
                    w, h = size_at(side, bid, by, horizon, aspect)
                    w, h = w * shrink, h * shrink
                    x0, x1 = cx - w / 2, cx + w / 2
                    y0 = by - h
                    if x0 < 0.01 or x1 > 0.99 or y0 < horizon - 0.02 or by > FRONT_Y[side]:
                        continue
                    px0, px1 = int(x0 * W), int(x1 * W)
                    py1 = int(by * H)
                    base_top = int((by - h * 0.32) * H)        # the footprint: lower third
                    if px1 <= px0 or py1 <= base_top:
                        continue
                    if avoid[base_top:py1, px0:px1].mean() > 0.02:
                        continue
                    gy0, gy1 = max(0, int(y0 * H) - GAP), min(H, py1 + GAP)
                    gx0, gx1 = max(0, px0 - GAP), min(W, px1 + GAP)
                    if taken[gy0:gy1, gx0:gx1].any():
                        continue
                    if bid in ("pad_2", "pad_3"):
                        prev = out.get("pad_1" if bid == "pad_2" else "pad_2")
                        if prev and cx < prev["x"] + prev["w"] * 0.9:
                            continue
                    dist = road_d[min(H - 1, py1 + 2), min(W - 1, int(cx * W))] if bid != "intelligence" else 30
                    road_pen = 0.0 if 6 <= dist <= 45 else (abs(dist - 25) / 25.0)
                    score = math.hypot(dx * 1.6, dy * 3.0) * 10 + road_pen * (2.0 if bid.startswith("pad_") else 1.0) + (1 - shrink) * 20
                    if best is None or score < best[0]:
                        best = (score, x0, y0, w, h)
            if best is not None:
                break
        if best is None:
            raise SystemExit(f"{side}: nowhere to put {bid}; adjust INTENT or BASE_W")
        _, x0, y0, w, h = best
        taken[max(0, int(y0 * H)):int((y0 + h) * H), max(0, int(x0 * W)):int((x0 + w) * W)] = True
        out[bid] = {"x": round(x0, 4), "y": round(y0, 4), "w": round(w, 4), "h": round(h, 4)}
    return {"horizon": round(horizon, 3), "buildings": out}


def preview(side: str, layout: dict, path: Path, boxes: bool) -> None:
    bg = Image.open(GAME / "assets" / "art" / "spaceport" / side / "background_spring.png").convert("RGBA").resize((1920, 1080))
    items = sorted(layout["buildings"].items(), key=lambda kv: kv[1]["y"] + kv[1]["h"])
    dr = ImageDraw.Draw(bg)
    for bid, r in items:
        cut = cutout_for(side, bid)
        bbox = cut.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()
        if bbox:
            cut = cut.crop(bbox)
        w, h = int(r["w"] * 1920), int(r["h"] * 1080)
        cut = cut.resize((max(1, w), max(1, h)), Image.LANCZOS)
        bg.alpha_composite(cut, (int(r["x"] * 1920), int(r["y"] * 1080)))
        if boxes:
            dr.rectangle([r["x"] * 1920, r["y"] * 1080, (r["x"] + r["w"]) * 1920, (r["y"] + r["h"]) * 1080], outline=(255, 0, 0, 255), width=2)
            dr.text((r["x"] * 1920 + 3, r["y"] * 1080 + 3), bid, fill=(255, 255, 0, 255))
    bg.convert("RGB").save(path)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--preview-only", action="store_true")
    ap.add_argument("--preview-dir", default=str(ROOT / "reference" / "layout_preview"))
    ap.add_argument("--boxes", action="store_true")
    a = ap.parse_args()
    out_dir = Path(a.preview_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    data = json.loads(LAYOUT.read_text())
    sides = {}
    for side in [x["id"] for x in json.loads((ROOT / "game" / "data" / "sides.json").read_text())["sides"]]:
        sides[side] = solve(side)
        preview(side, sides[side], out_dir / f"preview_{side}.png", a.boxes)
        print(f"{side}: horizon {sides[side]['horizon']}, preview {out_dir / f'preview_{side}.png'}")
    if not a.preview_only:
        data["sides"] = {s: {k: v[k] for k in ("buildings", "flag") if k in v} for s, v in sides.items()}
        for s in NO_PLOTS:
            if s in data["sides"]:
                data["sides"][s]["plots"] = False
        LAYOUT.write_text(json.dumps(data, indent=2) + "\n")
        print(f"wrote {LAYOUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
