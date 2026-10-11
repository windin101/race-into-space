extends GdUnitTestSuite
## Event deck and card effects (non-astronaut effects; astronaut cards are covered once
## the personnel module exists).

var data: Node


func before() -> void:
	data = load("res://scripts/data/game_data.gd").new()
	add_child(data)
	data.load_all()


func after() -> void:
	data.queue_free()


func _state(p_seed := 11) -> SimState:
	var s := SimState.new(data, p_seed)
	SimEvents.build_deck(s)
	return s


func _card(effect: String, params: Dictionary = {}) -> Dictionary:
	return {"effect": effect, "params": params}


func test_deck_shape() -> void:
	var s := _state()
	assert_int(s.event_deck.size()).is_equal(100)
	assert_int(s.event_deck[0]).is_equal(0)
	assert_int(s.event_deck[1]).is_equal(0)
	# Fall 1957 slots come from pool 0 (codes 1-3).
	assert_int(s.event_deck[2]).is_between(1, 3)
	assert_int(s.event_deck[3]).is_between(1, 3)
	# No code repeats, apart from the opening card.
	var seen := {}
	for i in range(2, 100):
		var c := s.event_deck[i]
		assert_bool(seen.has(c)).override_failure_message("code %d repeated" % c).is_false()
		seen[c] = true
		assert_int(c).is_between(1, 99)
	# 1958-59 slots are all from pool 1.
	for i in range(4, 12):
		assert_int(s.event_deck[i]).is_between(4, 43)


func test_deck_is_seeded() -> void:
	var a := _state(3)
	var b := _state(3)
	assert_array(a.event_deck).is_equal(b.event_deck)


func test_newscast_opening_turn_has_no_effect_and_drifts_budget() -> void:
	var s := _state()
	var p := s.player(0)
	var r := SimEvents.newscast(s, p)
	assert_int(r["code"]).is_equal(0)
	assert_int(r["text_index"]).is_equal(2)
	assert_str(r["text"]).contains("EISENHOWER")
	assert_int(p.budget).is_equal(60 + r["budget_drift"])


func test_year_gated_card_becomes_filler() -> void:
	var s := _state()
	var p := s.player(0)
	s.event_deck[SimEvents.slot_for(s, p)] = 99     # needs 1966
	var r := SimEvents.newscast(s, p)
	assert_str(r["effect"]).is_equal("filler")
	assert_int(r["text_index"]).is_between(102, 115)
	assert_int(p.bad_card_flags).is_not_equal(0)


func test_cash_and_budget_effects() -> void:
	var s := _state()
	var p := s.player(0)
	assert_bool(SimEvents.apply_card(s, p, _card("cash_delta", {"amount": -7}))["ok"]).is_true()
	assert_int(p.cash).is_equal(53)
	assert_bool(SimEvents.apply_card(s, p, _card("budget_delta", {"amount": 15}))["ok"]).is_true()
	assert_int(p.budget).is_equal(75)
	assert_bool(SimEvents.apply_card(s, p, _card("budget_pct", {"pct": 20, "cap": 20}))["ok"]).is_true()
	assert_int(p.budget).is_equal(60)
	p.cash = 9
	assert_bool(SimEvents.apply_card(s, p, _card("cash_pct", {"pct": 10, "min_cash": 10}))["ok"]).is_false()
	p.cash = 55
	assert_bool(SimEvents.apply_card(s, p, _card("cash_pct", {"pct": 10, "min_cash": 10}))["ok"]).is_true()
	assert_int(p.cash).is_equal(50)
	var dice := SimEvents.apply_card(s, p, _card("cash_delta", {"dice": "1d10"}))
	assert_int(dice["amount"]).is_between(1, 10)


func test_rd_modifiers_and_cost() -> void:
	var s := _state()
	var p := s.player(0)
	SimEvents.apply_card(s, p, _card("rd_mod_turn", {"amount": 1}))
	assert_int(p.rd_mods_turn).is_equal(1)
	SimEvents.apply_card(s, p, _card("rd_mod_year", {"amount": -1}))
	assert_int(p.rd_mods_turn).is_equal(0)
	assert_int(p.rd_mods_year).is_equal(-1)
	SimHardware.start_of_season(p)
	assert_int(p.rd_mods_turn).is_equal(0)       # negatives do not carry
	assert_bool(SimEvents.apply_card(s, p, _card("rd_cost_up", {"amount": 1}))["ok"]).is_false()
	p.cash = 500
	var atlas := p.program("rocket", 0)
	SimHardware.buy_program(s, p, atlas)
	atlas.safety = 50
	var r := SimEvents.apply_card(s, p, _card("rd_cost_up", {"amount": 1}))
	assert_bool(r["ok"]).is_true()
	assert_int(atlas.rd_cost()).is_equal(3)


func test_most_advanced_prefers_misc_then_manned() -> void:
	var s := _state()
	var p := s.player(0)
	p.cash = 5000
	var atlas := p.program("rocket", 0)
	var merc := p.program("manned", 0)
	var suits := p.program("misc", 3)
	for prog in [atlas, merc, suits]:
		SimHardware.buy_program(s, p, prog)
		prog.safety = prog.base_safety() + 10
	var r := SimEvents.apply_card(s, p, _card("pay_or_penalty", {"group": "dam_any", "cost": 10, "safety_penalty": -10}))
	assert_str(r["program"]).is_equal("EVA SUITS")
	assert_int(suits.damage).is_equal(-10)
	assert_bool(SimEvents.pay_damage(p, suits)).is_true()
	assert_int(suits.damage).is_equal(0)
	r = SimEvents.apply_card(s, p, _card("program_safety_delta", {"group": "nmod_manned", "amount": 5}))
	assert_str(r["program"]).is_equal("MERCURY")
	assert_int(merc.safety).is_equal(merc.base_safety() + 15)


