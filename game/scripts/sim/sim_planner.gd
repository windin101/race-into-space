class_name SimPlanner
extends RefCounted
## Future Missions planning, requirement penalties, VAB assembly, downgrades and rush.
## Rules: docs/specs/code-derived-rules.md sections 2, 3, 11; upstream future.cpp
## (FutureMissionOk, JointMissionOK), mission_util.cpp (MissionTimingOk), vab.cpp.
##
## A plan (stored in SimPlayer.future[pad]) is:
##   {mission_index, pad, duration, joint, part (1 primary / 2 second pad), rush_months,
##    crew_choice: [crew_index per vehicle]}

const RESCUE_FIRST := 58
const MISSION_NONE := 0
const RUSH_COST_PER_MONTH := 3
const RUSH_PENALTY_PER_MONTH := 3
const RUSH_MAX_MONTHS := 2
const MILESTONE_SKIP_PENALTY := 3
const DURATION_PENALTY_PER_LEVEL := 5
const LM_POINTS_REQUIRED := 3
const LM_PENALTY_PER_POINT := 3
const LUNAR_LANDING_FIRST := 53
## "(ORBIT)" docking missions that use a docking module already in orbit.
const ORBIT_DM_MISSIONS := [17, 24, 28, 29]
## Planet flyby mission indices.
const PLANET_MISSIONS := {10: "mars", 12: "jupiter", 13: "saturn"}

## Steps that are flown by a capsule (spec section 7).
const CAPSULE_LETTERS := "DEFGKMNOXYfg"
const LM_LETTERS := "QRSTa"
const PROBE_LETTERS := "VWZeU"

## Readiness thresholds (project rule; upstream thresholds are undocumented).
const READY_AOK := 75
const READY_CAUTION := 50


static func mission_def(state: SimState, index: int) -> Dictionary:
	return state.data.missions[index]


## Next season's date, which is when a plan made now will fly.
static func launch_date(state: SimState) -> Array:
	if state.season == SimState.SEASON_SPRING:
		return [state.year, SimState.SEASON_FALL]
	return [state.year + 1, SimState.SEASON_SPRING]


## Can the mission be planned on this pad for next season? Returns {ok, reason}.
static func can_plan(state: SimState, p: SimPlayer, mission_index: int, pad: int, duration: int = 0) -> Dictionary:
	if mission_index <= MISSION_NONE or mission_index >= RESCUE_FIRST or mission_index >= state.data.missions.size():
		return {"ok": false, "reason": "not a plannable mission"}
	if pad < 0 or pad > 2 or not p.pad_usable(pad):
		return {"ok": false, "reason": "pad not operational"}
	if p.future[pad] != null and p.future[pad].get("part", 1) == 2:
		return {"ok": false, "reason": "pad reserved for a joint mission"}
	var m := mission_def(state, mission_index)
	if m["dur"] == 1 and duration < m["days"]:
		return {"ok": false, "reason": "duration below the mission minimum"}
	if m["joint"] == 1:
		if pad >= 2 or not p.pad_usable(pad + 1):
			return {"ok": false, "reason": "joint mission needs the next pad operational"}
		var nxt = p.future[pad + 1]
		if nxt != null and nxt.get("part", 1) != 2:
			return {"ok": false, "reason": "next pad already has a mission"}
	if PLANET_MISSIONS.has(mission_index):
		var when := launch_date(state)
		if not SimCalendar.window_open(PLANET_MISSIONS[mission_index], when[0], when[1]):
			return {"ok": false, "reason": "launch window closed"}
	return {"ok": true, "reason": ""}


static func plan(state: SimState, p: SimPlayer, mission_index: int, pad: int, duration: int = 0) -> bool:
	var check := can_plan(state, p, mission_index, pad, duration)
	if not check["ok"]:
		return false
	var m := mission_def(state, mission_index)
	var dur: int = duration if m["dur"] == 1 else m["days"]
	cancel_plan(p, pad)
	p.future[pad] = {
		"mission_index": mission_index, "pad": pad, "duration": dur, "joint": m["joint"] == 1,
		"part": 1, "rush_months": 0, "crew_choice": [0, 0],
	}
	if m["joint"] == 1:
		p.future[pad + 1] = {"mission_index": mission_index, "pad": pad + 1, "part": 2, "primary_pad": pad}
	return true


