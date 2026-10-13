#!/usr/bin/env python3
"""Draw the Commonwealth programme emblem (an original design): a roundel launching on a
curved, tapering trail that ends in a gold star, with short exhaust flicks behind it.

    python3 -I tools/art_source/make_emblem_cwth.py   # writes emblem_cwth.svg here
    rsvg-convert -w 512 -h 512 tools/art_source/emblem_cwth.svg -o game/assets/art/icons/emblem_cwth.png
"""
import math
from pathlib import Path

BLUE, RED, WHITE, GOLD = "#2f3f8f", "#c8372d", "#ffffff", "#e3b23c"
C = (218.0, 300.0)          # roundel centre


def bez(p0, p1, p2, t):
    return tuple((1 - t) ** 2 * a + 2 * (1 - t) * t * b + t * t * c for a, b, c in zip(p0, p1, p2))


def band(p0, p1, p2, lo, hi, n=60, taper=1.0):
    """Polygon between offsets lo..hi from a quadratic curve, narrowing to the end."""
    left, right = [], []
    for i in range(n + 1):
        t = i / n
        x, y = bez(p0, p1, p2, t)
        dx, dy = (bez(p0, p1, p2, min(1, t + 1e-3))[k] - bez(p0, p1, p2, max(0, t - 1e-3))[k] for k in (0, 1))
        L = math.hypot(dx, dy) or 1
        nx, ny = -dy / L, dx / L
        s = (1 - t) ** taper
        left.append((x + nx * lo * s, y + ny * lo * s))
        right.append((x + nx * hi * s, y + ny * hi * s))
    pts = left + right[::-1]
    return "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts) + " Z"


def star(cx, cy, r, k=0.32, points=4, rot=-45):
    pts = []
    for i in range(points * 2):
        a = math.radians(rot + i * 180 / points)
        rr = r if i % 2 == 0 else r * k
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    return "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts) + " Z"


# The trail sweeps from inside the roundel up and to the right in a gentle arc.
p0, p1, p2 = C, (318.0, 236.0), (440.0, 76.0)
trail = [band(p0, p1, p2, -80, -34, taper=0.85), band(p0, p1, p2, -26, 26, taper=0.85),
         band(p0, p1, p2, 34, 62, taper=1.0)]
# Exhaust: three short flicks curling away behind the roundel, lower left.
flicks = []
for ang, length, col in ((196, 70, BLUE), (222, 96, RED), (248, 62, BLUE)):
    a = math.radians(ang)
    start = (C[0] + 80 * math.cos(a), C[1] - 80 * math.sin(a))
    end = (C[0] + (104 + length) * math.cos(a), C[1] - (104 + length) * math.sin(a))
    bend = math.radians(ang - 14)
    mid = (C[0] + (104 + length * 0.5) * math.cos(bend), C[1] - (104 + length * 0.5) * math.sin(bend))
    flicks.append((band(start, mid, end, -17, 17, taper=1.0), col))

svg = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">']
for d, col in flicks:
    svg.append(f'<path d="{d}" fill="{col}" stroke="{WHITE}" stroke-width="5" paint-order="stroke"/>')
for d, col in zip(trail, (BLUE, RED, BLUE)):
    svg.append(f'<path d="{d}" fill="{col}" stroke="{WHITE}" stroke-width="5" paint-order="stroke"/>')
svg.append(f'<circle cx="{C[0]}" cy="{C[1]}" r="104" fill="{BLUE}" stroke="{WHITE}" stroke-width="6"/>')
svg.append(f'<circle cx="{C[0]}" cy="{C[1]}" r="70" fill="{WHITE}"/>')
svg.append(f'<circle cx="{C[0]}" cy="{C[1]}" r="38" fill="{RED}"/>')
svg.append(f'<path d="{star(444, 72, 38)}" fill="{GOLD}" stroke="{WHITE}" stroke-width="4" paint-order="stroke"/>')
svg.append("</svg>")
out = Path(__file__).with_name("emblem_cwth.svg")
out.write_text("\n".join(svg) + "\n")
print("wrote", out)
