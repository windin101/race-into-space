#!/usr/bin/env python3
"""Batch-generate game art through a local ComfyUI (Qwen-Image / Qwen-Image-Edit).

    python3 -I tools/comfy_batch.py portraits  [--limit 12] [--names GLENN,GAGARIN] [--only-missing]
    python3 -I tools/comfy_batch.py hardware   [--limit 6]  [--side usa]
    python3 -I tools/comfy_batch.py backdrops  [--names title,newscast_usa]
    python3 -I tools/comfy_batch.py --dry-run portraits --limit 1     # print the workflow, submit nothing

Portraits and hardware are RESTYLED from the procedural renders exported by
game/tools/art_export.tscn (reference/art_source/), so identities and silhouettes stay
keyed to the game data; backdrops are generated from text. Seeds are derived from the
asset name, so re-running regenerates the same image unless the prompt changes.

Outputs land directly where the game's ArtAssets loader expects them:
  game/assets/art/portraits/<NAME>.png        336x400
  game/assets/art/hardware/<side>/<group>_<slot>.png   512x512, green chroma-keyed to alpha
  game/assets/art/backdrops/<name>.png        1920x1080
The folders are covered by wildcard lines in game/assets/MANIFEST.md (seed = crc32(name) + --reseed).

Settings and prompts: tools/comfy_style.json. Requires the ComfyUI server running and
the Qwen weights in its model folders.
"""

import argparse
import json
import sys
import time
import urllib.parse
import urllib.request
import uuid
import zlib
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "game"
SOURCE = ROOT / "reference" / "art_source"
STYLE = json.loads((ROOT / "tools" / "comfy_style.json").read_text())
_FEAT = SOURCE / "portrait_features.json"
FEATURES = json.loads(_FEAT.read_text()) if _FEAT.exists() else {}
SERVER = STYLE["server"]
CLIENT = str(uuid.uuid4())

NATION = {"usa": "American", "ussr": "Soviet"}
ROLE = {"usa": "astronaut", "ussr": "cosmonaut"}
SUIT = {"usa": "blue", "ussr": "red"}
KIND = {"probe": "unmanned probe", "rocket": "launch rocket", "manned": "crewed spacecraft", "misc": "spacecraft module"}


# ----------------------------------------------------------------- ComfyUI API

def api(path: str, data: dict | None = None):
    url = SERVER + path
    if data is None:
        with urllib.request.urlopen(url, timeout=60) as r:
            return json.loads(r.read())
    req = urllib.request.Request(url, data=json.dumps(data).encode(), headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read())


