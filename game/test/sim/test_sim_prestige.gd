extends GdUnitTestSuite
## Prestige award logic against synthetic mission results.

var data: Node


func before() -> void:
	data = load("res://scripts/data/game_data.gd").new()
	add_child(data)
	data.load_all()


func after() -> void:
	data.queue_free()


func _state() -> SimState:
	return SimState.new(data, 1)


func _result(player: int, goals: Array, manned := true, deaths := 0) -> Dictionary:
	return {"player": player, "mission_index": 1, "manned": manned, "goals": goals, "deaths": deaths}


func test_first_satellite_pays_12_and_sets_milestone() -> void:
	var s := _state()
	var r := SimPrestige.award(s, _result(0, [{"row": 0, "success": true}], false))
	assert_int(r["total"]).is_equal(12)
	assert_int(s.player(0).prestige).is_equal(12)
	assert_int(s.prestige_rows[0]["first"]).is_equal(0)
	assert_int(s.player(0).milestones[0]).is_equal(1)
	assert_int(s.player(1).milestones[0]).is_equal(0)


func test_second_nation_pays_second_column_once() -> void:
	var s := _state()
	SimPrestige.award(s, _result(0, [{"row": 0, "success": true}], false))
	var r := SimPrestige.award(s, _result(1, [{"row": 0, "success": true}], false))
	assert_int(r["total"]).is_equal(5)
	assert_int(s.prestige_rows[0]["second"]).is_equal(1)
	assert_int(s.player(1).milestones[0]).is_equal(1)
	# Third flight: only the trickle award, and only while the mission total is below 3.
	var r3 := SimPrestige.award(s, _result(0, [{"row": 0, "success": true}], false))
	assert_int(r3["total"]).is_equal(1)


func test_manned_first_adds_manned_space_mission_row() -> void:
	var s := _state()
	# First manned orbital: row 18 (12) + row 27 Manned Space Mission (15) = 27, as in
	# the manual's Gagarin example; row 0 is marked done by the chain without payment.
	var r := SimPrestige.award(s, _result(1, [{"row": 18, "success": true}]))
	assert_int(r["total"]).is_equal(27)
	assert_int(s.prestige_rows[0]["first"]).is_equal(1)
	assert_int(s.player(1).milestones[2]).is_equal(1)
	assert_int(s.player(1).milestones[1]).is_equal(1)


func test_lunar_landing_chain_and_value() -> void:
	var s := _state()
	var r := SimPrestige.award(s, _result(0, [{"row": 22, "success": true}, {"row": 15, "success": true}]))
	# 40 landing + 15 three-person craft + 15 manned space mission.
	assert_int(r["total"]).is_equal(70)
	for row in [20, 19, 7, 1, 18, 0]:
		assert_int(s.prestige_rows[row]["first"]).override_failure_message("row %d" % row).is_equal(0)
	assert_array(s.player(0).milestones).is_equal([1, 1, 1, 1, 1, 1, 1, 1])


func test_failure_pays_penalty_once_and_floors() -> void:
	var s := _state()
	var r := SimPrestige.award(s, _result(0, [{"row": 18, "success": false}, {"row": 27, "success": false}]))
	assert_int(r["total"]).is_equal(-7)      # -10 for the row, floored at -7 without a death
	var r2 := SimPrestige.award(s, _result(0, [{"row": 22, "success": true}], true, 1))
	assert_int(r2["total"]).is_equal(-10)    # death turns success into failure, floor -10
	assert_int(s.prestige_rows[22]["first"]).is_equal(-1)


func test_duration_chain() -> void:
	var s := _state()
	var r := SimPrestige.award(s, _result(0, [{"row": 10, "success": true}]))
	assert_int(r["total"]).is_equal(1 + 15)
	assert_int(s.prestige_rows[11]["first"]).is_equal(0)
	assert_int(s.prestige_rows[12]["first"]).is_equal(0)
	assert_int(s.prestige_rows[9]["first"]).is_equal(-1)
