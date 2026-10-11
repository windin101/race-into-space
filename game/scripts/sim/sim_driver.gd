class_name SimDriver
extends RefCounted
## A scripted player that follows the standard progression. Used to exercise the whole
## economy headless and to tune the undocumented formulas. Not the shipping AI.
##
## Three tracks run in parallel on separate pads: the manned ladder, the probe ladder,
## and unmanned test flights that raise safety past the R&D ceilings. Each ladder step
## names the mission, the duration to request, hardware to own first and the lowest
## effective safety at which to launch.

const RESERVE_MB := 5
const MIN_UNITS := 2
const MIN_ASTRONAUTS := 14
const TEST_FLY_AT := 50

const MANNED := [
	{"mission": 2, "duration": 1, "shop": [["rocket", 0], ["manned", 0], ["rocket", 4]], "fly_at": 65},
	{"mission": 4, "duration": 1, "shop": [["manned", 1], ["rocket", 1], ["misc", 4]], "fly_at": 65},
	{"mission": 6, "duration": 1, "shop": [["misc", 3]], "fly_at": 70},
	{"mission": 14, "duration": 1, "shop": [["manned", 2], ["rocket", 2]], "fly_at": 70, "ignore_docking": true},
	{"mission": 25, "duration": 4, "shop": [["manned", 5], ["misc", 0]], "fly_at": 70},
	{"mission": 38, "duration": 1, "shop": [["misc", 1]], "fly_at": 75},
	{"mission": 43, "duration": 3, "shop": [], "fly_at": 80},
	{"mission": 46, "duration": 4, "shop": [], "fly_at": 80},
	{"mission": 48, "duration": 4, "shop": [], "fly_at": 80, "repeat_until": "lm_points_3"},
	{"mission": 56, "duration": 4, "shop": [], "fly_at": 85},
]
const PROBES := [
	{"mission": 1, "duration": 0, "shop": [["rocket", 0], ["probe", 0]], "fly_at": 50},
	{"mission": 7, "duration": 0, "shop": [["probe", 1], ["rocket", 1]], "fly_at": 70},
	{"mission": 8, "duration": 0, "shop": [["probe", 2]], "fly_at": 70},
]

var player_index: int
var manned_step := 0
var probe_step := 0


func _init(p_player_index: int) -> void:
	player_index = p_player_index


func act(game: SimGame) -> void:
	var state := game.state
	var p := state.player(player_index)
	manned_step = _advance(p, MANNED, manned_step)
	probe_step = _advance(p, PROBES, probe_step)
	_pay_damage(p)
	_shop(state, p)
	_recruit_and_crew(state, p)
	_research(state, p)
	_plan_missions(game, state, p)


func _advance(p: SimPlayer, ladder: Array, step_idx: int) -> int:
	while step_idx < ladder.size():
		var step: Dictionary = ladder[step_idx]
		var done := false
		if step.has("repeat_until"):
			match step["repeat_until"]:
				"lm_points_3":
					done = p.lm_points >= 3
		else:
			for r in p.mission_log:
				if r["mission_index"] == step["mission"] and _clean_success(r) \
						and int(r.get("duration_achieved", 0)) >= int(step["duration"]):
					done = true
		if done:
			step_idx += 1
		else:
			break
	return step_idx


static func _clean_success(r: Dictionary) -> bool:
	if r["outcome"] != "success":
		return false
	for g in r.get("goals", []):
		if not g["success"]:
			return false
	return true


func _pay_damage(p: SimPlayer) -> void:
	for prog in p.owned_programs():
		if prog.damage != 0 and p.cash >= prog.damage_cost + RESERVE_MB:
			SimEvents.pay_damage(p, prog)


func _shopping_list() -> Array:
	var items: Array = []
	for s in range(0, mini(manned_step, MANNED.size() - 1) + 1):
		items.append_array(MANNED[s]["shop"])
	for s in range(0, mini(probe_step, PROBES.size() - 1) + 1):
		items.append_array(PROBES[s]["shop"])
	return items


func _shop(state: SimState, p: SimPlayer) -> void:
	var want_pads := 1
	if manned_step >= 1 or probe_step >= 1:
		want_pads = 2
	if manned_step >= 3:
		want_pads = 3
	if p.pad_count() < want_pads and p.cash >= SimEconomy.PAD_COST + 15:
		SimEconomy.buy_pad(p)
	for i in 3:
		if p.pads[i] > 0 and p.cash >= p.pads[i] + RESERVE_MB:
			SimEconomy.repair_pad(p, i)
	var reserved := _reserved_units(state, p)
	for item in _shopping_list():
		var prog: SimProgram = p.program(item[0], item[1])
		if prog == null:
			continue
		if not prog.owned:
			if SimHardware.can_buy_program(p, prog) and p.cash - SimHardware.program_price(p, prog) >= RESERVE_MB:
				SimHardware.buy_program(state, p, prog)
		elif not prog.is_eva_suit():
			var want: int = MIN_UNITS + int(reserved.get(prog, 0))
			while prog.units < want and SimHardware.can_buy_unit(p, prog) \
					and p.cash - SimHardware.unit_price(p, prog) >= RESERVE_MB:
				SimHardware.buy_unit(p, prog)


