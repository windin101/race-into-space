extends GdUnitTestSuite
## Annual review index, dismissal and director score.

var data: Node


func before() -> void:
	data = load("res://scripts/data/game_data.gd").new()
	add_child(data)
	data.load_all()


func after() -> void:
	data.queue_free()


func _state() -> SimState:
	var s := SimState.new(data, 1)
	s.year = 58
	return s


func _review_after(spring: int, fall: int, start_index := 8, level := 0) -> int:
	var s := _state()
	var p := s.player(0)
	p.level = level
	p.review_index = start_index
	s.player(1).review_index = 8
	p.prestige_history = [spring, fall]
	return SimReview.annual_review(s, p)["index"]


func test_index_moves_with_last_years_prestige() -> void:
	assert_int(_review_after(5, 5)).is_equal(7)          # 10: one step better
	assert_int(_review_after(10, 10)).is_equal(6)        # 20: two steps from 8
	assert_int(_review_after(20, 20)).is_equal(5)        # 40: three steps
	assert_int(_review_after(0, 0)).is_equal(10)         # zero is a step worse, then +1 trailing the rival
	assert_int(_review_after(1, 0)).is_equal(8)          # one is the only no-op
	assert_int(_review_after(-3, -2)).is_equal(10)       # -5, plus the rival bump
	assert_int(_review_after(-20, 5)).is_equal(10)       # mixed signs: 5/2 + -20 = -18, easy: +2
	assert_int(_review_after(-20, 5, 8, 2)).is_equal(12) # hard: +4
	assert_int(_review_after(-20, -20, 2)).is_equal(3)   # below 4 only +1 on a bad year
	assert_int(_review_after(30, 30, 1)).is_equal(1)     # clamped at 1


func test_worse_than_rival_adds_one() -> void:
	var s := _state()
	var p := s.player(0)
	p.prestige_history = [0, 0]
	s.player(1).review_index = 8
	assert_int(SimReview.annual_review(s, p)["index"]).is_equal(10)   # 9, then +1 for trailing


func test_text_index_by_side_and_dismissal_lines() -> void:
	var s := _state()
	assert_int(SimReview.text_index(s, s.player(0), 3)).is_equal(3)
	assert_int(SimReview.text_index(s, s.player(1), 3)).is_equal(21)
	assert_int(SimReview.text_index(s, s.player(0), 16)).is_equal(16)
	for i in 2:
		var a := SimAstronaut.new()
		a.status = SimAstronaut.Status.DEAD
		s.player(1).astronauts.append(a)
	assert_int(SimReview.text_index(s, s.player(1), 17)).is_equal(35)


func test_dismissal_requires_human_vs_ai_above_easy() -> void:
	var s := _state()
	var p := s.player(0)
	p.review_index = 16
	p.is_ai = false
	s.player(1).is_ai = true
	p.level = 0
	assert_bool(SimReview.dismissed(s, p)).is_false()
	p.level = 1
	assert_bool(SimReview.dismissed(s, p)).is_true()
	s.player(1).is_ai = false
	assert_bool(SimReview.dismissed(s, p)).is_false()
	p.review_index = 15
	s.player(1).is_ai = true
	assert_bool(SimReview.dismissed(s, p)).is_false()


func test_director_score_weights_and_landing_bonus() -> void:
	var s := _state()
	var p := s.player(0)
	p.mission_log = [{"prestige": {"total": 12}}, {"prestige": {"total": -7}}, {"prestige": {"total": 10}}]
	assert_int(SimReview.director_score(s, p)).is_equal(22)
	p.level = 1
	s.player(1).level = 0
	assert_int(SimReview.director_score(s, p)).is_equal(2 * 12 + 4 + 2 * 10 + 3)
	s.prestige_rows[22]["first"] = 0
	s.year = 66
	assert_int(SimReview.director_score(s, p)).is_equal(2 * 12 + 4 + 2 * 10 + 3 + 75)
