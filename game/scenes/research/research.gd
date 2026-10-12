extends ScreenPanel
## Research & Development, laid out like a hardware showroom: four picture tabs for the
## groups, a display case with the selected program's illustration and arrows to cycle,
## a stats sheet beside it, a row of engineer-team figures to pick how many teams to
## assign, and the research and damage-repair commands. All rules come from SimHardware
## and SimEvents; this screen only presents them.

const GROUP_TITLES := {"probe": "Unmanned", "rocket": "Rockets", "manned": "Capsules", "misc": "Misc"}
const PURCHASE := "res://scenes/admin/hardware_purchase.tscn"
const CASE_BG := Color("0a1424")

var _group := "rocket"
var _programs: Array = []          ## owned SimPrograms in the current group
var _index := 0
var _selected: SimProgram

var _tabs: Dictionary = {}         ## group -> Button
var _chips: HBoxContainer
var _case: Control
var _case_name: Label
var _prev: Button
var _next: Button
var _stats: GridContainer
var _stat_values: Dictionary = {}
var _teams := 1
var _team_buttons: Array = []
var _cost: Label
var _expected: Label
var _note: Label
var _result: Label
var _research: Button
var _pay_damage: Button


func _init() -> void:
	super()
	title = "Research & Development"


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
	UiHelp.attach(tabs, "I007")
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
	var visit := Button.new()
	visit.text = "Visit Purchasing Facility"
	visit.pressed.connect(func(): Screens.push(load(PURCHASE), {"id": "hardware", "title": "Hardware Purchase", "help": "I008"}))
	left.add_child(visit)

	# Stats sheet.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.custom_minimum_size.x = 420
	right.add_theme_constant_override("separation", 10)
	split.add_child(right)
	var sheet := PanelContainer.new()
	sheet.theme_type_variation = "Card"
	right.add_child(sheet)
	var sheet_box := VBoxContainer.new()
	sheet_box.add_theme_constant_override("separation", 6)
	sheet.add_child(sheet_box)
	_stats = GridContainer.new()
	_stats.columns = 2
	_stats.add_theme_constant_override("h_separation", 24)
	_stats.add_theme_constant_override("v_separation", 4)
	sheet_box.add_child(_stats)
	for key in ["units", "program_cost", "unit_cost", "safety", "rd_cost", "weight", "max_rd", "max_safety", "record"]:
		var k := Label.new()
		k.text = {"units": "Units on hand", "program_cost": "Initial cost", "unit_cost": "Unit cost", "safety": "Safety factor",
				  "rd_cost": "R&D cost per team", "weight": "Unit weight", "max_rd": "Maximum R&D", "max_safety": "Maximum safety",
				  "record": "Flight record"}[key]
		k.theme_type_variation = "Dim"
		_stats.add_child(k)
		var v := Label.new()
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_stats.add_child(v)
		_stat_values[key] = v

	# Teams: five figures, click the count to assign.
	var teams_title := Label.new()
	teams_title.theme_type_variation = "Dim"
	teams_title.text = "Engineering teams this season"
	right.add_child(teams_title)
	var team_row := HBoxContainer.new()
	team_row.add_theme_constant_override("separation", 8)
	right.add_child(team_row)
	for n in range(1, SimHardware.MAX_TEAMS + 1):
		var tb := Button.new()
		tb.toggle_mode = true
		tb.custom_minimum_size = Vector2(72, 60)
		tb.tooltip_text = "%d team%s" % [n, "" if n == 1 else "s"]
		tb.draw.connect(_draw_team_button.bind(tb, n))
		tb.pressed.connect(_set_teams.bind(n))
		team_row.add_child(tb)
		_team_buttons.append(tb)
	_cost = Label.new()
	_cost.theme_type_variation = "Subheading"
	right.add_child(_cost)
	_expected = Label.new()
	_expected.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_expected.theme_type_variation = "Small"
	right.add_child(_expected)
	_note = Label.new()
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.theme_type_variation = "Small"
	right.add_child(_note)
	_research = Button.new()
	_research.theme_type_variation = "Accent"
	_research.pressed.connect(_on_research)
	right.add_child(_research)
	_result = Label.new()
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_result)
	_pay_damage = Button.new()
	_pay_damage.theme_type_variation = "Danger"
	_pay_damage.pressed.connect(_on_pay_damage)
	right.add_child(_pay_damage)
	_set_group(_group)


