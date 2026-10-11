extends GdUnitTestSuite
## Derived logic behind the turn, intelligence and museum screens (TurnLogic).

var data: Node


func before() -> void:
	data = load("res://scripts/data/game_data.gd").new()
	add_child(data)
	data.load_all()


func after() -> void:
	data.queue_free()


func _launch(player: int, kinds: Array, outcome := "success") -> Dictionary:
	var awards: Array = []
	for k in kinds:
		awards.append({"row": 0, "kind": k, "points": 1})
	return {"player": player, "mission_index": 1, "outcome": outcome, "steps": [],
			"prestige": {"total": 0, "awards": awards}}


# ------------------------------------------------------------- launch visibility

func test_human_launches_always_visible() -> void:
	assert_bool(TurnLogic.launch_visible(_launch(0, []), 0)).is_true()
	assert_bool(TurnLogic.launch_visible(_launch(0, ["failure"], "failure"), 0)).is_true()
	assert_bool(TurnLogic.launch_visible({"player": 0, "outcome": "scrubbed", "reason": "pad damaged", "mission_index": 1}, 0)).is_true()


func test_rival_launch_visible_only_with_a_first() -> void:
	assert_bool(TurnLogic.launch_visible(_launch(1, []), 0)).is_false()
	assert_bool(TurnLogic.launch_visible(_launch(1, ["second", "other"]), 0)).is_false()
	assert_bool(TurnLogic.launch_visible(_launch(1, ["second", "first"]), 0)).is_true()
	assert_bool(TurnLogic.launch_visible({"player": 1, "outcome": "scrubbed", "mission_index": 1}, 0)).is_false()
	# Same rule from the Soviet seat.
	assert_bool(TurnLogic.launch_visible(_launch(0, []), 1)).is_false()
	assert_bool(TurnLogic.launch_visible(_launch(0, ["first"]), 1)).is_true()


func test_visible_launches_filters_report_in_order() -> void:
	var report := {"launches": [_launch(1, ["first"]), _launch(0, []), _launch(1, []), _launch(0, ["first"])]}
	var shown := TurnLogic.visible_launches(report, 0)
	assert_int(shown.size()).is_equal(3)
	assert_int(shown[0]["player"]).is_equal(1)
	assert_int(shown[1]["player"]).is_equal(0)
	assert_int(shown[2]["player"]).is_equal(0)
	assert_array(TurnLogic.visible_launches({}, 0)).is_empty()
	assert_array(TurnLogic.visible_launches({"launches": []}, 0)).is_empty()


# ------------------------------------------------------------- end game

func test_endgame_bands_by_year() -> void:
	assert_int(TurnLogic.endgame_band(57)).is_equal(0)
	assert_int(TurnLogic.endgame_band(65)).is_equal(0)
	assert_int(TurnLogic.endgame_band(66)).is_equal(1)
	assert_int(TurnLogic.endgame_band(67)).is_equal(1)
	assert_int(TurnLogic.endgame_band(68)).is_equal(2)
	assert_int(TurnLogic.endgame_band(69)).is_equal(2)
	assert_int(TurnLogic.endgame_band(70)).is_equal(3)
	assert_int(TurnLogic.endgame_band(71)).is_equal(3)
	assert_int(TurnLogic.endgame_band(72)).is_equal(4)
	assert_int(TurnLogic.endgame_band(77)).is_equal(4)


func test_endgame_text_index_selection() -> void:
	assert_int(TurnLogic.endgame_text_index(63, 0, 0)).is_equal(0)     # early USA landing
	assert_int(TurnLogic.endgame_text_index(63, 1, 0)).is_equal(1)     # early USSR landing
	assert_int(TurnLogic.endgame_text_index(69, 0, 1)).is_equal(4)     # the reader's side does not matter with a winner
	assert_int(TurnLogic.endgame_text_index(75, 1, 1)).is_equal(9)
	assert_int(TurnLogic.endgame_text_index(77, -1, 0)).is_equal(10)   # no landing: USA line
	assert_int(TurnLogic.endgame_text_index(77, -1, 1)).is_equal(11)   # no landing: USSR line
	var lines: Array = data.text["endgame"]["endgame"]
	assert_int(lines.size()).is_equal(12)


# ------------------------------------------------------------- intelligence

func _owned_state(level := 0) -> SimState:
	var s := SimState.new(data, 42)
	s.player(0).level = level
	for prog in s.player(1).all_programs():
		prog.owned = true
		prog.safety = 70
	return s


func test_intel_accuracy_by_level() -> void:
	assert_int(TurnLogic.intel_accuracy(0)).is_equal(60)
	assert_int(TurnLogic.intel_accuracy(1)).is_equal(50)
	assert_int(TurnLogic.intel_accuracy(2)).is_equal(40)
	assert_int(TurnLogic.intel_max_deviation(0)).is_equal(20)
	assert_int(TurnLogic.intel_max_deviation(2)).is_equal(30)


func test_intel_estimates_stay_within_band_and_in_range() -> void:
	for level in 3:
		var s := _owned_state(level)
		var dev := TurnLogic.intel_max_deviation(level)
		var est := TurnLogic.intel_estimates(s, s.player(1), level)
		assert_int(est.size()).is_equal(s.player(1).owned_programs().size())
		var moved := false
		for prog in s.player(1).owned_programs():
			var e: int = est["%s/%d" % [prog.group, prog.slot]]
			assert_int(absi(e - prog.safety)).is_less_equal(dev)
			assert_int(e).is_between(1, 100)
			if e != prog.safety:
				moved = true
		assert_bool(moved).override_failure_message("noise never applied at level %d" % level).is_true()


