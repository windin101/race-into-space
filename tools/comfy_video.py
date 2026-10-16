#!/usr/bin/env python3
"""Animated mission vignettes: a Qwen-Image keyframe in the game's flat style, animated by
Wan 2.2 image-to-video (14B GGUF, Lightning 4-step LoRAs), written as WebP frame sequences
that the playback stage already knows how to play.

    python3 -I tools/comfy_video.py                        # every family/outcome with no frames yet
    python3 -I tools/comfy_video.py --families launch --outcomes fail
    python3 -I tools/comfy_video.py --force --families reentry   # redo even if frames exist
    python3 -I tools/comfy_video.py --dry-run

Output: game/assets/art/vignettes/<family>_<ok|fail>/frame_NNNN.webp plus SOURCE.txt.
Families that already have archival footage are left alone unless --force is given.
Prompts: the "vignettes" block of tools/comfy_style.json. Requires the ComfyUI server.
"""

import argparse
import json
import shutil
import sys
import time
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import comfy_batch as cb  # noqa: E402

ROOT = cb.ROOT
GAME = cb.GAME
CFG = cb.STYLE["vignettes"]
OUT_DIR = GAME / "assets" / "art" / "vignettes"

VIDEO_MODELS = {
    "high": "wan2.2_i2v_high_noise_14B_Q4_K_M.gguf",
    "low": "wan2.2_i2v_low_noise_14B_Q4_K_M.gguf",
    "lora_high": "Wan2.2-Lightning_I2V-A14B-4steps-lora_HIGH_fp16.safetensors",
    "lora_low": "Wan2.2-Lightning_I2V-A14B-4steps-lora_LOW_fp16.safetensors",
    "clip": "umt5_xxl_fp8_e4m3fn_scaled.safetensors",
    "vae": "wan_2.1_vae.safetensors",
}
WAN_FPS = 16


def i2v_graph(image_name: str, prompt: str, negative: str, seed: int, width: int, height: int, length: int) -> dict:
    m = VIDEO_MODELS
    return {
        "1": {"class_type": "UnetLoaderGGUF", "inputs": {"unet_name": m["high"]}},
        "2": {"class_type": "UnetLoaderGGUF", "inputs": {"unet_name": m["low"]}},
        "3": {"class_type": "CLIPLoader", "inputs": {"clip_name": m["clip"], "type": "wan"}},
        "4": {"class_type": "VAELoader", "inputs": {"vae_name": m["vae"]}},
        "5": {"class_type": "LoraLoaderModelOnly", "inputs": {"model": ["1", 0], "lora_name": m["lora_high"], "strength_model": 1.0}},
        "6": {"class_type": "LoraLoaderModelOnly", "inputs": {"model": ["2", 0], "lora_name": m["lora_low"], "strength_model": 1.0}},
        "7": {"class_type": "ModelSamplingSD3", "inputs": {"model": ["5", 0], "shift": 8.0}},
        "8": {"class_type": "ModelSamplingSD3", "inputs": {"model": ["6", 0], "shift": 8.0}},
        "9": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["3", 0], "text": prompt}},
        "10": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["3", 0], "text": negative}},
        "11": {"class_type": "LoadImage", "inputs": {"image": image_name}},
        "12": {"class_type": "WanImageToVideo", "inputs": {"positive": ["9", 0], "negative": ["10", 0], "vae": ["4", 0],
                                                          "width": width, "height": height, "length": length, "batch_size": 1,
                                                          "start_image": ["11", 0]}},
        "13": {"class_type": "KSamplerAdvanced", "inputs": {"model": ["7", 0], "add_noise": "enable", "noise_seed": seed, "steps": 4, "cfg": 1.0,
                                                           "sampler_name": "euler", "scheduler": "simple", "positive": ["12", 0], "negative": ["12", 1],
                                                           "latent_image": ["12", 2], "start_at_step": 0, "end_at_step": 2, "return_with_leftover_noise": "enable"}},
        "14": {"class_type": "KSamplerAdvanced", "inputs": {"model": ["8", 0], "add_noise": "disable", "noise_seed": seed, "steps": 4, "cfg": 1.0,
                                                           "sampler_name": "euler", "scheduler": "simple", "positive": ["12", 0], "negative": ["12", 1],
                                                           "latent_image": ["13", 0], "start_at_step": 2, "end_at_step": 10000, "return_with_leftover_noise": "disable"}},
        "15": {"class_type": "VAEDecode", "inputs": {"samples": ["14", 0], "vae": ["4", 0]}},
        "16": {"class_type": "SaveImage", "inputs": {"images": ["15", 0], "filename_prefix": "ris/vig"}},
    }


