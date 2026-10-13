extends ScreenPanel
## Hardware Purchase, laid out like the Research showroom: four picture tabs for the
## groups, name chips and a viewer over every program in the group (owned or not) with a
## name strip to cycle, the specifications with a safety gauge, then the purchasing panel
## whose action bars buy the program and units (or say why they cannot). All rules come
## from SimHardware; this screen only presents them.

const GROUP_TITLES := {"probe": "Unmanned", "rocket": "Rockets", "manned": "Capsules", "misc": "Misc"}
const CASE_BG := Color("0a1424")
const STRIP_H := 52.0
const STAT_KEYS := ["units", "program_cost", "unit_cost", "safety", "weight", "max_rd", "max_safety"]
const STAT_TITLES := {"units": "Units on hand", "program_cost": "Initial cost", "unit_cost": "Unit cost",
		"safety": "Safety factor", "weight": "Unit weight", "max_rd": "Maximum R&D", "max_safety": "Maximum safety"}

var _group := "rocket"
var _programs: Array = []          ## every SimProgram designed in the current group
var _index := 0
var _selected: SimProgram

var _tabs: Dictionary = {}         ## group -> Button
var _chips: HBoxContainer
var _case: Control
var _case_name: Label
var _prev: Button
var _next: Button
var _banner: Label
var _spec_panel: UiPanel
var _stats: GridContainer
var _stat_keys: Dictionary = {}
var _stat_values: Dictionary = {}
var _gauge: Gauge
var _gauge_marker: Control
var _gauge_max: Label
var _detail: Label
var _buy_program: Button
var _buy_unit: Button
var _cash: Label
var _result: Label


func _init() -> void:
	super()
	title = "Hardware Purchase"


func _ready() -> void:
	super()
	# Picture tabs, one per hardware group.
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 12)
	content.add_child(tabs)
	for g in SimProgram.GROUPS:
		var b := Button.new()
		b.text = GROUP_TITLES[g]
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 112
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.expand_icon = false
		b.add_theme_constant_override("icon_max_width", 72)
		b.pressed.connect(_set_group.bind(g))
		tabs.add_child(b)
		_tabs[g] = b
	UiHelp.attach(tabs, "I008")
	_chips = HBoxContainer.new()
	_chips.add_theme_constant_override("separation", 6)
	content.add_child(_chips)

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 16)
	content.add_child(split)

	# Viewer: the display case with the name strip across its foot.
	var viewer := UiPanel.new()
	viewer.hide_title()
	viewer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewer.size_flags_stretch_ratio = 1.1
	viewer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(viewer)
	_case = Control.new()
	_case.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_case.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_case.clip_contents = true
	_case.draw.connect(_draw_case)
	_case.resized.connect(_case.queue_redraw)
	viewer.body.add_child(_case)
	var strip := _name_strip(_case)
	_prev = strip["prev"]
	_next = strip["next"]
	_case_name = strip["name"]
	_prev.pressed.connect(func(): _step(-1))
	_next.pressed.connect(func(): _step(1))
	_info_badge(_case, "I008")

	# Banner, specifications and the purchasing panel.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.custom_minimum_size.x = 420
	right.add_theme_constant_override("separation", 12)
	split.add_child(right)
	var banner_panel := PanelContainer.new()
	banner_panel.theme_type_variation = "Sunken"
	right.add_child(banner_panel)
	_banner = Label.new()
	_banner.theme_type_variation = "Heading"
	_banner.add_theme_color_override("font_color", UiPalette.GOLD)
	_banner.clip_text = true
	_banner.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	banner_panel.add_child(_banner)
	_spec_panel = UiPanel.new("Specifications", "I008")
	right.add_child(_spec_panel)
	_stats = GridContainer.new()
	_stats.columns = 2
	_stats.add_theme_constant_override("h_separation", 24)
	_stats.add_theme_constant_override("v_separation", 2)
	_spec_panel.body.add_child(_stats)
	for key in STAT_KEYS:
		var k := Label.new()
		k.text = STAT_TITLES[key]
		k.theme_type_variation = "Dim"
		_stats.add_child(k)
		_stat_keys[key] = k
		var v := Label.new()
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_stats.add_child(v)
		_stat_values[key] = v
	var gauge_row := HBoxContainer.new()
	gauge_row.add_theme_constant_override("separation", 12)
	_spec_panel.body.add_child(gauge_row)
	var gl := Label.new()
	gl.theme_type_variation = "Caps"
	gl.text = "SAFETY"
	gl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gauge_row.add_child(gl)
	_gauge = Gauge.new(false, "Safety (starting safety if bought now); the gold line is Maximum R&D")
	_gauge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gauge.mouse_filter = Control.MOUSE_FILTER_PASS
	gauge_row.add_child(_gauge)
	_gauge_marker = Control.new()
	_gauge_marker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_gauge_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gauge_marker.draw.connect(_draw_gauge_marker)
	_gauge.add_child(_gauge_marker)
	_gauge_max = Label.new()
	_gauge_max.theme_type_variation = "Caps"
	_gauge_max.add_theme_color_override("font_color", UiPalette.GOLD)
	_gauge_max.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gauge_row.add_child(_gauge_max)

	var board := UiPanel.new("Purchasing", "I008")
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(board)
	_cash = Label.new()
	_cash.theme_type_variation = "Subheading"
	_cash.add_theme_color_override("font_color", UiPalette.INFO)
	board.body.add_child(_cash)
	_detail = Label.new()
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.theme_type_variation = "Small"
	board.body.add_child(_detail)
	_result = Label.new()
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	board.body.add_child(_result)
	_buy_program = board.add_action("Purchase program", "go", _on_buy_program)
	_buy_unit = board.add_action("Buy unit", "go", _on_buy_unit)
	_set_group(_group)
	set_room("room_hangar")


