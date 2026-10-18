extends ScreenPanel
## Astronaut Complex, laid out as a dossier: the selected astronaut's name banner, big
## portrait, ratings and record on the left; the roster list in the middle; and on the
## right "Transfer to location", a lamp board of capsule programmes and training
## facilities (lit where the astronaut is), with the crew editor beneath it (seats as a
## lamp column, lit when filled). Each region is a UiPanel (ui-style-guide section 4).
## Commands go through SimPersonnel and are followed by Session.notify_change().

const FILTERS := ["all", "active", "training", "injured", "retired", "dead"]
const FILTER_TITLES := {"all": "All", "active": "Active", "training": "Training", "injured": "Injured", "retired": "Retired", "dead": "Dead"}
const SKILL_TITLES := {"capsule": "Capsule", "lm": "LM", "eva": "EVA", "docking": "Docking", "endurance": "Endurance"}
const SKILL_SHORT := {"capsule": "Cap", "lm": "LM", "eva": "EVA", "docking": "Dock", "endurance": "End"}
const ROLE_TITLES := {"cap": "Capsule", "lm": "LM", "eva": "EVA", "dock": "Docking"}
const ROLE_ORDER := ["cap", "lm", "eva", "dock"]
const ROLE_SKILLS := {"cap": "capsule", "lm": "lm", "eva": "eva", "dock": "docking"}
const DEFAULT_HELP := "I020"
const TRAINING := "res://scenes/astronauts/training.tscn"
## Status colour for the roster. A function, not a const: WARN and DANGER follow the
## colour-blind setting.
static func status_color(status: int) -> Color:
	match status:
		SimAstronaut.Status.BASIC_TRAINING, SimAstronaut.Status.ADVANCED_TRAINING:
			return UiPalette.INFO
		SimAstronaut.Status.INJURED:
			return UiPalette.WARN
		SimAstronaut.Status.RETIRED:
			return UiPalette.TEXT_MUTED
		SimAstronaut.Status.DEAD:
			return UiPalette.DANGER
	return UiPalette.TEXT

var _filter := "all"
var _filter_buttons: Dictionary = {}
var _table: DataTable
var _selected: SimAstronaut

# dossier column
var _banner: Label
var _portrait: Control
var _ratings: Dictionary = {}       ## key -> value Label
var _tenure: Label
var _history: Label
var _compat: Label

# transfer board
var _program_box: VBoxContainer
var _program_buttons: Dictionary = {}  ## slot -> Lamp
var _training_lamps: Dictionary = {}   ## skill -> Lamp
var _unassign: Button

# crew editor
var _crew_slot := -1
var _crew_program_opt: OptionButton
var _crew_capacity: Label
var _crews_box: VBoxContainer
var _pool_box: VBoxContainer
var _pool_checks: Array = []          ## CheckBox per candidate
var _picked: Array = []               ## SimAstronaut in seat order
var _seat_box: VBoxContainer
var _crew_index_opt: OptionButton
var _warning: Label
var _set_crew: Button

var _summary: Label


func _init() -> void:
	super()
	title = "Astronaut Complex"


func _ready() -> void:
	super()
	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 16)
	content.add_child(split)
	split.add_child(_build_dossier_column())
	split.add_child(_build_roster_column())
	split.add_child(_build_operations_column())
	set_room("room_crew")
	_set_filter(_filter)


func _build_roster_column() -> Control:
	var panel := UiPanel.new("Roster", DEFAULT_HELP)
	panel.size_flags_stretch_ratio = 1.0
	panel.custom_minimum_size.x = 440
	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 4)
	panel.body.add_child(filters)
	for f in FILTERS:
		var b := Button.new()
		b.text = FILTER_TITLES[f]
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.tooltip_text = "Show %s astronauts" % ("every" if f == "all" else FILTER_TITLES[f].to_lower())
		b.pressed.connect(_set_filter.bind(f))
		filters.add_child(b)
		_filter_buttons[f] = b
	_table = DataTable.new()
	_table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_table.tooltip_text = "Click a row to open the dossier; click a column heading to sort."
	var cols: Array = [
		{"key": "name", "title": "Name", "stretch": 1.5, "color": func(r): return status_color(r["_astronaut"].status)},
		{"key": "status", "title": "Status", "stretch": 1.3},
		{"key": "program", "title": "Program", "stretch": 1.2},
		{"key": "mood", "title": "Mood", "numeric": true, "stretch": 0.6, "color": func(r): return UiPalette.mood_color(int(r["mood"]))},
		{"key": "missions_flown", "title": "Flts", "numeric": true, "stretch": 0.5},
	]
	_table.set_columns(cols)
	_table.row_selected.connect(_on_row)
	panel.body.add_child(_table)
	_summary = Label.new()
	_summary.theme_type_variation = "Small"
	_summary.add_theme_color_override("font_color", UiPalette.TEXT_DIM)
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.body.add_child(_summary)
	return panel