func on_resume() -> void:
	_refresh()


# ----------------------------------------------------------------- drawing

func _draw_case() -> void:
	var size := _case.size
	_case.draw_rect(Rect2(Vector2.ZERO, size), CASE_BG)
	# A soft spotlight behind the exhibit.
	var centre := size / 2.0
	for i in range(6, 0, -1):
		_case.draw_circle(centre, minf(size.x, size.y) * 0.08 * i, Color(UiPalette.ACCENT_USA, 0.025))
	if _selected == null:
		_case.draw_string(get_theme_default_font(), Vector2(0, centre.y), "No program selected", HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTheme.SIZE_SUBHEADING, UiPalette.TEXT_MUTED)
		return
	var side := Session.human_side if Session.has_game() else "usa"
	var rect := Rect2(Vector2.ZERO, size).grow(-minf(size.x, size.y) * 0.08)
	HardwareArt.paint(_case, rect, _selected.group, _selected.slot, side)
	# Plinth line.
	_case.draw_line(Vector2(size.x * 0.15, size.y - 18), Vector2(size.x * 0.85, size.y - 18), UiPalette.BORDER_SOFT, 2.0)


func _draw_team_button(btn: Button, n: int) -> void:
	var size := btn.size
	var col := UiPalette.TEXT if btn.button_pressed else UiPalette.TEXT_MUTED
	var fig_w := 11.0
	var total := fig_w * n + 3.0 * (n - 1)
	var x := (size.x - total) / 2.0
	var y := size.y / 2.0 - 17.0
	for i in n:
		var cx := x + fig_w / 2.0
		btn.draw_circle(Vector2(cx, y), 4.0, col)
		btn.draw_rect(Rect2(cx - 5.0, y + 5.0, 10.0, 13.0), col)
		btn.draw_rect(Rect2(cx - 4.0, y + 18.0, 3.0, 7.0), col)
		btn.draw_rect(Rect2(cx + 1.0, y + 18.0, 3.0, 7.0), col)
		x += fig_w + 3.0
	btn.draw_string(get_theme_default_font(), Vector2(0, size.y - 6), str(n), HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTheme.SIZE_SMALL, col)


# ----------------------------------------------------------------- state

func _set_group(g: String) -> void:
	_group = g
	for key in _tabs:
		_tabs[key].button_pressed = key == g
	_index = 0
	_selected = null
	_result.text = ""
	_refresh()


func _set_teams(n: int) -> void:
	_teams = n
	_refresh_cost()


