extends ScreenPanel
## Astronaut / Cosmonaut Recruiting, laid out like the Astronaut Complex dossier: the
## selected candidate's name banner, big portrait and the ratings the astronaut
## difficulty level lets you see on the left; the candidate list in the middle (click a
## row to view, click it again to pick); and on the right the group board with the pick
## counter, the picks as portrait tiles, the running cost and the Recruit command.

const SKILL_TITLES := {"capsule": "Capsule", "lm": "LM", "eva": "EVA", "docking": "Docking", "endurance": "Endurance"}
const SKILL_SHORT := {"capsule": "Cap", "lm": "LM", "eva": "EVA", "docking": "Dock", "endurance": "End"}
const SIDE_TITLES := {"usa": "Astronaut Recruiting", "ussr": "Cosmonaut Recruiting"}
const PICK_MARK := "[x]"
const UNPICK_MARK := "[  ]"
const CASE_BG := Color("0a1424")
const TILE := Vector2(62, 74)
const TILE_W := 84.0

var _picked: Array = []       ## candidate names in pick order
var _shown := ""              ## candidate name in the dossier
var _pool: Array = []         ## candidate dictionaries on offer
var _quota := 0

var _table: DataTable
var _info: Label
var _note: Label
# dossier
var _banner: Label
var _portrait: Control
var _ratings: Dictionary = {}  ## key -> value Label
var _pick: Button
var _hidden_note: Label
# group board
var _group_title: Label
var _picked_title: Label
var _tiles: HFlowContainer
var _picked_list: Label
var _cost: Label
var _recruit: Button
var _clear: Button


func _init() -> void:
	super()
	title = SIDE_TITLES.get(Session.human_side if Session.has_game() else "usa", SIDE_TITLES["usa"])


func _ready() -> void:
	super()
	UiHelp.attach(content, "I012")
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
	_table = DataTable.new()
	_table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_table.size_flags_stretch_ratio = 1.2
	_table.custom_minimum_size.x = 440
	_table.row_selected.connect(_on_row)
	_table.row_activated.connect(_on_row_activated)
	split.add_child(_table)
	split.add_child(_build_board())
	_refresh()


func _build_dossier() -> Control:
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.size_flags_stretch_ratio = 0.9
	side.custom_minimum_size.x = 440
	side.add_theme_constant_override("separation", 8)
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
	_portrait.custom_minimum_size = Vector2(210, 250)
	_portrait.draw.connect(_draw_portrait)
	frame.add_child(_portrait)
	var ratings := GridContainer.new()
	ratings.columns = 2
	ratings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ratings.add_theme_constant_override("h_separation", 14)
	ratings.add_theme_constant_override("v_separation", 6)
	body.add_child(ratings)
	var keys: Array = ["sex", "service"]
	keys.append_array(SimAstronaut.SKILLS)
	for key in keys:
		var k := Label.new()
		k.text = {"sex": "SEX:", "service": "FROM:"}.get(key, SKILL_SHORT.get(key, key).to_upper() + ":")
		k.theme_type_variation = "Dim"
		ratings.add_child(k)
		var v := Label.new()
		v.theme_type_variation = "Subheading"
		v.add_theme_color_override("font_color", UiPalette.GOLD)
		ratings.add_child(v)
		_ratings[key] = v
	_pick = Button.new()
	_pick.toggle_mode = true
	_pick.pressed.connect(_on_pick_pressed)
	side.add_child(_pick)
	_hidden_note = Label.new()
	_hidden_note.theme_type_variation = "Small"
	_hidden_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_hidden_note)
	return side


