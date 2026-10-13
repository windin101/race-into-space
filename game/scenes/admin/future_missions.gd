extends ScreenPanel
## Future Missions office, laid out like the original: launch facility tabs A/B/C, the
## mission list with its filters, and for the selected mission a banner with arrows to
## cycle the list, the mission diagram (its steps as a path of nodes around the Earth and,
## for lunar missions, the Moon), the brief, the hardware the planner would use and the
## penalties, then the plan board (duration, joint launch, rush) with Assign and Clear.
## Rushing itself is set in Mission Control once the mission is scheduled.

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
const FACILITY := ["A", "B", "C"]
const CASE_BG := Color("0a1424")
## Which vehicles carry a crew, by mission crew_mode (as SimPlanner.assemble reads it).
const MANNED_BY_VEHICLE := {2: [true], 3: [false, true], 4: [true, true]}
const MANNED_COLOR := UiPalette.GOLD
const UNMANNED_COLOR := UiPalette.INFO
const EARTH := Color("2b5d9c")
const EARTH_LAND := Color("4f8a4f")
const MOON := Color("a7a9ad")
const MOON_DARK := Color("85878c")
const PLANET := Color("c9824a")

var _pad := 0
var _filters: Dictionary = DEFAULT_FILTERS.duplicate()
var _selected := -1
var _duration := 0

var _pad_buttons: Array = []
var _pad_labels: Array = []
var _filter_buttons: Dictionary = {}
var _table: DataTable
var _banner: Label
var _patch: TextureRect
var _prev: Button
var _next: Button
var _diagram: Control
var _legend: HFlowContainer
var _brief: Label
var _readiness: Label
var _hardware: Label
var _penalties: GridContainer
var _detail_boxes: Array = []
var _duration_buttons: Array = []
var _duration_range: Label
var _joint_value: Label
var _rush_value: Label
var _reason: Label
var _plan: Button
var _cancel: Button

## Diagram of the selected mission: [{letter, vehicle, count, zone, manned}] in flight order.
var _nodes: Array = []
var _target := ""          ## "", "moon" or "planet"


func _init() -> void:
	super()
	title = "Future Missions"


