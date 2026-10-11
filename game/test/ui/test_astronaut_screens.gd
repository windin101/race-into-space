extends GdUnitTestSuite
## Derived view logic of the Astronaut Complex and Training Centre screens: roster
## filtering and rows, seat/role labels, crew summaries, compatibility lines and the
## advanced-training cost and length text.

const Complex := preload("res://scenes/astronauts/astronaut_complex.gd")
const Training := preload("res://scenes/astronauts/training.gd")
const Status := SimAstronaut.Status

var data: Node


func before() -> void:
	data = load("res://scripts/data/game_data.gd").new()
	add_child(data)
	data.load_all()


func after() -> void:
	data.queue_free()


func _ast(name: String, status: int, skills := {}, compat := 5) -> SimAstronaut:
	var a := SimAstronaut.new()
	a.name = name
	a.status = status
	a.mood = 50
	a.compat = compat
	a.compat_left = 1
	a.compat_right = 1
	for k in skills:
		a.skills[k] = skills[k]
	return a


func _roster() -> Array:
	return [
		_ast("GLENN", Status.ACTIVE), _ast("SHEPARD", Status.BASIC_TRAINING),
		_ast("GRISSOM", Status.ADVANCED_TRAINING), _ast("COOPER", Status.INJURED),
		_ast("SLAYTON", Status.RETIRED), _ast("WHITE", Status.DEAD),
	]


func test_roster_filters() -> void:
	var roster := _roster()
	assert_int(Complex.filter_roster(roster, "all").size()).is_equal(6)
	var names := func(arr: Array) -> Array:
		var out: Array = []
		for a in arr:
			out.append(a.name)
		return out
	assert_array(names.call(Complex.filter_roster(roster, "active"))).is_equal(["GLENN"])
	assert_array(names.call(Complex.filter_roster(roster, "training"))).is_equal(["SHEPARD", "GRISSOM"])
	assert_array(names.call(Complex.filter_roster(roster, "injured"))).is_equal(["COOPER"])
	assert_array(names.call(Complex.filter_roster(roster, "retired"))).is_equal(["SLAYTON"])
	assert_array(names.call(Complex.filter_roster(roster, "dead"))).is_equal(["WHITE"])
	assert_array(Complex.filter_roster(roster, "bogus")).is_empty()


func test_status_and_crew_labels() -> void:
	var a := _ast("GRISSOM", Status.ADVANCED_TRAINING)
	a.training_focus = "docking"
	assert_str(Complex.status_title(a)).is_equal("Advanced Training (Docking)")
	assert_str(Complex.status_title(_ast("X", Status.BASIC_TRAINING))).is_equal("Basic Training")
	assert_str(Complex.crew_label(a)).is_equal("-")
	a.crew_index = 1
	a.crew_position = 0
	assert_str(Complex.crew_label(a)).is_equal("Crew 2, seat 1")


func test_roster_row_reads_program_from_player() -> void:
	var s := SimState.new(data, 3)
	var p := s.player(0)
	p.cash = 500
	var two_man := p.program("manned", 1)
	SimHardware.buy_program(s, p, two_man)
	var a := _ast("GLENN", Status.ACTIVE, {"capsule": 3, "endurance": 2})
	a.missions_flown = 2
	a.hero = true
	p.astronauts.append(a)
	var row := Complex.roster_row(a, p)
	assert_str(row["name"]).is_equal("Glenn")
	assert_str(row["program"]).is_equal("-")
	assert_bool(SimPersonnel.assign_to_program(p, a, 1)).is_true()
	row = Complex.roster_row(a, p)
	assert_str(row["program"]).is_equal(two_man.display_name().capitalize())
	assert_int(row["capsule"]).is_equal(3)
	assert_int(row["endurance"]).is_equal(2)
	assert_int(row["missions_flown"]).is_equal(2)
	assert_str(row["hero"]).is_equal("Hero")


func test_seat_labels_follow_role_slots_table() -> void:
	var table: Dictionary = data.constants["crew"]["role_slots_by_crew_size"]
	assert_array(Complex.seat_labels(1, table)).is_equal(["Commander: Capsule / LM / EVA"])
	assert_array(Complex.seat_labels(2, table)).is_equal(["Commander: Capsule / Docking", "Seat 2: LM / EVA"])
	assert_array(Complex.seat_labels(3, table)).is_equal(["Commander: Capsule", "Seat 2: LM / EVA", "Seat 3: Docking"])
	assert_array(Complex.seat_labels(4, table)).is_equal(["Commander: Capsule", "Seat 2: LM", "Seat 3: EVA", "Seat 4: Docking"])
	# module default when the table is missing
	assert_array(Complex.seat_labels(2)).is_equal(["Commander: Capsule / Docking", "Seat 2: LM / EVA"])


