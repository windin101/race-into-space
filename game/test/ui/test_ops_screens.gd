extends GdUnitTestSuite
## Derived view logic for the operations screens (OpsView): launch month naming, R&D
## expected gain, seat roles, downgrade options and the VAB auto-purchase shopping list.

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


func _plan(mi: int, pad := 0) -> Dictionary:
	var m: Dictionary = data.missions[mi]
	return {"mission_index": mi, "pad": pad, "duration": int(m["days"]), "joint": m["joint"] == 1,
			"part": 1, "rush_months": 0, "crew_choice": [0, 0]}


func test_launch_month_follows_default_months_and_rush() -> void:
	assert_int(OpsView.launch_month(1, 0, 0)).is_equal(SimGame.DEFAULT_MONTHS[1][0])
	assert_int(OpsView.launch_month(2, 1, 0)).is_equal(SimGame.DEFAULT_MONTHS[2][1])
	assert_int(OpsView.launch_month(3, 2, 0)).is_equal(SimGame.DEFAULT_MONTHS[3][2])
	assert_int(OpsView.launch_month(3, 0, 1)).is_equal(SimGame.DEFAULT_MONTHS[3][0] - 1)
	assert_int(OpsView.launch_month(3, 0, 9)).is_equal(0)


func test_month_names_are_calendar_months_with_fall_offset() -> void:
	assert_str(OpsView.month_name(0, SimState.SEASON_SPRING)).is_equal("January")
	assert_str(OpsView.month_name(4, SimState.SEASON_SPRING)).is_equal("May")
	assert_str(OpsView.month_name(0, SimState.SEASON_FALL)).is_equal("July")
	assert_str(OpsView.month_name(4, SimState.SEASON_FALL)).is_equal("November")
	assert_str(OpsView.month_name(5, SimState.SEASON_FALL)).is_equal("December")


func test_launch_month_name_indexes_by_pad_order() -> void:
	var s := _state()
	var p := s.player(0)
	p.missions = [_plan(1, 0), null, _plan(2, 2)]
	p.missions[2]["rush_months"] = 2
	assert_array(OpsView.scheduled_pads(p)).is_equal([0, 2])
	assert_str(OpsView.launch_month_name(s, p, 0)).is_equal(OpsView.month_name(SimGame.DEFAULT_MONTHS[2][0], s.season))
	assert_str(OpsView.launch_month_name(s, p, 2)).is_equal(OpsView.month_name(SimGame.DEFAULT_MONTHS[2][1] - 2, s.season))
	assert_str(OpsView.launch_month_name(s, p, 1)).is_equal("")
	# A joint second pad does not take a launch slot of its own.
	p.missions = [_plan(1, 0), {"mission_index": 1, "pad": 1, "part": 2, "primary_pad": 0}, null]
	assert_array(OpsView.scheduled_pads(p)).is_equal([0])


func test_expected_gain_uses_the_season_die() -> void:
	assert_float(OpsView.expected_gain(1, 0)).is_equal_approx(3.5, 0.001)
	assert_float(OpsView.expected_gain(2, 0)).is_equal_approx(7.0, 0.001)
	assert_float(OpsView.expected_gain(2, 2)).is_equal_approx(9.0, 0.001)
	assert_float(OpsView.expected_gain(3, -9)).is_equal_approx(3.0, 0.001)   # die floors at 1
	var text := OpsView.expected_gain_text(2, 0)
	assert_str(text).contains("+7.0%")
	assert_str(text).contains("1d6")
	assert_str(OpsView.expected_gain_text(1, 2)).contains("1d8")


func test_research_block_reasons() -> void:
	var s := _state()
	var p := s.player(0)
	var prog := _buy(s, p, "rocket", 0, 50)
	assert_str(OpsView.research_block_reason(p, prog)).is_equal("")
	prog.researched_this_season = true
	assert_str(OpsView.research_block_reason(p, prog)).is_not_empty()
	prog.researched_this_season = false
	prog.safety = prog.max_rd
	assert_str(OpsView.research_block_reason(p, prog)).is_not_empty()
	var dm := p.program("misc", 4)
	assert_str(OpsView.research_block_reason(p, dm)).is_not_empty()


