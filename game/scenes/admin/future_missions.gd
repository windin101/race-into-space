extends ScreenPanel
## Future Missions office: pick a pad and a mission for next season. The left side lists
## every plannable mission with filters; the right side explains the selected one (steps,
## the hardware the planner would use, penalties and the readiness band) and plans or
## cancels it. Rushing is set in Mission Control, not here.

const FIRST_PLANNABLE := 1
const LAST_PLANNABLE := SimPlanner.RESCUE_FIRST - 1
const MANNED_CREW_MODES := [2, 3, 4]
const DURATION_LETTERS := ["A", "B", "C", "D", "E", "F"]
const FILTER_DEFS := [
	{"key": "manned", "title": "Manned"}, {"key": "unmanned", "title": "Unmanned"},
	{"key": "lunar", "title": "Lunar"}, {"key": "docking", "title": "Docking"},
	{"key": "eva", "title": "EVA"}, {"key": "joint", "title": "Joint"},
]
## Manned/unmanned are inclusive categories; the rest are "only missions with this".
const DEFAULT_FILTERS := {"manned": true, "unmanned": true, "lunar": false, "docking": false, "eva": false, "joint": false}
const BAND_TITLES := {"a-ok": "A-OK", "caution": "Caution", "danger": "Danger"}
const KEEP_UPPER := ["JT", "LM", "LEM", "EVA", "L.L.", "U."]

var _pad := 0
var _filters: Dictionary = DEFAULT_FILTERS.duplicate()
var _selected := -1
var _duration := 0

var _pad_buttons: Array = []
var _pad_labels: Array = []
var _filter_buttons: Dictionary = {}
var _table: DataTable
var _name: Label
var _meta: Label
var _steps: Label
var _hardware: Label
var _penalties: Label
var _readiness: Label
var _joint_note: Label
var _duration_row: HBoxContainer
var _duration_pick: OptionButton
var _reason: Label
var _plan: Button
var _cancel: Button


func _init() -> void:
	super()
	title = "Future Missions"


func _ready() -> void:
	super()
	UiHelp.attach(content, "I011")

	# Pad selector.
	var pads := HBoxContainer.new()
	pads.add_theme_constant_override("separation", 16)
	content.add_child(pads)
	UiHelp.attach(pads, "I010")
	var pad_title := Label.new()
	pad_title.text = "Launch pad for next season:"
	pad_title.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	pads.add_child(pad_title)
	for i in 3:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 2)
		var b := Button.new()
		b.text = "Pad %d" % (i + 1)
		b.toggle_mode = true
		b.custom_minimum_size.x = 160
		b.pressed.connect(_set_pad.bind(i))
		box.add_child(b)
		var l := Label.new()
		l.theme_type_variation = "Small"
		l.custom_minimum_size.x = 160
		l.clip_text = true
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(l)
		pads.add_child(box)
		_pad_buttons.append(b)
		_pad_labels.append(l)

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 16)
	content.add_child(split)

	# Left: filters and the mission table.
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 3.0
	split.add_child(left)
	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 8)
	left.add_child(filters)
	var filter_title := Label.new()
	filter_title.theme_type_variation = "Dim"
	filter_title.text = "Show:"
	filters.add_child(filter_title)
	for f in FILTER_DEFS:
		var cb := CheckButton.new()
		cb.text = f["title"]
		cb.button_pressed = _filters[f["key"]]
		cb.toggled.connect(_set_filter.bind(f["key"]))
		filters.add_child(cb)
		_filter_buttons[f["key"]] = cb
	_table = DataTable.new()
	_table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_table.set_columns([
		{"key": "index", "title": "#", "numeric": true, "stretch": 0.5},
		{"key": "name", "title": "Mission", "stretch": 4},
		{"key": "crew", "title": "Crew", "stretch": 1.2},
		{"key": "duration", "title": "Duration", "stretch": 1.0},
		{"key": "flags", "title": "Involves", "stretch": 2.2},
	])
	_table.row_selected.connect(_on_row)
	left.add_child(_table)

	# Right: detail and plan controls.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 2.0
	right.custom_minimum_size.x = 400
	split.add_child(right)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 6)
	scroll.add_child(detail)
	_name = _para(detail, "Subheading")
	_meta = _para(detail, "Dim")
	_heading(detail, "Mission steps")
	_steps = _para(detail)
	_heading(detail, "Hardware the planner would use")
	_hardware = _para(detail)
	_heading(detail, "Safety penalties")
	_penalties = _para(detail)
	_readiness = _para(detail, "Subheading")
	_joint_note = _para(detail, "Small")

	_duration_row = HBoxContainer.new()
	_duration_row.add_theme_constant_override("separation", 10)
	right.add_child(_duration_row)
	var dl := Label.new()
	dl.text = "Duration:"
	_duration_row.add_child(dl)
	_duration_pick = OptionButton.new()
	_duration_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_duration_pick.item_selected.connect(_on_duration)
	_duration_row.add_child(_duration_pick)
	_reason = _para(right, "Small")
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	right.add_child(buttons)
	_plan = Button.new()
	_plan.theme_type_variation = "Accent"
	_plan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_plan.pressed.connect(_on_plan)
	buttons.add_child(_plan)
	_cancel = Button.new()
	_cancel.theme_type_variation = "Danger"
	_cancel.text = "Cancel plan"
	_cancel.pressed.connect(_on_cancel)
	buttons.add_child(_cancel)
	_refresh()


