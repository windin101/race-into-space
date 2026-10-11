extends GdUnitTestSuite
## Mission code parsing and mission resolution (SimMission).

const MISSION_ORBITAL_SATELLITE := 1
const MISSION_MANNED_SUBORBITAL := 2
const MISSION_MANNED_ORBITAL := 4
const MISSION_MANNED_DOCKING := 14
const MISSION_ORBITAL_DURATION := 25
const MISSION_EO_LM_TEST := 38
const MISSION_LO_LM_TEST := 48
const MISSION_JT_LUNAR_LANDING_LOR := 56

var data: Node


func before() -> void:
	data = load("res://scripts/data/game_data.gd").new()
	add_child(data)
	data.load_all()


func after() -> void:
	data.queue_free()


func _new_state(seed_value := 1, options := {}) -> SimState:
	return SimState.new(data, seed_value, options)


func _buy(s: SimState, p: SimPlayer, group: String, slot: int, safety := 99) -> SimProgram:
	var prog := p.program(group, slot)
	p.cash = 1000
	assert_bool(SimHardware.buy_program(s, p, prog)).is_true()
	prog.safety = safety
	return prog


func _crew(n: int, skill := 2) -> Array:
	var out: Array = []
	for i in n:
		var a := SimAstronaut.new()
		a.id = i
		a.name = "NAUT%d" % i
		a.status = SimAstronaut.Status.ACTIVE
		for k in SimAstronaut.SKILLS:
			a.skills[k] = skill
		out.append(a)
	return out


func _vehicle(rocket: SimProgram, payload := {}, crew := [], boosters = null) -> Dictionary:
	var full := {"capsule": null, "lm": null, "kicker": null, "probe": null, "eva": null,
		"docking": null, "photo": null}
	for k in payload:
		full[k] = payload[k]
	return {"rocket": rocket, "boosters": boosters, "payload": full, "crew": crew}


func _launch(mission_index: int, vehicles: Array, extra := {}) -> Dictionary:
	var launch := {
		"mission_index": mission_index, "player": 0, "pad": 0, "vehicles": vehicles,
		"duration_level": 0, "requirement_penalty": 0, "rush_penalty": 0, "lm_penalty": 0,
	}
	for k in extra:
		launch[k] = extra[k]
	return launch


## Orbital satellite: Atlas + Explorer at the given safeties.
func _satellite_launch(s: SimState, rocket_safety := 99, probe_safety := 99) -> Dictionary:
	var p := s.player(0)
	var atlas := _buy(s, p, "rocket", 0, rocket_safety)
	var explorer := _buy(s, p, "probe", 0, probe_safety)
	return _launch(MISSION_ORBITAL_SATELLITE, [_vehicle(atlas, {"probe": explorer})])


## Fly a launch built by `build` (state -> launch) with successive seeds until `accept`
## (result -> bool) is satisfied. Returns {state, result, seed}; fails the test otherwise.
func _fly_until(build: Callable, accept: Callable, options := {}, max_seeds := 400) -> Dictionary:
	for seed_value in range(1, max_seeds + 1):
		var s := _new_state(seed_value, options)
		var launch: Dictionary = build.call(s)
		var result := SimMission.fly(s, launch)
		if accept.call(result):
			return {"state": s, "result": result, "seed": seed_value}
	assert_bool(false).override_failure_message("no seed up to %d satisfied the predicate" % max_seeds).is_true()
	return {}


func _goal(result: Dictionary, row: int) -> Variant:
	for g in result["goals"]:
		if g["row"] == row:
			return g["success"]
	return null


# -- parsing ---------------------------------------------------------------------------

func test_parse_simple_code() -> void:
	var steps := SimMission.parse_code("ABC!|")
	assert_int(steps.size()).is_equal(4)
	assert_str(steps[0]["letter"]).is_equal("A")
	assert_int(steps[0]["loc"]).is_equal(0)
	assert_int(steps[2]["loc"]).is_equal(2)
	assert_str(steps[3]["letter"]).is_equal("!")
	assert_int(steps[3]["loc"]).is_equal(SimMission.LOC_END)
	for st in steps:
		assert_int(st["vehicle"]).is_equal(0)
		assert_bool(st["past_bang"]).is_false()
		assert_bool(st["alt_marker"]).is_false()
		assert_int(st["repeat"]).is_equal(0)


