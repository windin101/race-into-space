"""Woomera at the Cape's locked camera angle: every building, hangar and launch complex in
1950s Commonwealth range style. PALETTE env selects the finish: khaki (default) or green.

    PALETTE=green python3 -I tools/art_source/woomera_locked_angle.py OUT_DIR [ids...]
"""
import os, sys
sys.path.insert(0, "tools")
import comfy_batch as cb
from pathlib import Path
out = Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)
cfg = cb.STYLE["spaceport"]
PALETTE = os.environ.get("PALETTE", "khaki")
FINISH = {
    "khaki": ("plain functional 1950s Australian rocket range style like an RAAF station: khaki and olive-drab painted corrugated-iron roofs, "
              "walls of pale sand-khaki rendered brick and cream fibro panels, dark olive shaded faces"),
    "green": ("plain functional 1950s Australian rocket range style like an RAAF station: pale sage-green and eucalyptus-green painted corrugated-iron roofs, "
              "walls of cream and light mint-green weatherboard and rendered brick, darker grey-green shaded faces"),
}[PALETTE]
VIEW = ("seen from a high aerial angle looking down at about 40 degrees, a three-quarter view with the long front face "
        "toward the lower left and the right side face visible toward the lower right, the flat roof clearly visible from above, "
        "like a precise isometric architectural model; afternoon sun from the upper left, the right side face in soft shade, "
        "a short soft shadow falling to the lower right")
TEMPLATE = ("Flat vector illustration like a 1960s magazine plate, soft two-tone cel shading, clean geometric shapes, no outlines, "
            "limited muted palette. {desc}, at the Woomera rocket range in the Australian outback in the 1960s, {finish}, {view}, "
            "the whole structure visible and centred, isolated in front of a plain solid flat bright green chroma key background #00FF00.")
D = {
    "administration": ("A long two-storey range headquarters office block with rows of windows, a verandah along the front and a flagpole", ""),
    "research": ("A research laboratory block: a two-storey building with a wide glazed front and a small radio dish on the roof", ""),
    "programs": ("A long low project office with a central entrance porch and a row of flagpoles", ""),
    "astronaut_complex": ("A crew quarters: a long two-storey barracks block with verandahs on both floors and a small outdoor pool", ""),
    "training": ("A training centre: a large hall with a round domed centrifuge building attached at one end", ""),
    "vab": ("A huge rocket assembly hall: a very long tall windowless hangar-like building with a huge sliding door at one end, "
            "a wide concrete apron outside the door, nothing standing outside", "white, rocket, missile, spacecraft"),
    "mission_control": ("A range control centre: a wide low block with a large radar dish on a short tower on the roof", ""),
    "museum": ("A museum building with a plain colonnaded front and a small rocket monument beside it", ""),
    "intelligence": ("A small plain windowless security office with a fenced yard and a tall antenna mast", ""),
    "hangar": ("A single large aircraft hangar with a low curved roof and a big open door, on a small concrete apron, nothing else in the picture",
               "runway, airstrip, road, aeroplane, aircraft, people"),
    "memorial": ("A single tall slender pale stone obelisk memorial standing completely alone on a low three-step square plinth on a small paved square, "
                 "a wreath at its base, no building anywhere, nothing else in the picture", "building, house, office, block, wall, roof, people"),
    # launch-pad parts, assembled by tools/art_source/assemble_pads.py
    "platform": ("A large flat square concrete launch platform lying on the ground, pale grey concrete, a dark square open flame trench in its centre, "
                 "a low concrete lip around the edge, completely flat and empty, nothing standing on it, just the flat pad",
                 "tower, gantry, mast, rocket, building, walls, house, crane, fire, flames, glow, people"),
    "gantry": ("A single very tall slender steel lattice rocket service gantry tower standing alone on bare ground, white-painted girders with red bands, "
               "platforms at several levels and a small crane arm at the top, nothing else in the picture, no building, no rocket",
               "building, house, walls, rocket, missile, fire, flames, people, second tower"),
    "gantry_wreck": ("A collapsed white steel lattice rocket service tower lying bent and broken on scorched black concrete, twisted girders, "
                     "wisps of grey smoke, nothing else in the picture, no building, no rocket, no fire",
                     "building, house, walls, rocket, fire, flames, orange glow, people"),
}
PARTS = {"platform", "gantry", "gantry_wreck"}
PART_TEMPLATE = ("Flat vector illustration like a 1960s magazine plate, soft two-tone cel shading, clean geometric shapes, no outlines, "
                 "limited muted palette. {desc}, {view}, the whole object visible and centred, "
                 "isolated in front of a plain solid flat bright green chroma key background #00FF00.")
ids = sys.argv[2:] or list(D)
K0, K1 = int(os.environ.get("K0", 0)), int(os.environ.get("K1", 3))
for bid in ids:
    d, extra = D[bid]
    neg = cfg["cutout_negative"] + ", front view, straight-on elevation, side view, ground level view, low angle, white walls, bright white"
    if extra:
        neg += ", " + extra
    for k in range(K0, K1):
        prompt = PART_TEMPLATE.format(desc=d, view=VIEW) if bid in PARTS else TEMPLATE.format(desc=d, finish=FINISH, view=VIEW)
        img = cb.run_workflow(cb.t2i_graph(prompt, cb.seed_for("woomera/" + PALETTE + "/" + bid) + k, 1024, 768, neg), timeout=1800)[0]
        img = cb.chroma_key(img, tuple(cfg["chroma_key"]), tight=True)
        bb = img.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()
        if bb:
            img = img.crop(bb)
        img.save(out / f"{bid}_{k}.png")
        print(bid, k, flush=True)
print("ALL-DONE")
