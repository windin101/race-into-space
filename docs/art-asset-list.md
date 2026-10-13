# Graphical assets to replace the procedural placeholders

Everything visual is currently drawn by code (`game/scripts/art/`, `game/scripts/playback/vignettes.gd`).
This list is what an artist delivers to replace each painter, with formats and sizes.
Style rules are in `docs/art-style.md`. Sizes are given for the 1920x1080 design canvas
drawn at 2x (3840x2160), which is what a 4K display shows at UI scale 1.0.

## Formats Godot 4 takes

| use | format | notes |
|---|---|---|
| paintings, portraits, frames | PNG, 24-bit + alpha where needed, sRGB | lossless; mipmaps are generated on import |
| icons, emblems, flags | SVG (preferred) or PNG | SVG is rasterised at import at a chosen scale, so one file serves every UI scale |
| animation | PNG image sequence (`name_0001.png`...) or Ogg Theora `.ogv` | Theora is the only video codec in Godot core; sequences are safest |
| anything else | WebP is accepted but PNG is preferred for lossless art | |

Deliver transparent backgrounds wherever an element sits on another layer. Keep file
names lowercase with underscores; the loader keys on them.

## 1. Spaceports (two paintings, layered)

Canvas 3840x2160 for 16:9. Ultrawide monitors extend the logical canvas to 2580x1080,
so paint the background 5160x2160 with the 3840-wide composition centred and the extra
660 px each side as continuation (sky, sea, scrub), not new content.

Layers: the background is one full-canvas PNG; every other layer is a cutout with alpha
that the painter fits (aspect preserved, centred) into its rectangle below:

| layer | USA (Cape Canaveral) | USSR (Baikonur) | count |
|---|---|---|---|
| background: sky, horizon, ground, roads | spring and fall | spring and fall (fall washed lighter) | 4 |
| building, built | one per building below | same | 12 x 2 |
| building, unbuilt plot | cleared ground | same | 12 x 2 |
| pad: site (unbuilt), operational, damaged | three states | same | 3 x 2 |
| flag on pole (end-turn control) | US flag | Soviet flag | 2 |

Building rectangles at 3840x2160 (from `data/ui/spaceport_layout.json`; the painting
may spill outside the box, the box is the click target):

| id | title | x | y | w | h |
|---|---|---|---|---|---|
| administration | Administration | 230 | 1339 | 614 | 302 |
| research | Research & Development | 998 | 1188 | 576 | 259 |
| programs | Program Offices | 998 | 1490 | 576 | 173 |
| astronaut_complex | Astronaut Complex | 230 | 1728 | 691 | 259 |
| training | Training Centre | 1037 | 1728 | 538 | 238 |
| vab | Vehicle Assembly | 1728 | 1296 | 499 | 475 |
| mission_control | Mission Control | 1728 | 1858 | 614 | 194 |
| pad_1 | Launch Pad 1 | 2534 | 864 | 307 | 259 |
| pad_2 | Launch Pad 2 | 2918 | 1123 | 307 | 259 |
| pad_3 | Launch Pad 3 | 3302 | 1382 | 307 | 259 |
| museum | Space Museum | 2458 | 1771 | 576 | 238 |
| intelligence | Intelligence | 3149 | 1814 | 461 | 194 |
| flag | End turn | 3456 | 216 | 269 | 302 |

If the composition wants buildings elsewhere, move the rectangles in the layout file
rather than painting off-grid; hotspots follow the file.

Files: `assets/art/spaceport/<usa|ussr>/background_<spring|fall>.png`,
`building_<id>.png`, `plot_<id>.png`, `pad_<site|ok|damaged>.png`, `flag.png`.

## 2. Hardware illustrations (42)

One per program and side, shown on cards at 90x90 logical (180x180 at 4K) and later
larger on programme pages. Deliver 512x512 PNG with transparency, subject centred,
or SVG. The accent band in the side colour is part of the illustration.

USA: Explorer, Ranger, Surveyor, Atlas, Titan, Saturn, Nova, Boosters, Mercury, Gemini,
Apollo, XMS-2, Jupiter, Eagle, Cricket, Kicker-A, Kicker-B, Kicker-C, EVA Suits,
Docking Module, Photo Recon.
USSR: Sputnik, Cosmos, Luna, R-7, Proton, N1, UR-700, Boosters, Vostok, Voskhod, Soyuz,
Lapot, LK-700, LKM, LK, Kicker-A, Kicker-B, Kicker-C, EVA Suits, Docking Module,
Photo Recon.

