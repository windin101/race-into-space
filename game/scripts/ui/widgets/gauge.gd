class_name Gauge
extends Control
## A 0-100 gauge with ticks every 10 and a needle (ui-style-guide section 7). Vertical by
## default. Fill colour follows UiPalette.safety_color unless `fixed_color` is set.

var value := 0.0:
	set(v):
		value = clampf(v, 0.0, 100.0)
		queue_redraw()
var vertical := true
var label := ""
var fixed_color := Color(0, 0, 0, 0)


func _init(p_vertical := true, p_label := "") -> void:
	vertical = p_vertical
	label = p_label
	custom_minimum_size = Vector2(56, 200) if vertical else Vector2(220, 46)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var font := get_theme_default_font()
	var col: Color = fixed_color if fixed_color.a > 0 else UiPalette.safety_color(int(value))
	var box := Rect2(Vector2.ZERO, size)
	var track: Rect2
	if vertical:
		track = Rect2(size.x * 0.25, 6, size.x * 0.5, size.y - 40)
	else:
		track = Rect2(6, 6, size.x - 70, size.y - 12)
	draw_style_box(UiTheme.flat(UiPalette.PANEL_SUNKEN, UiPalette.BORDER_SOFT, 4), track)
	var k := value / 100.0
	var fill: Rect2
	if vertical:
		fill = Rect2(track.position.x + 3, track.end.y - (track.size.y - 6) * k - 3, track.size.x - 6, (track.size.y - 6) * k)
	else:
		fill = Rect2(track.position.x + 3, track.position.y + 3, (track.size.x - 6) * k, track.size.y - 6)
	draw_rect(fill, Color(col, 0.8))
	for i in range(1, 10):
		var t := i / 10.0
		if vertical:
			var y := track.end.y - track.size.y * t
			draw_line(Vector2(track.position.x, y), Vector2(track.position.x + 6 + (4 if i == 5 else 0), y), UiPalette.TEXT_MUTED, 1.0)
		else:
			var x := track.position.x + track.size.x * t
			draw_line(Vector2(x, track.end.y), Vector2(x, track.end.y - 6 - (4 if i == 5 else 0)), UiPalette.TEXT_MUTED, 1.0)
	var readout := "%d%%" % int(round(value))
	if vertical:
		var ny := track.end.y - track.size.y * k
		draw_line(Vector2(track.position.x - 4, ny), Vector2(track.end.x + 4, ny), Color.WHITE, 2.0)
		draw_string(font, Vector2(0, size.y - 8), readout, HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTheme.SIZE_SMALL, col)
	else:
		draw_string(font, Vector2(track.end.x + 8, size.y / 2.0 + 6), readout, HORIZONTAL_ALIGNMENT_LEFT, 60, UiTheme.SIZE_SMALL, col)
	if label != "":
		tooltip_text = label