static func cancel_plan(p: SimPlayer, pad: int) -> void:
	var cur = p.future[pad]
	if cur == null:
		return
	if cur.get("part", 1) == 2:
		pad = cur["primary_pad"]
		cur = p.future[pad]
	p.future[pad] = null
	if cur != null and cur.get("joint", false) and pad + 1 < 3:
		var nxt = p.future[pad + 1]
		if nxt != null and nxt.get("part", 1) == 2:
			p.future[pad + 1] = null


## Milestone, duration and new-mission penalties for flying this mission now.
static func requirement_penalty(state: SimState, p: SimPlayer, mission_index: int, duration: int = -1) -> Dictionary:
	var m := mission_def(state, mission_index)
	var highest := -1
	for row in m["prestige_categories"]:
		if SimPrestige.ROW_TO_MILESTONE.has(row):
			highest = maxi(highest, SimPrestige.ROW_TO_MILESTONE[row])
	var skipped := 0
	for ms in range(0, maxi(highest, 0)):
		if p.milestones[ms] == 0:
			skipped += 1
	var milestone_pen := skipped * MILESTONE_SKIP_PENALTY

	var required: int = maxi(0, int(m["days"]) - 1)
	if m["lunar"] == 1:
		var has_lunar_orbit: bool = "L" in m["code"]
		required = maxi(required, 4 if has_lunar_orbit else 3)
	if duration >= 0:
		required = maxi(required, duration - 1)
	var short := maxi(0, required - p.duration_level)
	var duration_pen := short * DURATION_PENALTY_PER_LEVEL

	var new_mission_pen := 0
	if highest >= 0 and p.milestones[highest] == 0 and skipped > 0:
		new_mission_pen = 1 + p.level
	elif highest >= 0 and skipped > 0:
		new_mission_pen = 1 + p.level

	var lm_pen := 0
	if mission_index >= LUNAR_LANDING_FIRST and m["lm"] == 1:
		lm_pen = maxi(0, LM_POINTS_REQUIRED - p.lm_points) * LM_PENALTY_PER_POINT

	var total := maxi(0, milestone_pen + duration_pen + new_mission_pen)
	return {"milestone": milestone_pen, "duration": duration_pen, "new_mission": new_mission_pen,
			"total": total, "lm": lm_pen, "skipped_milestones": skipped}


static func set_rush(p: SimPlayer, pad: int, months: int) -> bool:
	var pl = p.future[pad]
	if pl == null or pl.get("part", 1) == 2 or months < 0 or months > RUSH_MAX_MONTHS:
		return false
	var delta: int = (months - int(pl["rush_months"])) * RUSH_COST_PER_MONTH
	if delta > 0 and not p.spend(delta):
		return false
	if delta < 0:
		p.cash -= delta   # refund
	pl["rush_months"] = months
	return true


## Letters flown by each vehicle of the mission, ignoring tokens.
static func vehicle_letters(code: String) -> Array:
	var out := ["", ""]
	var vehicle := 0
	var i := 0
	while i < code.length():
		var ch := code[i]
		if ch == "+" and i + 1 < code.length():
			vehicle = 0 if code[i + 1] == "1" else 1
			i += 2
			continue
		if ch in "@%~":
			if ch == "~":
				i += 2
			else:
				i += 2
			continue
		if ch in "^&!|d":
			i += 1
			continue
		if ch == "I":
			pass
		out[vehicle] += ch
		i += 1
	return out


static func _owned_with_units(p: SimPlayer, group: String, slots: Array) -> Array:
	var out: Array = []
	for s in slots:
		var prog: SimProgram = p.program(group, s)
		if prog != null and prog.owned and prog.units > 0:
			out.append(prog)
	return out


static func _lift(rocket: SimProgram, boosters: SimProgram) -> int:
	var lift: int = rocket.spec["max_payload"]
	if boosters != null:
		lift += boosters.spec["max_payload"]
	return lift


static func _weight(payload: Dictionary) -> int:
	var w := 0
	for k in payload:
		var prog: SimProgram = payload[k]
		if prog != null:
			w += int(prog.spec["unit_weight"])
	return w


## Crew for a program and crew index, in seat order, from astronaut assignments.
static func crew_of(p: SimPlayer, slot: int, crew_index: int) -> Array:
	var members: Array = []
	for a in p.astronauts:
		if a.program_group == "manned" and a.program_slot == slot and a.crew_index == crew_index:
			members.append(a)
	members.sort_custom(func(x, y): return x.crew_position < y.crew_position)
	return members


