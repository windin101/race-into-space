#!/usr/bin/env bash
# Animate every vignette keyframe that has no clip yet, split across the two GPUs.
# Needs ComfyUI on :8188 (GPU 0) and :8190 (GPU 1, started with --cuda-device 1; 8189 is Lee's craft tooling).
#   tools/animate_vignettes.sh                 # everything missing
#   tools/animate_vignettes.sh --families reentry,launch
cd "$(dirname "$0")/.."
python3 -I tools/comfy_video.py --keyframes --shard 0/2 "$@" 2>&1 | grep -v -i 'nvml\|pynvml' | sed 's/^/[gpu0] /' &
COMFY_SERVER=http://127.0.0.1:8190 python3 -I tools/comfy_video.py --keyframes --shard 1/2 "$@" 2>&1 | grep -v -i 'nvml\|pynvml' | sed 's/^/[gpu1] /' &
wait