func on_resume() -> void:
	_refresh()


# ----------------------------------------------------------------- building

## The viewer's name strip, overlaid on the foot of the case: ◀ name ▶.
static func _name_strip(case: Control) -> Dictionary:
	var strip := PanelContainer.new()
	var sb := UiTheme.flat(Color(UiPalette.PANEL_SUNKEN, 0.88), Color.TRANSPARENT, 0, 0)
	sb.border_width_top = 1
	sb.border_color = UiPalette.BORDER_SOFT
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	strip.add_theme_stylebox_override("panel", sb)
	strip.anchor_left = 0.0
	strip.anchor_right = 1.0
	strip.anchor_top = 1.0
	strip.anchor_bottom = 1.0
	strip.offset_top = -STRIP_H
	case.add_child(strip)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	strip.add_child(row)
	var prev := Button.new()
	prev.text = "◀"
	prev.custom_minimum_size.x = 56
	prev.tooltip_text = "Previous program"
	row.add_child(prev)
	var name := Label.new()
	name.theme_type_variation = "CapsBright"
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.clip_text = true
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(name)
	var next := Button.new()
	next.text = "▶"
	next.custom_minimum_size.x = 56
	next.tooltip_text = "Next program"
	row.add_child(next)
	return {"prev": prev, "next": next, "name": name}


## The (i) badge in the case's top-right corner.
func _info_badge(case: Control, code: String) -> void:
	var badge := Button.new()
	badge.icon = ArtAssets.icon("chip_info")
	badge.theme_type_variation = "Flat"
	badge.tooltip_text = "Help for this screen"
	badge.focus_mode = Control.FOCUS_NONE
	badge.add_theme_constant_override("icon_max_width", 22)
	badge.anchor_left = 1.0
	badge.anchor_right = 1.0
	badge.offset_left = -44
	badge.offset_right = -8
	badge.offset_top = 8
	badge.offset_bottom = 44
	badge.pressed.connect(func(): UiHelp.show_code(self, code))
	case.add_child(badge)


