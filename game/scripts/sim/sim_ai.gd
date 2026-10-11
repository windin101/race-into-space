class_name SimAi
extends RefCounted
## The computer opponent. Plays by the same rules as the human through the same modules;
## difficulty changes its risk tolerance and the cash handicap it receives.
##
## Each season it: pays damage, buys the hardware its roadmap needs as early as cash
## allows (so research overlaps), researches the programs its next goals need, keeps
## crews on every capsule, then fills the pads: the next manned goal, the next probe
## goal, and unmanned test flights for the hardware that most needs flight experience.
## A mission is flown when its estimated success probability clears the level's bar.

const RESERVE_MB := 6
const MIN_ASTRONAUTS := 16

## Risk tolerance and handicap by the AI side's own level (0 easy for the player). Bars
## are the geometric mean per-step pass chance a mission must reach before it flies.
const LEVELS := {
	0: {"p_manned": 0.84, "p_lunar": 0.88, "p_landing": 0.90, "p_test": 0.60, "p_probe": 0.70, "cash_bonus": 0, "bonus_every": 0},
	1: {"p_manned": 0.80, "p_lunar": 0.85, "p_landing": 0.88, "p_test": 0.55, "p_probe": 0.65, "cash_bonus": 25, "bonus_every": 2},
	2: {"p_manned": 0.76, "p_lunar": 0.82, "p_landing": 0.86, "p_test": 0.50, "p_probe": 0.60, "cash_bonus": 25, "bonus_every": 1},
}

## Hardware roadmap: [group, slot, manned gate, probe gate]. An item is bought once
## either gate is reached (-1 never gates), in order, as cash allows; with plenty of cash
## the gates are ignored so research runs well ahead of need.
const ROADMAP := [
	["rocket", 0, 0, 0], ["probe", 0, -1, 0],
	["manned", 0, 0, -1], ["rocket", 4, 0, -1],
	["manned", 1, 1, -1], ["misc", 4, 1, -1], ["rocket", 1, 1, 1], ["misc", 3, 1, -1],
	["probe", 1, -1, 1], ["probe", 2, -1, 2],
	["manned", 2, 3, -1], ["rocket", 2, 3, -1], ["manned", 5, 3, -1], ["misc", 0, 4, -1],
]
const RICH_MB := 120

## Manned goal ladder: {mission, duration}. Advances on a clean success that reached the
## duration; "until" goals repeat until a condition holds.
const MANNED_GOALS := [
	{"mission": 2, "duration": 1},
	{"mission": 4, "duration": 1},
	{"mission": 6, "duration": 1},
	{"mission": 14, "duration": 1},
	{"mission": 27, "duration": 4},          # docking + duration D
	{"mission": 38, "duration": 1},          # Earth-orbital LM test
	{"mission": 43, "duration": 3},
	{"mission": 46, "duration": 4},
	{"mission": 48, "duration": 4, "until": "lm_points"},
	{"mission": 56, "duration": 4},
]
const PROBE_GOALS := [
	{"mission": 1, "duration": 0},
	{"mission": 7, "duration": 0},
	{"mission": 8, "duration": 0},
]

## Step letter -> hardware class for the success estimate (mirrors SimMission's choice).
const LETTER_CLASS := {
	"A": "rocket", "B": "boost", "J": "boost", "L": "boost", "C": "power", "D": "capsule",
	"E": "capsule", "F": "capsule", "G": "capsule", "K": "capsule", "M": "capsule", "N": "capsule",
	"O": "capsule", "X": "capsule", "Y": "capsule", "f": "capsule", "g": "capsule", "H": "eva",
	"P": "eva", "I": "docking", "Q": "lm", "R": "lm", "S": "lm", "T": "lm", "a": "lm",
	"U": "photo", "V": "probe", "W": "probe", "Z": "probe", "e": "probe", "b": "capsule", "c": "capsule",
}

var player_index: int
var manned_goal := 0
var probe_goal := 0
var _params: Dictionary


func _init(p_player_index: int) -> void:
	player_index = p_player_index


func act(game: SimGame) -> void:
	var state := game.state
	var p := state.player(player_index)
	_params = LEVELS.get(p.level, LEVELS[1])
	_handicap(state, p)
	_advance_goals(p)
	_pay_damage(p)
	_repair_and_build_pads(p)
	_shop(state, p)
	_recruit_and_crew(state, p)
	_research(state, p)
	_plan(game, state, p)


