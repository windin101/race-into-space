class_name SimMission
extends RefCounted
## Flying one launched mission: parse the step code, roll every step against its hardware
## and crew, apply the failure-table outcome, and produce the RESULT record that
## SimPrestige.award and the turn loop consume. Nothing here touches astronaut status;
## crew fates are reported in "crew_outcomes" for the turn loop to apply.
##
## Rules: docs/specs/code-derived-rules.md sections 2, 5, 7, 8, 9; constants.json
## "mission_step_letters", "failure_codes", "crew", "lm_tests", "docking_module",
## "photo_recon". Upstream: mc2.cpp MissionParse / MissionSteps / MissionSetDown,
## mis_m.cpp MisCheck / StepSafety / FailEval, prest.cpp Set_LM / Check_Dock / Check_Photo.
##
## Launch (built by the planner):
##   mission_index, player, pad, vehicles: [{rocket, boosters, payload: {capsule, lm, kicker,
##   probe, eva, docking, photo}, crew: [SimAstronaut]}], duration_level, requirement_penalty,
##   rush_penalty, lm_penalty, scrub_on_warning (optional, default false).
##
## Result: see fly().

const LOC_END := 127                ## loc of the '!' step (upstream 0x7f)
const TRACE_END := 127              ## "next step" value meaning the mission is over
const GOTO_END := 100               ## sgoto/fgoto value meaning the mission is over
const INFO_UNMANNED_FAIL := 1003
const INFO_SUCCESS := 1
const INFO_HARMLESS := 50
const INFO_DEATH := 3000
const INFO_MISSION_END := 1000
const MAX_ITERATIONS := 400

const CLASS_ROCKET := "rocket"
const CLASS_CAPSULE := "capsule"
const CLASS_LM := "lm"
const CLASS_KICKER := "kicker"
const CLASS_PROBE_DM := "probe_dm"
const CLASS_EVA := "eva"
const CLASS_PHOTO := "photo"
const CLASS_DURATION := "duration"

const CAPSULE_STEPS := ["D", "E", "F", "G", "K", "M", "N", "O", "X", "Y", "f", "g"]
const INSERTION_STEPS := ["B", "J", "L"]
const LEM_STEPS := ["Q", "R", "S", "T"]
const PROBE_STEPS := ["V", "W", "Z", "e"]

const LOC_LAUNCH := 0
const LOC_INSERTION := 1
const LOC_POWER_ON := 2
const LOC_LANDING := 4
const LOC_DOCKING := 8
const LOC_TLI := 9
const LOC_LUNAR_EVA := 15
const LOC_LEM_ACTIVITIES := 16
const LOC_LUNAR_LANDING := 18
const LOC_PHOTO := 20
const LOC_PLANETARY := 22
const LOC_LEM_TEST := 26
const LOC_DURATION := 27
const LOC_JOINT_DURATION := 28

const ROW_ORBITAL_SATELLITE := 0
const ROW_LUNAR_PROBE_LANDING := 7
const ROW_MANNED_ORBITAL := 18
const ROW_LUNAR_PASS := 19
const ROW_LUNAR_ORBIT := 20
const ROW_LUNAR_LANDING := 22
const ROW_MANNED_DOCKING := 24
const ROW_SPACEWALK := 26
const ROW_MANNED_SPACE_MISSION := 27
const ROW_FIRST_CAPSULE := 13       ## + capsule slot
const PLANET_ROW_BY_MISSION := {7: 1, 11: 2, 9: 3, 10: 4, 12: 5, 13: 6}
const MANNED_GOAL_ROWS := [22, 20, 19, 18, 27]   ## PosGoal priority order

const MISSION_LUNAR_FLYBY := 7
const MISSION_LUNAR_PROBE := 8
const MISSION_LUNAR_ORBITAL_LM_TEST := 48
const LM_TEST_DOUBLE_FIRST := 48
const LM_TEST_DOUBLE_LAST := 52
const DIRECT_ASCENT_MISSIONS := [54, 57]
const LAB_MISSIONS := [19, 22, 23, 30, 32, 35, 36, 37]
const EASY_DIE_UNIFORM_BELOW := 66
const EASY_DIE_MEAN := 57.0
const EASY_DIE_VARIANCE := 1000.0
const DOCKING_LIMIT_MANNED := 500
const DOCKING_LIMIT_UNMANNED := 2

const GROUP_ID_LETTER := {"probe": "P", "rocket": "R", "manned": "C", "misc": "M"}

static var _step_letters: Dictionary = {}


# ---------------------------------------------------------------------------------------
# Parsing
# ---------------------------------------------------------------------------------------

## Parse a mission code into step records, one per upstream STEP slot (so '!' and 'd'
## occupy an index, matching missions[i].alt). Each: {letter, loc, vehicle, repeat,
## past_bang, alt_marker}. repeat is 0, or 1..n for steps produced by ~nX.
static func parse_code(code: String, lunar := false) -> Array:
	var steps: Array = []
	var vehicle := 0
	var past_bang := false
	var i := 0
	while i < code.length() and code[i] != "|":
		var c: String = code[i]
		match c:
			"@":
				steps.append(_make_step("b", vehicle, 0, past_bang, lunar))
				i += 2
			"%":
				steps.append(_make_step("c", vehicle, 0, past_bang, lunar))
				i += 2
			"~":
				var n := int(code.substr(i + 1, 1))
				var letter := code.substr(i + 2, 1)
				for j in n:
					steps.append(_make_step(letter, vehicle, j + 1, past_bang, lunar))
				i += 3
			"+":
				vehicle = int(code.substr(i + 1, 1)) - 1
				i += 2
			"^":
				vehicle = 1
				i += 1
			"&":
				vehicle = 0
				i += 1
			_:
				if c == "!" or _is_step_letter(c):
					if c == "I":
						vehicle = 0
					steps.append(_make_step(c, vehicle, 0, past_bang, lunar))
					if c == "!":
						past_bang = true
				i += 1
	return steps


static func _is_step_letter(c: String) -> bool:
	if c.length() != 1:
		return false
	var u := c.unicode_at(0)
	return (u >= 65 and u <= 90) or (u >= 97 and u <= 103)   # A-Z, a-g


static func _make_step(letter: String, vehicle: int, repeat: int, past_bang: bool, lunar: bool) -> Dictionary:
	var loc := LOC_END
	if letter != "!":
		loc = letter.unicode_at(0) - 65
		if loc > 25:
			loc -= 6
		if loc == 32 and lunar:
			loc = 29
	return {
		"letter": letter, "loc": loc, "vehicle": vehicle, "repeat": repeat,
		"past_bang": past_bang, "alt_marker": letter == "d",
	}


