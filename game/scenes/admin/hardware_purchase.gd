extends ScreenPanel
## Hardware Purchase, laid out like the Research showroom: four picture tabs for the
## groups, name chips and a display case over every program in the group (owned or not),
## a stats sheet beside it, then the purchase board with the program and unit prices and
## the cash line. All rules come from SimHardware; this screen only presents them.

const GROUP_TITLES := {"probe": "Unmanned", "rocket": "Rockets", "manned": "Capsules", "misc": "Misc"}
const CASE_BG := Color("0a1424")
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
var _stats: GridContainer
var _stat_keys: Dictionary = {}
var _stat_values: Dictionary = {}
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
	split.add_theme_constant_override("separation", 20)
	content.add_child(split)

	# Display case.
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.1
	left.add_theme_constant_override("separation", 8)
	split.add_child(left)
	var case_panel := PanelContainer.new()
	case_panel.theme_type_variation = "Sunken"
	case_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(case_panel)
	_case = Control.new()
	_case.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_case.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_case.clip_contents = true
	_case.draw.connect(_draw_case)
	_case.resized.connect(_case.queue_redraw)
	case_panel.add_child(_case)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 10)
	left.add_child(nav)
	_prev = Button.new()
	_prev.text = "◀"
	_prev.custom_minimum_size.x = 64
	_prev.pressed.connect(func(): _step(-1))
	nav.add_child(_prev)
	_case_name = Label.new()
	_case_name.theme_type_variation = "Subheading"
	_case_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_case_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(_case_name)
	_next = Button.new()
	_next.text = "▶"
	_next.custom_minimum_size.x = 64
	_next.pressed.connect(func(): _step(1))
	nav.add_child(_next)

	# Banner, stats sheet and the purchase board.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.custom_minimum_size.x = 420
	right.add_theme_constant_override("separation", 10)
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
	var sheet := PanelContainer.new()
	sheet.theme_type_variation = "Card"
	right.add_child(sheet)
	_stats = GridContainer.new()
	_stats.columns = 2
	_stats.add_theme_constant_override("h_separation", 24)
	_stats.add_theme_constant_override("v_separation", 4)
	sheet.add_child(_stats)
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
	_detail = Label.new()
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.theme_type_variation = "Small"
	right.add_child(_detail)

	var board := PanelContainer.new()
	board.theme_type_variation = "Card"
	right.add_child(board)
	var board_box := VBoxContainer.new()
	board_box.add_theme_constant_override("separation", 6)
	board.add_child(board_box)
	var board_title := Label.new()
	board_title.text = "PURCHASING"
	board_title.theme_type_variation = "Subheading"
	board_title.add_theme_color_override("font_color", UiPalette.GOLD)
	board_box.add_child(board_title)
	_buy_program = Button.new()
	_buy_program.theme_type_variation = "Accent"
	_buy_program.pressed.connect(_on_buy_program)
	board_box.add_child(_buy_program)
	_buy_unit = Button.new()
	_buy_unit.pressed.connect(_on_buy_unit)
	board_box.add_child(_buy_unit)
	_cash = Label.new()
	_cash.theme_type_variation = "Subheading"
	_cash.add_theme_color_override("font_color", UiPalette.INFO)
	board_box.add_child(_cash)
	_result = Label.new()
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_result)
	_set_group(_group)


func on_resume() -> void:
	_refresh()


# ----------------------------------------------------------------- drawing

func _draw_case() -> void:
	var size := _case.size
	_case.draw_rect(Rect2(Vector2.ZERO, size), CASE_BG)
	var side := Session.human_side if Session.has_game() else "usa"
	var accent := UiPalette.ACCENT_USSR if side == "ussr" else UiPalette.ACCENT_USA
	# A soft spotlight behind the exhibit.
	var centre := size / 2.0
	for i in range(6, 0, -1):
		_case.draw_circle(centre, minf(size.x, size.y) * 0.08 * i, Color(accent, 0.025))
	if _selected == null:
		_case.draw_string(get_theme_default_font(), Vector2(0, centre.y), "No programs in this group", HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTheme.SIZE_SUBHEADING, UiPalette.TEXT_MUTED)
		return
	var rect := Rect2(Vector2.ZERO, size).grow(-minf(size.x, size.y) * 0.08)
	HardwareArt.paint(_case, rect, _selected.group, _selected.slot, side)
	# Plinth line.
	_case.draw_line(Vector2(size.x * 0.15, size.y - 18), Vector2(size.x * 0.85, size.y - 18), UiPalette.BORDER_SOFT, 2.0)
	if not _selected.owned:
		# Unopened programs sit behind glass with a status band, like a catalogue page.
		_case.draw_rect(Rect2(Vector2.ZERO, size), Color(CASE_BG, 0.45))
		var col := UiPalette.WARN if _selected.delay > 0 else UiPalette.INFO
		_case.draw_rect(Rect2(0, size.y - 34, size.x, 34), Color(0, 0, 0, 0.55))
		_case.draw_string(get_theme_default_font(), Vector2(0, size.y - 11), _status_text(_selected).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTheme.SIZE_SMALL, col)


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
		chip.tooltip_text = _status_text(prog)
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
	_prev.disabled = _programs.size() < 2
	_next.disabled = _programs.size() < 2
	for i in _chips.get_child_count():
		var chip: Button = _chips.get_child(i)
		chip.button_pressed = i == _index and has
	if not Session.has_game():
		return
	var p := Session.me()
	_cash.text = "CASH ON HAND: %d MB" % p.cash
	_stats.get_parent().visible = has
	if not has:
		_case_name.text = "Nothing to purchase"
		_banner.text = "HARDWARE PURCHASE"
		_detail.text = ""
		_buy_program.text = "Purchase program"
		_buy_program.disabled = true
		_buy_unit.text = "Buy unit"
		_buy_unit.disabled = true
		return
	_case_name.text = "%s   %s" % [prog.display_name().capitalize(), OpsView.kind_name(prog)]
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
	_buy_program.text = "Program purchased" if prog.owned else "Purchase program  (%d MB)" % program_price
	_buy_program.disabled = not SimHardware.can_buy_program(p, prog)
	_buy_unit.text = "Buy unit  (%d MB)" % unit_price
	_buy_unit.disabled = not prog.owned or prog.is_photo_recon() or not SimHardware.can_buy_unit(p, prog)


# ----------------------------------------------------------------- commands

func _on_buy_program() -> void:
	if _selected == null:
		return
	if SimHardware.buy_program(Session.state(), Session.me(), _selected):
		_result.text = "%s program opened at %d%% safety." % [_selected.display_name().capitalize(), _selected.safety]
		_result.add_theme_color_override("font_color", UiPalette.OK)
		Session.notify_change()
		_refresh()


func _on_buy_unit() -> void:
	if _selected == null:
		return
	if SimHardware.buy_unit(Session.me(), _selected):
		_result.text = "%s unit bought: %d on hand." % [_selected.display_name().capitalize(), _selected.units]
		_result.add_theme_color_override("font_color", UiPalette.OK)
		Session.notify_change()
		_refresh()