func _build_dossier_column() -> Control:
	var panel := UiPanel.new("Dossier", DEFAULT_HELP)
	panel.size_flags_stretch_ratio = 0.9
	panel.custom_minimum_size.x = 360
	var side := panel.body
	var banner_panel := PanelContainer.new()
	banner_panel.theme_type_variation = "Sunken"
	side.add_child(banner_panel)
	_banner = Label.new()
	_banner.theme_type_variation = "Heading"
	_banner.add_theme_color_override("font_color", UiPalette.GOLD)
	_banner.clip_text = true
	_banner.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	banner_panel.add_child(_banner)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	side.add_child(body)
	var frame := PanelContainer.new()
	frame.theme_type_variation = "Sunken"
	body.add_child(frame)
	_portrait = Control.new()
	_portrait.custom_minimum_size = Vector2(200, 240)
	_portrait.draw.connect(_draw_portrait)
	frame.add_child(_portrait)
	var ratings := GridContainer.new()
	ratings.columns = 2
	ratings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ratings.add_theme_constant_override("h_separation", 12)
	ratings.add_theme_constant_override("v_separation", 6)
	body.add_child(ratings)
	for key in ["mood", "capsule", "lm", "eva", "docking", "endurance"]:
		var k := Label.new()
		k.text = ("Mood" if key == "mood" else SKILL_SHORT[key]).to_upper()
		k.theme_type_variation = "Caps"
		k.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		k.tooltip_text = "Mood" if key == "mood" else "%s skill (0-%d)" % [SKILL_TITLES[key], SimAstronaut.SKILL_MAX]
		k.mouse_filter = Control.MOUSE_FILTER_PASS
		ratings.add_child(k)
		var v := Label.new()
		v.theme_type_variation = "Subheading"
		v.add_theme_color_override("font_color", UiPalette.GOLD)
		ratings.add_child(v)
		_ratings[key] = v
	_tenure = Label.new()
	_tenure.theme_type_variation = "Dim"
	_tenure.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_tenure)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(scroll)
	var notes := VBoxContainer.new()
	notes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notes.add_theme_constant_override("separation", 6)
	scroll.add_child(notes)
	notes.add_child(_caps("Compatibility"))
	_compat = Label.new()
	_compat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_compat.theme_type_variation = "Small"
	notes.add_child(_compat)
	notes.add_child(_caps("Mission history"))
	_history = Label.new()
	_history.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_history.theme_type_variation = "Small"
	notes.add_child(_history)
	return panel


func _draw_portrait() -> void:
	var size := _portrait.size
	_portrait.draw_rect(Rect2(Vector2.ZERO, size), Color("0a1424"))
	if _selected == null:
		return
	var side := Session.human_side if Session.has_game() else "usa"
	PortraitArt.paint(_portrait, Rect2(Vector2.ZERO, size), _selected.name, _selected.female, side, _selected.status_name())
	# Status band along the bottom, coloured like the roster.
	var col: Color = status_color(_selected.status)
	_portrait.draw_rect(Rect2(0, size.y - 26, size.x, 26), Color(0, 0, 0, 0.55))
	_portrait.draw_string(get_theme_default_font(), Vector2(0, size.y - 8), status_title(_selected).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTheme.SIZE_SMALL, col)