func _ready() -> void:
	super()
	UiHelp.attach(content, "I011")
	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 20)
	content.add_child(split)

	# Left: facility tabs, filters and the mission list.
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 580
	left.add_theme_constant_override("separation", 10)
	split.add_child(left)
	var pads := HBoxContainer.new()
	pads.add_theme_constant_override("separation", 8)
	left.add_child(pads)
	UiHelp.attach(pads, "I010")
	for i in 3:
		var tab := VBoxContainer.new()
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.add_theme_constant_override("separation", 2)
		pads.add_child(tab)
		var b := Button.new()
		b.toggle_mode = true
		b.text = "Facility %s" % FACILITY[i]
		b.custom_minimum_size.y = 110
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.expand_icon = false
		b.add_theme_constant_override("icon_max_width", 72)
		b.pressed.connect(_set_pad.bind(i))
		tab.add_child(b)
		_pad_buttons.append(b)
		var l := Label.new()
		l.theme_type_variation = "Small"
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size.y = 40
		tab.add_child(l)
		_pad_labels.append(l)
	var filters := HFlowContainer.new()
	filters.add_theme_constant_override("h_separation", 6)
	filters.add_theme_constant_override("v_separation", 6)
	left.add_child(filters)
	for f in FILTER_DEFS:
		var cb := Button.new()
		cb.text = f["title"]
		cb.toggle_mode = true
		cb.theme_type_variation = "Flat"
		cb.button_pressed = _filters[f["key"]]
		cb.toggled.connect(_set_filter.bind(f["key"]))
		filters.add_child(cb)
		_filter_buttons[f["key"]] = cb
	_table = DataTable.new()
	_table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_table.set_columns([
		{"key": "index", "title": "#", "numeric": true, "stretch": 0.6},
		{"key": "name", "title": "Mission", "stretch": 4, "color": func(row): return UiPalette.TEXT if row["_ok"] else UiPalette.TEXT_MUTED},
		{"key": "crew", "title": "Crew", "stretch": 1.1, "color": func(row): return MANNED_COLOR if row["crew"] == "Manned" else UiPalette.TEXT_DIM},
		{"key": "duration", "title": "Dur.", "stretch": 0.7},
	])
	_table.row_selected.connect(_on_row)
	left.add_child(_table)

	# Right: banner, diagram and brief, plan board.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	split.add_child(right)
	var banner_panel := PanelContainer.new()
	banner_panel.theme_type_variation = "Sunken"
	right.add_child(banner_panel)
	var banner_row := HBoxContainer.new()
	banner_row.add_theme_constant_override("separation", 12)
	banner_panel.add_child(banner_row)
	_prev = Button.new()
	_prev.text = "◀"
	_prev.custom_minimum_size.x = 56
	_prev.tooltip_text = "Previous mission in the list"
	_prev.pressed.connect(_step.bind(-1))
	banner_row.add_child(_prev)
	_patch = TextureRect.new()
	_patch.custom_minimum_size = Vector2(48, 48)
	_patch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_patch.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	banner_row.add_child(_patch)
	_banner = Label.new()
	_banner.theme_type_variation = "Heading"
	_banner.add_theme_color_override("font_color", UiPalette.GOLD)
	_banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner_row.add_child(_banner)
	_next = Button.new()
	_next.text = "▶"
	_next.custom_minimum_size.x = 56
	_next.tooltip_text = "Next mission in the list"
	_next.pressed.connect(_step.bind(1))
	banner_row.add_child(_next)

	var mid := HBoxContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 16)
	right.add_child(mid)
	var diagram_box := VBoxContainer.new()
	diagram_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diagram_box.add_theme_constant_override("separation", 6)
	mid.add_child(diagram_box)
	var case_panel := PanelContainer.new()
	case_panel.theme_type_variation = "Sunken"
	case_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	diagram_box.add_child(case_panel)
	_diagram = Control.new()
	_diagram.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_diagram.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_diagram.clip_contents = true
	_diagram.draw.connect(_draw_diagram)
	_diagram.resized.connect(_diagram.queue_redraw)
	case_panel.add_child(_diagram)
	_legend = HFlowContainer.new()
	_legend.add_theme_constant_override("h_separation", 14)
	_legend.add_theme_constant_override("v_separation", 0)
	diagram_box.add_child(_legend)

	var info := VBoxContainer.new()
	info.custom_minimum_size.x = 430
	info.add_theme_constant_override("separation", 8)
	mid.add_child(info)
	_brief = Label.new()
	_brief.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_brief.add_theme_color_override("font_color", UiPalette.INFO)
	info.add_child(_brief)
	_readiness = Label.new()
	_readiness.theme_type_variation = "Subheading"
	_readiness.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(_readiness)
	var hw_box := _card(info, "MISSION HARDWARE")
	_hardware = Label.new()
	_hardware.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hardware.theme_type_variation = "Small"
	hw_box.add_child(_hardware)
	var pen_box := _card(info, "SAFETY PENALTIES")
	_penalties = GridContainer.new()
	_penalties.columns = 2
	_penalties.add_theme_constant_override("h_separation", 18)
	_penalties.add_theme_constant_override("v_separation", 2)
	pen_box.add_child(_penalties)

	# Plan board and the Assign / Clear commands.
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 16)
	right.add_child(bottom)
	var board := _card(bottom, "MISSION PLAN")
	board.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 6)
	board.add_child(grid)
	_key(grid, "DURATION:")
	var dur_row := HBoxContainer.new()
	dur_row.add_theme_constant_override("separation", 4)
	grid.add_child(dur_row)
	for level in range(1, DURATION_LETTERS.size() + 1):
		var b := Button.new()
		b.text = DURATION_LETTERS[level - 1]
		b.toggle_mode = true
		b.custom_minimum_size.x = 44
		b.pressed.connect(_set_duration.bind(level))
		dur_row.add_child(b)
		_duration_buttons.append(b)
	_duration_range = Label.new()
	_duration_range.theme_type_variation = "Dim"
	_duration_range.custom_minimum_size.x = 120
	dur_row.add_child(_duration_range)
	_key(grid, "JOINT LAUNCH:")
	_joint_value = Label.new()
	grid.add_child(_joint_value)
	_key(grid, "RUSH:")
	_rush_value = Label.new()
	_rush_value.theme_type_variation = "Dim"
	_rush_value.text = "Set in Mission Control once scheduled"
	grid.add_child(_rush_value)

	var actions := VBoxContainer.new()
	actions.custom_minimum_size.x = 430
	actions.add_theme_constant_override("separation", 8)
	bottom.add_child(actions)
	_reason = Label.new()
	_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reason.theme_type_variation = "Small"
	_reason.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_reason.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	actions.add_child(_reason)
	_plan = Button.new()
	_plan.theme_type_variation = "Accent"
	_plan.pressed.connect(_on_plan)
	actions.add_child(_plan)
	_cancel = Button.new()
	_cancel.theme_type_variation = "Danger"
	_cancel.pressed.connect(_on_cancel)
	actions.add_child(_cancel)
	_detail_boxes = [mid, bottom]
	_refresh()