func test_parse_joint_lunar_landing_code() -> void:
	var m: Dictionary = data.missions[MISSION_JT_LUNAR_LANDING_LOR]
	var steps := SimMission.parse_code(m["code"], true)
	assert_int(steps.size()).is_equal(30)
	# +1ABJCL (0-4), +2ABJOL (5-9), +1IRUSQPT (10-16), +2M (17), +1I (18), +2KNgDE (19-23),
	# ! (24), OLd (25-27), +2Hd (28-29)
	for i in range(0, 5):
		assert_int(steps[i]["vehicle"]).is_equal(0)
	for i in range(5, 10):
		assert_int(steps[i]["vehicle"]).is_equal(1)
	assert_str(steps[10]["letter"]).is_equal("I")
	assert_int(steps[10]["vehicle"]).is_equal(0)
	assert_int(steps[17]["vehicle"]).is_equal(1)
	assert_str(steps[21]["letter"]).is_equal("g")
	assert_int(steps[21]["loc"]).is_equal(29)      # lunar missions treat g as reentry corridor
	assert_str(steps[24]["letter"]).is_equal("!")
	assert_int(m["alt"][24]).is_equal(-3)
	assert_bool(steps[23]["past_bang"]).is_false()
	assert_bool(steps[25]["past_bang"]).is_true()
	assert_bool(steps[27]["alt_marker"]).is_true()
	assert_str(steps[28]["letter"]).is_equal("H")
	assert_int(steps[28]["vehicle"]).is_equal(1)
	assert_bool(steps[29]["alt_marker"]).is_true()


func test_parse_repeat_duration_and_lab_tokens() -> void:
	var saturn := SimMission.parse_code("ABZ~6eVW!|")
	assert_int(saturn.size()).is_equal(12)
	for i in range(3, 9):
		assert_str(saturn[i]["letter"]).is_equal("e")
		assert_int(saturn[i]["loc"]).is_equal(30)
		assert_int(saturn[i]["repeat"]).is_equal(i - 2)
	assert_str(saturn[9]["letter"]).is_equal("V")
	assert_int(saturn[10]["loc"]).is_equal(22)

	# '@x' consumes its second character (upstream "unused"), so mission 25 has 8 slots.
	var duration := SimMission.parse_code("ABF@FGDE!|")
	assert_int(duration.size()).is_equal(8)
	assert_int(duration.size()).is_equal(data.missions[MISSION_ORBITAL_DURATION]["alt"].count(-3) + 7)
	assert_str(duration[3]["letter"]).is_equal("b")
	assert_int(duration[3]["loc"]).is_equal(27)
	assert_str(duration[4]["letter"]).is_equal("G")

	var lab := SimMission.parse_code("+1ABF+2ABF+1I%F+1GDE!|")
	assert_str(lab[7]["letter"]).is_equal("c")
	assert_int(lab[7]["loc"]).is_equal(28)
	assert_int(lab[7]["vehicle"]).is_equal(0)
	assert_int(lab[3]["vehicle"]).is_equal(1)

	var alt := SimMission.parse_code("A^B&C|")
	assert_int(alt[0]["vehicle"]).is_equal(0)
	assert_int(alt[1]["vehicle"]).is_equal(1)
	assert_int(alt[2]["vehicle"]).is_equal(0)
	assert_int(SimMission.parse_code("").size()).is_equal(0)


func test_step_names() -> void:
	assert_str(SimMission.step_name("A")).is_equal("LAUNCH")
	assert_str(SimMission.step_name("a")).is_equal("LEM THRUST TEST")
	assert_str(SimMission.step_name("S")).is_equal("LUNAR LANDING")


# -- unmanned --------------------------------------------------------------------------