def upload_image(path: Path) -> str:
    """Upload a source image to ComfyUI's input folder; returns the stored name."""
    boundary = uuid.uuid4().hex
    body = (f"--{boundary}\r\nContent-Disposition: form-data; name=\"image\"; filename=\"{path.name}\"\r\n"
            f"Content-Type: image/png\r\n\r\n").encode() + path.read_bytes() + f"\r\n--{boundary}\r\nContent-Disposition: form-data; name=\"overwrite\"\r\n\r\ntrue\r\n--{boundary}--\r\n".encode()
    req = urllib.request.Request(SERVER + "/upload/image", data=body, headers={"Content-Type": f"multipart/form-data; boundary={boundary}"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read())["name"]


def run_workflow(graph: dict, timeout: float = 900.0) -> list[Image.Image]:
    pid = api("/prompt", {"prompt": graph, "client_id": CLIENT})["prompt_id"]
    t0 = time.time()
    while time.time() - t0 < timeout:
        hist = api(f"/history/{pid}")
        if pid in hist:
            entry = hist[pid]
            if entry.get("status", {}).get("status_str") == "error":
                raise RuntimeError("ComfyUI error: " + json.dumps(entry["status"].get("messages", []))[:800])
            images = []
            for node_out in entry.get("outputs", {}).values():
                for im in node_out.get("images", []):
                    q = urllib.parse.urlencode({"filename": im["filename"], "subfolder": im.get("subfolder", ""), "type": im.get("type", "output")})
                    with urllib.request.urlopen(f"{SERVER}/view?{q}", timeout=120) as r:
                        images.append(Image.open(__import__("io").BytesIO(r.read())).convert("RGBA"))
            if images:
                return images
        time.sleep(1.5)
    raise TimeoutError("ComfyUI job did not finish")


def seed_for(name: str) -> int:
    return zlib.crc32(name.encode()) & 0x7FFFFFFF


# ----------------------------------------------------------------- workflows

def edit_graph(image_name: str, prompt: str, seed: int, width: int, height: int, style_name: str | None = None) -> dict:
    m, s = STYLE["models"], STYLE["sampling"]
    positive = {"clip": ["2", 0], "prompt": prompt, "vae": ["3", 0], "image1": ["5", 0]}
    graph_extra = {}
    if style_name:
        graph_extra["14"] = {"class_type": "LoadImage", "inputs": {"image": style_name}}
        graph_extra["15"] = {"class_type": "ImageScaleToTotalPixels", "inputs": {"image": ["14", 0], "upscale_method": "lanczos", "megapixels": round(width * height / 1e6, 2), "resolution_steps": 16}}
        positive["image2"] = ["15", 0]
    return graph_extra | {
        "1": {"class_type": "UNETLoader", "inputs": {"unet_name": m["edit"], "weight_dtype": "default"}},
        "2": {"class_type": "CLIPLoader", "inputs": {"clip_name": m["clip"], "type": "qwen_image"}},
        "3": {"class_type": "VAELoader", "inputs": {"vae_name": m["vae"]}},
        "4": {"class_type": "LoadImage", "inputs": {"image": image_name}},
        "5": {"class_type": "ImageScaleToTotalPixels", "inputs": {"image": ["4", 0], "upscale_method": "lanczos", "megapixels": round(width * height / 1e6, 2), "resolution_steps": 16}},
        "6": {"class_type": "TextEncodeQwenImageEditPlus", "inputs": positive},
        "7": {"class_type": "TextEncodeQwenImageEditPlus", "inputs": {"clip": ["2", 0], "prompt": STYLE["negative"], "vae": ["3", 0], "image1": ["5", 0]}},
        "8": {"class_type": "VAEEncode", "inputs": {"pixels": ["5", 0], "vae": ["3", 0]}},
        "9": {"class_type": "ModelSamplingAuraFlow", "inputs": {"model": ["1", 0], "shift": s["shift"]}},
        "10": {"class_type": "CFGNorm", "inputs": {"model": ["9", 0], "strength": 1.0}},
        "11": {"class_type": "KSampler", "inputs": {"model": ["10", 0], "seed": seed, "steps": s["steps"], "cfg": s["cfg"], "sampler_name": s["sampler"], "scheduler": s["scheduler"], "positive": ["6", 0], "negative": ["7", 0], "latent_image": ["8", 0], "denoise": 1.0}},
        "12": {"class_type": "VAEDecode", "inputs": {"samples": ["11", 0], "vae": ["3", 0]}},
        "13": {"class_type": "SaveImage", "inputs": {"images": ["12", 0], "filename_prefix": "ris/edit"}},
    }


def t2i_graph(prompt: str, seed: int, width: int, height: int, negative_extra: str = "") -> dict:
    m, s = STYLE["models"], STYLE["sampling"]
    return {
        "1": {"class_type": "UNETLoader", "inputs": {"unet_name": m["t2i"], "weight_dtype": "default"}},
        "2": {"class_type": "CLIPLoader", "inputs": {"clip_name": m["clip"], "type": "qwen_image"}},
        "3": {"class_type": "VAELoader", "inputs": {"vae_name": m["vae"]}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["2", 0], "text": prompt}},
        "5": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["2", 0], "text": STYLE["negative"] + (", " + negative_extra if negative_extra else "")}},
        "6": {"class_type": "EmptySD3LatentImage", "inputs": {"width": width, "height": height, "batch_size": 1}},
        "7": {"class_type": "ModelSamplingAuraFlow", "inputs": {"model": ["1", 0], "shift": 3.1}},
        "8": {"class_type": "KSampler", "inputs": {"model": ["7", 0], "seed": seed, "steps": s["steps"], "cfg": s["cfg"], "sampler_name": s["sampler"], "scheduler": s["scheduler"], "positive": ["4", 0], "negative": ["5", 0], "latent_image": ["6", 0], "denoise": 1.0}},
        "9": {"class_type": "VAEDecode", "inputs": {"samples": ["8", 0], "vae": ["3", 0]}},
        "10": {"class_type": "SaveImage", "inputs": {"images": ["9", 0], "filename_prefix": "ris/t2i"}},
    }


# ----------------------------------------------------------------- jobs

