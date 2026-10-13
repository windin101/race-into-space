class_name ScreenPanel
extends Control
## Base for full-screen panels, in the fixed frame of docs/specs/ui-style-guide.md:
## a top bar (back arrow, breadcrumb, prestige, date), the content area on the screen's
## backdrop, and a bottom resource bar whose right end holds the screen's context action
## (`footer`). Subclasses add children to `content` and their actions to `footer`; when a
## screen adds none, a "Spaceport" action is supplied.
##
## Backdrops: set_room(name) shows a painting as a monotone tint in the side's hue (offices);
## set_backdrop(name) shows it in full colour (stage-like screens).

var title := "":
	set(v):
		title = v
		if _sp_crumbs:
			FrameBars.fill_crumbs(_sp_crumbs, title, self)
var show_back := true
## Show the rival's prestige in the top bar (screens about the race).
var show_rival_prestige := false

var content: VBoxContainer
var footer: HBoxContainer
var _sp_backdrop: TextureRect
var _sp_panel: PanelContainer
var _sp_crumbs: HBoxContainer
var _sp_top_right: HBoxContainer
var _sp_chips: HBoxContainer
var _sp_back: Button
var _sp_status: Label


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiPalette.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_sp_backdrop = TextureRect.new()
	_sp_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sp_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_sp_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sp_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sp_backdrop.visible = false
	add_child(_sp_backdrop)

	var frame := VBoxContainer.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_constant_override("separation", 0)
	add_child(frame)
	var top := FrameBars.make_top(_on_back)
	frame.add_child(top["node"])
	_sp_crumbs = top["crumbs"]
	_sp_top_right = top["right"]
	_sp_back = top["back"]
	_sp_status = Label.new()
	_sp_status.theme_type_variation = "Dim"
	_sp_status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	(top["node"] as Control).get_child(0).add_child(_sp_status)
	(top["node"] as Control).get_child(0).move_child(_sp_status, 2)

	var margin := MarginContainer.new()
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	frame.add_child(margin)
	_sp_panel = PanelContainer.new()
	_sp_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(_sp_panel)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	_sp_panel.add_child(content)

	var bottom := FrameBars.make_bottom()
	frame.add_child(bottom["node"])
	_sp_chips = bottom["chips"]
	footer = bottom["action"]


func _ready() -> void:
	_sp_back.visible = show_back and Screens.stack.find(self) > 0
	FrameBars.fill_crumbs(_sp_crumbs, title, self)
	_refresh_status()
	if Session.has_game():
		Session.state_changed.connect(_refresh_status)
	_add_default_action.call_deferred()


func _add_default_action() -> void:
	if footer.get_child_count() > 0 or Screens.stack.find(self) <= 0:
		return
	var home := Button.new()
	home.text = "SPACEPORT"
	home.theme_type_variation = "Bar"
	home.tooltip_text = "Back to the spaceport"
	home.custom_minimum_size = Vector2(170, 40)
	home.pressed.connect(func(): Screens.go_home())
	footer.add_child(home)


## A painting in full colour behind translucent panels (stage-like screens).
func set_backdrop(name: String) -> void:
	_apply_backdrop(ArtAssets.backdrop(name), false)


## A painting as a monotone room in the side's hue behind translucent panels (offices).
func set_room(name: String) -> void:
	_apply_backdrop(ArtAssets.backdrop(name), true)


func _apply_backdrop(tex: Texture2D, monotone: bool) -> void:
	_sp_backdrop.texture = tex
	_sp_backdrop.visible = tex != null
	if monotone and tex != null:
		var mat := ShaderMaterial.new()
		mat.shader = load("res://scripts/ui/monotone.gdshader")
		var side := Session.human_side if Session.has_game() else "usa"
		mat.set_shader_parameter("tint", UiPalette.ROOM_TINT_USA if side == "usa" else UiPalette.ROOM_TINT_USSR)
		_sp_backdrop.material = mat
		_sp_backdrop.modulate = Color.WHITE
	else:
		_sp_backdrop.material = null
		_sp_backdrop.modulate = Color(0.65, 0.65, 0.65)
	if tex != null:
		_sp_panel.add_theme_stylebox_override("panel", UiTheme.flat(Color(UiPalette.PANEL, 0.55 if monotone else 0.72), UiPalette.BORDER_SOFT, 10))
		_make_translucent(content)
	else:
		_sp_panel.remove_theme_stylebox_override("panel")


## Nested panels (Sunken, Card) would hide the art, so they get a see-through copy of
## their own stylebox. Called once the subclass has built its content.
func _make_translucent(node: Node) -> void:
	for child in node.get_children():
		if child is PanelContainer and not child.has_theme_stylebox_override("panel"):
			var sb: StyleBox = child.get_theme_stylebox("panel")
			if sb is StyleBoxFlat:
				var copy := sb.duplicate() as StyleBoxFlat
				copy.bg_color = Color(copy.bg_color, 0.82)
				child.add_theme_stylebox_override("panel", copy)
		_make_translucent(child)


func set_status(text: String) -> void:
	_sp_status.text = text


func _refresh_status() -> void:
	FrameBars.fill_top_right(_sp_top_right, show_rival_prestige)
	FrameBars.fill_chips(_sp_chips)


func _on_back() -> void:
	Screens.pop()