func test_orbital_satellite_success_claims_row_0() -> void:
	var found := _fly_until(func(gs: SimState): return _satellite_launch(gs), func(res: Dictionary): return res["outcome"] == "success")
	var r: Dictionary = found["result"]
	var s: SimState = found["state"]
	assert_bool(r["manned"]).is_false()
	assert_int(r["steps"].size()).is_equal(3)
	assert_str(r["steps"][0]["letter"]).is_equal("A")
	assert_str(r["steps"][0]["hardware"]).is_equal("ATLAS")
	assert_str(r["steps"][1]["hardware"]).is_equal("EXPLORER")
	assert_str(r["steps"][2]["hardware"]).is_equal("EXPLORER")
	for st in r["steps"]:
		assert_bool(st["success"]).is_true()
		assert_int(st["step_info"]).is_equal(1)
		assert_int(st["safety"]).is_equal(99)
	assert_bool(_goal(r, 0)).is_true()
	assert_int(r["deaths"]).is_equal(0)
	assert_bool(r["catastrophic"]).is_false()
	assert_int(r["aborted_at"]).is_equal(-1)
	assert_array(r["hardware_lost"]).is_empty()
	var p := s.player(0)
	assert_int(p.program("rocket", 0).flights).is_equal(1)
	assert_int(p.program("rocket", 0).successes).is_equal(1)
	assert_int(p.program("probe", 0).successes).is_equal(1)
	# Prestige contract: the result scores as a first on row 0.
	var award := SimPrestige.award(s, r)
	assert_int(award["total"]).is_equal(data.prestige[0]["first"])


func test_rocket_failure_at_launch_fails_row_0() -> void:
	var found := _fly_until(func(gs: SimState): return _satellite_launch(gs, 1, 99), func(res: Dictionary): return res["outcome"] == "failure")
	var r: Dictionary = found["result"]
	var s: SimState = found["state"]
	assert_int(r["steps"].size()).is_equal(1)
	assert_str(r["steps"][0]["letter"]).is_equal("A")
	assert_bool(r["steps"][0]["success"]).is_false()
	assert_int(r["steps"][0]["step_info"]).is_equal(1003)
	assert_int(r["steps"][0]["roll"]).is_greater(1)
	assert_bool(r["steps"][0]["failure"] != null).is_true()
	assert_int(r["steps"][0]["failure"]["code"]).is_not_equal(-1)
	assert_str(r["steps"][0]["failure"]["key"]).is_equal("F000")
	assert_bool(_goal(r, 0)).is_false()
	assert_int(r["aborted_at"]).is_equal(0)
	assert_array(r["hardware_lost"]).contains(["ATLAS"])
	var atlas := s.player(0).program("rocket", 0)
	assert_int(atlas.flights).is_equal(1)
	assert_int(atlas.failures).is_equal(1)
	assert_int(atlas.successes).is_equal(0)
	assert_int(s.player(0).program("probe", 0).flights).is_equal(0)
	var award := SimPrestige.award(s, r)
	assert_int(award["total"]).is_equal(data.prestige[0]["failure"])


func test_unmanned_failure_ends_mission_at_that_step() -> void:
	var found := _fly_until(func(gs: SimState): return _satellite_launch(gs, 99, 1),
		func(res: Dictionary): return res["steps"].size() == 2)
	var r: Dictionary = found["result"]
	assert_bool(r["steps"][0]["success"]).is_true()
	assert_str(r["steps"][1]["letter"]).is_equal("B")
	assert_bool(r["steps"][1]["success"]).is_false()
	assert_int(r["steps"][1]["step_info"]).is_equal(1003)
	assert_str(r["outcome"]).is_equal("failure")
	assert_int(r["aborted_at"]).is_equal(1)
	assert_bool(_goal(r, 0)).is_false()
	# Unmanned failure types come from the -1..-5 rows.
	assert_int(r["steps"][1]["failure"]["code"]).is_not_equal(-1)


func test_pad_destroyed_on_code_12() -> void:
	var found := _fly_until(func(gs: SimState): return _satellite_launch(gs, 1, 99),
		func(res: Dictionary): return res["pad_damage"] > 0)
	var r: Dictionary = found["result"]
	var s: SimState = found["state"]
	assert_int(r["steps"][0]["failure"]["code"]).is_equal(12)
	assert_int(r["pad_damage"]).is_equal(20)
	assert_int(s.player(0).pads[0]).is_equal(20)
	assert_bool(s.player(0).pad_usable(0)).is_false()


