extends GdUnitTestSuite
## Future Missions planning, penalties, assembly and downgrades.

var data: Node


func before() -> void:
	data = load("res://scripts/data/game_data.gd").new()
	add_child(data)
	data.load_all()


func after() -> void:
	data.queue_free()


func _state() -> SimState:
	return SimState.new(data, 5)


func _buy(s: SimState, p: SimPlayer, group: String, slot: int, safety := 80, units := 2) -> SimProgram:
	p.cash = 5000
	var prog := p.program(group, slot)
	SimHardware.buy_program(s, p, prog)
	prog.safety = safety
	prog.units = units
	return prog


func _crew(p: SimPlayer, slot: int, n: int, crew_index := 0) -> void:
	for i in n:
		var a := SimAstronaut.new()
		a.id = p.astronauts.size()
		a.name = "A%d" % a.id
		a.status = SimAstronaut.Status.ACTIVE
		a.program_group = "manned"
		a.program_slot = slot
		a.crew_index = crew_index
		a.crew_position = i
		a.skills = {"capsule": 2, "lm": 1, "eva": 1, "docking": 1, "endurance": 1}
		p.astronauts.append(a)


func test_plan_rejects_rescue_bad_pad_and_duration() -> void:
	var s := _state()
	var p := s.player(0)
	assert_bool(SimPlanner.can_plan(s, p, 58, 0)["ok"]).is_false()
	assert_bool(SimPlanner.can_plan(s, p, 1, 1)["ok"]).is_false()     # pad 1 not built
	assert_bool(SimPlanner.can_plan(s, p, 1, 0)["ok"]).is_true()
	# Mission 20-ish duration missions: pick one with dur flag.
	var dur_mission := -1
	for m in data.missions:
		if m["dur"] == 1 and m["joint"] == 0:
			dur_mission = m["index"]
			break
	assert_bool(SimPlanner.can_plan(s, p, dur_mission, 0, 0)["ok"]).is_false()
	assert_bool(SimPlanner.can_plan(s, p, dur_mission, 0, data.missions[dur_mission]["days"])["ok"]).is_true()


func test_joint_mission_reserves_next_pad() -> void:
	var s := _state()
	var p := s.player(0)
	assert_bool(SimPlanner.plan(s, p, 16, 0)).is_false()       # needs pad 1
	SimEconomy.buy_pad(p)
	assert_bool(SimPlanner.plan(s, p, 16, 0)).is_true()
	assert_int(p.future[1]["part"]).is_equal(2)
	assert_bool(SimPlanner.can_plan(s, p, 1, 1)["ok"]).is_false()
	SimPlanner.cancel_plan(p, 1)
	assert_object(p.future[0]).is_null()
	assert_object(p.future[1]).is_null()


func test_planet_window_checked_for_launch_season() -> void:
	var s := _state()
	var p := s.player(0)
	s.year = 59
	s.season = SimState.SEASON_FALL          # launches Spring 1960: Mars window open
	assert_bool(SimPlanner.can_plan(s, p, 10, 0)["ok"]).is_true()
	s.season = SimState.SEASON_SPRING        # launches Fall 1959: closed
	assert_bool(SimPlanner.can_plan(s, p, 10, 0)["ok"]).is_false()


func test_requirement_penalty_first_manned_orbital() -> void:
	var s := _state()
	var p := s.player(0)
	# Manned orbital (row 18 -> milestone 2) with no milestones: skips 0 and 1 = -6, plus
	# new-mission 1 on easy = 7, as the spec derives from the manual's example.
	var pen := SimPlanner.requirement_penalty(s, p, 4)
	assert_int(pen["milestone"]).is_equal(6)
	assert_int(pen["new_mission"]).is_equal(1)
	assert_int(pen["total"]).is_equal(7)
	p.level = 2
	assert_int(SimPlanner.requirement_penalty(s, p, 4)["total"]).is_equal(9)
	p.milestones = [1, 1, 1, 1, 1, 1, 1, 1]
	assert_int(SimPlanner.requirement_penalty(s, p, 4)["total"]).is_equal(0)


func test_duration_and_lm_penalties() -> void:
	var s := _state()
	var p := s.player(0)
	p.milestones = [1, 1, 1, 1, 1, 1, 1, 1]
	# Manned lunar orbital needs duration D (4): with nothing held, 4 levels short = 20.
	var pen := SimPlanner.requirement_penalty(s, p, 46)
	assert_int(pen["duration"]).is_equal(20)
	p.duration_level = 3
	assert_int(SimPlanner.requirement_penalty(s, p, 46)["duration"]).is_equal(5)
	p.duration_level = 4
	assert_int(SimPlanner.requirement_penalty(s, p, 46)["duration"]).is_equal(0)
	# Lunar landing with no LM points: 9 on the LM only.
	assert_int(SimPlanner.requirement_penalty(s, p, 56)["lm"]).is_equal(9)
	p.lm_points = 2
	assert_int(SimPlanner.requirement_penalty(s, p, 56)["lm"]).is_equal(3)


