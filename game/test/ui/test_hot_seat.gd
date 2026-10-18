extends GdUnitTestSuite
## Hot-seat: several human sides share one computer. Each ends their season in turn; only
## the last human's end runs the AI and plays the season out.


func after_test() -> void:
	Session.game = null


func test_humans_take_turns_before_the_season_plays_out() -> void:
	Session.new_game(5, {"sides": ["usa", "ussr", "cwth"], "humans": ["usa", "cwth"]})
	assert_bool(Session.is_hot_seat()).is_true()
	assert_str(Session.human_side).is_equal("usa")
	var season := Session.state().season
	var year := Session.state().year
	var r1 := Session.end_turn()
	assert_str(str(r1.get("handover", ""))).is_equal("cwth")
	assert_str(Session.human_side).is_equal("cwth")
	assert_int(Session.state().season).is_equal(season)
	var r2 := Session.end_turn()
	assert_bool(r2.has("handover")).is_false()
	assert_str(Session.human_side).is_equal("usa")
	assert_bool(Session.state().season != season or Session.state().year != year).is_true()


func test_only_the_computer_side_gets_an_ai_driver() -> void:
	Session.new_game(5, {"sides": ["usa", "ussr", "cwth"], "humans": ["usa", "cwth"]})
	assert_int(Session.drivers.size()).is_equal(1)
	assert_bool(Session.state().player_for_side("ussr").is_ai).is_true()
	assert_bool(Session.state().player_for_side("cwth").is_ai).is_false()


func test_a_solo_game_is_unchanged() -> void:
	Session.new_game(5, {"sides": ["usa", "ussr"], "human_side": "ussr"})
	assert_bool(Session.is_hot_seat()).is_false()
	assert_str(Session.human_side).is_equal("ussr")
	var r := Session.end_turn()
	assert_bool(r.has("handover")).is_false()
	assert_str(Session.human_side).is_equal("ussr")


func test_a_mid_round_save_resumes_with_the_right_director() -> void:
	Session.new_game(5, {"sides": ["usa", "ussr"], "humans": ["usa", "ussr"]})
	Session.end_turn()   # the US hands over to the Soviet director
	var d := SimSave.to_dict(Session.game)
	var loaded := SimSave.from_dict(GameData, JSON.parse_string(JSON.stringify(d)))
	Session.load_game(loaded, SimSave.human_side_of(loaded))
	assert_str(Session.human_side).is_equal("ussr")
	assert_array(Session.humans).contains_exactly(["usa", "ussr"])
	assert_bool(Session.is_hot_seat()).is_true()
