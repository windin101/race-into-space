class_name SimGame
extends RefCounted
## The turn loop. Owns a SimState and drives the modules in the manual's order:
## turn announcement, newscast, (player actions), launches, end of season, review.
##
## Players act between begin_turn() and end_turn() by calling the module APIs directly
## (SimHardware, SimPlanner, SimPersonnel, SimEconomy) on state.player(i).

const SCRUB_PRESTIGE := -3          ## manual: scrubbing a scheduled mission costs 3 prestige
const ROW_LUNAR_LANDING := 22
const DEFAULT_MONTHS := {1: [4], 2: [3, 5], 3: [2, 3, 4]}

var state: SimState
var turn_number := 0
var last_turn_report: Dictionary = {}


func _init(data, p_seed: int = 0, options: Dictionary = {}) -> void:
	state = SimState.new(data, p_seed, options)
	SimEvents.build_deck(state)
	begin_turn()


## Start of a season: hardware upkeep, personnel, newscast, review.
func begin_turn() -> void:
	turn_number += 1
	state.turn_log.clear()
	state.note("--- %s ---" % state.date_string())
	for p in state.players:
		SimHardware.start_of_season(p)
		SimPersonnel.start_of_season(state, p)
		SimEvents.newscast(state, p)
		if p.docking_module_in_orbit > 0:
			p.docking_module_in_orbit -= 1
	if SimCalendar.is_review_time(state):
		SimReview.annual_reviews(state)
		_check_dismissal()


## Resolve launches, roll the season over, advance the calendar.
func end_turn() -> Dictionary:
	if state.ended:
		return last_turn_report
	var report := {"date": state.date_string(), "launches": []}
	for launch in _ordered_launches():
		report["launches"].append(_fly(launch))
		if state.ended:
			break
	for p in state.players:
		for pad in 3:
			if p.missions[pad] != null and p.missions[pad].get("part", 1) == 1 and not p.missions[pad].get("flown", false):
				# Could not be assembled: scrubbed.
				p.add_prestige(SCRUB_PRESTIGE)
				report["launches"].append({"player": p.index, "pad": pad, "outcome": "scrubbed",
						"mission_index": p.missions[pad]["mission_index"], "reason": p.missions[pad].get("reason", "")})
		p.missions = p.future
		p.future = [null, null, null]
	SimEconomy.end_of_season(state)
	for p in state.players:
		SimPersonnel.end_of_season(state, p)
		p.turn_flags.erase("program_first")
	if not state.ended:
		if SimCalendar.is_last_turn(state):
			_end_without_landing()
		elif not SimCalendar.advance(state):
			_end_without_landing()
	report["ended"] = state.ended
	report["winner"] = state.winner
	last_turn_report = report
	if not state.ended:
		begin_turn()
	return report


## Scrub a mission scheduled for this season: hardware stays in inventory, the manual's
## 3-point prestige penalty applies.
func scrub(p: SimPlayer, pad: int) -> bool:
	if p.missions[pad] == null:
		return false
	SimEvents.scrub_scheduled(p, pad)
	p.add_prestige(SCRUB_PRESTIGE)
	state.note("%s scrubs the mission on pad %d" % [p.side, pad + 1])
	return true


## All launches this season in launch-month order, assembled with downgrades.
func _ordered_launches() -> Array:
	var launches: Array = []
	for p in state.players:
		var pads: Array = []
		for pad in 3:
			if p.missions[pad] != null and p.missions[pad].get("part", 1) == 1:
				pads.append(pad)
		var months: Array = DEFAULT_MONTHS.get(pads.size(), [4])
		for i in pads.size():
			var pl: Dictionary = p.missions[pads[i]]
			if not p.pad_usable(pads[i]):
				pl["reason"] = "pad damaged"
				continue
			var launch := SimPlanner.assemble_with_downgrades(state, p, pl)
			if not launch.has("vehicles"):
				pl["reason"] = launch.get("reason", "")
				continue
			launch["month"] = maxi(0, int(months[i]) - int(pl.get("rush_months", 0)))
			launch["plan"] = pl
			launches.append(launch)
	# Same-month launches alternate priority by season so neither side always wins ties.
	var first_player := state.turn_index() % 2
	launches.sort_custom(func(a, b):
		if a["month"] != b["month"]:
			return a["month"] < b["month"]
		return (a["player"] == first_player) and (b["player"] != first_player))
	return launches


func _fly(launch: Dictionary) -> Dictionary:
	var p := state.player(launch["player"])
	var pl: Dictionary = launch["plan"]
	pl["flown"] = true
	SimPlanner.commit_launch(launch)
	var restores := _apply_damage_penalties(launch)
	var result: Dictionary = SimMission.fly(state, launch)
	for r in restores:
		r[0].safety = r[1]
	result["year"] = state.year
	result["season"] = state.season
	result["pad"] = launch["pad"]
	if launch.has("downgraded_from"):
		result["downgraded_from"] = launch["downgraded_from"]
	# Crew consequences.
	for v in launch["vehicles"]:
		for a in v["crew"]:
			var outcome: String = result.get("crew_outcomes", {}).get(a.id, "ok")
			var mapped := "success" if result["outcome"] == "success" else "failure"
			if outcome != "ok":
				mapped = outcome
			SimPersonnel.on_mission_outcome(state, p, a, mapped, launch["mission_index"])
	# Bookkeeping the mission module reports.
	p.lm_points += int(result.get("lm_points_gained", 0))
	if result.get("duration_achieved", 0) > p.duration_level:
		p.duration_level = int(result["duration_achieved"])
	if int(result.get("pad_damage", 0)) > 0:
		p.pads[launch["pad"]] = int(result["pad_damage"])
	var award := SimPrestige.award(state, result)
	result["prestige"] = award
	for aw in award["awards"]:
		if aw["kind"] == "first":
			p.turn_flags["program_first"] = true
			if aw["row"] == ROW_LUNAR_LANDING:
				state.ended = true
				state.winner = p.index
				state.end_reason = "lunar landing"
	# Heroes for the big firsts.
	for aw in award["awards"]:
		if aw["kind"] == "first" and aw["row"] in [27, 25, 18, 19, 22]:
			for v in launch["vehicles"]:
				for a in v["crew"]:
					SimPersonnel.make_hero(a)
	p.mission_log.append(result)
	state.note("%s flew %s: %s (%+d prestige)" % [p.side, state.data.missions[launch["mission_index"]]["name"], result["outcome"], award["total"]])
	return result


## Event-card damage lowers the affected hardware's safety for this one mission, then
## clears. Returns [program, original safety] pairs to restore after the flight.
func _apply_damage_penalties(launch: Dictionary) -> Array:
	var restores: Array = []
	for v in launch["vehicles"]:
		var items: Array = [v["rocket"], v["boosters"]]
		for k in v["payload"]:
			items.append(v["payload"][k])
		for prog in items:
			if prog != null and prog.damage != 0:
				restores.append([prog, prog.safety])
				prog.safety = maxi(1, prog.safety + prog.damage)
				prog.damage = 0
				prog.damage_cost = 0
	return restores


func _check_dismissal() -> void:
	for p in state.players:
		if SimReview.dismissed(state, p):
			state.ended = true
			# The dismissed director's race is over; the rival in the lead takes it.
			state.winner = state.leading_rival(p.index).index
			state.end_reason = "%s director dismissed" % p.side
			return


## Fall 1977 with no landing: nobody wins (upstream "failed objective" ending).
func _end_without_landing() -> void:
	state.ended = true
	state.end_reason = "time expired"
	state.winner = -1
