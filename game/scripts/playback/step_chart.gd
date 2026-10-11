class_name StepChart
extends Control
## The bottom readout of the launch screen: one bar per mission step showing the safety
## the step rolled against, with the roll as a marker. Green when the roll passed, red
## when it failed, grey for steps not yet reached.

var steps: Array = []          ## SimMission result steps
var revealed := 0              ## how many steps have been played
var _font: Font


func _init() -> void:
	custom_minimum_size = Vector2(300, 140)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_steps(p_steps: Array) -> void:
	steps = p_steps
	revealed = 0
	queue_redraw()


func reveal(n: int) -> void:
	revealed = clampi(n, 0, steps.size())
	queue_redraw()


func _draw() -> void:
	if _font == null:
		_font = get_theme_default_font()
	var n := steps.size()
	var bg := UiTheme.flat(UiPalette.PANEL_SUNKEN, UiPalette.BORDER_SOFT, 6)
	draw_style_box(bg, Rect2(Vector2.ZERO, size))
	if n == 0:
		return
	var margin := Vector2(44, 18)
	var plot := Rect2(margin, size - margin - Vector2(12, 26))
	var slot := plot.size.x / n
	var bar_w := clampf(slot * 0.62, 6.0, 48.0)
	var font_size := UiTheme.SIZE_SMALL
	for pct: int in [25, 50, 75, 100]:
		var y: float = plot.end.y - plot.size.y * pct / 100.0
		draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), UiPalette.BORDER_SOFT, 1.0)
		draw_string(_font, Vector2(4, y + font_size * 0.35), "%d" % pct, HORIZONTAL_ALIGNMENT_LEFT, margin.x - 8, font_size, UiPalette.TEXT_MUTED)
	for i in n:
		var st: Dictionary = steps[i]
		var x := plot.position.x + slot * i + (slot - bar_w) / 2.0
		var safety := clampi(int(st.get("safety", 0)), 0, 100)
		var roll := clampi(int(st.get("roll", 0)), 0, 100)
		var h := plot.size.y * safety / 100.0
		var played := i < revealed
		var col := UiPalette.TEXT_MUTED
		if played:
			col = UiPalette.OK if st.get("success", false) else UiPalette.DANGER
		draw_rect(Rect2(x, plot.end.y - h, bar_w, h), Color(col, 0.35 if played else 0.15))
		draw_rect(Rect2(x, plot.end.y - h, bar_w, h), col, false, 1.5)
		if played:
			var ry := plot.end.y - plot.size.y * roll / 100.0
			draw_line(Vector2(x - 2, ry), Vector2(x + bar_w + 2, ry), UiPalette.TEXT, 2.5)
			draw_circle(Vector2(x + bar_w / 2.0, ry), 3.5, UiPalette.TEXT)
		var letter: String = str(st.get("letter", "?"))
		draw_string(_font, Vector2(x, plot.end.y + font_size + 4), letter, HORIZONTAL_ALIGNMENT_CENTER, bar_w, font_size, UiPalette.TEXT if played else UiPalette.TEXT_MUTED)
	if revealed > 0 and revealed <= n:
		var st: Dictionary = steps[revealed - 1]
		var legend := "%s: safety %d%%, roll %d" % [str(st.get("name", "")), int(st.get("safety", 0)), int(st.get("roll", 0))]
		draw_string(_font, Vector2(margin.x, plot.position.y - 4), legend, HORIZONTAL_ALIGNMENT_LEFT, plot.size.x, font_size, UiPalette.TEXT_DIM)
