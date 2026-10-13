extends ScreenPanel
## Research & Development, laid out like a hardware showroom: four picture tabs for the
## groups, a viewer with the selected program's illustration and a name strip with arrows
## to cycle, the program data with a safety gauge against Maximum R&D, then the
## engineering teams board whose action bar runs the research (or says why it cannot).
## All rules come from SimHardware and SimEvents; this screen only presents them.

const GROUP_TITLES := {"probe": "Unmanned", "rocket": "Rockets", "manned": "Capsules", "misc": "Misc"}
const PURCHASE := "res://scenes/admin/hardware_purchase.tscn"
const CASE_BG := Color("0a1424")
const STRIP_H := 52.0

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
var _data_panel: UiPanel
var _stats: GridContainer
var _stat_values: Dictionary = {}
var _gauge: Gauge
var _gauge_marker: Control
var _gauge_max: Label
var _teams_panel: UiPanel
var _teams := 1
var _team_buttons: Array = []
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
	_info_badge(_case, "I007")
	var visit := viewer.add_action("Visit purchasing facility", "neutral",
			func(): Screens.push(load(PURCHASE), {"id": "hardware", "title": "Hardware Purchase", "help": "I008"}))
	visit.tooltip_text = "Open new programs and buy units in Hardware Purchase"

	# Program data and the teams board.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.custom_minimum_size.x = 420
	right.add_theme_constant_override("separation", 12)
	split.add_child(right)
	_data_panel = UiPanel.new("Program data", "I007")
	right.add_child(_data_panel)
	_stats = GridContainer.new()
	_stats.columns = 2
	_stats.add_theme_constant_override("h_separation", 24)
	_stats.add_theme_constant_override("v_separation", 2)
	_data_panel.body.add_child(_stats)
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

	# Teams: five figures, click the count to assign.
	_teams_panel = UiPanel.new("Engineering teams this season", "I007")
	_teams_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_teams_panel)
	var team_row := HBoxContainer.new()
	team_row.add_theme_constant_override("separation", 8)
	_teams_panel.body.add_child(team_row)
	for n in range(1, SimHardware.MAX_TEAMS + 1):
		var tb := Button.new()
		tb.toggle_mode = true
		tb.custom_minimum_size = Vector2(72, 60)
		tb.tooltip_text = "%d team%s" % [n, "" if n == 1 else "s"]
		tb.draw.connect(_draw_team_button.bind(tb, n))
		tb.pressed.connect(_set_teams.bind(n))
		team_row.add_child(tb)
		_team_buttons.append(tb)
	_expected = Label.new()
	_expected.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_expected.theme_type_variation = "Small"
	_teams_panel.body.add_child(_expected)
	_note = Label.new()
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.theme_type_variation = "Small"
	_teams_panel.body.add_child(_note)
	_result = Label.new()
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_teams_panel.body.add_child(_result)
	_research = _teams_panel.add_action("Research", "go", _on_research)
	_pay_damage = _teams_panel.add_action("Clear damage", "caution", _on_pay_damage)
	_pay_damage.visible = false
	_set_group(_group)
	set_room("room_lab")


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
	var stage := Vector2(size.x, size.y - STRIP_H)
	# A soft spotlight behind the exhibit.
	var centre := stage / 2.0
	for i in range(6, 0, -1):
		_case.draw_circle(centre, minf(stage.x, stage.y) * 0.08 * i, Color(UiPalette.accent(Session.human_side if Session.has_game() else "usa"), 0.025))
	if _selected == null:
		_case.draw_string(get_theme_default_font(), Vector2(0, centre.y), "No program selected", HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTheme.SIZE_SUBHEADING, UiPalette.TEXT_MUTED)
		return
	var side := Session.human_side if Session.has_game() else "usa"
	var rect := Rect2(Vector2.ZERO, stage).grow(-minf(stage.x, stage.y) * 0.08)
	HardwareArt.paint(_case, rect, _selected.group, _selected.slot, side)
	# Plinth line.
	_case.draw_line(Vector2(size.x * 0.15, stage.y - 14), Vector2(size.x * 0.85, stage.y - 14), UiPalette.BORDER_SOFT, 2.0)