## Display name of a step letter from constants mission_step_letters.
static func step_name(letter: String) -> String:
	if _step_letters.is_empty():
		var path := "res://data/constants.json"
		if FileAccess.file_exists(path):
			var json := JSON.new()
			if json.parse(FileAccess.get_file_as_string(path)) == OK:
				_step_letters = json.data.get("mission_step_letters", {})
	if letter == "!":
		return "END OF MISSION"
	var rec = _step_letters.get(letter)
	if rec is Dictionary:
		return rec.get("name", letter)
	return letter


# ---------------------------------------------------------------------------------------
# Flying
# ---------------------------------------------------------------------------------------

## Resolve the mission. Returns:
##   player, mission_index, manned, goals: [{row, success}], deaths, catastrophic,
##   outcome: "success" | "failure" | "scrubbed", steps: [attempt records],
##   crew_outcomes: {astronaut id: "ok"|"injured"|"dead"|"retired"}, hardware_lost: [names],
##   pad_damage: int, lm_points_gained, docking: "none"|"success"|"failure",
##   photo_success, duration_achieved, aborted_at (step index or -1).
static func fly(state: SimState, launch: Dictionary) -> Dictionary:
	var ctx := _setup(state, launch)
	_run(ctx)
	return _finish(ctx)


static func _setup(state: SimState, launch: Dictionary) -> Dictionary:
	var pidx: int = launch["player"]
	var p := state.player(pidx)
	var mission: Dictionary = state.data.missions[launch["mission_index"]]
	var ctx := {
		"state": state, "p": p, "pidx": pidx, "launch": launch, "mission": mission,
		"mission_index": int(launch["mission_index"]),
		"vehicles": [], "steps": [], "attempts": [],
		"programs": [], "succ": {}, "fail": {},
		"in_space": 0, "mflag": 0, "no_dock": false, "durx": -1, "durxx": -1, "duration": 0,
		"scrubbed": false, "death": false, "deaths": 0, "dead": {}, "crew_outcomes": {},
		"hardware_lost": [], "pad_damage": 0, "killers": [], "aborted_at": -1,
		"total_manned": 0, "failure_index": {},
	}
	_init_step_letters(state)
	for row in state.data.failures:
		var key: String = row["step"]
		if not ctx["failure_index"].has(key):
			ctx["failure_index"][key] = []
		ctx["failure_index"][key].append(row)

	# Vehicles and crews.
	var vehicles: Array = launch.get("vehicles", [])
	for i in vehicles.size():
		var v: Dictionary = vehicles[i]
		var payload: Dictionary = v.get("payload", {})
		var crew: Array = v.get("crew", [])
		var vc := {
			"pad": int(launch.get("pad", 0)) + i,
			"rocket": v.get("rocket"), "boosters": v.get("boosters"),
			"capsule": payload.get("capsule"), "lm": payload.get("lm"),
			"kicker": payload.get("kicker"), "probe": payload.get("probe"),
			"docking": payload.get("docking"), "eva": payload.get("eva"),
			"photo": payload.get("photo"),
			"crew": crew, "manned": crew.size(), "seats": _seats(state, crew.size()),
		}
		if vc["photo"] == null:
			vc["photo"] = p.program("misc", 5)
		ctx["vehicles"].append(vc)
		ctx["total_manned"] += crew.size()
		for a in crew:
			ctx["crew_outcomes"][a.id] = "ok"
		for key in ["rocket", "boosters", "capsule", "lm", "kicker", "probe", "docking", "eva", "photo"]:
			var prog = vc[key]
			if prog != null and not ctx["programs"].has(prog):
				ctx["programs"].append(prog)

	# Mission safety after the planner's penalties (mc2.cpp MisSkip, MissionSetup LM block).
	var req: int = launch.get("requirement_penalty", 0)
	var rush: int = launch.get("rush_penalty", 0)
	var lm_pen: int = launch.get("lm_penalty", 0)
	for prog in ctx["programs"]:
		var pen := req + rush + (lm_pen if prog.is_lm() else 0)
		prog.mission_safety = clampi(prog.safety - pen, 1, 99)
		ctx["succ"][prog] = 0
		ctx["fail"][prog] = 0

	# Planned duration (mis_m.cpp:177-186).
	var planned: int = launch.get("duration_level", 0)
	if planned > 0:
		ctx["durxx"] = planned - 1

	# Steps.
	var steps := parse_code(mission["code"], mission.get("lunar", 0) == 1)
	var alt: Array = mission.get("alt", [])
	var alt_d: Array = mission.get("alt_d", [])
	for i in steps.size():
		var s: Dictionary = steps[i]
		s["index"] = i
		var a: int = alt[i] if i < alt.size() else -1
		s["sgoto"] = 0
		s["fgoto"] = i + 1 if a == -2 else a
		s["dgoto"] = alt_d[i] if i < alt_d.size() else 0
		s["invalidated"] = false
		s["evaluated"] = false
		s["step_info"] = 0
		s["trace"] = 0
		if s["vehicle"] >= ctx["vehicles"].size():
			s["vehicle"] = maxi(ctx["vehicles"].size() - 1, 0)
	for i in steps.size():
		var s: Dictionary = steps[i]
		if i == 0:
			continue
		var prev: Dictionary = steps[i - 1]
		if s["alt_marker"]:
			var a: int = alt[i] if i < alt.size() else 0
			var target := GOTO_END if a == 0 else a
			prev["sgoto"] = target
			prev["fgoto"] = target
		elif s["letter"] == "!":
			prev["sgoto"] = GOTO_END
	ctx["steps"] = steps
	for s in steps:
		_assign_hardware(ctx, s)
	return ctx


static func _init_step_letters(state: SimState) -> void:
	if _step_letters.is_empty():
		_step_letters = state.constants().get("mission_step_letters", {})


static func _seats(state: SimState, n: int) -> Dictionary:
	var out := {"cap": -1, "lm": -1, "eva": -1, "dock": -1}
	if n <= 0:
		return out
	var table: Dictionary = state.constants().get("crew", {}).get("role_slots_by_crew_size", {})
	var rec = table.get(str(mini(n, 4)), {})
	for key in out:
		var v = rec.get(key)
		out[key] = -1 if v == null else int(v)
	return out


static func _hw_id(prog) -> String:
	if prog == null:
		return ""
	return GROUP_ID_LETTER.get(prog.group, "?") + str(prog.slot)


static func _has_kicker_c(vc: Dictionary) -> bool:
	var k = vc["kicker"]
	return k != null and k.is_kicker() and k.slot == 2


