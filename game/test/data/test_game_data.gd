extends GdUnitTestSuite
## Asserts that every data table loads and that known values from the 1993 manual
## and the upstream port survived the import.

var data: Node


func before() -> void:
	data = load("res://scripts/data/game_data.gd").new()
	add_child(data)
	data.load_all()


func after() -> void:
	data.queue_free()


func test_all_files_load() -> void:
	assert_array(data.load_errors).is_empty()
	assert_bool(data.loaded).is_true()


func test_row_counts() -> void:
	assert_int(data.prestige.size()).is_equal(28)
	assert_int(data.missions.size()).is_equal(62)
	assert_int(data.failures.size()).is_equal(925)
	var candidates := 0
	for side in ["usa", "ussr"]:
		assert_int(data.roster["sides"][side].size()).is_equal(5)
		for group in data.roster["sides"][side]:
			candidates += group["candidates"].size()
	assert_int(candidates).is_equal(224)
	assert_int(data.text["events"]["usa"].size()).is_equal(117)
	assert_int(data.text["help"]["help"].size()).is_equal(289)
	assert_int(data.budget_adjustments["flat"].size()).is_equal(180)


func test_mission_indices_match_positions() -> void:
	for i in data.missions.size():
		assert_int(data.missions[i]["index"]).is_equal(i)


func test_manual_prestige_values() -> void:
	# Rules of Play p.28: Manned Lunar Landing 40/15/8/-10, Woman in Space 8/0/0/-4.
	var landing: Dictionary = data.prestige_row("manned_lunar_landing")
	assert_int(landing["first"]).is_equal(40)
	assert_int(landing["second"]).is_equal(15)
	assert_int(landing["other"]).is_equal(8)
	assert_int(landing["failure"]).is_equal(-10)
	var woman: Dictionary = data.prestige_row("woman_in_space")
	assert_int(woman["first"]).is_equal(8)
	assert_int(woman["failure"]).is_equal(-4)


func test_historical_hardware_matches_manual() -> void:
	# Reference card, Historical model: Atlas 26 MB, lift 500, Max R&D 87, Max Safety 98.
	var atlas: Dictionary = data.equipment("historical", "usa", "rocket", 0)
	assert_str(atlas["name"]).is_equal("ATLAS")
	assert_int(atlas["program_cost"]).is_equal(26)
	assert_int(atlas["max_payload"]).is_equal(500)
	assert_int(atlas["max_rd"]).is_equal(87)
	assert_int(atlas["max_safety"]).is_equal(98)
	# Soviet Kicker-C exists only on the USSR side.
	assert_object(data.equipment("historical", "usa", "misc", 2)).is_null()
	var kicker_c: Dictionary = data.equipment("historical", "ussr", "misc", 2)
	assert_str(kicker_c["name"]).is_equal("KICKER-C")
	assert_int(kicker_c["program_cost"]).is_equal(40)


func test_basic_model_is_symmetric() -> void:
	# Basic model: both sides share the same numbers, only names differ.
	for group in ["probe", "rocket", "manned", "misc"]:
		var usa: Array = data.hardware["models"]["basic"]["usa"][group]
		var ussr: Array = data.hardware["models"]["basic"]["ussr"][group]
		for slot in usa.size():
			if usa[slot] == null:
				assert_object(ussr[slot]).is_null()
				continue
			for field in ["base_safety", "program_cost", "unit_cost", "rd_cost_per_team", "max_rd", "max_safety"]:
				assert_int(usa[slot][field]).override_failure_message(
					"%s slot %d field %s" % [group, slot, field]).is_equal(ussr[slot][field])


func test_mission_code_terminators() -> void:
	for m in data.missions:
		if m["index"] == 0:
			continue
		assert_str(m["code"]).override_failure_message("mission %d" % m["index"]).ends_with("|")


func test_roster_group_sizes() -> void:
	var expected_pick := [7, 9, 14, 16, 14]
	var expected_delay := [6, 4, 4, 8, 99]
	for side in ["usa", "ussr"]:
		for i in 5:
			var g: Dictionary = data.roster["sides"][side][i]
			assert_int(g["number_to_choose"]).is_equal(expected_pick[i])
			assert_int(g["recruiting_delay"]).is_equal(expected_delay[i])
