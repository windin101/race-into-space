# Adding a faction

A side is data and art. If adding one needs a code change, that is a bug: the guard test
`game/test/sim/test_sides_extensible.gd` plays a made-up side defined only in test data,
and should keep passing.

Use an id of lower-case letters, for example `cwth`. Everything below is keyed by it.

## 1. Registry: `game/data/sides.json`

Add an entry to `sides`:

| field | meaning |
|---|---|
| `id` | the key used everywhere else |
| `name`, `short`, `adjective`, `nation` | "United Kingdom...", "CW", "Commonwealth", "The Commonwealth" |
| `people` | the word for its crews: astronaut, cosmonaut, ... (used in titles and art prompts) |
| `accent`, `accent_dark`, `room_tint` | hex colours: UI accent, its dark variant, the office backdrop tint |
| `suit` | flight-suit colour words for portrait prompts |
| `site`, `capital_announces`, `agency` | spaceport name, how its news is announced, its intelligence agency |
| `reviewer`, `reviewer_deputy`, `reviewer_deputy_from`, `reviewer_deputy_to`, `review_body` | who gives the annual review, and the index band where the deputy appears |
| `heads_of_state` | `[[last_two_digit_year, name], ...]` for newscast placeholders |
| `text_slot` | which slot of the per-side text decks it uses (reviews, endgame); give it its own once those decks are written |
| `rules` | whose personnel rules it follows (`usa` or `ussr`) |

Raise `max_sides` if the new side should be able to join a three-way race and the screens
have room (they are laid out for four).

## 2. Game data

| file | block to add |
|---|---|
| `data/hardware.json` | `models.basic.<id>` and `models.historical.<id>`: the 21 slots, same groups and order as the other sides |
| `data/roster.json` | `sides.<id>`: five recruit groups of candidates |
| `data/new_game.json` | `sides.<id>` (director name, starting budget), `default_difficulty.<id>`, `default_astronaut_level.<id>` |
| `data/text/events.json` | `<id>`: the newscast card lines |
| `data/text/news.json` | `astronaut_news.<id>`, `retirement_reasons.<id>`, `filler_news.<id>` |
| `data/text/reviews.json`, `data/text/endgame.json` | lines for its `text_slot` |
| `data/audio/music_map.json` | optional `<screen>_<id>` entries for side-specific music |

## 3. Art

Each tool reads the side list from the registry, so a new id is picked up automatically.

| asset | where | tool |
|---|---|---|
| spaceport background | `assets/art/spaceport/<id>/background_spring.png` | `comfy_batch.py backdrops`, then `season_grade.py` for autumn |
| buildings, pads, flag cutouts | `assets/art/spaceport/<id>/` | `comfy_batch.py spaceport --side <id>`; add the side's site plan to `INTENT` in `spaceport_layout.py`, then run it |
| hardware icons | `assets/art/hardware/<id>/` | `comfy_batch.py hardware --side <id>` with descriptions in `comfy_style.json` |
| portraits | `assets/art/portraits/<NAME>.png` | `art_export.tscn`, then `comfy_batch.py portraits --side <id>` |
| mission patches | `assets/art/patches/<id>/` | `comfy_batch.py patches --side <id>`; add its colours to `patches.colours` and its flag to `flag_motif` |
| emblem, agency seal | `assets/art/icons/emblem_<id>.png`, `intel_<id>.png` | `comfy_batch.py icons` |
| flag | `assets/art/icons/flag_<id>.svg` | hand-drawn SVG |
| mission control room | `assets/art/backdrops/mission_control_<id>.png` | `comfy_batch.py backdrops` |
| newscast studio, review room, endgame paintings | `backdrops/newscast_<id>.png`, `review_<id>.png`, `endgame_<id>_win.png`, `endgame_<id>_lose.png` | `comfy_batch.py backdrops` |

Record every new file in `assets/MANIFEST.md` (wildcard lines are fine).

## 4. Check

```
tools/run_tests.sh
cd game && DISPLAY=:1 godot --path . --rendering-driver opengl3 res://tools/ui_screenshots.tscn -- --out <dir> --side <id>
```

Zero layout problems, every screen read through on the new side, then balance with
`tools/sim_cli.gd` batch runs (see `docs/specs/tuning-notes.md`).