## Hardware class and prestige row for one step (mc2.cpp MissionSteps).
static func _assign_hardware(ctx: Dictionary, s: Dictionary) -> void:
	s["class"] = ""
	s["hardware"] = null
	s["row"] = -1
	s["asf"] = 0
	s["ast"] = -1
	s["fname"] = ""
	s["name"] = ""
	if s["letter"] == "!" or s["alt_marker"] or ctx["vehicles"].is_empty():
		return
	var vc: Dictionary = ctx["vehicles"][s["vehicle"]]
	var letter: String = s["letter"]
	var cls := ""
	if letter == "A":
		cls = CLASS_ROCKET
	elif letter in CAPSULE_STEPS:
		cls = CLASS_KICKER if _has_kicker_c(vc) else CLASS_CAPSULE
	elif letter == "b" or letter == "c":
		cls = CLASS_DURATION
	elif letter == "a":
		cls = CLASS_LM
	elif letter == "C":
		if _has_kicker_c(vc):
			cls = CLASS_KICKER
		elif vc["lm"] != null:
			cls = CLASS_LM
		else:
			cls = CLASS_PROBE_DM
	elif letter in PROBE_STEPS:
		cls = CLASS_PROBE_DM
	elif letter == "H" or letter == "P":
		cls = CLASS_EVA
	elif letter == "U":
		cls = CLASS_PHOTO
	elif letter in INSERTION_STEPS:
		if vc["kicker"] != null:
			cls = CLASS_KICKER
		elif vc["capsule"] != null:
			cls = CLASS_CAPSULE
		elif vc["lm"] != null:
			cls = CLASS_LM
		else:
			cls = CLASS_PROBE_DM
		if s["index"] > 11 and vc["capsule"] != null:
			cls = CLASS_CAPSULE
	elif letter in LEM_STEPS:
		if _has_kicker_c(vc):
			cls = CLASS_KICKER
		elif vc["lm"] != null:
			cls = CLASS_LM
		elif vc["capsule"] != null:
			cls = CLASS_CAPSULE
		else:
			cls = CLASS_PROBE_DM
	elif letter == "I":
		cls = CLASS_PROBE_DM

	# Prestige row.
	var row := -1
	match letter:
		"B":
			row = ROW_MANNED_ORBITAL if vc["capsule"] != null else -1
		"C":
			var pdm_c = _probe_dm(ctx, s["vehicle"], letter)
			row = ROW_ORBITAL_SATELLITE if (pdm_c != null and pdm_c.is_probe() and pdm_c.slot == 0) else -1
		"D":
			row = ROW_MANNED_SPACE_MISSION
		"H", "P":
			row = ROW_SPACEWALK
		"I":
			row = ROW_MANNED_DOCKING if ctx["total_manned"] > 0 else -1
		"L":
			row = ROW_LUNAR_ORBIT if vc["capsule"] != null else -1
		"O":
			row = ROW_LUNAR_PASS
		"S":
			var pdm_s = _probe_dm(ctx, s["vehicle"], letter)
			row = ROW_LUNAR_PROBE_LANDING if (pdm_s != null and pdm_s.is_probe() and pdm_s.slot == 2) else -1
		"T":
			row = ROW_LUNAR_LANDING
		"W":
			row = PLANET_ROW_BY_MISSION.get(ctx["mission_index"], -1)
	# Steps on the alternate branch carry no prestige, except Lunar Orbit.
	if s["past_bang"] and row >= 0 and letter != "L":
		row = -1
	s["row"] = row

	# Crew skill for the role (mc2.cpp:430-480).
	var seats: Dictionary = vc["seats"]
	var crew: Array = vc["crew"]
	if vc["manned"] > 0:
		var seat := -1
		var skill := ""
		match cls:
			CLASS_CAPSULE:
				seat = seats["cap"]
				skill = "capsule"
			CLASS_LM:
				seat = seats["lm"]
				skill = "lm"
			CLASS_PROBE_DM:
				seat = seats["dock"]
				skill = "docking"
			CLASS_EVA:
				seat = seats["eva"]
				skill = "eva"
			CLASS_DURATION:
				if ctx["state"].options.get("use_endurance", true):
					s["asf"] = _crew_endurance(crew)
		if seat >= 0 and seat < crew.size() and skill != "":
			s["ast"] = seat
			s["asf"] = crew[seat].skill(skill)
	if cls == CLASS_DURATION:
		cls = CLASS_CAPSULE
	s["class"] = cls
	s["hardware"] = _hardware_for(ctx, s["vehicle"], cls, letter)
	s["name"] = _step_anim_name(ctx, s)
	s["fname"] = _failure_key(ctx, s)


static func _crew_endurance(crew: Array) -> int:
	if crew.is_empty():
		return 0
	var total := 0
	for a in crew:
		total += a.skill("endurance")
	return int(float(total) / float(crew.size()) + 0.5)


## The probe-or-docking-module slot: the docking module for 'I', otherwise the probe
## when one is carried, else the docking module (upstream Hard[Probe_DM] == 4).
static func _probe_dm(ctx: Dictionary, vi: int, letter: String):
	var vc: Dictionary = ctx["vehicles"][vi]
	if letter == "I":
		return vc["docking"]
	return vc["probe"] if vc["probe"] != null else vc["docking"]


## Hardware of a class on a vehicle, falling back to the other launch (GetEquipment).
static func _hardware_for(ctx: Dictionary, vi: int, cls: String, letter: String):
	var vehicles: Array = ctx["vehicles"]
	var order := [vi]
	if vehicles.size() > 1:
		order.append(1 - vi if vi <= 1 else 0)
	for v in order:
		var vc: Dictionary = vehicles[v]
		var hw = null
		match cls:
			CLASS_ROCKET:
				hw = vc["rocket"]
			CLASS_CAPSULE:
				hw = vc["capsule"]
			CLASS_LM:
				hw = vc["lm"]
			CLASS_KICKER:
				hw = vc["kicker"]
			CLASS_PROBE_DM:
				hw = _probe_dm(ctx, v, letter)
			CLASS_EVA:
				hw = vc["eva"]
			CLASS_PHOTO:
				hw = vc["photo"]
		if hw != null:
			return hw
	return null


## Upstream Mev.Name: letter + side + hardware ID (+ EVA suffix); only the ID characters
## matter here, they select the failure-table variant.
static func _step_anim_name(ctx: Dictionary, s: Dictionary) -> String:
	var letter: String = s["letter"]
	if letter == "H" and (ctx["mission_index"] == MISSION_LUNAR_ORBITAL_LM_TEST or s["past_bang"]):
		return "HMOON"
	var side := "U" if ctx["pidx"] == 0 else "S"
	var name := letter + side + _hw_id(s["hardware"])
	if s["class"] == CLASS_EVA:
		var vehicles: Array = ctx["vehicles"]
		var vc: Dictionary = vehicles[s["vehicle"]]
		var other: Dictionary = vehicles[1] if vehicles.size() > 1 else vc
		if _has_kicker_c(vehicles[0]):
			name += "M2"
		elif vc["capsule"] != null and vc["capsule"].slot == 4:
			name += "C4"
		elif letter == "P":
			name += _hw_id(vc["lm"] if vc["lm"] != null else other["lm"])
		else:
			name += _hw_id(vc["capsule"] if vc["capsule"] != null else other["capsule"])
	return name


