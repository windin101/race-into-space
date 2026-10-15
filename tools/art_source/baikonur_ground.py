"""Empty Baikonur ground at the Cape's camera: flat ochre steppe to a curved horizon."""
import sys
sys.path.insert(0, "tools")
import comfy_batch as cb
from pathlib import Path
out = Path(sys.argv[1])
p = ("Flat vector illustration like a 1960s magazine plate, soft two-tone cel shading, clean shapes, no outlines, limited muted palette. "
     "A completely flat open plain of Kazakh steppe seen from very high above, looking steeply down at a 40 degree angle like an aerial survey photograph, "
     "the ground fills almost the whole picture, only a thin strip of deep blue sky at the very top above a gently curved earth horizon. "
     "Perfectly level flat ground, warm ochre and orange-tan earth with a fine mottled speckled texture of slightly lighter and darker patches, "
     "a few tiny scattered dry shrubs, completely empty and undeveloped, no dunes, no hills, no roads, no tracks, no buildings, no water. "
     "Afternoon light from the upper left.")
neg = ("roads, paths, tracks, buildings, houses, structures, towers, rockets, people, cars, text, labels, watermark, photograph, photorealistic, "
       "city, fields, farmland, river, lake, water, sea, trees, forest, green grass, mountains, dunes, sand dunes, hills, low camera, horizon in the middle")
for k in range(4, 10):
    img = cb.run_workflow(cb.t2i_graph(p, cb.seed_for("baikonur/ground") + k, 1664, 928, neg), timeout=1800)[0]
    cb.fit_cover(img.convert("RGB"), (1920, 1080)).save(out / f"ground_{k}.png")
    print("ground", k, flush=True)
print("ALL-DONE")
