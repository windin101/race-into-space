extends ScreenPanel
## Launch Pad N: pad status with build or repair, this season's scheduled mission with
## the hardware it would fly and a scrub button, and next season's plan with cancel.
## Opened with setup({"pad": 0..2}).

var _pad := 0
var _pad_status: Label
var _build: Button
var _repair: Button
var _now_title: Label
var _now_text: Label
var _scrub: Button
var _next_title: Label
var _next_text: Label
var _cancel: Button


func _init() -> void:
	super()
	title = "Launch Pad 1"


func _ready() -> void:
	super()
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 12)
	content.add_child(status_row)
	UiHelp.attach(status_row, "I013")
	_pad_status = Label.new()
	_pad_status.theme_type_variation = "Subheading"
	_pad_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pad_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_row.add_child(_pad_status)
	_build = Button.new()
	_build.theme_type_variation = "Accent"
	_build.pressed.connect(_on_build)
	status_row.add_child(_build)
	_repair = Button.new()
	_repair.theme_type_variation = "Accent"
	_repair.pressed.connect(_on_repair)
	status_row.add_child(_repair)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 14)
	scroll.add_child(column)

	var now := PanelContainer.new()
	now.theme_type_variation = "Card"
	column.add_child(now)
	var now_box := VBoxContainer.new()
	now_box.add_theme_constant_override("separation", 6)
	now.add_child(now_box)
	_now_title = Label.new()
	_now_title.theme_type_variation = "Subheading"
	_now_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	now_box.add_child(_now_title)
	_now_text = Label.new()
	_now_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	now_box.add_child(_now_text)
	var now_actions := HBoxContainer.new()
	now_box.add_child(now_actions)
	_scrub = Button.new()
	_scrub.theme_type_variation = "Danger"
	_scrub.pressed.connect(_on_scrub)
	now_actions.add_child(_scrub)

	var next := PanelContainer.new()
	next.theme_type_variation = "Sunken"
	column.add_child(next)
	var next_box := VBoxContainer.new()
	next_box.add_theme_constant_override("separation", 6)
	next.add_child(next_box)
	_next_title = Label.new()
	_next_title.theme_type_variation = "Subheading"
	_next_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next_box.add_child(_next_title)
	_next_text = Label.new()
	_next_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next_box.add_child(_next_text)
	var next_actions := HBoxContainer.new()
	next_box.add_child(next_actions)
	_cancel = Button.new()
	_cancel.pressed.connect(_on_cancel)
	next_actions.add_child(_cancel)
	_refresh()


func setup(args: Dictionary) -> void:
	_pad = clampi(int(args.get("pad", 0)), 0, 2)
	title = "Launch Pad %d" % (_pad + 1)
	_refresh()


func on_resume() -> void:
	_refresh()