## Restyle an action-bar button with UiAction.style, then re-round the bar over the
## buttons that are visible (UiPanel records the corners at add time, and these screens
## hide one of their two bars at times).
static func _restyle(b: Button, kind: String, text: String, reason := "") -> void:
	UiAction.style(b, kind, text, reason)
	var shown: Array = []
	for c in b.get_parent().get_children():
		if c is Button and c.visible:
			shown.append(c)
	for c: Button in shown:
		c.set_meta("bar_corners", Vector2i(1 if c == shown[0] else 0, 1 if c == shown[shown.size() - 1] else 0))
		UiAction.apply_corners(c)


# ----------------------------------------------------------------- drawing

func _draw_case() -> void:
	var size := _case.size
	_case.draw_rect(Rect2(Vector2.ZERO, size), CASE_BG)
	var side := Session.human_side if Session.has_game() else "usa"
	var accent := UiPalette.ACCENT_USSR if side == "ussr" else UiPalette.ACCENT_USA
	var stage := Vector2(size.x, size.y - STRIP_H)
	# A soft spotlight behind the exhibit.
	var centre := stage / 2.0
	for i in range(6, 0, -1):
		_case.draw_circle(centre, minf(stage.x, stage.y) * 0.08 * i, Color(accent, 0.025))
	if _selected == null:
		_case.draw_string(get_theme_default_font(), Vector2(0, centre.y), "No programs in this group", HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTheme.SIZE_SUBHEADING, UiPalette.TEXT_MUTED)
		return
	var rect := Rect2(Vector2.ZERO, stage).grow(-minf(stage.x, stage.y) * 0.08)
	HardwareArt.paint(_case, rect, _selected.group, _selected.slot, side)
	# Plinth line.
	_case.draw_line(Vector2(size.x * 0.15, stage.y - 14), Vector2(size.x * 0.85, stage.y - 14), UiPalette.BORDER_SOFT, 2.0)
	if not _selected.owned:
		# Unopened programs sit behind glass with a status band, like a catalogue page.
		_case.draw_rect(Rect2(Vector2.ZERO, stage), Color(CASE_BG, 0.45))
		var col := UiPalette.WARN if _selected.delay > 0 else UiPalette.INFO
		_case.draw_rect(Rect2(0, stage.y - 34, size.x, 34), Color(0, 0, 0, 0.55))
		_case.draw_string(get_theme_default_font(), Vector2(0, stage.y - 11), _status_text(_selected).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTheme.SIZE_SMALL, col)


## The Maximum R&D line across the safety gauge's track (the gauge draws the track
## from x = 6 to size.x - 64).
func _draw_gauge_marker() -> void:
	if _selected == null:
		return
	var s := _gauge_marker.size
	var x := 6.0 + (s.x - 70.0) * clampf(_max_rd(_selected) / 100.0, 0.0, 1.0)
	_gauge_marker.draw_line(Vector2(x, 2), Vector2(x, s.y - 2), UiPalette.GOLD, 2.0)



# ----------------------------------------------------------------- state

func _set_group(g: String) -> void:
	_group = g
	for key in _tabs:
		_tabs[key].button_pressed = key == g
	_index = 0
	_selected = null
	_result.text = ""
	_refresh()


func _step(delta: int) -> void:
	if _programs.is_empty():
		return
	_index = posmod(_index + delta, _programs.size())
	_selected = _programs[_index]
	_result.text = ""
	_refresh_detail()


## Maximum R&D: the program's own once opened, the design's before.
static func _max_rd(prog: SimProgram) -> int:
	return prog.max_rd if prog.owned else int(prog.spec.get("max_rd", 0))


func _status_text(prog: SimProgram) -> String:
	if prog.owned:
		return "Owned"
	if prog.delay > 0:
		return "Delayed %d season%s" % [prog.delay, "" if prog.delay == 1 else "s"]
	return "Available"