func setup(_args: Dictionary) -> void:
	_refresh()


func on_resume() -> void:
	_refresh()


func _para(parent: Control, variation := "") -> Label:
	var l := Label.new()
	if variation != "":
		l.theme_type_variation = variation
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(l)
	return l


func _heading(parent: Control, text: String) -> void:
	var l := _para(parent, "Dim")
	l.text = text.to_upper()


# --- state -----------------------------------------------------------------------------

func _set_pad(i: int) -> void:
	_pad = i
	var p := Session.me()
	var pl = p.future[i]
	if pl != null and pl.get("part", 1) == 1:
		_selected = int(pl["mission_index"])
		_duration = int(pl.get("duration", 0))
	_refresh()


func _set_filter(on: bool, key: String) -> void:
	_filters[key] = on
	_refresh()


func _on_row(row: Dictionary) -> void:
	if _selected != int(row["index"]):
		_selected = int(row["index"])
		_duration = int(row["_m"]["days"])
	_refresh_detail()


func _on_duration(i: int) -> void:
	_duration = _duration_pick.get_item_id(i)
	_refresh_detail()


func _refresh() -> void:
	if not Session.has_game():
		return
	var p := Session.me()
	var missions: Array = GameData.missions
	if not _pad_ok(p, _pad):
		for i in 3:
			if _pad_ok(p, i):
				_pad = i
				break
	for i in 3:
		_pad_buttons[i].disabled = p.pads[i] == SimPlayer.PAD_NONE
		_pad_buttons[i].button_pressed = i == _pad
		_pad_labels[i].text = pad_status(p, i, missions)
		_pad_labels[i].tooltip_text = _pad_labels[i].text
	var rows: Array = []
	for mi in filter_missions(missions, _filters):
		var m: Dictionary = missions[mi]
		rows.append({
			"index": mi, "name": title_case(m["name"]), "crew": "Crew" if is_manned(m) else "Unmanned",
			"duration": duration_text(m), "flags": flags_text(m), "_m": m,
		})
	_table.set_rows(rows)
	var pl = p.future[_pad]
	if _selected < FIRST_PLANNABLE and pl != null and pl.get("part", 1) == 1:
		_selected = int(pl["mission_index"])
		_duration = int(pl.get("duration", 0))
	if _selected < FIRST_PLANNABLE and not rows.is_empty():
		_selected = int(rows[0]["index"])
		_duration = int(rows[0]["_m"]["days"])
	for i in _table.rows.size():
		if int(_table.rows[i]["index"]) == _selected:
			_table._on_row_pressed(i)
			break
	_refresh_detail()


func _refresh_detail() -> void:
	var state := Session.state()
	var p := Session.me()
	var has := _selected >= FIRST_PLANNABLE and _selected <= LAST_PLANNABLE
	for l in [_name, _meta, _steps, _hardware, _penalties, _readiness, _joint_note, _reason]:
		l.visible = has
	_duration_row.visible = false
	_plan.visible = has
	_cancel.visible = p.future[_pad] != null
	if not has:
		return
	var m: Dictionary = GameData.missions[_selected]
	_name.text = "%d. %s" % [_selected, title_case(m["name"])]
	_meta.text = meta_text(m)
	_steps.text = "\n".join(step_list(m["code"], m["lunar"] == 1, m["joint"] == 1, GameData.constants.get("mission_step_letters", {})))

	if m["dur"] == 1:
		_duration_row.visible = true
		var options := duration_options(m, GameData.constants.get("duration_levels", {}).get("days_range", {}))
		if _duration < int(m["days"]):
			_duration = int(m["days"])
		_duration_pick.clear()
		for i in options.size():
			_duration_pick.add_item(options[i]["label"], options[i]["level"])
			if options[i]["level"] == _duration:
				_duration_pick.select(i)
	else:
		_duration = int(m["days"])

	var launch := SimPlanner.assemble(state, p, trial_plan(m, _selected, _pad, _duration))
	_hardware.text = "\n".join(hardware_lines(launch))
	var pen := SimPlanner.requirement_penalty(state, p, _selected, _duration)
	_penalties.text = "\n".join(penalty_lines(pen))
	if launch.has("vehicles"):
		var ready := SimPlanner.readiness(launch)
		_readiness.text = "Readiness: %s  (lowest safety %d%%)" % [BAND_TITLES.get(ready["band"], ready["band"]), ready["lowest_safety"]]
		_readiness.add_theme_color_override("font_color", UiPalette.safety_color(int(ready["lowest_safety"])))
	else:
		_readiness.text = "Readiness: unknown until the hardware is in place"
		_readiness.add_theme_color_override("font_color", UiPalette.TEXT_DIM)
	_joint_note.visible = m["joint"] == 1
	_joint_note.text = "Joint mission: pad %d is reserved for the second launch." % (_pad + 2)

	var check := SimPlanner.can_plan(state, p, _selected, _pad, _duration)
	_plan.disabled = not check["ok"]
	_plan.text = "Plan on pad %d" % (_pad + 1)
	if check["ok"]:
		var when := SimPlanner.launch_date(state)
		_reason.text = "Flies %s %d." % ["Spring" if when[1] == SimState.SEASON_SPRING else "Fall", 1900 + when[0]]
		_reason.add_theme_color_override("font_color", UiPalette.TEXT_DIM)
	else:
		_reason.text = "Cannot plan: %s." % check["reason"]
		_reason.add_theme_color_override("font_color", UiPalette.WARN)