# ------------------------------------------------------------------ bookkeeping

## Upstream gives the computer cash injections unless the human plays on easy.
func _handicap(state: SimState, p: SimPlayer) -> void:
	var every: int = _params["bonus_every"]
	if every <= 0:
		return
	var human := state.opponent(p.index)
	if human.level == 0 and not human.is_ai:
		return
	if state.turn_index() % every == 0:
		p.cash += int(_params["cash_bonus"])


func _advance_goals(p: SimPlayer) -> void:
	while manned_goal < MANNED_GOALS.size() - 1 and _goal_done(p, MANNED_GOALS[manned_goal]):
		manned_goal += 1
	while probe_goal < PROBE_GOALS.size() and _goal_done(p, PROBE_GOALS[probe_goal]):
		probe_goal += 1


func _goal_done(p: SimPlayer, goal: Dictionary) -> bool:
	if goal.get("until", "") == "lm_points":
		return p.lm_points >= SimPlanner.LM_POINTS_REQUIRED
	for r in p.mission_log:
		if r["mission_index"] == goal["mission"] and _clean_success(r) \
				and int(r.get("duration_achieved", 0)) >= int(goal["duration"]):
			return true
	return false


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


func _repair_and_build_pads(p: SimPlayer) -> void:
	for i in 3:
		if p.pads[i] > 0 and p.cash >= p.pads[i] + RESERVE_MB:
			SimEconomy.repair_pad(p, i)
	var want := 1
	if manned_goal >= 1:
		want = 2
	if manned_goal >= 2:
		want = 3
	if p.pad_count() < want and p.cash >= SimEconomy.PAD_COST + 20:
		SimEconomy.buy_pad(p)


func _shop(state: SimState, p: SimPlayer) -> void:
	var reserved := _reserved_units(state, p)
	for item in ROADMAP:
		var gated_manned: bool = item[2] >= 0 and manned_goal >= item[2]
		var gated_probe: bool = item[3] >= 0 and probe_goal >= item[3]
		if not (gated_manned or gated_probe or p.cash >= RICH_MB):
			continue
		var prog: SimProgram = p.program(item[0], item[1])
		if prog == null:
			continue
		if not prog.owned:
			if SimHardware.can_buy_program(p, prog) and p.cash - SimHardware.program_price(p, prog) >= RESERVE_MB:
				SimHardware.buy_program(state, p, prog)
		elif not prog.is_eva_suit():
			var want: int = 2 + int(reserved.get(prog, 0))
			while prog.units < want and SimHardware.can_buy_unit(p, prog) \
					and p.cash - SimHardware.unit_price(p, prog) >= RESERVE_MB:
				SimHardware.buy_unit(p, prog)


func _recruit_and_crew(state: SimState, p: SimPlayer) -> void:
	var alive := 0
	for a in p.astronauts:
		if a.is_alive():
			alive += 1
	if alive < MIN_ASTRONAUTS and p.program("manned", 0).owned and p.cash >= 30:
		var cands := SimPersonnel.available_recruits(state, p)
		if not cands.is_empty():
			var sorted := cands.duplicate()
			sorted.sort_custom(func(a, b): return a["capsule"] + a["endurance"] + a["lm"] > b["capsule"] + b["endurance"] + b["lm"])
			var limit: int = state.data.roster["sides"][p.side][p.recruit_group]["number_to_choose"]
			var names: Array = []
			var woman_in := false
			for c in sorted:
				if names.size() >= limit:
					break
				names.append(c["name"])
				woman_in = woman_in or c.get("female", false)
			if p.female_allowed and not woman_in:
				for c in sorted:
					if c.get("female", false):
						names[names.size() - 1] = c["name"]
						break
			SimPersonnel.recruit(state, p, names)
	var programs := SimPersonnel.capsule_programs(p)
	programs.sort_custom(func(a, b): return a.slot > b.slot)
	for prog: SimProgram in programs:
		var cap: int = prog.crew_capacity()
		for crew_index in 2:
			var existing := SimPlanner.crew_of(p, prog.slot, crew_index)
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
			free.sort_custom(func(a, b): return a.skill("capsule") + a.skill("endurance") + a.skill("lm") > b.skill("capsule") + b.skill("endurance") + b.skill("lm"))
			if free.size() < cap:
				break
			var members: Array = free.slice(0, cap)
			for a in members:
				SimPersonnel.assign_to_program(p, a, prog.slot)
			SimPersonnel.set_crew(p, prog.slot, crew_index, members, state)


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


