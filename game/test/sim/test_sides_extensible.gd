extends GdUnitTestSuite
## The game is not tied to a fixed set of sides. A made-up side defined only here (its
## data copied from the United States' blocks) must start, play twenty seasons with the
## AI in a three- and a two-side race, and survive a save and load. If this fails, some
## code has started naming sides again.

const FAKE := "zz_test"

var data


func before() -> void:
	data = load("res://scripts/data/game_data.gd").new()
	data.load_all()
	for model in data.hardware["models"]:
		data.hardware["models"][model][FAKE] = data.hardware["models"][model]["usa"].duplicate(true)
	data.roster["sides"][FAKE] = data.roster["sides"]["usa"].duplicate(true)
	data.new_game["sides"][FAKE] = data.new_game["sides"]["usa"].duplicate(true)
	data.text["events"][FAKE] = data.text["events"]["usa"].duplicate(true)
	Sides.register({"id": FAKE, "name": "Test Federation", "short": "TF", "adjective": "Federal",
			"nation": "The Test Federation", "people": "aeronaut", "accent": "2e7d4f", "accent_dark": "1d5233",
			"room_tint": "2a6b45", "site": "Test Range", "agency": "TIB", "reviewer": "Chancellor",
			"text_slot": 0, "rules": "usa"})


func after() -> void:
	Sides.unregister(FAKE)


func _play(lineup: Array, seasons: int) -> SimGame:
	var game := SimGame.new(data, 4242, {"model": "basic", "sides": lineup})
	var drivers: Array = []
	for p in game.state.players:
		p.is_ai = true
		drivers.append(SimAi.new(p.index))
	for t in seasons:
		if game.state.ended:
			break
		for d in drivers:
			d.act(game)
		game.end_turn()
	return game


func test_three_side_race_plays_and_launches() -> void:
	var game := _play(["usa", "ussr", FAKE], 20)
	assert_int(game.state.players.size()).is_equal(3)
	assert_str(game.state.players[2].side).is_equal(FAKE)
	var flights := 0
	for p in game.state.players:
		flights += p.mission_log.size()
	assert_int(flights).is_greater(0)
	assert_int(game.state.players[2].mission_log.size()).override_failure_message("the added side never flew").is_greater(0)


func test_any_pair_can_race() -> void:
	var game := _play(["ussr", FAKE], 12)
	assert_int(game.state.players.size()).is_equal(2)
	assert_str(game.state.leading_rival(0).side).is_equal(FAKE)


func test_three_side_game_saves_and_loads() -> void:
	var game := _play(["usa", "ussr", FAKE], 8)
	var d := SimSave.to_dict(game)
	var back := SimSave.from_dict(data, JSON.parse_string(JSON.stringify(d)))
	assert_int(back.state.players.size()).is_equal(3)
	assert_str(back.state.players[2].side).is_equal(FAKE)
	for i in 3:
		assert_int(back.state.players[i].prestige_total).is_equal(game.state.players[i].prestige_total)
		assert_int(back.state.players[i].cash).is_equal(game.state.players[i].cash)


func test_third_side_to_achieve_a_row_counts_as_achieved() -> void:
	var game := SimGame.new(data, 1, {"model": "basic", "sides": ["usa", "ussr", FAKE]})
	var state := game.state
	var awards: Array = []
	SimPrestige._claim(state, 0, 0, 0, awards)
	SimPrestige._claim(state, 1, 0, 0, awards)
	SimPrestige._claim(state, 2, 0, 0, awards)
	assert_bool(SimPrestige.achieved(state, 2, 0)).is_true()
	assert_str(awards[2]["kind"]).is_equal("later")
