extends Control
## The hub: a placeholder spaceport with building hotspots laid out from
## data/ui/spaceport_layout.json in fractions of the design canvas, so they follow the
## window at any aspect ratio. Phase 7 replaces the flat blocks with paintings.

const PLACEHOLDER_PANEL := "res://scripts/ui/widgets/placeholder_panel.gd"
## A building whose base is lower than this (canvas fraction) has its name inside its box.
const TAG_INSIDE_BELOW := 0.92

var _layout: Dictionary
var _buildings: Array = []      ## this side's buildings: layout entries with its own boxes
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
	_buildings = side_buildings(_layout, _side())
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
	for b in _buildings:
		var entry: Dictionary = b.duplicate()
		var btn: Button = _buttons.get(b["id"])
		entry["built"] = btn == null or btn.visible
		buildings.append(entry)
	var pads: Array = me.pads if me != null else [0, -1, -1]
	var season: int = Session.state().season if Session.has_game() else 0
	var own_flag: Dictionary = _layout.get("sides", {}).get(_side(), {}).get("flag", {})
	SpaceportArt.paint(_sky, _sky.size, _side(), buildings, pads, season, own_flag)


## The layout's building list with this side's placements (from tools/spaceport_layout.py,
## fitted to the painting) laid over the shared defaults. Marked "fitted" so the painter
## draws each cutout exactly into its box.
static func side_buildings(layout: Dictionary, side: String) -> Array:
	var placed: Dictionary = layout.get("sides", {}).get(side, {}).get("buildings", {})
	var out: Array = []
	for b in layout.get("buildings", []):
		var entry: Dictionary = b.duplicate()
		if placed.has(b["id"]):
			for k in ["x", "y", "w", "h"]:
				entry[k] = float(placed[b["id"]][k])
			entry["fitted"] = true
		out.append(entry)
	return out


## The flag's box: the side's own placement when its layout has one, else the default.
static func flag_box(layout: Dictionary, side: String) -> Dictionary:
	var own: Dictionary = layout.get("sides", {}).get(side, {}).get("flag", {})
	if not own.is_empty():
		return own
	return layout.get("flag", {"x": 0.9, "y": 0.1, "w": 0.07, "h": 0.14})


func _build_buildings() -> void:
	for b in _buildings:
		var btn := Button.new()
		btn.name = b["id"]
		_style_hotspot(btn)
		_place(btn, b)
		# Near the bottom bar there is no room under the base, so the name sits inside.
		_add_tag(btn, b["title"], "inside" if float(b["y"]) + float(b["h"]) > TAG_INSIDE_BELOW else "below")
		btn.pressed.connect(_on_building.bind(b))
		if b.has("help"):
			UiHelp.attach(btn, b["help"])
		add_child(btn)
		_buttons[b["id"]] = btn
	var f: Dictionary = flag_box(_layout, _side())
	_flag = Button.new()
	_style_hotspot(_flag)
	_place(_flag, f)
	_add_tag(_flag, "End season", "above")
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
	btn.add_theme_stylebox_override("hover", UiTheme.flat(Color(1, 1, 1, 0.08), Color(UiPalette.GOLD, 0.8), 6, 2))
	btn.add_theme_stylebox_override("pressed", UiTheme.flat(Color(1, 1, 1, 0.18), UiPalette.GOLD, 6, 2))
	btn.add_theme_stylebox_override("focus", UiTheme.flat(Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0), 4, 0))
	btn.add_theme_stylebox_override("disabled", UiTheme.flat(Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0), 4, 0))
	btn.add_theme_font_override("font", load(UiTheme.FONT_BODY_BOLD))


## A building's name sits on a small plate centred just under its base, never truncated.
## where: "below" (under the base), "inside" (just above the base, for buildings at the
## bottom bar) or "above" (over the top, for the flag). It is a child of the hotspot, so it
## hides with it, and it lights up when the hotspot is hovered.
static func _add_tag(btn: Button, text: String, where := "below") -> void:
	btn.clip_contents = false
	var plate := PanelContainer.new()
	plate.name = "Tag"
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := UiTheme.flat(Color(UiPalette.BG_DEEP, 0.72), Color(1, 1, 1, 0.0), 4, 0)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 1
	sb.content_margin_bottom = 2
	plate.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", UiTheme.font(UiTheme.FONT_BODY_SEMIBOLD))
	l.add_theme_font_size_override("font_size", UiTheme.SIZE_SMALL)
	l.add_theme_color_override("font_color", UiPalette.TEXT)
	plate.add_child(l)
	btn.add_child(plate)
	plate.grow_horizontal = Control.GROW_DIRECTION_BOTH
	match where:
		"inside":
			plate.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
			plate.grow_vertical = Control.GROW_DIRECTION_BEGIN
			plate.offset_top = -4
			plate.offset_bottom = -4
		"above":
			plate.set_anchors_preset(Control.PRESET_CENTER_TOP)
			plate.grow_vertical = Control.GROW_DIRECTION_BEGIN
			plate.offset_top = -2
			plate.offset_bottom = -2
		_:
			plate.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
			plate.offset_top = 2
	btn.mouse_entered.connect(func(): l.add_theme_color_override("font_color", UiPalette.GOLD))
	btn.mouse_exited.connect(func(): l.add_theme_color_override("font_color", UiPalette.TEXT))
	btn.tooltip_text = text if btn.tooltip_text == "" else btn.tooltip_text


static func _set_tag(btn: Button, text: String) -> void:
	var plate := btn.get_node_or_null("Tag")
	if plate:
		(plate.get_child(0) as Label).text = text


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
	FrameBars.fill_crumbs(_crumbs, str(Sides.field(_side(), "site", Sides.name(_side()))), self)
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
			var label := "Launch Pad %d" % (i + 1) if me.pads[i] <= 0 else "Pad %d (damaged)" % (i + 1)
			if me.pads[i] == SimPlayer.PAD_NONE:
				label = "Pad %d site" % (i + 1)
			_set_tag(btn, label)
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
	if _buttons.has("memorial"):
		_set_tag(_buttons["memorial"], "%s Memorial" % str(Sides.field(_side(), "people", "astronaut")).capitalize())
	# The spaceplane's runway, like the original's per-programme overlays, appears with the
	# programme and carries its name.
	var plane: SimProgram = me.program("manned", 3)
	_set_building("runway", plane != null and plane.owned)
	if plane != null and _buttons.has("runway"):
		var plane_name := plane.display_name()
		if not plane_name.contains("-"):          # XMS-2 keeps its designation
			plane_name = plane_name.capitalize()
		_set_tag(_buttons["runway"], "%s Runway" % plane_name)
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
