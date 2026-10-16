"""Empty Woomera ground at the Cape's camera: red outback plain to a high curved horizon.

    python3 tools/art_source/woomera_ground.py OUT_DIR [k0 k1]
"""
import sys
sys.path.insert(0, "tools")
import comfy_batch as cb
from pathlib import Path
out = Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)
k0, k1 = (int(sys.argv[2]), int(sys.argv[3])) if len(sys.argv) > 3 else (0, 4)
VARIANTS = {
    0: "a faint pale pink dry salt lake far away near the horizon on the right",
    1: "a low line of dusty purple ranges along the far horizon",
    2: "a wide dry creek bed with a few gum trees winding across the far distance",
    3: "nothing on the horizon but the plain",
}
p = ("Flat vector illustration like a 1960s magazine plate, soft two-tone cel shading, clean shapes, no outlines, limited muted palette. "
     "A completely flat open plain of the South Australian outback near Woomera seen from very high above, the camera tilted steeply down at about 50 degrees like an aerial survey photograph, "
     "the ground fills almost the entire picture: the horizon is a gently curved line only one tenth of the way down from the top edge, with just a thin strip "
     "of deep blue sky above it. Perfectly level flat ground of rust-red and orange-brown earth with a fine mottled speckled texture and faint broad "
     "lighter and darker bands, scattered small grey-green saltbush and spinifex clumps, {variant}, "
     "uniform untouched virgin ground with no marks of any kind, no dunes, no hills nearby, no roads, no paths, no tracks, no tyre marks, no lines, no buildings. "
     "Hard bright midday light from the upper left.")
neg = ("roads, paths, tracks, tyre tracks, trails, lines, dirt road, footpath, buildings, houses, structures, towers, rockets, people, cars, text, labels, watermark, photograph, photorealistic, "
       "city, fields, farmland, river, sea, forest, green grass, mountains nearby, dunes, sand dunes, low camera, horizon in the middle, kangaroo, animals")
for k in range(k0, k1):
    img = cb.run_workflow(cb.t2i_graph(p.format(variant=VARIANTS.get(k % 4)), cb.seed_for("woomera/ground") + k, 1664, 928, neg), timeout=1800)[0]
    cb.fit_cover(img.convert("RGB"), (1920, 1080)).save(out / f"ground_{k}.png")
    print("ground", k, flush=True)
print("ALL-DONE")
