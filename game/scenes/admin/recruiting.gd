extends ScreenPanel
## Astronaut / Cosmonaut Recruiting, laid out like the Astronaut Complex dossier: the
## selected candidate's name banner, big portrait and the ratings the astronaut
## difficulty level lets you see on the left; the candidate list in the middle as card
## rows with the visible skills as stat chips, sortable (click a row to view, click it
## again or its pick lamp to pick); and on the right the group panel with the pick
## counter, the picks as portrait tiles, the running cost and the Recruit action.

const SKILL_TITLES := {"capsule": "Capsule", "lm": "LM", "eva": "EVA", "docking": "Docking", "endurance": "Endurance"}
const SKILL_SHORT := {"capsule": "Cap", "lm": "LM", "eva": "EVA", "docking": "Dock", "endurance": "End"}
const PICK_MARK := "[x]"
const UNPICK_MARK := "[  ]"
const CASE_BG := Color("0a1424")
const TILE := Vector2(62, 74)
const TILE_W := 84.0
const HELP := "I012"

## The candidate list's sort, remembered for the session: a row key ("" = group order).
static var sort_key := ""
static var sort_desc := true

var _picked: Array = []       ## candidate names in pick order
var _shown := ""              ## candidate name in the dossier
var _pool: Array = []         ## candidate dictionaries on offer
var _quota := 0

var _list: VBoxContainer
var _sort_bar: HBoxContainer
var _info: Label
var _note: Label
# dossier
var _banner: Label
var _portrait: Control
var _ratings: Dictionary = {}  ## key -> value Label
var _pick: Button
var _hidden_note: Label
# group board
var _group_panel: UiPanel
var _picked_title: Label
var _tiles: HFlowContainer
var _picked_list: Label
var _cost_chip: StatChip
var _cash_chip: StatChip
var _recruit: Button
var _clear: Button


func _init() -> void:
	super()
	title = "%s Recruiting" % str(Sides.field(_side(), "people", "astronaut")).capitalize()


func _ready() -> void:
	super()
	UiHelp.attach(content, HELP)
	_info = Label.new()
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.add_theme_color_override("font_color", UiPalette.INFO)
	content.add_child(_info)
	_note = Label.new()
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.add_theme_color_override("font_color", UiPalette.WARN)
	content.add_child(_note)

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 16)
	content.add_child(split)
	split.add_child(_build_dossier())
	split.add_child(_build_list())
	split.add_child(_build_board())
	set_room("room_crew")
	_refresh()


func _build_dossier() -> Control:
	var panel := UiPanel.new("Candidate", HELP)
	panel.size_flags_stretch_ratio = 0.7
	panel.custom_minimum_size.x = 400
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
	var keys: Array = ["sex", "service"]
	keys.append_array(SimAstronaut.SKILLS)
	for key in keys:
		var k := Label.new()
		k.text = {"sex": "SEX", "service": "FROM"}.get(key, SKILL_SHORT.get(key, key).to_upper())
		k.theme_type_variation = "Caps"
		k.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		k.mouse_filter = Control.MOUSE_FILTER_PASS
		k.tooltip_text = {"sex": "Sex", "service": "Civilian or military background"}.get(key, "%s skill" % SKILL_TITLES.get(key, key))
		ratings.add_child(k)
		var v := Label.new()
		v.theme_type_variation = "Subheading"
		v.add_theme_color_override("font_color", UiPalette.GOLD)
		ratings.add_child(v)
		_ratings[key] = v
	_hidden_note = Label.new()
	_hidden_note.theme_type_variation = "Small"
	_hidden_note.add_theme_color_override("font_color", UiPalette.TEXT_DIM)
	_hidden_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hidden_note.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(_hidden_note)
	_pick = panel.add_action("Pick candidate", "go", _on_pick_pressed)
	return panel


func _build_list() -> Control:
	var panel := UiPanel.new("Candidates", HELP)
	panel.size_flags_stretch_ratio = 1.4
	panel.custom_minimum_size.x = 640
	_sort_bar = HBoxContainer.new()
	_sort_bar.add_theme_constant_override("separation", 4)
	panel.body.add_child(_sort_bar)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.body.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)
	return panel


