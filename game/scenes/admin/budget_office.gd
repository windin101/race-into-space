extends ScreenPanel
## Budget Office: prestige-per-season and budget-per-season line graphs for both sides,
## drawn by a custom Control, and a table of the current season's numbers.

const SIDE_TITLES := {"usa": "United States", "ussr": "Soviet Union"}

var _prestige_graph: LineGraph
var _budget_graph: LineGraph
var _summary: DataTable


## Line graph of one or more integer series over seasons. Series: {label, color, values}.
class LineGraph extends Control:
	const MARGIN_LEFT := 64.0
	const MARGIN_RIGHT := 16.0
	const MARGIN_TOP := 12.0
	const MARGIN_BOTTOM := 30.0
	const LINE_WIDTH := 2.5
	const POINT_RADIUS := 3.0

	const GRID_LINES := 4
	const MAX_X_LABELS := 10

	var series: Array = []
	var empty_text := "No seasons recorded yet."

	func _init() -> void:
		custom_minimum_size = Vector2(240, 180)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_flags_vertical = Control.SIZE_EXPAND_FILL
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func set_series(p_series: Array) -> void:
		series = p_series
		queue_redraw()

	func _font() -> Font:
		return get_theme_default_font()

	func _font_size() -> int:
		var s := get_theme_font_size("font_size", "Small")
		return s if s > 0 else get_theme_default_font_size()

	func _draw() -> void:
		var all: Array = []
		var count := 0
		for s in series:
			all.append_array(s["values"])
			count = maxi(count, s["values"].size())
		var font := _font()
		var fs := _font_size()
		var plot := Rect2(MARGIN_LEFT, MARGIN_TOP, size.x - MARGIN_LEFT - MARGIN_RIGHT, size.y - MARGIN_TOP - MARGIN_BOTTOM)
		if plot.size.x <= 0.0 or plot.size.y <= 0.0:
			return
		draw_rect(plot, UiPalette.PANEL_SUNKEN, true)
		var rng := graph_range(all, GRID_LINES)
		var lo: float = rng["min"]
		var hi: float = rng["max"]
		var step: float = rng["step"]
		# Horizontal gridlines and y labels.
		var y: float = lo
		while y <= hi + 0.001:
			var py: float = plot.position.y + plot.size.y * (1.0 - (y - lo) / (hi - lo))
			var c := UiPalette.BORDER if absf(y) < 0.001 else UiPalette.BORDER_SOFT
			draw_line(Vector2(plot.position.x, py), Vector2(plot.end.x, py), c, 1.0)
			draw_string(font, Vector2(2.0, py + fs * 0.35), str(int(round(y))), HORIZONTAL_ALIGNMENT_RIGHT, MARGIN_LEFT - 8.0, fs, UiPalette.TEXT_DIM)
			y += step
		# Axes.
		draw_line(plot.position, Vector2(plot.position.x, plot.end.y), UiPalette.BORDER, 1.5)
		draw_line(Vector2(plot.position.x, plot.end.y), plot.end, UiPalette.BORDER, 1.5)
		if count == 0:
			draw_string(font, Vector2(plot.position.x + 12.0, plot.position.y + plot.size.y * 0.5), empty_text, HORIZONTAL_ALIGNMENT_LEFT, plot.size.x - 24.0, fs, UiPalette.TEXT_MUTED)
			return
		# X ticks: one per season, year labels thinned to MAX_X_LABELS.
		var stride := x_label_stride(count, MAX_X_LABELS)
		for i in count:
			var px := _x_for(i, count, plot)
			draw_line(Vector2(px, plot.end.y), Vector2(px, plot.end.y + 4.0), UiPalette.BORDER, 1.0)
			if i % stride == 0:
				draw_string(font, Vector2(px - 24.0, plot.end.y + fs + 6.0), season_label(i), HORIZONTAL_ALIGNMENT_CENTER, 48.0, fs, UiPalette.TEXT_DIM)
		# Series lines.
		for s in series:
			var values: Array = s["values"]
			var color: Color = s["color"]
			var pts := PackedVector2Array()
			for i in values.size():
				var px := _x_for(i, count, plot)
				var py: float = plot.position.y + plot.size.y * (1.0 - (float(values[i]) - lo) / (hi - lo))
				pts.append(Vector2(px, py))
			if pts.size() >= 2:
				draw_polyline(pts, color, LINE_WIDTH, true)
			for pt in pts:
				draw_circle(pt, POINT_RADIUS, color)

	func _x_for(i: int, count: int, plot: Rect2) -> float:
		if count <= 1:
			return plot.position.x + 12.0
		return plot.position.x + plot.size.x * float(i) / float(count - 1)

	## Axis range for a set of values: always includes zero, rounded out to a "nice" step so
	## about `lines` gridlines fit. {min, max, step}; an empty set gives 0..1.
	static func graph_range(values: Array, lines: int = 4) -> Dictionary:
		var lo := 0.0
		var hi := 0.0
		for v in values:
			lo = minf(lo, float(v))
			hi = maxf(hi, float(v))
		if hi - lo < 1.0:
			hi = lo + 1.0
		# Values are whole MB / prestige points, so never label fractions.
		var step := maxf(nice_step((hi - lo) / float(maxi(lines, 1))), 1.0)
		lo = floorf(lo / step) * step
		hi = ceilf(hi / step) * step
		if hi - lo < step:
			hi = lo + step
		return {"min": lo, "max": hi, "step": step}


	## Smallest 1/2/5 x 10^k that is >= raw.
	static func nice_step(raw: float) -> float:
		if raw <= 0.0:
			return 1.0
		var magnitude := pow(10.0, floorf(log(raw) / log(10.0)))
		for m in [1.0, 2.0, 5.0, 10.0]:
			if m * magnitude >= raw - 0.000001:
				return m * magnitude
		return 10.0 * magnitude


	## Label every `stride`-th season so at most `max_labels` fit; strides are whole years.
	static func x_label_stride(count: int, max_labels: int) -> int:
		var stride := 2
		while count / stride > max_labels:
			stride += 2
		return stride


	## History index i is the i-th season since Spring of the first year.
	static func season_label(i: int) -> String:
		var year: int = SimState.FIRST_YEAR + i / 2
		var season := "Spr" if i % 2 == 0 else "Fall"
		return "%s '%02d" % [season, year % 100]


