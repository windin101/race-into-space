extends Node
## Renders every UI scene at several window sizes and saves PNGs, emulating the game's
## canvas_items + expand stretch inside SubViewports so the window manager is not
## involved. Reports labels and buttons whose text is wider than the space they got.
##
##   DISPLAY=:1 godot --path game res://tools/ui_screenshots.tscn -- --out ../docs/screens/phase4 [--all-sizes]
##
## Scenes are discovered under res://scenes/. The four core screens render at every size;
## the rest at 1920x1080 unless --all-sizes is given. Scenes needing arguments list them
## in SETUP_ARGS.

const SIZES := [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3440, 1440), Vector2i(3840, 2160)]
const CORE := ["title_screen", "spaceport", "widget_gallery", "settings_screen"]
const SKIP := ["main"]
const SETUP_ARGS := {
	"launch_pad": {"pad": 0, "title": "Launch Pad 1"},
	"launch_results": {"report": {}},
	"annual_review": {},
	"end_game": {"report": {}},
}
const DESIGN := Vector2(1920, 1080)

var _out := "../docs/screens/phase4"
var _all_sizes := false
var _problems: Array = []


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--out" and i + 1 < args.size():
			_out = args[i + 1]
		if args[i] == "--all-sizes":
			_all_sizes = true
	call_deferred("_run")


func _run() -> void:
	await get_tree().process_frame
	Session.new_game(7, {"human_side": "usa"})
	_advance_game(6)
	get_tree().root.theme = UiTheme.get_theme("usa")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + _out))
	var scenes := _discover("res://scenes")
	scenes.sort()
	for path in scenes:
		var scene_name: String = path.get_file().get_basename()
		if scene_name in SKIP:
			continue
		var sizes: Array = SIZES if (scene_name in CORE or _all_sizes) else [Vector2i(1920, 1080)]
		for size in sizes:
			await _capture(scene_name, path, size)
	print("\n%d layout problem(s)" % _problems.size())
	for pr in _problems:
		print("  " + pr)
	get_tree().quit(1 if not _problems.is_empty() else 0)


## Play a few scripted seasons so screens have data to show.
func _advance_game(turns: int) -> void:
	var drivers := [SimDriver.new(0), SimDriver.new(1)]
	for t in turns:
		for d in drivers:
			d.act(Session.game)
		Session.game.end_turn()
	Session.notify_change()


func _discover(dir_path: String) -> Array:
	var out: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full := dir_path.path_join(entry)
		if dir.current_is_dir():
			out.append_array(_discover(full))
		elif entry.ends_with(".tscn"):
			out.append(full)
		entry = dir.get_next()
	return out


func _capture(scene_name: String, path: String, size: Vector2i) -> void:
	var vp := SubViewport.new()
	vp.size = size
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	var scale := minf(size.x / DESIGN.x, size.y / DESIGN.y) * Settings.ui_scale
	var logical := Vector2(size) / scale
	vp.size_2d_override = Vector2i(logical.round())
	vp.size_2d_override_stretch = true
	add_child(vp)
	var scene: Control = load(path).instantiate()
	scene.theme = UiTheme.get_theme(Session.human_side)   # SubViewports do not inherit the root theme
	vp.add_child(scene)
	scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	if scene.has_method("setup"):
		scene.call("setup", SETUP_ARGS.get(scene_name, {}))
	for i in 4:
		await get_tree().process_frame
	var img := vp.get_texture().get_image()
	var file := "%s/%s_%dx%d.png" % [_out, scene_name, size.x, size.y]
	img.save_png(ProjectSettings.globalize_path("res://" + file))
	_check_text(scene, "%s@%dx%d" % [scene_name, size.x, size.y])
	print("saved %s (logical %s)" % [file, str(Vector2i(logical.round()))])
	vp.queue_free()
	await get_tree().process_frame


func _check_text(node: Node, where: String) -> void:
	if node is Label and node.visible and node.text != "" and not node.clip_text \
			and node.autowrap_mode == TextServer.AUTOWRAP_OFF:
		var needed: float = node.get_minimum_size().x
		if needed > node.size.x + 1.0 and node.size.x > 0.0:
			_problems.append("%s: label '%s' needs %.0f px, has %.0f" % [where, node.text.substr(0, 40), needed, node.size.x])
	if node is Button and node.visible and node.text != "" and not node.clip_text:
		var needed: float = node.get_minimum_size().x
		if needed > node.size.x + 1.0 and node.size.x > 0.0:
			_problems.append("%s: button '%s' needs %.0f px, has %.0f" % [where, node.text.substr(0, 40), needed, node.size.x])
	for c in node.get_children():
		_check_text(c, where)
