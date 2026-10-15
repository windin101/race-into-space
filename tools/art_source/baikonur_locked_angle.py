"""Baikonur at the Cape's locked camera angle: an empty steppe ground and every building,
hangar and launch complex in the original's beige and tan-brown Soviet concrete.

    python3 -I tools/art_source/baikonur_locked_angle.py OUT_DIR [ids...]
"""
import sys
sys.path.insert(0, "tools")
import comfy_batch as cb
from pathlib import Path
out = Path(sys.argv[1])
cfg = cb.STYLE["spaceport"]
VIEW = ("seen from a high aerial angle looking down at about 40 degrees, a three-quarter view with the long front face "
        "toward the lower left and the right side face visible toward the lower right, the flat roof clearly visible from above, "
        "like a precise isometric architectural model; afternoon sun from the upper left, the right side face in soft shade, "
        "a short soft shadow falling to the lower right")
TEMPLATE = ("Flat vector illustration like a 1960s magazine plate, soft two-tone cel shading, clean geometric shapes, no outlines, "
            "limited muted palette. {desc}, at a Soviet space centre of the 1960s, plain Soviet modernist style built of pale beige "
            "and warm tan-brown concrete, sand-coloured walls and darker brown shaded faces, {view}, the whole structure visible and centred, "
            "isolated in front of a plain solid flat bright green chroma key background #00FF00.")
D = {
    "platform": ("A large flat octagonal concrete launch platform lying on the ground, a dark square open flame pit in its centre, a low concrete lip around the edge, "
                 "completely flat and empty, nothing standing on it, no tower, no building, no walls, just the flat pad", "tower, gantry, mast, rocket, building, walls, house, crane, fire, flames, glow, people"),
    "gantry": ("A single very tall slender steel lattice rocket service gantry tower standing alone on bare ground, grey steel girders with red-and-white bands, "
               "platforms at several levels and a small crane arm at the top, nothing else in the picture, no building, no rocket", "building, house, walls, rocket, missile, fire, flames, people, second tower"),
    "gantry_wreck": ("A collapsed steel lattice rocket service tower lying bent and broken on scorched black concrete, twisted girders, wisps of grey smoke drifting up, "
                     "nothing else in the picture, no building, no rocket, no fire", "building, house, walls, rocket, fire, flames, orange glow, people"),
    "gagarin": ("A Soviet R-7 rocket launch complex like Gagarin's Start at Baikonur: a large raised square concrete platform built out over the edge of a huge deep open concrete trench, "
                "four tall steel lattice support arms rising from the platform edge and leaning outward in a ring, two tall lattice service towers folded back beside them, "
                "the launch position in the middle completely empty with no rocket, a short concrete ramp up to the platform", "rocket, missile, spacecraft, smoke, fire, flames, burning, glow, orange, exhaust, people, vehicles"),
    "gagarin_site": ("A large raised square concrete platform built out over the edge of a huge deep open concrete trench, the trench dark grey and empty, a short concrete ramp up to the platform, "
                     "nothing standing on the platform, no towers, no arms, bare concrete", "rocket, tower, gantry, mast, arms, building, fire, flames, glow, orange, people"),
    "gagarin_wreck": ("A wrecked Soviet launch platform after a rocket explosion: a raised square concrete platform over a deep open trench, the concrete scorched black, "
                      "tall steel lattice support arms bent, broken and fallen across it in twisted wreckage, wisps of grey smoke, no fire", "rocket, fire, flames, orange glow, people"),
    "administration": ("A long three-storey Soviet administration block with rows of windows and a columned entrance porch", ""),
    "research": ("A Soviet research institute: a two-storey laboratory block with a wide glazed front and a small radio dish on the roof", ""),
    "programs": ("A long low Soviet design bureau office with a central entrance and a row of flagpoles with red flags", ""),
    "astronaut_complex": ("A Soviet cosmonaut residential hotel: a long four-storey block with balconies and a small outdoor pool", ""),
    "training": ("A Soviet cosmonaut training centre: a large hall with a round domed centrifuge building attached at one end", ""),
    "vab": ("A huge Soviet rocket assembly and test hall: a very long tall windowless hangar-like building with a huge sliding door at one end, "
            "railway tracks leading out of the door, nothing standing outside", "white, rocket, missile, spacecraft"),
    "mission_control": ("A Soviet flight control centre: a wide low block with a large radar dish on a short tower on the roof", ""),
    "museum": ("A Soviet museum building with a heavy colonnaded front and a small rocket monument beside it", ""),
    "intelligence": ("A small plain windowless Soviet security office with a fenced yard and a tall antenna mast", ""),
    "hangar": ("A single large aircraft hangar with a low curved roof and a big open door, on a small concrete apron, nothing else in the picture",
               "runway, airstrip, road, aeroplane, aircraft, people"),
    "memorial": ("A single tall slender pale stone obelisk memorial with a small red star at its top, standing completely alone on a low three-step square plinth on a small paved square, "
                 "a wreath at its base, no building anywhere, nothing else in the picture", "building, house, office, block, wall, roof, people"),
    "tower": ("A Soviet rocket launch complex with a compact footprint: a deep square concrete flame pit, dark grey and empty and cold, with an empty launch support ring over it, "
              "a tall steel lattice service tower standing beside it, on a small concrete pad, no rocket",
              "rocket, missile, spacecraft, smoke, fire, flames, burning, glow, orange, exhaust, people, vehicles, office building"),
    "padsite": ("A small empty square concrete launch pad with a deep square flame pit in its middle, the pit dark grey and empty and cold, nothing standing on it, no tower, no buildings, just the bare pad",
                "tower, gantry, rocket, building, crane, mast, people, fire, flames, burning, glow, orange"),
    "padwreck": ("A wrecked small concrete launch pad after a rocket explosion: the concrete scorched black, a steel lattice service tower bent and collapsed "
                 "into the flame pit in twisted wreckage, small wisps of grey smoke, no fire", "rocket, flames, fire, people, vehicles"),
}
PART_TEMPLATE = ("Flat vector illustration like a 1960s magazine plate, soft two-tone cel shading, clean geometric shapes, no outlines, "
                 "limited muted palette. {desc}, pale beige concrete and grey steel, {view}, the whole object visible and centred, "
                 "isolated in front of a plain solid flat bright green chroma key background #00FF00.")
PARTS = {"platform", "gantry", "gantry_wreck"}
ids = sys.argv[2:] or list(D)
for bid in ids:
    d, extra = D[bid]
    neg = cfg["cutout_negative"] + ", front view, straight-on elevation, side view, ground level view, low angle, white walls, bright white" + (", building, house, block, office, shed, hut, walls, roof" if bid in PARTS else "")
    if extra:
        neg += ", " + extra
    for k in (range(int(__import__('os').environ.get('K0', 3)), int(__import__('os').environ.get('K1', 7))) if len(sys.argv) > 2 else range(3)):
        tpl = PART_TEMPLATE if bid in PARTS else TEMPLATE
        img = cb.run_workflow(cb.t2i_graph(tpl.format(desc=d, view=VIEW), cb.seed_for("baikonur/" + bid) + k, 1024, 768, neg), timeout=1800)[0]
        img = cb.chroma_key(img, tuple(cfg["chroma_key"]), tight=True)
        bb = img.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()
        if bb:
            img = img.crop(bb)
        img.save(out / f"{bid}_{k}.png")
        print(bid, k, flush=True)
print("ALL-DONE")
