extends ScreenPanel
## Training Centre, laid out like the original's facility hall: five advanced-training
## facility cards across the top (capsule, LM, EVA, docking, endurance), each with its
## hardware picture and the trainees' portrait tiles; beneath them basic training and
## the medical centre as roster lists, the advanced trainees as a sortable list, and the
## command board to enrol or withdraw. The selected facility is the course on offer.
## Commands go through SimPersonnel and are followed by Session.notify_change().

const SKILL_TITLES := {"capsule": "Capsule", "lm": "LM", "eva": "EVA", "docking": "Docking", "endurance": "Endurance"}
const SKILL_SHORT := {"capsule": "Cap", "lm": "LM", "eva": "EVA", "docking": "Dock", "endurance": "End"}
## Hardware picture for each facility card: [group, slot].
const FACILITY_ART := {"capsule": ["manned", 0], "lm": ["manned", 5], "eva": ["misc", 3], "docking": ["misc", 4], "endurance": ["manned", 1]}
const DEFAULT_HELP := "I021"
const CASE_BG := Color("0a1424")
const TILE := Vector2(62, 74)
const TILE_W := 84.0     ## tile column width, wider than the portrait so names fit

var _skill := "capsule"
var _cards: Dictionary = {}     ## skill -> {"button", "count", "tiles"}

var _basic: DataTable
var _advanced: DataTable
var _medical: DataTable
var _withdraw: Button
var _withdraw_note: Label
var _enrol_title: Label
var _enrol_who: OptionButton
var _enrol_portrait: Control
var _enrol_level: Label
var _enrol_mood: Label
var _enrol_text: Label
var _enrol: Button
var _summary: Label

var _advanced_selected: SimAstronaut
var _candidates: Array = []     ## SimAstronaut in the enrol OptionButton order


func _init() -> void:
	super()
	title = "Training Centre"


func _ready() -> void:
	super()
	# Facility cards.
	var hall := HBoxContainer.new()
	hall.add_theme_constant_override("separation", 10)
	content.add_child(hall)
	UiHelp.attach(hall, DEFAULT_HELP)
	for s in SimAstronaut.SKILLS:
		hall.add_child(_facility_card(s))

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 16)
	content.add_child(split)
	UiHelp.attach(split, DEFAULT_HELP)

	# Left: basic training over the medical centre.
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 6)
	split.add_child(left)
	left.add_child(_banner("BASIC TRAINING"))
	left.add_child(_note("Recruits spend %d seasons here; one random skill improves each season." % _basic_seasons()))
	_basic = DataTable.new()
	_basic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_basic.set_columns([
		{"key": "name", "title": "Name", "stretch": 1.8},
		{"key": "left", "title": "Seasons", "numeric": true, "stretch": 0.9},
		{"key": "mood", "title": "Mood", "numeric": true, "stretch": 0.7, "color": func(r): return UiPalette.mood_color(int(r["mood"]))},
	])
	left.add_child(_basic)
	left.add_child(_banner("MEDICAL CENTRE"))
	left.add_child(_note("The injured return to active duty when their recovery ends."))
	_medical = DataTable.new()
	_medical.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_medical.set_columns([
		{"key": "name", "title": "Name", "stretch": 1.8, "color": func(_r): return UiPalette.WARN},
		{"key": "left", "title": "Recovery", "numeric": true, "stretch": 0.9},
		{"key": "mood", "title": "Mood", "numeric": true, "stretch": 0.7, "color": func(r): return UiPalette.mood_color(int(r["mood"]))},
	])
	left.add_child(_medical)

	# Middle: every advanced trainee, sortable.
	var middle := VBoxContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.size_flags_stretch_ratio = 1.1
	middle.add_theme_constant_override("separation", 6)
	split.add_child(middle)
	middle.add_child(_banner("ADVANCED TRAINING"))
	middle.add_child(_note("One skill per course: +1 after the second season and +1 on completion."))
	_advanced = DataTable.new()
	_advanced.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_advanced.set_columns([
		{"key": "name", "title": "Name", "stretch": 1.6},
		{"key": "focus", "title": "Course", "stretch": 1.1},
		{"key": "level", "title": "Skill", "numeric": true, "stretch": 0.6, "color": func(_r): return UiPalette.GOLD},
		{"key": "left", "title": "Seasons", "numeric": true, "stretch": 0.8},
		{"key": "mood", "title": "Mood", "numeric": true, "stretch": 0.6, "color": func(r): return UiPalette.mood_color(int(r["mood"]))},
	])
	_advanced.row_selected.connect(_on_advanced_row)
	middle.add_child(_advanced)

	# Right: the command board.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.custom_minimum_size.x = 420
	right.add_theme_constant_override("separation", 10)
	split.add_child(right)
	right.add_child(_build_enrol_board())
	right.add_child(_build_withdraw_board())

	_summary = Label.new()
	_summary.theme_type_variation = "Dim"
	_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_summary.clip_text = true
	_summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	footer.add_child(_summary)
	_set_skill(_skill)


