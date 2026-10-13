extends Control
## The hub: a placeholder spaceport with building hotspots laid out from
## data/ui/spaceport_layout.json in fractions of the design canvas, so they follow the
## window at any aspect ratio. Phase 7 replaces the flat blocks with paintings.

const PLACEHOLDER_PANEL := "res://scripts/ui/widgets/placeholder_panel.gd"

var _layout: Dictionary
var _buttons: Dictionary = {}
var _hud: Label
var _top_bar: PanelContainer
var _bottom_bar: PanelContainer
var _crumbs: HBoxContainer
var _top_right: HBoxContainer
var _chips: HBoxContainer
var _end_btn: Button
var _flag: Button
var _sky: ColorRect


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_layout = GameData.ui_layout.get("spaceport", {})
	_build_backdrop()
	_build_buildings()
	_build_hud()
	if Session.has_game():
		Session.state_changed.connect(_refresh)
	_refresh()


func _build_backdrop() -> void:
	# The painting is drawn live from the layout, so hotspots and art always agree.
	_sky = ColorRect.new()
	_sky.color = Color.TRANSPARENT
	_sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sky.draw.connect(_paint)
	_sky.resized.connect(_sky.queue_redraw)
	add_child(_sky)


func _paint() -> void:
	var me := Session.me() if Session.has_game() else null
	var buildings: Array = []
	for b in _layout.get("buildings", []):
		var entry: Dictionary = b.duplicate()
		var btn: Button = _buttons.get(b["id"])
		entry["built"] = btn == null or btn.visible
		buildings.append(entry)
	var pads: Array = me.pads if me != null else [0, -1, -1]
	var season: int = Session.state().season if Session.has_game() else 0
	SpaceportArt.paint(_sky, _sky.size, _side(), buildings, pads, season)


func _build_buildings() -> void:
	for b in _layout.get("buildings", []):
		var btn := Button.new()
		btn.text = b["title"]
		btn.name = b["id"]
		_style_hotspot(btn)
		btn.clip_text = true
		btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_place(btn, b)
		btn.pressed.connect(_on_building.bind(b))
		if b.has("help"):
			UiHelp.attach(btn, b["help"])
		add_child(btn)
		_buttons[b["id"]] = btn
	var f: Dictionary = _layout.get("flag", {"x": 0.9, "y": 0.1, "w": 0.07, "h": 0.14})
	_flag = Button.new()
	_flag.text = "End\nTurn"
	_style_hotspot(_flag)
	_place(_flag, f)
	_flag.pressed.connect(_on_end_turn)
	add_child(_flag)


## Hotspots sit on the painting: a translucent plate for the label, accent outline on hover.
static func _style_hotspot(btn: Button) -> void:
	btn.theme_type_variation = "Flat"
	btn.add_theme_color_override("font_color", UiPalette.BG_DEEP)
	btn.add_theme_color_override("font_hover_color", UiPalette.BG_DEEP)
	btn.add_theme_color_override("font_pressed_color", UiPalette.BG_DEEP)
	btn.add_theme_color_override("font_disabled_color", Color(UiPalette.BG_DEEP, 0.45))
	btn.add_theme_stylebox_override("normal", UiTheme.flat(Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0), 4, 0))
	btn.add_theme_stylebox_override("hover", UiTheme.flat(Color(1, 1, 1, 0.25), UiPalette.GOLD, 4, 2))
	btn.add_theme_stylebox_override("pressed", UiTheme.flat(Color(1, 1, 1, 0.4), UiPalette.GOLD, 4, 2))
	btn.add_theme_stylebox_override("focus", UiTheme.flat(Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0), 4, 0))
	btn.add_theme_stylebox_override("disabled", UiTheme.flat(Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0), 4, 0))
	btn.add_theme_font_override("font", load(UiTheme.FONT_BODY_BOLD))


## Anchor a control to a fractional rectangle of the canvas.
static func _place(c: Control, r: Dictionary) -> void:
	c.anchor_left = r["x"]
	c.anchor_top = r["y"]
	c.anchor_right = r["x"] + r["w"]
	c.anchor_bottom = r["y"] + r["h"]
	c.offset_left = 0
	c.offset_top = 0
	c.offset_right = 0
	c.offset_bottom = 0