Files: `assets/art/hardware/<usa|ussr>/<group>_<slot>.png` (groups probe, rocket,
manned, misc; slots per `docs/data-schema.md`), e.g. `rocket_0.png` is Atlas or R-7.

## 3. Astronaut portraits (230)

224 roster names plus the six bonus recruits from the event card (Manke, Powell, Yeager;
Ilyushin, Kramarenko, Dolgov). Head and shoulders, suit in the side's dark accent, plain
dark background. Cards show 84x100 logical; deliver 336x400 PNG (4x) or larger at the
same 0.84 aspect. Dead and retired tints are applied by code, so one image per person.

Files: `assets/art/portraits/<NAME>.png` with the name exactly as in
`game/data/roster.json` (upper case, e.g. `GRISSOM.png`, `P.POPOVICH.png`).

## 4. Mission vignettes (18 families x 2)

The playback stage is a 16:9 panel; deliver 1920x1080 frames. Each family needs a
success and a failure version. As image sequences, 24 to 48 frames at 1920x1080 PNG
(the player stretches the sequence over the step duration); or `.ogv` at 1920x1080,
2 to 3 seconds. Camera side-on, Earth low-left or below, Moon right, craft carries the
accent band; failures end in an explosion or an X and a red tint.

| family | step letters | subject |
|---|---|---|
| launch | A | liftoff from the pad |
| insertion | B, J, L | engine burn in Earth orbit, trans-lunar, lunar orbit insertion |
| power_on | C | satellite or module deploying |
| reentry | D, d | capsule re-entry |
| landing | E | parachute and splashdown |
| orbit | F, G, K, M, N, X, Y, f, g | craft in orbit (Earth or Moon) |
| lunar_pass | O | swing around the Moon |
| eva | H | spacewalk |
| lunar_eva | P | moonwalk and flag |
| docking | I | two craft joining |
| lm_ops | Q | LM separated in lunar orbit |
| lm_descent | R | powered descent |
| lm_landing | S | touchdown |
| lm_liftoff | T | ascent stage liftoff |
| lm_test | a | LM engine test in orbit |
| photo | U | reconnaissance pass |
| planetary | V, W, Z, e | probe cruise to a planet (Mercury, Venus, Mars, Jupiter, Saturn variants welcome) |
| duration | b, c | capsule in orbit with a day counter |

Files: `assets/art/vignettes/<family>_<ok|fail>/frame_0001.png` ... or
`assets/art/vignettes/<family>_<ok|fail>.ogv`.

## 5. Full-screen backdrops

| screen | count | size | notes |
|---|---|---|---|
| title | 1 | 3840x2160 PNG | key art; the title text is drawn by the game |
| newscast | 2 | 3840x2160 PNG | studio backdrop per side; anchor desk area left clear for text |
| annual review | 4 | 1024x1280 PNG | President, Vice President, General Secretary, Politburo portraits |
| end game | 4 | 3840x2160 PNG | victory and defeat per side |

Files: `assets/art/backdrops/title.png`, `newscast_<usa|ussr>.png`,
`review_<president|vp|secretary|politburo>.png`, `endgame_<usa|ussr>_<win|lose>.png`.

## 6. Icons and emblems (SVG)

| set | items | notes |
|---|---|---|
| building icons for the Administration menu | 5 (budget, purchase, missions, recruiting, preferences) | 64x64 design, monochrome in TEXT colour |
| agency emblems | CIA, KGB | Intelligence screen header |
| side emblems | US programme, Soviet programme | title and setup screens |
| flags | US, USSR | hub and tables |
| app icon | 1 | SVG plus 1024x1024 PNG; Flatpak also needs 128 and 256 PNG |
| mission patches | 62, one per mission (optional) | 256x256 PNG, shown in the VAB and museum |

Files: `assets/art/icons/<name>.svg`, `assets/art/patches/mission_<index>.png`.

## Wiring

Each painter will gain a loader that uses the file when it exists and falls back to the
procedural drawing when it does not, so assets can land one at a time. That loader is
not written yet; it is the first task once the first real asset arrives. Every file
must be added to `assets/MANIFEST.md` with its licence, and the manifest test will
refuse unlisted files.

