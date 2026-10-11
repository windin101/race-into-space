extends GdUnitTestSuite
## Derived view logic of the Administration screens: mission filtering and step lists
## (Future Missions), graph ranges and the summary table (Budget Office), recruit stat
## visibility and pick rows (Recruiting), office titles (Administration).

const FutureMissions := preload("res://scenes/admin/future_missions.gd")
const BudgetOffice := preload("res://scenes/admin/budget_office.gd")
const Recruiting := preload("res://scenes/admin/recruiting.gd")
const Administration := preload("res://scenes/admin/administration.gd")

var data: Node


func before() -> void:
	data = load("res://scripts/data/game_data.gd").new()
	add_child(data)
	data.load_all()


func after() -> void:
	data.queue_free()


func _letters() -> Dictionary:
	return data.constants.get("mission_step_letters", {})


# --- Future Missions --------------------------------------------------------------

func test_default_filters_list_every_plannable_mission() -> void:
	var got := FutureMissions.filter_missions(data.missions, FutureMissions.DEFAULT_FILTERS)
	assert_int(got.size()).is_equal(57)
	assert_int(got[0]).is_equal(1)
	assert_int(got[-1]).is_equal(57)


func test_manned_unmanned_filters_partition_the_list() -> void:
	var manned := FutureMissions.filter_missions(data.missions, {"manned": true, "unmanned": false})
	var unmanned := FutureMissions.filter_missions(data.missions, {"manned": false, "unmanned": true})
	assert_int(manned.size() + unmanned.size()).is_equal(57)
	for mi in manned:
		assert_bool(FutureMissions.is_manned(data.missions[mi])).is_true()
	for mi in unmanned:
		assert_bool(FutureMissions.is_manned(data.missions[mi])).is_false()
	assert_bool(manned.has(2)).is_true()      # Manned Suborbital
	assert_bool(unmanned.has(1)).is_true()    # Orbital Satellite
	assert_bool(unmanned.has(3)).is_true()    # Unmanned Suborbital has a capsule but no crew


func test_flag_filters_require_the_flag() -> void:
	for key in ["lunar", "docking", "eva", "joint"]:
		var filters := FutureMissions.DEFAULT_FILTERS.duplicate()
		filters[key] = true
		var got := FutureMissions.filter_missions(data.missions, filters)
		assert_array(got).is_not_empty()
		for mi in got:
			assert_int(int(data.missions[mi][key])).is_equal(1)
	var both := FutureMissions.DEFAULT_FILTERS.duplicate()
	both["joint"] = true
	both["eva"] = true
	for mi in FutureMissions.filter_missions(data.missions, both):
		assert_int(int(data.missions[mi]["joint"]) + int(data.missions[mi]["eva"])).is_equal(2)


func test_step_list_reads_the_main_path_only() -> void:
	var lines := FutureMissions.step_list("ADE!|", false, false, _letters())
	assert_array(lines).is_equal(["1. Launch", "2. Reentry", "3. Recovery/landing"])
	# Alternate branch after '!' and 'd' markers are not part of the plan.
	var landing: Dictionary = data.missions[53]
	var main := FutureMissions.step_list(landing["code"], true, false, _letters())
	assert_int(main.size()).is_equal(landing["code"].find("!"))
	for l in main:
		assert_bool(l.contains("Corridor")).is_false()


func test_step_list_collapses_coasts_and_names_joint_pads() -> void:
	var jupiter := FutureMissions.step_list("ABZ~6eVW!|", false, false, _letters())
	assert_int(jupiter.size()).is_equal(6)
	assert_str(jupiter[3]).is_equal("4. Mid-course Corr. Burn  x6")
	var mars := FutureMissions.step_list("ABZ~1eVW!|", false, false, _letters())
	assert_str(mars[3]).is_equal("4. Mid-course Corr. Burn")
	var joint := FutureMissions.step_list("+1ABC+2ABF+1I!|", false, true, _letters())
	assert_str(joint[0]).is_equal("1. Pad A: Launch")
	assert_str(joint[3]).is_equal("4. Pad B: Launch")
	assert_str(joint[6]).is_equal("7. Pad A: Docking")    # 'I' always returns to the primary pad


