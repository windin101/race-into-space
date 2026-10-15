import sys
sys.path.insert(0, "tools")
import comfy_batch as cb
from pathlib import Path
out = Path(sys.argv[1])
p = ("Flat vector illustration like a 1960s magazine plate, soft two-tone cel shading, clean shapes, no outlines, limited muted palette. "
     "A wide empty stretch of flat Florida coastal scrubland seen from high above at a 40 degree angle, an aerial view. "
     "A thin strip of pale sky at the very top above a gently curved horizon. A wide river runs diagonally across the upper part of the picture "
     "from the upper left down toward the right, with natural sandy banks, and a far green shore beyond it. "
     "The near land fills most of the picture: flat open grassland in soft greens with scattered low scrub and small clumps of trees, "
     "completely empty and undeveloped, no roads, no paths, no buildings, no structures. Afternoon light from the upper left.")
neg = "roads, paths, tracks, buildings, houses, structures, towers, rockets, people, cars, text, labels, watermark, photograph, photorealistic, city, fields, farmland"
for k in range(3):
    img = cb.run_workflow(cb.t2i_graph(p, cb.seed_for("angle/cape_ground") + k, 1664, 928, neg), timeout=1800)[0]
    cb.fit_cover(img.convert("RGB"), (1920, 1080)).save(out / f"ground_{k}.png")
    print("g", k, flush=True)
