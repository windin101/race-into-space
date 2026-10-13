extends Node
## Renders the procedural art for review: both spaceports at 3840x2160, a hardware sheet
## and a portrait sheet, into docs/screens/phase7.
##
##   DISPLAY=:1 godot --path game res://tools/art_capture.tscn -- --out ../docs/screens/phase7

var _out := "../docs/screens/phase7"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--out" and i + 1 < args.size():
			_out = args[i + 1]
	call_deferred("_run")


func _run() -> void:
	await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + _out))
	for side in Sides.ids():
		await _spaceport(side)
	await _hardware_sheet()
	await _portrait_sheet()
	get_tree().quit(0)


func _save(vp: SubViewport, name: String) -> void:
	for i in 3:
		await get_tree().process_frame
	var file := "%s/%s.png" % [_out, name]
	vp.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://" + file))
	print("saved " + file)
	vp.queue_free()


func _viewport(size: Vector2i) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = size
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	return vp


func _spaceport(side: String) -> void:
	var vp := _viewport(Vector2i(3840, 2160))
	var canvas := Control.new()
	canvas.size = Vector2(vp.size)
	vp.add_child(canvas)
	var layout: Dictionary = GameData.ui_layout.get("spaceport", {})
	var buildings: Array = []
	for b in layout.get("buildings", []):
		var e: Dictionary = b.duplicate()
		e["built"] = true
		buildings.append(e)
	canvas.draw.connect(func(): SpaceportArt.paint(canvas, canvas.size, side, buildings, [0, 0, 7], 0))
	await _save(vp, "spaceport_" + side)


func _hardware_sheet() -> void:
	var tile := Vector2(220, 220)
	var vp := _viewport(Vector2i(int(tile.x * 7), int(tile.y * 8)))
	var canvas := Control.new()
	canvas.size = Vector2(vp.size)
	vp.add_child(canvas)
	canvas.draw.connect(func():
		canvas.draw_rect(Rect2(Vector2.ZERO, canvas.size), UiPalette.PANEL)
		var row := 0
		for side in Sides.ids():
			for group in SimProgram.GROUPS:
				var specs: Array = GameData.hardware["models"]["basic"][side][group]
				for slot in 7:
					var r := Rect2(Vector2(tile.x * slot, tile.y * row), tile)
					canvas.draw_rect(r, UiPalette.BORDER_SOFT, false, 1.0)
					if specs[slot] == null:
						continue
					HardwareArt.paint(canvas, r.grow(-20), group, slot, side)
					canvas.draw_string(canvas.get_theme_default_font(), r.position + Vector2(8, tile.y - 10), str(specs[slot]["name"]).capitalize(), HORIZONTAL_ALIGNMENT_LEFT, tile.x - 16, 16, UiPalette.TEXT)
				row += 1)
	await _save(vp, "hardware_sheet")


func _portrait_sheet() -> void:
	var tile := Vector2(140, 170)
	var cols := 8
	var names: Array = []
	for side in Sides.ids():
		for group in GameData.roster["sides"][side].slice(0, 2):
			for c in group["candidates"].slice(0, 8):
				names.append([c["name"], c["female"], side])
	var rows := int(ceil(names.size() / float(cols)))
	var vp := _viewport(Vector2i(int(tile.x * cols), int(tile.y * rows)))
	var canvas := Control.new()
	canvas.size = Vector2(vp.size)
	vp.add_child(canvas)
	canvas.draw.connect(func():
		canvas.draw_rect(Rect2(Vector2.ZERO, canvas.size), UiPalette.PANEL)
		for i in names.size():
			var r := Rect2(Vector2(tile.x * (i % cols), tile.y * (i / cols)), tile)
			var status := "dead" if i == 3 else ("retired" if i == 7 else "")
			PortraitArt.paint(canvas, Rect2(r.position + Vector2(10, 6), Vector2(tile.x - 20, tile.y - 34)), names[i][0], names[i][1], names[i][2], status)
			canvas.draw_string(canvas.get_theme_default_font(), r.position + Vector2(8, tile.y - 8), str(names[i][0]).capitalize(), HORIZONTAL_ALIGNMENT_CENTER, tile.x - 16, 15, UiPalette.TEXT))
	await _save(vp, "portrait_sheet")
