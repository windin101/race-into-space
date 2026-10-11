extends GdUnitTestSuite
## Recruiting, training, crews, compatibility, mood, retirement and mission outcomes.

const Status := SimAstronaut.Status
const GROUP_1_USA := ["GRISSOM", "SHEPARD", "GLENN", "CARPENTER", "SCHIRRA", "COOPER", "SLAYTON"]

var data: Node


func before() -> void:
	data = load("res://scripts/data/game_data.gd").new()
	add_child(data)
	data.load_all()


func after() -> void:
	data.queue_free()


func _new_state(p_seed := 1, options := {}) -> SimState:
	return SimState.new(data, p_seed, options)


## An astronaut already through basic training, with neutral compatibility.
func _make_active(p: SimPlayer, name: String, skills := {}, compat := 5) -> SimAstronaut:
	var a := SimAstronaut.new()
	a.name = name
	for k in skills:
		a.skills[k] = skills[k]
	a.status = Status.ACTIVE
	a.mood = 50
	a.compat = compat
	a.compat_left = 1
	a.compat_right = 1
	a.id = p.astronauts.size()
	p.astronauts.append(a)
	return a


func _buy_capsule(s: SimState, p: SimPlayer, slot: int) -> SimProgram:
	p.cash = 500
	var prog := p.program("manned", slot)
	SimHardware.buy_program(s, p, prog)
	return prog


func _candidate(s: SimState, p: SimPlayer, name: String) -> Dictionary:
	for c in SimPersonnel.available_recruits(s, p):
		if c["name"] == name:
			return c
	return {}


func test_recruit_cost_and_group_advance() -> void:
	var s := _new_state()
	var p := s.player(0)
	assert_int(SimPersonnel.recruit_cost(p)).is_equal(20)
	assert_int(SimPersonnel.available_recruits(s, p).size()).is_equal(11)   # 14 minus 3 women
	assert_bool(SimPersonnel.recruit(s, p, GROUP_1_USA + ["KINCHELOE"])).is_true()
	assert_int(p.astronauts.size()).is_equal(7)                             # capped at number_to_choose
	assert_int(p.cash).is_equal(40)
	assert_int(p.recruit_group).is_equal(1)
	assert_int(p.recruit_delay).is_equal(6)
	assert_int(SimPersonnel.recruit_cost(p)).is_equal(15)
	for i in p.astronauts.size():
		var a: SimAstronaut = p.astronauts[i]
		assert_int(a.id).is_equal(i)
		assert_int(a.status).is_equal(Status.BASIC_TRAINING)
		assert_str(a.name).is_equal(GROUP_1_USA[i])
	assert_bool(SimPersonnel.recruit(s, p, ["WHITE"])).is_false()          # delay running


func test_availability_gated_by_recruit_delay() -> void:
	var s := _new_state()
	var p := s.player(0)
	SimPersonnel.recruit(s, p, GROUP_1_USA)
	for i in 5:
		SimPersonnel.start_of_season(s, p)
		assert_array(SimPersonnel.available_recruits(s, p)).is_empty()
	SimPersonnel.start_of_season(s, p)
	assert_int(p.recruit_delay).is_equal(0)
	assert_int(SimPersonnel.available_recruits(s, p).size()).is_equal(18)   # group 2: 21 minus 3 women
	p.female_allowed = true
	assert_int(SimPersonnel.available_recruits(s, p).size()).is_equal(21)
	p.recruit_group = 5
	assert_array(SimPersonnel.available_recruits(s, p)).is_empty()


func test_women_required_when_offered() -> void:
	var s := _new_state()
	var p := s.player(0)
	p.female_allowed = true
	assert_dict(_candidate(s, p, "HART")).is_not_empty()
	assert_bool(SimPersonnel.recruit(s, p, GROUP_1_USA)).is_false()
	assert_int(p.cash).is_equal(60)
	assert_bool(SimPersonnel.recruit(s, p, GROUP_1_USA.slice(0, 6) + ["HART"])).is_true()
	assert_bool(p.astronauts[6].female).is_true()


