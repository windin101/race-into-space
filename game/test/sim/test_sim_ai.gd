extends GdUnitTestSuite
## The computer opponent: estimate sanity, handicap gating, and landing by 1977.

var data: Node


func before() -> void:
	data = load("res://scripts/data/game_data.gd").new()
	add_child(data)
	data.load_all()


func after() -> void:
	data.queue_free()


func _play(seed_value: int, level: int, max_turns := 50) -> SimGame:
	var game := SimGame.new(data, seed_value, {"ai_usa": true, "ai_ussr": true, "level_usa": level, "level_ussr": level})
	var ais := [SimAi.new(0), SimAi.new(1)]
	var turns := 0
	while not game.state.ended and turns < max_turns:
		for ai in ais:
			ai.act(game)
		game.end_turn()
		turns += 1
	return game


func test_success_estimate_tracks_hardware_safety() -> void:
	var s := SimState.new(data, 3)
	var p := s.player(0)
	p.cash = 5000
	for pair in [["rocket", 0], ["probe", 0]]:
		SimHardware.buy_program(s, p, p.program(pair[0], pair[1]))
	var ai := SimAi.new(0)
	var plan := ai._trial_plan(s, 1, 0, 0)
	p.program("rocket", 0).safety = 50
	p.program("probe", 0).safety = 50
	var low := ai.success_probability(s, SimPlanner.assemble(s, p, plan))
	p.program("rocket", 0).safety = 90
	p.program("probe", 0).safety = 90
	var high := ai.success_probability(s, SimPlanner.assemble(s, p, plan))
	assert_float(low).is_between(0.45, 0.55)
	assert_float(high).is_between(0.85, 0.95)
	var whole := ai.mission_probability(s, SimPlanner.assemble(s, p, plan))
	assert_float(whole).is_less(high)


func test_handicap_only_when_human_not_on_easy() -> void:
	var s := SimState.new(data, 4)
	var usa := s.player(0)
	var ussr := s.player(1)
	usa.is_ai = false
	ussr.is_ai = true
	ussr.level = 2
	var ai := SimAi.new(1)
	ai._params = SimAi.LEVELS[2]
	usa.level = 0
	var before_cash := ussr.cash
	ai._handicap(s, ussr)
	assert_int(ussr.cash).is_equal(before_cash)
	usa.level = 1
	ai._handicap(s, ussr)
	assert_int(ussr.cash).is_equal(before_cash + 25)


func test_hard_ai_lands_on_the_moon() -> void:
	var landed := 0
	for seed_value in [301, 302, 303]:
		var game := _play(seed_value, 2)
		if game.state.end_reason == "lunar landing":
			landed += 1
			assert_int(game.state.year).is_less_equal(77)
	assert_int(landed).override_failure_message("hard AI landed in %d of 3 games" % landed).is_greater_equal(2)


func test_easy_ai_is_slower_than_hard() -> void:
	# Easy flies at higher safety bars, so by 1965 it has flown fewer missions.
	var easy := SimGame.new(data, 77, {"ai_usa": true, "ai_ussr": true, "level_usa": 0, "level_ussr": 0})
	var hard := SimGame.new(data, 77, {"ai_usa": true, "ai_ussr": true, "level_usa": 2, "level_ussr": 2})
	for pair in [[easy, 0], [hard, 2]]:
		var game: SimGame = pair[0]
		var ais := [SimAi.new(0), SimAi.new(1)]
		for t in 16:
			for ai in ais:
				ai.act(game)
			game.end_turn()
	var easy_missions := easy.state.player(0).mission_log.size() + easy.state.player(1).mission_log.size()
	var hard_missions := hard.state.player(0).mission_log.size() + hard.state.player(1).mission_log.size()
	assert_int(hard_missions).is_greater_equal(easy_missions)
	assert_int(hard.state.player(0).cash + hard.state.player(1).cash).is_greater(0)
