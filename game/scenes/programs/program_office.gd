extends ScreenPanel
## Program Offices: four picture tabs for the groups, then one row per owned program with
## its icon, inventory, safety, flight record and damage state. The selected program
## stands in a display case beside the list with its buy-unit command. Unopened programs
## are listed dimly with a link to Hardware Purchase.

const GROUP_TITLES := {"probe": "Unmanned", "rocket": "Rockets", "manned": "Capsules", "misc": "Misc"}
const HARDWARE_PURCHASE := "res://scenes/admin/hardware_purchase.tscn"
const CASE_BG := Color("0a1424")
const ROW_HEIGHT := 64.0
## Column widths of the programme rows (icon, name stretches, then the numbers).
const COLS := {"icon": 56.0, "units": 110.0, "safety": 90.0, "flights": 170.0, "state": 170.0}

var _group := "rocket"
var _selected: SimProgram
var _tabs: Dictionary = {}         ## group -> Button
var _rows: VBoxContainer
var _row_buttons: Dictionary = {}  ## SimProgram -> Button
var _unowned: VBoxContainer
var _case: Control
var _case_name: Label
var _banner: Label
var _stats: GridContainer
var _stat_values: Dictionary = {}
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
	split.add_theme_constant_override("separation", 20)
	content.add_child(split)

	# Programme rows.
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.5
	left.add_theme_constant_override("separation", 6)
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
	left.add_child(_make_header())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	scroll.add_child(column)
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 4)
	column.add_child(_rows)
	_unowned = VBoxContainer.new()
	_unowned.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_unowned.add_theme_constant_override("separation", 2)
	column.add_child(_unowned)

	# Display case for the selected programme.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.custom_minimum_size.x = 400
	right.add_theme_constant_override("separation", 8)
	split.add_child(right)
	var case_panel := PanelContainer.new()
	case_panel.theme_type_variation = "Sunken"
	case_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(case_panel)
	_case = Control.new()
	_case.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_case.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_case.clip_contents = true
	_case.draw.connect(_draw_case)
	_case.resized.connect(_case.queue_redraw)
	case_panel.add_child(_case)
	_case_name = Label.new()
	_case_name.theme_type_variation = "Subheading"
	_case_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(_case_name)
	var sheet := PanelContainer.new()
	sheet.theme_type_variation = "Card"
	right.add_child(sheet)
	_stats = GridContainer.new()
	_stats.columns = 2
	_stats.add_theme_constant_override("h_separation", 24)
	_stats.add_theme_constant_override("v_separation", 4)
	sheet.add_child(_stats)
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
	_note = Label.new()
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.theme_type_variation = "Small"
	right.add_child(_note)
	_buy = Button.new()
	_buy.theme_type_variation = "Accent"
	_buy.pressed.connect(func():
		if _selected != null:
			_on_buy_unit(_selected))
	right.add_child(_buy)
	_set_group(_group)


func on_resume() -> void:
	_refresh()


# ----------------------------------------------------------------- building

func _cell(text: String, width: float, align := HORIZONTAL_ALIGNMENT_RIGHT, variation := "") -> Label:
	var l := Label.new()
	l.text = text
	l.custom_minimum_size.x = width
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if variation != "":
		l.theme_type_variation = variation
	return l


func _make_header() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 10)
	pad.add_theme_constant_override("margin_right", 10)
	pad.add_child(row)
	row.add_child(_cell("", COLS["icon"]))
	var name_label := _cell("PROGRAM", 0, HORIZONTAL_ALIGNMENT_LEFT, "Dim")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	row.add_child(_cell("UNITS", COLS["units"], HORIZONTAL_ALIGNMENT_RIGHT, "Dim"))
	row.add_child(_cell("SAFETY", COLS["safety"], HORIZONTAL_ALIGNMENT_RIGHT, "Dim"))
	row.add_child(_cell("FLIGHTS", COLS["flights"], HORIZONTAL_ALIGNMENT_RIGHT, "Dim"))
	row.add_child(_cell("CONDITION", COLS["state"], HORIZONTAL_ALIGNMENT_RIGHT, "Dim"))
	return pad


func _make_row(prog: SimProgram, side: String) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.custom_minimum_size.y = ROW_HEIGHT
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(_select.bind(prog))
	var pad := MarginContainer.new()
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_theme_constant_override("margin_left", 10)
	pad.add_theme_constant_override("margin_right", 10)
	b.add_child(pad)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	pad.add_child(row)
	var icon := TextureRect.new()
	icon.texture = ArtAssets.hardware(side, prog.group, prog.slot)
	icon.custom_minimum_size = Vector2(COLS["icon"], COLS["icon"])
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var name_box := VBoxContainer.new()
	name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_box.alignment = BoxContainer.ALIGNMENT_CENTER
	name_box.add_theme_constant_override("separation", 0)
	row.add_child(name_box)
	var name_label := _cell(prog.display_name().capitalize(), 0, HORIZONTAL_ALIGNMENT_LEFT, "Subheading")
	name_box.add_child(name_label)
	name_box.add_child(_cell(OpsView.kind_name(prog), 0, HORIZONTAL_ALIGNMENT_LEFT, "Small"))
	row.add_child(_cell("n/a" if prog.is_photo_recon() else "%d / %d" % [prog.units, SimHardware.MAX_UNITS], COLS["units"]))
	var safety := _cell("%d%%" % prog.safety, COLS["safety"])
	safety.add_theme_color_override("font_color", UiPalette.safety_color(prog.safety))
	row.add_child(safety)
	row.add_child(_cell("%d  (%d failed)" % [prog.flights, prog.failures], COLS["flights"]))
	var state := _cell(_condition(prog), COLS["state"])
	state.add_theme_color_override("font_color", UiPalette.DANGER if prog.damage != 0 else (UiPalette.WARN if prog.delay > 0 else UiPalette.OK))
	row.add_child(state)
	for l in row.get_children():
		if l is Control:
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for l in name_box.get_children():
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


