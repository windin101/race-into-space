extends Node
## Exports the procedural portraits and hardware silhouettes as PNG source images for the
## AI restyling pass (tools/comfy_batch.py). Output goes under reference/art_source/,
## which is gitignored; the finished art lands in assets/art/ via the batch tool.
##
##   DISPLAY=:1 godot --path game res://tools/art_export.tscn -- --out ../reference/art_source

var _out := "../reference/art_source"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--out" and i + 1 < args.size():
			_out = args[i + 1]
	call_deferred("_run")


func _run() -> void:
	await get_tree().process_frame
	for sub in ["portraits", "hardware/usa", "hardware/ussr"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://%s/%s" % [_out, sub]))
	var count := 0
	for side in ["usa", "ussr"]:
		for group in GameData.roster["sides"][side]:
			for c in group["candidates"]:
				await _render(Vector2i(672, 800), "portraits/%s.png" % c["name"],
					func(canvas): PortraitArt.paint(canvas, Rect2(Vector2.ZERO, canvas.size), c["name"], c["female"], side, ""))
				count += 1
	for extra in [["MANKE", false, "usa"], ["POWELL", false, "usa"], ["YEAGER", false, "usa"], ["ILYUSHIN", false, "ussr"], ["KRAMARENKO", false, "ussr"], ["DOLGOV", false, "ussr"]]:
		await _render(Vector2i(672, 800), "portraits/%s.png" % extra[0],
			func(canvas): PortraitArt.paint(canvas, Rect2(Vector2.ZERO, canvas.size), extra[0], extra[1], extra[2], ""))
		count += 1
	for side in ["usa", "ussr"]:
		for group in SimProgram.GROUPS:
			var specs: Array = GameData.hardware["models"]["basic"][side][group]
			for slot in 7:
				if specs[slot] == null:
					continue
				await _render(Vector2i(1024, 1024), "hardware/%s/%s_%d.png" % [side, group, slot],
					func(canvas):
						canvas.draw_rect(Rect2(Vector2.ZERO, canvas.size), Color("1b2740"))
						HardwareArt.paint(canvas, Rect2(Vector2.ZERO, canvas.size).grow(-96), group, slot, side))
				count += 1
	# Portrait features as JSON so the text-to-image batch can describe each person.
	var features := {}
	for side in ["usa", "ussr"]:
		for group in GameData.roster["sides"][side]:
			for c in group["candidates"]:
				var f := PortraitArt.features(c["name"], c["female"])
				features[c["name"]] = _feature_words(f, c["female"], side)
	for extra in [["MANKE", false, "usa"], ["POWELL", false, "usa"], ["YEAGER", false, "usa"], ["ILYUSHIN", false, "ussr"], ["KRAMARENKO", false, "ussr"], ["DOLGOV", false, "ussr"]]:
		features[extra[0]] = _feature_words(PortraitArt.features(extra[0], extra[1]), extra[1], extra[2])
	var fa := FileAccess.open(ProjectSettings.globalize_path("res://%s/portrait_features.json" % _out), FileAccess.WRITE)
	fa.store_string(JSON.stringify(features, "  "))
	fa.close()
	print("exported %d images to %s" % [count, _out])
	get_tree().quit(0)


static func _feature_words(f: Dictionary, female: bool, side: String) -> Dictionary:
	var skin_words := ["fair", "light olive", "tan", "brown", "dark brown", "pale"]
	var hair_words := ["black", "dark brown", "brown", "light brown", "blond", "dark grey", "grey"]
	var style_words := ["short side-parted", "short swept-back", "full and thick", "cropped, receding"]
	var eye_words := ["brown", "blue", "green", "hazel"]
	return {
		"female": female, "side": side,
		"skin": skin_words[PortraitArt.SKINS.find(f["skin"])],
		"hair": hair_words[PortraitArt.HAIRS.find(f["hair"])],
		"hair_style": ("long, pinned up" if female else style_words[int(f["hair_style"])]),
		"eyes": eye_words[PortraitArt.EYES.find(f["eye"])],
		"glasses": f["glasses"], "moustache": f["moustache"],
		"face": "narrow" if f["jaw"] < 0.75 else ("square" if f["jaw"] > 0.85 else "oval"),
	}


func _render(size: Vector2i, rel: String, painter: Callable) -> void:
	var vp := SubViewport.new()
	vp.size = size
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var canvas := Control.new()
	canvas.size = Vector2(size)
	vp.add_child(canvas)
	canvas.draw.connect(func(): painter.call(canvas))
	for i in 2:
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://%s/%s" % [_out, rel]))
	vp.queue_free()