func _refresh() -> void:
	if not Session.has_game():
		return
	var p := Session.me()
	var side := p.side
	# Tab pictures: the group's first owned program, else its first design.
	for g in SimProgram.GROUPS:
		var pick: SimProgram = null
		for prog in p.programs[g]:
			if prog != null and (pick == null or (prog.owned and not pick.owned)):
				pick = prog
		_tabs[g].icon = ArtAssets.hardware(side, g, pick.slot) if pick != null else null
		_tabs[g].tooltip_text = "%s programs" % GROUP_TITLES[g]
	_programs = []
	for prog in p.programs[_group]:
		if prog != null:
			_programs.append(prog)
	for c in _chips.get_children():
		c.queue_free()
	for i in _programs.size():
		var prog: SimProgram = _programs[i]
		var chip := Button.new()
		chip.text = prog.display_name().capitalize()
		chip.theme_type_variation = "Flat"
		chip.toggle_mode = true
		if not prog.owned:
			chip.modulate.a = 0.6
		chip.tooltip_text = "%s: %s" % [chip.text, _status_text(prog)]
		chip.pressed.connect(func():
			_index = i
			_selected = _programs[i]
			_result.text = ""
			_refresh_detail())
		_chips.add_child(chip)
	if _programs.is_empty():
		_selected = null
	else:
		var keep := _programs.find(_selected) if _selected != null else -1
		_index = keep if keep >= 0 else clampi(_index, 0, _programs.size() - 1)
		_selected = _programs[_index]
	_refresh_detail()


func _refresh_detail() -> void:
	var prog := _selected
	var has := prog != null
	_case.queue_redraw()
	_gauge_marker.queue_redraw()
	_prev.disabled = _programs.size() < 2
	_next.disabled = _programs.size() < 2
	for b in [_prev, _next]:
		b.tooltip_text = ("Previous program" if b == _prev else "Next program") if _programs.size() >= 2 else "Only one program in this group"
	for i in _chips.get_child_count():
		var chip: Button = _chips.get_child(i)
		chip.button_pressed = i == _index and has
	if not Session.has_game():
		return
	var p := Session.me()
	_cash.text = "CASH ON HAND: %d MB" % p.cash
	_spec_panel.visible = has
	if not has:
		_case_name.text = "NOTHING TO PURCHASE"
		_banner.text = "HARDWARE PURCHASE"
		_detail.text = ""
		_buy_program.visible = true
		_restyle(_buy_program, "blocked", "Purchase program", "No programs are designed in this group.")
		_restyle(_buy_unit, "blocked", "Buy unit", "No programs are designed in this group.")
		return
	_case_name.text = "%s · %s" % [prog.display_name().to_upper(), OpsView.kind_name(prog).to_upper()]
	_banner.text = "%s: %s" % [prog.display_name().to_upper(), _status_text(prog).to_upper()]
	_banner.add_theme_color_override("font_color", UiPalette.GOLD if prog.owned else (UiPalette.WARN if prog.delay > 0 else UiPalette.INFO))
	var program_price := SimHardware.program_price(p, prog)
	var unit_price := SimHardware.unit_price(p, prog)
	_stat_values["units"].text = str(prog.units) if prog.owned else "0"
	_stat_values["program_cost"].text = "%d MB" % program_price
	_stat_values["unit_cost"].text = "%d MB" % unit_price
	var safety := prog.safety if prog.owned else SimHardware.starting_safety(Session.state(), p, prog)
	_stat_keys["safety"].text = "Safety factor" if prog.owned else "Starting safety"
	_stat_values["safety"].text = "%d%%" % safety
	_stat_values["safety"].add_theme_color_override("font_color", UiPalette.safety_color(safety))
	if prog.is_rocket():
		_stat_keys["weight"].text = "Maximum payload"
		_stat_values["weight"].text = str(prog.spec.get("max_payload", 0))
	else:
		_stat_keys["weight"].text = "Unit weight"
		_stat_values["weight"].text = str(prog.spec.get("unit_weight", 0)) if int(prog.spec.get("unit_weight", 0)) > 0 else "n/a"
	_stat_values["max_rd"].text = "%d%%" % prog.max_rd
	_stat_values["max_safety"].text = "%d%%" % prog.max_safety()
	_gauge.value = safety
	_gauge_max.text = "MAX R&D %d%%" % _max_rd(prog)

	var lines: PackedStringArray = []
	if prog.owned:
		lines.append("%d of %d units in inventory." % [prog.units, SimHardware.MAX_UNITS])
	if prog.delay > 0:
		lines.append("Purchases are blocked for %d more season%s." % [prog.delay, "" if prog.delay == 1 else "s"])
	if p.turn_flags.get("half_price", false):
		lines.append("Half-price sale this season.")
	if prog.is_photo_recon():
		lines.append("Photo reconnaissance has no units to buy.")
	if prog.damage != 0:
		lines.append("Damaged: %d%% on its next flight unless %d MB is paid in R&D." % [prog.damage, prog.damage_cost])
	_detail.text = "\n".join(lines)
	_detail.visible = not lines.is_empty()
	# An opened program needs no purchase bar; the unit bar takes the full width.
	_buy_program.visible = not prog.owned
	_buy_unit.visible = not prog.is_photo_recon() or not prog.owned
	if not prog.owned:
		var why := "" if SimHardware.can_buy_program(p, prog) else _program_reason(p, prog, program_price)
		_restyle(_buy_program, "go" if why == "" else "blocked", "Purchase program (%d MB)" % program_price, why)
		if why == "":
			_buy_program.tooltip_text = "Open the %s program: one unit at %d%% safety" % [prog.display_name().capitalize(), safety]
	if _buy_unit.visible:
		var why_unit := "" if SimHardware.can_buy_unit(p, prog) and not prog.is_photo_recon() else _unit_reason(p, prog, unit_price)
		_restyle(_buy_unit, "go" if why_unit == "" else "blocked", "Buy unit (%d MB)" % unit_price, why_unit)
		if why_unit == "":
			_buy_unit.tooltip_text = "Add one unit to the %s inventory" % prog.display_name().capitalize()


