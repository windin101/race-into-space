extends Node
## Renders a contact sheet of every vignette family (success at t=0.55, failure at
## t=0.9) and a mid-flight frame of the playback screen, for visual review.
##
##   DISPLAY=:1 godot --path game res://tools/playback_capture.tscn -- --out ../docs/screens/phase5

var _out := "../docs/screens/phase5"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--out" and i + 1 < args.size():
			_out = args[i + 1]
	call_deferred("_run")


func _run() -> void:
	await get_tree().process_frame
	Session.new_game(5, {"human_side": "usa"})
	get_tree().root.theme = UiTheme.get_theme("usa")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + _out))
	await _contact_sheet()
	await _playback_frame()
	get_tree().quit(0)


func _contact_sheet() -> void:
	var families: Array = []
	var seen := {}
	for letter in Vignettes.FAMILY:
		var fam: String = Vignettes.FAMILY[letter]
		if not seen.has(fam):
			seen[fam] = letter
			families.append(letter)
	var tile := Vector2(480, 270)
	var cols := 4
	var rows := int(ceil(families.size() * 2.0 / cols))
	var vp := SubViewport.new()
	vp.size = Vector2i(int(tile.x * cols), int(tile.y * rows))
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var canvas := Control.new()
	canvas.size = Vector2(vp.size)
	vp.add_child(canvas)
	canvas.draw.connect(func():
		var i := 0
		for letter in families:
			for variant in [[0.55, true], [0.9, false]]:
				var pos := Vector2(tile.x * (i % cols), tile.y * (i / cols))
				canvas.draw_set_transform(pos)
				Vignettes.paint(canvas, letter, variant[0], variant[1], tile, {"side_color": UiPalette.ACCENT_USA if i % 4 < 2 else UiPalette.ACCENT_USSR, "lunar": letter in "LOPQRSTa", "hardware_kind": "probe" if letter in "CUVWZe" else "capsule", "days": 8, "ringed": letter == "W"})
				var label := "%s (%s) %s" % [Vignettes.title_for(letter), letter, "ok" if variant[1] else "FAIL"]
				canvas.draw_string(canvas.get_theme_default_font(), Vector2(10, tile.y - 12), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UiPalette.TEXT)
				canvas.draw_set_transform(Vector2.ZERO)
				canvas.draw_rect(Rect2(pos, tile), UiPalette.BORDER, false, 1.0)
				i += 1)
	for i in 3:
		await get_tree().process_frame
	var file := "%s/vignettes.png" % _out
	vp.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://" + file))
	print("saved " + file)
	vp.queue_free()


func _playback_frame() -> void:
	# A real lunar landing result, then a frame a few steps in.
	var s := Session.state()
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
		a.name = ["Armstrong", "Aldrin", "Collins"][i]
		a.status = SimAstronaut.Status.ACTIVE
		a.skills = {"capsule": 4, "lm": 4, "eva": 4, "docking": 4, "endurance": 4}
		p.astronauts.append(a)
		crew.append(a)
	var launch := {"mission_index": 56, "player": 0, "pad": 0,
		"vehicles": [{"rocket": p.program("rocket", 2), "boosters": null, "payload": {"capsule": null, "lm": p.program("manned", 5), "kicker": null, "probe": null, "eva": null, "docking": p.program("misc", 4), "photo": p.program("misc", 5)}, "crew": []},
			{"rocket": p.program("rocket", 2), "boosters": null, "payload": {"capsule": p.program("manned", 2), "lm": null, "kicker": null, "probe": null, "eva": p.program("misc", 3), "docking": null, "photo": null}, "crew": crew}],
		"duration_level": 4, "requirement_penalty": 0, "rush_penalty": 0, "lm_penalty": 0}
	var result := SimMission.fly(s, launch)
	result["prestige"] = SimPrestige.award(s, result)
	var vp := SubViewport.new()
	vp.size = Vector2i(1920, 1080)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var scene: Control = load("res://scenes/playback/mission_playback.tscn").instantiate()
	scene.theme = UiTheme.get_theme("usa")
	vp.add_child(scene)
	scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	scene._set_speed(1.0)
	scene.setup({"report": {"date": "Fall 1969", "launches": [result]}})
	var shots := [[5.0, "playback_launch"], [20.0, "playback_mid"], [34.0, "playback_late"]]
	var elapsed := 0.0
	for shot in shots:
		while elapsed < shot[0]:
			await get_tree().process_frame
			elapsed += get_process_delta_time()
		var file := "%s/%s.png" % [_out, shot[1]]
		vp.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://" + file))
		print("saved " + file)
	vp.queue_free()