# -- manned ----------------------------------------------------------------------------

func _manned_orbital_launch(s: SimState, rocket_safety := 99, capsule_safety := 99) -> Dictionary:
	var p := s.player(0)
	var atlas := _buy(s, p, "rocket", 0, rocket_safety)
	var mercury := _buy(s, p, "manned", 0, capsule_safety)
	return _launch(MISSION_MANNED_ORBITAL, [_vehicle(atlas, {"capsule": mercury}, _crew(1))],
		{"duration_level": 1})


func test_manned_orbital_success_rewards_each_program_once() -> void:
	var found := _fly_until(func(gs: SimState): return _manned_orbital_launch(gs),
		func(res: Dictionary): return res["outcome"] == "success" and res["steps"].size() == 6)
	var r: Dictionary = found["result"]
	var s: SimState = found["state"]
	var p := s.player(0)
	assert_bool(r["manned"]).is_true()
	assert_bool(_goal(r, 27)).is_true()
	assert_bool(_goal(r, 18)).is_true()
	assert_bool(_goal(r, 13)).is_true()          # one-person craft first, added per launch
	assert_that(_goal(r, 12)).is_null()          # no duration row for a plain orbital
	assert_int(r["duration_achieved"]).is_equal(1)
	assert_dict(r["crew_outcomes"]).is_equal({0: "ok"})
	# Crew skill 2 on the capsule steps, none on the launch.
	assert_int(r["steps"][0]["safety"]).is_equal(99)
	assert_int(r["steps"][2]["safety"]).is_equal(99)   # 99 + 2 capped
	var mercury := p.program("manned", 0)
	var atlas := p.program("rocket", 0)
	assert_int(mercury.flights).is_equal(1)              # four capsule steps, rewarded once
	assert_int(mercury.successes).is_equal(1)
	assert_int(mercury.safety).is_equal(mercury.max_safety())    # 99 + 1 capped at max
	assert_int(atlas.flights).is_equal(1)
	assert_int(atlas.safety).is_equal(atlas.max_safety())


func test_crew_death_is_reported_not_applied() -> void:
	var found := _fly_until(func(gs: SimState): return _manned_orbital_launch(gs, 1, 99),
		func(res: Dictionary): return res["deaths"] >= 1)
	var r: Dictionary = found["result"]
	var s: SimState = found["state"]
	assert_bool(r["catastrophic"]).is_true()
	assert_str(r["crew_outcomes"][0]).is_equal("dead")
	assert_str(r["outcome"]).is_equal("failure")
	assert_int(r["steps"][0]["step_info"]).is_greater_equal(3000)
	for g in r["goals"]:
		assert_bool(g["success"]).is_false()
	# The astronaut object itself is untouched; the turn loop applies the outcome.
	var crew: Array = found["result"]["crew_outcomes"].keys()
	assert_int(crew.size()).is_equal(1)
	# The launch vehicle that killed the crew is punished (easy: halved, floored at base).
	var atlas := s.player(0).program("rocket", 0)
	assert_int(atlas.safety).is_equal(atlas.base_safety())
	assert_int(atlas.max_rd).is_equal(atlas.max_rd_original)
	var award := SimPrestige.award(s, r)
	assert_int(award["total"]).is_equal(SimPrestige.FLOOR_WITH_DEATH)


func test_save_card_cancels_one_failure() -> void:
	var build := func(gs: SimState):
		gs.player(0).save_cards = 1
		return _satellite_launch(gs, 1, 99)
	var accept := func(res: Dictionary): return res["steps"][0]["roll"] > 1 and res["outcome"] == "success"
	var found := _fly_until(build, accept)
	var r: Dictionary = found["result"]
	var s: SimState = found["state"]
	assert_bool(r["steps"][0]["success"]).is_true()
	assert_bool(r["steps"][0]["save_card"]).is_true()
	assert_int(s.player(0).save_cards).is_equal(0)
	assert_int(r["steps"].size()).is_equal(3)
	assert_str(r["outcome"]).is_equal("success")


