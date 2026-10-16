"""Tidy the traced Baikonur road network into straight runs and smooth arcs.

    python3 tools/art_source/baikonur_tidy_roads.py [debug.png]
Reads baikonur_roads.json (raw trace + hand roads), writes baikonur_roads_clean.json:
  * each road simplified (RDP) to a handful of control points,
  * endpoints snapped onto the nearest other road so junctions meet,
  * near-collinear vertices dropped, remaining corners replaced by circular fillets,
  * areas rebuilt as clean isometric parallelograms.
"""
import sys, json, math
from pathlib import Path
import numpy as np
HERE = Path(__file__).parent
RAW = json.loads((HERE / "baikonur_roads.json").read_text())
RDP_EPS, SNAP, FILLET_R, COLL_DEG = 16.0, 48.0, 46.0, 8.0

def rdp(pts, eps):
    if len(pts) < 3: return pts
    a, b = np.array(pts[0]), np.array(pts[-1]); d = b - a; n = np.hypot(*d) or 1
    dist = [abs((p[0]-a[0])*d[1] - (p[1]-a[1])*d[0]) / n for p in pts]
    i = int(np.argmax(dist))
    if dist[i] > eps: return rdp(pts[:i+1], eps)[:-1] + rdp(pts[i:], eps)
    return [pts[0], pts[-1]]

def seg_nearest(p, a, b):
    a, b, p = map(np.array, (a, b, p)); d = b - a; L2 = float(d @ d) or 1
    t = max(0.0, min(1.0, float((p - a) @ d) / L2)); q = a + t * d
    return q, float(np.hypot(*(p - q))), t

def drop_collinear(pts):
    out = [pts[0]]
    for i in range(1, len(pts) - 1):
        a, b, c = np.array(out[-1]), np.array(pts[i]), np.array(pts[i+1])
        u, v = b - a, c - b
        ang = abs(math.degrees(math.atan2(u[0]*v[1]-u[1]*v[0], u @ v)))
        if ang > COLL_DEG: out.append(pts[i])
    out.append(pts[-1]); return out

def fillet(pts, R):
    """Replace every interior corner with a circular arc tangent to both legs."""
    if len(pts) < 3: return pts
    out = [pts[0]]
    for i in range(1, len(pts) - 1):
        a, b, c = np.array(out[-1] if i == 1 else pts[i-1]), np.array(pts[i]), np.array(pts[i+1])
        u, v = a - b, c - b; lu, lv = np.hypot(*u), np.hypot(*v); u, v = u/lu, v/lv
        theta = math.acos(max(-1, min(1, float(u @ v))))        # interior angle
        if theta > math.radians(180 - COLL_DEG): out.append(tuple(b)); continue
        r = min(R, 0.45 * lu, 0.45 * lv); t = r / math.tan(theta / 2)
        p0, p1 = b + u * t, b + v * t
        bis = (u + v); bis /= np.hypot(*bis); centre = b + bis * (r / math.sin(theta / 2))
        a0 = math.atan2(*(p0 - centre)[::-1]); a1 = math.atan2(*(p1 - centre)[::-1])
        da = (a1 - a0 + math.pi) % (2*math.pi) - math.pi
        n = max(3, int(abs(da) * r / 6))
        for k in range(n + 1):
            ang = a0 + da * k / n; out.append((centre[0] + r*math.cos(ang), centre[1] + r*math.sin(ang)))
    out.append(pts[-1]); return out

roads = [{"pts": [tuple(p) for p in r["pts"]], "w": r.get("w", 1.0)} for r in RAW["roads"]]
for r in roads: r["pts"] = drop_collinear(rdp(r["pts"], RDP_EPS))
# snap ends onto other roads (extend/trim the last leg so the junction meets)
for i, r in enumerate(roads):
    for end in (0, -1):
        p = r["pts"][end]; best = None
        for j, o in enumerate(roads):
            if j == i: continue
            for a, b in zip(o["pts"], o["pts"][1:]):
                q, d, t = seg_nearest(p, a, b)
                if d < SNAP and (best is None or d < best[0]): best = (d, tuple(q))
        if best and best[0] > 0.5: r["pts"][end] = best[1]
for r in roads: r["pts"] = [tuple(map(float, p)) for p in fillet(drop_collinear(r["pts"]), FILLET_R)]

A, B = np.array([0.873, 0.488]), np.array([0.877, -0.479])
areas = []
for poly in RAW["areas"]:
    if len(poly) == 4:                       # hand-authored quad: keep as drawn
        areas.append([tuple(map(float, q)) for q in poly]); continue
    P = np.array(poly, float); M = np.linalg.inv(np.stack([A, B], 1))
    uv = (M @ P.T).T; u0, u1 = uv[:, 0].min(), uv[:, 0].max(); v0, v1 = uv[:, 1].min(), uv[:, 1].max()
    areas.append([tuple(map(float, A*u + B*v)) for u, v in ((u0, v0), (u1, v0), (u1, v1), (u0, v1))])
out = {"roads": roads, "areas": areas, "circles": RAW.get("circles", [])}
(HERE / "baikonur_roads_clean.json").write_text(json.dumps(out))
print(len(roads), "roads", sum(len(r["pts"]) for r in roads), "points")
if len(sys.argv) > 1:
    from PIL import Image, ImageDraw
    im = Image.new("RGB", (1920, 1080), "white"); d = ImageDraw.Draw(im)
    for r in roads:
        d.line(r["pts"], fill=(60, 60, 200), width=6)
        for p in r["pts"]: d.ellipse([p[0]-3, p[1]-3, p[0]+3, p[1]+3], fill=(200, 0, 0))
    for a in areas: d.polygon(a, outline=(0, 150, 0), width=3)
    im.save(sys.argv[1])