func _build_board() -> Control:
	_group_panel = UiPanel.new("Group selection", HELP)
	_group_panel.size_flags_stretch_ratio = 0.7
	_group_panel.custom_minimum_size.x = 380
	var v := _group_panel.body
	var counter_panel := PanelContainer.new()
	counter_panel.theme_type_variation = "Sunken"
	v.add_child(counter_panel)
	_picked_title = Label.new()
	_picked_title.theme_type_variation = "Heading"
	_picked_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_picked_title.clip_text = true
	counter_panel.add_child(_picked_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(inner)
	_tiles = HFlowContainer.new()
	_tiles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tiles.add_theme_constant_override("h_separation", 2)
	_tiles.add_theme_constant_override("v_separation", 6)
	inner.add_child(_tiles)
	_picked_list = Label.new()
	_picked_list.theme_type_variation = "Small"
	_picked_list.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_picked_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(_picked_list)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 8)
	v.add_child(chips)
	_cost_chip = StatChip.new("cost", "-", "Cost of recruiting this group")
	chips.add_child(_cost_chip)
	_cash_chip = StatChip.new("money", "-", "Cash on hand")
	chips.add_child(_cash_chip)
	_recruit = _group_panel.add_action("Recruit", "go", _on_recruit)
	_clear = _group_panel.add_action("Clear picks", "caution", _on_clear)
	return _group_panel


func setup(_args: Dictionary) -> void:
	_refresh()


func on_resume() -> void:
	_refresh()


# --- drawing -----------------------------------------------------------------------

func _side() -> String:
	return Session.human_side if Session.has_game() else "usa"


func _candidate(name: String) -> Dictionary:
	for c in _pool:
		if c["name"] == name:
			return c
	return {}


func _draw_portrait() -> void:
	var size := _portrait.size
	_portrait.draw_rect(Rect2(Vector2.ZERO, size), CASE_BG)
	var c := _candidate(_shown)
	if c.is_empty():
		_portrait.draw_string(get_theme_default_font(), Vector2(0, size.y / 2.0), "No candidate", HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTheme.SIZE_SUBHEADING, UiPalette.TEXT_MUTED)
		return
	PortraitArt.paint(_portrait, Rect2(Vector2.ZERO, size), str(c["name"]), bool(c.get("female", false)), _side())
	# Pick band along the bottom, as the Astronaut Complex shows status.
	var picked := _picked.has(_shown)
	_portrait.draw_rect(Rect2(0, size.y - 26, size.x, 26), Color(0, 0, 0, 0.55))
	_portrait.draw_string(get_theme_default_font(), Vector2(0, size.y - 8), "PICK %d" % (_picked.find(_shown) + 1) if picked else "CANDIDATE",
		HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTheme.SIZE_SMALL, UiPalette.OK if picked else UiPalette.TEXT_DIM)


func _pick_tile(name: String, index: int) -> Control:
	var c := _candidate(name)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.custom_minimum_size.x = TILE_W
	var b := Button.new()
	b.theme_type_variation = "Flat"
	b.custom_minimum_size = TILE
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.tooltip_text = "Pick %d: %s" % [index + 1, name.capitalize()]
	b.draw.connect(func():
		var r := Rect2(Vector2(2, 2), b.size - Vector2(4, 4))
		PortraitArt.paint(b, r, name, bool(c.get("female", false)), _side())
		b.draw_rect(Rect2(r.position, Vector2(18, 18)), Color(0, 0, 0, 0.6))
		b.draw_string(get_theme_default_font(), r.position + Vector2(0, 14), str(index + 1), HORIZONTAL_ALIGNMENT_CENTER, 18, UiTheme.SIZE_SMALL, UiPalette.GOLD)
		if name == _shown:
			b.draw_rect(Rect2(Vector2(1, 1), b.size - Vector2(2, 2)), UiPalette.GOLD, false, 2.0))
	b.pressed.connect(func(): _show(name))
	v.add_child(b)
	var l := Label.new()
	l.text = name.capitalize()
	l.theme_type_variation = "Small"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.custom_minimum_size.x = TILE_W
	v.add_child(l)
	return v



# --- refresh -----------------------------------------------------------------------