## Pick the capsule allowed by the mission's minimum-equipment class.
static func _capsule_candidates(p: SimPlayer, m_eq: int) -> Array:
	match m_eq:
		0: return []
		1: return _owned_with_units(p, "manned", [0, 1, 2, 3, 4])
		2: return _owned_with_units(p, "manned", [1, 2, 3, 4])
		3: return _owned_with_units(p, "manned", [2, 4])
		5: return _owned_with_units(p, "manned", [4])
	return _owned_with_units(p, "manned", [1, 2, 3, 4])


## Build the launch for a plan from owned hardware, or return {} with a reason when the
## hardware is not there. Does not consume units; see commit_launch.
static func assemble(state: SimState, p: SimPlayer, pl: Dictionary) -> Dictionary:
	var mi: int = pl["mission_index"]
	var m := mission_def(state, mi)
	var letters := vehicle_letters(m["code"])
	var n_vehicles: int = 2 if m["joint"] == 1 else 1
	var manned_modes := {2: [true], 3: [false, true], 4: [true, true], 5: [false, false], 1: [false], 0: [false]}
	var manned_by_vehicle: Array = manned_modes.get(int(m["crew_mode"]), [false, false])
	var capsule_needed_by_vehicle: Array = []
	for v in n_vehicles:
		var needs := false
		for ch in letters[v]:
			if ch in CAPSULE_LETTERS:
				needs = true
		capsule_needed_by_vehicle.append(needs and m["m_eq"] > 0)
	# Unmanned capsule missions (crew_mode 1/5) still need the capsule on the vehicle.
	if int(m["crew_mode"]) in [1, 5] and n_vehicles == 1:
		capsule_needed_by_vehicle[0] = true

	var vehicles: Array = []
	var used: Dictionary = {}
	for v in n_vehicles:
		var payload := {"capsule": null, "lm": null, "kicker": null, "probe": null, "eva": null, "docking": null, "photo": null}
		var vl: String = letters[v]
		if capsule_needed_by_vehicle[v]:
			var caps := _capsule_candidates(p, m["m_eq"])
			if caps.is_empty():
				return {"reason": "no suitable capsule"}
			payload["capsule"] = caps[0]
		if m["lm"] == 1:
			var lm_here := false
			for ch in vl:
				if ch in LM_LETTERS:
					lm_here = true
			if lm_here and not used.has("lm"):
				var lms := _owned_with_units(p, "manned", [5, 6])
				if lms.is_empty():
					return {"reason": "no lunar module"}
				payload["lm"] = lms[0]
				used["lm"] = true
		if m["docking"] == 1 and not used.has("docking"):
			var dm_here := ("I" in vl) if n_vehicles == 1 else (("C" in vl) and payload["capsule"] == null)
			if n_vehicles == 2 and not dm_here and v == 1 and not used.has("docking") and not (("C" in letters[0]) and capsule_needed_by_vehicle[0] == false):
				dm_here = true
			if dm_here:
				if mi in ORBIT_DM_MISSIONS:
					if p.docking_module_in_orbit <= 0:
						return {"reason": "no docking module in orbit"}
				else:
					var dms := _owned_with_units(p, "misc", [4])
					if dms.is_empty():
						return {"reason": "no docking module"}
					payload["docking"] = dms[0]
				used["docking"] = true
		if m["eva"] == 1 and payload["capsule"] != null:
			var suits: SimProgram = p.program("misc", 3)
			if suits == null or not suits.owned:
				return {"reason": "no EVA suits"}
			payload["eva"] = suits
		var probe_here := false
		for ch in vl:
			if ch in PROBE_LETTERS or (ch == "C" and m["m_eq"] == 0 and n_vehicles == 1):
				probe_here = true
		if m["m_eq"] == 0 and probe_here and payload["capsule"] == null and payload["lm"] == null:
			var probe_slots: Array
			if mi == 1:
				probe_slots = [0]
			elif mi == 8:
				probe_slots = [2]
			elif mi == 42 or mi == 45:
				probe_slots = [1, 2]
			else:
				probe_slots = [1]
			var probes := _owned_with_units(p, "probe", probe_slots)
			if probes.is_empty():
				return {"reason": "no suitable probe"}
			payload["probe"] = probes[0]
		if m["lunar"] == 1 and payload["capsule"] != null and ("J" in vl):
			# A kicker carries a capsule beyond Earth orbit unless the capsule is a four-man ship.
			if payload["capsule"].slot != 4:
				var kickers := _owned_with_units(p, "misc", [0, 1, 2])
				if not kickers.is_empty():
					payload["kicker"] = kickers[kickers.size() - 1]
		if "U" in vl:
			payload["photo"] = p.program("misc", 5)

		# Rocket: cheapest owned rocket that lifts the payload, adding boosters if needed.
		var weight := _weight(payload)
		var rockets := _owned_with_units(p, "rocket", [0, 1, 2, 3])
		var boosters_prog: SimProgram = null
		var bl := _owned_with_units(p, "rocket", [4])
		if not bl.is_empty():
			boosters_prog = bl[0]
		var chosen: SimProgram = null
		var chosen_boosters: SimProgram = null
		for r in rockets:
			if _lift(r, null) >= weight:
				chosen = r
				break
		if chosen == null and boosters_prog != null:
			for r in rockets:
				if _lift(r, boosters_prog) >= weight:
					chosen = r
					chosen_boosters = boosters_prog
					break
		if chosen == null:
			return {"reason": "no rocket can lift the payload"}
		var crew: Array = []
		if manned_by_vehicle[v] and payload["capsule"] != null:
			var choice: Array = pl.get("crew_choice", [0, 0])
			crew = crew_of(p, payload["capsule"].slot, choice[v])
			if crew.is_empty() or crew.size() != payload["capsule"].crew_capacity():
				return {"reason": "no full crew for the capsule"}
			for a in crew:
				if not a.is_available():
					return {"reason": "crew member unavailable"}
		vehicles.append({"rocket": chosen, "boosters": chosen_boosters, "payload": payload, "crew": crew})

	var pen := requirement_penalty(state, p, mi, pl.get("duration", -1))
	return {
		"mission_index": mi, "player": p.index, "pad": pl["pad"], "vehicles": vehicles,
		"duration_level": pl.get("duration", m["days"]),
		"requirement_penalty": pen["total"],
		"rush_penalty": int(pl.get("rush_months", 0)) * RUSH_PENALTY_PER_MONTH,
		"lm_penalty": pen["lm"],
	}


