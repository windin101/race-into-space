#!/usr/bin/env python3
"""Batch the vignette keyframes through the Gemini image model, seeding each with the
hardware icon of the vehicle flown so the craft on screen is the one in the game.

    .venv-gemini/bin/python tools/vignette_keyframes.py --dry-run
    .venv-gemini/bin/python tools/vignette_keyframes.py --families reentry landing --sides usa ussr cwth --slots manned_0
    .venv-gemini/bin/python tools/vignette_keyframes.py            # the whole priority matrix

Writes reference/vignette_keyframes/<family>_<ok|fail>/<side>/<slot>.png (1664x960-ish, 16:9).
Key: $GEMINI_API_KEY or ~/.config/gemini/api_key. Existing files are skipped unless --force.
"""
import argparse, os, sys, time, json
from pathlib import Path
from PIL import Image
from google import genai
from google.genai import types

ROOT = Path(__file__).resolve().parent.parent
ICONS = ROOT / "game/assets/art/hardware"
OUT = ROOT / "reference/vignette_keyframes"
MODEL = "gemini-2.5-flash-image"

TEMPLATE = ("Wide 16:9 cinematic still in exactly the art style of the attached image: thick clean black outlines, flat cel shading, "
            "muted 1960s technical-illustration palette. The spacecraft in the attached image is the hero of the scene: keep its exact "
            "shape, proportions, colours and markings, do not redesign it. Scene: {scene}. {flavour}. Single clear subject, simple "
            "uncluttered background, no text, no captions, no logos other than the markings already on the spacecraft, no faces.")

