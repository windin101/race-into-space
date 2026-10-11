extends GdUnitTestSuite
## Save and load: a game serialised mid-way must continue exactly like the original.

const SEED := 11
const SLOT := "gdunit_roundtrip"

var data: Node


func before() -> void:
	data = load("res://scripts/data/game_data.gd").new()
	add_child(data)
	data.load_all()


func after() -> void:
	SimSave.delete_slot(SLOT)
	data.queue_free()


func _game(p_seed := SEED) -> SimGame:
	return SimGame.new(data, p_seed, {"ai_usa": true, "ai_ussr": true, "human_side": "usa"})


func _play(game: SimGame, seasons: int) -> void:
	var drivers := [SimDriver.new(0), SimDriver.new(1)]
	for t in seasons:
		for d in drivers:
			d.act(game)
		game.end_turn()


## The game dictionary goes through a real JSON encode/decode, like a slot file does.
func _json_trip(d: Dictionary) -> Dictionary:
	var text := JSON.stringify(d)
	var json := JSON.new()
	assert_int(json.parse(text)).is_equal(OK)
	return json.data


func _assert_same_game(a: SimGame, b: SimGame) -> void:
	assert_str(b.state.date_string()).is_equal(a.state.date_string())
	assert_int(b.turn_number).is_equal(a.turn_number)
	assert_bool(b.state.ended).is_equal(a.state.ended)
	assert_int(b.state.winner).is_equal(a.state.winner)
	assert_array(b.state.event_deck).is_equal(a.state.event_deck)
	assert_array(b.state.prestige_rows).is_equal(a.state.prestige_rows)
	assert_int(b.state.rng.save_state()).is_equal(a.state.rng.save_state())
	for i in 2:
		var pa := a.state.player(i)
		var pb := b.state.player(i)
		assert_int(pb.cash).is_equal(pa.cash)
		assert_int(pb.budget).is_equal(pa.budget)
		assert_int(pb.prestige).is_equal(pa.prestige)
		assert_int(pb.prestige_total).is_equal(pa.prestige_total)
		assert_array(pb.prestige_history).is_equal(pa.prestige_history)
		assert_array(pb.pads).is_equal(pa.pads)
		assert_array(pb.milestones).is_equal(pa.milestones)
		assert_int(pb.review_index).is_equal(pa.review_index)
		assert_int(pb.mission_log.size()).is_equal(pa.mission_log.size())
		for m in pa.mission_log.size():
			assert_str(pb.mission_log[m]["outcome"]).is_equal(pa.mission_log[m]["outcome"])
			assert_int(pb.mission_log[m]["mission_index"]).is_equal(pa.mission_log[m]["mission_index"])
		assert_int(pb.astronauts.size()).is_equal(pa.astronauts.size())
		for n in pa.astronauts.size():
			assert_str(pb.astronauts[n].name).is_equal(pa.astronauts[n].name)
			assert_int(pb.astronauts[n].status).is_equal(pa.astronauts[n].status)
			assert_int(pb.astronauts[n].id).is_equal(pa.astronauts[n].id)
		for prog in pa.all_programs():
			var copy: SimProgram = pb.program(prog.group, prog.slot)
			assert_bool(copy.owned).is_equal(prog.owned)
			assert_int(copy.safety).is_equal(prog.safety)
			assert_int(copy.units).is_equal(prog.units)
			assert_int(copy.max_rd).is_equal(prog.max_rd)


