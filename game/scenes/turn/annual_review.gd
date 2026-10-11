extends ScreenPanel
## Annual Review: the Capitol / Politburo verdict on last year, with a portrait placeholder,
## the review line from text/reviews.json, a bar chart of the index history and the
## dismissal warning when the index nears SimReview.FIRED_AT.

const WARN_FROM := SimReview.FIRED_AT - 2

var _review: Dictionary = {}
var _portrait: Label
var _portrait_sub: Label
var _text: Label
var _warning: Label
var _chart: ReviewChart


class ReviewChart extends Control:
	## Review index per year as bars around the START_INDEX baseline: at or below it draws
	## upward in the good colour, above it downward in the poor colour (review.json chart_rule).
	var reviews: Array = []
	var font: Font
	var font_size := 14

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
	split.add_theme_constant_override("separation", 16)
	content.add_child(split)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.0
	left.add_theme_constant_override("separation", 10)
	split.add_child(left)
	var portrait_card := PanelContainer.new()
	portrait_card.theme_type_variation = "Card"
	portrait_card.custom_minimum_size.y = 160
	left.add_child(portrait_card)
	var pbox := VBoxContainer.new()
	pbox.alignment = BoxContainer.ALIGNMENT_CENTER
	portrait_card.add_child(pbox)
	_portrait = Label.new()
	_portrait.theme_type_variation = "Heading"
	_portrait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pbox.add_child(_portrait)
	_portrait_sub = Label.new()
	_portrait_sub.theme_type_variation = "Dim"
	_portrait_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pbox.add_child(_portrait_sub)
	var chart_title := Label.new()
	chart_title.theme_type_variation = "Subheading"
	chart_title.text = "Review history"
	chart_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(chart_title)
	_chart = ReviewChart.new()
	left.add_child(_chart)
	UiHelp.attach(_chart, "I030")

	var right := PanelContainer.new()
	right.theme_type_variation = "Sunken"
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 1.4
	split.add_child(right)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	var rbox := VBoxContainer.new()
	rbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rbox.add_theme_constant_override("separation", 12)
	scroll.add_child(rbox)
	_text = Label.new()
	_text.theme_type_variation = "Subheading"
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rbox.add_child(_text)
	_warning = Label.new()
	_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_warning.add_theme_color_override("font_color", UiPalette.DANGER)
	rbox.add_child(_warning)

	var go := Button.new()
	go.text = "Continue"
	go.theme_type_variation = "Accent"
	go.pressed.connect(func(): Screens.pop())
	footer.add_child(go)
	_refresh()


func setup(args: Dictionary) -> void:
	var r = args.get("review", null)
	_review = r if r is Dictionary else {}
	_refresh()


func on_resume() -> void:
	_refresh()


func _refresh() -> void:
	if not Session.has_game():
		_text.text = "No game in progress."
		return
	var p := Session.me()
	var review := _review
	if review.is_empty() and not p.reviews.is_empty():
		review = p.reviews.back()
	_chart.font = get_theme_default_font()
	_chart.set_reviews(p.reviews)
	var body := "Capitol" if p.side == "usa" else "Politburo"
	if review.is_empty():
		_portrait.text = TurnLogic.review_portrait(p.side, p.review_index)
		_portrait_sub.text = "%s review" % body
		_text.text = "No annual review has been held yet. The %s meets each spring from %d." % [body, 1900 + SimState.FIRST_YEAR + 1]
		_warning.text = ""
		_warning.visible = false
		return
	var index := int(review.get("index", p.review_index))
	_portrait.text = TurnLogic.review_portrait(p.side, index)
	_portrait_sub.text = "%s review, %d   Index %d of %d (lower is better)" % [body, 1900 + int(review.get("year", Session.state().year)), index, SimReview.FIRED_AT]
	var lines: Array = GameData.text.get("reviews", {}).get("review", [])
	var ti := int(review.get("text_index", -1))
	_text.text = str(lines[ti]).replace("\n", " ").capitalize() if ti >= 0 and ti < lines.size() else "(no review text)"
	var warn := index >= WARN_FROM
	_warning.visible = warn
	if warn:
		if index >= SimReview.FIRED_AT:
			_warning.text = "The director has been dismissed."
		else:
			_warning.text = "Warning: another poor year will reach index %d and the director will be dismissed." % SimReview.FIRED_AT
