class_name Lamp
extends Button
## A pill lamp labelled in caps (ui-style-guide section 7): off (dark), on (green),
## warn (amber), fail (red). Clickable when `toggle` callers connect `pressed`.

enum State { OFF, ON, WARN, FAIL }

var state: int = State.OFF


func _init(label := "", initial: int = State.OFF) -> void:
	text = label.to_upper()
	custom_minimum_size = Vector2(150, 30)
	focus_mode = Control.FOCUS_NONE
	set_state(initial)


func set_state(s: int) -> void:
	state = s
	var col: Color = [UiPalette.PANEL_RAISED, UiPalette.OK, UiPalette.WARN, UiPalette.DANGER][s]
	var lit := s != State.OFF
	var sb := UiTheme.flat(col.darkened(0.15) if lit else UiPalette.PANEL_SUNKEN, col.lightened(0.2) if lit else UiPalette.BORDER_SOFT, 6, 1)
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		var c := sb.duplicate() as StyleBoxFlat
		if st == "hover":
			c.border_color = Color.WHITE
		add_theme_stylebox_override(st, c)
	add_theme_font_override("font", UiTheme.font(UiTheme.FONT_LABEL))
	add_theme_font_size_override("font_size", UiTheme.SIZE_SMALL)
	clip_text = false
	var fc := Color.WHITE if lit else UiPalette.TEXT_MUTED
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color"]:
		add_theme_color_override(k, fc)
