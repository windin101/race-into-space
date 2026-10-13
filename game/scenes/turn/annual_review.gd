extends ScreenPanel
## Annual Review, staged in the painted chamber (backdrop review_<side>): the reviewer as a
## large portrait tile on the left; on the right a gold banner, the verdict from
## text/reviews.json as a cyan brief with the dismissal warning when the index nears
## SimReview.FIRED_AT, a small stats sheet and the bar chart of the index history.

const WARN_FROM := SimReview.FIRED_AT - 2

const CASE_BG := Color("0a1424")

var _review: Dictionary = {}
var _reviewer: Control
var _reviewer_side := "usa"
var _reviewer_title := ""
var _banner: Label
var _portrait_sub: Label
var _sheet: GridContainer
var _sheet_values: Array = []
var _text: Label
var _warning: Label
var _chart: ReviewChart


class ReviewChart extends Control:
	## Review index per year as bars around the START_INDEX baseline: at or below it draws
	## upward in the good colour, above it downward in the poor colour (review.json chart_rule).
	var reviews: Array = []
	var font: Font
	var font_size := UiTheme.SIZE_SMALL

	func _init() -> void:
		custom_minimum_size = Vector2(240, 160)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_flags_vertical = Control.SIZE_EXPAND_FILL

	func set_reviews(r: Array) -> void:
		reviews = r
		queue_redraw()

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, UiPalette.PANEL_SUNKEN)
		var f := font if font != null else get_theme_default_font()
		var pad_left := 52.0
		var pad := 12.0
		var plot := Rect2(pad_left, pad, maxf(size.x - pad_left - pad, 1.0), maxf(size.y - 2 * pad - 22.0, 1.0))
		var max_index := float(SimReview.FIRED_AT)
		var unit := plot.size.y / (max_index - 1.0)
		var base_y := plot.position.y + (SimReview.START_INDEX - 1) * unit
		draw_line(Vector2(plot.position.x, base_y), Vector2(plot.end.x, base_y), UiPalette.BORDER, 1.0)
		draw_string(f, Vector2(2, plot.position.y + font_size), "Good", HORIZONTAL_ALIGNMENT_LEFT, pad_left - 4, font_size, UiPalette.OK)
		draw_string(f, Vector2(2, base_y + font_size * 0.4), "Fair", HORIZONTAL_ALIGNMENT_LEFT, pad_left - 4, font_size, UiPalette.TEXT_DIM)
		draw_string(f, Vector2(2, plot.end.y), "Poor", HORIZONTAL_ALIGNMENT_LEFT, pad_left - 4, font_size, UiPalette.DANGER)
		if reviews.is_empty():
			draw_string(f, Vector2(plot.position.x + 8, base_y - 6), "No reviews yet", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UiPalette.TEXT_MUTED)
			return
		var n := reviews.size()
		var slot := plot.size.x / n
		var bar_w := clampf(slot * 0.6, 4.0, 48.0)
		for i in n:
			var r: Dictionary = reviews[i]
			var idx := clampi(int(r.get("index", SimReview.START_INDEX)), 1, SimReview.FIRED_AT)
			var top_y := plot.position.y + (idx - 1) * unit
			var x := plot.position.x + slot * i + (slot - bar_w) / 2.0
			var colour := TurnLogic.review_chart_colour(GameData.review, idx)
			var bar := Rect2(x, minf(top_y, base_y), bar_w, maxf(absf(top_y - base_y), 2.0))
			draw_rect(bar, colour)
			var label := "'%02d" % int(r.get("year", 0))
			draw_string(f, Vector2(x + bar_w / 2.0 - font_size, plot.end.y + font_size + 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UiPalette.TEXT_DIM)


func _init() -> void:
	super()
	title = "Annual Review"
	show_back = false


func _ready() -> void:
	super()
	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 20)
	content.add_child(split)

	# The reviewer, large, with their office on a band beneath.
	var left_panel := UiPanel.new("Reviewer")
	left_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	split.add_child(left_panel)
	var left := left_panel.body
	_reviewer = Control.new()
	_reviewer.custom_minimum_size = Vector2(400, 500)
	_reviewer.draw.connect(_draw_reviewer)
	left.add_child(_reviewer)
	_portrait_sub = Label.new()
	_portrait_sub.theme_type_variation = "Dim"
	_portrait_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_portrait_sub.custom_minimum_size.x = 400
	left.add_child(_portrait_sub)

	# The verdict: banner, brief text, stats sheet, history chart.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	split.add_child(right)
	var brief := UiPanel.new("Verdict")
	right.add_child(brief)
	var rbox := brief.body
	rbox.add_theme_constant_override("separation", 12)
	_banner = Label.new()
	_banner.theme_type_variation = "Heading"
	_banner.add_theme_color_override("font_color", UiPalette.GOLD)
	_banner.clip_text = true
	_banner.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	rbox.add_child(_banner)
	_text = Label.new()
	_text.theme_type_variation = "Subheading"
	_text.add_theme_color_override("font_color", UiPalette.INFO)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rbox.add_child(_text)
	_warning = Label.new()
	_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_warning.add_theme_color_override("font_color", UiPalette.DANGER)
	rbox.add_child(_warning)
	_sheet = GridContainer.new()
	_sheet.columns = 2
	_sheet.add_theme_constant_override("h_separation", 24)
	_sheet.add_theme_constant_override("v_separation", 4)
	rbox.add_child(_sheet)
	for key in ["REVIEW INDEX:", "DISMISSAL AT:", "DIRECTOR SCORE:", "PRESTIGE TOTAL:"]:
		var k := Label.new()
		k.text = key
		k.theme_type_variation = "Dim"
		_sheet.add_child(k)
		var v := Label.new()
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		v.custom_minimum_size.x = 120
		_sheet.add_child(v)
		_sheet_values.append(v)

	var chart_panel := UiPanel.new("Review history", "I030")
	chart_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(chart_panel)
	_chart = ReviewChart.new()
	_chart.tooltip_text = "Review index each spring: bars above the line are good years, below it poor ones"
	chart_panel.body.add_child(_chart)
	UiHelp.attach(_chart, "I030")

	var go := Button.new()
	go.custom_minimum_size = Vector2(170, 40)
	UiAction.style(go, "go", "Continue")
	go.tooltip_text = "Close the review"
	go.pressed.connect(func(): Screens.pop())
	footer.add_child(go)
	_refresh()


