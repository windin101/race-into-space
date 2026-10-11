# Art and audio style guide

Everything visual in Race Into Space is drawn, not photographed: flat-shaded vector
shapes, a restrained palette, and period typography. The original's photographs, FMV
and painted screens are not used, and nothing here should resemble them closely.

## Principles

- **Flat and crisp.** Shapes are filled polygons and circles with at most one shade of
  shadow. No gradients beyond the sky, no textures, no outlines except where a shape
  would otherwise vanish against its background. Everything scales to 4K because it is
  geometry, not pixels.
- **One palette.** Colours come from `UiPalette` (UI) and the painter constants
  (`Vignettes`, `SpaceportArt`, `HardwareArt`, `PortraitArt`). The side accent (US blue
  `#3d7bdc`, Soviet red `#d23a2f`) is the only colour that changes between sides.
- **Period, not pastiche.** Oswald for headings (a 1960s condensed grotesque feel),
  Source Sans 3 for text. Panels are dark navy with thin borders, like a mission control
  console, never beige DOS chrome.
- **Legible first.** Illustrations sit beside data, never behind it. Nothing decorative
  may lower the contrast of text.

## Spaceports

Painted live by `SpaceportArt.paint()` from the hotspot layout in
`data/ui/spaceport_layout.json`, so hotspots and painting cannot drift apart.

- Cape Canaveral: blue sky, Atlantic strip on the horizon, sand, green scrub, white
  buildings with grey roofs.
- Baikonur: hazy sky, ochre steppe, the same building grammar; fall seasons wash the
  ground lighter.
- Buildings appear as the programme grows (cleared plots before then); pads show a
  gantry, an accent-coloured pad marker, scorched concrete when damaged, and only an
  outline before they are built.
- The flag is the end-of-turn control, drawn in the corner as a flag.

To replace with hand-painted art later: paint each side at 3840x2160 using the same
layout rectangles, keep per-building layers so states still work, and swap the painter
for a layered texture; the hotspot buttons stay.

## Hardware

`HardwareArt.paint()` draws one silhouette per program slot: rockets grow in height,
stages and engine count by class; capsules widen with seats; the minishuttle is a delta;
lunar modules are gold-skirted boxes on legs; probes are a spinner, a panelled bus and a
tripod lander; kickers are stubby stages; the suit, docking drum and camera round out the
set. Accent band in the side colour. Cards show them at 90x90 logical pixels; the same
painter can draw them large on a programme page.

## Portraits

`PortraitArt.paint()` builds a face deterministically from the astronaut's name: skin,
hair colour and style, eye colour, face proportions, glasses, moustache, and a suit in
the side's dark accent. Status tints: dead portraits darken with a black band, retired
ones grey. Replacing them with illustrated portraits keyed by name needs no caller
change.

## Mission vignettes

See `scripts/playback/vignettes.gd`: eighteen families keyed by step letter, each with a
success and a failure frame. Camera is always side-on; Earth lower left or below, Moon
right; the craft carries the accent band. Failures tint the frame red in the last
quarter and add an explosion or an X mark.

## Audio

All audio is synthesised by `tools/gen_audio.py` (numpy, ffmpeg) and released under
CC0; nothing is sampled. Music is minor-key, slow and sparse: a title pad with a rising
arpeggio, a quiet spaceport drone with occasional pings, and a tense ostinato for
playback. Effects are short synthesised cues (click, confirm, back, flag roll, launch
rumble, explosion, success chord, failure fall, first fanfare, newscast sting). Volumes
are set on the Music and SFX buses from Settings. Replacing them with recorded music
only needs files of the same names under `assets/audio/`.

## Licensing

Every file under `assets/` is listed in `assets/MANIFEST.md` with its source and
licence. Procedural art has no files; it is code under the project licence. Fonts are
OFL. Audio generated here is CC0. Nothing from the original game or its port is used.