func test_duration_text_and_options() -> void:
	assert_str(FutureMissions.duration_text(data.missions[1])).is_equal("-")
	assert_str(FutureMissions.duration_text(data.missions[2])).is_equal("A")
	assert_str(FutureMissions.duration_text(data.missions[25])).is_equal("B+")
	var ranges: Dictionary = data.constants["duration_levels"]["days_range"]
	var opts := FutureMissions.duration_options(data.missions[25], ranges)
	assert_int(opts.size()).is_equal(5)
	assert_int(opts[0]["level"]).is_equal(2)
	assert_str(opts[0]["label"]).is_equal("B  (3-5 days)")
	assert_int(opts[-1]["level"]).is_equal(6)
	assert_array(FutureMissions.duration_options(data.missions[2], ranges)).is_empty()


func test_title_case_keeps_abbreviations() -> void:
	assert_str(FutureMissions.title_case("JT MANNED ORBITAL DOCKING (ORBIT) EVA")).is_equal("JT Manned Orbital Docking (Orbit) EVA")
	assert_str(FutureMissions.title_case("HISTORICAL L.L.")).is_equal("Historical L.L.")
	assert_str(FutureMissions.flags_text(data.missions[53])).is_equal("Docking, EVA, LM, Lunar")
	assert_str(FutureMissions.flags_text(data.missions[1])).is_equal("-")
	assert_str(FutureMissions.meta_text(data.missions[1])).is_equal("ORBITAL SATELLITE   Unmanned")
	assert_str(FutureMissions.meta_text(data.missions[25])).is_equal("ORBITAL-X   Crew   Duration B+")


func test_hardware_and_penalty_lines() -> void:
	var s := SimState.new(data, 5)
	var p := s.player(0)
	var m: Dictionary = data.missions[1]
	var plan := FutureMissions.trial_plan(m, 1, 0, 0)
	assert_int(plan["duration"]).is_equal(0)
	assert_bool(plan["joint"]).is_false()
	var missing := FutureMissions.hardware_lines(SimPlanner.assemble(s, p, plan))
	assert_int(missing.size()).is_equal(1)
	assert_bool(missing[0].begins_with("Cannot assemble: ")).is_true()
	p.cash = 5000
	for spec in [["probe", 0], ["rocket", 0]]:
		var prog: SimProgram = p.program(spec[0], spec[1])
		SimHardware.buy_program(s, p, prog)
		prog.units = 1
		prog.safety = 80
	var launch := SimPlanner.assemble(s, p, plan)
	var lines := FutureMissions.hardware_lines(launch)
	assert_int(lines.size()).is_equal(2)
	assert_bool(lines[0].contains("(80%)")).is_true()
	var pen := FutureMissions.penalty_lines(SimPlanner.requirement_penalty(s, p, 1, 0))
	assert_int(pen.size()).is_equal(4)
	assert_str(pen[3]).is_equal("Total on every step: -0%")
	var lm_pen := FutureMissions.penalty_lines({"milestone": 6, "duration": 5, "new_mission": 2, "total": 13, "lm": 9, "skipped_milestones": 2})
	assert_int(lm_pen.size()).is_equal(5)
	assert_str(lm_pen[0]).is_equal("Milestones skipped: 2  (-6%)")


func test_pad_status_reports_plans_and_reservations() -> void:
	var s := SimState.new(data, 5)
	var p := s.player(0)
	assert_str(FutureMissions.pad_status(p, 0, data.missions)).is_equal("no plan")
	assert_str(FutureMissions.pad_status(p, 1, data.missions)).is_equal("not built")
	p.pads[1] = SimPlayer.PAD_OK
	assert_bool(SimPlanner.plan(s, p, 16, 0)).is_true()     # joint docking reserves pad 2
	assert_str(FutureMissions.pad_status(p, 0, data.missions)).is_equal(FutureMissions.title_case(data.missions[16]["abbr"]))
	assert_str(FutureMissions.pad_status(p, 1, data.missions)).is_equal("joint from pad 1")
	p.pads[2] = 5
	assert_str(FutureMissions.pad_status(p, 2, data.missions)).is_equal("damaged")