func test_penalties_lower_mission_safety() -> void:
	var s := _new_state(5)
	var p := s.player(0)
	var saturn := _buy(s, p, "rocket", 2, 80)
	var apollo := _buy(s, p, "manned", 2, 90)
	var eagle := _buy(s, p, "manned", 5, 85)
	var dm := _buy(s, p, "misc", 4, 60)
	var launch := _launch(MISSION_EO_LM_TEST,
		[_vehicle(saturn, {"capsule": apollo, "lm": eagle, "docking": dm}, _crew(3, 0))],
		{"duration_level": 1, "requirement_penalty": 6, "rush_penalty": 3, "lm_penalty": 9})
	var r := SimMission.fly(s, launch)
	assert_int(saturn.mission_safety).is_equal(80 - 9)
	assert_int(apollo.mission_safety).is_equal(90 - 9)
	assert_int(eagle.mission_safety).is_equal(85 - 18)
	assert_int(dm.mission_safety).is_equal(60 - 9)
	assert_int(r["steps"][0]["safety"]).is_equal(71)
	# Floor is 1, cap 99.
	var s2 := _new_state(5)
	var p2 := s2.player(0)
	var atlas := _buy(s2, p2, "rocket", 0, 5)
	var explorer := _buy(s2, p2, "probe", 0, 99)
	SimMission.fly(s2, _launch(MISSION_ORBITAL_SATELLITE, [_vehicle(atlas, {"probe": explorer})],
		{"requirement_penalty": 30}))
	assert_int(atlas.mission_safety).is_equal(1)
	assert_int(explorer.mission_safety).is_equal(69)


func _lm_test_launch(s: SimState, mission_index: int) -> Dictionary:
	var p := s.player(0)
	var saturn := _buy(s, p, "rocket", 2)
	var apollo := _buy(s, p, "manned", 2)
	var eagle := _buy(s, p, "manned", 5)
	var dm := _buy(s, p, "misc", 4, 93)
	_buy(s, p, "probe", 0)       # the docking module powers on against the best probe
	return _launch(mission_index, [_vehicle(saturn, {"capsule": apollo, "lm": eagle, "docking": dm}, _crew(3))],
		{"duration_level": 4})


func test_lm_points_accrue_on_lem_thrust_tests() -> void:
	var found := _fly_until(func(gs: SimState): return _lm_test_launch(gs, MISSION_EO_LM_TEST),
		func(res: Dictionary): return res["outcome"] == "success")
	var r: Dictionary = found["result"]
	var s: SimState = found["state"]
	assert_int(r["lm_points_gained"]).is_equal(1)
	assert_int(s.player(0).lm_points).is_equal(1)
	var lm_steps: Array = r["steps"].filter(func(st: Dictionary): return st["letter"] == "a")
	assert_int(lm_steps.size()).is_equal(1)
	assert_str(lm_steps[0]["hardware"]).is_equal("EAGLE")
	assert_int(s.player(0).program("manned", 5).successes).is_equal(1)
	# Lunar-orbital LM tests pay double.
	var lunar := _fly_until(func(gs2: SimState): return _lm_test_launch(gs2, MISSION_LO_LM_TEST),
		func(res2: Dictionary): return res2["outcome"] == "success")
	assert_int(lunar["result"]["lm_points_gained"]).is_equal(2)
	assert_int(lunar["state"].player(0).lm_points).is_equal(2)


func _docking_launch(s: SimState, dm_safety: int) -> Dictionary:
	var p := s.player(0)
	var titan := _buy(s, p, "rocket", 1)
	var gemini := _buy(s, p, "manned", 1)
	var dm := _buy(s, p, "misc", 4, dm_safety)
	_buy(s, p, "probe", 0)
	return _launch(MISSION_MANNED_DOCKING, [_vehicle(titan, {"capsule": gemini, "docking": dm}, _crew(2))],
		{"duration_level": 1})


