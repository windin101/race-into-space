extends ScreenPanel
## Astronaut Complex: the roster (filterable, sortable), a detail column for the selected
## astronaut (card, mission history, compatibility with crewmates, program assignment)
## and a crew editor that builds, inspects and clears the crews of a capsule program.
## Commands go through SimPersonnel and are followed by Session.notify_change().

const FILTERS := ["all", "active", "training", "injured", "retired", "dead"]
const FILTER_TITLES := {"all": "All", "active": "Active", "training": "Training", "injured": "Injured", "retired": "Retired", "dead": "Dead"}
const SKILL_TITLES := {"capsule": "Capsule", "lm": "LM", "eva": "EVA", "docking": "Docking", "endurance": "Endurance"}
const SKILL_SHORT := {"capsule": "Cap", "lm": "LM", "eva": "EVA", "docking": "Dock", "endurance": "End"}
const ROLE_TITLES := {"cap": "Capsule", "lm": "LM", "eva": "EVA", "dock": "Docking"}
const ROLE_ORDER := ["cap", "lm", "eva", "dock"]
const DEFAULT_HELP := "I020"

var _filter := "all"
var _filter_buttons: Dictionary = {}
var _table: DataTable
var _selected: SimAstronaut

# detail column
var _card: AstronautCard
var _detail_title: Label
var _history: Label
var _compat: Label
var _program_opt: OptionButton
var _assign: Button
var _unassign: Button

# crew editor
var _crew_slot := -1
var _crew_program_opt: OptionButton
var _crew_capacity: Label
var _crews_box: VBoxContainer
var _pool_box: VBoxContainer
var _pool_checks: Array = []          ## CheckBox per candidate
var _picked: Array = []               ## SimAstronaut in seat order
var _crew_index_opt: OptionButton
var _warning: Label
var _set_crew: Button

var _summary: Label


func _init() -> void:
	super()
	title = "Astronaut Complex"


func _ready() -> void:
	super()
	var filters := HBoxContainer.new()
	content.add_child(filters)
	var filter_label := Label.new()
	filter_label.text = "Show"
	filter_label.theme_type_variation = "Dim"
	filters.add_child(filter_label)
	for f in FILTERS:
		var b := Button.new()
		b.text = FILTER_TITLES[f]
		b.toggle_mode = true
		b.pressed.connect(_set_filter.bind(f))
		filters.add_child(b)
		_filter_buttons[f] = b
	var hint := Label.new()
	hint.text = "Click a column heading to sort."
	hint.theme_type_variation = "Small"
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.clip_text = true
	filters.add_child(hint)
	UiHelp.attach(filters, DEFAULT_HELP)

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 16)
	content.add_child(split)

	_table = DataTable.new()
	_table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_table.size_flags_stretch_ratio = 2.2
	var cols: Array = [
		{"key": "name", "title": "Name", "stretch": 1.6},
		{"key": "status", "title": "Status", "stretch": 1.3},
		{"key": "program", "title": "Program", "stretch": 1.3},
		{"key": "crew", "title": "Crew", "stretch": 1.2},
		{"key": "mood", "title": "Mood", "numeric": true, "stretch": 0.7, "color": func(r): return UiPalette.mood_color(int(r["mood"]))},
	]
	for s in SimAstronaut.SKILLS:
		cols.append({"key": s, "title": SKILL_SHORT[s], "numeric": true, "stretch": 0.6})
	cols.append({"key": "missions_flown", "title": "Flts", "numeric": true, "stretch": 0.6})
	cols.append({"key": "hero", "title": "Hero", "stretch": 0.6, "color": UiPalette.GOLD})
	_table.set_columns(cols)
	_table.row_selected.connect(_on_row)
	split.add_child(_table)

	split.add_child(_build_detail_column())
	split.add_child(_build_crew_column())

	_summary = Label.new()
	_summary.theme_type_variation = "Dim"
	_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_summary.clip_text = true
	_summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	footer.add_child(_summary)
	_set_filter(_filter)


