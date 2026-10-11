#!/usr/bin/env bash
# Run the gdUnit4 suite headless. Uses $GODOT_BIN or ~/.local/bin/godot.
set -euo pipefail
GODOT="${GODOT_BIN:-$HOME/.local/bin/godot}"
cd "$(dirname "$0")/../game"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . -s -d res://addons/gdUnit4/bin/GdUnitCmdTool.gd --add res://test --ignoreHeadlessMode "$@" \
  | sed 's/\x1b\[[0-9;]*m//g' | grep -E 'PASSED|FAILED|ERROR|Statistics|Expecting|but was' || true