func test_intel_estimates_are_stable_within_a_turn_and_change_between_turns() -> void:
	var s := _owned_state(1)
	var a := TurnLogic.intel_estimates(s, s.player(1), 1)
	var b := TurnLogic.intel_estimates(s, s.player(1), 1)
	assert_dict(a).is_equal(b)
	var seed_before := TurnLogic.intel_seed(s)
	SimCalendar.advance(s)
	assert_int(TurnLogic.intel_seed(s)).is_not_equal(seed_before)
	var c := TurnLogic.intel_estimates(s, s.player(1), 1)
	assert_bool(a == c).override_failure_message("estimates should differ in a new turn").is_false()


func test_intel_estimates_only_cover_owned_programs() -> void:
	var s := SimState.new(data, 5)
	var est := TurnLogic.intel_estimates(s, s.player(1), 0)
	for key in est:
		var parts: PackedStringArray = str(key).split("/")
		assert_bool(s.player(1).program(parts[0], int(parts[1])).owned).is_true()


# ------------------------------------------------------------- annual review

func test_review_portrait_rule() -> void:
	assert_str(TurnLogic.review_portrait("usa", 1)).is_equal("President")
	assert_str(TurnLogic.review_portrait("usa", 4)).is_equal("President")
	assert_str(TurnLogic.review_portrait("usa", 5)).is_equal("Vice President")
	assert_str(TurnLogic.review_portrait("usa", 10)).is_equal("Vice President")
	assert_str(TurnLogic.review_portrait("usa", 11)).is_equal("President")
	assert_str(TurnLogic.review_portrait("ussr", 4)).is_equal("General Secretary")
	assert_str(TurnLogic.review_portrait("ussr", 11)).is_equal("Politburo")
	assert_str(TurnLogic.review_portrait("ussr", 12)).is_equal("General Secretary")


func test_review_chart_colour_from_table() -> void:
	assert_object(TurnLogic.review_chart_colour(data.review, 8)).is_equal(UiPalette.OK)
	assert_object(TurnLogic.review_chart_colour(data.review, 9)).is_equal(UiPalette.DANGER)
	assert_object(TurnLogic.review_chart_colour(data.review, 1)).is_equal(UiPalette.OK)
	assert_object(TurnLogic.review_chart_colour({}, 12)).is_equal(UiPalette.DANGER)


# ------------------------------------------------------------- newscast

func test_effect_lines() -> void:
	assert_str(TurnLogic.effect_line({"applied": false, "effect": "cash_delta", "detail": {"amount": 5}})).is_equal("")
	assert_str(TurnLogic.effect_line({"applied": true, "effect": "budget_delta", "detail": {"ok": true, "amount": 15}})).is_equal("+15 MB budget")
	assert_str(TurnLogic.effect_line({"applied": true, "effect": "rd_mod_turn", "detail": {"ok": true, "amount": 10}})).is_equal("R&D teams roll better this season")
	assert_str(TurnLogic.effect_line({"applied": true, "effect": "pad_damage", "detail": {"ok": true, "pad": 0}})).is_equal("Pad 1 damaged")
	assert_str(TurnLogic.effect_line({"applied": true, "effect": "none", "detail": {"ok": true}})).is_equal("")
	assert_object(TurnLogic.news_colour(0)).is_equal(UiPalette.TEXT)


func test_news_placeholders_resolved() -> void:
	var s := SimState.new(data, 1)
	var p := s.player(0)
	var news := {"applied": true, "effect": "cash_delta", "detail": {"ok": true, "amount": 12}}
	assert_str(TurnLogic.resolve_placeholders("CREDIT THE SPACE AGENCY j ADDITIONAL FUNDS.", news, p, 60)).is_equal("CREDIT THE SPACE AGENCY 12 ADDITIONAL FUNDS.")
	var prog_news := {"applied": true, "effect": "program_safety_delta", "detail": {"ok": true, "program": "atlas", "amount": -15}}
	assert_str(TurnLogic.resolve_placeholders("THE e PROGRAM LOST i%.", prog_news, p, 60)).is_equal("THE ATLAS PROGRAM LOST 15%.")
	var pad_news := {"applied": true, "effect": "mission_scrub", "detail": {"ok": true, "pad": 1}}
	assert_str(TurnLogic.resolve_placeholders("THE h FACILITY (b PAD).", pad_news, p, 60)).is_equal("THE SECONDARY FACILITY (SECOND PAD).")
	assert_str(TurnLogic.resolve_placeholders("PRESIDENT g AND DIRECTOR m.", {}, p, 62)).is_equal("PRESIDENT KENNEDY AND DIRECTOR %s." % p.director_name.to_upper())
	# Letters inside words and after apostrophes are left alone.
	assert_str(TurnLogic.resolve_placeholders("AMERICA'S plan", {}, p, 60)).is_equal("AMERICA'S plan")
	assert_str(TurnLogic.head_of_state("ussr", 70)).is_equal("Brezhnev")
	assert_object(TurnLogic.news_colour(1)).is_equal(UiPalette.OK)
	assert_object(TurnLogic.news_colour(2)).is_equal(UiPalette.DANGER)