func test_dict_round_trip_restores_every_field() -> void:
	var g := _game()
	_play(g, 6)
	var d := _json_trip(SimSave.to_dict(g))
	var g2 := SimSave.from_dict(data, d)
	_assert_same_game(g, g2)
	# Spot checks on things the quick compare does not cover.
	var p := g.state.player(0)
	var p2 := g2.state.player(0)
	assert_str(p2.director_name).is_equal(p.director_name)
	assert_dict(p2.turn_flags).is_equal(p.turn_flags)
	assert_dict(p2.last_news).is_equal(p.last_news)
	assert_array(p2.reviews).is_equal(p.reviews)
	assert_array(p2.missions).is_equal(p.missions)
	assert_array(p2.future).is_equal(p.future)
	assert_array(p2.mission_log).is_equal(p.mission_log)
	assert_int(p2.astronauts.size()).is_greater(0)
	for n in p.astronauts.size():
		assert_dict(p2.astronauts[n].skills).is_equal(p.astronauts[n].skills)
		assert_int(p2.astronauts[n].mood).is_equal(p.astronauts[n].mood)
		assert_int(p2.astronauts[n].program_slot).is_equal(p.astronauts[n].program_slot)
		assert_int(p2.astronauts[n].crew_index).is_equal(p.astronauts[n].crew_index)
	# Astronaut ids in crew outcomes must come back as ints, not JSON strings.
	for r in p2.mission_log:
		for k in r["crew_outcomes"]:
			assert_int(typeof(k)).is_equal(TYPE_INT)


func test_loaded_game_continues_identically() -> void:
	var g := _game()
	_play(g, 6)
	var g2 := SimSave.from_dict(data, _json_trip(SimSave.to_dict(g)))
	_play(g, 4)
	_play(g2, 4)
	_assert_same_game(g, g2)
	assert_str(g.state.date_string()).is_equal("Spring 1962")


func test_loaded_game_matches_an_unbroken_run() -> void:
	# Saving must not perturb the original either: a game played straight through for
	# ten seasons equals one saved and reloaded at six.
	var straight := _game()
	_play(straight, 10)
	var g := _game()
	_play(g, 6)
	var g2 := SimSave.from_dict(data, _json_trip(SimSave.to_dict(g)))
	_play(g2, 4)
	_assert_same_game(straight, g2)


func test_from_dict_does_not_rerun_the_first_turn() -> void:
	var g := _game()
	var d := SimSave.to_dict(g)
	var g2 := SimSave.from_dict(data, d)
	assert_int(g2.turn_number).is_equal(1)
	_assert_same_game(g, g2)
	assert_dict(g2.state.player(1).last_news).is_equal(g.state.player(1).last_news)


func test_slot_save_list_load_delete() -> void:
	SimSave.delete_slot(SLOT)
	var g := _game()
	_play(g, 3)
	assert_bool(SimSave.save_slot(g, SLOT, "Round trip")).is_true()
	assert_bool(FileAccess.file_exists(SimSave.slot_path(SLOT))).is_true()
	var found := {}
	for meta in SimSave.list_slots():
		if meta["slot"] == SLOT:
			found = meta
	assert_dict(found).is_not_empty()
	assert_str(found["label"]).is_equal("Round trip")
	assert_str(found["side"]).is_equal("usa")
	assert_str(found["date"]).is_equal(g.state.date_string())
	assert_int(found["seed"]).is_equal(SEED)
	assert_str(found["saved_at"]).is_not_empty()
	var g2 := SimSave.load_slot(data, SLOT)
	assert_object(g2).is_not_null()
	_assert_same_game(g, g2)
	assert_bool(SimSave.delete_slot(SLOT)).is_true()
	assert_bool(FileAccess.file_exists(SimSave.slot_path(SLOT))).is_false()
	assert_bool(SimSave.delete_slot(SLOT)).is_false()
	assert_object(SimSave.load_slot(data, SLOT)).is_null()
	for meta in SimSave.list_slots():
		assert_str(meta["slot"]).is_not_equal(SLOT)


func test_bad_slot_names_are_rejected() -> void:
	var g := _game()
	assert_bool(SimSave.save_slot(g, "", "x")).is_false()
	assert_bool(SimSave.save_slot(g, "../escape", "x")).is_false()
	assert_object(SimSave.load_slot(data, "no_such_slot_here")).is_null()
