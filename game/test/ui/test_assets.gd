extends GdUnitTestSuite
## Procedural art paints without error for every program and a range of names; audio
## assets exist, load and are all listed in the manifest.

var data: Node


func before() -> void:
	data = load("res://scripts/data/game_data.gd").new()
	add_child(data)
	data.load_all()


func after() -> void:
	data.queue_free()


func test_hardware_and_portrait_painters_cover_everything() -> void:
	var canvas := Control.new()
	canvas.size = Vector2(400, 400)
	add_child(canvas)
	var done := {}
	canvas.draw.connect(func():
		for side in ["usa", "ussr"]:
			for group in SimProgram.GROUPS:
				for slot in 7:
					HardwareArt.paint(canvas, Rect2(0, 0, 90, 90), group, slot, side)
			for grp in data.roster["sides"][side]:
				for c in grp["candidates"]:
					PortraitArt.paint(canvas, Rect2(0, 0, 84, 100), c["name"], c["female"], side, "")
			PortraitArt.paint(canvas, Rect2(0, 0, 84, 100), "X", false, side, "dead")
			var layout: Dictionary = data.ui_layout["spaceport"]
			var buildings: Array = []
			for b in layout["buildings"]:
				var e: Dictionary = b.duplicate()
				e["built"] = b["id"] != "museum"
				buildings.append(e)
			SpaceportArt.paint(canvas, canvas.size, side, buildings, [0, -1, 7], 1)
		done["ok"] = true)
	canvas.queue_redraw()
	await await_idle_frame()
	await await_idle_frame()
	assert_bool(done.has("ok")).is_true()
	canvas.queue_free()


func test_portraits_are_deterministic() -> void:
	var a := PortraitArt.features("GLENN", false)
	var b := PortraitArt.features("GLENN", false)
	assert_dict(a).is_equal(b)
	var c := PortraitArt.features("GRISSOM", false)
	assert_bool(a == c).is_false()
	assert_bool(PortraitArt.features("TERESHKOVA", true)["moustache"]).is_false()


func test_audio_assets_exist_and_load() -> void:
	for name in ["click", "back", "confirm", "flag", "launch", "explosion", "success", "failure", "first", "newscast"]:
		var path := "res://assets/audio/sfx/%s.ogg" % name
		assert_bool(ResourceLoader.exists(path)).override_failure_message("missing " + path).is_true()
		assert_object(load(path)).is_not_null()
	for name in ["title_theme", "spaceport_day", "mission"]:
		var path := "res://assets/audio/music/%s.ogg" % name
		assert_bool(ResourceLoader.exists(path)).override_failure_message("missing " + path).is_true()
		var s = load(path)
		assert_object(s).is_not_null()
		assert_float(s.get_length()).is_greater(30.0)


func test_manifest_lists_every_asset_file() -> void:
	var manifest := FileAccess.get_file_as_string("res://assets/MANIFEST.md")
	assert_str(manifest).is_not_empty()
	var missing: Array = []
	for path: String in _files("res://assets"):
		var rel: String = path.trim_prefix("res://assets/")
		if rel.ends_with(".import") or rel.ends_with(".md") or rel.ends_with(".txt"):
			continue
		if not manifest.contains(rel):
			missing.append(rel)
	assert_array(missing).override_failure_message("not in MANIFEST.md: " + str(missing)).is_empty()


func _files(dir_path: String) -> Array:
	var out: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full := dir_path.path_join(entry)
		if dir.current_is_dir():
			out.append_array(_files(full))
		else:
			out.append(full)
		entry = dir.get_next()
	return out
