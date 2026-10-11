# UI screen conventions and simulation API cheat sheet

Read this before writing any screen. Phase 4 builds every building screen on top of
the Phase 3 framework (`game/scripts/ui/`) and the Phase 2 simulation (`game/scripts/sim/`).

## Conventions

- One scene per screen under `game/scenes/<area>/<name>.tscn`, a `Control` root with a
  script of the same name. The `.tscn` is a bare root node; the script builds the children
  in `_ready()` (see `game/scenes/admin/hardware_purchase.gd` for the reference pattern).
- Screens that are panels extend `ScreenPanel` (`game/scripts/ui/widgets/screen_panel.gd`):
  set `title` in `_init()` after `super()`, add children to `content` and `footer`. The
  header shows date, cash and budget automatically and the back button pops the screen.
- Navigation: `Screens.push(load("res://scenes/...tscn"), args)` / `Screens.pop()`. A
  screen receives `args` in `func setup(args: Dictionary)` (called after `_ready`) and
  `func on_resume()` when a screen above it closes. Refresh your data in both.
- Game state: `Session.state()` (SimState), `Session.me()` (the human SimPlayer),
  `Session.rival()`, `Session.human_side`. After any command that changes state call
  `Session.notify_change()` so headers and the hub refresh.
- Never mutate state directly in a screen; call the static rule modules (below). Never
  put a number in a screen that comes from the rules; read it from the module or
  `GameData.constants`.
- Colours only from `UiPalette`; text styles only via `theme_type_variation`
  ("Title", "Heading", "Subheading", "Dim", "Small"; buttons "Accent", "Danger", "Flat";
  panels "Raised", "Sunken", "Card").
- Widgets: `DataTable`, `StatBar`, `HardwareCard`, `AstronautCard`, `ConfirmBox.ask(...)`
  (await), `ConfirmBox.notice(...)`, `UiHelp.attach(control, "I0NN")`.
- Layout must survive 1280x720 to 3840x2160 and ultrawide. Use containers, `SIZE_EXPAND_FILL`,
  `clip_text` with ellipsis on table cells, `autowrap_mode` on paragraphs. Never fixed
  pixel positions except through anchors. Run `tools/ui_screenshots.tscn`
  (`DISPLAY=:1 godot --path game res://tools/ui_screenshots.tscn`) and fix every reported
  clipped label.
- Tests: add a gdUnit suite under `game/test/ui/` for any non-trivial view logic (sorting,
  filtering, derived numbers). `game/test/ui/test_all_scenes.gd` already instantiates
  every scene with a live game; keep it green (`tools/run_tests.sh`).
- No console errors or warnings when the screen opens, refreshes, or is left.

## Simulation API (static modules, all take `state: SimState` and `p: SimPlayer`)

Hardware (`SimHardware`): `can_buy_program(p, prog)`, `buy_program(state, p, prog)`,
`can_buy_unit(p, prog)`, `buy_unit(p, prog)`, `program_price(p, prog)`, `unit_price(p, prog)`,
`max_teams(p, prog)`, `research_cost(p, prog, teams)`, `research(state, p, prog, teams) -> gain`,
`starting_safety(state, p, prog)`. `SimProgram` fields: `group`, `slot`, `spec`, `owned`,
`safety`, `max_rd`, `units`, `delay`, `researched_this_season`, `damage`, `damage_cost`;
helpers `display_name()`, `program_cost()`, `unit_cost()`, `rd_cost()`, `max_safety()`,
`base_safety()`, `is_rocket()/is_capsule()/is_lm()/is_probe()/is_kicker()/is_eva_suit()/
is_docking_module()/is_photo_recon()`, `crew_capacity()`, `can_research()`.
`p.programs[group][slot]`, `p.program(group, slot)`, `p.owned_programs()`, `p.all_programs()`.
Groups: "probe", "rocket", "manned", "misc" (slots documented in docs/data-schema.md).

