#!/usr/bin/env python3
"""Turn a clip of archival footage into a vignette frame sequence the game can use.

    python3 -I tools/footage_import.py --src clip.mp4 --family launch --outcome ok \
        --start 00:00:03 --duration 3 --fps 12 --source-url "https://..." --licence "Public domain (NASA)"

Writes game/assets/art/vignettes/<family>_<outcome>/frame_0001.png ... at 1920x1080
(letterboxed, never stretched), prints the manifest line to add to game/assets/MANIFEST.md,
and records the provenance beside the frames in SOURCE.txt. Families and outcomes are
those in docs/art-asset-list.md section 4. Requires ffmpeg.

Keep clips short (2 to 4 s) and frame rates modest (10 to 15 fps): the player stretches
the sequence over the step duration, and 36 PNG frames at 1080p is about 20 MB.
"""

import argparse
import shutil
import subprocess
from pathlib import Path

FAMILIES = ["launch", "insertion", "power_on", "reentry", "landing", "orbit", "lunar_pass", "eva",
            "lunar_eva", "docking", "lm_ops", "lm_descent", "lm_landing", "lm_liftoff", "lm_test",
            "photo", "planetary", "duration"]


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--src", required=True, type=Path, help="downloaded clip (any format ffmpeg reads)")
    ap.add_argument("--family", required=True, choices=FAMILIES)
    ap.add_argument("--outcome", default="ok", choices=["ok", "fail"])
    ap.add_argument("--start", default="0", help="start time, e.g. 00:01:23.5")
    ap.add_argument("--duration", type=float, default=3.0)
    ap.add_argument("--fps", type=int, default=12)
    ap.add_argument("--source-url", default="")
    ap.add_argument("--licence", default="Public domain (NASA)")
    ap.add_argument("--out-root", type=Path, default=Path("game/assets/art/vignettes"))
    ap.add_argument("--video", action="store_true", help="also write an Ogg Theora .ogv beside the frames")
    a = ap.parse_args()
    if shutil.which("ffmpeg") is None:
        raise SystemExit("ffmpeg is required")
    if not a.src.is_file():
        raise SystemExit(f"no such file: {a.src}")

    out_dir = a.out_root / f"{a.family}_{a.outcome}"
    out_dir.mkdir(parents=True, exist_ok=True)
    for old in out_dir.glob("frame_*.png"):
        old.unlink()
    scale = "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=black"
    cmd = ["ffmpeg", "-y", "-loglevel", "error", "-ss", a.start, "-t", str(a.duration), "-i", str(a.src),
           "-vf", f"fps={a.fps},{scale}", "-start_number", "1", str(out_dir / "frame_%04d.png")]
    subprocess.run(cmd, check=True)
    frames = sorted(out_dir.glob("frame_*.png"))
    if a.video:
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-ss", a.start, "-t", str(a.duration), "-i", str(a.src),
                        "-vf", scale, "-c:v", "libtheora", "-q:v", "7", "-an",
                        str(a.out_root / f"{a.family}_{a.outcome}.ogv")], check=True)
    (out_dir / "SOURCE.txt").write_text(
        f"source: {a.src.name}\nurl: {a.source_url}\nlicence: {a.licence}\nstart: {a.start}\nduration: {a.duration}\nfps: {a.fps}\n")
    rel = f"art/vignettes/{a.family}_{a.outcome}/"
    print(f"wrote {len(frames)} frames to {out_dir}")
    print("manifest line:")
    print(f"| {rel}frame_*.png | {a.family} vignette ({a.outcome}), {len(frames)} frames | {a.source_url or a.src.name} | {a.licence} |")


if __name__ == "__main__":
    main()
