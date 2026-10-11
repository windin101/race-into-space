extends ScreenPanel
## Research & Development: assign engineer teams to an owned program for the season and
## pay off event-card damage. Follows the Hardware Purchase pattern: filter row, table,
## detail card and command buttons that call the rule modules.

const GROUP_TITLES := {"probe": "Probes and satellites", "rocket": "Rockets", "manned": "Capsules and lunar modules", "misc": "Kickers, suits, docking"}

var _group := "rocket"
var _table: DataTable
var _card: HardwareCard
var _teams: HSlider
var _teams_label: Label
var _cost: Label
var _expected: Label
var _note: Label
var _result: Label
var _research: Button
var _pay_damage: Button
var _group_buttons: Dictionary = {}
var _selected: SimProgram


func _init() -> void:
	super()
	title = "Research & Development"


func _ready() -> void:
	super()
	var filters := HBoxContainer.new()
	content.add_child(filters)
	for g in SimProgram.GROUPS:
		var b := Button.new()
		b.text = GROUP_TITLES[g]
		b.toggle_mode = true
		b.pressed.connect(_set_group.bind(g))
		filters.add_child(b)
		_group_buttons[g] = b
	UiHelp.attach(filters, "I007")

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 16)
	content.add_child(split)

	_table = DataTable.new()
	_table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_table.size_flags_stretch_ratio = 2.0
	_table.set_columns([
		{"key": "name", "title": "Program", "stretch": 2},
		{"key": "kind", "title": "Type"},
		{"key": "safety", "title": "Safety", "numeric": true, "suffix": "%", "color": func(r): return UiPalette.safety_color(int(r["safety"]))},
		{"key": "max_rd", "title": "Max R&D", "numeric": true, "suffix": "%"},
		{"key": "max_safety", "title": "Max safety", "numeric": true, "suffix": "%"},
		{"key": "rd_cost", "title": "MB / team", "numeric": true},
		{"key": "teams", "title": "Teams", "numeric": true},
		{"key": "researched", "title": "Researched", "numeric": true},
	])
	_table.row_selected.connect(_on_row)
	split.add_child(_table)

	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.custom_minimum_size.x = 340
	split.add_child(side)
	_card = HardwareCard.new()
	side.add_child(_card)

	var teams_row := HBoxContainer.new()
	teams_row.add_theme_constant_override("separation", 8)
	side.add_child(teams_row)
	var teams_title := Label.new()
	teams_title.text = "Teams"
	teams_row.add_child(teams_title)
	_teams = HSlider.new()
	_teams.min_value = 1
	_teams.max_value = SimHardware.MAX_TEAMS
	_teams.step = 1
	_teams.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_teams.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_teams.value_changed.connect(func(_v): _refresh_cost())
	teams_row.add_child(_teams)
	_teams_label = Label.new()
	_teams_label.custom_minimum_size.x = 90
	_teams_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	teams_row.add_child(_teams_label)

	_cost = Label.new()
	side.add_child(_cost)
	_expected = Label.new()
	_expected.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_expected.theme_type_variation = "Small"
	side.add_child(_expected)
	_note = Label.new()
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.theme_type_variation = "Small"
	side.add_child(_note)
	_research = Button.new()
	_research.theme_type_variation = "Accent"
	_research.pressed.connect(_on_research)
	side.add_child(_research)
	_result = Label.new()
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_result)
	_pay_damage = Button.new()
	_pay_damage.theme_type_variation = "Danger"
	_pay_damage.pressed.connect(_on_pay_damage)
	side.add_child(_pay_damage)
	_set_group(_group)


func on_resume() -> void:
	_refresh()


func _set_group(g: String) -> void:
	_group = g
	for key in _group_buttons:
		_group_buttons[key].button_pressed = key == g
	_selected = null
	_result.text = ""
	_refresh()


func _refresh() -> void:
	if not Session.has_game():
		return
	var p := Session.me()
	var rows: Array = []
	for prog in p.programs[_group]:
		if prog == null or not prog.owned:
			continue
		rows.append({
			"name": prog.display_name().capitalize(),
			"kind": OpsView.kind_name(prog),
			"safety": prog.safety, "max_rd": prog.max_rd, "max_safety": prog.max_safety(),
			"rd_cost": prog.rd_cost(),
			"teams": SimHardware.max_teams(p, prog),
			"researched": "Yes" if prog.researched_this_season else "No",
			"_prog": prog,
		})
	_table.set_rows(rows)
	if _selected == null and not rows.is_empty():
		_selected = rows[0]["_prog"]
	_refresh_detail()


func _on_row(row: Dictionary) -> void:
	_selected = row["_prog"]
	_result.text = ""
	_refresh_detail()


func _refresh_detail() -> void:
	var prog := _selected
	var has := prog != null
	_card.visible = has
	_teams.get_parent().visible = has
	_cost.visible = has
	_expected.visible = has
	_research.visible = has
	_pay_damage.visible = false
	if not has:
		_note.text = "No programs in this group have been opened. Open them in Hardware Purchase."
		return
	var p := Session.me()
	_card.set_program(prog)
	var max_teams := SimHardware.max_teams(p, prog)
	var block := OpsView.research_block_reason(p, prog)
	_teams.editable = block == ""
	_teams.max_value = maxi(1, max_teams)
	_teams.value = clampi(int(_teams.value), 1, maxi(1, max_teams))
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
	var teams := int(_teams.value)
	var cost := SimHardware.research_cost(p, prog, teams)
	_teams_label.text = "%d team%s" % [teams, "" if teams == 1 else "s"]
	_cost.text = "Total cost %d MB" % cost
	var headroom := prog.max_rd - prog.safety
	_expected.text = OpsView.expected_gain_text(teams, p.rd_mods_turn) + ", capped at %d%% more (Max R&D %d%%)." % [maxi(headroom, 0), prog.max_rd]
	_research.text = "Research  (%d MB)" % cost
	_research.disabled = OpsView.research_block_reason(p, prog) != "" or p.cash < cost


func _on_research() -> void:
	if _selected == null:
		return
	var prog := _selected
	var before := prog.safety
	var gain := SimHardware.research(Session.state(), Session.me(), prog, int(_teams.value))
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