func test_crew_summary_counts_conflicts_and_role_skills() -> void:
	var s := SimState.new(data, 3)
	var table: Dictionary = data.constants["crew"]["role_slots_by_crew_size"]
	var cdr := _ast("A", Status.ACTIVE, {"capsule": 3, "docking": 2, "endurance": 1}, 5)
	var pilot := _ast("B", Status.ACTIVE, {"lm": 4, "eva": 1, "endurance": 2}, 5)
	assert_str(Complex.crew_summary([], 2, s, table)).is_equal("No seats filled.")
	assert_str(Complex.crew_summary([cdr], 2, s, table)).is_equal("0 conflicts.  1 of 2 seats filled.")
	var full := Complex.crew_summary([cdr, pilot], 2, s, table)
	assert_str(full).contains("0 conflicts")
	assert_str(full).contains("Cap 3")
	assert_str(full).contains("LM 4")
	assert_str(full).contains("EVA 1")
	assert_str(full).contains("Dock 2")
	assert_str(full).contains("End 2")     # (1 + 2) / 2 rounded to nearest
	# a one-man capsule has no docking seat
	assert_str(Complex.crew_summary([cdr], 1, s, table)).contains("Dock -")
	# an incompatible pair is flagged
	var loner := _ast("C", Status.ACTIVE, {}, 1)
	assert_int(SimPersonnel.crew_conflicts([cdr, loner])).is_greater(0)
	assert_str(Complex.crew_summary([cdr, loner], 2, s, table)).starts_with("2 conflicts")


func test_compat_lines_report_both_directions() -> void:
	var a := _ast("GLENN", Status.ACTIVE, {}, 5)
	var b := _ast("SHEPARD", Status.ACTIVE, {}, 5)
	var c := _ast("COOPER", Status.ACTIVE, {}, 1)
	assert_array(Complex.compat_lines(a, [a, b])).is_equal(["Shepard: get on"])
	assert_array(Complex.compat_lines(a, [a, c])).is_equal(["Cooper: mutual dislike"])
	c.compat_left = 2
	c.compat_right = 2
	c.compat = 3     # c likes 1..5 so c likes a (5); a likes 4..6 so a dislikes c
	assert_array(Complex.compat_lines(a, [c])).is_equal(["Cooper: Glenn dislikes Cooper"])


func test_history_lines_name_missions() -> void:
	var a := _ast("GLENN", Status.ACTIVE)
	a.mission_history.append({"year": 62, "season": SimState.SEASON_SPRING, "mission_index": 1, "outcome": "success"})
	var lines := Complex.history_lines(a, data.missions)
	assert_int(lines.size()).is_equal(1)
	assert_str(lines[0]).starts_with("Spring 1962  ")
	assert_str(lines[0]).contains(str(data.missions[1]["name"]))
	assert_str(lines[0]).ends_with(": success")


func test_enrol_terms_follow_the_rules() -> void:
	var c: Dictionary = data.constants
	var t := Training.enrol_terms(0, false, c)
	assert_bool(t["ok"]).is_true()
	assert_int(t["cost"]).is_equal(3)
	assert_int(t["seasons"]).is_equal(4)
	assert_str(t["text"]).starts_with("3 MB for 4 seasons; raises the skill from 0 to 2.")
	t = Training.enrol_terms(2, true, c)
	assert_int(t["cost"]).is_equal(3)
	assert_int(t["seasons"]).is_equal(3)
	assert_str(t["text"]).contains("from 2 to 4")
	t = Training.enrol_terms(3, false, c)
	assert_int(t["cost"]).is_equal(2)
	assert_int(t["seasons"]).is_equal(2)
	assert_str(t["text"]).contains("from 3 to 4")
	t = Training.enrol_terms(3, true, c)      # the short option does not shorten the late entry
	assert_int(t["seasons"]).is_equal(2)
	t = Training.enrol_terms(4, false, c)
	assert_bool(t["ok"]).is_false()
	assert_str(t["text"]).contains("maximum")
	# defaults without a constants table match the module constants
	t = Training.enrol_terms(1, false)
	assert_int(t["cost"]).is_equal(SimPersonnel.ADVANCED_COST)
	assert_int(t["seasons"]).is_equal(SimPersonnel.ADVANCED_SEASONS)


func test_enrol_candidates_and_training_rows() -> void:
	var roster := _roster()
	var crewed := _ast("CARPENTER", Status.ACTIVE)
	crewed.program_slot = 1
	crewed.crew_index = 0
	crewed.crew_position = 0
	var pooled := _ast("SCHIRRA", Status.ACTIVE)
	pooled.program_slot = 1
	roster.append_array([crewed, pooled])
	var names: Array = []
	for a in Training.enrol_candidates(roster):
		names.append(a.name)
	assert_array(names).is_equal(["GLENN", "SCHIRRA"])
	assert_int(Training.by_status(roster, Status.ACTIVE).size()).is_equal(3)
	var trainee := _ast("GRISSOM", Status.ADVANCED_TRAINING, {"eva": 2})
	trainee.training_focus = "eva"
	trainee.training_seasons_left = 3
	var row := Training.training_row(trainee)
	assert_str(row["focus"]).is_equal("EVA")
	assert_int(row["left"]).is_equal(3)
	assert_int(row["eva"]).is_equal(2)
	var hurt := _ast("COOPER", Status.INJURED)
	hurt.injured_until_seasons = 2
	assert_int(Training.medical_row(hurt)["left"]).is_equal(2)
	assert_str(Training.medical_row(hurt)["focus"]).is_equal("-")