def to_stage(frame: Image.Image, size=(1920, 1080)) -> Image.Image:
    """Scale to fill the 16:9 stage (the clip is 832x480, nearly 16:9: a sliver is cropped)."""
    return cb.fit_cover(frame.convert("RGB"), size)


def write_sequence(frames: list, folder: Path, fps_out: int, note: str) -> int:
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    step = WAN_FPS / fps_out
    picked = [frames[min(len(frames) - 1, round(i * step))] for i in range(int(len(frames) / step))]
    for i, fr in enumerate(picked, 1):
        to_stage(fr).save(folder / f"frame_{i:04d}.webp", "WEBP", quality=85, method=4)
    (folder / "SOURCE.txt").write_text(note)
    return len(picked)


def jobs(a) -> list[dict]:
    out = []
    for fam, outcomes in CFG["scenes"].items():
        if a.families and fam not in a.families:
            continue
        for outcome in ("ok", "fail"):
            if a.outcomes and outcome not in a.outcomes:
                continue
            folder = OUT_DIR / f"{fam}_{outcome}"
            has_frames = folder.exists() and any(folder.glob("frame_*.webp"))
            archival = has_frames and (folder / "SOURCE.txt").exists() and "Qwen-Image" not in (folder / "SOURCE.txt").read_text()
            if has_frames and not a.force:
                continue
            if archival and not a.force:
                continue
            still, motion = outcomes[outcome]
            out.append({"family": fam, "outcome": outcome, "folder": folder, "still": still, "motion": motion})
    return out


KEYFRAMES = ROOT / "reference" / "vignette_keyframes"


