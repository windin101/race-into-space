extends ScreenPanel
## Program Offices: one card per owned program in the chosen group, with inventory,
## flight record and a buy-unit button. Unowned programs are listed dimly with a link
## to Hardware Purchase.

const GROUP_TITLES := {"probe": "Probes and satellites", "rocket": "Rockets", "manned": "Capsules and lunar modules", "misc": "Kickers, suits, docking"}
const HARDWARE_PURCHASE := "res://scenes/admin/hardware_purchase.tscn"
const CARD_WIDTH := 320.0

var _group := "rocket"
var _group_buttons: Dictionary = {}
var _flow: HFlowContainer
var _unowned: VBoxContainer


func _init() -> void:
	super()
	title = "Program Offices"


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
	UiHelp.attach(filters, "I008")

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	scroll.add_child(column)
	_flow = HFlowContainer.new()
	_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_flow.add_theme_constant_override("h_separation", 12)
	_flow.add_theme_constant_override("v_separation", 12)
	column.add_child(_flow)
	_unowned = VBoxContainer.new()
	_unowned.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(_unowned)
	_set_group(_group)


func on_resume() -> void:
	_refresh()


func _set_group(g: String) -> void:
	_group = g
	for key in _group_buttons:
		_group_buttons[key].button_pressed = key == g
	_refresh()


func _refresh() -> void:
	if not Session.has_game():
		return
	for c in _flow.get_children():
		c.queue_free()
	for c in _unowned.get_children():
		c.queue_free()
	var p := Session.me()
	var owned := 0
	var unowned: Array = []
	for prog in p.programs[_group]:
		if prog == null:
			continue
		if prog.owned:
			_flow.add_child(_make_card(p, prog))
			owned += 1
		else:
			unowned.append(prog)
	if owned == 0:
		var none := Label.new()
		none.theme_type_variation = "Dim"
		none.text = "No programs in this group have been opened yet."
		_flow.add_child(none)
	if not unowned.is_empty():
		var heading := Label.new()
		heading.theme_type_variation = "Subheading"
		heading.text = "Not yet opened"
		_unowned.add_child(heading)
		for prog in unowned:
			_unowned.add_child(_make_unowned_row(prog))


func _make_card(p: SimPlayer, prog: SimProgram) -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "Sunken"
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	var card := HardwareCard.new()
	card.set_program(prog)
	v.add_child(card)
	var record := Label.new()
	record.theme_type_variation = "Small"
	record.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	record.custom_minimum_size.x = CARD_WIDTH
	var lines: PackedStringArray = []
	lines.append("%d unit%s in inventory (max %d)" % [prog.units, "" if prog.units == 1 else "s", SimHardware.MAX_UNITS])
	lines.append("Flights %d   Successes %d   Failures %d" % [prog.flights, prog.successes, prog.failures])
	if prog.delay > 0:
		lines.append("Purchases delayed for %d more season%s." % [prog.delay, "" if prog.delay == 1 else "s"])
	if prog.damage != 0:
		lines.append("Damaged: %d%% on its next flight unless %d MB is paid in R&D." % [prog.damage, prog.damage_cost])
	record.text = "\n".join(lines)
	v.add_child(record)
	if not prog.is_photo_recon():
		var buy := Button.new()
		buy.text = "Buy unit  (%d MB)" % SimHardware.unit_price(p, prog)
		buy.disabled = not SimHardware.can_buy_unit(p, prog)
		buy.pressed.connect(_on_buy_unit.bind(prog))
		v.add_child(buy)
	return panel


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


func _on_buy_unit(prog: SimProgram) -> void:
	if SimHardware.buy_unit(Session.me(), prog):
		Session.notify_change()
		_refresh()


func _open_hardware_purchase() -> void:
	if ResourceLoader.exists(HARDWARE_PURCHASE):
		Screens.push(load(HARDWARE_PURCHASE), {})