func _condition(prog: SimProgram) -> String:
	if prog.damage != 0:
		return "DAMAGED %d%%" % prog.damage
	if prog.delay > 0:
		return "DELAYED %d" % prog.delay
	return "SOUND"


func _make_unowned_row(prog: SimProgram) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.modulate.a = 0.7
	var name_label := Label.new()
	name_label.theme_type_variation = "Dim"
	name_label.text = "%s  (%s, program %d MB)" % [prog.display_name().capitalize(), OpsView.kind_name(prog), prog.program_cost()]
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var link := Button.new()
	link.theme_type_variation = "Flat"
	link.text = "buy in Hardware Purchase"
	link.pressed.connect(_open_hardware_purchase)
	row.add_child(link)
	return row


# ----------------------------------------------------------------- drawing

func _draw_case() -> void:
	var size := _case.size
	_case.draw_rect(Rect2(Vector2.ZERO, size), CASE_BG)
	var side := Session.human_side if Session.has_game() else "usa"
	var accent := UiPalette.ACCENT_USSR if side == "ussr" else UiPalette.ACCENT_USA
	var centre := size / 2.0
	for i in range(6, 0, -1):
		_case.draw_circle(centre, minf(size.x, size.y) * 0.08 * i, Color(accent, 0.025))
	if _selected == null:
		_case.draw_string(get_theme_default_font(), Vector2(0, centre.y), "No program selected", HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTheme.SIZE_SUBHEADING, UiPalette.TEXT_MUTED)
		return
	var rect := Rect2(Vector2.ZERO, size).grow(-minf(size.x, size.y) * 0.08)
	HardwareArt.paint(_case, rect, _selected.group, _selected.slot, side)
	_case.draw_line(Vector2(size.x * 0.15, size.y - 18), Vector2(size.x * 0.85, size.y - 18), UiPalette.BORDER_SOFT, 2.0)


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
	var owned: Array = []
	var unowned: Array = []
	for prog in p.programs[_group]:
		if prog == null:
			continue
		if prog.owned:
			owned.append(prog)
		else:
			unowned.append(prog)
	for prog in owned:
		var b := _make_row(prog, side)
		_rows.add_child(b)
		_row_buttons[prog] = b
	if owned.is_empty():
		var none := Label.new()
		none.theme_type_variation = "Dim"
		none.text = "No programs in this group have been opened yet."
		_rows.add_child(none)
	if not unowned.is_empty():
		var heading := Label.new()
		heading.theme_type_variation = "Subheading"
		heading.add_theme_color_override("font_color", UiPalette.GOLD)
		heading.text = "NOT YET OPENED"
		_unowned.add_child(heading)
		for prog in unowned:
			_unowned.add_child(_make_unowned_row(prog))
	if _selected == null or not owned.has(_selected):
		_selected = owned[0] if not owned.is_empty() else null
	_banner.text = "%s OFFICE: %d PROGRAM%s" % [GROUP_TITLES[_group].to_upper(), owned.size(), "" if owned.size() == 1 else "S"]
	_refresh_detail()


func _refresh_detail() -> void:
	for prog in _row_buttons:
		_row_buttons[prog].button_pressed = prog == _selected
	_case.queue_redraw()
	var prog := _selected
	var has := prog != null
	_stats.get_parent().visible = has
	_buy.visible = has
	if not has:
		_case_name.text = "Nothing in service"
		_note.text = ""
		return
	var p := Session.me()
	_case_name.text = "%s   %s" % [prog.display_name().capitalize(), OpsView.kind_name(prog)]
	_stat_values["record"].text = "%d flown, %d succeeded, %d failed" % [prog.flights, prog.successes, prog.failures]
	_stat_values["max_rd"].text = "%d%%" % prog.max_rd
	_stat_values["max_safety"].text = "%d%%" % prog.max_safety()
	_stat_values["unit_cost"].text = "%d MB" % SimHardware.unit_price(p, prog)
	var lines: PackedStringArray = []
	if prog.delay > 0:
		lines.append("Purchases delayed for %d more season%s." % [prog.delay, "" if prog.delay == 1 else "s"])
	if prog.damage != 0:
		lines.append("Damaged: %d%% on its next flight unless %d MB is paid in R&D." % [prog.damage, prog.damage_cost])
	_note.text = "\n".join(lines)
	_note.visible = not lines.is_empty()
	_buy.text = "Buy unit  (%d MB)" % SimHardware.unit_price(p, prog)
	_buy.disabled = prog.is_photo_recon() or not SimHardware.can_buy_unit(p, prog)


# ----------------------------------------------------------------- commands

func _on_buy_unit(prog: SimProgram) -> void:
	if SimHardware.buy_unit(Session.me(), prog):
		Session.notify_change()
		_refresh()


func _open_hardware_purchase() -> void:
	if ResourceLoader.exists(HARDWARE_PURCHASE):
		Screens.push(load(HARDWARE_PURCHASE), {})
