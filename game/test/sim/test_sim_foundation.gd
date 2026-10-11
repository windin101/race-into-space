extends GdUnitTestSuite
## RNG, calendar, economy and hardware purchase/R&D.

var data: Node


func before() -> void:
	data = load("res://scripts/data/game_data.gd").new()
	add_child(data)
	data.load_all()


func after() -> void:
	data.queue_free()


func _new_state(seed := 1, options := {}) -> SimState:
	return SimState.new(data, seed, options)


func test_rng_is_reproducible() -> void:
	var a := SimRng.new(42)
	var b := SimRng.new(42)
	var seq_a: Array[int] = []
	var seq_b: Array[int] = []
	for i in 20:
		seq_a.append(a.d(100))
		seq_b.append(b.d(100))
	assert_array(seq_a).is_equal(seq_b)
	for v in seq_a:
		assert_int(v).is_between(1, 100)


func test_new_game_defaults() -> void:
	var s := _new_state()
	assert_int(s.year).is_equal(57)
	assert_int(s.season).is_equal(0)
	assert_str(s.date_string()).is_equal("Spring 1957")
	for p in s.players:
		assert_int(p.budget).is_equal(60)
		assert_int(p.cash).is_equal(60)
		assert_int(p.pad_count()).is_equal(1)
		assert_int(p.owned_programs().size()).is_equal(0)
	assert_str(s.player(0).director_name).is_equal("WEBB")
	assert_str(s.player(1).director_name).is_equal("KOROLYOV")


func test_calendar_runs_41_turns() -> void:
	var s := _new_state()
	var turns := 1
	while SimCalendar.advance(s):
		turns += 1
	assert_int(turns).is_equal(42)
	assert_int(s.year).is_equal(78)
	var s2 := _new_state()
	assert_bool(SimCalendar.is_review_time(s2)).is_false()
	SimCalendar.advance(s2)
	SimCalendar.advance(s2)
	assert_str(s2.date_string()).is_equal("Spring 1958")
	assert_bool(SimCalendar.is_review_time(s2)).is_true()


func test_planet_windows() -> void:
	assert_bool(SimCalendar.window_open("mars", 60, 0)).is_true()
	assert_bool(SimCalendar.window_open("mars", 60, 1)).is_false()
	assert_bool(SimCalendar.window_open("mars", 69, 1)).is_true()
	assert_bool(SimCalendar.window_open("saturn", 66, 1)).is_true()
	assert_bool(SimCalendar.window_open("saturn", 67, 0)).is_false()
	assert_bool(SimCalendar.window_open("venus", 58, 0)).is_true()


func test_budget_bands() -> void:
	assert_int(SimEconomy.budget_band(40)).is_equal(0)
	assert_int(SimEconomy.budget_band(50)).is_equal(0)
	assert_int(SimEconomy.budget_band(51)).is_equal(1)
	assert_int(SimEconomy.budget_band(90)).is_equal(1)
	assert_int(SimEconomy.budget_band(110)).is_equal(2)
	assert_int(SimEconomy.budget_band(140)).is_equal(3)
	assert_int(SimEconomy.budget_band(160)).is_equal(4)
	assert_int(SimEconomy.budget_band(161)).is_equal(5)


func test_end_of_season_rolls_prestige_into_budget_and_pays_yearly() -> void:
	var s := _new_state()
	var p := s.player(0)
	p.add_prestige(12)
	p.cash = 10
	SimEconomy.end_of_season(s)          # spring: budget grows, no cash
	assert_int(p.budget).is_equal(72)
	assert_int(p.prestige).is_equal(0)
	assert_int(p.cash).is_equal(10)
	SimCalendar.advance(s)
	p.add_prestige(200)
	SimEconomy.end_of_season(s)          # fall: capped budget is paid out
	assert_int(p.budget).is_equal(180)
	assert_int(p.cash).is_equal(190)
	assert_array(p.prestige_history).is_equal([12, 200])


func test_cash_overflow_resets_to_900() -> void:
	var s := _new_state()
	s.season = SimState.SEASON_FALL
	var p := s.player(0)
	p.cash = 950
	SimEconomy.end_of_season(s)
	assert_int(p.cash).is_equal(900)


func test_newscast_adjustment_uses_band_table() -> void:
	var s := _new_state(7)
	var p := s.player(0)
	p.budget = 30                        # floored to 40, band 0: every pick is positive
	var delta := SimEconomy.newscast_adjustment(s, p)
	assert_int(delta).is_between(5, 30)
	assert_int(p.budget).is_equal(40 + delta)


