extends ScreenPanel
## End of the game: who won and why, the alternate-history narration from text/endgame.json,
## both sides' final prestige and director scores, and the way out (Statistics or title).

const MUSEUM := "res://scenes/museum/museum.tscn"
const TITLE := "res://scenes/ui/title_screen.tscn"

var _report: Dictionary = {}
var _headline: Label
var _reason: Label
var _story: VBoxContainer
var _scores: DataTable


func _init() -> void:
	super()
	title = "The Race Is Over"
	show_back = false


func _ready() -> void:
	super()
	_headline = Label.new()
	_headline.theme_type_variation = "Title"
	_headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_headline)
	_reason = Label.new()
	_reason.theme_type_variation = "Dim"
	_reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_reason)

	var panel := PanelContainer.new()
	panel.theme_type_variation = "Sunken"
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	_story = VBoxContainer.new()
	_story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_story.add_theme_constant_override("separation", 12)
	scroll.add_child(_story)

	var scores_title := Label.new()
	scores_title.theme_type_variation = "Subheading"
	scores_title.text = "Final standings"
	content.add_child(scores_title)
	_scores = DataTable.new()
	# Header row plus one line per side; the header button is about two row heights tall.
	_scores.custom_minimum_size.y = DataTable.ROW_MIN_HEIGHT * 4 + 12
	_scores.set_columns([
		{"key": "side", "title": "Side", "stretch": 2},
		{"key": "director", "title": "Director", "stretch": 2},
		{"key": "level", "title": "Level"},
		{"key": "prestige", "title": "Prestige", "numeric": true},
		{"key": "score", "title": "Director score", "numeric": true},
		{"key": "review", "title": "Review index", "numeric": true},
	])
	content.add_child(_scores)
	UiHelp.attach(_scores, "I030")

	var stats := Button.new()
	stats.text = "Statistics"
	stats.pressed.connect(func(): Screens.push(load(MUSEUM)))
	footer.add_child(stats)
	var back := Button.new()
	back.text = "Return to title"
	back.theme_type_variation = "Accent"
	back.pressed.connect(func(): Screens.reset(load(TITLE)))
	footer.add_child(back)
	_refresh()


func setup(args: Dictionary) -> void:
	var r = args.get("report", {})
	_report = r if r is Dictionary else {}
	_refresh()


func on_resume() -> void:
	_refresh()


## The game ends by itself, so Escape must not pop this screen.
func handles_back() -> bool:
	return true


func _refresh() -> void:
	for c in _story.get_children():
		c.queue_free()
	if not Session.has_game():
		_headline.text = "No game"
		return
	var state := Session.state()
	var me := Session.me()
	var winner := int(_report.get("winner", state.winner))
	var reason := str(state.end_reason)
	if winner < 0:
		_headline.text = "Failed objective"
		_headline.add_theme_color_override("font_color", UiPalette.WARN)
		_reason.text = "Nobody landed on the Moon. %s" % (reason.capitalize() if reason != "" else "")
	elif winner == me.index:
		_headline.text = "Victory for the %s" % TurnLogic.side_name(me.side)
		_headline.add_theme_color_override("font_color", UiPalette.OK)
		_reason.text = reason.capitalize()
	else:
		_headline.text = "The %s wins the race" % TurnLogic.side_name(state.player(winner).side)
		_headline.add_theme_color_override("font_color", UiPalette.DANGER)
		_reason.text = reason.capitalize()
	if not state.ended and _report.is_empty():
		_reason.text = "The game has not ended yet."
	set_backdrop("endgame_%s_%s" % [me.side, "win" if winner == me.index else "lose"])

	var lines: Array = GameData.text.get("endgame", {}).get("endgame", [])
	var sides: Array = [me.index] if winner >= 0 else [0, 1]
	for side_index in sides:
		var head := Label.new()
		head.theme_type_variation = "Subheading"
		head.text = TurnLogic.side_name(state.player(side_index).side)
		head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_story.add_child(head)
		var ti := TurnLogic.endgame_text_index(state.year, winner, side_index)
		var body := Label.new()
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.text = str(lines[ti]).replace("\n", " ").capitalize() if ti >= 0 and ti < lines.size() else "(no ending text)"
		_story.add_child(body)

	var rows: Array = []
	for p in state.players:
		rows.append({
			"side": TurnLogic.side_name(p.side), "director": p.director_name,
			"level": TurnLogic.level_name(p.level), "prestige": p.prestige_total,
			"score": SimReview.director_score(state, p), "review": p.review_index,
		})
	_scores.set_rows(rows)