def animate_keyframes(a) -> None:
    """Animate the Gemini keyframes under reference/vignette_keyframes/<fam>_<out>/<side>/<slot>.png
    into vignettes/<fam>_<out>/<side>/<slot>/frame_*.webp with the family's motion prompt."""
    vw, vh = CFG["video_size"]
    todo = []
    for png in sorted(KEYFRAMES.glob("*/*/*.png")):
        fam_out, side, slot = png.parent.parent.name, png.parent.name, png.stem
        fam, outcome = fam_out.rsplit("_", 1)
        if a.families and fam not in a.families: continue
        if a.outcomes and outcome not in a.outcomes: continue
        if a.sides and side not in a.sides: continue
        folder = OUT_DIR / fam_out / side / slot
        if folder.exists() and any(folder.glob("frame_*.webp")) and not a.force: continue
        todo.append((fam, outcome, side, slot, png, folder))
    if a.limit: todo = todo[:a.limit]
    print(f"{len(todo)} keyframe clip(s) to animate")
    for n, (fam, outcome, side, slot, png, folder) in enumerate(todo, 1):
        if a.dry_run:
            print(f"  {folder.relative_to(GAME)}"); continue
        motion = CFG["scenes"][fam][outcome][1]
        motion_prompt = CFG["motion_prompt"].format(motion=motion)
        seed = cb.seed_for(f"vignette/{fam}_{outcome}/{side}/{slot}") + a.reseed
        key = cb.fit_cover(Image.open(png).convert("RGB"), (vw, vh))
        tmp = ROOT / "reference" / "art_source" / "vignette_key.png"; tmp.parent.mkdir(parents=True, exist_ok=True); key.save(tmp)
        t0 = time.time()
        frames = cb.run_workflow(i2v_graph(cb.upload_image(tmp), motion_prompt, CFG["motion_negative"], seed, vw, vh, CFG["frames"]), timeout=3600)
        note = (f"Keyframe by Gemini 2.5 Flash Image from the {side} {slot} hardware icon (tools/vignette_keyframes.py), animated by "
                f"Wan 2.2 image-to-video (Apache 2.0) via tools/comfy_video.py --keyframes.\nseed {seed}\nmotion: {motion_prompt}\nLicence: CC0 (AI output)\n")
        count = write_sequence(frames, folder, CFG["fps_out"], note)
        print(f"{n}/{len(todo)} {fam}_{outcome}/{side}/{slot}: {count} frames ({time.time() - t0:.0f}s)", flush=True)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--keyframes", action="store_true", help="animate the Gemini keyframes under reference/vignette_keyframes into per-side, per-vehicle clips")
    ap.add_argument("--sides", default="", help="with --keyframes: comma-separated side ids")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--families", default="", help="comma-separated family names")
    ap.add_argument("--outcomes", default="", help="ok, fail or both")
    ap.add_argument("--clips", default="", help="exact clips, e.g. docking_fail,orbit_fail (overrides --families/--outcomes)")
    ap.add_argument("--force", action="store_true", help="regenerate even where frames exist (archival footage too)")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--reseed", type=int, default=0)
    ap.add_argument("--keep-stills", action="store_true", help="also save the keyframe under reference/art_source/vignettes/")
    a = ap.parse_args()
    a.families = [f for f in a.families.split(",") if f]
    a.outcomes = [o for o in a.outcomes.split(",") if o]
    a.clips = {c for c in a.clips.split(",") if c}
    a.sides = [x for x in a.sides.split(",") if x]
    if a.keyframes:
        animate_keyframes(a); return
    if a.clips:
        a.families, a.outcomes, a.force = [], [], True
    todo = [j for j in jobs(a) if not a.clips or f"{j['family']}_{j['outcome']}" in a.clips]
    print(f"{len(todo)} clip(s) to generate")
    sw, sh = CFG["still_size"]
    vw, vh = CFG["video_size"]
    for n, j in enumerate(todo, 1):
        name = f"{j['family']}_{j['outcome']}"
        seed = cb.seed_for("vignette/" + name) + a.reseed
        still_prompt = CFG["still_prompt"].format(scene=j["still"])
        motion_prompt = CFG["motion_prompt"].format(motion=j["motion"])
        if a.dry_run:
            print(f"{name}\n  still:  {still_prompt}\n  motion: {motion_prompt}")
            continue
        t0 = time.time()
        still = cb.run_workflow(cb.t2i_graph(still_prompt, seed, sw, sh, CFG["still_negative"]))[0]
        t1 = time.time()
        if a.keep_stills:
            keep = ROOT / "reference" / "art_source" / "vignettes"
            keep.mkdir(parents=True, exist_ok=True)
            still.convert("RGB").save(keep / f"{name}.png")
        key = cb.fit_cover(still.convert("RGB"), (vw, vh))
        tmp = ROOT / "reference" / "art_source" / "vignette_key.png"
        tmp.parent.mkdir(parents=True, exist_ok=True)
        key.save(tmp)
        uploaded = cb.upload_image(tmp)
        frames = cb.run_workflow(i2v_graph(uploaded, motion_prompt, CFG["motion_negative"], seed, vw, vh, CFG["frames"]), timeout=3600)
        t2 = time.time()
        note = (f"Generated for this project: Qwen-Image keyframe + Wan 2.2 image-to-video (Apache 2.0 models) via tools/comfy_video.py.\n"
                f"seed {seed}\nstill: {still_prompt}\nmotion: {motion_prompt}\nLicence: CC0 (AI output)\n")
        count = write_sequence(frames, j["folder"], CFG["fps_out"], note)
        print(f"{n}/{len(todo)} {name}: {count} frames  (still {t1 - t0:.0f}s, video {t2 - t1:.0f}s, {len(frames)} raw frames)")
    if todo and not a.dry_run:
        print("MANIFEST.md: the vignettes wildcard line covers these folders; each has a SOURCE.txt.")


if __name__ == "__main__":
    main()
