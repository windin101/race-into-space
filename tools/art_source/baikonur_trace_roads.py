"""Trace the original Baikonur road network (skeleton + fat areas from the original
screenshot) into clean polylines and polygons for baikonur_roads.json."""
import json, math, sys
import numpy as np, cv2
from PIL import Image
from pathlib import Path
from scipy.ndimage import label, distance_transform_edt, binary_opening
S = Path(sys.argv[1])
sk = np.asarray(Image.open(S / "sk.png")) > 0
H, W = sk.shape
pix = set(zip(*np.where(sk)))
def nbrs(p):
    y, x = p
    return [(y + dy, x + dx) for dy in (-1, 0, 1) for dx in (-1, 0, 1) if (dy or dx) and (y + dy, x + dx) in pix]
deg = {p: len(nbrs(p)) for p in pix}
nodes = {p for p, d in deg.items() if d != 2}
# merge node clusters (junction blobs of adjacent node pixels)
seen = set(); cluster = {}
for n in nodes:
    if n in seen: continue
    stack = [n]; group = []
    while stack:
        q = stack.pop()
        if q in seen: continue
        seen.add(q); group.append(q)
        stack += [r for r in nbrs(q) if r in nodes and r not in seen]
    cy = sum(p[0] for p in group) / len(group); cx = sum(p[1] for p in group) / len(group)
    for p in group: cluster[p] = (cx, cy)
# walk segments between node clusters
visited = set(); segs = []
for n in nodes:
    for m in nbrs(n):
        if m in nodes or (n, m) in visited: continue
        path = [cluster[n]]; prev, cur = n, m
        visited.add((n, m))
        while True:
            path.append((cur[1], cur[0]))
            nx = [r for r in nbrs(cur) if r != prev]
            if cur in nodes or not nx: break
            prev, cur = cur, nx[0]
            if cur in nodes:
                path.append(cluster[cur]); visited.add((cur, prev)); break
        segs.append(path)
def rdp(p, eps):
    if len(p) < 3: return p
    a, b = np.array(p[0]), np.array(p[-1]); v = b - a; L = np.linalg.norm(v) or 1
    d = [abs(v[0] * (q[1] - a[1]) - v[1] * (q[0] - a[0])) / L for q in p[1:-1]]
    i = int(np.argmax(d)) + 1
    if d[i - 1] > eps: return rdp(p[:i + 1], eps)[:-1] + rdp(p[i:], eps)
    return [p[0], p[-1]]
def plen(p): return sum(math.dist(a, b) for a, b in zip(p, p[1:]))
# --- cluster node points within 14 px, so each junction is one point -------------------
pts = sorted({tuple(np.round(e, 1)) for p in segs for e in (p[0], p[-1])})
cid = {}; centres = []
for q in pts:
    for i, c in enumerate(centres):
        if math.dist(q, c) <= 14: cid[q] = i; break
    else: cid[q] = len(centres); centres.append(q)
def key(e): return cid[tuple(np.round(e, 1))]
edges = []
for p in segs:
    a, b = key(p[0]), key(p[-1])
    if a == b and plen(p) < 40: continue
    edges.append([a, b, [tuple(centres[a])] + [tuple(q) for q in p[1:-1]] + [tuple(centres[b])]])
# --- prune dangling stubs, repeatedly ---------------------------------------------------
changed = True
while changed:
    changed = False
    deg = {}
    for a, b, p in edges: deg[a] = deg.get(a, 0) + 1; deg[b] = deg.get(b, 0) + 1
    keep = []
    for e in edges:
        a, b, p = e
        at_edge = any(q[0] < 12 or q[0] > W - 12 or q[1] < 12 or q[1] > H - 12 for q in (p[0], p[-1]))
        if (deg[a] == 1 or deg[b] == 1) and plen(p) < 60 and not at_edge: changed = True; continue
        keep.append(e)
    edges = keep
# --- join chains through 2-way nodes ---------------------------------------------------
def joined(edges):
    while True:
        deg = {}
        for a, b, p in edges: deg[a] = deg.get(a, 0) + 1; deg[b] = deg.get(b, 0) + 1
        two = [n for n, d in deg.items() if d == 2]
        done = False
        for n in two:
            inc = [e for e in edges if n in (e[0], e[1])]
            if len(inc) != 2 or inc[0] is inc[1]: continue
            e1, e2 = inc
            p1 = e1[2] if e1[1] == n else e1[2][::-1]; o1 = e1[0] if e1[1] == n else e1[1]
            p2 = e2[2] if e2[0] == n else e2[2][::-1]; o2 = e2[1] if e2[0] == n else e2[0]
            if o1 == n or o2 == n: continue
            edges = [e for e in edges if e is not e1 and e is not e2] + [[o1, o2, p1 + p2[1:]]]
            done = True; break
        if not done: return edges
edges = joined(edges)
dbg = Image.new("RGB", (W, H), (0, 0, 0))
from PIL import ImageDraw as _D
_d = _D.Draw(dbg)
_d.line([(0,0),(0,0)], fill=0)
for a, b, p in edges: _d.line([(x, y) for x, y in p], fill=(255, 255, 255), width=3)
dbg.save(S / "traced_debug.png")
roads = [{"pts": [[round(float(x), 1), round(float(y), 1)] for x, y in rdp(p, 6.0)], "w": 1.0} for a, b, p in edges]
# fat paved areas
mask = np.asarray(Image.open(Path("tools/art_source/baikonur_roads_mask.png"))) > 0
fat = binary_opening(mask, iterations=22)
cnts, _ = cv2.findContours(fat.astype(np.uint8), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
areas = []; circles = []
for c in cnts:
    x, y, w, h = cv2.boundingRect(c)
    if w < 40 or h < 40: continue
    if cv2.contourArea(c) < 3000: continue
    if abs(x + w / 2 - 1040) < 150 and abs(y + h / 2 - 650) < 120:
        circles.append([float(x + w / 2), float(y + h / 2), 36.0, 26.0]); continue
    if cv2.contourArea(c) > 20000:
        ap = cv2.approxPolyDP(c, 8, True); areas.append([[int(p[0][0]), int(p[0][1])] for p in ap]); continue
    A = (0.873, 0.488); B = (0.877, -0.479); cx, cy = x + w / 2, y + h / 2
    lb, la = w * 0.55, h * 0.9
    P0 = (cx - (A[0] * la + B[0] * lb) / 2, cy - (A[1] * la + B[1] * lb) / 2)
    P1 = (P0[0] + B[0] * lb, P0[1] + B[1] * lb); P2 = (P1[0] + A[0] * la, P1[1] + A[1] * la); P3 = (P0[0] + A[0] * la, P0[1] + A[1] * la)
    areas.append([[round(float(q[0]), 1), round(float(q[1]), 1)] for q in (P0, P1, P2, P3)])
json.dump({"roads": roads, "areas": areas, "circles": circles}, open(S / "traced.json", "w"))
print(len(segs), "segments ->", len(roads), "roads,", len(areas), "areas,", len(circles), "circles")
