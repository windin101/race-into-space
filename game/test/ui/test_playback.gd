extends GdUnitTestSuite
## Vignette coverage, playback sequencing, and a complete lunar landing playing through.

var data: Node


func before() -> void:
	data = load("res://scripts/data/game_data.gd").new()
	add_child(data)
	data.load_all()


func after() -> void:
	data.queue_free()


func test_every_step_letter_has_a_vignette_family() -> void:
	var letters: Dictionary = data.constants["mission_step_letters"]
	for letter in letters:
		if letter.begins_with("_"):
			continue
		assert_bool(Vignettes.FAMILY.has(letter)).override_failure_message("no vignette for " + letter).is_true()
		assert_bool(Vignettes.TITLES.has(Vignettes.family_for(letter))).is_true()
	# And every letter actually used in a mission code.
	var regex := RegEx.new()
	regex.compile("\\+[0-9]|@.|%.|~[0-9]|[\\^&!|]")
	for m in data.missions:
		for ch in regex.sub(m["code"], "", true):
			assert_bool(Vignettes.FAMILY.has(ch)).override_failure_message("mission %d letter %s" % [m["index"], ch]).is_true()


func test_every_family_paints_without_error() -> void:
	var canvas := Control.new()
	canvas.size = Vector2(640, 360)
	add_child(canvas)
	var painted := {}
	canvas.draw.connect(func():
		for letter in Vignettes.FAMILY:
			for t in [0.0, 0.3, 0.6, 0.9, 1.0]:
				for ok in [true, false]:
					Vignettes.paint(canvas, letter, t, ok, canvas.size, {"side_color": UiPalette.ACCENT_USA, "lunar": letter in "LOPQRST", "hardware_kind": "probe" if letter in "CUVWZe" else "capsule", "days": 8})
			painted["done"] = true)
	canvas.queue_redraw()
	await await_idle_frame()
	await await_idle_frame()
	assert_bool(painted.has("done")).is_true()
	canvas.queue_free()


func _lor_landing_result() -> Dictionary:
	var s := SimState.new(data, 5)
	var p := s.player(0)
	p.cash = 5000
	for pair in [["rocket", 2], ["manned", 2], ["manned", 5], ["misc", 4], ["misc", 3]]:
		var prog: SimProgram = p.program(pair[0], pair[1])
		SimHardware.buy_program(s, p, prog)
		prog.safety = 99
		prog.units = 3
	var crew: Array = []
	for i in 3:
		var a := SimAstronaut.new()
		a.id = i
		a.name = "A%d" % i
		a.status = SimAstronaut.Status.ACTIVE
		a.skills = {"capsule": 4, "lm": 4, "eva": 4, "docking": 4, "endurance": 4}
		p.astronauts.append(a)
		crew.append(a)
	var payload_1 := {"capsule": null, "lm": p.program("manned", 5), "kicker": null, "probe": null, "eva": null, "docking": p.program("misc", 4), "photo": p.program("misc", 5)}
	var payload_2 := {"capsule": p.program("manned", 2), "lm": null, "kicker": null, "probe": null, "eva": p.program("misc", 3), "docking": null, "photo": null}
	var launch := {"mission_index": 56, "player": 0, "pad": 0,
		"vehicles": [{"rocket": p.program("rocket", 2), "boosters": null, "payload": payload_1, "crew": []},
			{"rocket": p.program("rocket", 2), "boosters": null, "payload": payload_2, "crew": crew}],
		"duration_level": 4, "requirement_penalty": 0, "rush_penalty": 0, "lm_penalty": 0}
	var result := SimMission.fly(s, launch)
	result["prestige"] = SimPrestige.award(s, result)
	return {"state": s, "result": result}


func test_sequence_for_a_lunar_landing() -> void:
	var r := _lor_landing_result()
	var result: Dictionary = r["result"]
	var items := PlaybackScript.sequence(result, r["state"])
	var step_items := 0
	var firsts := 0
	for it in items:
		if it["kind"] == "step":
			step_items += 1
		if it["kind"] == "flash" and it["kicker"] == "FIRST":
			firsts += 1
	assert_int(step_items).is_equal(result["steps"].size())
	assert_str(items.back()["kind"]).is_equal("verdict")
	if result["outcome"] == "success":
		assert_int(firsts).is_greater(0)
	assert_float(PlaybackScript.total_seconds(items, 1.0)).is_greater(10.0)
	assert_float(PlaybackScript.total_seconds(items, 4.0)).is_less(PlaybackScript.total_seconds(items, 1.0))


func test_visible_launches_rule() -> void:
	var first := {"player": 1, "prestige": {"awards": [{"kind": "first", "row": 0, "points": 12}]}}
	var routine := {"player": 1, "prestige": {"awards": [{"kind": "other", "row": 0, "points": 1}]}}
	var mine := {"player": 0, "outcome": "failure", "prestige": {"awards": []}}
	var vis := PlaybackScript.visible_launches({"launches": [first, routine, mine]}, 0)
	assert_int(vis.size()).is_equal(2)
	assert_bool(vis.has(routine)).is_false()


func test_complete_lunar_landing_plays_without_gaps() -> void:
	Session.new_game(5, {"human_side": "usa"})
	var r := _lor_landing_result()
	var report := {"date": "Fall 1969", "launches": [r["result"]]}
	var scene: Control = load("res://scenes/playback/mission_playback.tscn").instantiate()
	add_child(scene)
	scene._set_speed(8.0)
	scene.setup({"report": report})
	var waited := 0.0
	while (scene._playing or scene._stage_letter == "") and waited < 60.0:
		await await_millis(100)
		waited += 0.1
	assert_bool(scene._playing).override_failure_message("playback did not finish in 60 s").is_false()
	assert_int(scene._chart.revealed).is_equal(r["result"]["steps"].size())
	assert_bool(scene._continue_btn.visible).is_true()
	scene.queue_free()


func test_mission_title_keeps_abbreviations() -> void:
	assert_str(PlaybackScript.mission_title("JT LUNAR LANDING: LOR")).is_equal("Joint Lunar Landing: LOR")
	assert_str(PlaybackScript.mission_title("MANNED ORBITAL EVA")).is_equal("Manned Orbital EVA")
	assert_str(PlaybackScript.mission_title("MANNED EARTH ORBITAL LM TEST")).is_equal("Manned Earth Orbital LM Test")
