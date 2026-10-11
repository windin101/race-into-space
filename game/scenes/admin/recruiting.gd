extends ScreenPanel
## Astronaut / Cosmonaut Recruiting: the current candidate group, with the skills the
## astronaut difficulty level lets you see, a pick list up to the group's quota, the
## running cost and the Recruit command.

const SKILL_TITLES := {"capsule": "Capsule", "lm": "LM", "eva": "EVA", "docking": "Docking", "endurance": "Endurance"}
const SIDE_TITLES := {"usa": "Astronaut Recruiting", "ussr": "Cosmonaut Recruiting"}
const PICK_MARK := "[x]"
const UNPICK_MARK := "[  ]"

var _picked: Array = []       ## candidate names in pick order
var _table: DataTable
var _info: Label
var _note: Label
var _picked_title: Label
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
	content.add_child(_info)
	_note = Label.new()
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.add_theme_color_override("font_color", UiPalette.WARN)
	content.add_child(_note)

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 16)
	content.add_child(split)
	_table = DataTable.new()
	_table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_table.size_flags_stretch_ratio = 3.0
	_table.row_selected.connect(_on_row)
	_table.row_activated.connect(_on_row)
	split.add_child(_table)

	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.custom_minimum_size.x = 320
	side.add_theme_constant_override("separation", 8)
	split.add_child(side)
	_picked_title = Label.new()
	_picked_title.theme_type_variation = "Subheading"
	side.add_child(_picked_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(scroll)
	_picked_list = Label.new()
	_picked_list.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_picked_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_picked_list)
	_cost = Label.new()
	_cost.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_cost)
	_recruit = Button.new()
	_recruit.theme_type_variation = "Accent"
	_recruit.pressed.connect(_on_recruit)
	side.add_child(_recruit)
	_clear = Button.new()
	_clear.text = "Clear picks"
	_clear.pressed.connect(_on_clear)
	side.add_child(_clear)
	_refresh()


func setup(_args: Dictionary) -> void:
	_refresh()


func on_resume() -> void:
	_refresh()


func _refresh() -> void:
	if not Session.has_game():
		return
	var state := Session.state()
	var p := Session.me()
	var pool := SimPersonnel.available_recruits(state, p)
	var groups: Array = GameData.roster["sides"][p.side]
	var group: Dictionary = groups[p.recruit_group] if p.recruit_group >= 0 and p.recruit_group < groups.size() else {}
	var quota := int(group.get("number_to_choose", 0))
	# Drop picks that are no longer offered.
	var names: Array = []
	for c in pool:
		names.append(c["name"])
	_picked = _picked.filter(func(n): return names.has(n))

	var cols: Array = [
		{"key": "pick", "title": "Pick", "stretch": 0.6},
		{"key": "name", "title": "Name", "stretch": 2.5},
		{"key": "sex", "title": "Sex", "stretch": 0.6},
	]
	for key in visible_skills(p.astronaut_level):
		cols.append({"key": key, "title": SKILL_TITLES[key], "numeric": true})
	_table.set_columns(cols)
	_table.set_rows(candidate_rows(pool, _picked, p.astronaut_level))

	if p.recruit_delay > 0:
		_info.text = "No candidates are available. Next group available in %d season%s." % [p.recruit_delay, "" if p.recruit_delay == 1 else "s"]
	elif group.is_empty():
		_info.text = "No further recruitment groups are available."
	else:
		_info.text = "Group %d: choose up to %d of these %d candidates for %d MB. Hidden stats stay hidden until the recruits finish basic training." % [
			int(group.get("group", p.recruit_group + 1)), quota, pool.size(), SimPersonnel.recruit_cost(p, state)]
	_note.visible = not pool.is_empty() and SimPersonnel.woman_required(p)
	_note.text = "At least one woman must be in this group's pick."
	_refresh_side(p, state, quota, pool.is_empty())


func _refresh_side(p: SimPlayer, state: SimState, quota: int, empty: bool) -> void:
	_picked_title.text = "Picked %d of %d" % [_picked.size(), quota]
	var lines: PackedStringArray = []
	for i in _picked.size():
		lines.append("%d. %s" % [i + 1, str(_picked[i]).capitalize()])
	_picked_list.text = "\n".join(lines) if not lines.is_empty() else "Click a candidate to pick them."
	var cost := SimPersonnel.recruit_cost(p, state)
	_cost.text = "Cost: %d MB for the group   (cash %d MB)" % [cost, p.cash]
	_recruit.text = "Recruit  (%d MB)" % cost
	_recruit.disabled = empty or _picked.is_empty() or p.cash < cost
	_clear.disabled = _picked.is_empty()


func _on_row(row: Dictionary) -> void:
	var p := Session.me()
	var groups: Array = GameData.roster["sides"][p.side]
	var quota := int(groups[p.recruit_group].get("number_to_choose", 0)) if p.recruit_group < groups.size() else 0
	var name: String = row["_name"]
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