func test_recruit_losses_stay_within_bounds() -> void:
	for run in range(1, 25):
		var s := _new_state(run)
		var p := s.player(1)
		var pool := SimPersonnel.available_recruits(s, p)
		var names: Array = []
		for c in pool.slice(0, 7):
			names.append(c["name"])
		SimPersonnel.recruit(s, p, names)
		for i in 7:
			var a: SimAstronaut = p.astronauts[i]
			var c: Dictionary = pool[i]
			var primary_loss: int = (c["capsule"] - a.skills["capsule"]) + (c["endurance"] - a.skills["endurance"])
			assert_int(primary_loss).is_between(0, 1)
			assert_int(a.skills["capsule"]).is_between(c["capsule"] - 1, c["capsule"])
			assert_int(a.skills["endurance"]).is_between(c["endurance"] - 1, c["endurance"])
			var secondary: int = a.skills["lm"] + a.skills["eva"] + a.skills["docking"]
			assert_int(secondary).is_equal(c["lm"] + c["eva"] + c["docking"] - 3)
			assert_int(a.mood).is_between(85, 100)
			assert_int(a.mood % 5).is_equal(0)
			assert_int(a.compat).is_between(1, 10)
			assert_int(a.compat_left).is_between(1, 2)
			assert_int(a.compat_right).is_between(1, 2)


func test_basic_training_takes_three_seasons_and_raises_skills() -> void:
	var s := _new_state(2)
	var p := s.player(0)
	SimPersonnel.recruit(s, p, GROUP_1_USA)
	var before: Array[int] = []
	for a in p.astronauts:
		before.append(a.skills["capsule"] + a.skills["lm"] + a.skills["eva"] + a.skills["docking"] + a.skills["endurance"])
	for i in 2:
		SimPersonnel.start_of_season(s, p)
		for a in p.astronauts:
			assert_int(a.status).is_not_equal(Status.ACTIVE)
	SimPersonnel.start_of_season(s, p)
	var graduated := 0
	for i in p.astronauts.size():
		var a: SimAstronaut = p.astronauts[i]
		for k in SimAstronaut.SKILLS:
			assert_int(a.skills[k]).is_between(0, 4)
		if a.status == Status.ACTIVE:
			graduated += 1
			var total: int = a.skills["capsule"] + a.skills["lm"] + a.skills["eva"] + a.skills["docking"] + a.skills["endurance"]
			assert_int(total).is_greater_equal(before[i] + 3)   # three gains, and negatives floored
			assert_int(a.training_seasons_left).is_equal(0)
			assert_int(a.seasons_in_status).is_equal(0)
		else:
			assert_bool(a.status == Status.INJURED or a.status == Status.RETIRED).is_true()
	assert_int(graduated).is_greater_equal(5)


func test_advanced_training_cost_length_and_gain() -> void:
	var s := _new_state()
	var p := s.player(0)
	var a := _make_active(p, "A", {"lm": 1})
	assert_bool(SimPersonnel.start_advanced_training(s, p, a, "lm")).is_true()
	assert_int(p.cash).is_equal(57)
	assert_int(a.status).is_equal(Status.ADVANCED_TRAINING)
	assert_bool(SimPersonnel.start_advanced_training(s, p, a, "lm")).is_false()   # already training
	SimPersonnel.start_of_season(s, p)
	assert_int(a.skills["lm"]).is_equal(1)
	SimPersonnel.start_of_season(s, p)
	assert_int(a.skills["lm"]).is_equal(2)                                        # halfway bonus
	SimPersonnel.start_of_season(s, p)
	assert_int(a.status).is_equal(Status.ADVANCED_TRAINING)
	SimPersonnel.start_of_season(s, p)
	assert_int(a.status).is_equal(Status.ACTIVE)
	assert_int(a.skills["lm"]).is_equal(3)
	# Already at 3: 2 MB, joins the last two seasons, ends at 4. Refused at 4.
	assert_bool(SimPersonnel.start_advanced_training(s, p, a, "lm")).is_true()
	assert_int(p.cash).is_equal(55)
	SimPersonnel.start_of_season(s, p)
	assert_int(a.status).is_equal(Status.ADVANCED_TRAINING)
	SimPersonnel.start_of_season(s, p)
	assert_int(a.status).is_equal(Status.ACTIVE)
	assert_int(a.skills["lm"]).is_equal(4)
	assert_bool(SimPersonnel.start_advanced_training(s, p, a, "lm")).is_false()
	assert_int(p.cash).is_equal(55)