func _recruit_and_crew(state: SimState, p: SimPlayer) -> void:
	var alive := 0
	for a in p.astronauts:
		if a.is_alive():
			alive += 1
	if alive < MIN_ASTRONAUTS and p.program("manned", 0).owned and p.cash >= 40:
		var cands := SimPersonnel.available_recruits(state, p)
		if not cands.is_empty():
			var names: Array = []
			var sorted := cands.duplicate()
			sorted.sort_custom(func(a, b): return a["capsule"] + a["endurance"] > b["capsule"] + b["endurance"])
			var limit: int = state.data.roster["sides"][p.side][p.recruit_group]["number_to_choose"]
			var woman_in := false
			for c in sorted:
				if names.size() >= limit:
					break
				names.append(c["name"])
				if c.get("female", false):
					woman_in = true
			if p.female_allowed and not woman_in:
				for c in sorted:
					if c.get("female", false):
						names[names.size() - 1] = c["name"]
						break
			SimPersonnel.recruit(state, p, names)
	# One full, available crew on every owned capsule, biggest capsule first.
	var programs := SimPersonnel.capsule_programs(p)
	programs.sort_custom(func(a, b): return a.slot > b.slot)
	for prog: SimProgram in programs:
		var cap: int = prog.crew_capacity()
		var existing := SimPlanner.crew_of(p, prog.slot, 0)
		var intact := existing.size() == cap
		for a in existing:
			if not a.is_available():
				intact = false
		if intact:
			continue
		for a in existing:
			SimPersonnel.unassign(p, a)
		var free: Array = []
		for a in p.astronauts:
			if a.is_available() and not a.in_crew() and a.program_slot == -1:
				free.append(a)
		free.sort_custom(func(a, b): return a.skill("capsule") + a.skill("endurance") > b.skill("capsule") + b.skill("endurance"))
		if free.size() < cap:
			continue
		var members: Array = free.slice(0, cap)
		for a in members:
			SimPersonnel.assign_to_program(p, a, prog.slot)
		SimPersonnel.set_crew(p, prog.slot, 0, members, state)


func _research(state: SimState, p: SimPlayer) -> void:
	var needed := _needed_programs(state, p)
	var progs := p.owned_programs()
	progs.sort_custom(func(a, b):
		var na: bool = a in needed
		var nb: bool = b in needed
		if na != nb:
			return na
		return a.safety < b.safety)
	for prog in progs:
		var teams := SimHardware.max_teams(p, prog)
		while teams > 0 and SimHardware.research_cost(p, prog, teams) > p.cash - RESERVE_MB:
			teams -= 1
		if teams > 0:
			SimHardware.research(state, p, prog, teams)


func _trial_plan(state: SimState, mi: int, duration: int, pad: int) -> Dictionary:
	var m: Dictionary = state.data.missions[mi]
	return {"mission_index": mi, "pad": pad, "duration": maxi(int(m["days"]), duration),
			"joint": m["joint"] == 1, "part": 1, "rush_months": 0, "crew_choice": [0, 0]}


func _launch_programs(launch: Dictionary) -> Array:
	var out: Array = []
	for v in launch["vehicles"]:
		out.append(v["rocket"])
		if v["boosters"] != null:
			out.append(v["boosters"])
		for k in v["payload"]:
			if v["payload"][k] != null:
				out.append(v["payload"][k])
	return out


## Units that this season's plans will consume, per program.
func _reserved_units(state: SimState, p: SimPlayer) -> Dictionary:
	var reserved := {}
	for pad in 3:
		var pl = p.future[pad]
		if pl == null or pl.get("part", 1) == 2:
			continue
		var launch := SimPlanner.assemble(state, p, pl)
		if not launch.has("vehicles"):
			continue
		for prog in _launch_programs(launch):
			if not (prog.is_eva_suit() or prog.is_photo_recon()):
				reserved[prog] = int(reserved.get(prog, 0)) + 1
	return reserved


## True when every program on the launch still has a unit beyond those reserved.
func _units_spare(state: SimState, p: SimPlayer, launch: Dictionary) -> bool:
	var reserved := _reserved_units(state, p)
	for prog in _launch_programs(launch):
		if prog.is_eva_suit() or prog.is_photo_recon():
			continue
		if prog.units - int(reserved.get(prog, 0)) < 1:
			return false
	return true