func _on_plan() -> void:
	var state := Session.state()
	var p := Session.me()
	var check := SimPlanner.can_plan(state, p, _selected, _pad, _duration)
	if not check["ok"]:
		ConfirmBox.notice(self, "Cannot plan this mission", check["reason"].capitalize() + ".")
		return
	if SimPlanner.plan(state, p, _selected, _pad, _duration):
		Session.notify_change()
	_refresh()


func _on_cancel() -> void:
	SimPlanner.cancel_plan(Session.me(), _pad)
	Session.notify_change()
	_refresh()


static func _pad_ok(p: SimPlayer, i: int) -> bool:
	return p.pads[i] != SimPlayer.PAD_NONE


# --- derived view logic (static, tested in test_admin_screens.gd) ---------------------

static func is_manned(m: Dictionary) -> bool:
	return int(m["crew_mode"]) in MANNED_CREW_MODES


## Plannable mission indices that pass the filters, in index order.
static func filter_missions(missions: Array, filters: Dictionary) -> Array:
	var out: Array = []
	for mi in range(FIRST_PLANNABLE, mini(LAST_PLANNABLE, missions.size() - 1) + 1):
		var m: Dictionary = missions[mi]
		var manned := is_manned(m)
		if manned and not filters.get("manned", true):
			continue
		if not manned and not filters.get("unmanned", true):
			continue
		var skip := false
		for key in ["lunar", "docking", "eva", "joint"]:
			if filters.get(key, false) and int(m[key]) != 1:
				skip = true
		if skip:
			continue
		out.append(mi)
	return out


## "ABBR   Crew   Duration B+   Docking, EVA" with empty parts left out.
static func meta_text(m: Dictionary) -> String:
	var parts: PackedStringArray = [str(m["abbr"]), "Crew" if is_manned(m) else "Unmanned"]
	if int(m["days"]) > 0:
		parts.append("Duration " + duration_text(m))
	if flags_text(m) != "-":
		parts.append(flags_text(m))
	return "   ".join(parts)


static func flags_text(m: Dictionary) -> String:
	var parts: PackedStringArray = []
	if m["docking"] == 1:
		parts.append("Docking")
	if m["eva"] == 1:
		parts.append("EVA")
	if m["lm"] == 1:
		parts.append("LM")
	if m["joint"] == 1:
		parts.append("Joint")
	if m["lunar"] == 1:
		parts.append("Lunar")
	return ", ".join(parts) if not parts.is_empty() else "-"


## "B" for a fixed level, "B+" when the player may choose any level from B up, "-" if none.
static func duration_text(m: Dictionary) -> String:
	var days := int(m["days"])
	if days <= 0:
		return "-"
	var letter: String = DURATION_LETTERS[clampi(days, 1, DURATION_LETTERS.size()) - 1]
	return letter + "+" if m["dur"] == 1 else letter


## Duration levels the player may pick for a dur==1 mission: every level >= days.
static func duration_options(m: Dictionary, days_range: Dictionary) -> Array:
	var out: Array = []
	if m["dur"] != 1:
		return out
	for level in range(maxi(1, int(m["days"])), DURATION_LETTERS.size() + 1):
		var letter: String = DURATION_LETTERS[level - 1]
		var label := letter
		var rng: Variant = days_range.get(letter)
		if rng is Array and rng.size() == 2:
			label = "%s  (%d-%d days)" % [letter, int(rng[0]), int(rng[1])]
		out.append({"level": level, "label": label})
	return out


