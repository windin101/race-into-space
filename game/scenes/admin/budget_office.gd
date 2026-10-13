extends ScreenPanel
## Budget Office: under a gold banner, a ledger sheet of this season's figures (a column per
## figure, a row per side) in a Card, then the prestige-per-season and budget-per-season
## line graphs (drawn by a custom Control), each with a side-coloured legend.

const SIDE_TITLES := {"usa": "United States", "ussr": "Soviet Union"}

const LEDGER_KEYS := ["CASH", "BUDGET", "SPENT THIS SEASON", "PRESTIGE THIS SEASON", "PRESTIGE TOTAL", "DIRECTOR SCORE"]

var _prestige_graph: LineGraph
var _budget_graph: LineGraph
var _ledger_title: Label
var _ledger: GridContainer
var _ledger_cells: Dictionary = {} ## side -> Label per summary row


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
	show_rival_prestige = true


func _ready() -> void:
	super()
	UiHelp.attach(content, "I007")
	# The gold banner: the one main subject of the screen.
	var banner := PanelContainer.new()
	banner.theme_type_variation = "Sunken"
	content.add_child(banner)
	_ledger_title = Label.new()
	_ledger_title.theme_type_variation = "Heading"
	_ledger_title.add_theme_color_override("font_color", UiPalette.GOLD)
	_ledger_title.clip_text = true
	_ledger_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	banner.add_child(_ledger_title)
	# Ledger sheet: a column per figure, a row per side.
	var sheet := UiPanel.new("This season", "I007")
	content.add_child(sheet)
	_ledger = GridContainer.new()
	_ledger.columns = LEDGER_KEYS.size() + 1
	_ledger.add_theme_constant_override("h_separation", 24)
	_ledger.add_theme_constant_override("v_separation", 6)
	sheet.body.add_child(_ledger)
	var corner := Control.new()
	corner.custom_minimum_size.x = 200
	_ledger.add_child(corner)
	for key in LEDGER_KEYS:
		var k := Label.new()
		k.text = key
		k.theme_type_variation = "Caps"
		k.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_ledger.add_child(k)
	for side in ["usa", "ussr"]:
		var h := Label.new()
		h.text = SIDE_TITLES[side].to_upper()
		h.theme_type_variation = "CapsBright"
		h.add_theme_color_override("font_color", UiPalette.accent(side).lightened(0.3))
		h.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_ledger.add_child(h)
		var cells: Array = []
		for key in LEDGER_KEYS:
			var v := Label.new()
			v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			v.theme_type_variation = "Readout"
			v.tooltip_text = "%s: %s" % [SIDE_TITLES[side], str(key).capitalize()]
			v.mouse_filter = Control.MOUSE_FILTER_PASS
			_ledger.add_child(v)
			cells.append(v)
		_ledger_cells[side] = cells

	# The two graphs side by side, each with a side-coloured legend.
	var graphs := HBoxContainer.new()
	graphs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graphs.add_theme_constant_override("separation", 16)
	content.add_child(graphs)
	_prestige_graph = LineGraph.new()
	graphs.add_child(_graph_box("Prestige per season", _prestige_graph))
	_budget_graph = LineGraph.new()
	graphs.add_child(_graph_box("Budget per season (MB)", _budget_graph))
	set_room("room_office")
	_refresh()


func setup(_args: Dictionary) -> void:
	_refresh()


func on_resume() -> void:
	_refresh()


func _graph_box(heading: String, graph: LineGraph) -> Control:
	var panel := UiPanel.new(heading, "I007")
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 18)
	head.alignment = BoxContainer.ALIGNMENT_END
	panel.body.add_child(head)
	for side in ["usa", "ussr"]:
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 6)
		var swatch := ColorRect.new()
		swatch.color = UiPalette.accent(side)
		swatch.custom_minimum_size = Vector2(22, 6)
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item.add_child(swatch)
		var text := Label.new()
		text.text = SIDE_TITLES[side].to_upper()
		text.theme_type_variation = "Caps"
		text.add_theme_color_override("font_color", UiPalette.accent(side).lightened(0.3))
		item.add_child(text)
		head.add_child(item)
	panel.tooltip_text = "%s for both sides, one point per season." % heading
	panel.body.add_child(graph)
	return panel


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
	_ledger_title.text = "LEDGER: %s" % state.date_string().to_upper()
	var rows := summary_rows(state)
	for j in 2:
		var side: String = ["usa", "ussr"][j]
		var mine := state.player(j) == Session.me()
		for i in mini(rows.size(), _ledger_cells[side].size()):
			var r: Dictionary = rows[i]
			var lbl: Label = _ledger_cells[side][i]
			var v := int(r[side])
			lbl.text = ("%d MB" % v) if str(r["metric"]).ends_with("(MB)") else str(v)
			lbl.add_theme_color_override("font_color", UiPalette.TEXT if mine else UiPalette.TEXT_DIM)


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