func _needed_programs(state: SimState, p: SimPlayer) -> Array:
	var out: Array = []
	for pair in [[MANNED, manned_step], [PROBES, probe_step]]:
		var ladder: Array = pair[0]
		var idx: int = pair[1]
		if idx >= ladder.size():
			continue
		var step: Dictionary = ladder[idx]
		var launch := SimPlanner.assemble(state, p, _trial_plan(state, step["mission"], step["duration"], 0))
		if launch.has("vehicles"):
			out.append_array(_launch_programs(launch))
	return out


## Lowest effective safety on the launch, optionally ignoring the docking module
## (which only improves by flying).
func _lowest_safety(launch: Dictionary, ignore_docking: bool) -> int:
	var lowest := 100
	var pen: int = launch["requirement_penalty"] + launch["rush_penalty"]
	for prog in _launch_programs(launch):
		if ignore_docking and prog.is_docking_module():
			continue
		var s: int = prog.safety - pen
		if prog.is_lm():
			s -= launch["lm_penalty"]
		lowest = mini(lowest, s)
	return lowest


func _plan_missions(game: SimGame, state: SimState, p: SimPlayer) -> void:
	# Drop ladder plans made a season ago for a step that has since been completed.
	var current: Array = []
	if manned_step < MANNED.size():
		current.append(MANNED[manned_step]["mission"])
	if probe_step < PROBES.size():
		current.append(PROBES[probe_step]["mission"])
	for pad in 3:
		var pl = p.future[pad]
		if pl == null or pl.get("part", 1) == 2:
			continue
		var mi: int = pl["mission_index"]
		if mi in [1, 3, 5, 15]:
			continue
		if not (mi in current):
			SimPlanner.cancel_plan(p, pad)
	# A lunar mission already scheduled for this season whose step is done is not worth
	# the risk of a repeat: scrub it (3 prestige) rather than fly it.
	for pad in 3:
		var sched = p.missions[pad]
		if sched == null or sched.get("part", 1) == 2:
			continue
		var mi: int = sched["mission_index"]
		if mi >= 43 and not (mi in current):
			game.scrub(p, pad)
	var free_pads: Array = []
	for pad in 3:
		if p.future[pad] == null and p.pad_usable(pad):
			free_pads.append(pad)
	# Manned track takes the first free pad; a joint mission needs the next one too.
	if manned_step < MANNED.size():
		var step: Dictionary = MANNED[manned_step]
		for pad in free_pads:
			if _try_plan(state, p, step, pad):
				free_pads.erase(pad)
				if step.has("joint") or state.data.missions[step["mission"]]["joint"] == 1:
					free_pads.erase(pad + 1)
				break
	if probe_step < PROBES.size() and not free_pads.is_empty():
		var step: Dictionary = PROBES[probe_step]
		for pad in free_pads:
			if _try_plan(state, p, step, pad):
				free_pads.erase(pad)
				break
	for pad in free_pads:
		_plan_test_flight(state, p, pad)


func _try_plan(state: SimState, p: SimPlayer, step: Dictionary, pad: int) -> bool:
	var mi: int = step["mission"]
	var duration: int = step["duration"]
	if not SimPlanner.can_plan(state, p, mi, pad, duration)["ok"]:
		return false
	var launch := SimPlanner.assemble(state, p, _trial_plan(state, mi, duration, pad))
	if not launch.has("vehicles"):
		return false
	if not _units_spare(state, p, launch):
		return false
	var lowest := _lowest_safety(launch, step.get("ignore_docking", false))
	if lowest >= int(step["fly_at"]) or _research_exhausted(launch):
		return SimPlanner.plan(state, p, mi, pad, duration)
	return false


## True when every program on the launch has reached its research ceiling.
func _research_exhausted(launch: Dictionary) -> bool:
	for prog in _launch_programs(launch):
		if prog.can_research():
			return false
	return true


## An unmanned flight that exercises hardware the ladders need: docking tests once a
## docking module exists, otherwise orbital tests.
func _plan_test_flight(state: SimState, p: SimPlayer, pad: int) -> void:
	var options: Array = [5, 3, 1]
	var dm: SimProgram = p.program("misc", 4)
	if dm != null and dm.owned and dm.safety < 75:
		options = [15, 5, 3, 1]
	for mi in options:
		if not SimPlanner.can_plan(state, p, mi, pad)["ok"]:
			continue
		var launch := SimPlanner.assemble(state, p, _trial_plan(state, mi, 0, pad))
		if launch.has("vehicles") and _lowest_safety(launch, true) >= TEST_FLY_AT \
				and _units_spare(state, p, launch):
			SimPlanner.plan(state, p, mi, pad)
			return