func test_advanced_training_short_option_and_refunds() -> void:
	var s := _new_state(1, {"short_training": true})
	var p := s.player(0)
	var a := _make_active(p, "A", {"eva": 0})
	SimPersonnel.start_advanced_training(s, p, a, "eva")
	for i in 3:
		SimPersonnel.start_of_season(s, p)
	assert_int(a.status).is_equal(Status.ACTIVE)
	assert_int(a.skills["eva"]).is_equal(2)
	var expected := [3, 2, 1, 0]
	for elapsed in 4:
		var s2 := _new_state()
		var p2 := s2.player(0)
		var b := _make_active(p2, "B", {"docking": 1})
		SimPersonnel.start_advanced_training(s2, p2, b, "docking")
		for i in elapsed:
			SimPersonnel.start_of_season(s2, p2)
		var cash_before := p2.cash
		assert_int(SimPersonnel.withdraw_training(s2, p2, b)).is_equal(expected[elapsed])
		assert_int(p2.cash).is_equal(cash_before + expected[elapsed])
		assert_int(b.status).is_equal(Status.ACTIVE)
		assert_str(b.training_focus).is_equal("")
	assert_int(SimPersonnel.withdraw_training(s, p, a)).is_equal(0)      # not in training


func test_crew_capacity_validation() -> void:
	var s := _new_state()
	var p := s.player(0)
	_buy_capsule(s, p, 1)                                   # two-man capsule
	assert_int(SimPersonnel.capsule_programs(p).size()).is_equal(1)
	var a := _make_active(p, "A")
	var b := _make_active(p, "B")
	var c := _make_active(p, "C")
	var d := _make_active(p, "D")
	assert_bool(SimPersonnel.assign_to_program(p, a, 0)).is_false()     # not owned
	for x in [a, b, c]:
		assert_bool(SimPersonnel.assign_to_program(p, x, 1)).is_true()
		assert_bool(x.moved_this_season).is_true()
	assert_bool(SimPersonnel.assign_to_program(p, a, 1)).is_false()     # already assigned
	assert_bool(SimPersonnel.set_crew(p, 1, 0, [a])).is_false()         # too small
	assert_bool(SimPersonnel.set_crew(p, 1, 0, [a, b, c])).is_false()   # too big
	assert_bool(SimPersonnel.set_crew(p, 1, 0, [a, d])).is_false()      # d not in the program
	assert_bool(SimPersonnel.set_crew(p, 1, 0, [a, a])).is_false()      # duplicate
	assert_bool(SimPersonnel.set_crew(p, 1, 0, [b, a])).is_true()
	assert_int(a.crew_position).is_equal(1)
	assert_int(b.crew_position).is_equal(0)
	assert_array(SimPersonnel.crew(p, 1, 0)).is_equal([b, a])
	assert_bool(SimPersonnel.set_crew(p, 1, 1, [a, c])).is_false()      # a already in crew 0
	assert_bool(SimPersonnel.set_crew(p, 1, 8, [a, c])).is_false()      # beyond max crews
	assert_bool(SimPersonnel.start_advanced_training(s, p, a, "lm")).is_false()   # in a crew
	SimPersonnel.clear_crew(p, 1, 0)
	assert_bool(a.in_crew()).is_false()
	assert_array(SimPersonnel.crew(p, 1, 0)).is_empty()
	assert_bool(SimPersonnel.set_crew(p, 1, 1, [a, c])).is_true()
	assert_array(SimPersonnel.crews_of(p, 1)).is_equal([1])
	SimPersonnel.unassign(p, a)
	assert_int(a.program_slot).is_equal(-1)
	assert_array(SimPersonnel.crew(p, 1, 1)).is_empty()                 # crew dissolved
	assert_int(c.program_slot).is_equal(1)                              # crewmate keeps the program


func test_compatibility_ring() -> void:
	var p := SimPlayer.new()
	var ten := _make_active(p, "TEN", {}, 10)
	var one := _make_active(p, "ONE", {}, 1)
	var nine := _make_active(p, "NINE", {}, 9)
	var five := _make_active(p, "FIVE", {}, 5)
	var three := _make_active(p, "THREE", {}, 3)
	assert_bool(SimPersonnel.compatible(ten, one)).is_true()       # 10 + CR 1 wraps to 1
	assert_bool(SimPersonnel.compatible(ten, nine)).is_true()
	assert_bool(SimPersonnel.compatible(ten, five)).is_false()
	assert_bool(SimPersonnel.compatible(one, ten)).is_true()       # 1 - CL 1 wraps to 10
	assert_bool(SimPersonnel.compatible(three, one)).is_false()
	three.compat_left = 2
	assert_bool(SimPersonnel.compatible(three, one)).is_true()     # not symmetric
	assert_bool(SimPersonnel.compatible(one, three)).is_false()
	assert_int(SimPersonnel.conflicts_for(three, [three, one, five])).is_equal(1)
	assert_int(SimPersonnel.crew_conflicts([three, one, five])).is_equal(5)   # 3>5, 1>3, 1>5, 5>3, 5>1


