class_name StatusLamps
extends VBoxContainer
## Three stacked lamps, only one lit: Systems nominal / Warning / Failure.

enum Level { NOMINAL, WARNING, FAILURE, NONE }

var _lamps: Array = []


func _init() -> void:
	add_theme_constant_override("separation", 6)
	for label in ["Systems nominal", "Warning", "Failure"]:
		var l := Lamp.new(label)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.custom_minimum_size = Vector2(170, 34)
		add_child(l)
		_lamps.append(l)
	set_level(Level.NONE)


func set_level(level: int) -> void:
	for i in 3:
		var on := i == level
		_lamps[i].set_state([Lamp.State.ON, Lamp.State.WARN, Lamp.State.FAIL][i] if on else Lamp.State.OFF)
