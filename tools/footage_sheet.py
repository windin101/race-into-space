#!/usr/bin/env python3
"""Contact sheet of timestamped thumbnails from a video, for picking vignette shots.

    python3 -I tools/footage_sheet.py --src reel.mp4 --every 20 --cols 8 --out sheet.png [--start 0 --duration 1200]

One thumbnail every `every` seconds, each stamped with its timecode, tiled `cols` wide.
Long reels produce several sheets (sheet_1.png, sheet_2.png ...) of at most `rows` rows.
"""

import argparse
import math
import subprocess
from pathlib import Path


def duration_of(src: Path) -> float:
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(src)],
                         capture_output=True, text=True, check=True).stdout.strip()
    return float(out)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True, type=Path)
    ap.add_argument("--every", type=float, default=20.0)
    ap.add_argument("--cols", type=int, default=8)
    ap.add_argument("--rows", type=int, default=10)
    ap.add_argument("--width", type=int, default=240)
    ap.add_argument("--start", type=float, default=0.0)
    ap.add_argument("--duration", type=float, default=0.0, help="0 = to the end")
    ap.add_argument("--out", required=True, type=Path)
    a = ap.parse_args()
    total = duration_of(a.src)
    span = a.duration if a.duration > 0 else total - a.start
    per_sheet = a.every * a.cols * a.rows
    sheets = max(1, math.ceil(span / per_sheet))
    for i in range(sheets):
        t0 = a.start + i * per_sheet
        length = min(per_sheet, a.start + span - t0)
        out = a.out if sheets == 1 else a.out.with_name(f"{a.out.stem}_{i + 1}{a.out.suffix}")
        vf = (f"fps=1/{a.every},scale={a.width}:-2,"
              f"drawtext=text='%{{pts\\:hms}}':x=4:y=4:fontsize=16:fontcolor=white:box=1:boxcolor=black@0.6,"
              f"tile={a.cols}x{a.rows}")
        cmd = ["ffmpeg", "-y", "-loglevel", "error", "-ss", str(t0), "-t", str(length), "-copyts", "-i", str(a.src),
               "-vf", vf, "-frames:v", "1", str(out)]
        subprocess.run(cmd, check=True)
        print(f"wrote {out} covering {t0:.0f}s to {t0 + length:.0f}s")


if __name__ == "__main__":
    main()