func _build_detail_column() -> Control:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = 1.0
	scroll.custom_minimum_size.x = 320
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 8)
	scroll.add_child(side)

	_detail_title = Label.new()
	_detail_title.theme_type_variation = "Subheading"
	_detail_title.text = "Selected astronaut"
	side.add_child(_detail_title)
	_card = AstronautCard.new()
	_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_child(_card)

	side.add_child(_heading("Assignment"))
	var assign_row := HBoxContainer.new()
	side.add_child(assign_row)
	_program_opt = OptionButton.new()
	_program_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_program_opt.clip_text = true
	_program_opt.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	assign_row.add_child(_program_opt)
	_assign = Button.new()
	_assign.text = "Assign"
	_assign.theme_type_variation = "Accent"
	_assign.pressed.connect(_on_assign)
	assign_row.add_child(_assign)
	_unassign = Button.new()
	_unassign.text = "Unassign"
	_unassign.pressed.connect(_on_unassign)
	assign_row.add_child(_unassign)

	side.add_child(_heading("Compatibility with crewmates"))
	_compat = Label.new()
	_compat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_compat.theme_type_variation = "Small"
	side.add_child(_compat)

	side.add_child(_heading("Mission history"))
	_history = Label.new()
	_history.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_history.theme_type_variation = "Small"
	side.add_child(_history)
	return scroll


func _build_crew_column() -> Control:
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.size_flags_stretch_ratio = 1.1
	side.custom_minimum_size.x = 360
	side.add_theme_constant_override("separation", 8)

	var head := HBoxContainer.new()
	side.add_child(head)
	var t := Label.new()
	t.text = "Crew editor"
	t.theme_type_variation = "Subheading"
	head.add_child(t)
	_crew_program_opt = OptionButton.new()
	_crew_program_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_crew_program_opt.clip_text = true
	_crew_program_opt.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_crew_program_opt.item_selected.connect(_on_crew_program_selected)
	head.add_child(_crew_program_opt)
	_crew_capacity = Label.new()
	_crew_capacity.theme_type_variation = "Dim"
	_crew_capacity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_crew_capacity)

	side.add_child(_heading("Crews"))
	var crews_scroll := ScrollContainer.new()
	crews_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	crews_scroll.size_flags_stretch_ratio = 1.2
	crews_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(crews_scroll)
	_crews_box = VBoxContainer.new()
	_crews_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_crews_box.add_theme_constant_override("separation", 6)
	crews_scroll.add_child(_crews_box)

	side.add_child(_heading("Form a crew (pick seats in order; the first pick commands)"))
	var pool_scroll := ScrollContainer.new()
	pool_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pool_scroll.size_flags_stretch_ratio = 1.0
	pool_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(pool_scroll)
	_pool_box = VBoxContainer.new()
	_pool_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pool_scroll.add_child(_pool_box)

	_warning = Label.new()
	_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_warning.theme_type_variation = "Small"
	side.add_child(_warning)

	var actions := HBoxContainer.new()
	side.add_child(actions)
	var as_label := Label.new()
	as_label.text = "Save as"
	as_label.theme_type_variation = "Dim"
	actions.add_child(as_label)
	_crew_index_opt = OptionButton.new()
	_crew_index_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_crew_index_opt.clip_text = true
	actions.add_child(_crew_index_opt)
	_set_crew = Button.new()
	_set_crew.text = "Set crew"
	_set_crew.theme_type_variation = "Accent"
	_set_crew.pressed.connect(_on_set_crew)
	actions.add_child(_set_crew)
	return side


