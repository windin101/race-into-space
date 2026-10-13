extends ScreenPanel
## Program Offices: four picture tabs for the groups, then one card row per owned program
## with its picture and stat chips (units, safety, flights, condition). The selected
## program stands in a viewer beside the list, with its data, a safety gauge and the
## buy-unit action bar. Unopened programs are listed dimly with a link to Hardware Purchase.

const GROUP_TITLES := {"probe": "Unmanned", "rocket": "Rockets", "manned": "Capsules", "misc": "Misc"}
const HARDWARE_PURCHASE := "res://scenes/admin/hardware_purchase.tscn"
const CASE_BG := Color("0a1424")
const STRIP_H := 52.0
const ROW_HEIGHT := 92.0
const THUMB := 64.0

var _group := "rocket"
var _selected: SimProgram
var _owned: Array = []             ## owned SimPrograms in the current group, slot order
var _tabs: Dictionary = {}         ## group -> Button
var _rows: VBoxContainer
var _row_buttons: Dictionary = {}  ## SimProgram -> Button
var _unowned: VBoxContainer
var _case: Control
var _case_name: Label
var _prev: Button
var _next: Button
var _banner: Label
var _data_panel: UiPanel
var _stats: GridContainer
var _stat_values: Dictionary = {}
var _gauge: Gauge
var _gauge_marker: Control
var _gauge_max: Label
var _note: Label
var _buy: Button


func _init() -> void:
	super()
	title = "Program Offices"


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

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 16)
	content.add_child(split)

	# Program card rows.
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.4
	left.add_theme_constant_override("separation", 12)
	split.add_child(left)
	var banner_panel := PanelContainer.new()
	banner_panel.theme_type_variation = "Sunken"
	left.add_child(banner_panel)
	_banner = Label.new()
	_banner.theme_type_variation = "Heading"
	_banner.add_theme_color_override("font_color", UiPalette.GOLD)
	_banner.clip_text = true
	_banner.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	banner_panel.add_child(_banner)
	var list := UiPanel.new("Programs in service", "I008")
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(list)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list.body.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 14)
	scroll.add_child(column)
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 6)
	column.add_child(_rows)
	_unowned = VBoxContainer.new()
	_unowned.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_unowned.add_theme_constant_override("separation", 4)
	column.add_child(_unowned)

	# Viewer for the selected program, its data and the buy-unit bar.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.custom_minimum_size.x = 420
	right.add_theme_constant_override("separation", 12)
	split.add_child(right)
	var viewer := UiPanel.new()
	viewer.hide_title()
	viewer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(viewer)
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
	_data_panel = UiPanel.new("Program data", "I008")
	right.add_child(_data_panel)
	_stats = GridContainer.new()
	_stats.columns = 2
	_stats.add_theme_constant_override("h_separation", 24)
	_stats.add_theme_constant_override("v_separation", 2)
	_data_panel.body.add_child(_stats)
	for key in ["record", "max_rd", "max_safety", "unit_cost"]:
		var k := Label.new()
		k.text = {"record": "Flight record", "max_rd": "Maximum R&D", "max_safety": "Maximum safety", "unit_cost": "Unit cost"}[key]
		k.theme_type_variation = "Dim"
		_stats.add_child(k)
		var v := Label.new()
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_stats.add_child(v)
		_stat_values[key] = v
	var gauge_row := HBoxContainer.new()
	gauge_row.add_theme_constant_override("separation", 12)
	_data_panel.body.add_child(gauge_row)
	var gl := Label.new()
	gl.theme_type_variation = "Caps"
	gl.text = "SAFETY"
	gl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gauge_row.add_child(gl)
	_gauge = Gauge.new(false, "Safety now; the gold line is Maximum R&D")
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
	_note = Label.new()
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.theme_type_variation = "Small"
	_data_panel.body.add_child(_note)
	_buy = _data_panel.add_action("Buy unit", "go", func():
		if _selected != null:
			_on_buy_unit(_selected))
	_set_group(_group)
	set_room("room_lab")


func on_resume() -> void:
	_refresh()


# ----------------------------------------------------------------- building