# --- Budget Office ----------------------------------------------------------------

func test_graph_range_includes_zero_and_rounds_to_nice_steps() -> void:
	var empty := BudgetOffice.graph_range([])
	assert_float(empty["min"]).is_equal(0.0)
	assert_float(empty["max"]).is_equal(1.0)
	assert_float(empty["step"]).is_equal(1.0)     # integer data: never label fractions
	var pos := BudgetOffice.graph_range([3, 17, 42], 4)
	assert_float(pos["min"]).is_equal(0.0)
	assert_float(pos["step"]).is_equal(20.0)
	assert_float(pos["max"]).is_equal(60.0)
	var neg := BudgetOffice.graph_range([-7, 12], 4)
	assert_float(neg["min"]).is_equal(-10.0)
	assert_float(neg["max"]).is_equal(15.0)
	assert_float(neg["step"]).is_equal(5.0)
	assert_float(BudgetOffice.nice_step(0.3)).is_equal(0.5)
	assert_float(BudgetOffice.nice_step(30.0)).is_equal(50.0)
	assert_float(BudgetOffice.nice_step(100.0)).is_equal(100.0)


func test_x_labels_and_season_names() -> void:
	assert_int(BudgetOffice.x_label_stride(6, 10)).is_equal(2)
	assert_int(BudgetOffice.x_label_stride(40, 10)).is_equal(4)
	assert_str(BudgetOffice.season_label(0)).is_equal("Spr '57")
	assert_str(BudgetOffice.season_label(3)).is_equal("Fall '58")


func test_summary_rows_follow_the_players() -> void:
	var s := SimState.new(data, 5)
	s.player(0).cash = 123
	s.player(1).prestige_total = 45
	var rows := BudgetOffice.summary_rows(s)
	assert_int(rows.size()).is_equal(6)
	assert_int(rows[0]["usa"]).is_equal(123)
	assert_int(rows[4]["ussr"]).is_equal(45)
	assert_int(rows[5]["usa"]).is_equal(SimReview.director_score(s, s.player(0)))


# --- Recruiting -------------------------------------------------------------------

func test_visible_skills_follow_the_astronaut_level() -> void:
	assert_array(Recruiting.visible_skills(0)).is_equal(["capsule", "lm", "eva", "docking", "endurance"])
	assert_array(Recruiting.visible_skills(1)).is_equal(["capsule", "docking", "endurance"])
	assert_array(Recruiting.visible_skills(2)).is_equal(["capsule", "endurance"])


func test_candidate_rows_mark_picks_and_hide_stats() -> void:
	var s := SimState.new(data, 5)
	var p := s.player(0)
	var pool := SimPersonnel.available_recruits(s, p)
	assert_array(pool).is_not_empty()
	var rows := Recruiting.candidate_rows(pool, [pool[1]["name"]], 2)
	assert_int(rows.size()).is_equal(pool.size())
	assert_str(rows[0]["pick"]).is_equal(Recruiting.UNPICK_MARK)
	assert_str(rows[1]["pick"]).is_equal(Recruiting.PICK_MARK)
	assert_bool(rows[0].has("capsule")).is_true()
	assert_bool(rows[0].has("lm")).is_false()
	assert_str(rows[0]["_name"]).is_equal(pool[0]["name"])
	var full := Recruiting.candidate_rows(pool, [], 0)
	assert_int(full[0]["lm"]).is_equal(int(pool[0]["lm"]))


# --- Administration ---------------------------------------------------------------

func test_office_titles_by_side() -> void:
	var recruiting: Dictionary = Administration.OFFICES[3]
	assert_str(Administration.office_title(recruiting, "usa")).is_equal("Astronaut Recruiting")
	assert_str(Administration.office_title(recruiting, "ussr")).is_equal("Cosmonaut Recruiting")
	assert_str(Administration.office_title(Administration.OFFICES[0], "ussr")).is_equal("Budget Office")
	for office in Administration.OFFICES:
		assert_str(UiHelp.text_for(office["help"])).is_not_empty()