# ------------------------------------------------------------------ planning

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


func _needed_programs(state: SimState, p: SimPlayer) -> Array:
	var out: Array = []
	for goal in [_current_manned_goal(), _current_probe_goal()]:
		if goal.is_empty():
			continue
		var launch := SimPlanner.assemble(state, p, _trial_plan(state, goal["mission"], goal["duration"], 0))
		if launch.has("vehicles"):
			out.append_array(_launch_programs(launch))
	return out


func _current_manned_goal() -> Dictionary:
	return MANNED_GOALS[mini(manned_goal, MANNED_GOALS.size() - 1)]


func _current_probe_goal() -> Dictionary:
	return PROBE_GOALS[probe_goal] if probe_goal < PROBE_GOALS.size() else {}


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


func _units_spare(state: SimState, p: SimPlayer, launch: Dictionary) -> bool:
	var reserved := _reserved_units(state, p)
	for prog in _launch_programs(launch):
		if prog.is_eva_suit() or prog.is_photo_recon():
			continue
		if prog.units - int(reserved.get(prog, 0)) < 1:
			return false
	return true


## Geometric mean per-step pass chance of the mission, from the step letters and the
## effective safety of the hardware each one rolls against. Compared against the bars.
func success_probability(state: SimState, launch: Dictionary) -> float:
	var m: Dictionary = state.data.missions[launch["mission_index"]]
	var steps := SimMission.parse_code(m["code"], m["lunar"] == 1)
	var pen: int = launch["requirement_penalty"] + launch["rush_penalty"]
	var log_sum := 0.0
	var count := 0
	for st in steps:
		var letter: String = st["letter"]
		if not LETTER_CLASS.has(letter) or st.get("past_bang", false):
			continue
		var v: Dictionary = launch["vehicles"][clampi(int(st.get("vehicle", 0)), 0, launch["vehicles"].size() - 1)]
		var safety := _step_safety(LETTER_CLASS[letter], v, pen, launch["lm_penalty"])
		if safety <= 0:
			continue
		var repeat := maxi(int(st.get("repeat", 1)), 1)
		for i in repeat:
			log_sum += log(clampf(safety / 100.0, 0.01, 0.99))
			count += 1
	if count == 0:
		return 0.0
	return exp(log_sum / count)


## Chance that every step passes, for reporting.
func mission_probability(state: SimState, launch: Dictionary) -> float:
	var m: Dictionary = state.data.missions[launch["mission_index"]]
	var steps := SimMission.parse_code(m["code"], m["lunar"] == 1)
	var n := 0
	for st in steps:
		if LETTER_CLASS.has(st["letter"]) and not st.get("past_bang", false):
			n += maxi(int(st.get("repeat", 1)), 1)
	return pow(success_probability(state, launch), n)


func _step_safety(cls: String, v: Dictionary, pen: int, lm_pen: int) -> int:
	var pay: Dictionary = v["payload"]
	var prog: SimProgram = null
	match cls:
		"rocket":
			var s: int = v["rocket"].safety - pen
			if v["boosters"] != null:
				s = int(s * (v["boosters"].safety - pen) / 100.0)
			return s
		"boost":
			prog = pay["kicker"] if pay["kicker"] != null else (pay["capsule"] if pay["capsule"] != null else (pay["lm"] if pay["lm"] != null else pay["probe"]))
		"power":
			prog = pay["lm"] if pay["lm"] != null else (pay["probe"] if pay["probe"] != null else pay["docking"])
		"capsule":
			prog = pay["capsule"] if pay["capsule"] != null else pay["probe"]
		"eva":
			prog = pay["eva"]
		"docking":
			prog = pay["docking"]
		"lm":
			prog = pay["lm"] if pay["lm"] != null else pay["capsule"]
		"photo":
			prog = pay["photo"]
		"probe":
			prog = pay["probe"] if pay["probe"] != null else pay["capsule"]
	if prog == null:
		return 0
	var s := prog.safety - pen
	if prog.is_lm():
		s -= lm_pen
	if prog.is_docking_module():
		s = prog.safety        # the module is not researched; penalties still apply upstream, kept simple
	return s