func test_crew_skill_by_role() -> void:
	var p := SimPlayer.new()
	var cmdr := _make_active(p, "C", {"capsule": 4, "lm": 1, "eva": 0, "docking": 3, "endurance": 2})
	var pilot := _make_active(p, "P", {"capsule": 1, "lm": 3, "eva": 2, "docking": 1, "endurance": 3})
	var two := [cmdr, pilot]
	assert_int(SimPersonnel.crew_skill(two, "capsule")).is_equal(4)
	assert_int(SimPersonnel.crew_skill(two, "docking")).is_equal(3)
	assert_int(SimPersonnel.crew_skill(two, "lm")).is_equal(3)
	assert_int(SimPersonnel.crew_skill(two, "eva")).is_equal(2)
	assert_int(SimPersonnel.crew_skill(two, "endurance")).is_equal(3)      # 2.5 rounds up
	assert_int(SimPersonnel.crew_skill([pilot], "docking")).is_equal(0)   # one-man crew: no docking seat
	assert_int(SimPersonnel.crew_skill([pilot], "lm")).is_equal(3)
	assert_int(SimPersonnel.crew_skill([], "capsule")).is_equal(0)


func test_end_of_season_mood_components() -> void:
	var s := _new_state()                                   # spring: no 5% fall roll
	var p := s.player(0)
	_buy_capsule(s, p, 1)
	var idle := _make_active(p, "IDLE")
	var a := _make_active(p, "A", {}, 4)
	var b := _make_active(p, "B", {}, 5)
	var hero := _make_active(p, "H", {}, 6)
	SimPersonnel.make_hero(hero)
	SimPersonnel.assign_to_program(p, a, 1)
	SimPersonnel.assign_to_program(p, b, 1)
	SimPersonnel.assign_to_program(p, hero, 1)
	SimPersonnel.set_crew(p, 1, 0, [a, b])
	SimPersonnel.end_of_season(s, p)
	assert_int(idle.mood).is_equal(44)                      # -6 not in a crew
	assert_int(a.mood).is_equal(48)                         # +5 moved up, -4 moved, -3 in crew
	assert_int(hero.mood).is_equal(45)                      # +5 -4 -6
	SimPersonnel.start_of_season(s, p)
	SimPersonnel.set_crew(p, 1, 0, [hero, a])               # a (4, CL/CR 1) dislikes hero (6)
	SimPersonnel.end_of_season(s, p)
	assert_int(a.mood).is_equal(48 - 3 + 5 - 3)             # in crew, hero aboard, one conflict
	assert_int(hero.mood).is_equal(45 - 3 + 5 - 3)          # hero (6, range 5-7) dislikes a (4) too
	assert_int(b.mood).is_equal(48 - 6)
	p.turn_flags["program_first"] = true
	SimPersonnel.start_of_season(s, p)
	SimPersonnel.end_of_season(s, p)
	assert_int(b.mood).is_equal(42 + 5 - 6)


func test_mood_clamps_to_0_100() -> void:
	var s := _new_state()
	var p := s.player(0)
	var high := _make_active(p, "HIGH")
	high.mood = 100
	p.turn_flags["program_first"] = true
	SimPersonnel.end_of_season(s, p)
	assert_int(high.mood).is_equal(99)                      # +5 -6
	high.mood = 100
	SimPersonnel.start_advanced_training(s, p, high, "lm")  # +5 training mood at level 0
	SimPersonnel.end_of_season(s, p)
	assert_int(high.mood).is_equal(100)
	p.turn_flags.clear()
	var low := _make_active(p, "LOW")
	low.mood = 3
	SimPersonnel.end_of_season(s, p)
	assert_int(low.mood).is_equal(0)


func test_low_mood_retirement_timing_per_side() -> void:
	var s := _new_state()
	var usa := s.player(0)
	var ussr := s.player(1)
	var a := _make_active(usa, "A")
	var c := _make_active(ussr, "C")
	a.mood = 10
	c.mood = 10
	SimPersonnel.end_of_season(s, usa)
	SimPersonnel.end_of_season(s, ussr)
	assert_int(a.status).is_equal(Status.ACTIVE)
	assert_int(a.retire_in_seasons).is_equal(2)
	assert_str(a.retire_reason).is_equal("low morale")
	assert_int(c.status).is_equal(Status.RETIRED)
	assert_str(c.retire_reason).is_equal("low morale")
	SimPersonnel.start_of_season(s, usa)
	assert_int(a.status).is_equal(Status.ACTIVE)
	assert_int(a.retire_in_seasons).is_equal(1)
	SimPersonnel.start_of_season(s, usa)
	assert_int(a.status).is_equal(Status.RETIRED)
	assert_bool(a.is_alive()).is_false()
	assert_int(SimPersonnel.roster_summary(usa)["retired"]).is_equal(1)