## Generating the art locally (2026-10-12)

The portraits, hardware icons and backdrops are produced with Qwen-Image and
Qwen-Image-Edit (Apache 2.0) through the local ComfyUI server, driven by
`tools/comfy_batch.py` with prompts in `tools/comfy_style.json`:

```
DISPLAY=:1 godot --path game res://tools/art_export.tscn -- --out ../reference/art_source
python3 -I tools/comfy_batch.py portraits [--only-missing] [--names A,B] [--reseed N]
python3 -I tools/comfy_batch.py hardware
python3 -I tools/comfy_batch.py backdrops
python3 -I tools/art_review_sheet.py portraits --out /tmp/review.png
```

- Portraits are text-to-image only. The export step writes each name's deterministic
  feature set (face shape, skin, hair, eyes, moustache, glasses) to
  `reference/art_source/portrait_features.json`, and the prompt is built from those words.
  Image-edit with a style reference was tried and dropped: the model copies the reference
  face onto everyone. The look is anchored on `SHEPARD.png`; a pale painted frame is cropped
  by `trim_frame` in the batch tool. A bad draw is fixed by `--reseed 1` for that name.
- Hardware is text-to-image as well, from a one-line description per vehicle in
  `comfy_style.json`, painted on a green screen that `chroma_key` cuts by green dominance
  (the model's green is never pure #00ff00). Image-edit over the procedural silhouettes was
  tried first and left the source almost untouched. Ask for the craft "floating in empty
  space" and put ground, shadow and label in the negative prompt, or it paints a floor.
- Seeds are `crc32(name)` plus the reseed offset, so a rerun reproduces the same picture.
  `MANIFEST.md` covers the folders with wildcard lines rather than one line per file.
- Spaceports: `comfy_batch.py spaceport` renders the empty landscape per side and season,
  then one green-screen cutout per building, the generic plot, the three pad states and the
  flag (top half only, the model always paints a building at the pole's foot). The painter
  fits each cutout into its hotspot box grown by 30% and stands it on the box's baseline.
  Prompts that say "no rockets" get rockets; put the unwanted thing in the negative instead.
- Icons: the five Administration glyphs and the two flags are hand-drawn SVGs under
  `assets/art/icons/`. Emblems (fictional agencies, never real seals), the app icon and the
  mission patches come from `comfy_batch.py icons` and `comfy_batch.py patches`; a patch's
  motif is assembled from the mission name's keywords in `patch_motif()`, one per side so the
  colours match the programme. Shown by Administration, Intelligence, New Game and the VAB.
  Word choice matters more than negatives: "spidery lander" drew spiders, "capsule" alone drew
  pills; say "four-legged landing module" and "cone-shaped capsule with a heat shield".
- Vignettes without archival footage (every failure, and the ten families NASA never
  filmed) are animated: `tools/comfy_video.py` paints a 16:9 keyframe with Qwen-Image in the
  flat style, then Wan 2.2 image-to-video (14B GGUF, Lightning 4-step LoRAs, 832x480, 81
  frames) animates it; frames are resampled to 12 fps, scaled to 1920x1080 and saved as
  WebP. About 3.4 MB and a few minutes per clip. Prompts per family and outcome live in the
  `vignettes` block of `comfy_style.json`. Archival clips are never overwritten without
  `--force`.
- Mission playback is staged as a control room: `backdrops/mission_control_<side>.png` is
  the painted room (a wide shot from the back, far wall plain, so the monitor wall drawn by
  `mission_playback.gd` sits over it). The big screen plays the vignette; the four small
  monitors show the payload and booster icons, the crew portraits and a ground-track plot,
  all tinted with scanlines in code. Nothing in the painting needs to line up with a rect.
- Spaceport layout: `tools/spaceport_layout.py` places every building per side on its
  painting. It masks roads, tracks, water, sky, the foreground and the UI bars, starts each
  building at a hand-made site plan (INTENT in the script), nudges it to clear ground near a
  road, sizes it by depth from the horizon, and takes its height from the cutout's own
  aspect so the click box and the drawing agree. Output is the `sides` block of
  `data/ui/spaceport_layout.json`. Run it after repainting a background or a cutout.
- Autumn backgrounds are `tools/season_grade.py` colour grades of the spring paintings, so
  both seasons share one composition and one layout. Never generate them separately.
