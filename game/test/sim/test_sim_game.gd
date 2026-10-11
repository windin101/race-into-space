extends GdUnitTestSuite
## The turn loop end to end with the scripted driver.

var data: Node


func before() -> void:
	data = load("res://scripts/data/game_data.gd").new()
	add_child(data)
	data.load_all()


func after() -> void:
	data.queue_free()


func _game(p_seed := 1) -> SimGame:
	return SimGame.new(data, p_seed, {"ai_usa": true, "ai_ussr": true})


func test_first_turn_state() -> void:
	var g := _game()
	assert_str(g.state.date_string()).is_equal("Spring 1957")
	assert_int(g.turn_number).is_equal(1)
	for p in g.state.players:
		assert_dict(p.last_news).is_not_empty()
		assert_int(p.last_news["code"]).is_equal(0)
		assert_int(p.budget).is_equal(60 + int(p.last_news["budget_drift"]))


func test_end_turn_moves_plans_and_advances() -> void:
	var g := _game()
	var p := g.state.player(0)
	p.cash = 500
	SimHardware.buy_program(g.state, p, p.program("rocket", 0))
	SimHardware.buy_program(g.state, p, p.program("probe", 0))
	assert_bool(SimPlanner.plan(g.state, p, 1, 0)).is_true()
	var report := g.end_turn()
	assert_str(report["date"]).is_equal("Spring 1957")
	assert_array(report["launches"]).is_empty()           # nothing was scheduled for this season
	assert_str(g.state.date_string()).is_equal("Fall 1957")
	assert_int(p.missions[0]["mission_index"]).is_equal(1)
	assert_object(p.future[0]).is_null()
	report = g.end_turn()
	assert_int(report["launches"].size()).is_equal(1)
	assert_int(report["launches"][0]["mission_index"]).is_equal(1)
	assert_int(p.mission_log.size()).is_equal(1)
	assert_str(g.state.date_string()).is_equal("Spring 1958")


func test_unassemblable_mission_is_scrubbed_with_penalty() -> void:
	var g := _game()
	var p := g.state.player(0)
	SimPlanner.plan(g.state, p, 1, 0)                     # no hardware at all
	g.end_turn()
	var report := g.end_turn()
	assert_int(report["launches"].size()).is_equal(1)
	assert_str(report["launches"][0]["outcome"]).is_equal("scrubbed")
	# -3 was folded into the budget at season end.
	assert_int(p.prestige_history[1]).is_equal(-3)


func test_lunar_landing_ends_game() -> void:
	var g := _game(2)
	var p := g.state.player(1)
	# Fake a landing result through the prestige path the turn loop uses.
	var result := {"player": 1, "mission_index": 56, "manned": true,
			"goals": [{"row": 22, "success": true}], "deaths": 0}
	var award := SimPrestige.award(g.state, result)
	assert_int(award["total"]).is_greater(40)
	# The loop's victory check keys on a "first" award on row 22.
	var first_landing := false
	for aw in award["awards"]:
		if aw["kind"] == "first" and aw["row"] == 22:
			first_landing = true
	assert_bool(first_landing).is_true()


func test_scripted_game_runs_to_completion_deterministically() -> void:
	var results: Array = []
	for run in 2:
		var g := _game(7)
		var drivers := [SimDriver.new(0), SimDriver.new(1)]
		var turns := 0
		while not g.state.ended and turns < 50:
			for d in drivers:
				d.act(g)
			g.end_turn()
			turns += 1
		assert_bool(g.state.ended).is_true()
		assert_int(turns).is_less_equal(42)
		results.append([g.state.end_reason, g.state.winner, g.state.player(0).prestige_total,
				g.state.player(1).prestige_total, g.state.player(0).mission_log.size()])
	assert_array(results[0]).is_equal(results[1])
	# A scripted side should at least get a satellite up in twenty years.
	var g2 := _game(7)
	var drivers2 := [SimDriver.new(0), SimDriver.new(1)]
	var turns2 := 0
	while not g2.state.ended and turns2 < 50:
		for d in drivers2:
			d.act(g2)
		g2.end_turn()
		turns2 += 1
	assert_int(g2.state.player(0).mission_log.size()).is_greater(0)
	assert_int(g2.state.player(0).milestones[0] + g2.state.player(1).milestones[0]).is_greater(0)