func _heading(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = "Dim"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


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
	for r in rows:
		if r["_astronaut"] == _selected:
			visible_sel = true
	if not visible_sel:
		_selected = rows[0]["_astronaut"] if not rows.is_empty() else null
	_refresh_detail()
	_refresh_crew_editor()
	_refresh_summary()


func _refresh_summary() -> void:
	var s := SimPersonnel.roster_summary(Session.me())
	_summary.text = "Roster %d:  %d active, %d in basic training, %d in advanced training, %d injured, %d retired, %d dead" % [
		s.get("total", 0), s.get("active", 0), s.get("basic_training", 0), s.get("advanced_training", 0),
		s.get("injured", 0), s.get("retired", 0), s.get("dead", 0)]


func _on_row(row: Dictionary) -> void:
	_selected = row["_astronaut"]
	_refresh_detail()


func _refresh_detail() -> void:
	var p := Session.me()
	var a := _selected
	_card.visible = a != null
	_program_opt.clear()
	if a == null:
		_detail_title.text = "No astronaut selected"
		_history.text = ""
		_compat.text = ""
		_assign.disabled = true
		_unassign.disabled = true
		return
	_detail_title.text = a.name.capitalize()
	_card.set_astronaut(a)
	var programs := SimPersonnel.capsule_programs(p)
	for prog in programs:
		_program_opt.add_item(prog.display_name().capitalize(), prog.slot)
	if a.program_slot >= 0:
		var i := _program_opt.get_item_index(a.program_slot)
		if i >= 0:
			_program_opt.select(i)
	_assign.disabled = programs.is_empty() or a.status != SimAstronaut.Status.ACTIVE or a.program_slot >= 0
	_unassign.disabled = a.program_slot < 0
	if a.in_crew():
		var mates := SimPersonnel.crew(p, a.program_slot, a.crew_index)
		var lines := compat_lines(a, mates)
		_compat.text = "\n".join(lines) if not lines.is_empty() else "Flies alone."
	else:
		_compat.text = "Not in a crew."
	var hist := history_lines(a, GameData.missions)
	_history.text = "\n".join(hist) if not hist.is_empty() else "No missions yet."


func _on_assign() -> void:
	if _selected == null or _program_opt.selected < 0:
		return
	var slot := _program_opt.get_item_id(_program_opt.selected)
	if SimPersonnel.assign_to_program(Session.me(), _selected, slot):
		Session.notify_change()
		_refresh()


func _on_unassign() -> void:
	if _selected == null or _selected.program_slot < 0:
		return
	SimPersonnel.unassign(Session.me(), _selected)
	Session.notify_change()
	_refresh()


# --- crew editor -------------------------------------------------------------------

func _role_table() -> Dictionary:
	return Session.state().constants().get("crew", {}).get("role_slots_by_crew_size", {})


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
	_pool_checks.clear()
	_crew_index_opt.clear()
	if _crew_slot < 0:
		_crew_capacity.text = "Open a capsule program in Hardware Purchase before forming crews."
		_warning.text = ""
		_set_crew.disabled = true
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
		cb.text = "%s   (%s)   mood %d" % [a.name.capitalize(), _skills_short(a), a.mood]
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
		none.text = "Nobody is assigned and free. Use Assign in the detail column."
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
	panel.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var t := Label.new()
	t.text = "Crew %d" % (idx + 1)
	t.theme_type_variation = "Subheading"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.clip_text = true
	head.add_child(t)
	var clear := Button.new()
	clear.text = "Clear"
	clear.theme_type_variation = "Danger"
	clear.pressed.connect(_on_clear_crew.bind(idx))
	head.add_child(clear)
	for i in members.size():
		var a: SimAstronaut = members[i]
		var l := Label.new()
		var seat: String = labels[i] if i < labels.size() else "Seat %d" % (i + 1)
		l.text = "%s - %s" % [seat, a.name.capitalize()]
		l.clip_text = true
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(l)
		var sk := Label.new()
		sk.text = "    %s   mood %d" % [_skills_short(a), a.mood]
		sk.theme_type_variation = "Small"
		sk.clip_text = true
		sk.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		sk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(sk)
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


func _refresh_pick_state(capacity: int, table: Dictionary) -> void:
	var full := _picked.size() >= capacity
	for cb in _pool_checks:
		var a: SimAstronaut = cb.get_meta("astronaut")
		cb.disabled = full and not _picked.has(a)
	var text := crew_summary(_picked, capacity, Session.state(), table)
	if not _picked.is_empty():
		var labels := seat_labels(capacity, table)
		var seats: PackedStringArray = []
		for i in _picked.size():
			seats.append("%s %s" % [labels[i].split(":")[0] if i < labels.size() else "Seat %d" % (i + 1), _picked[i].name.capitalize()])
		text = "%s\n%s" % ["; ".join(seats), text]
	_warning.text = text
	var conflicts := SimPersonnel.crew_conflicts(_picked)
	_warning.add_theme_color_override("font_color", UiPalette.WARN if conflicts > 0 else UiPalette.TEXT_DIM)
	_set_crew.disabled = _picked.size() != capacity or capacity == 0


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