# family: (vehicle group it shows, {ok: scene, fail: scene})
SCENES = {
 "launch": ("rocket", {
    "ok": "the rocket standing on its launch pad at the moment of liftoff, bright exhaust flame and billowing white smoke, a steel gantry tower beside it, dawn sky",
    "fail": "the rocket exploding a few metres above its pad: the lower stage torn open by a huge orange fireball, the rocket tilting and breaking apart, debris and black smoke rolling across the pad, the gantry engulfed"}),
 "insertion": ("rocket", {
    "ok": "the rocket's upper stage high above the curved blue Earth against black space, the spent first stage just separated and falling away below, engine lit",
    "fail": "the rocket's upper stage in space high above the curved Earth, its engine sputtering with a ragged uneven flame, the vehicle beginning to tumble and shed panels"}),
 "orbit": ("capsule", {
    "ok": "the spacecraft in orbit over a blue Earth with white clouds, stars beyond, sunlight from one side",
    "fail": "the spacecraft drifting in orbit with a plume of vapour venting from its side, tumbling slowly"}),
 "reentry": ("capsule", {
    "ok": "the capsule entering the atmosphere blunt heat-shield end first, the shield glowing orange-white with a long pink-orange plasma trail streaming back past the capsule, Earth's curved horizon below",
    "fail": "the capsule high in the upper atmosphere at the edge of space, entering at a bad angle, tumbling, plasma streaming unevenly off one side of the heat shield, pieces of the shield breaking away, the curved Earth a distant globe far below"}),
 "landing": ("capsule", {
    "ok": "the capsule descending under three large red-and-white parachutes toward {ground_ok}",
    "fail": "the capsule falling fast under plain white parachutes, one streaming tangled and the others only partly open, {ground_fail} rushing up"}),
 "docking": ("capsule", {
    "ok": "exactly two objects, both large and close to the camera, filling the middle of the frame, in orbit over the blue Earth: on the left the manned spacecraft from the attached image seen side-on, nose pointing right; on the right a single plain unmanned cylindrical target stage seen side-on, a bare metal drum with flat round ends, a small docking collar on its left end facing the spacecraft, no cabin, no windows, no nose cone; the two are a short gap apart; there is only one manned spacecraft in the picture, never two capsules",
    "fail": "in orbit high above the blue Earth against black starry space, the spacecraft coming in too fast at a crooked angle toward a plain cylindrical target vehicle, the docking collar about to strike the target's side, vapour puffing from its thrusters, no ground, no desert"}),
 "lm_descent": ("lander", {
    "ok": "the lunar lander descending toward the grey cratered lunar surface on a bright engine flame, the Earth small in the black sky",
    "fail": "the lunar lander tilted and coming down too fast toward the grey lunar surface, its engine flame sputtering"}),
 "lm_landing": ("lander", {
    "ok": "the lunar lander touching down on the grey lunar surface under a black starry sky, engine flame fading, dust spraying outward from under it",
    "fail": "the lunar lander hitting the lunar surface hard and tipping over, one leg crumpled, dust exploding outward"}),
 "power_on": ("probe", {
    "ok": "the satellite in orbit over the blue Earth, its solar panels just unfolded and an antenna extending, small status lights glowing",
    "fail": "the satellite in orbit over the blue Earth with one solar panel jammed half open, a puff of vapour from its side, tumbling slowly"}),
 "eva": ("capsule", {
    "ok": "an astronaut in a white spacesuit floating on a tether outside the open hatch of the spacecraft, the blue Earth filling the background",
    "fail": "an astronaut in a white spacesuit at the open hatch of the spacecraft, struggling to get back in, the suit stiff and ballooned, the tether tangled, Earth below"}),
 "lunar_pass": ("capsule", {
    "ok": "the spacecraft coasting past the Moon: the grey cratered lunar surface fills the bottom of the frame, black starry space above, the Earth small and blue in the distance",
    "fail": "the spacecraft near the Moon drifting off course, its engine bell dark, a thin trail of vapour, the grey cratered surface filling the bottom of the frame"}),
 "lm_ops": ("lander", {
    "ok": "the lunar lander just separated from its mother spacecraft in orbit around the Moon, the two a short distance apart, the grey cratered surface far below",
    "fail": "the lunar lander floating free in orbit, legs dangling in empty black space, nothing under it, one landing leg bent and vapour leaking from its descent stage; the grey cratered Moon is a distant curved globe far below in the lower part of the frame, the lander is not touching it"}),
 "lm_liftoff": ("lander", {
    "ok": "the ascent stage of the lunar lander lifting off, leaving its four-legged descent stage standing on the grey lunar surface below, a sharp bright flame between them, a flag beside the descent stage, Earth in the black sky",
    "fail": "the ascent stage of the lunar lander only just rising off its descent stage on the grey lunar surface, its flame weak and flickering, tilting to one side"}),
 "lm_test": ("lander", {
    "ok": "the lunar lander firing its descent engine in Earth orbit, a steady flame, the blue Earth below, its mother spacecraft nearby",
    "fail": "the lunar lander in Earth orbit with its engine flame burning ragged and uneven, a panel shaking loose, the blue Earth below"}),
 "photo": ("probe", {
    "ok": "the reconnaissance satellite in orbit over the blue Earth, its camera aimed down at a coastline far below, no ground detail other than the distant globe",
    "fail": "the reconnaissance satellite in orbit over the blue Earth, its camera door jammed shut and a solar panel bent, drifting"}),
 "planetary": ("probe", {
    "ok": "the space probe cruising past a huge banded gas-giant planet, deep black space and stars, the planet filling one side of the frame",
    "fail": "the space probe drifting in deep space, its dish antenna pointing away from a distant small planet, tumbling slowly"}),
 "duration": ("capsule", {
    "ok": "the spacecraft in orbit over the blue Earth, the day-night terminator line crossing the globe below, the spacecraft lit from one side",
    "fail": "the spacecraft in orbit over the blue Earth, frost crystals forming on its hull and windows, a vent leaking a thin stream of vapour, drifting"}),
 "lunar_eva": ("lander", {
    "ok": "an astronaut in a white spacesuit standing on the grey lunar surface beside the lander, planting {flag} on a pole, Earth in the black sky, no rover",
    "fail": "an astronaut in a white spacesuit stumbling and falling in the dust beside the lander on the grey lunar surface, the sky above pure black with stars, no rover"}),
}
FLAVOUR = {
 "usa": {"markings": "American flag markings", "home": "Cape Canaveral, blue Atlantic", "flag": "the flag of the United States",
         "ground_ok": "a calm blue ocean, a recovery ship below", "ground_fail": "the sea"},
 "ussr": {"markings": "Red star markings", "home": "the Baikonur steppe", "flag": "the red Soviet flag with a gold hammer and sickle",
          "ground_ok": "dry flat grassland, coming down on land under a single big parachute", "ground_fail": "the flat dry grassland"},
 "cwth": {"markings": "RAF roundel and Union Jack markings", "home": "the red desert and scrub of Woomera", "flag": "a correct British Union Jack flag (red and white crosses on blue)",
          "ground_ok": "a flat red desert plain, a recovery helicopter nearby", "ground_fail": "the red desert"},
}
# families that happen on the ground see the side's home landscape; everything else is in
# space or the upper atmosphere, where the only ground is a distant curved globe
GROUND_FAMILIES = {"launch", "landing"}
SPACE = ("Setting: at the edge of space, very high altitude. The Earth far below is a distant curved globe of blue ocean and white cloud with a thin "
         "glowing blue atmosphere line on its limb and black starry space above; no buildings, no launch site, no roads, no fields, no ground detail "
         "of any kind, nothing on the surface is close")