func _refresh() -> void:
	if not Session.has_game():
		return
	var state := Session.state()
	var p := Session.me()
	var pool := SimPersonnel.available_recruits(state, p)
	_pool = pool
	var groups: Array = GameData.roster["sides"][p.side]
	var group: Dictionary = groups[p.recruit_group] if p.recruit_group >= 0 and p.recruit_group < groups.size() else {}
	var quota := int(group.get("number_to_choose", 0))
	_quota = quota
	# Drop picks that are no longer offered.
	var names: Array = []
	for c in pool:
		names.append(c["name"])
	_picked = _picked.filter(func(n): return names.has(n))
	if not names.has(_shown):
		_shown = names[0] if not names.is_empty() else ""

	_refresh_list(pool, p.astronaut_level)

	if p.recruit_delay > 0:
		_info.text = "No candidates are available. Next group available in %d season%s." % [p.recruit_delay, "" if p.recruit_delay == 1 else "s"]
	elif group.is_empty():
		_info.text = "No further recruitment groups are available."
	else:
		_info.text = "Group %d: choose up to %d of these %d candidates for %d MB. Hidden stats stay hidden until the recruits finish basic training." % [
			int(group.get("group", p.recruit_group + 1)), quota, pool.size(), SimPersonnel.recruit_cost(p, state)]
	_note.visible = not pool.is_empty() and SimPersonnel.woman_required(p)
	_note.text = "At least one woman must be in this group's pick."
	_group_panel.set_title("Group %d selection" % int(group.get("group", p.recruit_group + 1)) if not group.is_empty() else "No group open")
	_refresh_dossier(p)
	_refresh_side(p, state, quota, pool.is_empty())


## Sort the candidate rows by `key` ("" keeps the group order). Numbers sort high first
## when `desc`; names and sex alphabetically (reversed when not `desc`).
static func sort_rows(rows: Array, key: String, desc: bool) -> Array:
	var out := rows.duplicate()
	if key == "":
		return out
	out.sort_custom(func(a, b):
		var va: Variant = a.get(key, 0)
		var vb: Variant = b.get(key, 0)
		if typeof(va) == TYPE_STRING:
			return str(va) > str(vb) if desc else str(va) < str(vb)
		return int(va) > int(vb) if desc else int(va) < int(vb))
	return out


func _refresh_list(pool: Array, level: int) -> void:
	var shown := visible_skills(level)
	# Sort bar: one button per sortable column; the active one shows its direction.
	for c in _sort_bar.get_children():
		c.queue_free()
	var sort_label := Label.new()
	sort_label.text = "SORT"
	sort_label.theme_type_variation = "Caps"
	sort_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_sort_bar.add_child(sort_label)
	var keys: Array = ["", "name", "sex"]
	keys.append_array(shown)
	if not shown.has(sort_key) and not ["", "name", "sex"].has(sort_key):
		sort_key = ""
	for key in keys:
		var b := Button.new()
		var t: String = {"": "Group", "name": "Name", "sex": "Sex"}.get(key, SKILL_SHORT.get(key, key))
		if key == sort_key and key != "":
			t += " ▼" if sort_desc else " ▲"
		b.text = t
		b.toggle_mode = true
		b.set_pressed_no_signal(key == sort_key)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.tooltip_text = "Show the candidates in the group's own order" if key == "" else \
			"Sort by %s; click again to reverse" % ({"name": "name", "sex": "sex"}.get(key, SKILL_TITLES.get(key, key).to_lower() + " skill"))
		b.pressed.connect(_on_sort.bind(key))
		_sort_bar.add_child(b)

	for c in _list.get_children():
		c.queue_free()
	var rows := sort_rows(candidate_rows(pool, _picked, level), sort_key, sort_desc)
	for row in rows:
		_list.add_child(_candidate_row(row, shown))
	if rows.is_empty():
		var none := Label.new()
		none.text = "No candidates on offer this season."
		none.theme_type_variation = "Dim"
		_list.add_child(none)


func _on_sort(key: String) -> void:
	if key == sort_key and key != "":
		sort_desc = not sort_desc
	else:
		sort_key = key
		sort_desc = key != "name" and key != "sex"
	_refresh_list(_pool, Session.me().astronaut_level)