func _facility_card(skill: String) -> Control:
	var card := PanelContainer.new()
	card.theme_type_variation = "Card"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	card.add_child(v)
	var b := Button.new()
	b.text = SKILL_TITLES[skill].to_upper()
	b.toggle_mode = true
	b.custom_minimum_size.y = 110
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.expand_icon = false
	b.add_theme_constant_override("icon_max_width", 68)
	b.pressed.connect(_set_skill.bind(skill))
	v.add_child(b)
	var count := Label.new()
	count.theme_type_variation = "Small"
	count.add_theme_color_override("font_color", UiPalette.INFO)
	count.clip_text = true
	count.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(count)
	var tiles := HFlowContainer.new()
	tiles.custom_minimum_size.y = TILE.y + 22
	tiles.add_theme_constant_override("h_separation", 2)
	tiles.add_theme_constant_override("v_separation", 4)
	v.add_child(tiles)
	_cards[skill] = {"button": b, "count": count, "tiles": tiles}
	return card


func _build_enrol_board() -> Control:
	var board := PanelContainer.new()
	board.theme_type_variation = "Card"
	var fv := VBoxContainer.new()
	fv.add_theme_constant_override("separation", 8)
	board.add_child(fv)
	_enrol_title = Label.new()
	_enrol_title.theme_type_variation = "Subheading"
	_enrol_title.add_theme_color_override("font_color", UiPalette.GOLD)
	_enrol_title.clip_text = true
	_enrol_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	fv.add_child(_enrol_title)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	fv.add_child(body)
	var frame := PanelContainer.new()
	frame.theme_type_variation = "Sunken"
	body.add_child(frame)
	_enrol_portrait = Control.new()
	_enrol_portrait.custom_minimum_size = Vector2(108, 130)
	_enrol_portrait.draw.connect(_draw_enrol_portrait)
	frame.add_child(_enrol_portrait)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	body.add_child(col)
	var who := Label.new()
	who.text = "CANDIDATE:"
	who.theme_type_variation = "Dim"
	col.add_child(who)
	_enrol_who = OptionButton.new()
	_enrol_who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_enrol_who.clip_text = true
	_enrol_who.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_enrol_who.item_selected.connect(func(_i): _refresh_enrol_text())
	col.add_child(_enrol_who)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	col.add_child(grid)
	var lk := Label.new()
	lk.text = "SKILL:"
	lk.theme_type_variation = "Dim"
	grid.add_child(lk)
	_enrol_level = Label.new()
	_enrol_level.theme_type_variation = "Subheading"
	_enrol_level.add_theme_color_override("font_color", UiPalette.GOLD)
	grid.add_child(_enrol_level)
	var mk := Label.new()
	mk.text = "MOOD:"
	mk.theme_type_variation = "Dim"
	grid.add_child(mk)
	_enrol_mood = Label.new()
	_enrol_mood.theme_type_variation = "Subheading"
	grid.add_child(_enrol_mood)
	_enrol_text = Label.new()
	_enrol_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_enrol_text.theme_type_variation = "Small"
	fv.add_child(_enrol_text)
	_enrol = Button.new()
	_enrol.theme_type_variation = "Accent"
	_enrol.clip_text = true
	_enrol.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_enrol.pressed.connect(_on_enrol)
	fv.add_child(_enrol)
	return board


func _build_withdraw_board() -> Control:
	var board := PanelContainer.new()
	board.theme_type_variation = "Card"
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	board.add_child(v)
	var t := Label.new()
	t.text = "WITHDRAW FROM TRAINING"
	t.theme_type_variation = "Subheading"
	t.add_theme_color_override("font_color", UiPalette.GOLD)
	v.add_child(t)
	_withdraw_note = Label.new()
	_withdraw_note.theme_type_variation = "Small"
	_withdraw_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_withdraw_note)
	_withdraw = Button.new()
	_withdraw.text = "Withdraw"
	_withdraw.theme_type_variation = "Danger"
	_withdraw.pressed.connect(_on_withdraw)
	v.add_child(_withdraw)
	return board


