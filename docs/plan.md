# Race Into Space: phased plan

Living roadmap. Phases run roughly in order, but 3 (UI framework) can start as soon as
2 has a loadable game state. Each phase has a definition of done so it can be closed.

## Phase 0: Foundations (done 2026-10-11)

- Repo, GPL-2.0-or-later, Godot 4.7 project skeleton.
- Research report (`docs/reports/`), upstream reference map, original manuals.
- Decisions: Godot + GDScript, high-res vector/painted art, no Interplay media, new title.

## Phase 1: Data pipeline (done 2026-10-11, tag phase-1)

Goal: every table the game needs exists as project-owned data in `game/data/`, with a
repeatable importer, so the simulation never reads the upstream clone at runtime.

- `tools/import_upstream.py`: reads `reference/raceintospace/data/gamedata/*.json`, writes
  clean, documented JSON (or `.tres` resources) into `game/data/`. One output file per
  concept: hardware (Basic + Historical), prestige table, missions, mission steps and
  failure modes, rosters and crew, newscast events, help text, budget adjustment table.
- Prestige row names, duration day bands, crew capacities and the other code-only
  constants are transcribed by hand from `src/` into the same files, with a comment
  giving the upstream file:line they came from.
- Validation script cross-checks hardware and prestige against the 1993 manual text and
  reports discrepancies (the XMS-2/Lapot duration one is already known).
- Data schema documented in `docs/data-schema.md`; code-derived rules in `docs/specs/code-derived-rules.md`.

Done when: importer runs clean, Godot loads every file at startup without errors, and a
GDScript test suite (gdUnit4) asserts row counts and a handful of known values.

## Phase 2: Headless simulation core

Goal: a complete game can be played by script with no UI, so rules can be tested and
tuned before any screen exists.

- Game state model: players, season/year, cash, prestige, hardware inventories with
  safety and R&D, pads, astronaut corps with skills/mood/status, scheduled missions,
  achieved milestones, event history.
- Turn loop in the manual's order: announcement, newscast/event, spaceport actions,
  assembly, launches, end of turn, annual budget and review.
- Economy: budget formula (from upstream `game_main.cpp`), purchases, R&D rolls, pads,
  training, rush costs, event costs.
- Mission planning rules: prerequisites, hardware eligibility, crew requirements,
  milestone-skip, duration, LM-test, new-mission and rush penalties, downgrade/scrub.
- Mission resolution: step sequence from the mission code string, per-step rolls against
  component safety plus crew skill, failure severity and failure-mode lookup, outcomes
  for hardware, crew and prestige, firsts and second-place awards.
- Personnel: recruitment groups and delays, training, crews, mood, retirement, death.
- Events deck and intelligence briefings.
- End game: landing victory, dismissal at review, 1977 timeout.
- Deterministic RNG with seed so playthroughs are reproducible.
- Scripted "dumb" player driver that follows the standard progression, used to run
  thousands of games headless and compare budget and prestige curves to the Let's Play
  figures in the research report.

Done when: a seeded scripted game from 1957 to a Moon landing runs headless, every
rule above has at least one test, and tuning notes for the undocumented formulas are in
`docs/specs/`.

## Phase 3: UI framework

Goal: the scaffolding every screen uses, proven at 1080p, 1440p ultrawide and 4K.

- Theme: one Godot Theme resource with MSDF fonts, nine-patch panels, colour palette with
  US blue and USSR red variants, SVG icons imported as DPITexture.
- Scaling: canvas_items stretch, `content_scale_factor` exposed as a UI-scale option,
  integer-scale option for any pixel-art elements.
- Screen manager: hub-and-spoke navigation (spaceport hub, full-screen panels, modal
  dialogs), back-stack, transitions.
- Reusable widgets: data table with sortable columns, stat bar, hardware card, astronaut
  card, confirm dialog, tooltip with help text from `help.json`.
- Settings screen: UI scale, resolution/window mode, audio, animation speed.
- Placeholder art: flat-colour spaceport with labelled building hotspots.

Done when: a demo scene shows all widgets, and resizing between 720p and 4K keeps
layouts correct with no clipped text.

## Phase 4: Game screens

Goal: the full game is playable end to end on placeholder art.

Build in play order so each slice is testable:
1. Title, new game setup (sides, difficulty, model, names), save/load.
2. Turn announcement and newscast with event cards.
3. Spaceport hub with building states (programs purchased unlock buildings).
4. Administration: budget office with graphs, hardware purchase, future missions
   planner with the A-OK/Caution/Danger readout, recruiting, preferences.
5. R&D screen with team assignment and safety readout.
6. Program buildings, launch pads, VAB with auto-purchase and crew assignment,
   Mission Control with month, rush, downgrade and scrub.
7. Astronaut complex: roster, training, mood, medical, crews.
8. Intelligence (CIA/KGB) briefing.
9. Museum: timeline, director rating, records, hardware efficiency, astronaut history.
10. Annual review, victory and dismissal screens.

Done when: a human can play a full game against the scripted driver from Phase 2 with
no console errors, and every screen has a screenshot in `docs/screens/`.

## Phase 5: Mission playback

Goal: replace the 1994 FMV with an original, animated mission sequence.

- Mission playback scene: step readout bar chart of rolls versus safety, mission log,
  news flash overlay for firsts and failures.
- Animation system driven by the mission step string: a library of 2D animated vignettes
  (launch, staging, orbit, EVA, docking, lunar descent, splashdown) built from vector
  art with simple keyframe animation, parameterised by hardware type and side.
- Failure vignettes for the main failure classes.
- Skip and speed controls; "mosaic" style full-screen option.

Done when: every step letter in the mission codes has a vignette, and a complete lunar
landing plays without gaps.

## Phase 6: AI opponent

- Port the observable behaviour: same rules as the human, difficulty as handicap,
  tendency to retry failed mission types.
- Planning AI: budget allocation, R&D priority, mission progression along the standard
  ladder, risk tolerance by difficulty.
- Nine difficulty combinations and the three astronaut-data levels.

Done when: the AI lands on the Moon within the 1977 window in most seeded games at each
level, and loses to a competent human at Level 1.

## Phase 7: Art and audio

- Style guide in `docs/art-style.md`: painted spaceports, illustrated hardware, astronaut
  portraits (generated or illustrated, not Interplay's), period typography.
- Spaceport paintings for both sides in at least 4K, building states.
- Hardware illustrations for every program in both models.
- Portrait set for 224 astronauts, or a portrait generator.
- Music and SFX: original or CC0/CC-BY, tracked in `assets/MANIFEST.md` with licence per
  file.

Done when: no placeholder art remains on any screen and the manifest is complete.

## Phase 8: Polish and release

- Hot-seat two-player, options, accessibility (font scale, colour-blind palettes,
  keyboard navigation).
- Save-game versioning and migration.
- Exports: Linux first, then Windows and macOS; Flatpak manifest; web export as a stretch.
- CI: GitHub Actions running the gdUnit4 suite headless on each push.
- Player manual in `docs/manual/`, written fresh.
- Tag 1.0, publish on itch.io and GitHub Releases.

## Cross-cutting rules

- Simulation code never touches the scene tree; UI reads state and sends commands.
- Every number comes from `game/data/` with a provenance comment, never a magic literal.
- New art and text only; the upstream clone is reference, not a source of files.
- Each phase closes with a commit tagged `phase-N`.
