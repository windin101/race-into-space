extends GdUnitTestSuite
## constants.json is hand-transcribed from the upstream C++; these tests tie it to the
## generated tables so a mismatch between the two shows up immediately.

var data: Node


func before() -> void:
	data = load("res://scripts/data/game_data.gd").new()
	add_child(data)
	data.load_all()


func after() -> void:
	data.queue_free()


func test_constants_present() -> void:
	assert_dict(data.constants).is_not_empty()
	for key in ["prestige_rows", "milestones", "duration_levels", "lm_tests", "docking_module",
			"photo_recon", "rush", "budget", "difficulty", "rnd", "mission_roll",
			"mission_step_letters", "failure_codes", "crew", "astronauts", "calendar", "launch_pads"]:
		assert_dict(data.constants).override_failure_message("missing key " + key).contains_keys([key])


func test_prestige_row_names_align_with_table() -> void:
	var names: Array = data.constants["prestige_rows"]
	assert_int(names.size()).is_equal(28)
	for i in 28:
		var title: String = data.prestige[i]["title"]
		assert_str(names[i].to_upper().replace("-", " ")).override_failure_message(
			"row %d: '%s' vs '%s'" % [i, names[i], title]).is_equal(title.to_upper().replace("-", " "))


func test_every_mission_step_letter_is_defined() -> void:
	var letters: Dictionary = data.constants["mission_step_letters"]
	var regex := RegEx.new()
	# Strip joint-launch switches, duration/lab tokens, coast repeat counts and terminators.
	regex.compile("\\+[0-9]|@.|%.|~[0-9]|[\\^&!|]")
	for m in data.missions:
		if m["index"] == 0:
			continue
		var stripped: String = regex.sub(m["code"], "", true)
		for ch in stripped:
			assert_bool(letters.has(ch)).override_failure_message(
				"mission %d uses undefined step letter '%s' in %s" % [m["index"], ch, m["code"]]).is_true()


func test_manual_penalties() -> void:
	# Rules of Play: milestone skip -3 each, LM tests -3 per missing point (3 needed),
	# rush 3 MB and -3% per month for up to two months, docking starts at 40%.
	assert_int(data.constants["milestones"]["skip_penalty_per_milestone"]).is_equal(3)
	assert_int(data.constants["lm_tests"]["points_required"]).is_equal(3)
	assert_int(data.constants["lm_tests"]["penalty_per_missing_point"]).is_equal(3)
	assert_int(data.constants["rush"]["cost_mb_per_month"]).is_equal(3)
	assert_int(data.constants["rush"]["safety_penalty_per_month"]).is_equal(3)
	assert_int(data.constants["rush"]["max_months"]).is_equal(2)
	assert_int(data.constants["docking_module"]["base_safety"]).is_equal(40)
	assert_int(data.constants["photo_recon"]["base_safety"]).is_equal(55)


func test_duration_levels_are_contiguous() -> void:
	var ranges: Dictionary = data.constants["duration_levels"]["days_range"]
	var prev_end := 0
	for level in ["A", "B", "C", "D", "E", "F"]:
		var r: Array = ranges[level]
		assert_int(r[0]).override_failure_message("level " + level).is_equal(prev_end + 1)
		assert_int(r[1]).is_greater_equal(r[0])
		prev_end = r[1]
	assert_int(prev_end).is_equal(20)


func test_calendar_bounds() -> void:
	var cal: Dictionary = data.constants["calendar"]
	assert_int(cal["start"]["year"]).is_equal(57)
	assert_int(cal["start"]["season"]).is_equal(0)
	assert_int(cal["seasons_per_year"]).is_equal(2)
	assert_int(data.new_game["start_year"]).is_equal(1957)


func test_mission_crew_modes_are_documented() -> void:
	# crew_mode is an arrangement code 0-5 (see constants crew.mission_mCrew_field), not a head count.
	for m in data.missions:
		assert_int(m["crew_mode"]).override_failure_message("mission %d" % m["index"]).is_between(0, 5)
	var caps: Dictionary = data.constants["crew"]["capacity_by_hardware"]
	assert_int(caps["four_man_capsule"]).is_equal(4)
	assert_int(caps["one_man_capsule"]).is_equal(1)
