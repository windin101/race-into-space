extends Control
## The hub: a placeholder spaceport with building hotspots laid out from
## data/ui/spaceport_layout.json in fractions of the design canvas, so they follow the
## window at any aspect ratio. Phase 7 replaces the flat blocks with paintings.

const PLACEHOLDER_PANEL := "res://scripts/ui/widgets/placeholder_panel.gd"

var _layout: Dictionary
var _buttons: Dictionary = {}
var _hud: Label
var _flag: Button
var _sky: ColorRect
var _ground: ColorRect
var _horizon: ColorRect


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
	_sky = ColorRect.new()
	_sky.color = UiPalette.BG_DEEP.lerp(UiPalette.accent_dark(_side()), 0.25)
	_sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sky)
	_horizon = ColorRect.new()
	_horizon.color = UiPalette.PANEL
	_horizon.anchor_top = 0.36
	_horizon.anchor_bottom = 0.40
	_horizon.anchor_right = 1.0
	_horizon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_horizon)
	_ground = ColorRect.new()
	_ground.color = Color("1b2a1f")
	_ground.anchor_top = 0.40
	_ground.anchor_bottom = 1.0
	_ground.anchor_right = 1.0
	_ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ground)


func _build_buildings() -> void:
	for b in _layout.get("buildings", []):
		var btn := Button.new()
		btn.text = b["title"]
		btn.name = b["id"]
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
	_flag.theme_type_variation = "Accent"
	_place(_flag, f)
	_flag.pressed.connect(_on_end_turn)
	add_child(_flag)


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


func _build_hud() -> void:
	_hud = Label.new()
	_hud.theme_type_variation = "Subheading"
	_hud.anchor_left = 0.02
	_hud.anchor_top = 0.02
	_hud.anchor_right = 0.6
	_hud.anchor_bottom = 0.10
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hud)
	var title := Label.new()
	title.theme_type_variation = "Title"
	title.text = "Cape Canaveral" if _side() == "usa" else "Baikonur"
	title.anchor_left = 0.02
	title.anchor_top = 0.10
	title.anchor_right = 0.6
	title.anchor_bottom = 0.22
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)


func _side() -> String:
	return Session.human_side if Session.has_game() else "usa"


func _refresh() -> void:
	if not Session.has_game():
		_hud.text = "No game in progress"
		return
	var s := Session.state()
	var me := Session.me()
	_hud.text = "%s     Cash %d MB     Budget %d MB     Prestige %d" % [s.date_string(), me.cash, me.budget, me.prestige_total]
	for i in 3:
		var btn: Button = _buttons.get("pad_%d" % (i + 1))
		if btn:
			btn.text = "Launch Pad %d" % (i + 1) if me.pads[i] <= 0 else "Pad %d (damaged)" % (i + 1)
			btn.theme_type_variation = "" if me.pads[i] != SimPlayer.PAD_NONE else "Flat"
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


func _set_building(id: String, built: bool) -> void:
	var btn: Button = _buttons.get(id)
	if btn:
		btn.visible = built


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
		var report := Session.end_turn()
		TurnFlow.after_end_turn(report)


## The hub refreshes itself when a turn screen above it closes.
func on_resume() -> void:
	_refresh()