func test_docking_success_raises_module_safety_capped() -> void:
	var found := _fly_until(func(gs: SimState): return _docking_launch(gs, 40), func(res: Dictionary): return res["docking"] == "success")
	var r: Dictionary = found["result"]
	var s: SimState = found["state"]
	var dm := s.player(0).program("misc", 4)
	assert_int(dm.safety).is_equal(50)
	assert_bool(_goal(r, 24)).is_true()
	var dock_steps: Array = r["steps"].filter(func(st: Dictionary): return st["letter"] == "I")
	assert_str(dock_steps[0]["hardware"]).is_equal("DOCKING")
	assert_int(dock_steps[0]["safety"]).is_equal(40 + 2)          # docking specialist skill
	assert_int(s.player(0).docking_module_in_orbit).is_equal(2)   # power-on succeeded
	# Capped at the module's max safety.
	var capped := _fly_until(func(gs2: SimState): return _docking_launch(gs2, 90), func(res2: Dictionary): return res2["docking"] == "success")
	var dm2: SimProgram = capped["state"].player(0).program("misc", 4)
	assert_int(dm2.safety).is_equal(dm2.max_safety())
	assert_int(dm2.max_safety()).is_equal(93)
	# A failed docking still pays +5 (from base 40, so a code-26 cut clamped to base is neutral).
	var failed := _fly_until(func(gs3: SimState): return _docking_launch(gs3, 40), func(res3: Dictionary): return res3["docking"] == "failure")
	assert_int(failed["state"].player(0).program("misc", 4).safety).is_equal(40 + 5)


func test_duration_steps_repeat_to_the_planned_level() -> void:
	var build := func(gs: SimState):
		var p := gs.player(0)
		var titan := _buy(gs, p, "rocket", 1)
		var gemini := _buy(gs, p, "manned", 1)
		return _launch(MISSION_ORBITAL_DURATION, [_vehicle(titan, {"capsule": gemini}, _crew(2))],
			{"duration_level": 3})
	var found := _fly_until(build, func(res: Dictionary): return res["outcome"] == "success")
	var r: Dictionary = found["result"]
	var duration_steps: Array = r["steps"].filter(func(st: Dictionary): return st["letter"] == "b")
	assert_int(duration_steps.size()).is_equal(2)      # level C = two passes
	assert_int(r["duration_achieved"]).is_equal(3)
	assert_bool(_goal(r, 11)).is_true()                 # duration C row
	assert_bool(_goal(r, 14)).is_true()                 # two-person craft


func test_same_seed_same_result() -> void:
	var results: Array = []
	for i in 2:
		var s := _new_state(77)
		var p := s.player(0)
		var atlas := _buy(s, p, "rocket", 0, 60)
		var mercury := _buy(s, p, "manned", 0, 70)
		var r := SimMission.fly(s, _launch(MISSION_MANNED_SUBORBITAL, [_vehicle(atlas, {"capsule": mercury}, _crew(1))],
			{"duration_level": 1}))
		results.append(r)
	assert_str(JSON.stringify(results[0]["steps"])).is_equal(JSON.stringify(results[1]["steps"]))
	assert_str(JSON.stringify(results[0]["goals"])).is_equal(JSON.stringify(results[1]["goals"]))
	assert_dict(results[0]["crew_outcomes"]).is_equal(results[1]["crew_outcomes"])
	assert_str(results[0]["outcome"]).is_equal(results[1]["outcome"])
	# A different seed produces a different roll sequence somewhere in 20 tries.
	var differs := false
	for seed_value in range(1, 21):
		var s := _new_state(seed_value)
		var p := s.player(0)
		var atlas := _buy(s, p, "rocket", 0, 60)
		var mercury := _buy(s, p, "manned", 0, 70)
		var r := SimMission.fly(s, _launch(MISSION_MANNED_SUBORBITAL, [_vehicle(atlas, {"capsule": mercury}, _crew(1))],
			{"duration_level": 1}))
		if JSON.stringify(r["steps"]) != JSON.stringify(results[0]["steps"]):
			differs = true
			break
	assert_bool(differs).is_true()