## Why SimHardware.can_buy_program refuses, in the order it checks.
func _program_reason(p: SimPlayer, prog: SimProgram, price: int) -> String:
	if prog.owned:
		return "The program is already open."
	if prog.delay > 0:
		return "Purchases delayed %d more season%s." % [prog.delay, "" if prog.delay == 1 else "s"]
	if p.cash < price:
		return "Not enough cash: the program costs %d MB and you have %d MB." % [price, p.cash]
	return "Not available this season."


## Why SimHardware.can_buy_unit refuses, in the order it checks.
func _unit_reason(p: SimPlayer, prog: SimProgram, price: int) -> String:
	if not prog.owned:
		return "Purchase the program first."
	if prog.is_photo_recon():
		return "Photo reconnaissance has no units to buy."
	if prog.delay > 0:
		return "Purchases delayed %d more season%s." % [prog.delay, "" if prog.delay == 1 else "s"]
	if prog.units >= SimHardware.MAX_UNITS:
		return "Inventory full: %d of %d units on hand." % [prog.units, SimHardware.MAX_UNITS]
	if p.cash < price:
		return "Not enough cash: a unit costs %d MB and you have %d MB." % [price, p.cash]
	return "Not available this season."


# ----------------------------------------------------------------- commands

func _on_buy_program() -> void:
	if _selected == null or UiAction.is_blocked(_buy_program):
		return
	if SimHardware.buy_program(Session.state(), Session.me(), _selected):
		_result.text = "%s program opened at %d%% safety." % [_selected.display_name().capitalize(), _selected.safety]
		_result.add_theme_color_override("font_color", UiPalette.OK)
		Session.notify_change()
		_refresh()


func _on_buy_unit() -> void:
	if _selected == null or UiAction.is_blocked(_buy_unit):
		return
	if SimHardware.buy_unit(Session.me(), _selected):
		_result.text = "%s unit bought: %d on hand." % [_selected.display_name().capitalize(), _selected.units]
		_result.add_theme_color_override("font_color", UiPalette.OK)
		Session.notify_change()
		_refresh()