func _step(delta: int) -> void:
	if _programs.is_empty():
		return
	_index = posmod(_index + delta, _programs.size())
	_selected = _programs[_index]
	_result.text = ""
	_refresh_detail()


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
		var tex: Texture2D = ArtAssets.hardware(side, g, pick.slot) if pick != null else null
		_tabs[g].icon = tex
	_programs = []
	for prog in p.programs[_group]:
		if prog != null and prog.owned:
			_programs.append(prog)
	for c in _chips.get_children():
		c.queue_free()
	for i in _programs.size():
		var chip := Button.new()
		chip.text = _programs[i].display_name().capitalize()
		chip.theme_type_variation = "Flat"
		chip.toggle_mode = true
		chip.pressed.connect(func():
			_index = i
			_selected = _programs[i]
			_result.text = ""
			_refresh_detail())
		_chips.add_child(chip)
	if _programs.is_empty():
		_selected = null
	else:
		_index = clampi(_index, 0, _programs.size() - 1)
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
	_stats.get_parent().get_parent().visible = has
	_cost.visible = has
	_expected.visible = has
	_research.visible = has
	_pay_damage.visible = false
	for tb in _team_buttons:
		tb.visible = has
	if not has:
		_case_name.text = "Nothing to research"
		_note.text = "No programs in this group have been opened. Open them in the Purchasing Facility."
		return
	var p := Session.me()
	_case_name.text = "%s   %s" % [prog.display_name().capitalize(), OpsView.kind_name(prog)]
	_stat_values["units"].text = str(prog.units)
	_stat_values["program_cost"].text = "%d MB" % prog.program_cost()
	_stat_values["unit_cost"].text = "%d MB" % prog.unit_cost()
	_stat_values["safety"].text = "%d%%" % prog.safety
	_stat_values["safety"].add_theme_color_override("font_color", UiPalette.safety_color(prog.safety))
	_stat_values["rd_cost"].text = "%d MB" % prog.rd_cost()
	if prog.is_rocket():
		_stats.get_child(_stats.get_children().find(_stat_values["weight"]) - 1).text = "Maximum payload"
		_stat_values["weight"].text = str(prog.spec.get("max_payload", 0))
	else:
		_stats.get_child(_stats.get_children().find(_stat_values["weight"]) - 1).text = "Unit weight"
		_stat_values["weight"].text = str(prog.spec.get("unit_weight", 0)) if int(prog.spec.get("unit_weight", 0)) > 0 else "n/a"
	_stat_values["max_rd"].text = "%d%%" % prog.max_rd
	_stat_values["max_safety"].text = "%d%%" % prog.max_safety()
	_stat_values["record"].text = "%d flight%s, %d failure%s" % [prog.flights, "" if prog.flights == 1 else "s", prog.failures, "" if prog.failures == 1 else "s"]
	var max_teams := SimHardware.max_teams(p, prog)
	var block := OpsView.research_block_reason(p, prog)
	_teams = clampi(_teams, 1, maxi(1, max_teams))
	for i in _team_buttons.size():
		var tb: Button = _team_buttons[i]
		tb.disabled = block != "" or i + 1 > max_teams
		tb.button_pressed = i + 1 == _teams
		tb.queue_redraw()
	var lines: PackedStringArray = []
	if block != "":
		lines.append(block)
	else:
		lines.append("Up to %d team%s may be assigned this season." % [max_teams, "" if max_teams == 1 else "s"])
	if p.rd_mods_turn != 0:
		lines.append("Research rolls use a 1d%d die this season." % OpsView.rd_die(p))
	if prog.damage != 0:
		lines.append("Damaged: %d%% on its next flight unless %d MB is paid to clear it." % [prog.damage, prog.damage_cost])
		_pay_damage.visible = true
		_pay_damage.text = "Pay to clear damage  (%d MB)" % prog.damage_cost
		_pay_damage.disabled = p.cash < prog.damage_cost
	_note.text = "\n".join(lines)
	_refresh_cost()


func _refresh_cost() -> void:
	var prog := _selected
	if prog == null:
		return
	var p := Session.me()
	var cost := SimHardware.research_cost(p, prog, _teams)
	for i in _team_buttons.size():
		var tb: Button = _team_buttons[i]
		tb.button_pressed = i + 1 == _teams
		tb.queue_redraw()
	_cost.text = "Research program for %d MB" % cost
	var headroom := prog.max_rd - prog.safety
	_expected.text = OpsView.expected_gain_text(_teams, p.rd_mods_turn) + ", capped at %d%% more (Max R&D %d%%)." % [maxi(headroom, 0), prog.max_rd]
	_research.text = "Research  (%d MB)" % cost
	_research.disabled = OpsView.research_block_reason(p, prog) != "" or p.cash < cost


# ----------------------------------------------------------------- commands

func _on_research() -> void:
	if _selected == null:
		return
	var prog := _selected
	var before := prog.safety
	var gain := SimHardware.research(Session.state(), Session.me(), prog, _teams)
	if gain < 0:
		_result.text = "Research refused."
		_result.add_theme_color_override("font_color", UiPalette.DANGER)
		return
	_result.text = "%s gained +%d%% safety: %d%% to %d%%." % [prog.display_name().capitalize(), gain, before, prog.safety]
	_result.add_theme_color_override("font_color", UiPalette.OK)
	Session.notify_change()
	_refresh()


func _on_pay_damage() -> void:
	if _selected == null:
		return
	if SimEvents.pay_damage(Session.me(), _selected):
		_result.text = "%s damage cleared." % _selected.display_name().capitalize()
		_result.add_theme_color_override("font_color", UiPalette.OK)
		Session.notify_change()
		_refresh()