## Try the plan, then its downgrades in order. Returns the launch (with "downgraded_from"
## set when a fallback was used) or {} with "reason" when nothing can fly.
static func assemble_with_downgrades(state: SimState, p: SimPlayer, pl: Dictionary) -> Dictionary:
	var first := assemble(state, p, pl)
	if first.has("vehicles"):
		return first
	var original: int = pl["mission_index"]
	for alt in mission_def(state, original)["downgrades"]:
		if alt == MISSION_NONE:
			break
		var alt_plan := pl.duplicate()
		alt_plan["mission_index"] = alt
		var m := mission_def(state, alt)
		if m["joint"] == 1 and not pl.get("joint", false):
			continue
		var launch := assemble(state, p, alt_plan)
		if launch.has("vehicles"):
			launch["downgraded_from"] = original
			return launch
	return {"reason": first["reason"]}


## Consume one unit of every program on the launch.
static func commit_launch(launch: Dictionary) -> void:
	for v in launch["vehicles"]:
		v["rocket"].units -= 1
		if v["boosters"] != null:
			v["boosters"].units -= 1
		for k in v["payload"]:
			var prog: SimProgram = v["payload"][k]
			if prog != null and not (prog.is_eva_suit() or prog.is_photo_recon()):
				prog.units -= 1


## Lowest effective safety across the hardware on the launch, and its readiness band.
static func readiness(launch: Dictionary) -> Dictionary:
	var lowest := 100
	var pen: int = launch["requirement_penalty"] + launch["rush_penalty"]
	for v in launch["vehicles"]:
		var items: Array = [v["rocket"], v["boosters"]]
		for k in v["payload"]:
			items.append(v["payload"][k])
		for prog in items:
			if prog == null:
				continue
			var s: int = prog.safety - pen
			if prog.is_lm():
				s -= launch["lm_penalty"]
			lowest = mini(lowest, s)
	var band := "danger"
	if lowest >= READY_AOK:
		band = "a-ok"
	elif lowest >= READY_CAUTION:
		band = "caution"
	return {"lowest_safety": lowest, "band": band}