## The Maximum R&D line across the safety gauge's track (the gauge draws the track
## from x = 6 to size.x - 64).
func _draw_gauge_marker() -> void:
	if _selected == null:
		return
	var s := _gauge_marker.size
	var x := 6.0 + (s.x - 70.0) * clampf(_selected.max_rd / 100.0, 0.0, 1.0)
	_gauge_marker.draw_line(Vector2(x, 2), Vector2(x, s.y - 2), UiPalette.GOLD, 2.0)


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
		_tabs[g].tooltip_text = "%s programs" % GROUP_TITLES[g]
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
		chip.tooltip_text = "Show the %s" % chip.text
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
	_gauge_marker.queue_redraw()
	_prev.disabled = _programs.size() < 2
	_next.disabled = _programs.size() < 2
	for b in [_prev, _next]:
		b.tooltip_text = ("Previous program" if b == _prev else "Next program") if _programs.size() >= 2 else "Only one program in this group"
	for i in _chips.get_child_count():
		var chip: Button = _chips.get_child(i)
		chip.button_pressed = i == _index and has
	_data_panel.visible = has
	_expected.visible = has
	_pay_damage.visible = false
	for tb in _team_buttons:
		tb.visible = has
	if not has:
		_case_name.text = "NOTHING TO RESEARCH"
		_note.text = "No programs in this group have been opened. Open them in the Purchasing Facility."
		_restyle(_research, "blocked", "Research", "No program in this group has been opened.")
		return
	var p := Session.me()
	_case_name.text = "%s · %s" % [prog.display_name().to_upper(), OpsView.kind_name(prog).to_upper()]
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
	_gauge.value = prog.safety
	_gauge_max.text = "MAX R&D %d%%" % prog.max_rd
	var max_teams := SimHardware.max_teams(p, prog)
	var block := OpsView.research_block_reason(p, prog)
	_teams = clampi(_teams, 1, maxi(1, max_teams))
	for i in _team_buttons.size():
		var tb: Button = _team_buttons[i]
		tb.disabled = block != "" or i + 1 > max_teams
		tb.button_pressed = i + 1 == _teams
		var label := "%d team%s" % [i + 1, "" if i == 0 else "s"]
		if block != "":
			tb.tooltip_text = "%s: unavailable. %s" % [label, block]
		elif i + 1 > max_teams:
			tb.tooltip_text = "%s: unavailable. At most %d may be assigned this season." % [label, max_teams]
		else:
			tb.tooltip_text = "Assign %s" % label
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
		var dmg_reason := "" if p.cash >= prog.damage_cost else "Not enough cash: clearing the damage costs %d MB and you have %d MB." % [prog.damage_cost, p.cash]
		_restyle(_pay_damage, "caution" if dmg_reason == "" else "blocked", "Clear damage (%d MB)" % prog.damage_cost, dmg_reason)
		_pay_damage.tooltip_text = dmg_reason if dmg_reason != "" else "Pay to clear the damage before the next flight"
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
	var headroom := prog.max_rd - prog.safety
	_expected.text = OpsView.expected_gain_text(_teams, p.rd_mods_turn) + ", capped at %d%% more (Max R&D %d%%)." % [maxi(headroom, 0), prog.max_rd]
	var reason := OpsView.research_block_reason(p, prog)
	if reason == "" and p.cash < cost:
		reason = "Not enough cash: research with %d team%s costs %d MB and you have %d MB." % [_teams, "" if _teams == 1 else "s", cost, p.cash]
	_restyle(_research, "go" if reason == "" else "blocked",
			"Research with %d team%s (%d MB)" % [_teams, "" if _teams == 1 else "s", cost], reason)
	if reason == "":
		_research.tooltip_text = "Assign the teams and roll for safety now"


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