static func _char_at(s: String, i: int) -> String:
	return s[i] if i < s.length() else ""


## Failure table key F<variant><loc> (mc2.cpp:603-688).
static func _failure_key(ctx: Dictionary, s: Dictionary) -> String:
	var loc: int = s["loc"]
	var name: String = s["name"]
	var hw = s["hardware"]
	var vc: Dictionary = ctx["vehicles"][s["vehicle"]]
	var variant := "0"
	var loc_key := "%02d" % loc
	if loc == 32 or loc == 29:
		loc_key = "01"
	var capsule = vc["capsule"]
	if loc == LOC_LAUNCH and capsule != null and capsule.is_capsule() and capsule.slot == 3:
		variant = "1"          # minishuttle launch
	elif loc == LOC_LANDING and hw != null and hw.is_capsule() and hw.slot == 3:
		variant = "3"          # minishuttle landing
	elif ctx["pidx"] == 1 and loc == LOC_LANDING:
		variant = "1" if (hw != null and hw.is_capsule() and hw.slot == 0) else "2"
	var n2 := _char_at(name, 2)
	var n3 := _char_at(name, 3)
	if n2 == "C" and loc == LOC_POWER_ON:
		variant = "1"
	if name.substr(2, 4) == "M3C0":
		variant = "1"
	if n2 != "P":
		if loc == LOC_LUNAR_EVA and _char_at(name, 5) == "6":
			variant = "1"
		if loc == LOC_LEM_ACTIVITIES and s["index"] > 8:
			var prev: Dictionary = ctx["steps"][s["index"] - 1]
			if prev["loc"] == LOC_LUNAR_LANDING and n3 >= "5":
				variant = "2"
			elif prev["loc"] == LOC_LUNAR_LANDING and n3 <= "4":
				variant = "3"
			else:
				variant = "1"
		if loc >= 17 and loc <= 19 and n3 <= "4":
			variant = "1"
		if loc == LOC_LUNAR_LANDING and n3 != "4" and n2 != "M":
			variant = "0"
		# Upstream also tests Name[4] on photo steps for F120; the name is 4 chars, so it
		# never fires and is omitted here.
	return "F" + variant + loc_key


# ---------------------------------------------------------------------------------------
# The step loop (mis_m.cpp MisCheck)
# ---------------------------------------------------------------------------------------

static func _run(ctx: Dictionary) -> void:
	var steps: Array = ctx["steps"]
	if steps.is_empty():
		return
	var cur := 0
	var prev := -1
	var iterations := 0
	while iterations < MAX_ITERATIONS:
		iterations += 1
		# Duration hack part 1: repeat a passed duration step, or end durations on a failure.
		if prev >= 0:
			var ps: Dictionary = steps[prev]
			if (ps["loc"] == LOC_DURATION or ps["loc"] == LOC_JOINT_DURATION) and ctx["durx"] > 0:
				if ps["step_info"] != INFO_SUCCESS:
					ctx["duration"] = 1
					ctx["durx"] = -1
				else:
					ctx["duration"] += 1
					ctx["durx"] -= 1
					ps["trace"] = prev
			cur = ps["trace"]
		if cur == TRACE_END or cur < 0 or cur >= steps.size():
			break
		# Skip markers and steps with no hardware (upstream "bogus step").
		var skipped := false
		while cur < steps.size():
			var s: Dictionary = steps[cur]
			if s["letter"] == "!":
				skipped = true
				break
			if s["alt_marker"] or s["hardware"] == null:
				cur += 1
				continue
			break
		if skipped or cur >= steps.size():
			break
		var step: Dictionary = steps[cur]
		# Duration hack part 2: arm the duration counter on the first duration step.
		if (step["loc"] == LOC_DURATION or step["loc"] == LOC_JOINT_DURATION) and ctx["durx"] == -1:
			ctx["durx"] = ctx["durxx"] - 1
			ctx["duration"] = 2
		_evaluate(ctx, step)
		# Post-step bookkeeping (mis_m.cpp:470-520).
		if step["loc"] == LOC_END or step["sgoto"] == GOTO_END:
			step["trace"] = TRACE_END
		if step["sgoto"] == step["fgoto"] and step["trace"] != TRACE_END:
			step["trace"] = step["sgoto"]
		if step["loc"] == LOC_DOCKING and step["step_info"] == INFO_SUCCESS:
			ctx["no_dock"] = true
		var vc: Dictionary = ctx["vehicles"][step["vehicle"]]
		if step["loc"] == LOC_LAUNCH and vc["manned"] > 0:
			ctx["in_space"] += 1
		if step["loc"] == LOC_LANDING and vc["manned"] > 0:
			ctx["in_space"] -= 1
		if step["trace"] == TRACE_END and cur == 3 and ctx["mission_index"] in LAB_MISSIONS:
			ctx["in_space"] = 1
			step["trace"] = step["dgoto"]
		if step["trace"] == GOTO_END:
			step["trace"] = TRACE_END
		prev = cur
		if step["trace"] == TRACE_END:
			break


## Roll one step and record the attempt.
static func _evaluate(ctx: Dictionary, step: Dictionary) -> void:
	var state: SimState = ctx["state"]
	var p: SimPlayer = ctx["p"]
	var hw = step["hardware"]
	var vc: Dictionary = ctx["vehicles"][step["vehicle"]]
	var die := _roll_die(state, p)
	var safety := _step_safety(ctx, step)
	var problem := die > safety
	var saved := false
	if problem and p.save_cards > 0:
		p.save_cards -= 1
		problem = false
		saved = true
	step["evaluated"] = true
	var attempt := {
		"index": step["index"], "letter": step["letter"], "loc": step["loc"],
		"name": step_name(step["letter"]), "vehicle": step["vehicle"],
		"hardware": hw.display_name() if hw != null else "", "safety": safety, "roll": die,
		"success": not problem, "step_info": 0, "failure": null, "save_card": saved,
	}
	var dm_power_on: bool = hw != null and hw.is_docking_module() and step["loc"] == LOC_POWER_ON
	if problem:
		var rnum: int = state.rng.d(10000)
		if ctx["total_manned"] == 0 or (vc["manned"] == 0 and not ctx["no_dock"]):
			rnum = -state.rng.d(5)
		var fail := _lookup_failure(ctx, step["fname"], rnum)
		attempt["failure"] = {
			"code": fail.get("code", 0), "val": fail.get("val", 0), "xtra": fail.get("xtra", 0),
			"fail": fail.get("fail", 0), "text": fail.get("text", ""), "key": step["fname"],
		}
		_fail_eval(ctx, step, fail)
		if step["trace"] == TRACE_END and ctx["aborted_at"] == -1 and step["step_info"] >= INFO_MISSION_END:
			ctx["aborted_at"] = step["index"]
	else:
		if dm_power_on:
			p.docking_module_in_orbit = state.constants().get("docking_module", {}).get("in_orbit_seasons_after_power_on", 2)
		else:
			ctx["succ"][hw] += 1
		if step["sgoto"] == GOTO_END:
			step["trace"] = TRACE_END
		elif step["sgoto"] != 0:
			step["trace"] = step["sgoto"]
		else:
			step["trace"] = step["index"] + 1
		step["step_info"] = INFO_SUCCESS
	attempt["step_info"] = step["step_info"]
	ctx["attempts"].append(attempt)