func _build_board() -> Control:
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.custom_minimum_size.x = 380
	side.add_theme_constant_override("separation", 8)
	var board := PanelContainer.new()
	board.theme_type_variation = "Card"
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(board)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	board.add_child(v)
	_group_title = Label.new()
	_group_title.theme_type_variation = "Subheading"
	_group_title.add_theme_color_override("font_color", UiPalette.GOLD)
	_group_title.clip_text = true
	_group_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(_group_title)
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
	_cost = Label.new()
	_cost.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_cost)
	_recruit = Button.new()
	_recruit.theme_type_variation = "Accent"
	_recruit.pressed.connect(_on_recruit)
	v.add_child(_recruit)
	_clear = Button.new()
	_clear.text = "Clear picks"
	_clear.pressed.connect(_on_clear)
	v.add_child(_clear)
	return side


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

	var cols: Array = [
		{"key": "pick", "title": "Pick", "stretch": 0.6},
		{"key": "name", "title": "Name", "stretch": 2.2, "color": func(r): return UiPalette.GOLD if _picked.has(r["_name"]) else UiPalette.TEXT},
		{"key": "sex", "title": "Sex", "stretch": 0.6},
	]
	for key in visible_skills(p.astronaut_level):
		cols.append({"key": key, "title": SKILL_SHORT[key], "numeric": true, "stretch": 0.6})
	_table.set_columns(cols)
	_table.set_rows(candidate_rows(pool, _picked, p.astronaut_level))
	_mark_shown_row()

	if p.recruit_delay > 0:
		_info.text = "No candidates are available. Next group available in %d season%s." % [p.recruit_delay, "" if p.recruit_delay == 1 else "s"]
	elif group.is_empty():
		_info.text = "No further recruitment groups are available."
	else:
		_info.text = "Group %d: choose up to %d of these %d candidates for %d MB. Hidden stats stay hidden until the recruits finish basic training." % [
			int(group.get("group", p.recruit_group + 1)), quota, pool.size(), SimPersonnel.recruit_cost(p, state)]
	_note.visible = not pool.is_empty() and SimPersonnel.woman_required(p)
	_note.text = "At least one woman must be in this group's pick."
	_group_title.text = "GROUP %d SELECTION" % int(group.get("group", p.recruit_group + 1)) if not group.is_empty() else "NO GROUP OPEN"
	_refresh_dossier(p)
	_refresh_side(p, state, quota, pool.is_empty())


func _mark_shown_row() -> void:
	for i in _table.rows.size():
		if _table.rows[i].get("_name") == _shown:
			_table.select_index(i)


func _refresh_dossier(p: SimPlayer) -> void:
	_portrait.queue_redraw()
	var c := _candidate(_shown)
	if c.is_empty():
		_banner.text = "NAME: -"
		for key in _ratings:
			_ratings[key].text = "-"
		_pick.text = "Pick candidate"
		_pick.set_pressed_no_signal(false)
		_pick.disabled = true
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
	_pick.set_pressed_no_signal(picked)
	_pick.text = "Remove from picks" if picked else "Pick candidate"
	_pick.disabled = not picked and _picked.size() >= _quota
	_hidden_note.text = "Click a row to view a candidate, click it again to pick. Skills marked ? are hidden at this difficulty until basic training ends." \
		if shown.size() < SimAstronaut.SKILLS.size() else "Click a row to view a candidate, click it again to pick."


func _refresh_side(p: SimPlayer, state: SimState, quota: int, empty: bool) -> void:
	_picked_title.text = "PICKED %d OF %d" % [_picked.size(), quota]
	_picked_title.add_theme_color_override("font_color", UiPalette.OK if quota > 0 and _picked.size() == quota else UiPalette.GOLD)
	for t in _tiles.get_children():
		t.queue_free()
	for i in _picked.size():
		_tiles.add_child(_pick_tile(str(_picked[i]), i))
	_picked_list.visible = _picked.is_empty()
	_picked_list.text = "No candidates on offer this season." if empty else "Click a candidate twice, or use Pick candidate, to add them to the group."
	var cost := SimPersonnel.recruit_cost(p, state)
	_cost.text = "Cost: %d MB for the group   (cash %d MB)" % [cost, p.cash]
	_recruit.text = "Recruit  (%d MB)" % cost
	_recruit.disabled = empty or _picked.is_empty() or p.cash < cost
	_clear.disabled = _picked.is_empty()


func _show(name: String) -> void:
	_shown = name
	_mark_shown_row()
	_refresh_dossier(Session.me())
	for t in _tiles.get_children():
		t.get_child(0).queue_redraw()


func _on_row(row: Dictionary) -> void:
	_show(row["_name"])


func _on_row_activated(row: Dictionary) -> void:
	_shown = row["_name"]
	_toggle_pick(row["_name"])


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