func _build_operations_column() -> Control:
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.size_flags_stretch_ratio = 1.2
	side.custom_minimum_size.x = 400
	side.add_theme_constant_override("separation", 12)

	var board := UiPanel.new("Transfer to location", DEFAULT_HELP)
	side.add_child(board)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 10)
	board.body.add_child(columns)
	var prog_col := VBoxContainer.new()
	prog_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prog_col.add_theme_constant_override("separation", 4)
	columns.add_child(prog_col)
	prog_col.add_child(_caps("Programme"))
	_program_box = VBoxContainer.new()
	_program_box.add_theme_constant_override("separation", 4)
	prog_col.add_child(_program_box)
	var training_box := VBoxContainer.new()
	training_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	training_box.add_theme_constant_override("separation", 4)
	columns.add_child(training_box)
	training_box.add_child(_caps("Training"))
	for key in SimAstronaut.SKILLS:
		var tb := Lamp.new(SKILL_TITLES[key])
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.tooltip_text = "Open the Training Centre at the %s facility" % SKILL_TITLES[key].to_lower()
		tb.pressed.connect(func(): Screens.push(load(TRAINING), {"id": "training", "title": "Training Centre", "help": "I120", "skill": key}))
		training_box.add_child(tb)
		_training_lamps[key] = tb
	_unassign = board.add_action("Release from program", "caution", _on_unassign)

	side.add_child(_build_crew_column())
	return side


func _build_crew_column() -> Control:
	var panel := UiPanel.new("Crew editor", DEFAULT_HELP)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var side := panel.body

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	side.add_child(head)
	var t := _caps("Programme")
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(t)
	_crew_program_opt = OptionButton.new()
	_crew_program_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_crew_program_opt.clip_text = true
	_crew_program_opt.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_crew_program_opt.tooltip_text = "The capsule programme whose crews you are editing"
	_crew_program_opt.item_selected.connect(_on_crew_program_selected)
	head.add_child(_crew_program_opt)
	_crew_capacity = Label.new()
	_crew_capacity.theme_type_variation = "Small"
	_crew_capacity.add_theme_color_override("font_color", UiPalette.TEXT_DIM)
	_crew_capacity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_crew_capacity)

	side.add_child(_caps("Crews"))
	var crews_scroll := ScrollContainer.new()
	crews_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	crews_scroll.size_flags_stretch_ratio = 1.1
	crews_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(crews_scroll)
	_crews_box = VBoxContainer.new()
	_crews_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_crews_box.add_theme_constant_override("separation", 6)
	crews_scroll.add_child(_crews_box)

	var form_head := _caps("Form a crew")
	form_head.tooltip_text = "Tick astronauts in seat order; the first pick commands. Click a lit seat lamp to release it."
	form_head.mouse_filter = Control.MOUSE_FILTER_PASS
	side.add_child(form_head)
	var form := HBoxContainer.new()
	form.size_flags_vertical = Control.SIZE_EXPAND_FILL
	form.add_theme_constant_override("separation", 10)
	side.add_child(form)
	var pool_scroll := ScrollContainer.new()
	pool_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pool_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pool_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	form.add_child(pool_scroll)
	_pool_box = VBoxContainer.new()
	_pool_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pool_scroll.add_child(_pool_box)
	_seat_box = VBoxContainer.new()
	_seat_box.custom_minimum_size.x = 250
	_seat_box.add_theme_constant_override("separation", 4)
	form.add_child(_seat_box)

	_warning = Label.new()
	_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_warning.theme_type_variation = "Small"
	side.add_child(_warning)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	side.add_child(actions)
	var as_label := _caps("Save as")
	as_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	actions.add_child(as_label)
	_crew_index_opt = OptionButton.new()
	_crew_index_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_crew_index_opt.clip_text = true
	_crew_index_opt.tooltip_text = "Which crew slot the picked seats are saved to"
	actions.add_child(_crew_index_opt)
	_set_crew = panel.add_action("Set crew", "go", _on_set_crew)
	return panel


## A small label in the wide caps face.
func _caps(text: String) -> Label:
	var l := Label.new()
	l.text = text.to_upper()
	l.theme_type_variation = "Caps"
	return l


## Style an action (UiAction colour rules) and give it a tooltip when it is not blocked
## (a blocked action's tooltip is its reason).
static func _act(b: Button, kind: String, text: String, reason := "", tip := "") -> void:
	UiAction.style(b, kind, text, reason)
	if kind != "blocked" and tip != "":
		b.tooltip_text = tip


func setup(args: Dictionary) -> void:
	var help: String = str(args.get("help", ""))
	if help != "":
		UiHelp.attach(content, help)
	_refresh()


func on_resume() -> void:
	_refresh()


# --- derived view logic (static so tests can cover it without a scene) -------------