## A card row: the program's picture, its name strip in caps and the stat chips the
## player compares programs on.
func _make_row(prog: SimProgram, side: String) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.custom_minimum_size.y = ROW_HEIGHT
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.tooltip_text = "Show the %s in the viewer" % prog.display_name().capitalize()
	b.pressed.connect(_select.bind(prog))
	var pad := MarginContainer.new()
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_theme_constant_override("margin_left", 10)
	pad.add_theme_constant_override("margin_right", 10)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_bottom", 8)
	b.add_child(pad)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14)
	pad.add_child(row)
	var icon := TextureRect.new()
	icon.texture = ArtAssets.hardware(side, prog.group, prog.slot)
	icon.custom_minimum_size = Vector2(THUMB, THUMB)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(box)
	var name_label := Label.new()
	name_label.theme_type_variation = "CapsBright"
	name_label.text = "%s · %s" % [prog.display_name().to_upper(), OpsView.kind_name(prog).to_upper()]
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 8)
	chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(chips)
	var units := "n/a" if prog.is_photo_recon() else "%d/%d" % [prog.units, SimHardware.MAX_UNITS]
	_chip(chips, "rocket", units, "Units on hand (of %d)" % SimHardware.MAX_UNITS, not prog.is_photo_recon() and prog.units == 0)
	_chip(chips, "safety", "%d%%" % prog.safety, "Safety factor", false, UiPalette.safety_color(prog.safety))
	_chip(chips, "review", "%d (%d failed)" % [prog.flights, prog.failures], "Flights flown (failed)")
	var cond_col := UiPalette.WARN if prog.delay > 0 else UiPalette.OK
	_chip(chips, "info", _condition(prog), "Condition: damage or purchase delay", prog.damage != 0, cond_col)
	return b


func _chip(parent: Control, icon: String, value: String, tip: String, blocking := false, colour := Color(0, 0, 0, 0)) -> StatChip:
	var c := StatChip.new(icon, "", tip)
	c.set_value(value, blocking, colour)
	# Pass clicks through to the row while keeping the chip's tooltip.
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(c)
	return c


func _condition(prog: SimProgram) -> String:
	if prog.damage != 0:
		return "DAMAGED %d%%" % prog.damage
	if prog.delay > 0:
		return "DELAYED %d" % prog.delay
	return "SOUND"


func _make_unowned_row(prog: SimProgram) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var name_label := Label.new()
	name_label.theme_type_variation = "Dim"
	name_label.text = "%s  (%s)" % [prog.display_name().capitalize(), OpsView.kind_name(prog)]
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	_chip(row, "cost", "%d MB" % prog.program_cost(), "Program cost").mouse_filter = Control.MOUSE_FILTER_STOP
	var link := Button.new()
	link.theme_type_variation = "Bar"
	link.text = "PURCHASE"
	link.custom_minimum_size.x = 150
	link.tooltip_text = "Open the %s program in Hardware Purchase" % prog.display_name().capitalize()
	link.pressed.connect(_open_hardware_purchase)
	row.add_child(link)
	return row


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


# ----------------------------------------------------------------- drawing

func _draw_case() -> void:
	var size := _case.size
	_case.draw_rect(Rect2(Vector2.ZERO, size), CASE_BG)
	var side := Session.human_side if Session.has_game() else "usa"
	var accent := UiPalette.accent(side)
	var stage := Vector2(size.x, size.y - STRIP_H)
	var centre := stage / 2.0
	for i in range(6, 0, -1):
		_case.draw_circle(centre, minf(stage.x, stage.y) * 0.08 * i, Color(accent, 0.025))
	if _selected == null:
		_case.draw_string(get_theme_default_font(), Vector2(0, centre.y), "No program selected", HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTheme.SIZE_SUBHEADING, UiPalette.TEXT_MUTED)
		return
	var rect := Rect2(Vector2.ZERO, stage).grow(-minf(stage.x, stage.y) * 0.08)
	HardwareArt.paint(_case, rect, _selected.group, _selected.slot, side)
	_case.draw_line(Vector2(size.x * 0.15, stage.y - 14), Vector2(size.x * 0.85, stage.y - 14), UiPalette.BORDER_SOFT, 2.0)


## The Maximum R&D line across the safety gauge's track (the gauge draws the track
## from x = 6 to size.x - 64).
func _draw_gauge_marker() -> void:
	if _selected == null:
		return
	var s := _gauge_marker.size
	var x := 6.0 + (s.x - 70.0) * clampf(_selected.max_rd / 100.0, 0.0, 1.0)
	_gauge_marker.draw_line(Vector2(x, 2), Vector2(x, s.y - 2), UiPalette.GOLD, 2.0)



# ----------------------------------------------------------------- state

func _set_group(g: String) -> void:
	_group = g
	for key in _tabs:
		_tabs[key].button_pressed = key == g
	_selected = null
	_refresh()


func _select(prog: SimProgram) -> void:
	_selected = prog
	_refresh_detail()


func _step(delta: int) -> void:
	if _owned.is_empty():
		return
	var at := _owned.find(_selected)
	_selected = _owned[posmod(at + delta, _owned.size())]
	_refresh_detail()


