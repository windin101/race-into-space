#!/usr/bin/env bash
# Run the gdUnit4 suite headless. Uses $GODOT_BIN or ~/.local/bin/godot.
# Exits 1 if any suite reports failures or errors.
set -uo pipefail
GODOT="${GODOT_BIN:-$HOME/.local/bin/godot}"
cd "$(dirname "$0")/../game"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
out=$("$GODOT" --headless --path . -s -d res://addons/gdUnit4/bin/GdUnitCmdTool.gd --add res://test --ignoreHeadlessMode "$@" 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
echo "$out" | grep -E 'PASSED|FAILED|ERROR|Statistics|Expecting|but was|WARNING' | sed 's#res://test/##'
if echo "$out" | grep -E '^Statistics' | grep -qv '0 errors | 0 failures'; then
  echo "TESTS FAILED"; exit 1
fi
echo "ALL TESTS PASSED"