## The mission die (mc2.cpp:493, game_main.cpp MisRandom).
static func _roll_die(state: SimState, p: SimPlayer) -> int:
	if p.level == 0:
		var r := state.rng.d(100)
		if r < EASY_DIE_UNIFORM_BELOW:
			return r
		while true:
			var g := int(state.rng.gaussian(EASY_DIE_MEAN, sqrt(EASY_DIE_VARIANCE)) + 0.5)
			if g >= EASY_DIE_UNIFORM_BELOW and g < 101:
				return g
	return state.rng.d(98 if p.is_ai else 100)


## StepSafety: hardware mission safety, boosters, joint duration, docking kludge, crew.
static func _step_safety(ctx: Dictionary, step: Dictionary) -> int:
	var hw = step["hardware"]
	var vc: Dictionary = ctx["vehicles"][step["vehicle"]]
	var loc: int = step["loc"]
	var safety: int = hw.mission_safety
	var options: Dictionary = ctx["state"].options
	if step["letter"] == "A" and vc["boosters"] != null:
		var b: int = vc["boosters"].safety
		if options.get("classic_boosters", false):
			safety = int((safety + b) / 2.0)
		elif options.get("booster_safety_min", false):
			safety = mini(safety, b)
		else:
			safety = int(safety * b / 100.0)
	elif (loc == LOC_DURATION or loc == LOC_JOINT_DURATION) and ctx["in_space"] == 2:
		var vehicles: Array = ctx["vehicles"]
		if vehicles.size() > 1 and vehicles[0]["capsule"] != null and vehicles[1]["capsule"] != null:
			safety = int((vehicles[0]["capsule"].mission_safety + vehicles[1]["capsule"].mission_safety) / 2.0)
	elif hw.is_docking_module() and (loc == LOC_INSERTION or loc == LOC_POWER_ON):
		safety = _docking_kludge_safety(ctx["p"])
	safety += step["asf"]
	return mini(safety, 99)


## DockingKludge: on insertion/power-on the docking module rides on the best probe.
static func _docking_kludge_safety(p: SimPlayer) -> int:
	var best := 0
	for prog in p.programs["probe"]:
		if prog != null and prog.owned:
			best = maxi(best, prog.safety)
	return best


static func _lookup_failure(ctx: Dictionary, key: String, rnum: int) -> Dictionary:
	for row in ctx["failure_index"].get(key, []):
		var pct: int = row["percentage"]
		if rnum < 0:
			if pct == rnum:
				return row
		elif pct > rnum:
			return row
	return {}


# ---------------------------------------------------------------------------------------
# Failure handling (mis_m.cpp FailEval)
# ---------------------------------------------------------------------------------------