func _refresh() -> void:
	if not Session.has_game():
		return
	var state := Session.state()
	var p := Session.me()
	var pad_state: int = p.pads[_pad]
	_build.visible = false
	_repair.visible = false
	if pad_state == SimPlayer.PAD_NONE:
		_pad_status.text = "Not built."
		if _is_next_to_build(p):
			_build.visible = true
			_build.text = "Build pad  (%d MB)" % SimEconomy.PAD_COST
			_build.disabled = not SimEconomy.can_buy_pad(p)
		else:
			_pad_status.text += "  Pads are built in order; build the lower-numbered pad first."
	elif pad_state == SimPlayer.PAD_OK:
		_pad_status.text = "Operational."
	else:
		var cost := mini(pad_state, SimEconomy.PAD_COST)
		_pad_status.text = ("Destroyed; rebuilding costs %d MB." if pad_state >= SimEconomy.PAD_COST else "Damaged; repair costs %d MB.") % cost
		_repair.visible = true
		_repair.text = "Repair  (%d MB)" % cost
		_repair.disabled = p.cash < cost

	# This season.
	var pl = p.missions[_pad]
	_scrub.visible = pl != null
	if pl == null:
		_now_title.text = "This season (%s): nothing scheduled on this pad." % state.date_string()
		_now_text.text = "" if pad_state == SimPlayer.PAD_OK else "The pad must be operational for a mission to fly from it."
	elif pl.get("part", 1) == 2:
		var primary: int = int(pl.get("primary_pad", _pad))
		var m := SimPlanner.mission_def(state, int(pl["mission_index"]))
		_now_title.text = "This season (%s): second vehicle of %s" % [state.date_string(), str(m["name"]).capitalize()]
		_now_text.text = "This is part two of the joint mission launched from Pad %d; the plan and its crews are managed there." % (primary + 1)
		_scrub.text = "Scrub the joint mission"
	else:
		var m := SimPlanner.mission_def(state, int(pl["mission_index"]))
		_now_title.text = "This season (%s): %s" % [state.date_string(), str(m["name"]).capitalize()]
		_now_text.text = "\n".join(_preview_lines(state, p, pl))
		_scrub.text = "Scrub mission"
	_scrub.disabled = state.ended

	# Next season.
	var when := SimPlanner.launch_date(state)
	var when_text := "%s %d" % ["Spring" if when[1] == SimState.SEASON_SPRING else "Fall", 1900 + when[0]]
	var fut = p.future[_pad]
	_cancel.visible = fut != null
	if fut == null:
		_next_title.text = "Next season (%s): no plan on this pad." % when_text
		_next_text.text = "Missions are planned in the Future Missions Office in Administration."
	else:
		var m := SimPlanner.mission_def(state, int(fut["mission_index"]))
		if fut.get("part", 1) == 2:
			_next_title.text = "Next season (%s): second vehicle of %s" % [when_text, str(m["name"]).capitalize()]
			_next_text.text = "Reserved for the joint mission planned on Pad %d." % (int(fut.get("primary_pad", _pad)) + 1)
			_cancel.text = "Cancel the joint plan"
		else:
			_next_title.text = "Next season (%s): %s" % [when_text, str(m["name"]).capitalize()]
			var bits: PackedStringArray = []
			bits.append("%d step%s." % [str(m["code"]).length(), "" if str(m["code"]).length() == 1 else "s"])
			if fut.get("joint", false):
				bits.append("Joint mission; Pad %d is reserved for its second vehicle." % (_pad + 2))
			if int(fut.get("rush_months", 0)) > 0:
				bits.append("Rushed by %d month%s." % [int(fut["rush_months"]), "" if int(fut["rush_months"]) == 1 else "s"])
			var pen := SimPlanner.requirement_penalty(state, p, int(fut["mission_index"]), int(fut.get("duration", -1)))
			if int(pen["total"]) > 0 or int(pen["lm"]) > 0:
				bits.append("Requirement penalty -%d%%%s." % [int(pen["total"]), ("; LM penalty -%d%%" % int(pen["lm"])) if int(pen["lm"]) > 0 else ""])
			_next_text.text = " ".join(bits)
			_cancel.text = "Cancel plan"


## Is this the first unbuilt pad? Pads are built in order.
func _is_next_to_build(p: SimPlayer) -> bool:
	for i in _pad:
		if p.pads[i] == SimPlayer.PAD_NONE:
			return false
	return true


func _preview_lines(state: SimState, p: SimPlayer, pl: Dictionary) -> Array:
	var lines: Array = []
	if not p.pad_usable(_pad):
		lines.append("The pad is not operational: the mission will be scrubbed at the end of the season unless it is repaired.")
	var launch := SimPlanner.assemble_with_downgrades(state, p, pl)
	if not launch.has("vehicles"):
		lines.append("Cannot fly: %s. Buy the missing hardware or assign a crew in the Vehicle Assembly Building, or it will be scrubbed." % launch.get("reason", "unknown"))
		return lines
	if launch.has("downgraded_from"):
		var m := SimPlanner.mission_def(state, int(launch["mission_index"]))
		lines.append("Would fly as the downgrade %s." % str(m["name"]).capitalize())
	lines.append("Launches in %s.   Readiness %s." % [OpsView.launch_month_name(state, p, _pad), OpsView.readiness_text(launch)])
	for i in launch["vehicles"].size():
		var v: Dictionary = launch["vehicles"][i]
		var names: PackedStringArray = []
		for item in OpsView.payload_items(v):
			names.append(item["name"])
		lines.append("Vehicle %d: %s carrying %s  (payload %d / lift %d)." % [i + 1, OpsView.rocket_name(v), ", ".join(names) if not names.is_empty() else "no payload", OpsView.payload_weight(v), OpsView.lift(v)])
		for line in OpsView.crew_lines(v):
			lines.append("    " + line)
	return lines


func _on_build() -> void:
	if SimEconomy.buy_pad(Session.me()):
		Session.notify_change()
		_refresh()


func _on_repair() -> void:
	if SimEconomy.repair_pad(Session.me(), _pad):
		Session.notify_change()
		_refresh()


func _on_scrub() -> void:
	var p := Session.me()
	if p.missions[_pad] == null:
		return
	if await ConfirmBox.ask(self, "Scrub the mission?", "Hardware stays in inventory; scrubbing costs %d prestige." % absi(SimGame.SCRUB_PRESTIGE)):
		if Session.game.scrub(p, _pad):
			Session.notify_change()
			_refresh()


func _on_cancel() -> void:
	var p := Session.me()
	if p.future[_pad] == null:
		return
	SimPlanner.cancel_plan(p, _pad)
	Session.notify_change()
	_refresh()