## One card row: the pick lamp, the name, sex and a chip per visible skill.
func _candidate_row(row: Dictionary, shown: Array) -> Control:
	var name: String = row["_name"]
	var picked := _picked.has(name)
	var b := Button.new()
	b.toggle_mode = true
	b.set_pressed_no_signal(name == _shown)
	b.custom_minimum_size.y = 46
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.tooltip_text = "Click to view %s; click again to %s" % [name.capitalize(), "remove from the picks" if picked else "pick"]
	b.set_meta("candidate", name)
	b.pressed.connect(_on_row_pressed.bind(name))
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 8
	h.offset_right = -8
	h.add_theme_constant_override("separation", 10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var lamp := Lamp.new("Pick %d" % (_picked.find(name) + 1) if picked else "Pick", Lamp.State.ON if picked else Lamp.State.OFF)
	lamp.custom_minimum_size = Vector2(96, 30)
	lamp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lamp.tooltip_text = "Remove %s from the picks" % name.capitalize() if picked else "Pick %s" % name.capitalize()
	lamp.pressed.connect(func():
		_shown = name
		_toggle_pick(name))
	h.add_child(lamp)
	var n := Label.new()
	n.text = str(row["name"])
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	n.custom_minimum_size.x = 120
	n.clip_text = true
	n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	n.add_theme_color_override("font_color", UiPalette.GOLD if picked else UiPalette.TEXT)
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(n)
	var sex := Label.new()
	sex.text = str(row["sex"])
	sex.tooltip_text = "Female" if row["sex"] == "F" else "Male"
	sex.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sex.mouse_filter = Control.MOUSE_FILTER_PASS
	sex.add_theme_color_override("font_color", UiPalette.INFO if row["sex"] == "F" else UiPalette.TEXT_DIM)
	h.add_child(sex)
	for key in shown:
		var level := int(row.get(key, 0))
		var chip := StatChip.new("", "", "%s skill" % SKILL_TITLES[key])
		chip.set_value("%s %d" % [SKILL_SHORT[key].to_upper(), level], false, UiPalette.OK if level >= 3 else Color(0, 0, 0, 0))
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		chip.mouse_filter = Control.MOUSE_FILTER_PASS
		h.add_child(chip)
	return b


func _mark_shown_row() -> void:
	for b in _list.get_children():
		if b is Button and b.has_meta("candidate"):
			b.set_pressed_no_signal(b.get_meta("candidate") == _shown)


func _refresh_dossier(p: SimPlayer) -> void:
	_portrait.queue_redraw()
	var c := _candidate(_shown)
	if c.is_empty():
		_banner.text = "NAME: -"
		for key in _ratings:
			_ratings[key].text = "-"
		UiAction.style(_pick, "blocked", "Pick candidate", "No candidate selected. Candidates appear when a recruitment group opens.")
		_hidden_note.text = ""
		return
	_banner.text = "NAME: %s" % str(c["name"]).to_upper()
	_ratings["sex"].text = "F" if c.get("female", false) else "M"
	_ratings["service"].text = "CIVILIAN" if int(c.get("service", 0)) == 0 else "MILITARY"
	var shown := visible_skills(p.astronaut_level)
	for key in SimAstronaut.SKILLS:
		var v: Label = _ratings[key]
		if shown.has(key):
			v.text = str(int(c.get(key, 0)))
			v.add_theme_color_override("font_color", UiPalette.GOLD)
		else:
			v.text = "?"
			v.add_theme_color_override("font_color", UiPalette.TEXT_MUTED)
	var picked := _picked.has(_shown)
	if picked:
		UiAction.style(_pick, "caution", "Remove from picks")
		_pick.tooltip_text = "Take %s out of the group" % str(c["name"]).capitalize()
	elif _picked.size() >= _quota:
		UiAction.style(_pick, "blocked", "Pick candidate", "Group full. You may pick at most %d candidates from this group." % _quota)
	else:
		UiAction.style(_pick, "go", "Pick candidate")
		_pick.tooltip_text = "Add %s to the group" % str(c["name"]).capitalize()
	_hidden_note.text = "Click a row to view a candidate, click it again or its lamp to pick. Skills marked ? are hidden at this difficulty until basic training ends." \
		if shown.size() < SimAstronaut.SKILLS.size() else "Click a row to view a candidate, click it again or its lamp to pick."


## Why the group cannot be recruited now; "" when it can.
func recruit_reason(p: SimPlayer, state: SimState, empty: bool) -> String:
	if empty:
		return "No candidates. None are on offer this season."
	if _picked.is_empty():
		return "No picks yet. Click a candidate twice, or its pick lamp, to add them."
	var cost := SimPersonnel.recruit_cost(p, state)
	if p.cash < cost:
		return "Not enough cash. Recruiting costs %d MB and you have %d MB." % [cost, p.cash]
	if SimPersonnel.woman_required(p):
		var any_woman := false
		for c in _pool:
			if _picked.has(c["name"]) and c.get("female", false):
				any_woman = true
		if not any_woman:
			return "Pick at least one woman. " + UiHelp.text_for("I100")
	return ""


func _refresh_side(p: SimPlayer, state: SimState, quota: int, empty: bool) -> void:
	_picked_title.text = "PICKED %d OF %d" % [_picked.size(), quota]
	_picked_title.add_theme_color_override("font_color", UiPalette.OK if quota > 0 and _picked.size() == quota else UiPalette.GOLD)
	for t in _tiles.get_children():
		t.queue_free()
	for i in _picked.size():
		_tiles.add_child(_pick_tile(str(_picked[i]), i))
	_picked_list.visible = _picked.is_empty()
	_picked_list.text = "No candidates on offer this season." if empty else "Click a candidate twice, or its pick lamp, to add them to the group."
	var cost := SimPersonnel.recruit_cost(p, state)
	_cost_chip.set_value("%d MB" % cost, p.cash < cost)
	_cash_chip.set_value("%d MB" % p.cash)
	var why := recruit_reason(p, state, empty)
	UiAction.go_or_blocked(_recruit, "Recruit (%d MB)" % cost, why)
	if why == "":
		_recruit.tooltip_text = "Hire the %d picked candidate%s; they start basic training" % [_picked.size(), "" if _picked.size() == 1 else "s"]
	# Clear picks only shares the bar when there is something to clear.
	_clear.visible = not _picked.is_empty()
	UiAction.style(_clear, "caution", "Clear picks")
	_clear.tooltip_text = "Empty the group and start the picks again"
	_recruit.set_meta("bar_corners", Vector2i(1, 0 if _clear.visible else 1))
	UiAction.apply_corners(_recruit)


func _show(name: String) -> void:
	_shown = name
	_mark_shown_row()
	_refresh_dossier(Session.me())
	for t in _tiles.get_children():
		t.get_child(0).queue_redraw()


## Click a row to view the candidate; click the shown row again to pick or unpick.
func _on_row_pressed(name: String) -> void:
	if name == _shown:
		_toggle_pick(name)
	else:
		_show(name)


func _on_pick_pressed() -> void:
	if _shown != "":
		_toggle_pick(_shown)


func _toggle_pick(name: String) -> void:
	var p := Session.me()
	var groups: Array = GameData.roster["sides"][p.side]
	var quota := int(groups[p.recruit_group].get("number_to_choose", 0)) if p.recruit_group < groups.size() else 0
	if _picked.has(name):
		_picked.erase(name)
	elif _picked.size() < quota:
		_picked.append(name)
	else:
		ConfirmBox.notice(self, "Group full", "You may pick at most %d candidates from this group." % quota)
	_refresh()


func _on_clear() -> void:
	_picked.clear()
	_refresh()


func _on_recruit() -> void:
	var state := Session.state()
	var p := Session.me()
	if SimPersonnel.woman_required(p):
		var any_woman := false
		for c in SimPersonnel.available_recruits(state, p):
			if _picked.has(c["name"]) and c.get("female", false):
				any_woman = true
		if not any_woman:
			ConfirmBox.notice(self, "Recruitment problem", UiHelp.text_for("I100"))
			return
	if SimPersonnel.recruit(state, p, _picked.duplicate()):
		_picked.clear()
		Session.notify_change()
	else:
		ConfirmBox.notice(self, "Recruitment failed", "The candidates could not be recruited. Check your cash and your picks.")
	_refresh()


# --- derived view logic (static, tested in test_admin_screens.gd) ---------------------

## Skills shown before hire at an astronaut difficulty level (constants.json
## difficulty.effects_astronaut_level): Capsule and Endurance always; Docking below
## level 2; LM and EVA only at level 0. Order follows SimAstronaut.SKILLS.
static func visible_skills(astronaut_level: int) -> Array:
	var out: Array = []
	for key in SimAstronaut.SKILLS:
		match key:
			"capsule", "endurance":
				out.append(key)
			"docking":
				if astronaut_level < 2:
					out.append(key)
			"lm", "eva":
				if astronaut_level < 1:
					out.append(key)
	return out


## Table rows for the candidate pool; hidden skills are left out of the row.
static func candidate_rows(pool: Array, picked: Array, astronaut_level: int) -> Array:
	var rows: Array = []
	var shown := visible_skills(astronaut_level)
	for c in pool:
		var row := {
			"pick": PICK_MARK if picked.has(c["name"]) else UNPICK_MARK,
			"name": str(c["name"]).capitalize(),
			"sex": "F" if c.get("female", false) else "M",
			"_name": c["name"],
		}
		for key in shown:
			row[key] = int(c.get(key, 0))
		rows.append(row)
	return rows
