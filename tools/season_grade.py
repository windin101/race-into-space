#!/usr/bin/env python3
"""Make each spaceport's autumn background by colour-grading its spring painting, so the
two seasons share one composition (roads, coast, horizon) and one building layout.

    python3 -I tools/season_grade.py

Greens become straw and rust, blues (sky, sea) lose saturation and warm toward haze,
everything gets a little softer and warmer. Roads, sand and white stay where they are.
"""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ART = ROOT / "game" / "assets" / "art" / "spaceport"


def rgb_to_hsv(a):
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    mx, mn = a.max(-1), a.min(-1)
    d = mx - mn
    h = np.zeros_like(mx)
    m = d > 1e-6
    rr = m & (mx == r)
    gg = m & (mx == g) & ~rr
    bb = m & ~rr & ~gg
    h[rr] = ((g - b)[rr] / d[rr]) % 6
    h[gg] = (b - r)[gg] / d[gg] + 2
    h[bb] = (r - g)[bb] / d[bb] + 4
    h = h / 6.0
    s = np.where(mx > 1e-6, d / np.maximum(mx, 1e-6), 0)
    return h, s, mx


def hsv_to_rgb(h, s, v):
    i = np.floor(h * 6).astype(int) % 6
    f = h * 6 - np.floor(h * 6)
    p, q, t = v * (1 - s), v * (1 - s * f), v * (1 - s * (1 - f))
    out = np.zeros(h.shape + (3,))
    for k, (x, y, z) in enumerate([(v, t, p), (q, v, p), (p, v, t), (p, q, v), (t, p, v), (v, p, q)]):
        sel = i == k
        out[sel, 0], out[sel, 1], out[sel, 2] = x[sel], y[sel], z[sel]
    return out


def grade(src: Path, dst: Path, side: str) -> None:
    a = np.asarray(Image.open(src).convert("RGB")).astype(float) / 255.0
    h, s, v = rgb_to_hsv(a)
    deg = h * 360
    green = (deg > 55) & (deg < 170) & (s > 0.08)
    blue = (deg >= 170) & (deg < 260) & (s > 0.08)
    # Greens to straw (light) and rust (dark), keeping their light and shade.
    dark = v < 0.62
    h = np.where(green & ~dark, 40 / 360, h)
    h = np.where(green & dark, 24 / 360, h)
    s = np.where(green, np.clip(s * (1.25 if side == "usa" else 1.1) + 0.06, 0, 0.75), s)
    v = np.where(green & dark, v * 0.92, v)
    # Sky and sea: less saturated, a touch warmer and paler for haze.
    s = np.where(blue, s * (0.45 if side == "usa" else 0.3), s)
    v = np.where(blue, np.clip(v * 1.02 + 0.03, 0, 1), v)
    out = hsv_to_rgb(h, s, v)
    # Warm, soft overall grade.
    warm = np.array([1.04, 1.0, 0.92]) if side == "usa" else np.array([1.0, 0.99, 0.95])
    out = np.clip(out * warm * 0.96 + 0.02, 0, 1)
    Image.fromarray((out * 255).astype(np.uint8)).save(dst)


def main() -> None:
    for side in ("usa", "ussr"):
        grade(ART / side / "background_spring.png", ART / side / "background_fall.png", side)
        print("wrote", side)


if __name__ == "__main__":
    main()