func _init() -> void:
	super()
	title = "Budget Office"


func _ready() -> void:
	super()
	UiHelp.attach(content, "I007")
	var graphs := HBoxContainer.new()
	graphs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graphs.size_flags_stretch_ratio = 3.0
	graphs.add_theme_constant_override("separation", 16)
	content.add_child(graphs)
	_prestige_graph = LineGraph.new()
	graphs.add_child(_graph_box("Prestige per season", _prestige_graph))
	_budget_graph = LineGraph.new()
	graphs.add_child(_graph_box("Budget per season (MB)", _budget_graph))

	var heading := Label.new()
	heading.theme_type_variation = "Subheading"
	heading.text = "This season"
	content.add_child(heading)
	_summary = DataTable.new()
	_summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_summary.size_flags_stretch_ratio = 2.0
	_summary.custom_minimum_size.y = 6 * DataTable.ROW_MIN_HEIGHT + 40
	_summary.set_columns([
		{"key": "metric", "title": "Figure", "stretch": 2},
		{"key": "usa", "title": SIDE_TITLES["usa"], "numeric": true, "color": UiPalette.accent("usa").lightened(0.3)},
		{"key": "ussr", "title": SIDE_TITLES["ussr"], "numeric": true, "color": UiPalette.accent("ussr").lightened(0.3)},
	])
	content.add_child(_summary)
	_refresh()


func setup(_args: Dictionary) -> void:
	_refresh()


func on_resume() -> void:
	_refresh()


func _graph_box(heading: String, graph: LineGraph) -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.theme_type_variation = "Subheading"
	label.text = heading
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(label)
	box.add_child(graph)
	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", 18)
	for side in ["usa", "ussr"]:
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 6)
		var swatch := ColorRect.new()
		swatch.color = UiPalette.accent(side)
		swatch.custom_minimum_size = Vector2(14, 14)
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item.add_child(swatch)
		var text := Label.new()
		text.theme_type_variation = "Small"
		text.text = SIDE_TITLES[side]
		item.add_child(text)
		legend.add_child(item)
	box.add_child(legend)
	return box


func _refresh() -> void:
	if not Session.has_game():
		return
	var state := Session.state()
	var usa := state.player(0)
	var ussr := state.player(1)
	_prestige_graph.set_series([
		{"label": SIDE_TITLES["usa"], "color": UiPalette.accent("usa"), "values": Array(usa.prestige_history)},
		{"label": SIDE_TITLES["ussr"], "color": UiPalette.accent("ussr"), "values": Array(ussr.prestige_history)},
	])
	_budget_graph.set_series([
		{"label": SIDE_TITLES["usa"], "color": UiPalette.accent("usa"), "values": Array(usa.budget_history)},
		{"label": SIDE_TITLES["ussr"], "color": UiPalette.accent("ussr"), "values": Array(ussr.budget_history)},
	])
	_summary.set_rows(summary_rows(state))


## The current-season table: one row per figure, a value per side.
static func summary_rows(state: SimState) -> Array:
	var usa := state.player(0)
	var ussr := state.player(1)
	return [
		{"metric": "Cash (MB)", "usa": usa.cash, "ussr": ussr.cash},
		{"metric": "Budget (MB)", "usa": usa.budget, "ussr": ussr.budget},
		{"metric": "Spent this season (MB)", "usa": usa.spending_this_season, "ussr": ussr.spending_this_season},
		{"metric": "Prestige this season", "usa": usa.prestige, "ussr": ussr.prestige},
		{"metric": "Prestige total", "usa": usa.prestige_total, "ussr": ussr.prestige_total},
		{"metric": "Director score", "usa": SimReview.director_score(state, usa), "ussr": SimReview.director_score(state, ussr)},
	]




# Outer-class wrappers so tests and other screens can reach the graph maths.
static func graph_range(values: Array, lines: int = LineGraph.GRID_LINES) -> Dictionary:
	return LineGraph.graph_range(values, lines)


static func nice_step(raw: float) -> float:
	return LineGraph.nice_step(raw)


static func x_label_stride(count: int, max_labels: int) -> int:
	return LineGraph.x_label_stride(count, max_labels)


static func season_label(i: int) -> String:
	return LineGraph.season_label(i)
