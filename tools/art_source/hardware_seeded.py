"""Hardware icons from a style seed: the edit model is given one of the player's approved
Nano Banana icons as the style reference and asked for a different vehicle in that style.

    K0=0 K1=1 python3 -I tools/art_source/hardware_seeded.py OUT_DIR [side/group_slot ...]
Writes OUT_DIR/<side>/<group>_<slot>_s<k>.png as 1024 RGB on white; the pick is keyed later.
"""
import os, sys
sys.path.insert(0, "tools")
import comfy_batch as cb
from pathlib import Path
from PIL import Image
out = Path(sys.argv[1]); U = Path.home() / "craft/in/hardware/user"
UP = "standing vertically upright, nose at the top, engine nozzles at the bottom"
SIDE = "lying horizontally, nose to the left"
# key: (seed icon, orientation, description)
D = {
 # ---- USA ----
 "usa/probe_1": ("usa_probe_0.png", SIDE, "the Ranger lunar probe: a hexagonal bus with a tall conical tower of struts on top ending in a small cylindrical instrument capsule, two flat rectangular solar panel wings, a dish antenna underneath"),
 "usa/probe_2": ("usa_probe_0.png", SIDE, "the Surveyor lunar lander: a triangular tripod frame of tubular struts on three legs with round footpads, a tall mast with a tilted flat solar panel and a planar antenna at the top, instrument boxes on the frame"),
 "usa/rocket_1": ("usa_rocket_0.png", UP, "the Titan II rocket: a tall slim two-stage rocket of constant diameter, white with a black and white chequered roll pattern on the first stage, two engine bells at the base, a small capsule on top"),
 "usa/rocket_2": ("usa_rocket_0.png", UP, "the Saturn V moon rocket: a very tall white rocket with black vertical roll-pattern stripes on the first stage, four fins and five huge engine bells at the base, a wider first stage, a narrower second and third stage, a conical fairing and a slim escape tower at the top"),
 "usa/rocket_3": ("usa_rocket_0.png", UP, "the Nova super-heavy moon rocket: a colossal rocket fatter than Saturn V, white with black roll-pattern stripes, eight huge engine bells clustered across its very broad base, three stages, a conical fairing and an escape tower"),
 "usa/rocket_4": ("usa_rocket_0.png", UP, "two identical slim white solid rocket boosters standing side by side a short gap apart, each a plain cylinder with a pointed nose cone and one flared nozzle, no core rocket between them"),
 "usa/manned_0": ("usa_manned_1.png", SIDE, "the Mercury one-man capsule: a small truncated cone with corrugated dark shingles, a flat heat shield at the wide end, a short cylinder with an antenna canister at the narrow end, one small square window"),
 "usa/manned_2": ("usa_manned_1.png", SIDE, "the Apollo command and service module: a short silver cone (the command module) with a small docking probe on its tip, joined base to base with a long white cylinder (the service module) of the same width, one big engine bell at the far end, a small high-gain dish on a boom"),
 "usa/manned_4": ("usa_manned_1.png", "standing upright on its legs", "the Jupiter direct-ascent three-man lunar capsule: a large conical crew capsule standing on a squat cylindrical landing stage with four splayed landing legs and one rocket engine underneath"),
 "usa/manned_5": ("usa_manned_1.png", "standing upright on its legs", "the Apollo lunar module Eagle: an octagonal descent stage wrapped in gold and black foil on four splayed legs with round footpads, a boxy silver ascent stage with two triangular windows and a hatch on top, an antenna dish"),
 "usa/manned_6": ("usa_manned_1.png", "standing upright on its legs", "a tiny one-man open-frame lunar lander: an astronaut-sized open cabin with a small instrument panel on a lattice frame, one engine bell underneath and three thin legs"),
 "usa/misc_0": ("usa_manned_1.png", SIDE, "the Agena upper stage: a plain slim white cylinder with a single small engine bell at one end and a conical docking collar at the other, no wings, no fins"),
 "usa/misc_1": ("usa_manned_1.png", SIDE, "the Centaur upper stage: a smooth polished stainless-steel cylinder with flat ends like a tin can, two engine bells sticking out of one end, no wings, no fins, no cabin"),
 "usa/misc_2": ("usa_manned_1.png", SIDE, "the Saturn S-IVB upper stage: a fat smooth white cylinder with flat ends, a black band around one end, one big engine bell sticking out of that end, no wings, no fins"),
 "usa/misc_3": ("usa_manned_1.png", "standing upright", "a single empty white Apollo-era spacesuit standing upright, a boxy backpack life-support unit, a helmet with a gold mirror visor, blue gloves and a coiled umbilical hose, nothing else"),
 "usa/misc_4": ("usa_manned_1.png", SIDE, "a short cylindrical docking module with a probe-and-drogue docking ring at one end, a round hatch, and small thruster quads, no wings"),
 "usa/misc_5": ("usa_probe_0.png", SIDE, "a Corona photo-reconnaissance satellite: a long cylinder with a large camera lens at one end, a small conical film-return capsule at the other, two flat solar panels"),
 # ---- USSR ----
 "ussr/probe_0": ("usa_probe_0.png", SIDE, "the Sputnik 1 satellite: a polished metal sphere with four long thin rod antennae trailing back from one side"),
 "ussr/probe_1": ("usa_probe_0.png", SIDE, "a Soviet Cosmos satellite: a short cylinder with rounded ends and two flat solar panel wings, a few small antennae"),
 "ussr/probe_2": ("usa_probe_0.png", UP, "the Luna 2 lunar probe: a polished metal sphere with four short rod antennae sitting on top of a short cylindrical rocket stage with one engine nozzle at the bottom"),
 "ussr/rocket_0": ("usa_rocket_0.png", UP, "the Soviet R-7 Semyorka rocket: a grey-green central core with four long conical strap-on boosters clustered tightly around its lower half, each tapering to a point near the top, the famous tulip outline, a cluster of small engine nozzles across the base, a short fairing on top, no fins"),
 "ussr/rocket_1": ("usa_rocket_0.png", UP, "the Soviet Proton rocket: a tall white and grey rocket with six slim cylindrical fuel tanks clustered around a wider central core on the first stage, six engine bells at the base, a narrower upper stage and a conical fairing"),
 "ussr/rocket_2": ("usa_rocket_0.png", UP, "the Soviet N1 moon rocket: a giant stepped cone, very wide at the base and tapering in steps to a slim top, grey and white, a ring of thirty small engine nozzles across the wide base, a small escape tower on top"),
 "ussr/rocket_3": ("usa_rocket_0.png", UP, "the Soviet UR-700 moon rocket: a huge rocket made of nine clustered cylindrical boosters packed side by side, grey and white, many engine bells at the base, a conical fairing on top"),
 "ussr/rocket_4": ("usa_rocket_0.png", UP, "two identical slim grey-green strap-on liquid rocket boosters standing side by side a short gap apart, each tapering to a conical nose with one engine nozzle at the bottom, no core rocket between them"),
 "ussr/manned_0": ("usa_manned_1.png", SIDE, "the Vostok spacecraft: a round polished spherical re-entry capsule with three small portholes on the left, bolted to a conical instrument module on the right with a ring of small spherical gas bottles around the join and one engine nozzle at the far end, a few whip antennae"),
 "ussr/manned_1": ("usa_manned_1.png", SIDE, "the Voskhod spacecraft: a round spherical capsule on the left joined to a conical instrument module on the right, with a short straight fabric inflatable airlock cylinder standing up from the top of the sphere, one engine nozzle at the far end"),
 "ussr/manned_2": ("usa_manned_1.png", SIDE, "the Soyuz spacecraft: a spherical orbital module on the left, a bell-shaped descent module in the middle, a cylindrical service module on the right with two flat rectangular solar panel wings and one engine nozzle, green-grey"),
 "ussr/manned_4": ("usa_manned_1.png", "standing upright on its legs", "the Soviet LK-700 direct-ascent lunar lander: a conical crew capsule standing on a wide squat landing stage with four splayed legs and a cluster of engine bells underneath, grey-green"),
 "ussr/manned_5": ("usa_manned_1.png", "standing upright on its legs", "a Soviet two-man lunar lander: a round pressurised cabin with a porthole on a cylindrical engine section, one large engine bell underneath, four splayed legs with round footpads, grey-green"),
 "ussr/manned_6": ("usa_manned_1.png", "standing upright on its legs", "the Soviet LK one-cosmonaut lunar lander: a small round cabin with a porthole and a hatch on top of a four-legged lattice landing frame with a single engine bell, grey-green"),
 "ussr/misc_0": ("usa_manned_1.png", SIDE, "a Soviet upper stage: a plain slim grey-green cylinder with a single small engine bell at one end, no wings, no fins"),
 "ussr/misc_1": ("usa_manned_1.png", SIDE, "a Soviet Block-D upper stage: a short fat grey cylinder with a large spherical fuel tank showing at one end and one engine bell, no wings, no fins"),
 "ussr/misc_2": ("usa_manned_1.png", SIDE, "a large Soviet upper stage: a smooth grey-green cylinder with flat ends and one big engine bell at one end, no wings, no fins"),
 "ussr/misc_3": ("usa_manned_1.png", "standing upright", "a single empty Soviet spacesuit standing upright: a bulky white suit with a rigid backpack and a helmet with a white visor hood and a small red star, nothing else"),
 "ussr/misc_4": ("usa_manned_1.png", SIDE, "a short grey-green cylindrical docking module with a probe-and-drogue docking ring at one end and a round hatch, no wings"),
 "ussr/misc_5": ("usa_probe_0.png", SIDE, "a Soviet Zenit photo-reconnaissance satellite: a spherical camera capsule with a large lens, attached to a conical instrument module with a few antennae"),
 # ---- Commonwealth ----
 "cwth/probe_0": ("usa_probe_0.png", SIDE, "the Ariel scientific satellite: a small drum-shaped body with four paddle-shaped solar panels on arms and thin wire antennae"),
 "cwth/probe_1": ("usa_probe_0.png", SIDE, "a compact British lunar probe: a short cylindrical bus with a large dish antenna on top and two flat solar panels, a few small thrusters"),
 "cwth/probe_2": ("usa_probe_0.png", SIDE, "a small British three-legged lunar lander: a boxy instrument body on three thin legs with round footpads, a mast with one tilted solar panel"),
 "cwth/rocket_0": ("usa_rocket_0.png", UP, "the British Black Arrow rocket: a slim white two-stage rocket with a pointed nose, a slightly wider first stage, a cluster of four small engine bells at the base, no fins"),
 "cwth/rocket_1": ("usa_rocket_0.png", UP, "the British Blue Streak rocket with an upper stage: a broad polished stainless-steel first stage with two engine bells and a slimmer white upper stage with a pointed fairing"),
 "cwth/rocket_2": ("usa_rocket_0.png", UP, "a heavy British three-stage rocket: a wide stainless-steel first stage with four engine bells, a white second stage, a third stage and a long payload fairing, a small escape tower"),
 "cwth/rocket_3": ("usa_rocket_0.png", UP, "a colossal British super-heavy moon rocket: a very broad first stage with five large engine bells and small fins, three white and silver stages, a conical fairing and a slim escape tower"),
 "cwth/rocket_4": ("usa_rocket_0.png", UP, "two identical slim white strap-on liquid rocket boosters standing side by side a short gap apart, each with a conical nose and one engine bell, no core rocket between them"),
 "cwth/manned_4": ("cwth_manned_2.png", "standing upright on its legs", "a British direct-ascent lunar spacecraft: a dark grey conical crew capsule with a round window standing on a squat cylindrical stage with four splayed landing legs and a rocket engine underneath, a small RAF roundel"),
 "cwth/manned_5": ("cwth_manned_2.png", "standing upright on its legs", "a British two-man lunar lander: an octagonal descent stage wrapped in gold and black foil on four splayed legs with round footpads, a boxy silver ascent cabin with two windows and a hatch on top, a small RAF roundel"),
 "cwth/manned_6": ("cwth_manned_2.png", "standing upright on its legs", "a tiny British one-man open lunar lander: a small pressurised cabin pod with a round window on a lattice frame with three thin legs and one engine bell, a small RAF roundel"),
 "cwth/misc_0": ("cwth_manned_2.png", SIDE, "the Waxwing solid rocket motor: a small round spherical motor casing with one short nozzle at one end, no wings, no fins, no cabin"),
 "cwth/misc_1": ("cwth_manned_2.png", SIDE, "a compact British upper stage: a short plain white cylinder with flat ends and two small engine bells sticking out of one end, no wings, no fins, no cabin"),
 "cwth/misc_2": ("cwth_manned_2.png", SIDE, "a larger British upper stage: a smooth white cylinder with flat ends and one wide engine bell at one end, a small RAF roundel, no wings, no fins, no cabin"),
 "cwth/misc_3": ("cwth_manned_2.png", "standing upright", "a single empty British spacesuit standing upright: a white suit with a backpack, a helmet with a gold visor, a small Union Jack patch on the shoulder, nothing else"),
 "cwth/misc_4": ("cwth_manned_2.png", SIDE, "a short white cylindrical docking module with a probe-and-drogue docking ring at one end and a round hatch, a small RAF roundel, no wings"),
 "cwth/misc_5": ("usa_probe_0.png", SIDE, "a British photo-reconnaissance satellite: a long cylinder with a large camera lens at one end, two flat solar panels, a small Union Jack marking"),
}
TEMPLATE = ("Using image 1 only as the art style reference (thick clean black outlines, flat cel shading, muted palette, plain white "
            "background), draw a completely different vehicle in exactly that style: {desc}, {orient}. Replace the vehicle in image 1 "
            "entirely, exactly one vehicle, the whole vehicle visible and centred, no background, no ground, no text other than small markings.")
K0, K1 = int(os.environ.get("K0", 0)), int(os.environ.get("K1", 1))
uploaded = {}
for key in (sys.argv[2:] or list(D)):
    seed, orient, desc = D[key]
    side, stem = key.split("/"); (out / side).mkdir(parents=True, exist_ok=True)
    if seed not in uploaded:
        src = Image.open(U / seed).convert("RGBA"); bg = Image.new("RGB", src.size, (255, 255, 255)); bg.paste(src, mask=src.getchannel("A"))
        tmp = out / f"_seed_{seed}"; bg.resize((1024, 1024), Image.LANCZOS).save(tmp); uploaded[seed] = cb.upload_image(tmp)
    for k in range(K0, K1):
        img = cb.run_workflow(cb.edit_graph(uploaded[seed], TEMPLATE.format(desc=desc, orient=orient), cb.seed_for("hwseed/" + key) + k, 1024, 1024), timeout=1800)[0]
        img.convert("RGB").save(out / side / f"{stem}_s{k}.png"); print(key, k, flush=True)
print("ALL-DONE")