func test_assemble_orbital_satellite() -> void:
	var s := _state()
	var p := s.player(0)
	_buy(s, p, "rocket", 0)
	_buy(s, p, "probe", 0)
	SimPlanner.plan(s, p, 1, 0)
	var launch := SimPlanner.assemble(s, p, p.future[0])
	assert_bool(launch.has("vehicles")).override_failure_message(str(launch)).is_true()
	assert_int(launch["vehicles"].size()).is_equal(1)
	assert_str(launch["vehicles"][0]["rocket"].display_name()).is_equal("ATLAS")
	assert_str(launch["vehicles"][0]["payload"]["probe"].display_name()).is_equal("EXPLORER")
	assert_object(launch["vehicles"][0]["boosters"]).is_null()
	SimPlanner.commit_launch(launch)
	assert_int(p.program("rocket", 0).units).is_equal(1)
	assert_int(p.program("probe", 0).units).is_equal(1)


func test_assemble_needs_lift_and_uses_boosters() -> void:
	var s := _state()
	var p := s.player(0)
	_buy(s, p, "rocket", 0)                   # Atlas lifts 600
	_buy(s, p, "manned", 1)                   # Gemini weighs 1200
	_crew(p, 1, 2)
	SimPlanner.plan(s, p, 4, 0)
	var launch := SimPlanner.assemble(s, p, p.future[0])
	assert_str(launch.get("reason", "")).is_equal("no rocket can lift the payload")
	_buy(s, p, "rocket", 4)                   # Boosters add 1000
	launch = SimPlanner.assemble(s, p, p.future[0])
	assert_bool(launch.has("vehicles")).override_failure_message(str(launch)).is_true()
	assert_object(launch["vehicles"][0]["boosters"]).is_not_null()
	assert_int(launch["vehicles"][0]["crew"].size()).is_equal(2)


func test_assemble_requires_full_available_crew() -> void:
	var s := _state()
	var p := s.player(0)
	_buy(s, p, "rocket", 1)
	_buy(s, p, "manned", 0)
	SimPlanner.plan(s, p, 2, 0)              # manned suborbital, one-man capsule
	assert_str(SimPlanner.assemble(s, p, p.future[0]).get("reason", "")).is_equal("no full crew for the capsule")
	_crew(p, 0, 1)
	assert_bool(SimPlanner.assemble(s, p, p.future[0]).has("vehicles")).is_true()
	p.astronauts[0].status = SimAstronaut.Status.INJURED
	assert_str(SimPlanner.assemble(s, p, p.future[0]).get("reason", "")).is_equal("crew member unavailable")


func test_downgrade_when_hardware_missing() -> void:
	var s := _state()
	var p := s.player(0)
	_buy(s, p, "rocket", 1)
	_buy(s, p, "manned", 1)
	_crew(p, 1, 2)
	SimPlanner.plan(s, p, 6, 0)              # manned orbital EVA, but no EVA suits
	var launch := SimPlanner.assemble_with_downgrades(s, p, p.future[0])
	assert_bool(launch.has("vehicles")).override_failure_message(str(launch)).is_true()
	assert_int(launch["mission_index"]).is_equal(4)   # downgrades to manned earth orbital
	assert_int(launch["downgraded_from"]).is_equal(6)


func test_joint_lor_landing_assembles_two_vehicles() -> void:
	var s := _state()
	var p := s.player(0)
	SimEconomy.buy_pad(p)
	_buy(s, p, "rocket", 2)                   # Saturn
	_buy(s, p, "manned", 2)                   # Apollo
	_buy(s, p, "manned", 5)                   # Eagle
	_buy(s, p, "misc", 4)                     # Docking module
	_buy(s, p, "misc", 3)                     # EVA suits
	_crew(p, 2, 3)
	p.milestones = [1, 1, 1, 1, 1, 1, 1, 0]
	p.duration_level = 4
	p.lm_points = 3
	assert_bool(SimPlanner.plan(s, p, 56, 0)).is_true()
	var launch := SimPlanner.assemble(s, p, p.future[0])
	assert_bool(launch.has("vehicles")).override_failure_message(str(launch)).is_true()
	assert_int(launch["vehicles"].size()).is_equal(2)
	assert_object(launch["vehicles"][0]["payload"]["lm"]).is_not_null()
	assert_object(launch["vehicles"][1]["payload"]["capsule"]).is_not_null()
	assert_int(launch["vehicles"][1]["crew"].size()).is_equal(3)
	assert_int(launch["requirement_penalty"]).is_equal(0)
	assert_int(launch["lm_penalty"]).is_equal(0)


func test_rush_costs_and_refunds() -> void:
	var s := _state()
	var p := s.player(0)
	SimPlanner.plan(s, p, 1, 0)
	var cash := p.cash
	assert_bool(SimPlanner.set_rush(p, 0, 2)).is_true()
	assert_int(p.cash).is_equal(cash - 6)
	assert_bool(SimPlanner.set_rush(p, 0, 1)).is_true()
	assert_int(p.cash).is_equal(cash - 3)
	assert_bool(SimPlanner.set_rush(p, 0, 3)).is_false()


func test_readiness_bands() -> void:
	var s := _state()
	var p := s.player(0)
	_buy(s, p, "rocket", 0, 90)
	_buy(s, p, "probe", 0, 90)
	SimPlanner.plan(s, p, 1, 0)
	var launch := SimPlanner.assemble(s, p, p.future[0])
	assert_str(SimPlanner.readiness(launch)["band"]).is_equal("a-ok")
	p.program("probe", 0).safety = 60
	launch = SimPlanner.assemble(s, p, p.future[0])
	assert_str(SimPlanner.readiness(launch)["band"]).is_equal("caution")
	SimPlanner.set_rush(p, 0, 2)
	launch = SimPlanner.assemble(s, p, p.future[0])
	assert_int(SimPlanner.readiness(launch)["lowest_safety"]).is_equal(54)
