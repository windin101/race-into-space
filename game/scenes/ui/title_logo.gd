class_name TitleLogo
extends PanelContainer
## The title logo, in the original's arrangement: a framed dark panel with RACE over
## SPACE in big chrome capitals, INTO set vertically between them on the right, and the
## subtitle on a strip beneath. Built from our own wide face and a gradient shader; no
## artwork from the original is used.

const FRAME := Color("e8a33c")
const SUBTITLE := "U.S.-SOVIET SPACE RACE SIMULATION"


func _init(scale_px := 128.0) -> void:
	var sb := UiTheme.flat(Color(0.03, 0.04, 0.07, 0.92), FRAME, 4, 4)
	sb.set_content_margin_all(0)
	add_theme_stylebox_override("panel", sb)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	add_child(v)
	var body := MarginContainer.new()
	for side in ["left", "right"]:
		body.add_theme_constant_override("margin_" + side, int(scale_px * 0.22))
	body.add_theme_constant_override("margin_top", int(scale_px * 0.12))
	body.add_theme_constant_override("margin_bottom", int(scale_px * 0.04))
	v.add_child(body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(scale_px * 0.10))
	body.add_child(row)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", int(-scale_px * 0.30))
	row.add_child(words)
	words.add_child(_chrome("RACE", scale_px))
	words.add_child(_chrome("SPACE", scale_px))
	# INTO, set vertically and read top to bottom, between the two words on the right.
	var into_box := Control.new()
	into_box.custom_minimum_size = Vector2(scale_px * 0.42, scale_px * 1.5)
	row.add_child(into_box)
	var into := _chrome("INTO", scale_px * 0.36)
	into.rotation_degrees = 90
	into_box.add_child(into)
	into_box.resized.connect(func():
		into.position = Vector2(into_box.size.x * 0.5 + into.size.y * 0.5, into_box.size.y * 0.5 - into.size.x * 0.5))
	var strip := PanelContainer.new()
	var ssb := UiTheme.flat(Color(0.03, 0.04, 0.07, 0.0), Color(FRAME, 0.0), 0, 0)
	ssb.border_width_top = 3
	ssb.border_color = FRAME
	ssb.content_margin_top = 6
	ssb.content_margin_bottom = 8
	strip.add_theme_stylebox_override("panel", ssb)
	v.add_child(strip)
	var sub := Label.new()
	sub.text = SUBTITLE
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", UiTheme.font(UiTheme.FONT_LABEL))
	sub.add_theme_font_size_override("font_size", int(scale_px * 0.19))
	sub.add_theme_color_override("font_color", Color("f2e6c8"))
	strip.add_child(sub)


func _chrome(text: String, px: float) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", UiTheme.font(UiTheme.FONT_LABEL))
	l.add_theme_font_size_override("font_size", int(px))
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.07, 0.12))
	l.add_theme_constant_override("outline_size", maxi(2, int(px * 0.025)))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", int(px * 0.03))
	l.add_theme_constant_override("shadow_offset_y", int(px * 0.04))
	var mat := ShaderMaterial.new()
	mat.shader = load("res://scripts/ui/chrome_text.gdshader")
	mat.set_shader_parameter("height", px * 1.45)
	l.material = mat
	l.resized.connect(func(): mat.set_shader_parameter("height", l.size.y))
	# Where the capitals sit inside the label box for this face (measured from a render):
	# the gradient must span exactly the cap height for the horizon band to land mid-letter.
	mat.set_shader_parameter("top_pad", 0.22)
	mat.set_shader_parameter("cap", 0.58)
	return l