func test_tech_steal_and_leak() -> void:
	var s := _state()
	var us := s.player(0)
	var them := s.player(1)
	us.cash = 500
	them.cash = 500
	SimHardware.buy_program(s, us, us.program("rocket", 0))
	SimHardware.buy_program(s, them, them.program("rocket", 0))
	us.program("rocket", 0).safety = 30
	them.program("rocket", 0).safety = 50
	var r := SimEvents.apply_card(s, us, _card("tech_steal"))
	assert_bool(r["ok"]).is_true()
	assert_int(us.program("rocket", 0).safety).is_equal(50)
	us.program("rocket", 0).safety = 40
	r = SimEvents.apply_card(s, us, _card("tech_leak"))
	assert_bool(r["ok"]).is_true()
	assert_int(us.program("rocket", 0).safety).is_equal(30)
	assert_bool(SimEvents.apply_card(s, them, _card("tech_steal"))["ok"]).is_false()


func test_program_wide_effects() -> void:
	var s := _state()
	var p := s.player(0)
	SimEvents.apply_card(s, p, _card("program_delay", {"seasons": 2}))
	assert_int(p.program("rocket", 0).delay).is_equal(2)
	assert_int(p.program("rocket", 4).delay).is_equal(2)
	var explorer := p.program("probe", 0)
	SimEvents.apply_card(s, p, _card("program_max_safety_up", {"amount": 5}))
	assert_int(explorer.max_safety()).is_equal(99)      # 98 + 5 capped at 99
	SimEvents.apply_card(s, p, _card("half_price_sale"))
	assert_bool(p.turn_flags["half_price"]).is_true()
	assert_bool(SimEvents.apply_card(s, p, _card("program_unit_cost_up", {"program": "Manned[1]", "amount": 2}))["ok"]).is_false()
	p.cash = 500
	SimHardware.buy_program(s, p, p.program("manned", 1))
	assert_bool(SimEvents.apply_card(s, p, _card("program_unit_cost_up", {"program": "Manned[1]", "amount": 2}))["ok"]).is_true()
	assert_int(p.program("manned", 1).unit_cost()).is_equal(8)


func test_safety_halved_only_above_50() -> void:
	var s := _state()
	var p := s.player(0)
	p.cash = 500
	var atlas := p.program("rocket", 0)
	SimHardware.buy_program(s, p, atlas)
	atlas.safety = 45
	assert_bool(SimEvents.apply_card(s, p, _card("program_safety_halved"))["ok"]).is_false()
	atlas.safety = 81
	assert_bool(SimEvents.apply_card(s, p, _card("program_safety_halved"))["ok"]).is_true()
	assert_int(atlas.safety).is_equal(41)


func test_mission_scrub_delay_and_pad_damage() -> void:
	var s := _state()
	var p := s.player(0)
	assert_bool(SimEvents.apply_card(s, p, _card("mission_scrub"))["ok"]).is_false()
	p.missions[0] = {"mission_index": 1, "pad": 0, "part": 1, "joint": false, "crew_choice": [0, 0]}
	assert_bool(SimEvents.apply_card(s, p, _card("pad_damage", {"pad": 0, "repair_cost": 15}))["ok"]).is_false()
	var r := SimEvents.apply_card(s, p, _card("mission_delay"))
	assert_bool(r["ok"]).is_true()
	assert_object(p.missions[0]).is_null()
	assert_int(p.future[0]["mission_index"]).is_equal(1)
	assert_bool(SimEvents.apply_card(s, p, _card("pad_damage", {"pad": 0, "repair_cost": 15}))["ok"]).is_true()
	assert_int(p.pads[0]).is_equal(15)
	p.pads[0] = SimPlayer.PAD_OK
	p.missions[0] = {"mission_index": 1, "pad": 0, "part": 1, "joint": false}
	assert_bool(SimEvents.apply_card(s, p, _card("mission_scrub"))["ok"]).is_true()
	assert_object(p.missions[0]).is_null()


func test_save_card_needs_owned_hardware() -> void:
	var s := _state()
	var p := s.player(0)
	assert_bool(SimEvents.apply_card(s, p, _card("save_card", {"group": "save_rocket"}))["ok"]).is_false()
	p.cash = 500
	SimHardware.buy_program(s, p, p.program("rocket", 0))
	assert_bool(SimEvents.apply_card(s, p, _card("save_card", {"group": "save_rocket"}))["ok"]).is_true()
	assert_int(p.save_cards).is_equal(1)


func test_every_card_effect_is_handled() -> void:
	var s := _state()
	var handled := ["none", "unimplemented", "cash_delta", "cash_pct", "budget_delta", "budget_pct",
			"rd_mod_turn", "rd_mod_year", "rd_cost_up", "tech_steal", "tech_leak",
			"program_safety_delta", "program_safety_halved", "program_max_safety_up",
			"program_delay", "program_unit_cost_up", "pay_or_penalty", "save_card",
			"half_price_sale", "female_astronauts", "mission_scrub", "mission_delay",
			"mission_crew_swap", "pad_damage", "astronaut_death", "astronaut_injury",
			"astronaut_retire", "astronaut_recruit"]
	for card in s.data.event_effects["cards"]:
		assert_bool(card["effect"] in handled).override_failure_message(
			"card %d effect %s" % [card["index"], card["effect"]]).is_true()