func _bar_for(mi: int, state: SimState) -> float:
	var m: Dictionary = state.data.missions[mi]
	if mi >= SimPlanner.LUNAR_LANDING_FIRST:
		return _params["p_landing"]
	if m["lunar"] == 1:
		return _params["p_lunar"]
	if int(m["crew_mode"]) in [2, 3, 4]:
		return _params["p_manned"]
	if m["m_eq"] == 0:
		return _params["p_probe"]
	return _params["p_test"]


func _plan(game: SimGame, state: SimState, p: SimPlayer) -> void:
	# Drop stale plans whose goal has completed, and scrub stale lunar missions this season.
	var current: Array = [_current_manned_goal()["mission"]]
	if not _current_probe_goal().is_empty():
		current.append(_current_probe_goal()["mission"])
	for pad in 3:
		var pl = p.future[pad]
		if pl != null and pl.get("part", 1) == 1 and not (pl["mission_index"] in [1, 3, 5, 15]) and not (pl["mission_index"] in current):
			SimPlanner.cancel_plan(p, pad)
		var sched = p.missions[pad]
		if sched != null and sched.get("part", 1) == 1 and sched["mission_index"] >= 43 and not (sched["mission_index"] in current):
			game.scrub(p, pad)
	var free_pads: Array = []
	for pad in 3:
		if p.future[pad] == null and p.pad_usable(pad):
			free_pads.append(pad)
	if free_pads.is_empty():
		return
	# Manned goal first.
	var goal := _current_manned_goal()
	for pad in free_pads.duplicate():
		if _try_goal(state, p, goal, pad):
			free_pads.erase(pad)
			if state.data.missions[goal["mission"]]["joint"] == 1:
				free_pads.erase(pad + 1)
			break
	# Probe goal next.
	var pg := _current_probe_goal()
	if not pg.is_empty():
		for pad in free_pads.duplicate():
			if _try_goal(state, p, pg, pad):
				free_pads.erase(pad)
				break
	# Test flights with whatever is left.
	for pad in free_pads:
		_plan_test(state, p, pad)


func _try_goal(state: SimState, p: SimPlayer, goal: Dictionary, pad: int) -> bool:
	var mi: int = goal["mission"]
	var duration: int = goal["duration"]
	if not SimPlanner.can_plan(state, p, mi, pad, duration)["ok"]:
		return false
	var launch := SimPlanner.assemble(state, p, _trial_plan(state, mi, duration, pad))
	if not launch.has("vehicles") or not _units_spare(state, p, launch):
		return false
	var prob := success_probability(state, launch)
	var exhausted := true
	for prog in _launch_programs(launch):
		if prog.can_research():
			exhausted = false
	if prob >= _bar_for(mi, state) or (exhausted and prob >= _bar_for(mi, state) * 0.8):
		return SimPlanner.plan(state, p, mi, pad, duration)
	return false


## An unmanned flight that raises the safety of hardware the goals need: docking tests
## when a docking module is below its ceiling, otherwise orbital tests of the capsule
## and rocket the manned goal uses.
func _plan_test(state: SimState, p: SimPlayer, pad: int) -> void:
	var options: Array = [5, 3, 1]
	var dm: SimProgram = p.program("misc", 4)
	if dm != null and dm.owned and dm.safety < dm.max_safety() - 5 and manned_goal >= 1:
		options = [15, 5, 3, 1]
	for mi in options:
		if not SimPlanner.can_plan(state, p, mi, pad)["ok"]:
			continue
		var launch := SimPlanner.assemble(state, p, _trial_plan(state, mi, 0, pad))
		if not launch.has("vehicles") or not _units_spare(state, p, launch):
			continue
		# Tests are worth flying when the hardware is past research but below max safety.
		var worth := false
		for prog in _launch_programs(launch):
			if prog.owned and not prog.can_research() and prog.safety < prog.max_safety() and not prog.is_photo_recon():
				worth = true
		if not worth and mi != 15:
			continue
		if success_probability(state, launch) >= _params["p_test"]:
			SimPlanner.plan(state, p, mi, pad)
			return
