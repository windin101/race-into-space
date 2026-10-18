#!/usr/bin/env bash
# Regression gate: replay the seeded two-player AI games and compare every season's
# prestige, cash and launches with tools/fingerprint_2p_baseline.txt. A change that is not
# meant to alter the rules must reproduce it exactly; one that is meant to re-records it
# (and says so in docs/specs/tuning-notes.md).
#   tools/check_fingerprint.sh           # compare
#   tools/check_fingerprint.sh --record  # overwrite the baseline
set -uo pipefail
GODOT="${GODOT_BIN:-$HOME/.local/bin/godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="$ROOT/tools/fingerprint_2p_baseline.txt"
GAMES=$(grep -c . "$BASE")
out=$("$GODOT" --headless --path "$ROOT/game" -s res://tools/sim_fingerprint.gd -- --games "$GAMES" --sides usa,ussr 2>/dev/null | grep -E '^game [0-9]+ seed')
if [ "${1:-}" = "--record" ]; then
  echo "$out" > "$BASE"; echo "recorded $GAMES games"; exit 0
fi
if diff <(echo "$out") "$BASE" > /dev/null; then
  echo "FINGERPRINT OK ($GAMES games)"
else
  echo "FINGERPRINT CHANGED:"; diff <(echo "$out") "$BASE" | head -20; exit 1
fi
