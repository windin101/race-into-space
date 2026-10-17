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
    "fail": "the rocket's upper stage high over the curved Earth, its engine sputtering with a ragged uneven flame, the vehicle beginning to tumble"}),
 "orbit": ("capsule", {
    "ok": "the spacecraft in orbit over a blue Earth with white clouds, stars beyond, sunlight from one side",
    "fail": "the spacecraft drifting in orbit with a plume of vapour venting from its side, tumbling slowly"}),
 "reentry": ("capsule", {
    "ok": "the capsule entering the atmosphere blunt heat-shield end first, the shield glowing orange-white with a long pink-orange plasma trail streaming back past the capsule, Earth's curved horizon below",
    "fail": "the capsule high in the upper atmosphere entering at a bad angle, tumbling, plasma streaming unevenly off one side of the heat shield, pieces of the shield breaking away, the curved Earth far below"}),
 "landing": ("capsule", {
    "ok": "the capsule descending under three large red-and-white parachutes toward {ground_ok}",
    "fail": "the capsule falling fast under plain white parachutes, one streaming tangled and the others only partly open, {ground_fail} rushing up"}),
 "docking": ("capsule", {
    "ok": "the spacecraft approaching nose first toward a single plain cylindrical unmanned target stage (not another spacecraft of the same type) in orbit over the blue Earth, the docking collar lined up, a few metres apart",
    "fail": "in orbit high above the blue Earth against black starry space, the spacecraft coming in too fast at a crooked angle toward a plain cylindrical target vehicle, the docking collar about to strike the target's side, vapour puffing from its thrusters, no ground, no desert"}),
 "lm_descent": ("lander", {
    "ok": "the lunar lander descending toward the grey cratered lunar surface on a bright engine flame, the Earth small in the black sky",
    "fail": "the lunar lander tilted and coming down too fast toward the grey lunar surface, its engine flame sputtering"}),
 "lm_landing": ("lander", {
    "ok": "the lunar lander touching down on the grey lunar surface under a black starry sky, engine flame fading, dust spraying outward from under it",
    "fail": "the lunar lander hitting the lunar surface hard and tipping over, one leg crumpled, dust exploding outward"}),
 "lunar_eva": ("lander", {
    "ok": "an astronaut in a white spacesuit standing on the grey lunar surface beside the lander, planting {flag} on a pole, Earth in the black sky, no rover",
    "fail": "an astronaut in a white spacesuit stumbling and falling in the dust beside the lander on the lunar surface, no rover"}),
}
FLAVOUR = {
 "usa": {"flavour": "American flag markings; the Earth below painted as blue ocean and white cloud, no recognisable coastlines or map outlines", "flag": "the flag of the United States", "ground_ok": "a calm blue ocean, a recovery ship below", "ground_fail": "the sea"},
 "ussr": {"flavour": "Red star markings; for a landing the capsule comes down onto dry flat grassland, not water", "flag": "the red Soviet flag with a gold hammer and sickle", "ground_ok": "a flat brown steppe, coming down on land under a single big parachute", "ground_fail": "the flat brown steppe"},
 "cwth": {"flavour": "RAF roundel and Union Jack markings, the red desert and scrub of Woomera", "flag": "a correct British Union Jack flag (red and white crosses on blue)", "ground_ok": "a flat red desert plain, a recovery helicopter nearby", "ground_fail": "the red desert"},
}
# slots per vehicle group per side
SLOTS = {"rocket": ["rocket_0", "rocket_1", "rocket_2", "rocket_3"],
         "capsule": ["manned_0", "manned_1", "manned_2", "manned_3"],
         "lander": ["manned_4", "manned_5", "manned_6"]}

def key() -> str:
    k = os.environ.get("GEMINI_API_KEY") or (Path.home() / ".config/gemini/api_key").read_text().strip()
    return k

def jobs(args):
    for fam in args.families:
        group, scenes = SCENES[fam]
        for side in args.sides:
            for slot in (args.slots or SLOTS[group]):
                if not (ICONS / side / f"{slot}.png").exists(): continue
                for outcome in args.outcomes:
                    yield fam, outcome, side, slot, scenes[outcome].format(**FLAVOUR[side]), FLAVOUR[side]["flavour"]

def icon_on_white(side: str, slot: str) -> Image.Image:
    im = Image.open(ICONS / side / f"{slot}.png").convert("RGBA"); bg = Image.new("RGB", im.size, (255, 255, 255)); bg.paste(im, mask=im.getchannel("A")); return bg

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--families", nargs="+", default=list(SCENES)); ap.add_argument("--sides", nargs="+", default=["usa", "ussr", "cwth"])
    ap.add_argument("--slots", nargs="+", default=None); ap.add_argument("--outcomes", nargs="+", default=["ok", "fail"])
    ap.add_argument("--dry-run", action="store_true"); ap.add_argument("--force", action="store_true"); ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--redo", nargs="+", default=[], help="specific keyframes to regenerate, as <family>_<outcome>/<side>/<slot>")
    a = ap.parse_args()
    todo = []
    if a.redo:
        for key_ in a.redo:
            fam_out, side, slot = key_.split("/"); fam, outcome = fam_out.rsplit("_", 1)
            group, scenes = SCENES[fam]
            todo.append((fam, outcome, side, slot, scenes[outcome].format(**FLAVOUR[side]), FLAVOUR[side]["flavour"], OUT / fam_out / side / f"{slot}.png"))
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