# slots per vehicle group per side
SLOTS = {"rocket": ["rocket_0", "rocket_1", "rocket_2", "rocket_3"], "probe": ["probe_0", "probe_1", "probe_2"],
         "capsule": ["manned_0", "manned_1", "manned_2", "manned_3"],
         "lander": ["manned_4", "manned_5", "manned_6"]}

# the trimmed matrix the animator uses (tools/comfy_video.py): one lander, two capsules
# for orbit-type families; --all-slots makes every slot
def wanted(fam: str, slot: str) -> bool:
    group = SCENES[fam][0]
    if group == "lander":
        return slot == "manned_5"
    if fam in ("docking", "orbit", "duration", "eva", "lunar_pass", "power_on"):
        return slot in ("manned_0", "manned_1") if group == "capsule" else True
    return True


def flavour_for(fam: str, side: str) -> str:
    f = FLAVOUR[side]
    if fam in GROUND_FAMILIES:
        return f["markings"] + ", " + f["home"]
    if fam.startswith("lm_") or fam in ("lunar_eva", "lunar_pass", "planetary"):
        return f["markings"]
    return f["markings"] + ". " + SPACE


def key() -> str:
    k = os.environ.get("GEMINI_API_KEY") or (Path.home() / ".config/gemini/api_key").read_text().strip()
    return k

def jobs(args):
    for fam in args.families:
        group, scenes = SCENES[fam]
        for side in args.sides:
            for slot in (args.slots or SLOTS[group]):
                if not (ICONS / side / f"{slot}.png").exists(): continue
                if not args.slots and not args.all_slots and not wanted(fam, slot): continue
                for outcome in args.outcomes:
                    yield fam, outcome, side, slot, scenes[outcome].format(**FLAVOUR[side]), flavour_for(fam, side)

def icon_on_white(side: str, slot: str) -> Image.Image:
    im = Image.open(ICONS / side / f"{slot}.png").convert("RGBA"); bg = Image.new("RGB", im.size, (255, 255, 255)); bg.paste(im, mask=im.getchannel("A")); return bg

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--families", nargs="+", default=list(SCENES)); ap.add_argument("--sides", nargs="+", default=["usa", "ussr", "cwth"])
    ap.add_argument("--slots", nargs="+", default=None); ap.add_argument("--outcomes", nargs="+", default=["ok", "fail"])
    ap.add_argument("--dry-run", action="store_true"); ap.add_argument("--force", action="store_true"); ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--redo", nargs="+", default=[], help="specific keyframes to regenerate, as <family>_<outcome>/<side>/<slot>")
    ap.add_argument("--all-slots", action="store_true", help="every slot, not the trimmed matrix")
    a = ap.parse_args()
    todo = []
    if a.redo:
        for key_ in a.redo:
            fam_out, side, slot = key_.split("/"); fam, outcome = fam_out.rsplit("_", 1)
            group, scenes = SCENES[fam]
            todo.append((fam, outcome, side, slot, scenes[outcome].format(**FLAVOUR[side]), flavour_for(fam, side), OUT / fam_out / side / f"{slot}.png"))
    for fam, outcome, side, slot, scene, flavour in ([] if a.redo else jobs(a)):
        dst = OUT / f"{fam}_{outcome}" / side / f"{slot}.png"
        if dst.exists() and not a.force: continue
        todo.append((fam, outcome, side, slot, scene, flavour, dst))
    if a.limit: todo = todo[:a.limit]
    print(f"{len(todo)} keyframes to make")
    if a.dry_run:
        for t in todo: print(" ", t[6].relative_to(ROOT))
        return
    client = genai.Client(api_key=key())
    for i, (fam, outcome, side, slot, scene, flavour, dst) in enumerate(todo, 1):
        prompt = TEMPLATE.format(scene=scene, flavour=flavour)
        for attempt in range(3):
            try:
                resp = client.models.generate_content(model=MODEL, contents=[prompt, icon_on_white(side, slot)],
                                                      config=types.GenerateContentConfig(response_modalities=["IMAGE"],
                                                                                         image_config=types.ImageConfig(aspect_ratio="16:9")))
                img = next((p.inline_data for p in resp.candidates[0].content.parts if p.inline_data), None)
                if img is None: raise RuntimeError("no image in response: " + str(resp.candidates[0].finish_reason))
                dst.parent.mkdir(parents=True, exist_ok=True); dst.write_bytes(img.data)
                print(f"[{i}/{len(todo)}] {dst.relative_to(ROOT)}", flush=True); break
            except Exception as e:
                print(f"  retry {attempt+1}: {e}", flush=True); time.sleep(5 * (attempt + 1))
        time.sleep(1.0)
    print("ALL-DONE")

if __name__ == "__main__":
    main()