## True when the astronaut belongs under the roster filter button.
static func matches_filter(a: SimAstronaut, filter: String) -> bool:
	match filter:
		"all":
			return true
		"active":
			return a.status == SimAstronaut.Status.ACTIVE
		"training":
			return a.status == SimAstronaut.Status.BASIC_TRAINING or a.status == SimAstronaut.Status.ADVANCED_TRAINING
		"injured":
			return a.status == SimAstronaut.Status.INJURED
		"retired":
			return a.status == SimAstronaut.Status.RETIRED
		"dead":
			return a.status == SimAstronaut.Status.DEAD
	return false


static func filter_roster(astronauts: Array, filter: String) -> Array:
	var out: Array = []
	for a in astronauts:
		if matches_filter(a, filter):
			out.append(a)
	return out


static func status_title(a: SimAstronaut) -> String:
	var s := a.status_name().replace("_", " ").capitalize()
	if a.status == SimAstronaut.Status.ADVANCED_TRAINING and a.training_focus != "":
		s += " (%s)" % SKILL_TITLES.get(a.training_focus, a.training_focus)
	return s


static func crew_label(a: SimAstronaut) -> String:
	if not a.in_crew():
		return "-"
	return "Crew %d, seat %d" % [a.crew_index + 1, a.crew_position + 1]


static func program_label(a: SimAstronaut, p: SimPlayer) -> String:
	if a.program_slot < 0:
		return "-"
	var prog: SimProgram = p.program("manned", a.program_slot)
	return prog.display_name().capitalize() if prog != null else "Slot %d" % a.program_slot


## One roster table row.
static func roster_row(a: SimAstronaut, p: SimPlayer) -> Dictionary:
	var row := {
		"name": a.name.capitalize(), "status": status_title(a), "program": program_label(a, p),
		"crew": crew_label(a), "mood": a.mood, "missions_flown": a.missions_flown,
		"hero": "Hero" if a.hero else "", "_astronaut": a,
	}
	for s in SimAstronaut.SKILLS:
		row[s] = a.skill(s)
	return row


## Seat labels for a crew of `size` from constants crew.role_slots_by_crew_size (falls
## back to the module default). Seat 0 is the commander.
static func seat_labels(size: int, table: Dictionary = {}) -> PackedStringArray:
	var slots: Variant = table.get(str(size), table.get(size, null))
	if slots == null:
		slots = SimPersonnel.ROLE_SLOTS_DEFAULT.get(size, {})
	var out: PackedStringArray = []
	for seat in size:
		var roles: PackedStringArray = []
		for key in ROLE_ORDER:
			var s: Variant = slots.get(key, null)
			if s != null and int(s) == seat:
				roles.append(ROLE_TITLES[key])
		var label := "Commander" if seat == 0 else "Seat %d" % (seat + 1)
		if not roles.is_empty():
			label += ": " + " / ".join(roles)
		out.append(label)
	return out


## How the astronaut gets on with each crewmate, both directions.
static func compat_lines(a: SimAstronaut, mates: Array) -> PackedStringArray:
	var out: PackedStringArray = []
	for m in mates:
		if m == a:
			continue
		var likes := SimPersonnel.compatible(a, m)
		var liked := SimPersonnel.compatible(m, a)
		var verdict := "get on"
		if not likes and not liked:
			verdict = "mutual dislike"
		elif not likes:
			verdict = "%s dislikes %s" % [a.name.capitalize(), m.name.capitalize()]
		elif not liked:
			verdict = "%s dislikes %s" % [m.name.capitalize(), a.name.capitalize()]
		out.append("%s: %s" % [m.name.capitalize(), verdict])
	return out


## Conflicts and per-role skills for a (possibly partial) crew. Skills are only
## meaningful for a full crew; a partial pick reports the count instead.
static func crew_summary(members: Array, capacity: int, state: SimState = null, table: Dictionary = {}) -> String:
	if members.is_empty():
		return "No seats filled."
	var conflicts := SimPersonnel.crew_conflicts(members)
	var text := "%d conflict%s" % [conflicts, "" if conflicts == 1 else "s"]
	if members.size() != capacity:
		return "%s.  %d of %d seats filled." % [text, members.size(), capacity]
	var slots: Variant = table.get(str(capacity), table.get(capacity, null))
	if slots == null:
		slots = SimPersonnel.ROLE_SLOTS_DEFAULT.get(capacity, {})
	var parts: PackedStringArray = []
	for s in SimAstronaut.SKILLS:
		var seat: Variant = slots.get(SimPersonnel.ROLE_KEYS.get(s, ""), null) if s != "endurance" else 0
		if seat == null:
			parts.append("%s -" % SKILL_SHORT[s])
		else:
			parts.append("%s %d" % [SKILL_SHORT[s], SimPersonnel.crew_skill(members, s, state)])
	return "%s.  Crew skills: %s." % [text, ", ".join(parts)]


