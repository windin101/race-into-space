class_name HardwareCard
extends PanelContainer
## Summary card for one hardware program: name, safety bar, ceilings, units and costs.

signal pressed(program: SimProgram)

var program: SimProgram

var _name: Label
var _kind: Label
var _safety: StatBar
var _ceilings: Label
var _units: Label
var _costs: Label
var _button: Button
var _icon: Control


func _init() -> void:
	theme_type_variation = "Card"
	custom_minimum_size = Vector2(300, 150)
	var h := HBoxContainer.new()
	add_child(h)
	_icon = Control.new()
	_icon.custom_minimum_size = Vector2(90, 90)
	_icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_icon.draw.connect(_draw_icon)
	h.add_child(_icon)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	_name = Label.new()
	_name.theme_type_variation = "Subheading"
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_name)
	_kind = Label.new()
	_kind.theme_type_variation = "Dim"
	top.add_child(_kind)
	_safety = StatBar.new("Safety")
	_safety.label_width = 70
	v.add_child(_safety)
	_ceilings = Label.new()
	_ceilings.theme_type_variation = "Small"
	v.add_child(_ceilings)
	_units = Label.new()
	v.add_child(_units)
	_costs = Label.new()
	_costs.theme_type_variation = "Small"
	v.add_child(_costs)
	_button = Button.new()
	_button.theme_type_variation = "Flat"
	_button.flat = true
	_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	_button.pressed.connect(func(): pressed.emit(program))
	_button.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_button)


func _draw_icon() -> void:
	if program == null:
		return
	var side := Session.human_side if Session.has_game() else "usa"
	HardwareArt.paint(_icon, Rect2(Vector2.ZERO, _icon.size), program.group, program.slot, side)


func set_program(p: SimProgram) -> void:
	program = p
	_icon.queue_redraw()
	_name.text = p.display_name().capitalize()
	_kind.text = _kind_name(p)
	_safety.value = p.safety if p.owned else p.base_safety()
	_ceilings.text = "Max R&D %d%%   Max safety %d%%" % [p.max_rd, p.max_safety()]
	if p.owned:
		_units.text = "%d unit%s in inventory" % [p.units, "" if p.units == 1 else "s"]
		_costs.text = "Unit %d MB   R&D %d MB per team" % [p.unit_cost(), p.rd_cost()]
	else:
		_units.text = "Not purchased"
		_costs.text = "Program %d MB   Unit %d MB   R&D %d MB per team" % [p.program_cost(), p.unit_cost(), p.rd_cost()]
	if p.spec.has("max_payload") and p.is_rocket():
		_costs.text += "   Lift %d" % p.spec["max_payload"]
	elif p.spec.get("unit_weight", 0) > 0:
		_costs.text += "   Weight %d" % p.spec["unit_weight"]


static func _kind_name(p: SimProgram) -> String:
	if p.is_rocket():
		return "Rocket"
	if p.is_capsule():
		return "Capsule"
	if p.is_lm():
		return "Lunar module"
	if p.is_probe():
		return "Probe"
	if p.is_kicker():
		return "Kicker"
	if p.is_eva_suit():
		return "EVA suits"
	if p.is_docking_module():
		return "Docking module"
	return "Photo recon"