static func _fail_eval(ctx: Dictionary, step: Dictionary, fail: Dictionary) -> void:
	var state: SimState = ctx["state"]
	var hw = step["hardware"]
	var vi: int = step["vehicle"]
	var vc: Dictionary = ctx["vehicles"][vi]
	var loc: int = step["loc"]
	var cur: int = step["index"]
	var code: int = fail.get("code", 0)
	var val: int = fail.get("val", 0)
	var xtra: int = fail.get("xtra", 0)
	var dm_power_on: bool = hw.is_docking_module() and loc == LOC_POWER_ON
	if not dm_power_on:
		ctx["fail"][hw] += 1

	# Fully unmanned: any failure ends the mission.
	if ctx["total_manned"] == 0:
		step["step_info"] = INFO_UNMANNED_FAIL
		step["trace"] = TRACE_END
		if code == 12:
			_destroy_pad(ctx, vc["pad"], 20)
		if loc == LOC_PHOTO and ctx["mission_index"] == MISSION_LUNAR_PROBE and cur > 0:
			var prev_hw = ctx["steps"][cur - 1]["hardware"]
			if prev_hw != null:
				ctx["fail"][prev_hw] += 1
		_lose_hardware(ctx, hw)
		return

	step["step_info"] = 0
	var fnote := 5
	ctx["death"] = false
	match code:
		0, 20:
			fnote = 0
			step["step_info"] = INFO_HARMLESS
			step["trace"] = TRACE_END if step["fgoto"] == -1 else cur + 1
		2:
			step["step_info"] = INFO_MISSION_END + loc
			step["trace"] = TRACE_END
			_lose_hardware(ctx, hw)
		3, 5:
			fnote = 8
			var target := vi
			if ctx["in_space"] > 0 and vc["manned"] == 0 and _hw_id(hw) == "M2":
				target = _other_vehicle(ctx, vi)
			_kill_all(ctx, step, target)
			step["step_info"] = 4600 + loc
			step["trace"] = TRACE_END
			_lose_hardware(ctx, hw)
		4:
			step["step_info"] = 1900 + loc
			fnote = _branch_alternate(step)
		6:
			fnote = 0
			hw.mission_safety = maxi(hw.mission_safety - absi(val), 1)
			step["step_info"] = 900 + loc
			step["trace"] = cur + 1
		7:
			fnote = 0
			step["step_info"] = 1700 + loc
			step["trace"] = TRACE_END if step["fgoto"] == -1 else cur + 1
		9:
			if loc == LOC_LAUNCH and vc["manned"] > 0:
				ctx["in_space"] -= 1
			fnote = 2
			step["step_info"] = 9
			step["trace"] = cur
		12:
			hw.mission_safety = maxi(hw.mission_safety - absi(val), 1)
			step["step_info"] = 1600 + loc
			_destroy_pad(ctx, vc["pad"], absi(xtra))
			step["trace"] = TRACE_END
			_lose_hardware(ctx, hw)
		13:
			fnote = 8
			_kill_all(ctx, step, vi)
			_destroy_pad(ctx, vc["pad"], absi(xtra) if val == 0 else absi(val))
			step["step_info"] = 4500 + loc
			step["trace"] = TRACE_END
			_lose_hardware(ctx, hw)
		15:
			fnote = 3
			hw.mission_safety = maxi(hw.mission_safety - state.rng.d(20), 1)
			step["step_info"] = 15
		16:
			fnote = 0
			step["step_info"] = 1100 + loc
			for a in vc["crew"]:
				if state.rng.below(100) < val:
					if state.rng.below(100) >= xtra:
						_injure(ctx, a)
						step["step_info"] = maxi(2100 + loc, step["step_info"])
						if fnote == 0:
							fnote = 9
					else:
						_kill_one(ctx, step, a)
						step["step_info"] = 3100 + loc
						fnote = 8
			fnote = _branch_if_alive(ctx, step, fnote)
		17:
			fnote = 0
			step["step_info"] = 1300 + loc
			for a in vc["crew"]:
				if state.rng.below(100) < xtra:
					_retire(ctx, a)
					step["step_info"] = 2300 + loc
					fnote = 9
			for a in vc["crew"]:
				if state.rng.below(100) >= val:
					_kill_one(ctx, step, a)
					step["step_info"] = 3300 + loc
					fnote = 8
			fnote = _branch_if_alive(ctx, step, fnote)
		18:
			if (ctx["mflag"] & val) > 0:
				fnote = 1
				step["step_info"] = 1800 + loc
				_invalidate(step)
				if step["fgoto"] == -1:
					step["trace"] = TRACE_END
					fnote = 0
				else:
					step["trace"] = _goto_target(step["fgoto"])
			else:
				fnote = 0
				step["step_info"] = 18
				ctx["mflag"] = ctx["mflag"] | val
				step["trace"] = TRACE_END if step["fgoto"] == -1 else cur + 1
		19:
			if loc == LOC_LAUNCH and vc["manned"] > 0:
				ctx["in_space"] -= 1
			fnote = 2
			if (ctx["mflag"] & val) > 0:
				step["step_info"] = 1200 + loc
			else:
				step["step_info"] = 19
				ctx["mflag"] = ctx["mflag"] | val
			step["trace"] = cur
		22:
			step["step_info"] = 19
			if state.rng.below(100) > val:
				fnote = 8
				var victim = _eva_astronaut(ctx, vi)
				if victim != null:
					_kill_one(ctx, step, victim)
				step["step_info"] = 3200 + loc
			step["trace"] = _goto_target(step["fgoto"])
		23:
			fnote = 0
			step["step_info"] = 23 + loc
			for a in vc["crew"]:
				if state.rng.below(100) < val:
					fnote = 9
					_retire(ctx, a)
					step["step_info"] = 2400 + loc
			_invalidate(step)
			step["trace"] = TRACE_END if step["fgoto"] == -1 else _goto_target(step["fgoto"])
		24:
			_cut_permanent_safety(ctx, hw)
			step["step_info"] = 800 + loc
			step["trace"] = TRACE_END
		25:
			step["step_info"] = 700
			step["trace"] = TRACE_END
		26:
			fnote = 1
			step["step_info"] = 1926
			_cut_permanent_safety(ctx, hw)
			_invalidate(step)
			if step["fgoto"] == -1:
				step["trace"] = TRACE_END
				fnote = 7
			else:
				step["trace"] = _goto_target(step["fgoto"])
		30:
			ctx["duration"] = 1
			ctx["durx"] = -1
			fnote = 7
			step["step_info"] = 1950
			step["trace"] = cur + 1
		31:
			step["trace"] = step["dgoto"]
			step["step_info"] = 3100 + cur
			if ctx["mission_index"] in DIRECT_ASCENT_MISSIONS:
				_kill_all(ctx, step, vi)
			else:
				for a in _lm_crew(ctx, vi):
					_kill_one(ctx, step, a)
			ctx["death"] = true
		33:
			fnote = 8
			if vc["manned"] > 0:
				_kill_all(ctx, step, vi)
			var other := _other_vehicle(ctx, vi)
			if other != vi and ctx["vehicles"][other]["manned"] > 0:
				_kill_all(ctx, step, other)
			step["step_info"] = 4600 + loc
			step["trace"] = TRACE_END
		40:
			fnote = 1
			step["step_info"] = 1951
			if loc == LOC_TLI or loc == LOC_LEM_TEST or loc == LOC_JOINT_DURATION:
				fnote = _branch_alternate(step)
			else:
				fnote = 7
				_invalidate(step)
				step["trace"] = TRACE_END if step["fgoto"] == -1 else cur + 1
		_:
			fnote = 0
			step["step_info"] = INFO_HARMLESS
			step["trace"] = TRACE_END if step["fgoto"] == -1 else cur + 1

	# Code 15: the player may scrub; the AI (and the default) presses on.
	if fnote == 3:
		var scrub: bool = (not ctx["p"].is_ai) and ctx["launch"].get("scrub_on_warning", false)
		if scrub:
			step["step_info"] += 1000
			ctx["scrubbed"] = true
		else:
			step["trace"] = cur + 1
	if ctx["scrubbed"] and (loc != LOC_DOCKING or not ctx["no_dock"]):
		_invalidate(step)
		if step["fgoto"] == -1:
			step["trace"] = TRACE_END
		else:
			step["trace"] = _goto_target(step["fgoto"])

	# EVA suit failures never trigger death branching (upstream quirk).
	if _hw_id(hw) == "M3":
		ctx["death"] = false
	if ctx["death"]:
		if step["dgoto"] == 0:
			step["trace"] = TRACE_END
		elif step["dgoto"] > 0:
			step["trace"] = step["dgoto"]
	if code == 9 or code == 19:
		step["trace"] = cur
	ctx["death"] = false


## A goto target: -1 ends, step numbers jump, anything else negative also ends.
static func _goto_target(fgoto: int) -> int:
	return fgoto if fgoto >= 0 else TRACE_END


static func _invalidate(step: Dictionary) -> void:
	step["invalidated"] = true


## Codes 4 and 40: prestige on this step is lost and the mission jumps to the alternate
## step, or ends when there is none. Returns the upstream FNote (5 ended, else 1).
static func _branch_alternate(step: Dictionary) -> int:
	_invalidate(step)
	if step["fgoto"] == -1:
		step["trace"] = TRACE_END
		return 5
	step["trace"] = _goto_target(step["fgoto"])
	return 5 if step["trace"] == TRACE_END else 1