## Readable main-path step list from a mission code: one line per step, numbered,
## consecutive repeated coast steps collapsed, joint vehicles prefixed.
static func step_list(code: String, lunar: bool, joint: bool, names: Dictionary) -> Array:
	var out: Array = []
	var counts: Array = []
	var last_key := ""
	for step in SimMission.parse_code(code, lunar):
		if step["past_bang"] or step["letter"] == "!" or step["alt_marker"]:
			continue
		var key := "%s/%d" % [step["letter"], step["vehicle"]]
		if int(step["repeat"]) > 1 and key == last_key:
			counts[counts.size() - 1] += 1
			continue
		var name := step_name(str(step["letter"]), names)
		if joint:
			name = "Pad %s: %s" % ["A" if int(step["vehicle"]) == 0 else "B", name]
		out.append(name)
		counts.append(1)
		last_key = key if int(step["repeat"]) > 0 else ""
	var lines: Array = []
	for i in out.size():
		var text: String = out[i]
		if counts[i] > 1:
			text += "  x%d" % counts[i]
		lines.append("%d. %s" % [i + 1, text])
	return lines


static func step_name(letter: String, names: Dictionary) -> String:
	var rec: Variant = names.get(letter)
	if rec is Dictionary and rec.has("name"):
		return title_case(str(rec["name"]))
	return title_case(SimMission.step_name(letter))


## Upper-case data names to title case, keeping the game's abbreviations.
static func title_case(s: String) -> String:
	var words: PackedStringArray = []
	for word in s.split(" ", false):
		if word in KEEP_UPPER:
			words.append(word)
			continue
		var lower := word.to_lower()
		for i in lower.length():
			var ch := lower[i]
			if ch.to_upper() != ch:
				lower = lower.substr(0, i) + ch.to_upper() + lower.substr(i + 1)
				break
		words.append(lower)
	return " ".join(words)


## The plan dictionary SimPlanner.assemble expects, for a mission not yet planned.
static func trial_plan(m: Dictionary, mission_index: int, pad: int, duration: int) -> Dictionary:
	return {
		"mission_index": mission_index, "pad": pad,
		"duration": duration if m["dur"] == 1 else int(m["days"]),
		"joint": m["joint"] == 1, "part": 1, "rush_months": 0, "crew_choice": [0, 0],
	}


## One line per vehicle part, or the reason assembly failed.
static func hardware_lines(launch: Dictionary) -> Array:
	if not launch.has("vehicles"):
		return ["Cannot assemble: %s." % launch.get("reason", "unknown")]
	var lines: Array = []
	var vehicles: Array = launch["vehicles"]
	for v in vehicles.size():
		var veh: Dictionary = vehicles[v]
		var prefix := "" if vehicles.size() == 1 else "Pad %s: " % ["A" if v == 0 else "B"]
		var rocket: SimProgram = veh["rocket"]
		var rocket_text := "%s%s (%d%%)" % [prefix, rocket.display_name().capitalize(), rocket.safety]
		if veh["boosters"] != null:
			rocket_text += " + %s (%d%%)" % [veh["boosters"].display_name().capitalize(), veh["boosters"].safety]
		lines.append(rocket_text)
		for key in ["capsule", "lm", "kicker", "probe", "docking", "eva", "photo"]:
			var prog: SimProgram = veh["payload"][key]
			if prog != null:
				lines.append("%s    %s (%d%%)" % [prefix, prog.display_name().capitalize(), prog.safety])
		var crew: Array = veh["crew"]
		if not crew.is_empty():
			var names: PackedStringArray = []
			for a in crew:
				names.append(a.name.capitalize())
			lines.append("%s    Crew: %s" % [prefix, ", ".join(names)])
	return lines


## The requirement_penalty breakdown as readable lines.
static func penalty_lines(pen: Dictionary) -> Array:
	var lines: Array = []
	lines.append("Milestones skipped: %d  (-%d%%)" % [int(pen["skipped_milestones"]), int(pen["milestone"])])
	lines.append("Duration steps short: -%d%%" % int(pen["duration"]))
	lines.append("New mission type: -%d%%" % int(pen["new_mission"]))
	lines.append("Total on every step: -%d%%" % int(pen["total"]))
	if int(pen["lm"]) > 0:
		lines.append("Missing LM test points: -%d%% on the lunar module" % int(pen["lm"]))
	return lines


## What a pad is doing next season, for the selector.
static func pad_status(p: SimPlayer, i: int, missions: Array) -> String:
	if p.pads[i] == SimPlayer.PAD_NONE:
		return "not built"
	if p.pads[i] > 0:
		return "damaged"
	var pl = p.future[i]
	if pl == null:
		return "no plan"
	if pl.get("part", 1) == 2:
		return "joint from pad %d" % (int(pl["primary_pad"]) + 1)
	var m: Dictionary = missions[int(pl["mission_index"])]
	return title_case(m["abbr"])