func test_boosters_combine_with_rocket() -> void:
	var s := _new_state(3)
	var p := s.player(0)
	var atlas := _buy(s, p, "rocket", 0, 80)
	var boosters := _buy(s, p, "rocket", 4, 50)
	var explorer := _buy(s, p, "probe", 0, 99)
	var r := SimMission.fly(s, _launch(MISSION_ORBITAL_SATELLITE, [_vehicle(atlas, {"probe": explorer}, [], boosters)]))
	assert_int(r["steps"][0]["safety"]).is_equal(40)      # 80 x 50 / 100
	var s2 := _new_state(3, {"classic_boosters": true})
	var p2 := s2.player(0)
	var atlas2 := _buy(s2, p2, "rocket", 0, 80)
	var boosters2 := _buy(s2, p2, "rocket", 4, 50)
	var explorer2 := _buy(s2, p2, "probe", 0, 99)
	var r2 := SimMission.fly(s2, _launch(MISSION_ORBITAL_SATELLITE, [_vehicle(atlas2, {"probe": explorer2}, [], boosters2)]))
	assert_int(r2["steps"][0]["safety"]).is_equal(65)     # (80 + 50) / 2


func test_easy_die_stays_within_1_to_100() -> void:
	var s := _new_state(9)
	var p := s.player(0)
	var atlas := _buy(s, p, "rocket", 0, 50)
	var explorer := _buy(s, p, "probe", 0, 50)
	var launch := _launch(MISSION_ORBITAL_SATELLITE, [_vehicle(atlas, {"probe": explorer})])
	var seen_high := false
	for i in 60:
		var r := SimMission.fly(s, launch)
		for st in r["steps"]:
			assert_int(st["roll"]).is_between(1, 100)
			if st["roll"] >= 66:
				seen_high = true
		atlas.safety = 50
		explorer.safety = 50
	assert_bool(seen_high).is_true()


func test_joint_lunar_landing_flies_both_vehicles() -> void:
	var build := func(gs: SimState):
		var p := gs.player(0)
		var saturn := _buy(gs, p, "rocket", 2)
		var apollo := _buy(gs, p, "manned", 2)
		var eagle := _buy(gs, p, "manned", 5)
		var dm := _buy(gs, p, "misc", 4, 93)
		var eva := _buy(gs, p, "misc", 3)
		_buy(gs, p, "probe", 0)
		return _launch(MISSION_JT_LUNAR_LANDING_LOR, [
			_vehicle(saturn, {"lm": eagle, "docking": dm}),
			_vehicle(saturn, {"capsule": apollo, "eva": eva}, _crew(3)),
		], {"duration_level": 4})
	var found := _fly_until(build, func(res: Dictionary): return res["outcome"] == "success")
	var r: Dictionary = found["result"]
	var s: SimState = found["state"]
	assert_bool(r["manned"]).is_true()
	assert_int(r["steps"].size()).is_equal(24)          # every main-path step, none repeated
	assert_bool(_goal(r, 22)).is_true()                  # lunar landing
	assert_bool(_goal(r, 20)).is_true()
	assert_bool(_goal(r, 19)).is_true()
	assert_bool(_goal(r, 26)).is_true()                  # lunar EVA
	assert_bool(_goal(r, 24)).is_true()                  # docking
	assert_bool(_goal(r, 15)).is_true()                  # three-person craft
	assert_str(r["docking"]).is_equal("success")
	assert_bool(r["photo_success"]).is_true()
	assert_int(r["duration_achieved"]).is_equal(4)
	assert_int(r["lm_points_gained"]).is_equal(0)
	var by_letter := {}
	for st in r["steps"]:
		by_letter[st["letter"]] = st
	assert_str(by_letter["S"]["hardware"]).is_equal("EAGLE")
	assert_str(by_letter["P"]["hardware"]).is_equal("EVA SUITS")
	assert_str(by_letter["T"]["hardware"]).is_equal("EAGLE")
	assert_str(by_letter["K"]["hardware"]).is_equal("APOLLO")
	assert_int(by_letter["L"]["vehicle"]).is_equal(1)
	assert_int(s.player(0).program("manned", 5).successes).is_equal(1)
	assert_int(s.player(0).program("misc", 5).safety).is_equal(55 + 5)   # manned lunar pass bonus
