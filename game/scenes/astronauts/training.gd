extends ScreenPanel
## Training Centre: who is in basic training, who is in advanced training (with a
## withdraw command), an enrolment form for advanced training and the medical centre
## roll of injured astronauts. Commands go through SimPersonnel and are followed by
## Session.notify_change().

const SKILL_TITLES := {"capsule": "Capsule", "lm": "LM", "eva": "EVA", "docking": "Docking", "endurance": "Endurance"}
const SKILL_SHORT := {"capsule": "Cap", "lm": "LM", "eva": "EVA", "docking": "Dock", "endurance": "End"}
const DEFAULT_HELP := "I021"

var _basic: DataTable
var _advanced: DataTable
var _medical: DataTable
var _withdraw: Button
var _withdraw_note: Label
var _enrol_who: OptionButton
var _enrol_skill: OptionButton
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
	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 16)
	content.add_child(split)
	UiHelp.attach(split, DEFAULT_HELP)

	# left: basic training over medical
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	split.add_child(left)
	left.add_child(_heading("Basic training", "Recruits spend %d seasons here; one random skill improves each season." % _basic_seasons()))
	_basic = DataTable.new()
	_basic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_basic.set_columns(_skill_columns([
		{"key": "name", "title": "Name", "stretch": 1.8},
		{"key": "left", "title": "Seasons left", "numeric": true, "stretch": 1.0},
		{"key": "mood", "title": "Mood", "numeric": true, "stretch": 0.7, "color": func(r): return UiPalette.mood_color(int(r["mood"]))},
	]))
	left.add_child(_basic)
	left.add_child(_heading("Medical centre", "Injured astronauts return to active duty when their recovery ends."))
	_medical = DataTable.new()
	_medical.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_medical.set_columns(_skill_columns([
		{"key": "name", "title": "Name", "stretch": 1.8},
		{"key": "left", "title": "Seasons to recover", "numeric": true, "stretch": 1.2},
		{"key": "mood", "title": "Mood", "numeric": true, "stretch": 0.7, "color": func(r): return UiPalette.mood_color(int(r["mood"]))},
	]))
	left.add_child(_medical)

	# right: advanced training over the enrol form
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	split.add_child(right)
	right.add_child(_heading("Advanced training", "One skill per course: +1 after the second season and +1 on completion."))
	_advanced = DataTable.new()
	_advanced.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_advanced.set_columns(_skill_columns([
		{"key": "name", "title": "Name", "stretch": 1.8},
		{"key": "focus", "title": "Focus", "stretch": 1.0},
		{"key": "left", "title": "Seasons left", "numeric": true, "stretch": 1.0},
		{"key": "mood", "title": "Mood", "numeric": true, "stretch": 0.7, "color": func(r): return UiPalette.mood_color(int(r["mood"]))},
	]))
	_advanced.row_selected.connect(_on_advanced_row)
	right.add_child(_advanced)
	var wrow := HBoxContainer.new()
	right.add_child(wrow)
	_withdraw_note = Label.new()
	_withdraw_note.theme_type_variation = "Small"
	_withdraw_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_withdraw_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wrow.add_child(_withdraw_note)
	_withdraw = Button.new()
	_withdraw.text = "Withdraw"
	_withdraw.theme_type_variation = "Danger"
	_withdraw.pressed.connect(_on_withdraw)
	wrow.add_child(_withdraw)

	var form := PanelContainer.new()
	form.theme_type_variation = "Card"
	right.add_child(form)
	var fv := VBoxContainer.new()
	fv.add_theme_constant_override("separation", 8)
	form.add_child(fv)
	var ft := Label.new()
	ft.text = "Enrol in advanced training"
	ft.theme_type_variation = "Subheading"
	fv.add_child(ft)
	var row := HBoxContainer.new()
	fv.add_child(row)
	_enrol_who = OptionButton.new()
	_enrol_who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_enrol_who.size_flags_stretch_ratio = 1.4
	_enrol_who.clip_text = true
	_enrol_who.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_enrol_who.item_selected.connect(func(_i): _refresh_enrol_text())
	row.add_child(_enrol_who)
	_enrol_skill = OptionButton.new()
	_enrol_skill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_enrol_skill.clip_text = true
	for s in SimAstronaut.SKILLS:
		_enrol_skill.add_item(SKILL_TITLES[s])
	_enrol_skill.item_selected.connect(func(_i): _refresh_enrol_text())
	row.add_child(_enrol_skill)
	_enrol = Button.new()
	_enrol.text = "Enrol"
	_enrol.theme_type_variation = "Accent"
	_enrol.pressed.connect(_on_enrol)
	row.add_child(_enrol)
	_enrol_text = Label.new()
	_enrol_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_enrol_text.theme_type_variation = "Small"
	fv.add_child(_enrol_text)

	_summary = Label.new()
	_summary.theme_type_variation = "Dim"
	_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_summary.clip_text = true
	_summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	footer.add_child(_summary)