static func _branch_if_alive(ctx: Dictionary, step: Dictionary, fnote: int) -> int:
	var vc: Dictionary = ctx["vehicles"][step["vehicle"]]
	var dead := 0
	for a in vc["crew"]:
		if ctx["dead"].has(a.id):
			dead += 1
	var out := fnote
	if dead == vc["manned"]:
		step["step_info"] = 4100 + step["loc"]
		step["trace"] = TRACE_END
	elif step["fgoto"] == -1:
		step["trace"] = TRACE_END
	else:
		if out == 0:
			out = 1
		step["trace"] = _goto_target(step["fgoto"])
	if step["loc"] == LOC_LAUNCH:
		if out == 0:
			out = 5
		step["trace"] = TRACE_END
	return out


static func _other_vehicle(ctx: Dictionary, vi: int) -> int:
	if ctx["vehicles"].size() < 2:
		return vi
	return 1 - vi if vi <= 1 else 0


static func _eva_astronaut(ctx: Dictionary, vi: int):
	var vc: Dictionary = ctx["vehicles"][vi]
	var seat: int = vc["seats"]["eva"]
	if seat >= 0 and seat < vc["crew"].size():
		return vc["crew"][seat]
	var other := _other_vehicle(ctx, vi)
	var oc: Dictionary = ctx["vehicles"][other]
	seat = oc["seats"]["eva"]
	if seat >= 0 and seat < oc["crew"].size():
		return oc["crew"][seat]
	return null


## LMCrew: the LM specialist, plus the commander for a two-seat LM.
static func _lm_crew(ctx: Dictionary, vi: int) -> Array:
	var vehicles: Array = ctx["vehicles"]
	var pad := vi
	if vehicles[pad]["manned"] == 0:
		pad = _other_vehicle(ctx, vi)
	var vc: Dictionary = vehicles[pad]
	var lm = vehicles[0]["lm"]
	if lm == null and vehicles.size() > 1:
		lm = vehicles[1]["lm"]
	var capacity: int = lm.crew_capacity() if lm != null else 1
	var out: Array = []
	var seats: Dictionary = vc["seats"]
	if seats["lm"] > 0 and seats["lm"] < vc["crew"].size():
		out.append(vc["crew"][seats["lm"]])
	if capacity == 2 and seats["cap"] >= 0 and seats["cap"] < vc["crew"].size():
		out.append(vc["crew"][seats["cap"]])
	return out


static func _kill_all(ctx: Dictionary, step: Dictionary, vi: int) -> void:
	_note_killer(ctx, step)
	for a in ctx["vehicles"][vi]["crew"]:
		_kill(ctx, a)
	ctx["death"] = true


static func _kill_one(ctx: Dictionary, step: Dictionary, a) -> void:
	_note_killer(ctx, step)
	_kill(ctx, a)


static func _note_killer(ctx: Dictionary, step: Dictionary) -> void:
	var hw = step["hardware"]
	if hw != null and not ctx["killers"].has(hw):
		ctx["killers"].append(hw)


static func _kill(ctx: Dictionary, a) -> void:
	if a == null or ctx["dead"].has(a.id):
		return
	ctx["dead"][a.id] = true
	ctx["crew_outcomes"][a.id] = "dead"
	ctx["deaths"] += 1


static func _injure(ctx: Dictionary, a) -> void:
	if a != null and not ctx["dead"].has(a.id):
		ctx["crew_outcomes"][a.id] = "injured"


static func _retire(ctx: Dictionary, a) -> void:
	if a != null and not ctx["dead"].has(a.id):
		ctx["crew_outcomes"][a.id] = "retired"


static func _destroy_pad(ctx: Dictionary, pad: int, cost: int) -> void:
	var p: SimPlayer = ctx["p"]
	if pad >= 0 and pad < p.pads.size():
		p.pads[pad] = cost
	ctx["pad_damage"] = cost


static func _lose_hardware(ctx: Dictionary, hw) -> void:
	if hw == null:
		return
	var label: String = hw.display_name()
	if not ctx["hardware_lost"].has(label):
		ctx["hardware_lost"].append(label)


## Codes 24/26: Safety -= rand(0..9), then VerifySafety keeps it at or above Base.
static func _cut_permanent_safety(ctx: Dictionary, hw) -> void:
	var state: SimState = ctx["state"]
	hw.safety = clampi(hw.safety - state.rng.below(10), hw.base_safety(), hw.max_safety())


# ---------------------------------------------------------------------------------------
# After the mission
# ---------------------------------------------------------------------------------------

