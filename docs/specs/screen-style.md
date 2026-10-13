# Screen style: the original's layouts, our art

Settled on 2026-10-13 after reworking Research, the Astronaut Complex, Vehicle Assembly
and Mission Playback. Every remaining screen follows the same pattern. The reference
implementations are `game/scenes/research/research.gd`,
`game/scenes/astronauts/astronaut_complex.gd`, `game/scenes/vab/vehicle_assembly.gd`
and `game/scenes/playback/mission_playback.gd`; copy their idioms rather than inventing new ones.

## What stays fixed

- The simulation API and every command path (SimHardware, SimPersonnel, SimPlanner,
  SimEvents, SimGame, OpsView, TurnLogic). Screens present rules; they never restate them.
- `ScreenPanel` as the base (header, `content`, `footer`, status line, `set_backdrop`).
- Static view helpers that tests cover (`matches_filter`, `roster_row`, `seat_labels`...)
  keep their names and signatures.
- Arguments passed through `setup(args)` and `on_resume()`.
- Help codes attached with `UiHelp.attach`.

## The look (from the 1993 screens, rebuilt)

1. **Banner.** A `PanelContainer` with `theme_type_variation = "Sunken"` holding a
   `Label` with `theme_type_variation = "Heading"` in `UiPalette.GOLD`, text in capitals:
   `LAUNCH FACILITY: A`, `NAME: GRISSOM`, `MISSION HARDWARE`. One per major panel.
2. **Picture tabs.** Group choices are `Button`s with `toggle_mode`, an `icon` from
   `ArtAssets.hardware(side, group, slot)` or `ArtAssets.icon(name)`, `icon_alignment =
   HORIZONTAL_ALIGNMENT_CENTER`, `vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP`,
   `icon_max_width` 64-72 and a minimum height of about 110.
3. **Display case.** A `Control` inside a Sunken panel that draws on `CASE_BG =
   Color("0a1424")`, a soft spotlight (concentric circles at alpha 0.025), the subject via
   `HardwareArt.paint(c, rect, group, slot, side)` or `PortraitArt.paint(c, rect, name,
   female, side, status)` (both fall back to procedural art when a file is missing), and a
   plinth line in `UiPalette.BORDER_SOFT`. Arrows `◀` `▶` beneath to cycle, with the name
   centred between them.
4. **Stats sheet.** A `GridContainer` with two columns inside a Card panel: keys as
   `Dim` labels, values right-aligned, safety in `UiPalette.safety_color`, mood in
   `UiPalette.mood_color`, money as `%d MB`, counts plain. Capitalised key text with a
   trailing colon (`MOOD:`) where the original did that.
5. **Boards.** Groups of commands as a vertical or two-column stack of full-width
   `Button`s under a gold board title (`TRANSFER TO LOCATION`). The current state shows as
   a pressed toggle; unavailable choices are `disabled`, never hidden.
6. **Figures.** Small procedural glyphs drawn on buttons (team figures in Research) where
   the original used icons; keep them under 20 lines of draw code.
7. **Brief text** in `UiPalette.INFO` capitals for the original's cyan mission brief
   lines (`CREW: UNMANNED`, `CURRENT PAYLOAD: 300`).
8. **Rooms.** A painted backdrop via `set_backdrop("<name>")` only for stage-like screens
   (newscast, end game, annual review, playback); offices stay on the flat panel colour.
9. **Lists.** `DataTable` stays where sorting matters, narrowed to the columns that help
   choose (name, status, programme, one or two numbers); colour names by status with a
   `color` column func.
10. **Portraits and patches.** Crew everywhere as `ArtAssets.portrait(name)` tiles; a
    mission as `ArtAssets.patch(side, index)` beside its name.

## Per-screen notes (what the original showed)

- **Hardware Purchase**: the Research layout exactly (picture tabs, display case with
  arrows, stats sheet: units on hand, initial cost, unit cost, safety, max payload or
  weight, max safety), then `Purchase program (N MB)` / `Buy unit (N MB)` and the cash line.
- **Program Offices**: picture tabs, then one row per owned programme with its icon,
  inventory, safety, flights and the damage state; the selected one in a display case.
- **Future Missions**: facility tabs A/B/C, a mission banner with `◀ ▶` to cycle the
  mission list, the brief (crew, duration, requirements, prestige) and a **mission
  diagram**: the step letters drawn as a path of nodes around a small Earth (and Moon
  when lunar), coloured by whether the step is manned; duration/rush/joint controls as a
  board; `Assign` and `Clear`.
- **Mission Control**: three pad bays side by side, each drawing the assembled vehicle
  (`HardwareArt.paint`) on the pad cutout (`ArtAssets.spaceport_layer(side, "pad_ok")`)
  with the launch month, readiness, downgrade and scrub commands beneath.
- **Launch Pad N**: the pad as a display case (`pad_site` / `pad_ok` / `pad_damaged`
  cutouts) with the scheduled vehicle standing on it when operational; status, build and
  repair commands as a board.
- **Training Centre**: basic training as a roster list; advanced training as five
  facility cards (capsule, LM, EVA, docking, endurance), each with the matching hardware
  icon and the trainees' portrait tiles; the command board to enrol or withdraw.
- **Recruiting**: the Astronaut Complex dossier for the selected candidate (portrait,
  ratings), the candidate list beside it, `Recruit` and the group counter.
- **Intelligence**: the seal header stays; the selected rival programme in a display case
  with the estimate sheet beside it; the briefing table beneath.
- **Museum**: a gold banner per hall; the firsts list with the mission patch and date,
  heroes with portrait tiles; the other tables as they are.
- **Budget Office**: a ledger sheet (cash, budget, this season's spending, next season's
  forecast) in a Card, then the two graphs with side-coloured legends.
- **Launch Results**: each launch headed by its patch and name, crew as portrait tiles,
  step lines coloured by outcome.
- **Annual Review**: `set_backdrop("review_<side>")` (a painted chamber) with the verdict
  text as a brief; the reviewer as a large procedural portrait tile.
- **Newscast**: already on its backdrop; add the anchor as a portrait tile beside the card.
- **Preferences / Settings / Title / Setup**: leave the structure; apply banners and
  boards only where a plain button column exists.

## Checking a screen

```
cd game && DISPLAY=:1 godot --headless --path . --check-only -s res://scenes/<dir>/<file>.gd
DISPLAY=:1 godot --path . --rendering-driver opengl3 res://tools/ui_screenshots.tscn -- \
    --out ../../../../../tmp/<somewhere>/shots --only <scene_name> [--side ussr] [--season fall]
```

The screenshot tool advances a scripted game six turns so every screen has data. It
reports clipped labels and buttons as layout problems; fix those before calling a screen
done. Run `tools/run_tests.sh` once at the end, not per screen.