## The fixed frame over the painting (ui-style-guide section 2): the site name, prestige
## and date on top; the resource chips and the End season action below. The hub has no
## back arrow.
func _build_hud() -> void:
	var top := FrameBars.make_top(func(): pass)
	_top_bar = top["node"]
	_top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	(top["back"] as Button).visible = false
	_crumbs = top["crumbs"]
	_top_right = top["right"]
	_hud = Label.new()
	_hud.theme_type_variation = "Dim"
	_hud.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hud.visible = false
	_top_bar.get_child(0).add_child(_hud)
	_top_bar.get_child(0).move_child(_hud, 2)
	add_child(_top_bar)
	var bottom := FrameBars.make_bottom()
	_bottom_bar = bottom["node"]
	_bottom_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_chips = bottom["chips"]
	add_child(_bottom_bar)
	_end_btn = Button.new()
	_end_btn.custom_minimum_size = Vector2(190, 40)
	UiAction.style(_end_btn, "go", "End season")
	_end_btn.tooltip_text = "Lower the flag and play out the season  (or click the flag)"
	_end_btn.pressed.connect(func():
		if not UiAction.is_blocked(_end_btn):
			_on_end_turn())
	(bottom["action"] as HBoxContainer).add_child(_end_btn)


func _side() -> String:
	return Session.human_side if Session.has_game() else "usa"


func _refresh() -> void:
	FrameBars.fill_crumbs(_crumbs, "Cape Canaveral" if _side() == "usa" else "Baikonur", self)
	FrameBars.fill_top_right(_top_right)
	FrameBars.fill_chips(_chips)
	if not Session.has_game():
		_hud.text = "No game in progress"
		_hud.visible = true
		UiAction.style(_end_btn, "blocked", "End season", "No game in progress.")
		return
	_hud.visible = false
	var s := Session.state()
	var me := Session.me()
	for i in 3:
		var btn: Button = _buttons.get("pad_%d" % (i + 1))
		if btn:
			btn.text = "Launch Pad %d" % (i + 1) if me.pads[i] <= 0 else "Pad %d (damaged)" % (i + 1)
			if me.pads[i] == SimPlayer.PAD_NONE:
				btn.text = "Pad %d site" % (i + 1)
	# Buildings appear as the programme grows, as on the original spaceport.
	var any_program := me.owned_programs().size() > 1          # photo recon is pre-owned
	var any_manned := false
	for prog in me.owned_programs():
		if prog.is_capsule():
			any_manned = true
	var any_astronauts := not me.astronauts.is_empty()
	_set_building("programs", any_program)
	_set_building("research", any_program)
	_set_building("astronaut_complex", any_manned or any_astronauts)
	_set_building("training", any_astronauts)
	_set_building("vab", any_program)
	_set_building("mission_control", any_program)
	_flag.disabled = s.ended
	_flag.tooltip_text = "The game is over." if s.ended else "Lower the flag to end the season"
	if s.ended:
		UiAction.style(_end_btn, "blocked", "End season", "The game is over.")
	else:
		UiAction.style(_end_btn, "go", "End season")
		_end_btn.tooltip_text = "Lower the flag and play out %s" % s.date_string()


func _set_building(id: String, built: bool) -> void:
	var btn: Button = _buttons.get(id)
	if btn:
		btn.visible = built
	if _sky:
		_sky.queue_redraw()


func _on_building(b: Dictionary) -> void:
	var args: Dictionary = b.get("args", {}).duplicate()
	args["id"] = b["id"]
	args["title"] = b["title"]
	args["help"] = b.get("help", "")
	var scene: String = b.get("scene", "")
	if scene != "" and ResourceLoader.exists(scene):
		Screens.push(load(scene), args)
	else:
		Screens.push(load(PLACEHOLDER_PANEL).new(), args)


func _on_end_turn() -> void:
	if not Session.has_game():
		return
	if await ConfirmBox.ask(self, "End the season?", "Lower the flag and let %s play out." % Session.state().date_string()):
		Sound.sfx("flag")
		var report := Session.end_turn()
		TurnFlow.after_end_turn(report)


## The hub refreshes itself when a turn screen above it closes.
func on_resume() -> void:
	_refresh()