func setup(args: Dictionary) -> void:
	var r = args.get("review", null)
	_review = r if r is Dictionary else {}
	_refresh()


func on_resume() -> void:
	_refresh()


func _draw_reviewer() -> void:
	var size := _reviewer.size
	_reviewer.draw_rect(Rect2(Vector2.ZERO, size), CASE_BG)
	if _reviewer_title == "":
		return
	PortraitArt.paint(_reviewer, Rect2(Vector2.ZERO, size), _reviewer_title, false, _reviewer_side)
	_reviewer.draw_rect(Rect2(0, size.y - 30, size.x, 30), Color(0, 0, 0, 0.6))
	_reviewer.draw_string(get_theme_default_font(), Vector2(0, size.y - 9), _reviewer_title.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTheme.SIZE_BODY, UiPalette.GOLD)


func _show_reviewer(side: String, office: String) -> void:
	_reviewer_side = side
	_reviewer_title = office
	_reviewer.queue_redraw()


func _refresh() -> void:
	if not Session.has_game():
		_text.text = "No game in progress."
		return
	var state := Session.state()
	var p := Session.me()
	set_backdrop("review_%s" % p.side)
	var review := _review
	if review.is_empty() and not p.reviews.is_empty():
		review = p.reviews.back()
	_chart.font = get_theme_default_font()
	_chart.set_reviews(p.reviews)
	var body := "Capitol" if p.side == "usa" else "Politburo"
	_sheet_values[1].text = str(SimReview.FIRED_AT)
	_sheet_values[2].text = str(SimReview.director_score(state, p))
	_sheet_values[3].text = str(p.prestige_total)
	if review.is_empty():
		var office := TurnLogic.review_portrait(p.side, p.review_index)
		_show_reviewer(p.side, office)
		_portrait_sub.text = "For the %s" % body
		_banner.text = "%s REVIEW" % body.to_upper()
		_text.text = ("No annual review has been held yet. The %s meets each spring from %d." % [body, 1900 + SimState.FIRST_YEAR + 1]).to_upper()
		_sheet_values[0].text = str(p.review_index)
		_sheet_values[0].add_theme_color_override("font_color", TurnLogic.review_chart_colour(GameData.review, p.review_index))
		_warning.text = ""
		_warning.visible = false
		return
	var index := int(review.get("index", p.review_index))
	var year := 1900 + int(review.get("year", state.year))
	var office := TurnLogic.review_portrait(p.side, index)
	_show_reviewer(p.side, office)
	_portrait_sub.text = "For the %s, %d" % [body, year]
	_banner.text = "%s REVIEW: %d" % [body.to_upper(), year]
	_sheet_values[0].text = "%d  (lower is better)" % index
	_sheet_values[0].add_theme_color_override("font_color", TurnLogic.review_chart_colour(GameData.review, index))
	var lines: Array = GameData.text.get("reviews", {}).get("review", [])
	var ti := int(review.get("text_index", -1))
	_text.text = str(lines[ti]).replace("\n", " ").to_upper() if ti >= 0 and ti < lines.size() else "(NO REVIEW TEXT)"
	var warn := index >= WARN_FROM
	_warning.visible = warn
	if warn:
		if index >= SimReview.FIRED_AT:
			_warning.text = "THE DIRECTOR HAS BEEN DISMISSED."
		else:
			_warning.text = "WARNING: ANOTHER POOR YEAR WILL REACH INDEX %d AND THE DIRECTOR WILL BE DISMISSED." % SimReview.FIRED_AT
