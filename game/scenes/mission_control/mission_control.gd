extends ScreenPanel
## Mission Control: this season's scheduled missions with their launch month, rush,
## downgrade and scrub controls and readiness, and the flag that ends the season.

var _list: VBoxContainer
var _empty: Label
var _flag: Button


func _init() -> void:
	super()
	title = "Mission Control"


func _ready() -> void:
	super()
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	UiHelp.attach(scroll, "I010")
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 14)
	scroll.add_child(_list)
	_empty = Label.new()
	_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty.theme_type_variation = "Dim"
	_list.add_child(_empty)
	_flag = Button.new()
	_flag.theme_type_variation = "Accent"
	_flag.text = "Lower the flag: end the season"
	_flag.pressed.connect(_on_lower_flag)
	footer.add_child(_flag)
	_refresh()


func on_resume() -> void:
	_refresh()


func _refresh() -> void:
	if not Session.has_game():
		return
	for c in _list.get_children():
		if c != _empty:
			c.queue_free()
	var state := Session.state()
	var p := Session.me()
	_flag.disabled = state.ended
	var pads := OpsView.scheduled_pads(p)
	_empty.visible = pads.is_empty()
	if pads.is_empty():
		_empty.text = "No launches are scheduled for %s. Lower the flag to end the season, or plan next season's missions in the Future Missions Office." % state.date_string()
		return
	for pad in pads:
		_list.add_child(_make_mission_card(state, p, pad))


func _make_mission_card(state: SimState, p: SimPlayer, pad: int) -> Control:
	var pl: Dictionary = p.missions[pad]
	var m := SimPlanner.mission_def(state, int(pl["mission_index"]))
	var panel := PanelContainer.new()
	panel.theme_type_variation = "Card"
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	v.add_child(head)
	var name_label := Label.new()
	name_label.theme_type_variation = "Subheading"
	name_label.text = "%s   (Pad %d)" % [str(m["name"]).capitalize(), pad + 1]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.add_child(name_label)
	var month := Label.new()
	month.theme_type_variation = "Subheading"
	month.text = "Launches in " + OpsView.launch_month_name(state, p, pad)
	head.add_child(month)
	var ready_label := Label.new()
	ready_label.theme_type_variation = "Subheading"
	head.add_child(ready_label)

	var info := Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.theme_type_variation = "Small"
	v.add_child(info)
	var launch := SimPlanner.assemble_with_downgrades(state, p, pl)
	var bits: PackedStringArray = []
	if launch.has("vehicles"):
		ready_label.text = "Readiness " + OpsView.readiness_text(launch)
		ready_label.add_theme_color_override("font_color", OpsView.readiness_color(launch))
		if launch.has("downgraded_from"):
			bits.append("Hardware is missing for the plan; it would fly as the downgrade %s." % str(SimPlanner.mission_def(state, int(launch["mission_index"]))["name"]).capitalize())
		bits.append("Penalties on every step: requirements -%d%%, lunar module -%d%%, rush -%d%%." % [
			int(launch["requirement_penalty"]), int(launch["lm_penalty"]), int(launch["rush_penalty"])])
	else:
		ready_label.text = "Cannot fly"
		ready_label.add_theme_color_override("font_color", UiPalette.DANGER)
		bits.append("Not assembled: %s. It will be scrubbed at the end of the season." % launch.get("reason", "unknown"))
	if pl.get("joint", false):
		bits.append("Joint mission; the second vehicle flies from Pad %d." % (pad + 2))
	var chain_names: PackedStringArray = []
	for alt in OpsView.downgrade_options(state, pl):
		chain_names.append(str(SimPlanner.mission_def(state, int(alt))["name"]).capitalize())
	bits.append("Downgrade chain: " + " > ".join(chain_names) + ".")
	info.text = "\n".join(bits)

	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 12)
	row.add_theme_constant_override("v_separation", 6)
	v.add_child(row)

	var rush_label := Label.new()
	rush_label.text = "Rush"
	row.add_child(rush_label)
	var rush := OptionButton.new()
	for months in range(0, SimPlanner.RUSH_MAX_MONTHS + 1):
		rush.add_item(OpsView.rush_label(months), months)
	rush.select(rush.get_item_index(int(pl.get("rush_months", 0))))
	rush.item_selected.connect(func(idx: int): _set_rush(pad, rush.get_item_id(idx)))
	row.add_child(rush)

	var fly_label := Label.new()
	fly_label.text = "Fly as"
	row.add_child(fly_label)
	var fly := OptionButton.new()
	for alt in OpsView.downgrade_options(state, pl):
		fly.add_item(str(SimPlanner.mission_def(state, int(alt))["name"]).capitalize(), int(alt))
	fly.select(fly.get_item_index(int(pl["mission_index"])))
	fly.item_selected.connect(func(idx: int): _set_mission(pad, fly.get_item_id(idx)))
	row.add_child(fly)

	var scrub := Button.new()
	scrub.theme_type_variation = "Danger"
	scrub.text = "Scrub mission"
	scrub.disabled = state.ended
	scrub.pressed.connect(_on_scrub.bind(pad))
	row.add_child(scrub)
	return panel


func _set_rush(pad: int, months: int) -> void:
	var p := Session.me()
	if SimPlanner.set_rush(p, pad, months, true):
		Session.notify_change()
		_refresh()
	else:
		_refresh()
		await ConfirmBox.notice(self, "Cannot rush", "Rushing costs %d MB per month; you have %d MB." % [SimPlanner.RUSH_COST_PER_MONTH, p.cash])


func _set_mission(pad: int, mission_index: int) -> void:
	var p := Session.me()
	var pl = p.missions[pad]
	if pl == null or int(pl["mission_index"]) == mission_index:
		return
	pl["mission_index"] = mission_index
	Session.notify_change()
	_refresh()


func _on_scrub(pad: int) -> void:
	var p := Session.me()
	if p.missions[pad] == null:
		return
	if await ConfirmBox.ask(self, "Scrub the mission?", "Hardware stays in inventory; scrubbing costs %d prestige." % absi(SimGame.SCRUB_PRESTIGE)):
		if Session.game.scrub(p, pad):
			Session.notify_change()
			_refresh()


func _on_lower_flag() -> void:
	if not Session.has_game() or Session.state().ended:
		return
	if await ConfirmBox.ask(self, "End the season?", "Lower the flag and let %s play out." % Session.state().date_string()):
		var report := Session.end_turn()
		Screens.pop()
		TurnFlow.after_end_turn(report)