func test_seat_roles_follow_the_personnel_table() -> void:
	var one := OpsView.seat_roles(1)
	assert_int(one.size()).is_equal(1)
	assert_str(one[0]).contains("Capsule")
	assert_str(one[0]).contains("EVA")
	var two := OpsView.seat_roles(2)
	assert_int(two.size()).is_equal(2)
	assert_str(two[0]).contains("Capsule")
	assert_str(two[0]).contains("Docking")
	assert_str(two[1]).contains("LM")
	assert_str(two[1]).contains("EVA")
	assert_str(OpsView.crew_title(0)).is_equal("Primary")
	assert_str(OpsView.crew_title(1)).is_equal("Backup")
	assert_str(OpsView.crew_title(2)).is_equal("Crew 3")


func test_rush_labels_quote_the_planner_constants() -> void:
	assert_str(OpsView.rush_label(0)).is_equal("No rush")
	assert_str(OpsView.rush_label(1)).contains("%d MB" % SimPlanner.RUSH_COST_PER_MONTH)
	assert_str(OpsView.rush_label(2)).contains("-%d%%" % (2 * SimPlanner.RUSH_PENALTY_PER_MONTH))


func test_downgrade_options_start_with_the_plan_and_stop_at_zero() -> void:
	var s := _state()
	var opts := OpsView.downgrade_options(s, _plan(17))
	assert_int(opts[0]).is_equal(17)
	var chain: Array = data.missions[17]["downgrades"]
	for i in opts.size() - 1:
		assert_int(opts[i + 1]).is_equal(int(chain[i]))
	assert_bool(opts.has(0)).is_false()
	assert_array(OpsView.downgrade_options(s, _plan(1))).is_equal([1])


func test_shopping_list_names_programs_without_units() -> void:
	var s := _state()
	var p := s.player(0)
	var rocket := _buy(s, p, "rocket", 0, 80, 0)
	var probe := _buy(s, p, "probe", 0, 80, 0)
	var pl := _plan(1)
	assert_bool(SimPlanner.assemble(s, p, pl).has("vehicles")).is_false()
	var wanted := OpsView.shopping_list(s, p, pl)
	assert_bool(wanted.has(rocket)).is_true()
	assert_bool(wanted.has(probe)).is_true()
	assert_int(wanted.size()).is_equal(2)
	# Inventory is untouched by the what-if assembly.
	assert_int(rocket.units).is_equal(0)
	assert_int(probe.units).is_equal(0)
	rocket.units = 1
	wanted = OpsView.shopping_list(s, p, pl)
	assert_array(wanted).is_equal([probe])
	probe.units = 1
	assert_array(OpsView.shopping_list(s, p, pl)).is_empty()


func test_auto_purchase_buys_what_it_can_and_reports_the_rest() -> void:
	var s := _state()
	var p := s.player(0)
	var rocket := _buy(s, p, "rocket", 0, 80, 0)
	var probe := _buy(s, p, "probe", 0, 80, 0)
	p.cash = SimHardware.unit_price(p, rocket)
	var failed := OpsView.auto_purchase(p, [rocket, probe])
	assert_int(rocket.units).is_equal(1)
	assert_int(probe.units).is_equal(0)
	assert_array(failed).is_equal([probe])
	p.cash = 100
	assert_array(OpsView.auto_purchase(p, [probe])).is_empty()
	assert_int(probe.units).is_equal(1)


func test_launch_descriptions() -> void:
	var s := _state()
	var p := s.player(0)
	var rocket := _buy(s, p, "rocket", 0, 80, 1)
	var probe := _buy(s, p, "probe", 0, 80, 1)
	var launch := SimPlanner.assemble(s, p, _plan(1))
	assert_bool(launch.has("vehicles")).is_true()
	var v: Dictionary = launch["vehicles"][0]
	assert_int(OpsView.lift(v)).is_equal(int(rocket.spec["max_payload"]))
	assert_int(OpsView.payload_weight(v)).is_equal(int(probe.spec["unit_weight"]))
	assert_str(OpsView.rocket_name(v)).is_equal(rocket.display_name().capitalize())
	assert_array(OpsView.launch_programs(launch)).contains([rocket, probe])
	assert_array(OpsView.crew_lines(v)).is_empty()
	assert_str(OpsView.readiness_text(launch)).contains(str(SimPlanner.readiness(launch)["band"]).to_upper())
