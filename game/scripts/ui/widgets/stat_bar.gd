class_name StatBar
extends HBoxContainer
## A labelled horizontal bar: "Safety  [#######   ] 72%". Colour follows the value band
## unless a fixed colour is given.

var label_text := "":
	set(v):
		label_text = v
		if _label:
			_label.text = v
var value := 0:
	set(v):
		value = v
		_refresh()
var max_value := 100:
	set(v):
		max_value = v
		_refresh()
var suffix := "%"
var fixed_color := Color.TRANSPARENT
var label_width := 110.0
var show_value := true

var _label: Label
var _bar: ProgressBar
var _value_label: Label


func _init(p_label := "", p_value := 0, p_max := 100, p_suffix := "%") -> void:
	label_text = p_label
	value = p_value
	max_value = p_max
	suffix = p_suffix
	add_theme_constant_override("separation", 8)
	_label = Label.new()
	_label.text = label_text
	_label.custom_minimum_size.x = label_width
	_label.clip_text = true
	add_child(_label)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.custom_minimum_size = Vector2(60, 14)
	_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(_bar)
	_value_label = Label.new()
	_value_label.custom_minimum_size.x = 48
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_value_label)
	_refresh()


func _refresh() -> void:
	if _bar == null:
		return
	_bar.max_value = maxi(max_value, 1)
	_bar.value = clampi(value, 0, max_value)
	_value_label.text = "%d%s" % [value, suffix]
	_value_label.visible = show_value
	var c := fixed_color
	if c.a == 0:
		c = UiPalette.safety_color(int(100.0 * value / maxi(max_value, 1)))
	var fill := UiTheme.flat(c, Color.TRANSPARENT, 4)
	_bar.add_theme_stylebox_override("fill", fill)
