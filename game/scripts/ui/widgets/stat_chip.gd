class_name StatChip
extends PanelContainer
## Icon and number on a sunken pill (ui-style-guide section 7). The tooltip names the
## quantity; a blocking value turns red. Optional click target.

signal pressed

var _icon: TextureRect
var _value: Label
var _clickable := false


func _init(icon_name := "", value := "", tip := "") -> void:
	var sb := UiTheme.flat(UiPalette.PANEL_SUNKEN, UiPalette.BORDER_SOFT, 14, 1)
	sb.content_margin_left = 10
	sb.content_margin_right = 12
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(h)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(22, 22)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(_icon)
	_value = Label.new()
	_value.theme_type_variation = "Mono"
	_value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(_value)
	set_icon(icon_name)
	set_value(value)
	tooltip_text = tip


func set_icon(icon_name: String) -> void:
	_icon.texture = ArtAssets.icon("chip_" + icon_name) if icon_name != "" else null
	_icon.visible = _icon.texture != null


## colour: optional override; blocking: red value.
func set_value(text: String, blocking := false, colour: Color = Color(0, 0, 0, 0)) -> void:
	_value.text = text
	if blocking:
		_value.add_theme_color_override("font_color", UiPalette.DANGER)
	elif colour.a > 0:
		_value.add_theme_color_override("font_color", colour)
	else:
		_value.remove_theme_color_override("font_color")


func set_clickable(on: bool) -> void:
	_clickable = on
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if on else Control.CURSOR_ARROW


func _gui_input(event: InputEvent) -> void:
	if _clickable and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
		accept_event()