static func history_lines(a: SimAstronaut, missions: Array) -> PackedStringArray:
	var out: PackedStringArray = []
	for h in a.mission_history:
		var idx: int = int(h.get("mission_index", -1))
		var mname: String = str(missions[idx].get("name", "Mission %d" % idx)) if idx >= 0 and idx < missions.size() else "Mission %d" % idx
		var season: String = "Spring" if int(h.get("season", 0)) == SimState.SEASON_SPRING else "Fall"
		out.append("%s %d  %s: %s" % [season, 1900 + int(h.get("year", 0)), mname, str(h.get("outcome", ""))])
	return out



# --- refresh -----------------------------------------------------------------------

func _set_filter(f: String) -> void:
	_filter = f
	for key in _filter_buttons:
		_filter_buttons[key].button_pressed = key == f
	_refresh()


func _refresh() -> void:
	var p := Session.me()
	var rows: Array = []
	for a in filter_roster(p.astronauts, _filter):
		rows.append(roster_row(a, p))
	_table.set_rows(rows)
	var visible_sel := false
	for i in rows.size():
		if rows[i]["_astronaut"] == _selected:
			visible_sel = true
	if not visible_sel:
		_selected = rows[0]["_astronaut"] if not rows.is_empty() else null
	_mark_selected_row()
	_refresh_detail()
	_refresh_crew_editor()
	_refresh_summary()


func _mark_selected_row() -> void:
	for i in _table.rows.size():
		if _table.rows[i].get("_astronaut") == _selected:
			_table.select_index(i)


func _refresh_summary() -> void:
	var s := SimPersonnel.roster_summary(Session.me())
	_summary.text = "Roster %d:  %d active, %d in basic training, %d in advanced training, %d injured, %d retired, %d dead." % [
		s.get("total", 0), s.get("active", 0), s.get("basic_training", 0), s.get("advanced_training", 0),
		s.get("injured", 0), s.get("retired", 0), s.get("dead", 0)]


func _on_row(row: Dictionary) -> void:
	_selected = row["_astronaut"]
	_refresh_detail()


## Why the astronaut cannot move into the programme at `slot`; "" when they can.
func _transfer_reason(a: SimAstronaut, slot: int) -> String:
	if a.program_slot == slot:
		return ""
	if a.status != SimAstronaut.Status.ACTIVE:
		return "%s is %s and cannot transfer." % [a.name.capitalize(), status_title(a).to_lower()]
	if a.program_slot >= 0:
		return "Release %s from the %s program first." % [a.name.capitalize(), program_label(a, Session.me())]
	return ""