static func _finish(ctx: Dictionary) -> Dictionary:
	var state: SimState = ctx["state"]
	var p: SimPlayer = ctx["p"]
	var mission: Dictionary = ctx["mission"]
	var steps: Array = ctx["steps"]
	var attempts: Array = ctx["attempts"]
	var manned: bool = ctx["total_manned"] > 0
	var deaths: int = ctx["deaths"]
	var max_info := 0
	for a in attempts:
		max_info = maxi(max_info, a["step_info"] if a["step_info"] != 0 else INFO_UNMANNED_FAIL)
	var catastrophic := max_info >= INFO_DEATH or deaths > 0

	# Goals: rows carried by evaluated steps, in first-evaluation order, then the
	# mission's categories that were never reached (prest.cpp AllotPrest).
	var goal_rows: Array = []
	var goal_ok: Dictionary = {}
	var seen: Dictionary = {}
	for a in attempts:
		var s: Dictionary = steps[a["index"]]
		if seen.has(s["index"]) or s["row"] < 0:
			continue
		seen[s["index"]] = true
		var row: int = s["row"]
		var ok: bool = not s["invalidated"] and s["step_info"] < INFO_DEATH and s["step_info"] != 0
		if not goal_ok.has(row):
			goal_rows.append(row)
			goal_ok[row] = ok
		elif not ok:
			goal_ok[row] = false
	if manned:
		if mission.get("eva", 0) == 1 and not goal_ok.has(ROW_SPACEWALK):
			goal_rows.append(ROW_SPACEWALK)
			goal_ok[ROW_SPACEWALK] = false
		if mission.get("docking", 0) == 1 and not goal_ok.has(ROW_MANNED_DOCKING):
			goal_rows.append(ROW_MANNED_DOCKING)
			goal_ok[ROW_MANNED_DOCKING] = false
	for row in mission.get("prestige_categories", []):
		if not goal_ok.has(row):
			goal_rows.append(row)
			goal_ok[row] = false
	if deaths > 0:
		for row in goal_ok.keys():
			goal_ok[row] = false
	var top_goal := -1
	for row in MANNED_GOAL_ROWS:
		if goal_ok.get(row, false):
			top_goal = row
			break

	# Duration achieved (prest.cpp:790-840).
	var duration: int = ctx["duration"]
	if manned:
		duration = maxi(duration, 1)
	if manned and mission.get("dur", 0) == 0 and top_goal >= 0:
		match top_goal:
			ROW_MANNED_SPACE_MISSION:
				duration = 1
			ROW_MANNED_ORBITAL:
				duration = 1 if ctx["mission_index"] <= 6 else 2
			ROW_LUNAR_PASS:
				duration = 3
			ROW_LUNAR_ORBIT, ROW_LUNAR_LANDING:
				duration = 4
	if manned and deaths == 0 and top_goal >= 0:
		var mike := 14 - duration
		if mission.get("dur", 0) == 0:
			match top_goal:
				ROW_MANNED_ORBITAL:
					mike = 7 if ctx["mission_index"] <= 6 else 12
				ROW_LUNAR_PASS:
					mike = 11
				ROW_LUNAR_ORBIT, ROW_LUNAR_LANDING:
					mike = 10
				_:
					mike = 7
		if mike >= 8 and mike <= 12 and not goal_ok.has(mike):
			goal_rows.append(mike)
			goal_ok[mike] = true
		# Capsule firsts, one per manned launch with a capsule.
		for vc in ctx["vehicles"]:
			if vc["manned"] > 0 and vc["capsule"] != null:
				var row: int = ROW_FIRST_CAPSULE + vc["capsule"].slot
				if not goal_ok.has(row):
					goal_rows.append(row)
					goal_ok[row] = true
	var goals: Array = []
	for row in goal_rows:
		goals.append({"row": row, "success": goal_ok[row]})

	# Crew deaths punish the hardware at once (mis_m.cpp F_KillCrew), before the prestige
	# pass pays its docking and photo bonuses and MissionSetDown rewards successes.
	for hw in ctx["killers"]:
		SimHardware.punish_death(p, hw)
		for vc in ctx["vehicles"]:
			if vc["rocket"] == hw and vc["boosters"] != null and hw.safety == hw.base_safety():
				vc["boosters"].safety = vc["boosters"].base_safety()

	# LM points (prest.cpp Set_LM): 1 per passed LEM thrust test, doubled on 48-52.
	var lm_gained := 0
	for a in attempts:
		if a["loc"] == LOC_LEM_TEST and (a["step_info"] == INFO_SUCCESS or a["step_info"] == INFO_HARMLESS):
			lm_gained += 1
	if ctx["mission_index"] >= LM_TEST_DOUBLE_FIRST and ctx["mission_index"] <= LM_TEST_DOUBLE_LAST and max_info < INFO_DEATH:
		lm_gained *= 2
	p.lm_points += lm_gained

	# Docking module (prest.cpp Check_Dock on the first docking step by index).
	var docking := "none"
	var dm_consts: Dictionary = state.constants().get("docking_module", {})
	for s in steps:
		if s["loc"] != LOC_DOCKING:
			continue
		if s["step_info"] == 0:
			break
		var limit := DOCKING_LIMIT_MANNED if manned else DOCKING_LIMIT_UNMANNED
		docking = "success" if s["step_info"] <= limit else "failure"
		break
	if docking != "none":
		var dm = p.program("misc", 4)
		if dm != null and dm.owned:
			var inc: int = dm_consts.get("success_increment", 10) if docking == "success" else dm_consts.get("failure_increment", 5)
			dm.safety = mini(dm.safety + inc, dm.max_safety())

	# Photo recon (prest.cpp:709-715, :1060-1075).
	var photo_success := false
	var photo = p.program("misc", 5)
	var photo_consts: Dictionary = state.constants().get("photo_recon", {})
	var photo_cap: int = photo_consts.get("cap", 99)
	if manned:
		photo_success = goal_ok.get(ROW_LUNAR_PASS, false)
		if photo_success and photo != null and photo.owned:
			photo.safety = mini(photo.safety + photo_consts.get("manned_lunar_pass_or_orbit_success", 5), photo_cap)
	else:
		photo_success = _check_photo(steps)
		var mi: int = ctx["mission_index"]
		if photo_success and photo != null and photo.owned and (mi == MISSION_LUNAR_FLYBY or mi == MISSION_LUNAR_PROBE):
			photo.safety = mini(photo.safety + photo_consts.get("unmanned_lunar_flyby_or_probe_photo_step_success", 5), photo_cap)
			if mi == MISSION_LUNAR_PROBE and max_info == INFO_SUCCESS:
				photo.safety = mini(photo.safety + photo_consts.get("lunar_probe_safe_landing_extra", 10), photo_cap)

	# Hardware bookkeeping (mc2.cpp MissionSetDown).
	for prog in ctx["programs"]:
		var succ: int = ctx["succ"][prog]
		var failed: int = ctx["fail"][prog]
		if succ > 0:
			SimHardware.reward_success(prog)
			prog.failures += failed
		elif failed > 0:
			prog.flights += 1
			prog.failures += 1
	for vc in ctx["vehicles"]:
		var rocket = vc["rocket"]
		var boosters = vc["boosters"]
		if rocket == null or boosters == null or not ctx["programs"].has(boosters):
			continue
		if ctx["succ"][rocket] > 0 and ctx["succ"][boosters] == 0 and ctx["fail"][boosters] == 0:
			SimHardware.reward_success(boosters)
			boosters.failures += ctx["fail"][rocket]
		elif ctx["fail"][rocket] > 0 and ctx["succ"][boosters] == 0 and ctx["fail"][boosters] == 0:
			boosters.flights += 1
			boosters.failures += 1

	var outcome := "success"
	if ctx["scrubbed"]:
		outcome = "scrubbed"
	elif max_info >= INFO_MISSION_END:
		outcome = "failure"
	else:
		# An abort that brought the crew home still fails the mission's goals.
		for g in goals:
			if not g["success"]:
				outcome = "failure"
				break
	return {
		"player": ctx["pidx"], "mission_index": ctx["mission_index"], "manned": manned,
		"goals": goals, "deaths": deaths, "catastrophic": catastrophic, "outcome": outcome,
		"steps": attempts, "crew_outcomes": ctx["crew_outcomes"],
		"hardware_lost": ctx["hardware_lost"], "pad_damage": ctx["pad_damage"],
		"lm_points_gained": lm_gained, "docking": docking, "photo_success": photo_success,
		"duration_achieved": duration, "aborted_at": ctx["aborted_at"], "max_step_info": max_info,
	}


## Check_Photo: a passed photo step, or a passed planetary step at index 4; a failed
## photo step vetoes.
static func _check_photo(steps: Array) -> bool:
	for s in steps:
		if s["loc"] == LOC_PHOTO and s["step_info"] == INFO_SUCCESS:
			return true
		if s["loc"] == LOC_PLANETARY and s["index"] == 4 and s["step_info"] == INFO_SUCCESS:
			return true
		if s["loc"] == LOC_PHOTO and s["step_info"] > INFO_SUCCESS:
			return false
	return false