func test_buy_pads() -> void:
	var s := _new_state()
	var p := s.player(0)
	assert_bool(SimEconomy.buy_pad(p)).is_true()
	assert_bool(SimEconomy.buy_pad(p)).is_true()
	assert_bool(SimEconomy.buy_pad(p)).is_false()
	assert_int(p.pad_count()).is_equal(3)
	assert_int(p.cash).is_equal(20)
	p.pads[1] = 7
	assert_bool(p.pad_usable(1)).is_false()
	assert_bool(SimEconomy.repair_pad(p, 1)).is_true()
	assert_int(p.cash).is_equal(13)
	assert_bool(p.pad_usable(1)).is_true()


func test_buy_program_and_units() -> void:
	var s := _new_state()
	var p := s.player(0)
	var atlas := p.program("rocket", 0)
	assert_bool(SimHardware.buy_program(s, p, atlas)).is_true()
	assert_bool(atlas.owned).is_true()
	assert_int(atlas.units).is_equal(1)
	assert_int(atlas.safety).is_equal(atlas.base_safety())
	assert_int(p.cash).is_equal(60 - atlas.program_cost())
	assert_bool(SimHardware.buy_program(s, p, atlas)).is_false()
	for i in 5:
		assert_bool(SimHardware.buy_unit(p, atlas)).is_true()
	assert_bool(SimHardware.buy_unit(p, atlas)).is_false()
	assert_int(atlas.units).is_equal(6)


func test_cannot_buy_without_cash_or_during_delay() -> void:
	var s := _new_state()
	var p := s.player(0)
	var nova := p.program("rocket", 3)
	assert_bool(SimHardware.can_buy_program(p, nova)).is_false()
	p.cash = 1000
	nova.delay = 2
	assert_bool(SimHardware.can_buy_program(p, nova)).is_false()
	SimHardware.start_of_season(p)
	SimHardware.start_of_season(p)
	assert_bool(SimHardware.can_buy_program(p, nova)).is_true()


func test_half_price_sale() -> void:
	var s := _new_state()
	var p := s.player(0)
	p.turn_flags["half_price"] = true
	var atlas := p.program("rocket", 0)
	assert_int(SimHardware.program_price(p, atlas)).is_equal(int(atlas.program_cost() / 2.0))
	SimHardware.start_of_season(p)
	assert_int(SimHardware.program_price(p, atlas)).is_equal(atlas.program_cost())


func test_research_raises_safety_up_to_max_rd() -> void:
	var s := _new_state(3)
	var p := s.player(0)
	p.cash = 500
	var atlas := p.program("rocket", 0)
	SimHardware.buy_program(s, p, atlas)
	var start := atlas.safety
	var gain := SimHardware.research(s, p, atlas, 5)
	assert_int(gain).is_between(5, 30)
	assert_int(atlas.safety).is_equal(start + gain)
	assert_int(SimHardware.research(s, p, atlas, 1)).is_equal(-1)  # once per season
	var seasons := 0
	while atlas.safety < atlas.max_rd and seasons < 40:
		SimHardware.start_of_season(p)
		SimHardware.research(s, p, atlas, SimHardware.max_teams(p, atlas))
		seasons += 1
	assert_int(atlas.safety).is_equal(atlas.max_rd)
	assert_int(SimHardware.max_teams(p, atlas)).is_equal(0)


func test_max_teams_limited_below_hard() -> void:
	var s := _new_state()
	var p := s.player(0)
	p.cash = 500
	var atlas := p.program("rocket", 0)
	SimHardware.buy_program(s, p, atlas)
	atlas.safety = atlas.max_rd - 2
	assert_int(SimHardware.max_teams(p, atlas)).is_equal(2)
	p.level = 2
	assert_int(SimHardware.max_teams(p, atlas)).is_equal(5)


func test_docking_module_cannot_be_researched() -> void:
	var s := _new_state()
	var p := s.player(0)
	p.cash = 500
	var dm := p.program("misc", 4)
	SimHardware.buy_program(s, p, dm)
	assert_int(dm.safety).is_equal(40)
	assert_bool(dm.can_research()).is_false()


func test_success_and_death_adjust_safety() -> void:
	var s := _new_state()
	var p := s.player(0)
	p.cash = 500
	var merc := p.program("manned", 0)
	SimHardware.buy_program(s, p, merc)
	merc.safety = merc.max_rd
	SimHardware.reward_success(merc)
	assert_int(merc.safety).is_equal(merc.max_rd_original + 1)
	assert_int(merc.max_rd).is_equal(merc.max_rd_original + 1)
	merc.safety = 80
	SimHardware.punish_death(p, merc)       # easy: halved
	assert_int(merc.safety).is_equal(40)
	assert_int(merc.max_rd).is_equal(merc.max_rd_original)
	p.level = 1
	merc.safety = 80
	SimHardware.punish_death(p, merc)       # medium: back to base
	assert_int(merc.safety).is_equal(merc.base_safety())
