#!/usr/bin/env python3
"""Paint the bodies used by the mission diagram (Earth, Moon, planets) and cut each one
out along its own outline, rings included, into game/assets/art/diagram/<name>.png.

    python3 -I tools/diagram_bodies.py [--names saturn,jupiter] [--reseed N]
"""
import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
import comfy_batch as cb  # noqa: E402

OUT = cb.GAME / "assets" / "art" / "diagram"
BASE = ("Flat vector illustration in the style of 1960s space programme press art, soft two-tone cel "
        "shading, clean shapes, no outlines. {body}, alone, complete and centred, with wide empty black "
        "margins on every side, lit from the upper left. Plain pure black background, no stars, no text.")
BODIES = {
    "earth": "Planet Earth as a round globe: blue oceans, green and tan continents, white cloud swirls, a thin pale blue atmosphere glow",
    "moon": "The Moon as a round globe: pale grey with darker maria and a few craters",
    "mars": "Planet Mars as a round globe: rust red and orange with darker markings and a small white polar cap",
    "venus": "Planet Venus as a round globe: smooth pale yellow and cream cloud bands",
    "mercury": "Planet Mercury as a round globe: warm grey-brown, cratered",
    "jupiter": "Planet Jupiter as a round globe: cream, tan and rust horizontal cloud bands and one red oval storm, nothing else on it",
    "saturn": "Planet Saturn: a pale gold banded globe circled by its broad flat ring system, seen slightly from above",
}
NEG = "text, stars, frame, spacecraft, astronaut, second planet, moon in front, cropped, close-up, border"


def cut(img: Image.Image) -> Image.Image:
    a = np.asarray(img.convert("RGB")).astype(int)
    lum = a.max(-1)
    mask = lum > 38
    labels, n = ndimage.label(mask)
    if n == 0:
        raise ValueError("empty render")
    sizes = ndimage.sum(mask, labels, range(1, n + 1))
    keep = labels == (int(np.argmax(sizes)) + 1)
    keep = ndimage.binary_fill_holes(keep)
    # Soft edge: a small blur of the mask, then tighten so no black fringe survives.
    alpha = ndimage.gaussian_filter(keep.astype(float), 1.2)
    alpha = np.clip((alpha - 0.35) / 0.4, 0, 1)
    ys, xs = np.nonzero(keep)
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    rgba = np.dstack([a, (alpha * 255).astype(int)]).astype(np.uint8)
    out = Image.fromarray(rgba, "RGBA").crop((x0, y0, x1 + 1, y1 + 1))
    side = max(out.size)
    sq = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    sq.paste(out, ((side - out.width) // 2, (side - out.height) // 2), out)
    return sq.resize((512, 512), Image.LANCZOS)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--names", default="")
    ap.add_argument("--reseed", type=int, default=0)
    a = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    names = [n for n in a.names.split(",") if n] or list(BODIES)
    for name in names:
        img = cb.run_workflow(cb.t2i_graph(BASE.format(body=BODIES[name]), cb.seed_for("diagram/" + name) + a.reseed, 1024, 1024, NEG))[0]
        cut(img).save(OUT / f"{name}.png")
        print("wrote", name)


if __name__ == "__main__":
    main()
