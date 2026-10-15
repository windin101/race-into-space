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
            "limited muted palette. {desc}, at an American space centre of the 1960s, clean white 1960s American modernist style, "
            "{view}, the whole structure visible and centred, isolated in front of a plain solid flat bright green chroma key background #00FF00.")
ids = ["padsite", "padwreck"]
OVERRIDE = {
    "padsite": ("A small empty octagonal concrete launch pad with a square concrete launch mount pedestal in its middle, nothing standing on it, no tower, no buildings, just the bare pad", "tower, gantry, rocket, building, crane, mast, people"),
    "padwreck": ("A wrecked small octagonal concrete launch pad after a rocket explosion: the concrete scorched black, a steel lattice service tower bent and collapsed lying across the pad in twisted wreckage, small wisps of grey smoke, no fire", "rocket, flames, fire, people, vehicles"),
    "tower": ("A 1960s American rocket launch complex with a small compact footprint: a tall rectangular steel lattice mobile service gantry tower, several times taller than it is wide, with platforms at many levels and a crane arm on top, standing right beside an empty square launch mount pedestal, both on a small octagonal concrete pad, a short umbilical mast beside the mount; the pad is empty with no rocket", "rocket, missile, spacecraft, smoke, fire, flames, exhaust, people, vehicles, large apron, wide concrete area, trench"),
    "pad": ("An empty 1960s rocket launch pad: a large square concrete launch apron with a narrow dark grey empty concrete channel cut across it, a tall red-and-white steel lattice umbilical service tower standing at one side of an empty launch mount, a small low concrete blockhouse at the edge of the apron, the pad is empty with no rocket", "rocket, missile, spacecraft, smoke, fire, flames, lava, orange, glow, exhaust, people, vehicles"),
    "hangar": ("A single aircraft hangar with a curved barrel-vault roof and a large open door, standing on a small square concrete apron, nothing else in the picture", "runway, airstrip, road, aeroplane, aircraft, people"),
    "vab": ("A gigantic vehicle assembly building: a very tall white windowless box, about twice as tall as it is wide, "
            "with huge tall vertical doors running almost the full height of the front, a low two-storey annex at its base", ""),
    "memorial": ("A single slender white stone obelisk memorial standing alone on a low three-step square plinth on a small paved square, "
                 "a wreath at its base, nothing else in the picture", "building, house, office, wall, roof, people"),
}
for bid in ids:
    d = OVERRIDE[bid][0]
    neg = cfg["cutout_negative"] + ", front view, straight-on elevation, side view, ground level view, low angle"
    if OVERRIDE[bid][1]:
        neg += ", " + OVERRIDE[bid][1]
    for k in range(30, 33):
        img = cb.run_workflow(cb.t2i_graph(TEMPLATE.format(desc=d, view=VIEW), cb.seed_for("angle/" + bid) + k, 1024, 768, neg), timeout=1800)[0]
        img = cb.chroma_key(img, tuple(cfg["chroma_key"]), tight=True)
        bb = img.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()
        if bb:
            img = img.crop(bb)
        img.save(out / f"{bid}_{k}.png")
        print(bid, k, flush=True)
print("ALL-DONE")
