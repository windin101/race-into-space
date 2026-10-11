extends ScreenPanel
## Hardware Purchase: open programs and buy units. Reference screen for Phase 4 patterns:
## a filter row, a sortable table, a detail card and command buttons that call the rules
## modules and then Session.notify_change().

const GROUP_TITLES := {"probe": "Probes and satellites", "rocket": "Rockets", "manned": "Capsules and lunar modules", "misc": "Kickers, suits, docking"}

var _group := "rocket"
var _table: DataTable
var _card: HardwareCard
var _detail: Label
var _buy_program: Button
var _buy_unit: Button
var _group_buttons: Dictionary = {}
var _selected: SimProgram


func _init() -> void:
	super()
	title = "Hardware Purchase"


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
	UiHelp.attach(filters, "I005")

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 16)
	content.add_child(split)

	_table = DataTable.new()
	_table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_table.size_flags_stretch_ratio = 2.0
	_table.set_columns([
		{"key": "name", "title": "Program", "stretch": 2},
		{"key": "status", "title": "Status"},
		{"key": "safety", "title": "Safety", "numeric": true, "suffix": "%", "color": func(r): return UiPalette.safety_color(int(r["safety"]))},
		{"key": "max_rd", "title": "Max R&D", "numeric": true, "suffix": "%"},
		{"key": "max_safety", "title": "Max safety", "numeric": true, "suffix": "%"},
		{"key": "program_cost", "title": "Program MB", "numeric": true},
		{"key": "unit_cost", "title": "Unit MB", "numeric": true},
		{"key": "units", "title": "Units", "numeric": true},
	])
	_table.row_selected.connect(_on_row)
	split.add_child(_table)

	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.custom_minimum_size.x = 320
	split.add_child(side)
	_card = HardwareCard.new()
	side.add_child(_card)
	_detail = Label.new()
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.theme_type_variation = "Small"
	side.add_child(_detail)
	_buy_program = Button.new()
	_buy_program.theme_type_variation = "Accent"
	_buy_program.pressed.connect(_on_buy_program)
	side.add_child(_buy_program)
	_buy_unit = Button.new()
	_buy_unit.pressed.connect(_on_buy_unit)
	side.add_child(_buy_unit)
	_set_group(_group)


func on_resume() -> void:
	_refresh()


func _set_group(g: String) -> void:
	_group = g
	for key in _group_buttons:
		_group_buttons[key].button_pressed = key == g
	_selected = null
	_refresh()


func _refresh() -> void:
	var p := Session.me()
	var rows: Array = []
	for prog in p.programs[_group]:
		if prog == null:
			continue
		rows.append({
			"name": prog.display_name().capitalize(),
			"status": "Owned" if prog.owned else ("Delayed %d" % prog.delay if prog.delay > 0 else "Available"),
			"safety": prog.safety if prog.owned else prog.base_safety(),
			"max_rd": prog.max_rd, "max_safety": prog.max_safety(),
			"program_cost": SimHardware.program_price(p, prog), "unit_cost": SimHardware.unit_price(p, prog),
			"units": prog.units if prog.owned else 0, "_prog": prog,
		})
	_table.set_rows(rows)
	if _selected == null and not rows.is_empty():
		_selected = rows[0]["_prog"]
	_refresh_detail()


func _on_row(row: Dictionary) -> void:
	_selected = row["_prog"]
	_refresh_detail()


func _refresh_detail() -> void:
	var p := Session.me()
	var prog := _selected
	_card.visible = prog != null
	if prog == null:
		_buy_program.disabled = true
		_buy_unit.disabled = true
		_detail.text = ""
		return
	_card.set_program(prog)
	var lines: PackedStringArray = []
	if not prog.owned:
		lines.append("Opening this program would start it at %d%% safety." % SimHardware.starting_safety(Session.state(), p, prog))
	if prog.delay > 0:
		lines.append("Purchases are blocked for %d more season%s." % [prog.delay, "" if prog.delay == 1 else "s"])
	if p.turn_flags.get("half_price", false):
		lines.append("Half-price sale this season.")
	if prog.damage != 0:
		lines.append("Damaged: %d%% on its next flight unless %d MB is paid in R&D." % [prog.damage, prog.damage_cost])
	_detail.text = "\n".join(lines)
	_buy_program.text = "Open program  (%d MB)" % SimHardware.program_price(p, prog)
	_buy_program.disabled = not SimHardware.can_buy_program(p, prog)
	_buy_program.visible = not prog.owned
	_buy_unit.text = "Buy a unit  (%d MB)" % SimHardware.unit_price(p, prog)
	_buy_unit.disabled = not SimHardware.can_buy_unit(p, prog)
	_buy_unit.visible = prog.owned and not prog.is_photo_recon()


func _on_buy_program() -> void:
	if _selected == null:
		return
	if SimHardware.buy_program(Session.state(), Session.me(), _selected):
		Session.notify_change()
		_refresh()


func _on_buy_unit() -> void:
	if _selected == null:
		return
	if SimHardware.buy_unit(Session.me(), _selected):
		Session.notify_change()
		_refresh()