func setup(_args: Dictionary) -> void:
	_refresh()


func on_resume() -> void:
	_refresh()


## A Card with a gold title; returns the box to fill.
func _card(parent: Control, heading: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "Card"
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	var l := Label.new()
	l.text = heading
	l.theme_type_variation = "Subheading"
	l.add_theme_color_override("font_color", UiPalette.GOLD)
	box.add_child(l)
	return box


func _key(parent: Control, text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = "Dim"
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(l)
	return l


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


func _set_duration(level: int) -> void:
	_duration = level
	_refresh_detail()


## Cycle the selection through the list as shown (the banner arrows).
func _step(delta: int) -> void:
	var rows: Array = _table.rows
	if rows.is_empty():
		return
	var at := -1
	for i in rows.size():
		if int(rows[i]["index"]) == _selected:
			at = i
			break
	var i := posmod(at + delta, rows.size()) if at >= 0 else 0
	_selected = int(rows[i]["index"])
	_duration = int(rows[i]["_m"]["days"])
	_select_in_table()
	_refresh_detail()


func _select_in_table() -> void:
	var found := -1
	for i in _table.rows.size():
		if int(_table.rows[i]["index"]) == _selected:
			found = i
			break
	_table.select_index(found)
	if found >= 0 and found < _table._row_nodes.size():
		_scroll_to(_table._row_nodes[found])


## Bring a list row into view once the freshly built rows have been laid out.
func _scroll_to(row_node: Control) -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if is_instance_valid(row_node) and row_node.is_inside_tree():
		_table._scroll.ensure_control_visible(row_node)


func _refresh() -> void:
	if not Session.has_game() or _table == null:
		return
	var state := Session.state()
	var p := Session.me()
	var missions: Array = GameData.missions
	if not _pad_ok(p, _pad):
		for i in 3:
			if _pad_ok(p, i):
				_pad = i
				break
	for i in 3:
		var b: Button = _pad_buttons[i]
		b.disabled = p.pads[i] == SimPlayer.PAD_NONE
		b.button_pressed = i == _pad
		_pad_labels[i].text = pad_status(p, i, missions)
		b.tooltip_text = "Launch Facility %s: %s" % [FACILITY[i], pad_status(p, i, missions)]
		var layer := "pad_site" if p.pads[i] == SimPlayer.PAD_NONE else ("pad_ok" if p.pads[i] == SimPlayer.PAD_OK else "pad_damaged")
		b.icon = ArtAssets.spaceport_layer(p.side, layer)
	var rows: Array = []
	for mi in filter_missions(missions, _filters):
		var m: Dictionary = missions[mi]
		var dur := int(m["days"]) if m["dur"] == 1 else 0
		rows.append({
			"index": mi, "name": title_case(m["name"]), "crew": "Manned" if is_manned(m) else "Unmanned",
			"duration": duration_text(m), "_m": m,
			"_ok": SimPlanner.can_plan(state, p, mi, _pad, dur)["ok"],
		})
	_table.set_rows(rows)
	var pl = p.future[_pad]
	if _selected < FIRST_PLANNABLE and pl != null and pl.get("part", 1) == 1:
		_selected = int(pl["mission_index"])
		_duration = int(pl.get("duration", 0))
	if _selected < FIRST_PLANNABLE and not rows.is_empty():
		_selected = int(rows[0]["index"])
		_duration = int(rows[0]["_m"]["days"])
	_select_in_table()
	_refresh_detail()


func _refresh_detail() -> void:
	var state := Session.state()
	var p := Session.me()
	var has := _selected >= FIRST_PLANNABLE and _selected <= LAST_PLANNABLE
	for box in _detail_boxes:
		box.visible = has
	_prev.disabled = _table.rows.size() < 2
	_next.disabled = _table.rows.size() < 2
	_cancel.text = "Clear Facility %s" % FACILITY[_pad]
	_cancel.disabled = p.future[_pad] == null
	if not has:
		_banner.text = "NO MISSION SELECTED"
		_patch.texture = null
		_nodes = []
		_diagram.queue_redraw()
		return
	var m: Dictionary = GameData.missions[_selected]
	_banner.text = "%d. %s" % [_selected, str(m["name"]).to_upper()]
	_patch.texture = ArtAssets.patch(p.side, _selected)
	_patch.visible = _patch.texture != null
	var letters: Dictionary = GameData.constants.get("mission_step_letters", {})
	_build_diagram(m, letters)
	_diagram.tooltip_text = "\n".join(step_list(m["code"], m["lunar"] == 1, m["joint"] == 1, letters))

	# Duration board.
	var ranges: Dictionary = GameData.constants.get("duration_levels", {}).get("days_range", {})
	var options := duration_options(m, ranges)
	if m["dur"] == 1:
		if _duration < int(m["days"]):
			_duration = int(m["days"])
	else:
		_duration = int(m["days"])
	for i in _duration_buttons.size():
		var b: Button = _duration_buttons[i]
		var level := i + 1
		var allowed := false
		for o in options:
			if int(o["level"]) == level:
				allowed = true
				b.tooltip_text = o["label"]
		b.disabled = not allowed
		b.button_pressed = level == _duration
	var rng: Variant = ranges.get(DURATION_LETTERS[_duration - 1]) if _duration >= 1 and _duration <= DURATION_LETTERS.size() else null
	_duration_range.text = ("%d-%d days" % [int(rng[0]), int(rng[1])]) if rng is Array and rng.size() == 2 else "none"
	if m["joint"] == 1:
		_joint_value.text = "Yes; Facility %s carries the second vehicle" % FACILITY[mini(_pad + 1, 2)] if _pad < 2 else "Needs the next facility"
	else:
		_joint_value.text = "No"

	# Brief, hardware, penalties, readiness.
	var when := SimPlanner.launch_date(state)
	var when_text := "%s %d" % ["SPRING" if when[1] == SimState.SEASON_SPRING else "FALL", 1900 + when[0]]
	var flags := flags_text(m)
	var lines: PackedStringArray = [
		"CREW: %s" % _crew_text(m),
		"DURATION: %s" % ("NONE" if duration_text(m) == "-" else duration_text(m)),
		"REQUIRES: %s" % ("NOTHING SPECIAL" if flags == "-" else flags.to_upper()),
		"PRESTIGE: %s" % _prestige_text(m),
		"FLIES: %s" % when_text,
	]
	_brief.text = "\n".join(lines)
	var launch := SimPlanner.assemble(state, p, trial_plan(m, _selected, _pad, _duration))
	_hardware.text = "\n".join(hardware_lines(launch))
	_hardware.add_theme_color_override("font_color", UiPalette.TEXT if launch.has("vehicles") else UiPalette.WARN)
	var pen := SimPlanner.requirement_penalty(state, p, _selected, _duration)
	for c in _penalties.get_children():
		c.queue_free()
	for line in penalty_lines(pen):
		var parts: PackedStringArray = str(line).split(": ", true, 1)
		var k := Label.new()
		k.text = parts[0].to_upper() + ":"
		k.theme_type_variation = "Dim"
		_penalties.add_child(k)
		var v := Label.new()
		v.text = parts[1] if parts.size() > 1 else ""
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if parts[0].begins_with("Total"):
			v.add_theme_color_override("font_color", UiPalette.WARN if int(pen["total"]) > 0 else UiPalette.OK)
		_penalties.add_child(v)
	if launch.has("vehicles"):
		var ready := SimPlanner.readiness(launch)
		_readiness.text = "Readiness: %s  (lowest safety %d%%)" % [BAND_TITLES.get(ready["band"], ready["band"]), ready["lowest_safety"]]
		_readiness.add_theme_color_override("font_color", UiPalette.safety_color(int(ready["lowest_safety"])))
	else:
		_readiness.text = "Readiness: unknown until the hardware is in place"
		_readiness.add_theme_color_override("font_color", UiPalette.TEXT_DIM)

	# Assign.
	var check := SimPlanner.can_plan(state, p, _selected, _pad, _duration)
	_plan.disabled = not check["ok"]
	_plan.text = "Assign to Facility %s" % FACILITY[_pad]
	if check["ok"]:
		var notes: PackedStringArray = ["Flies %s %d." % ["Spring" if when[1] == SimState.SEASON_SPRING else "Fall", 1900 + when[0]]]
		var cur = p.future[_pad]
		if cur != null and cur.get("part", 1) == 1 and int(cur["mission_index"]) != _selected:
			notes.append("Replaces %s on this facility." % title_case(GameData.missions[int(cur["mission_index"])]["name"]))
		_reason.text = " ".join(notes)
		_reason.add_theme_color_override("font_color", UiPalette.TEXT_DIM)
	else:
		_reason.text = "Cannot plan: %s." % check["reason"]
		_reason.add_theme_color_override("font_color", UiPalette.WARN)


func _crew_text(m: Dictionary) -> String:
	if not is_manned(m):
		return "UNMANNED"
	var by: Array = MANNED_BY_VEHICLE.get(int(m["crew_mode"]), [true])
	if m["joint"] != 1:
		return "MANNED"
	if by.size() > 1 and by[0] and by[1]:
		return "MANNED, BOTH VEHICLES"
	return "MANNED, VEHICLE %s" % ("B" if by.size() > 1 and by[1] else "A")


func _prestige_text(m: Dictionary) -> String:
	var names: PackedStringArray = []
	for row in m.get("prestige_categories", []):
		var r := int(row)
		if r >= 0 and r < GameData.prestige.size():
			names.append(str(GameData.prestige[r].get("title", "")).to_upper())
	return ", ".join(names) if not names.is_empty() else "NONE"


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


# --- mission diagram -------------------------------------------------------------------

## Turn the mission code into diagram nodes: the main path (as step_list reads it), each
## step placed in a zone (on the ground, in Earth orbit, outbound, at the Moon or planet,
## on the lunar surface, homebound) and marked manned or not by its vehicle.
func _build_diagram(m: Dictionary, letters: Dictionary) -> void:
	_nodes = []
	var code := str(m["code"])
	_target = "planet" if "Z" in code.split("|")[0] else ("moon" if m["lunar"] == 1 or "J" in code.split("|")[0] else "")
	var manned_by: Array = MANNED_BY_VEHICLE.get(int(m["crew_mode"]), [false, false])
	var loc := ["earth", "earth"]
	var landed := [false, false]
	var last_key := ""
	for step in SimMission.parse_code(code, m["lunar"] == 1):
		if step["past_bang"] or step["letter"] == "!" or step["alt_marker"]:
			continue
		var letter := str(step["letter"])
		var v := clampi(int(step["vehicle"]), 0, 1)
		var key := "%s/%d" % [letter, v]
		if int(step["repeat"]) > 1 and key == last_key and not _nodes.is_empty():
			_nodes[_nodes.size() - 1]["count"] += 1
			continue
		last_key = key if int(step["repeat"]) > 0 else ""
		var zone := ""
		match letter:
			"A", "E":
				zone = "ground"
				loc[v] = "earth"
			"J":
				zone = "out"
				loc[v] = "moon"
			"Z":
				zone = "orbit"
				loc[v] = "planet"
			"O", "e":
				zone = "out"
			"K":
				zone = "target"
				loc[v] = "back"
			"N", "f":
				zone = "back" if loc[v] == "back" else "out"
			"g", "D", "G":
				zone = "orbit"
				loc[v] = "earth"
			_:
				match loc[v]:
					"earth": zone = "orbit"
					"back": zone = "back"
					_:
						zone = "target"
						if letter == "S":
							landed[v] = true
						if landed[v] and letter in ["S", "Q", "P", "T", "U"]:
							zone = "surface"
						if letter == "T":
							landed[v] = false
		var manned: bool = is_manned(m) and v < manned_by.size() and manned_by[v]
		_nodes.append({"letter": letter, "vehicle": v, "count": 1, "zone": zone, "manned": manned,
					   "name": step_name(letter, letters)})
	for c in _legend.get_children():
		c.queue_free()
	var seen := {}
	for n in _nodes:
		if seen.has(n["letter"]):
			continue
		seen[n["letter"]] = true
		var l := Label.new()
		l.theme_type_variation = "Small"
		l.text = "%s  %s" % [n["letter"], n["name"]]
		l.add_theme_color_override("font_color", UiPalette.TEXT_DIM)
		_legend.add_child(l)
	_diagram.queue_redraw()


## Node positions for the current size, one per entry of _nodes.
func _layout_nodes(size: Vector2, earth: Vector2, re: float, body: Vector2, rb: float, node_r: float) -> Array:
	var by_zone := {}
	for i in _nodes.size():
		# Launch and recovery share one arc on the surface so the vehicles do not overlap.
		var key := "%s/%d" % [_nodes[i]["zone"], 0 if _nodes[i]["zone"] == "ground" else _nodes[i]["vehicle"]]
		if not by_zone.has(key):
			by_zone[key] = []
		by_zone[key].append(i)
	var out: Array = []
	out.resize(_nodes.size())
	var lane := node_r * 2.3
	for key in by_zone:
		var ids: Array = by_zone[key]
		var zone: String = key.get_slice("/", 0)
		var v := int(key.get_slice("/", 1))
		var n := ids.size()
		for j in n:
			var t := (j + 0.5) / n
			var pos := Vector2.ZERO
			match zone:
				"ground":
					pos = earth + Vector2.from_angle(deg_to_rad(lerpf(215.0, 145.0, t))) * re
				"orbit":
					var r := re + node_r * 2.6 + v * lane
					var a0 := 225.0 if _target != "" else 215.0
					var a1 := 475.0 if _target != "" else 505.0
					pos = earth + Vector2.from_angle(deg_to_rad(lerpf(a0, a1, t))) * r
				"target":
					var r := rb + node_r * 3.0 + v * lane
					pos = body + Vector2.from_angle(deg_to_rad(lerpf(195.0, 505.0, t))) * r
				"surface":
					pos = body + Vector2.from_angle(deg_to_rad(lerpf(205.0, 335.0, t))) * rb
				"out", "back":
					var tt := (j + 1.0) / (n + 1.0)
					var outward := zone == "out"
					var a := earth + Vector2.from_angle(deg_to_rad(-35.0 if outward else 35.0)) * (re + node_r * 2.6)
					var b := body + Vector2.from_angle(deg_to_rad(215.0 if outward else 145.0)) * (rb + node_r * 3.0)
					var ctrl := (a + b) / 2.0 + Vector2(0, (-1.0 if outward else 1.0) * size.y * 0.16)
					pos = a.lerp(ctrl, tt).lerp(ctrl.lerp(b, tt), tt) + Vector2(0, v * lane * (-1.0 if outward else 1.0))
			out[ids[j]] = pos
	return out


func _draw_diagram() -> void:
	var c := _diagram
	var size := c.size
	c.draw_rect(Rect2(Vector2.ZERO, size), CASE_BG)
	var side := Session.human_side if Session.has_game() else "usa"
	for i in range(6, 0, -1):
		c.draw_circle(size / 2.0, minf(size.x, size.y) * 0.08 * i, Color(UiPalette.accent(side), 0.025))
	var font := c.get_theme_default_font()
	if _nodes.is_empty():
		c.draw_string(font, Vector2(0, size.y / 2.0), "No mission selected", HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTheme.SIZE_SUBHEADING, UiPalette.TEXT_MUTED)
		return
	var unit := minf(size.x, size.y)
	var node_r := clampf(unit * 0.032, 10.0, 15.0)
	var earth := Vector2(size.x * 0.24, size.y * 0.56) if _target != "" else Vector2(size.x * 0.5, size.y * 0.52)
	var re := unit * (0.13 if _target != "" else 0.14)
	var body := Vector2(size.x * 0.76, size.y * 0.44)
	var rb := re * (0.85 if _target == "moon" else 0.5)
	var pos := _layout_nodes(size, earth, re, body, rb, node_r)
	# Faint orbit rings, then the path lines (per vehicle, in flight order) behind the bodies.
	var ring := Color(UiPalette.BORDER_SOFT, 0.8)
	c.draw_arc(earth, re + node_r * 2.6, 0, TAU, 96, ring, 1.0, true)
	if _target != "":
		c.draw_arc(body, rb + node_r * 3.0, 0, TAU, 64, ring, 1.0, true)
	for v in 2:
		var last := Vector2.INF
		for i in _nodes.size():
			if _nodes[i]["vehicle"] != v:
				continue
			if last != Vector2.INF:
				var col: Color = MANNED_COLOR if _nodes[i]["manned"] else UNMANNED_COLOR
				c.draw_line(last, pos[i], Color(col, 0.5), 2.0, true)
			last = pos[i]
	# Bodies.
	c.draw_circle(earth, re, EARTH)
	c.draw_circle(earth + Vector2(-re * 0.3, -re * 0.25), re * 0.38, EARTH_LAND)
	c.draw_circle(earth + Vector2(re * 0.35, re * 0.3), re * 0.28, EARTH_LAND)
	c.draw_arc(earth, re, 0, TAU, 64, Color(1, 1, 1, 0.25), 1.5)
	c.draw_string(font, earth + Vector2(-re, re * 0.72), "EARTH", HORIZONTAL_ALIGNMENT_CENTER, re * 2.0, UiTheme.SIZE_SMALL, Color(1, 1, 1, 0.7))
	if _target == "moon":
		c.draw_circle(body, rb, MOON)
		c.draw_circle(body + Vector2(-rb * 0.3, -rb * 0.2), rb * 0.22, MOON_DARK)
		c.draw_circle(body + Vector2(rb * 0.35, rb * 0.3), rb * 0.16, MOON_DARK)
		c.draw_string(font, body + Vector2(-rb, rb * 0.62), "MOON", HORIZONTAL_ALIGNMENT_CENTER, rb * 2.0, UiTheme.SIZE_SMALL, Color(0, 0, 0, 0.6))
	elif _target == "planet":
		c.draw_circle(body, rb, PLANET)
		c.draw_line(body + Vector2(-rb, rb * 0.15), body + Vector2(rb, rb * 0.15), Color(PLANET.darkened(0.3)), 2.0)
		c.draw_string(font, body + Vector2(-rb * 3.0, rb + node_r * 3.0 + 40), "PLANET", HORIZONTAL_ALIGNMENT_CENTER, rb * 6.0, UiTheme.SIZE_SMALL, UiPalette.TEXT_MUTED)
	# Nodes.
	for i in _nodes.size():
		var n: Dictionary = _nodes[i]
		var col: Color = MANNED_COLOR if n["manned"] else UNMANNED_COLOR
		c.draw_circle(pos[i], node_r, CASE_BG)
		c.draw_arc(pos[i], node_r, 0, TAU, 32, col, 2.0, true)
		c.draw_string(font, pos[i] + Vector2(-node_r, UiTheme.SIZE_SMALL * 0.35), n["letter"], HORIZONTAL_ALIGNMENT_CENTER, node_r * 2.0, UiTheme.SIZE_SMALL, col)
		if int(n["count"]) > 1:
			c.draw_string(font, pos[i] + Vector2(node_r * 0.8, node_r * 1.6), "x%d" % n["count"], HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_SMALL - 3, UiPalette.TEXT_DIM)
	# Key.
	var y := 22.0
	for entry in [[MANNED_COLOR, "Manned step"], [UNMANNED_COLOR, "Unmanned step"]]:
		c.draw_circle(Vector2(18, y - 5), 5, entry[0])
		c.draw_string(font, Vector2(30, y), entry[1], HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_SMALL, UiPalette.TEXT_DIM)
		y += 20.0


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