func _heading(text: String, sub: String) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var l := Label.new()
	l.text = text
	l.theme_type_variation = "Subheading"
	v.add_child(l)
	var s := Label.new()
	s.text = sub
	s.theme_type_variation = "Small"
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(s)
	return v


func _skill_columns(front: Array) -> Array:
	var cols := front.duplicate()
	for s in SimAstronaut.SKILLS:
		cols.append({"key": s, "title": SKILL_SHORT[s], "numeric": true, "stretch": 0.6})
	return cols


func setup(args: Dictionary) -> void:
	var help: String = str(args.get("help", ""))
	if help != "":
		UiHelp.attach(content, help)
	_refresh()


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


# --- refresh -----------------------------------------------------------------------

func _basic_seasons() -> int:
	return int(GameData.constants.get("astronauts", {}).get("basic_training", {}).get("seasons", SimPersonnel.BASIC_SEASONS))


func _refresh() -> void:
	var p := Session.me()
	var basic_rows: Array = []
	for a in by_status(p.astronauts, SimAstronaut.Status.BASIC_TRAINING):
		basic_rows.append(training_row(a))
	_basic.set_rows(basic_rows)
	var adv_rows: Array = []
	for a in by_status(p.astronauts, SimAstronaut.Status.ADVANCED_TRAINING):
		adv_rows.append(training_row(a))
	_advanced.set_rows(adv_rows)
	var med_rows: Array = []
	for a in by_status(p.astronauts, SimAstronaut.Status.INJURED):
		med_rows.append(medical_row(a))
	_medical.set_rows(med_rows)
	var keep := false
	for r in adv_rows:
		if r["_astronaut"] == _advanced_selected:
			keep = true
	if not keep:
		_advanced_selected = null
	_refresh_withdraw()

	_candidates = enrol_candidates(p.astronauts)
	var previous: SimAstronaut = null
	if _enrol_who.selected >= 0 and _enrol_who.selected < _enrol_who.item_count:
		previous = _enrol_who.get_item_metadata(_enrol_who.selected)
	_enrol_who.clear()
	for i in _candidates.size():
		var a: SimAstronaut = _candidates[i]
		_enrol_who.add_item(a.name.capitalize())
		_enrol_who.set_item_metadata(i, a)
		if a == previous:
			_enrol_who.select(i)
	if _candidates.is_empty():
		_enrol_who.add_item("No eligible astronaut")
		_enrol_who.set_item_metadata(0, null)
	_refresh_enrol_text()
	_summary.text = "In basic training %d,  in advanced training %d,  injured %d,  eligible to enrol %d" % [
		basic_rows.size(), adv_rows.size(), med_rows.size(), _candidates.size()]


func _on_advanced_row(row: Dictionary) -> void:
	_advanced_selected = row["_astronaut"]
	_refresh_withdraw()


func _refresh_withdraw() -> void:
	_withdraw.disabled = _advanced_selected == null
	if _advanced_selected == null:
		_withdraw_note.text = "Select a trainee to withdraw them early. Part of the fee is refunded depending on how far along they are."
	else:
		_withdraw_note.text = "Withdraw %s from %s training (%d seasons left)." % [
			_advanced_selected.name.capitalize(), SKILL_TITLES.get(_advanced_selected.training_focus, _advanced_selected.training_focus),
			_advanced_selected.training_seasons_left]


func _enrol_pick() -> SimAstronaut:
	if _enrol_who.selected < 0 or _enrol_who.selected >= _enrol_who.item_count:
		return null
	return _enrol_who.get_item_metadata(_enrol_who.selected)


func _enrol_skill_key() -> String:
	var i := _enrol_skill.selected
	return SimAstronaut.SKILLS[i] if i >= 0 and i < SimAstronaut.SKILLS.size() else ""


func _refresh_enrol_text() -> void:
	var a := _enrol_pick()
	var skill := _enrol_skill_key()
	if a == null or skill == "":
		_enrol_text.text = "Only active astronauts who are not in a crew can enrol."
		_enrol.disabled = true
		return
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
