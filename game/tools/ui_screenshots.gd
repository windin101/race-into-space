extends Node
## Renders the UI scenes at several window sizes and saves PNGs, emulating the game's
## canvas_items + expand stretch inside SubViewports so the window manager is not
## involved. Also reports labels whose text is wider than the space they got.
##
##   godot --path game res://tools/ui_screenshots.tscn -- --out ../docs/screens/phase3

const SIZES := [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3440, 1440), Vector2i(3840, 2160)]
const SCENES := {
	"title": "res://scenes/ui/title_screen.tscn",
	"spaceport": "res://scenes/spaceport/spaceport.tscn",
	"gallery": "res://scenes/ui/widget_gallery.tscn",
	"settings": "res://scenes/ui/settings_screen.tscn",
}
const DESIGN := Vector2(1920, 1080)

var _out := "../docs/screens/phase3"
var _problems: Array = []


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--out" and i + 1 < args.size():
			_out = args[i + 1]
	call_deferred("_run")


func _run() -> void:
	await get_tree().process_frame
	Session.new_game(7, {"human_side": "usa"})
	get_tree().root.theme = UiTheme.get_theme("usa")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + _out))
	for scene_name in SCENES:
		for size in SIZES:
			await _capture(scene_name, SCENES[scene_name], size)
	print("\n%d layout problem(s)" % _problems.size())
	for pr in _problems:
		print("  " + pr)
	get_tree().quit(1 if not _problems.is_empty() else 0)


func _capture(scene_name: String, path: String, size: Vector2i) -> void:
	var vp := SubViewport.new()
	vp.size = size
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	# Emulate canvas_items stretch with aspect expand: scale by the smaller ratio and let
	# the logical canvas grow along the other axis.
	var scale := minf(size.x / DESIGN.x, size.y / DESIGN.y) * Settings.ui_scale
	var logical := Vector2(size) / scale
	vp.size_2d_override = Vector2i(logical.round())
	vp.size_2d_override_stretch = true
	add_child(vp)
	var scene: Control = load(path).instantiate()
	scene.theme = UiTheme.get_theme(Session.human_side)   # SubViewports do not inherit the root theme
	vp.add_child(scene)
	scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	for i in 4:
		await get_tree().process_frame
	var img := vp.get_texture().get_image()
	var file := "%s/%s_%dx%d.png" % [_out, scene_name, size.x, size.y]
	img.save_png(ProjectSettings.globalize_path("res://" + file))
	_check_labels(scene, "%s@%dx%d" % [scene_name, size.x, size.y])
	print("saved %s (logical %s)" % [file, str(Vector2i(logical.round()))])
	vp.queue_free()
	await get_tree().process_frame


func _check_labels(node: Node, where: String) -> void:
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
		_check_labels(c, where)