func _refresh_detail() -> void:
	var p := Session.me()
	var a := _selected
	_portrait.queue_redraw()
	for c in _program_box.get_children():
		c.queue_free()
	_program_buttons.clear()
	for key in _training_lamps:
		var lamp: Lamp = _training_lamps[key]
		var here: bool = a != null and a.status == SimAstronaut.Status.ADVANCED_TRAINING and a.training_focus == key
		lamp.set_state(Lamp.State.ON if here else Lamp.State.OFF)
	if a == null:
		_banner.text = "NAME: -"
		for key in _ratings:
			_ratings[key].text = "-"
		_tenure.text = ""
		_history.text = ""
		_compat.text = ""
		_act(_unassign, "blocked", "Release from program", "No astronaut selected.")
		return
	_banner.text = "NAME: %s" % a.name.to_upper()
	_ratings["mood"].text = str(a.mood)
	_ratings["mood"].add_theme_color_override("font_color", UiPalette.mood_color(a.mood))
	for key in SimAstronaut.SKILLS:
		_ratings[key].text = str(a.skill(key))
	_tenure.text = "%s.  %d season%s active, %d mission%s flown%s." % [status_title(a), a.seasons_active, "" if a.seasons_active == 1 else "s",
		a.missions_flown, "" if a.missions_flown == 1 else "s", ", decorated hero" if a.hero else ""]
	var programs := SimPersonnel.capsule_programs(p)
	for prog in programs:
		var here: bool = a.program_slot == prog.slot
		var b := Lamp.new(prog.display_name(), Lamp.State.ON if here else Lamp.State.OFF)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var why := _transfer_reason(a, prog.slot)
		if here:
			b.tooltip_text = "%s is in the %s program pool" % [a.name.capitalize(), prog.display_name().capitalize()]
		elif why != "":
			b.tooltip_text = why
		else:
			b.tooltip_text = "Transfer %s to the %s program" % [a.name.capitalize(), prog.display_name().capitalize()]
		b.pressed.connect(_on_assign_slot.bind(prog.slot))
		_program_box.add_child(b)
		_program_buttons[prog.slot] = b
	if programs.is_empty():
		var none := Label.new()
		none.text = "No capsule program open."
		none.theme_type_variation = "Small"
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_program_box.add_child(none)
	if a.program_slot < 0:
		_act(_unassign, "blocked", "Release from program", "%s is not assigned to a program." % a.name.capitalize())
	else:
		_act(_unassign, "caution", "Release from %s" % program_label(a, p), "",
			"Take %s out of the program pool (and any crew)" % a.name.capitalize())
	if a.in_crew():
		var mates := SimPersonnel.crew(p, a.program_slot, a.crew_index)
		var lines := compat_lines(a, mates)
		_compat.text = "\n".join(lines) if not lines.is_empty() else "Flies alone."
	else:
		_compat.text = "Not in a crew."
	var hist := history_lines(a, GameData.missions)
	_history.text = "\n".join(hist) if not hist.is_empty() else "No missions yet."


func _on_assign_slot(slot: int) -> void:
	if _selected == null:
		return
	if _selected.program_slot == slot:
		_refresh_detail()
		return
	var why := _transfer_reason(_selected, slot)
	if why != "":
		ConfirmBox.notice(self, "Cannot transfer", why)
		_refresh_detail()
		return
	if SimPersonnel.assign_to_program(Session.me(), _selected, slot):
		Session.notify_change()
		_refresh()
	else:
		_refresh_detail()


func _on_unassign() -> void:
	if _selected == null or _selected.program_slot < 0:
		return
	SimPersonnel.unassign(Session.me(), _selected)
	Session.notify_change()
	_refresh()


# --- crew editor -------------------------------------------------------------------

func _role_table() -> Dictionary:
	return Session.state().constants().get("crew", {}).get("role_slots_by_crew_size", {})


## The skills each seat flies, from the role-slot table: seat -> Array of skill keys.
static func seat_skills(size: int, table: Dictionary = {}) -> Array:
	var slots: Variant = table.get(str(size), table.get(size, null))
	if slots == null:
		slots = SimPersonnel.ROLE_SLOTS_DEFAULT.get(size, {})
	var out: Array = []
	for seat in size:
		var skills: Array = []
		for key in ROLE_ORDER:
			var s: Variant = slots.get(key, null)
			if s != null and int(s) == seat:
				skills.append(ROLE_SKILLS[key])
		out.append(skills)
	return out


## Lamp state for a seat: dark when empty, green when filled, amber when the occupant has
## no skill in any of the seat's roles.
static func seat_state(a: SimAstronaut, skills: Array) -> int:
	if a == null:
		return Lamp.State.OFF
	var best := 0
	for s in skills:
		best = maxi(best, a.skill(s))
	return Lamp.State.WARN if not skills.is_empty() and best == 0 else Lamp.State.ON