def roster_entries() -> list[dict]:
    roster = json.loads((GAME / "data" / "roster.json").read_text())
    out = []
    for side in ("usa", "ussr"):
        for group in roster["sides"][side]:
            for c in group["candidates"]:
                out.append({"name": c["name"], "female": c["female"], "side": side})
    for name, side in [("MANKE", "usa"), ("POWELL", "usa"), ("YEAGER", "usa"), ("ILYUSHIN", "ussr"), ("KRAMARENKO", "ussr"), ("DOLGOV", "ussr")]:
        out.append({"name": name, "female": False, "side": side})
    return out


def hardware_entries() -> list[dict]:
    hw = json.loads((GAME / "data" / "hardware.json").read_text())["models"]["basic"]
    out = []
    for side in ("usa", "ussr"):
        for group in ("probe", "rocket", "manned", "misc"):
            for slot, spec in enumerate(hw[side][group]):
                if spec:
                    out.append({"side": side, "group": group, "slot": slot, "name": spec["name"].title(),
                                "seed_key": f"{side}/{group}_{slot}"})
    return out


def trim_frame(img: Image.Image, max_frac: float = 0.1, bright: int = 170) -> Image.Image:
    """Crop away a pale frame the model sometimes paints around a portrait."""
    g = img.convert("L")
    w, h = g.size
    px = g.load()

    def line_mean(xs, ys):
        vals = [px[x, y] for x in xs for y in ys]
        return sum(vals) / len(vals)

    left = right = top = bottom = 0
    while left < w * max_frac and line_mean([left], range(h)) > bright:
        left += 1
    while right < w * max_frac and line_mean([w - 1 - right], range(h)) > bright:
        right += 1
    while top < h * max_frac and line_mean(range(w), [top]) > bright:
        top += 1
    while bottom < h * max_frac and line_mean(range(w), [h - 1 - bottom]) > bright:
        bottom += 1
    if left + right + top + bottom == 0:
        return img
    pad = 3
    return img.crop((left + pad, top + pad, w - right - pad, h - bottom - pad))


def fit_cover(img: Image.Image, size: tuple[int, int]) -> Image.Image:
    w, h = img.size
    scale = max(size[0] / w, size[1] / h)
    img = img.resize((round(w * scale), round(h * scale)), Image.LANCZOS)
    left = (img.width - size[0]) // 2
    top = (img.height - size[1]) // 2
    return img.crop((left, top, left + size[0], top + size[1]))