func _banner(text: String) -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "Sunken"
	var l := Label.new()
	l.text = text
	l.theme_type_variation = "Heading"
	l.add_theme_color_override("font_color", UiPalette.GOLD)
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	panel.add_child(l)
	return panel


func _note(text: String) -> Label:
	var s := Label.new()
	s.text = text
	s.theme_type_variation = "Small"
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return s


func setup(args: Dictionary) -> void:
	var help: String = str(args.get("help", ""))
	if help != "":
		UiHelp.attach(content, help)
	var skill: String = str(args.get("skill", ""))
	if SKILL_TITLES.has(skill):
		_skill = skill
	_set_skill(_skill)


func on_resume() -> void:
	_refresh()


# --- derived view logic (static so tests can cover it without a scene) -------------

## Astronauts eligible for advanced training: active and not in a crew.
static func enrol_candidates(astronauts: Array) -> Array:
	var out: Array = []
	for a in astronauts:
		if a.status == SimAstronaut.Status.ACTIVE and not a.in_crew():
			out.append(a)
	return out


static func by_status(astronauts: Array, status: int) -> Array:
	var out: Array = []
	for a in astronauts:
		if a.status == status:
			out.append(a)
	return out


## Cost and length of an advanced course for a skill at `level`, from constants
## astronauts.advanced_training (module defaults when absent): {ok, cost, seasons, text}.
static func enrol_terms(level: int, short_training: bool, constants: Dictionary = {}) -> Dictionary:
	var adv: Dictionary = constants.get("astronauts", {}).get("advanced_training", {})
	if level >= SimAstronaut.SKILL_MAX:
		return {"ok": false, "cost": 0, "seasons": 0,
			"text": "Already at the maximum of %d. No course is available." % SimAstronaut.SKILL_MAX}
	var cost: int = int(adv.get("cost_mb", SimPersonnel.ADVANCED_COST))
	var seasons: int = int(adv.get("seasons", SimPersonnel.ADVANCED_SEASONS))
	if short_training:
		seasons = int(adv.get("seasons_short_option", SimPersonnel.ADVANCED_SEASONS_SHORT))
	var note := ""
	if level == SimAstronaut.SKILL_MAX - 1:
		cost = int(adv.get("cost_if_skill_already_3", SimPersonnel.ADVANCED_COST_SKILL_3))
		seasons = SimPersonnel.ADVANCED_ENTRY_SKILL_3_SEASONS
		note = " Joins the last %d seasons of the course." % seasons
	var target := mini(level + 2, SimAstronaut.SKILL_MAX)
	return {"ok": true, "cost": cost, "seasons": seasons,
		"text": "%d MB for %d seasons; raises the skill from %d to %d.%s" % [cost, seasons, level, target, note]}


static func training_row(a: SimAstronaut) -> Dictionary:
	var row := {
		"name": a.name.capitalize(), "left": a.training_seasons_left, "mood": a.mood,
		"focus": SKILL_TITLES.get(a.training_focus, a.training_focus) if a.training_focus != "" else "-",
		"_astronaut": a,
	}
	for s in SimAstronaut.SKILLS:
		row[s] = a.skill(s)
	return row


static func medical_row(a: SimAstronaut) -> Dictionary:
	var row := training_row(a)
	row["left"] = a.injured_until_seasons
	return row


# --- drawing -----------------------------------------------------------------------

func _side() -> String:
	return Session.human_side if Session.has_game() else "usa"


func _portrait_tile(a: SimAstronaut) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.custom_minimum_size.x = TILE_W
	var b := Button.new()
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.toggle_mode = true
	b.theme_type_variation = "Flat"
	b.custom_minimum_size = TILE
	b.tooltip_text = "%s: %s training, %d season%s left" % [a.name.capitalize(), SKILL_TITLES.get(a.training_focus, a.training_focus),
		a.training_seasons_left, "" if a.training_seasons_left == 1 else "s"]
	b.set_pressed_no_signal(a == _advanced_selected)
	b.set_meta("astronaut", a)
	b.draw.connect(_draw_tile.bind(b, a))
	b.pressed.connect(_select_trainee.bind(a))
	v.add_child(b)
	var l := Label.new()
	l.text = a.name.capitalize()
	l.theme_type_variation = "Small"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.custom_minimum_size.x = TILE_W
	v.add_child(l)
	return v