func test_mustering_out_after_eighth_active_season() -> void:
	var retired_usa := 0
	var retired_ussr := 0
	for run in range(1, 80):
		var s := _new_state(run)
		for side in 2:
			var p := s.player(side)
			var a := _make_active(p, "A")
			a.seasons_active = 8
			var young := _make_active(p, "Y")
			young.seasons_active = 7
			var odd := _make_active(p, "O")
			odd.seasons_active = 9
			SimPersonnel.end_of_season(s, p)
			assert_int(young.retire_in_seasons).is_equal(-1)
			assert_int(odd.retire_in_seasons).is_equal(-1)
			if a.retire_in_seasons > 0:
				if side == 0:
					retired_usa += 1
					assert_int(a.retire_in_seasons).is_equal(3)
				else:
					retired_ussr += 1
					assert_int(a.retire_in_seasons).is_equal(2)
				var reasons: Array = data.text["news"]["retirement_reasons"][p.side].slice(0, 6)
				assert_bool(reasons.has(a.retire_reason)).is_true()
	assert_int(retired_usa).is_between(1, 30)
	assert_int(retired_ussr).is_between(1, 30)


func test_mission_outcome_effects() -> void:
	var s := _new_state()
	var p := s.player(0)
	_buy_capsule(s, p, 2)                                   # three-man capsule
	var a := _make_active(p, "A")
	var b := _make_active(p, "B")
	var c := _make_active(p, "C")
	for x in [a, b, c]:
		SimPersonnel.assign_to_program(p, x, 2)
	SimPersonnel.set_crew(p, 2, 0, [a, b, c])
	SimPersonnel.on_mission_outcome(s, p, a, "success", 5)
	assert_int(a.mood).is_equal(85)                         # +35 on astronaut level 0
	assert_int(a.missions_flown).is_equal(1)
	assert_array(a.mission_history).is_equal([{"year": 57, "season": 0, "mission_index": 5, "outcome": "success"}])
	p.astronaut_level = 1
	a.mood = 50
	SimPersonnel.on_mission_outcome(s, p, a, "success", 5)
	assert_int(a.mood).is_equal(80)
	SimPersonnel.on_mission_outcome(s, p, a, "scrubbed", 5)
	assert_int(a.mood).is_equal(75)
	assert_int(a.missions_flown).is_equal(2)
	SimPersonnel.on_mission_outcome(s, p, b, "injured", 5)
	assert_int(b.status).is_equal(Status.INJURED)
	assert_int(b.injured_until_seasons).is_equal(3)
	assert_int(b.program_slot).is_equal(-1)
	assert_bool(a.in_crew()).is_false()                     # crew dissolved
	assert_int(a.program_slot).is_equal(2)
	for i in 3:
		SimPersonnel.start_of_season(s, p)
	assert_int(b.status).is_equal(Status.ACTIVE)
	SimPersonnel.on_mission_outcome(s, p, c, "dead", 5)
	assert_int(c.status).is_equal(Status.DEAD)
	assert_str(c.death_reason).is_equal("mission")
	assert_bool(c.is_alive()).is_false()
	SimPersonnel.on_mission_outcome(s, p, a, "retired", 5)
	assert_int(a.retire_in_seasons).is_equal(1)
	assert_int(a.program_slot).is_equal(-1)
	SimPersonnel.start_of_season(s, p)
	assert_int(a.status).is_equal(Status.RETIRED)
	assert_str(a.retire_reason).is_equal("mission")
	var summary := SimPersonnel.roster_summary(p)
	assert_int(summary["dead"]).is_equal(1)
	assert_int(summary["retired"]).is_equal(1)
	assert_int(summary["active"]).is_equal(1)
	assert_int(summary["total"]).is_equal(3)


func test_season_counters() -> void:
	var s := _new_state()
	var p := s.player(0)
	_buy_capsule(s, p, 0)
	var a := _make_active(p, "A")
	SimPersonnel.assign_to_program(p, a, 0)
	for i in 6:
		SimPersonnel.start_of_season(s, p)
	assert_int(a.seasons_active).is_equal(6)
	assert_int(a.seasons_in_program).is_equal(6)
	assert_int(a.seasons_in_status).is_equal(6)
	assert_bool(a.moved_this_season).is_false()
	a.mood = 50
	SimPersonnel.end_of_season(s, p)
	assert_int(a.mood).is_equal(40)                         # -6 no crew, -4 six seasons in the one-man program