Economy (`SimEconomy`): `can_buy_pad(p)`, `buy_pad(p)`, `repair_pad(p, i)`, `PAD_COST`;
`p.pads[i]` is -1 none, 0 ok, >0 repair cost. `p.cash`, `p.budget`, `p.prestige`
(this season), `p.prestige_total`, `p.prestige_history[]`, `p.budget_history[]`,
`p.spending_this_season`.

Planner (`SimPlanner`): `can_plan(state, p, mission_index, pad, duration) -> {ok, reason}`,
`plan(state, p, mission_index, pad, duration)`, `cancel_plan(p, pad)`,
`requirement_penalty(state, p, mission_index, duration) -> {milestone, duration, new_mission, total, lm, skipped_milestones}`,
`set_rush(p, pad, months, scheduled := false)` (Mission Control passes true for this season's missions),
`set_capsule(plan, slot)`, `set_crew_choice(plan, vehicle, crew_index)`, `set_mission(state, plan, index)` (downgrades only),
`capsule_candidates(p, m_eq, with_empty)`, `assemble(state, p, plan) -> launch or {reason}`,
`assemble_with_downgrades(...)`, `readiness(launch) -> {lowest_safety, band}`,
`crew_of(p, slot, crew_index)`, `launch_date(state)`. Plans live in `p.future[pad]`
(next season) and `p.missions[pad]` (this season): `{mission_index, pad, duration, joint,
part, rush_months, crew_choice, capsule_slot?}`. Mission defs: `GameData.missions[i]`
(`name`, `abbr`, `code`, `days`, `dur`, `docking`, `eva`, `lm`, `joint`, `lunar`, `m_eq`,
`crew_mode`, `prestige_categories`, `downgrades`, `diagram`). Plannable indices 1..57.

Personnel (`SimPersonnel`): `available_recruits(state, p)`, `recruit_cost(p)`,
`recruit(state, p, names)`, `capsule_programs(p)`, `assign_to_program(p, a, slot)`,
`unassign(p, a)`, `set_crew(p, slot, crew_index, members, state)`, `clear_crew(p, slot, i)`,
`crew(p, slot, i)`, `crews_of(p, slot)`, `compatible(a, b)`, `crew_conflicts(crew)`,
`crew_skill(crew, role, state)`, `start_advanced_training(state, p, a, skill)`,
`withdraw_training(state, p, a)`, `roster_summary(p)`. `SimAstronaut`: `name`, `female`,
`skills{capsule, lm, eva, docking, endurance}`, `skill(key)`, `mood`, `status`
(`SimAstronaut.Status.*`), `status_name()`, `program_slot`, `crew_index`, `crew_position`,
`training_focus`, `training_seasons_left`, `missions_flown`, `hero`, `mission_history`.
`p.astronauts`, `p.recruit_group`, `p.recruit_delay`, `p.female_allowed`.

Events (`SimEvents`): `p.last_news` = `{code, text_index, text, color, effect, applied, budget_drift, detail}`;
`pay_damage(p, prog)`. Review: `p.reviews[]` (`{year, index, text_index, bad, value}`),
`p.review_index`, `SimReview.director_score(state, p)`,
`GameData.text["reviews"]["review"][text_index]`. End: `state.ended`, `state.winner`,
`state.end_reason`, `GameData.text["endgame"]["endgame"]`.

Prestige: `GameData.prestige[row]` (`key`, `title`, `first`, `second`, `other`, `failure`),
`state.prestige_rows[row]` (`first`, `second`, `first_year`, `first_season`),
`p.milestones[8]`, `p.duration_level`, `p.lm_points`, `p.docking_module_in_orbit`.
Mission log: `p.mission_log[]` results (`mission_index`, `outcome`, `goals`, `steps[]`,
`prestige{total, awards}`, `deaths`, `crew_outcomes`, `duration_achieved`).

Turn: `Session.end_turn() -> report {date, launches[], ended, winner}`;
`Session.game.scrub(p, pad)`; `state.date_string()`, `state.year` (two-digit),
`state.season`, `state.turn_index()`, `state.turn_log`.

Text: `GameData.text["events"][side][i]`, `["news"]`, `["reviews"]`, `["endgame"]`,
`["help"]`. Help codes for buildings are in `data/ui/spaceport_layout.json`.