func _draw_tile(b: Button, a: SimAstronaut) -> void:
	var r := Rect2(Vector2(2, 2), b.size - Vector2(4, 4))
	PortraitArt.paint(b, r, a.name, a.female, _side(), a.status_name())
	# Seasons left in the corner, the selected trainee framed in gold.
	b.draw_rect(Rect2(r.end.x - 18, r.end.y - 18, 18, 18), Color(0, 0, 0, 0.6))
	b.draw_string(get_theme_default_font(), Vector2(r.end.x - 18, r.end.y - 4), str(a.training_seasons_left), HORIZONTAL_ALIGNMENT_CENTER, 18, UiTheme.SIZE_SMALL, UiPalette.INFO)
	if a == _advanced_selected:
		b.draw_rect(Rect2(Vector2(1, 1), b.size - Vector2(2, 2)), UiPalette.GOLD, false, 2.0)


func _draw_enrol_portrait() -> void:
	var size := _enrol_portrait.size
	_enrol_portrait.draw_rect(Rect2(Vector2.ZERO, size), CASE_BG)
	var a := _enrol_pick()
	if a == null:
		_enrol_portrait.draw_string(get_theme_default_font(), Vector2(0, size.y / 2.0), "-", HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTheme.SIZE_SUBHEADING, UiPalette.TEXT_MUTED)
		return
	PortraitArt.paint(_enrol_portrait, Rect2(Vector2.ZERO, size), a.name, a.female, _side(), a.status_name())


# --- refresh -----------------------------------------------------------------------

func _basic_seasons() -> int:
	return int(GameData.constants.get("astronauts", {}).get("basic_training", {}).get("seasons", SimPersonnel.BASIC_SEASONS))


func _set_skill(skill: String) -> void:
	_skill = skill
	for key in _cards:
		_cards[key]["button"].button_pressed = key == skill
	_refresh()


func _refresh() -> void:
	if not Session.has_game():
		return
	var p := Session.me()
	var side := p.side
	var basic_rows: Array = []
	for a in by_status(p.astronauts, SimAstronaut.Status.BASIC_TRAINING):
		basic_rows.append(training_row(a))
	_basic.set_rows(basic_rows)
	var trainees := by_status(p.astronauts, SimAstronaut.Status.ADVANCED_TRAINING)
	var adv_rows: Array = []
	for a in trainees:
		var row := training_row(a)
		row["level"] = a.skill(a.training_focus) if a.training_focus != "" else 0
		adv_rows.append(row)
	_advanced.set_rows(adv_rows)
	var med_rows: Array = []
	for a in by_status(p.astronauts, SimAstronaut.Status.INJURED):
		med_rows.append(medical_row(a))
	_medical.set_rows(med_rows)
	if not trainees.has(_advanced_selected):
		_advanced_selected = null
	_mark_advanced_row()

	# Facility cards: picture, head count and the trainees' portrait tiles.
	for skill in _cards:
		var card: Dictionary = _cards[skill]
		var art: Array = FACILITY_ART[skill]
		card["button"].icon = ArtAssets.hardware(side, art[0], art[1])
		var tiles: HFlowContainer = card["tiles"]
		for c in tiles.get_children():
			c.queue_free()
		var here: Array = trainees.filter(func(a): return a.training_focus == skill)
		card["count"].text = "%d IN TRAINING" % here.size() if not here.is_empty() else "FACILITY IDLE"
		for a in here:
			tiles.add_child(_portrait_tile(a))
	_refresh_withdraw()

	_candidates = enrol_candidates(p.astronauts)
	var previous: SimAstronaut = null
	if _enrol_who.selected >= 0 and _enrol_who.selected < _enrol_who.item_count:
		previous = _enrol_who.get_item_metadata(_enrol_who.selected)
	_enrol_who.clear()
	for i in _candidates.size():
		var a: SimAstronaut = _candidates[i]
		_enrol_who.add_item("%s   (%s %d)" % [a.name.capitalize(), SKILL_SHORT[_skill], a.skill(_skill)])
		_enrol_who.set_item_metadata(i, a)
		if a == previous:
			_enrol_who.select(i)
	if _candidates.is_empty():
		_enrol_who.add_item("No eligible astronaut")
		_enrol_who.set_item_metadata(0, null)
	_refresh_enrol_text()
	_summary.text = "In basic training %d,  in advanced training %d,  injured %d,  eligible to enrol %d" % [
		basic_rows.size(), adv_rows.size(), med_rows.size(), _candidates.size()]