def chroma_key(img: Image.Image, key: tuple[int, int, int], tolerance: int = 90) -> Image.Image:
    """Green-screen removal that copes with the model's imperfect green: any pixel whose green
    channel dominates both red and blue is cut, partially so near the edge, and the remaining
    green spill on the subject's rim is neutralised."""
    import numpy as np

    arr = np.asarray(img.convert("RGBA")).astype(np.float32)
    r, g, b = arr[..., 0], arr[..., 1], arr[..., 2]
    dominance = g - np.maximum(r, b)  # how green a pixel is
    alpha = np.clip(1.0 - (dominance - 20.0) / 50.0, 0.0, 1.0)  # >=70 fully cut, <=20 kept
    arr[..., 3] = alpha * 255.0
    spill = np.clip(dominance, 0, None) * (alpha > 0)
    arr[..., 1] = np.minimum(g, np.maximum(r, b) + np.where(spill > 0, 10.0, 255.0))
    out = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")
    # Drop a floor shadow the model may paint: fully transparent rows below the subject are
    # already gone; crop the alpha bbox and recentre so the icon fills the tile.
    bbox = out.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()
    if bbox:
        sub = out.crop(bbox)
        scale = min((img.width * 0.9) / sub.width, (img.height * 0.9) / sub.height)
        sub = sub.resize((max(1, round(sub.width * scale)), max(1, round(sub.height * scale))), Image.LANCZOS)
        out = Image.new("RGBA", img.size, (0, 0, 0, 0))
        out.paste(sub, ((img.width - sub.width) // 2, (img.height - sub.height) // 2), sub)
    return out


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("kind", choices=["portraits", "hardware", "backdrops"])
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--names", default="", help="comma-separated names to restrict to")
    ap.add_argument("--side", default="", help="usa or ussr")
    ap.add_argument("--only-missing", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--reseed", type=int, default=0, help="add N to each seed to get a different draw for the same name")
    a = ap.parse_args()
    wanted = {n.strip().upper() for n in a.names.split(",") if n.strip()}
    style = STYLE["style"]

    if a.kind == "portraits":
        cfg = STYLE["portrait"]
        jobs = roster_entries()
    elif a.kind == "hardware":
        cfg = STYLE["hardware"]
        jobs = hardware_entries()
    else:
        cfg = STYLE["backdrops"]
        jobs = [{"name": k, "prompt": v} for k, v in cfg["prompts"].items()]
    if a.side:
        jobs = [j for j in jobs if j.get("side", "") == a.side]
    if wanted:
        jobs = [j for j in jobs if j["name"].upper() in wanted]
    if a.limit:
        jobs = jobs[: a.limit]

    done = 0
    for j in jobs:
        neg_item = ""
        if a.kind == "portraits":
            out = GAME / "assets" / "art" / "portraits" / f"{j['name']}.png"
            size = cfg["size"]
            if cfg.get("mode", "edit") == "t2i":
                src = None
                f = FEATURES.get(j["name"], {})
                extras = ""
                if f.get("glasses"):
                    extras += ", wearing glasses"
                if f.get("moustache"):
                    extras += ", with a moustache"
                prompt = cfg["t2i_prompt"].format(age=cfg.get("age", "thirty-five year old"), nationality=NATION[j["side"]], role=ROLE[j["side"]],
                                                  gender="a woman" if j["female"] else "a man", face=f.get("face", "oval"), skin=f.get("skin", "fair"),
                                                  hair=f.get("hair", "brown"), hair_style=f.get("hair_style", "short"), eyes=f.get("eyes", "brown"),
                                                  extras=extras, suit=SUIT[j["side"]])
            else:
                src = SOURCE / "portraits" / f"{j['name']}.png"
                prompt = cfg["prompt"].format(style=style, era=cfg["era"], nationality=NATION[j["side"]], role=ROLE[j["side"]],
                                              suit=SUIT[j["side"]], gender="a woman" if j["female"] else "a man")
        elif a.kind == "hardware":
            out = GAME / "assets" / "art" / "hardware" / j["side"] / f"{j['group']}_{j['slot']}.png"
            size = cfg["size"]
            if cfg.get("mode", "edit") == "t2i":
                src = None
                desc = cfg["descriptions"].get(j["name"], f"A {j['name']} {KIND[j['group']]}")
                neg_item = ""
                if isinstance(desc, dict):
                    neg_item, desc = desc.get("negative", ""), desc["desc"]
                prompt = cfg["t2i_prompt"].format(desc=desc, kind=KIND[j["group"]], nationality=NATION[j["side"]])
            else:
                src = SOURCE / "hardware" / j["side"] / f"{j['group']}_{j['slot']}.png"
                prompt = cfg["prompt"].format(style=style, name=j["name"], kind=KIND[j["group"]], nationality=NATION[j["side"]])
        else:
            out = GAME / "assets" / "art" / "backdrops" / f"{j['name']}.png"
            src = None
            prompt = j["prompt"].format(style=style)
            size = cfg["size"]
        if a.only_missing and out.exists():
            continue
        seed = seed_for(j.get("seed_key", j["name"])) + a.reseed
        if src is not None:
            if not src.exists():
                print(f"skip {j['name']}: no source render at {src} (run art_export.tscn)")
                continue
            style_ref = cfg.get("style_ref")
            style_name = None
            if style_ref and (ROOT / style_ref).exists():
                style_name = upload_image(ROOT / style_ref) if not a.dry_run else Path(style_ref).name
            if a.dry_run:
                print(json.dumps(edit_graph(src.name, prompt, seed, *size, style_name), indent=1)[:1500])
                return
            uploaded = upload_image(src)
            graph = edit_graph(uploaded, prompt, seed, *size, style_name)
        else:
            if a.dry_run:
                print(json.dumps(t2i_graph(prompt, seed, *size, ", ".join(x for x in [cfg.get("negative_extra", ""), neg_item] if x)), indent=1)[:1500])
                return
            graph = t2i_graph(prompt, seed, *size, ", ".join(x for x in [cfg.get("negative_extra", ""), neg_item] if x))
        t0 = time.time()
        img = run_workflow(graph)[0]
        if a.kind == "portraits":
            img = fit_cover(trim_frame(img), tuple(cfg["output"])).convert("RGB")
        elif a.kind == "hardware":
            img = chroma_key(fit_cover(img, tuple(cfg["output"])), tuple(cfg["chroma_key"]))
        else:
            img = img.convert("RGB")
        out.parent.mkdir(parents=True, exist_ok=True)
        img.save(out)
        done += 1
        print(f"{done}/{len(jobs)} {out.relative_to(ROOT)}  ({time.time() - t0:.0f}s)")
    if done:
        print("MANIFEST.md covers these folders with wildcard lines; per-image seeds are crc32 of the name plus --reseed.")

if __name__ == "__main__":
    main()