func _refresh() -> void:
	if not Session.has_game():
		return
	for c in _rows.get_children():
		c.queue_free()
	for c in _unowned.get_children():
		c.queue_free()
	_row_buttons.clear()
	var p := Session.me()
	var side := p.side
	for g in SimProgram.GROUPS:
		var pick: SimProgram = null
		for prog in p.programs[g]:
			if prog != null and (pick == null or (prog.owned and not pick.owned)):
				pick = prog
		_tabs[g].icon = ArtAssets.hardware(side, g, pick.slot) if pick != null else null
		_tabs[g].tooltip_text = "%s office" % GROUP_TITLES[g]
	_owned = []
	var unowned: Array = []
	for prog in p.programs[_group]:
		if prog == null:
			continue
		if prog.owned:
			_owned.append(prog)
		else:
			unowned.append(prog)
	for prog in _owned:
		var b := _make_row(prog, side)
		_rows.add_child(b)
		_row_buttons[prog] = b
	if _owned.is_empty():
		var none := Label.new()
		none.theme_type_variation = "Dim"
		none.text = "No programs in this group have been opened yet."
		_rows.add_child(none)
	if not unowned.is_empty():
		var heading := Label.new()
		heading.theme_type_variation = "Caps"
		heading.text = "NOT YET OPENED"
		_unowned.add_child(heading)
		for prog in unowned:
			_unowned.add_child(_make_unowned_row(prog))
	if _selected == null or not _owned.has(_selected):
		_selected = _owned[0] if not _owned.is_empty() else null
	_banner.text = "%s OFFICE: %d PROGRAM%s" % [GROUP_TITLES[_group].to_upper(), _owned.size(), "" if _owned.size() == 1 else "S"]
	_refresh_detail()


func _refresh_detail() -> void:
	for prog in _row_buttons:
		_row_buttons[prog].button_pressed = prog == _selected
	_case.queue_redraw()
	_gauge_marker.queue_redraw()
	_prev.disabled = _owned.size() < 2
	_next.disabled = _owned.size() < 2
	for b in [_prev, _next]:
		b.tooltip_text = ("Previous program" if b == _prev else "Next program") if _owned.size() >= 2 else "Only one program in service"
	var prog := _selected
	var has := prog != null
	_data_panel.visible = has
	if not has:
		_case_name.text = "NOTHING IN SERVICE"
		_note.text = ""
		return
	var p := Session.me()
	_case_name.text = "%s · %s" % [prog.display_name().to_upper(), OpsView.kind_name(prog).to_upper()]
	_stat_values["record"].text = "%d flown, %d succeeded, %d failed" % [prog.flights, prog.successes, prog.failures]
	_stat_values["max_rd"].text = "%d%%" % prog.max_rd
	_stat_values["max_safety"].text = "%d%%" % prog.max_safety()
	_stat_values["unit_cost"].text = "%d MB" % SimHardware.unit_price(p, prog)
	_gauge.value = prog.safety
	_gauge_max.text = "MAX R&D %d%%" % prog.max_rd
	var lines: PackedStringArray = []
	if prog.delay > 0:
		lines.append("Purchases delayed for %d more season%s." % [prog.delay, "" if prog.delay == 1 else "s"])
	if prog.damage != 0:
		lines.append("Damaged: %d%% on its next flight unless %d MB is paid in R&D." % [prog.damage, prog.damage_cost])
	_note.text = "\n".join(lines)
	_note.visible = not lines.is_empty()
	var price := SimHardware.unit_price(p, prog)
	var why := ""
	if prog.is_photo_recon():
		why = "Photo reconnaissance has no units to buy."
	elif not SimHardware.can_buy_unit(p, prog):
		if prog.delay > 0:
			why = "Purchases delayed %d more season%s." % [prog.delay, "" if prog.delay == 1 else "s"]
		elif prog.units >= SimHardware.MAX_UNITS:
			why = "Inventory full: %d of %d units on hand." % [prog.units, SimHardware.MAX_UNITS]
		elif p.cash < price:
			why = "Not enough cash: a unit costs %d MB and you have %d MB." % [price, p.cash]
		else:
			why = "Not available this season."
	UiAction.go_or_blocked(_buy, "Buy unit (%d MB)" % price, why)
	if why == "":
		_buy.tooltip_text = "Add one unit to the %s inventory" % prog.display_name().capitalize()


# ----------------------------------------------------------------- commands

func _on_buy_unit(prog: SimProgram) -> void:
	if UiAction.is_blocked(_buy):
		return
	if SimHardware.buy_unit(Session.me(), prog):
		Session.notify_change()
		_refresh()


func _open_hardware_purchase() -> void:
	if ResourceLoader.exists(HARDWARE_PURCHASE):
		Screens.push(load(HARDWARE_PURCHASE), {})