func _select_trainee(a: SimAstronaut) -> void:
	_advanced_selected = a
	_mark_advanced_row()
	_refresh_selection()


func _on_advanced_row(row: Dictionary) -> void:
	_advanced_selected = row["_astronaut"]
	_refresh_selection()


func _mark_advanced_row() -> void:
	for i in _advanced.rows.size():
		if _advanced.rows[i].get("_astronaut") == _advanced_selected:
			_advanced.select_index(i)


## Reflect the selected trainee on the portrait tiles and the withdraw board.
func _refresh_selection() -> void:
	for skill in _cards:
		for tile in _cards[skill]["tiles"].get_children():
			var b: Button = tile.get_child(0)
			b.set_pressed_no_signal(b.get_meta("astronaut") == _advanced_selected)
			b.queue_redraw()
	_refresh_withdraw()


func _refresh_withdraw() -> void:
	_withdraw.disabled = _advanced_selected == null
	if _advanced_selected == null:
		_withdraw_note.text = "Select a trainee (a portrait tile or a row) to withdraw them early. Part of the fee is refunded depending on how far along they are."
	else:
		_withdraw_note.text = "Withdraw %s from %s training (%d seasons left)." % [
			_advanced_selected.name.capitalize(), SKILL_TITLES.get(_advanced_selected.training_focus, _advanced_selected.training_focus),
			_advanced_selected.training_seasons_left]


func _enrol_pick() -> SimAstronaut:
	if _enrol_who == null or _enrol_who.selected < 0 or _enrol_who.selected >= _enrol_who.item_count:
		return null
	return _enrol_who.get_item_metadata(_enrol_who.selected)


func _enrol_skill_key() -> String:
	return _skill if SKILL_TITLES.has(_skill) else ""


func _refresh_enrol_text() -> void:
	var a := _enrol_pick()
	var skill := _enrol_skill_key()
	_enrol_title.text = "ENROL: %s TRAINING" % SKILL_TITLES.get(skill, "-").to_upper()
	_enrol.text = "Enrol in %s training" % SKILL_TITLES.get(skill, "-")
	_enrol_portrait.queue_redraw()
	if a == null or skill == "":
		_enrol_level.text = "-"
		_enrol_mood.text = "-"
		_enrol_text.text = "Only active astronauts who are not in a crew can enrol."
		_enrol.disabled = true
		return
	_enrol_level.text = "%s %d" % [SKILL_SHORT[skill].to_upper(), a.skill(skill)]
	_enrol_mood.text = str(a.mood)
	_enrol_mood.add_theme_color_override("font_color", UiPalette.mood_color(a.mood))
	var state := Session.state()
	var terms := enrol_terms(a.skill(skill), bool(state.options.get("short_training", false)), state.constants())
	var text: String = terms["text"]
	if terms["ok"] and a.program_slot >= 0:
		var prog: SimProgram = Session.me().program("manned", a.program_slot)
		text += " %s leaves the %s pool for the duration." % [a.name.capitalize(), prog.display_name().capitalize() if prog != null else "program"]
	var affordable: bool = terms["ok"] and int(terms["cost"]) <= Session.me().cash
	if terms["ok"] and not affordable:
		text += " Not enough cash."
	_enrol_text.text = text
	_enrol.disabled = not affordable


func _on_enrol() -> void:
	var a := _enrol_pick()
	var skill := _enrol_skill_key()
	if a == null or skill == "":
		return
	if SimPersonnel.start_advanced_training(Session.state(), Session.me(), a, skill):
		Session.notify_change()
		_refresh()
	else:
		ConfirmBox.notice(self, "Not enrolled", "%s could not start %s training." % [a.name.capitalize(), SKILL_TITLES[skill]])


func _on_withdraw() -> void:
	var a := _advanced_selected
	if a == null:
		return
	var focus: String = SKILL_TITLES.get(a.training_focus, a.training_focus)
	if not await ConfirmBox.ask(self, "Withdraw from training?",
			"%s leaves %s training now. Progress so far is kept; part of the fee comes back." % [a.name.capitalize(), focus]):
		return
	var refund := SimPersonnel.withdraw_training(Session.state(), Session.me(), a)
	Session.notify_change()
	_refresh()
	_withdraw_note.text = "%s withdrawn from %s training. %d MB refunded." % [a.name.capitalize(), focus, refund]