## One seat as a lamp (labelled with the seat) and the occupant's name beside it.
func _seat_row(label: String, a: SimAstronaut, skills: Array, on_click: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var short := label.split(":")[0]
	var lamp := Lamp.new(short, seat_state(a, skills))
	lamp.custom_minimum_size.x = 140
	var roles := label.split(":")[1].strip_edges() if label.contains(":") else "no role"
	if a == null:
		lamp.tooltip_text = "%s (%s): empty" % [short, roles]
	else:
		lamp.tooltip_text = "%s (%s): %s%s" % [short, roles, a.name.capitalize(),
			"\nNo skill in this seat's roles." if lamp.state == Lamp.State.WARN else ""]
	if on_click.is_valid():
		lamp.pressed.connect(on_click)
		if a != null:
			lamp.tooltip_text += "\nClick to release the seat."
	row.add_child(lamp)
	var name := Label.new()
	name.text = a.name.capitalize() if a != null else "empty"
	name.theme_type_variation = "" if a != null else "Dim"
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name.clip_text = true
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(name)
	return row


func _on_crew_program_selected(index: int) -> void:
	_crew_slot = _crew_program_opt.get_item_id(index)
	_picked.clear()
	_refresh_crew_editor()


func _refresh_crew_editor() -> void:
	var p := Session.me()
	var programs := SimPersonnel.capsule_programs(p)
	_crew_program_opt.clear()
	var slot_ok := false
	for prog in programs:
		_crew_program_opt.add_item(prog.display_name().capitalize(), prog.slot)
		if prog.slot == _crew_slot:
			slot_ok = true
	if not slot_ok:
		_crew_slot = programs[0].slot if not programs.is_empty() else -1
		_picked.clear()
	if _crew_slot >= 0:
		_crew_program_opt.select(_crew_program_opt.get_item_index(_crew_slot))
	for c in _crews_box.get_children():
		c.queue_free()
	for c in _pool_box.get_children():
		c.queue_free()
	for c in _seat_box.get_children():
		c.queue_free()
	_pool_checks.clear()
	_crew_index_opt.clear()
	if _crew_slot < 0:
		_crew_capacity.text = "Open a capsule program in Hardware Purchase before forming crews."
		_warning.text = ""
		_act(_set_crew, "blocked", "Set crew", "No capsule program is open. Buy one in Hardware Purchase first.")
		return
	var prog: SimProgram = p.program("manned", _crew_slot)
	var capacity := prog.crew_capacity()
	var table := _role_table()
	var labels := seat_labels(capacity, table)
	var in_use := SimPersonnel.crews_of(p, _crew_slot)
	_crew_capacity.text = "%s carries %d.  Seats: %s." % [prog.display_name().capitalize(), capacity, "; ".join(labels)]

	for idx in in_use:
		_crews_box.add_child(_crew_panel(p, idx, SimPersonnel.crew(p, _crew_slot, idx), labels, capacity, table))
	if in_use.is_empty():
		var none := Label.new()
		none.text = "No crews formed yet."
		none.theme_type_variation = "Small"
		_crews_box.add_child(none)

	# candidates: assigned to this program, active, not in a crew
	var still_picked: Array = []
	for a in _picked:
		if a.program_slot == _crew_slot and a.status == SimAstronaut.Status.ACTIVE and not a.in_crew():
			still_picked.append(a)
	_picked = still_picked
	var candidates := 0
	for a in p.astronauts:
		if a.program_slot != _crew_slot or a.status != SimAstronaut.Status.ACTIVE or a.in_crew():
			continue
		candidates += 1
		var cb := CheckBox.new()
		cb.text = "%s   mood %d" % [a.name.capitalize(), a.mood]
		cb.tooltip_text = "%s: %s.  Tick to take the next free seat." % [a.name.capitalize(), _skills_short(a)]
		cb.clip_text = true
		cb.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cb.set_pressed_no_signal(_picked.has(a))
		cb.toggled.connect(_on_pick.bind(a))
		cb.set_meta("astronaut", a)
		_pool_box.add_child(cb)
		_pool_checks.append(cb)
	if candidates == 0:
		var none := Label.new()
		none.text = "Nobody in this program is free. Transfer someone with the programme lamps above."
		none.theme_type_variation = "Small"
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_pool_box.add_child(none)

	var max_crews := SimPersonnel.max_crews(Session.state())
	var first_free := -1
	for i in max_crews:
		var used := in_use.has(i)
		_crew_index_opt.add_item("Crew %d%s" % [i + 1, "  (replace)" if used else ""], i)
		if first_free < 0 and not used:
			first_free = i
	_crew_index_opt.select(_crew_index_opt.get_item_index(first_free if first_free >= 0 else 0))
	_refresh_pick_state(capacity, table)


func _crew_panel(p: SimPlayer, idx: int, members: Array, labels: PackedStringArray, capacity: int, table: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "Sunken"
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var t := Label.new()
	t.text = "CREW %d" % (idx + 1)
	t.theme_type_variation = "CapsBright"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.clip_text = true
	head.add_child(t)
	var clear := Button.new()
	UiAction.style(clear, "caution", "Clear")
	clear.tooltip_text = "Break up crew %d; its members return to the program pool" % (idx + 1)
	clear.pressed.connect(_on_clear_crew.bind(idx))
	head.add_child(clear)
	var skills := seat_skills(capacity, table)
	for i in members.size():
		var a: SimAstronaut = members[i]
		var seat: String = labels[i] if i < labels.size() else "Seat %d" % (i + 1)
		var row := _seat_row(seat, a, skills[i] if i < skills.size() else [], Callable())
		var name: Label = row.get_child(1)
		name.text = "%s   %s" % [a.name.capitalize(), _skills_short(a)]
		name.tooltip_text = "%s, mood %d" % [a.name.capitalize(), a.mood]
		name.mouse_filter = Control.MOUSE_FILTER_PASS
		v.add_child(row)
	var info := Label.new()
	info.text = crew_summary(members, capacity, Session.state(), table)
	info.theme_type_variation = "Small"
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var conflicts := SimPersonnel.crew_conflicts(members)
	info.add_theme_color_override("font_color", UiPalette.WARN if conflicts > 0 else UiPalette.TEXT_DIM)
	v.add_child(info)
	return panel


static func _skills_short(a: SimAstronaut) -> String:
	var parts: PackedStringArray = []
	for s in SimAstronaut.SKILLS:
		parts.append("%s %d" % [SKILL_SHORT[s], a.skill(s)])
	return " ".join(parts)


func _on_pick(pressed: bool, a: SimAstronaut) -> void:
	if pressed:
		if not _picked.has(a):
			_picked.append(a)
	else:
		_picked.erase(a)
	var prog: SimProgram = Session.me().program("manned", _crew_slot)
	_refresh_pick_state(prog.crew_capacity() if prog != null else 0, _role_table())


func _release_seat(a: SimAstronaut) -> void:
	_picked.erase(a)
	for cb in _pool_checks:
		if cb.get_meta("astronaut") == a:
			cb.set_pressed_no_signal(false)
	var prog: SimProgram = Session.me().program("manned", _crew_slot)
	_refresh_pick_state(prog.crew_capacity() if prog != null else 0, _role_table())


func _refresh_pick_state(capacity: int, table: Dictionary) -> void:
	var full := _picked.size() >= capacity
	for cb in _pool_checks:
		var a: SimAstronaut = cb.get_meta("astronaut")
		cb.disabled = full and not _picked.has(a)
		if cb.disabled:
			cb.tooltip_text = "Every seat is filled. Release a seat to pick someone else."
		else:
			cb.tooltip_text = "%s: %s.  Tick to take the next free seat." % [a.name.capitalize(), _skills_short(a)]
	# Seat lamp column: lit when filled.
	for c in _seat_box.get_children():
		c.queue_free()
	var labels := seat_labels(capacity, table)
	var skills := seat_skills(capacity, table)
	for i in capacity:
		var a: SimAstronaut = _picked[i] if i < _picked.size() else null
		var cb: Callable = _release_seat.bind(a) if a != null else Callable()
		_seat_box.add_child(_seat_row(labels[i] if i < labels.size() else "Seat %d" % (i + 1), a, skills[i] if i < skills.size() else [], cb))
	_warning.text = crew_summary(_picked, capacity, Session.state(), table)
	var conflicts := SimPersonnel.crew_conflicts(_picked)
	_warning.add_theme_color_override("font_color", UiPalette.WARN if conflicts > 0 else UiPalette.TEXT_DIM)
	if capacity == 0:
		_act(_set_crew, "blocked", "Set crew", "This program carries no crew.")
	elif _picked.size() < capacity:
		var need := capacity - _picked.size()
		_act(_set_crew, "blocked", "Set crew", "Pick %d more for the seats. Every seat must be filled." % need)
	else:
		_act(_set_crew, "go", "Set crew", "", "Save the picked seats as the chosen crew")


func _on_set_crew() -> void:
	if _crew_slot < 0 or _crew_index_opt.selected < 0:
		return
	var idx := _crew_index_opt.get_item_id(_crew_index_opt.selected)
	if SimPersonnel.set_crew(Session.me(), _crew_slot, idx, _picked.duplicate(), Session.state()):
		_picked.clear()
		Session.notify_change()
		_refresh()
	else:
		ConfirmBox.notice(self, "Crew not formed", "Every member must be active, assigned to this program and not already in another crew.")


func _on_clear_crew(idx: int) -> void:
	if _crew_slot < 0:
		return
	SimPersonnel.clear_crew(Session.me(), _crew_slot, idx)
	Session.notify_change()
	_refresh()
