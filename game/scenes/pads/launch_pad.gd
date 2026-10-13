extends ScreenPanel
## Launch Pad N, laid out like the original: the pad in a display case (the bare site,
## the ready pad with this season's vehicle standing on it, or the wreck), a status sheet
## and this season's and next season's mission briefs beside it, and the build, repair,
## scrub and cancel commands as a board. Opened with setup({"pad": 0..2}).

const MissionControl := preload("res://scenes/mission_control/mission_control.gd")
const FACILITY := ["A", "B", "C"]

var _pad := 0
var _vehicle: Dictionary = {}
var _pad_state := SimPlayer.PAD_OK
var _banner: Label
var _case: Control
var _caption: Label
var _status_panel: UiPanel
var _now_panel: UiPanel
var _next_panel: UiPanel
var _sheet: GridContainer
var _values: Dictionary = {}
var _now_brief: Label
var _now_notes: Label
var _next_brief: Label
var _next_notes: Label
var _build: Button
var _repair: Button
var _scrub: Button
var _cancel: Button
var _hint: Label


func _init() -> void:
	super()
	title = "Launch Pad 1"


func _ready() -> void:
	super()
	set_room("room_hangar")
	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 16)
	content.add_child(split)
	UiHelp.attach(split, "I013")

	# Left: banner and the pad on display.
	var left := UiPanel.new("The pad", "I013")
	left.size_flags_stretch_ratio = 1.3
	split.add_child(left)
	var banner_panel := PanelContainer.new()
	banner_panel.theme_type_variation = "Sunken"
	left.body.add_child(banner_panel)
	_banner = Label.new()
	_banner.theme_type_variation = "Heading"
	_banner.add_theme_color_override("font_color", UiPalette.GOLD)
	banner_panel.add_child(_banner)
	_case = Control.new()
	_case.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_case.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_case.clip_contents = true
	_case.draw.connect(_draw_case)
	_case.resized.connect(_case.queue_redraw)
	left.body.add_child(_case)
	_caption = Label.new()
	_caption.theme_type_variation = "Subheading"
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.body.add_child(_caption)

	# Right: status sheet with build/repair, this season with scrub, next season with cancel.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.custom_minimum_size.x = 620
	right.add_theme_constant_override("separation", 12)
	split.add_child(right)
	_status_panel = UiPanel.new("Pad status", "I013")
	right.add_child(_status_panel)
	_sheet = GridContainer.new()
	_sheet.columns = 2
	_sheet.add_theme_constant_override("h_separation", 24)
	_sheet.add_theme_constant_override("v_separation", 6)
	_status_panel.body.add_child(_sheet)
	for key in ["status", "cost", "now", "month", "readiness", "next"]:
		var k := Label.new()
		k.theme_type_variation = "Caps"
		k.text = {"status": "STATUS", "cost": "REPAIR COST", "now": "THIS SEASON", "month": "LAUNCH",
				  "readiness": "READINESS", "next": "NEXT SEASON"}[key]
		_sheet.add_child(k)
		var v := Label.new()
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.clip_text = true
		v.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_sheet.add_child(v)
		_values[key] = v
	_hint = _note(_status_panel.body)

	_now_panel = UiPanel.new("This season", "I013")
	_now_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_now_panel)
	_now_brief = _brief(_now_panel.body)
	_now_notes = _note(_now_panel.body)

	_next_panel = UiPanel.new("Next season", "I013")
	right.add_child(_next_panel)
	_next_brief = _brief(_next_panel.body)
	_next_notes = _note(_next_panel.body)
	_build = _status_panel.add_action("Build pad", "go", _on_build)
	_repair = _status_panel.add_action("Repair pad", "go", _on_repair)
	_scrub = _now_panel.add_action("Scrub mission", "caution", _on_scrub)
	_cancel = _next_panel.add_action("Cancel next season's plan", "caution", _on_cancel)
	_refresh()


func setup(args: Dictionary) -> void:
	_pad = clampi(int(args.get("pad", 0)), 0, 2)
	title = "Launch Pad %d" % (_pad + 1)
	_refresh()


func on_resume() -> void:
	_refresh()


func _brief(parent: Control) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", UiPalette.INFO)
	parent.add_child(l)
	return l


func _note(parent: Control) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.theme_type_variation = "Small"
	parent.add_child(l)
	return l


# ----------------------------------------------------------------- refresh

func _refresh() -> void:
	if not Session.has_game() or _banner == null:
		return
	var state := Session.state()
	var p := Session.me()
	_pad_state = p.pads[_pad]
	_banner.text = "LAUNCH FACILITY: %s" % FACILITY[_pad]

	# Pad status and the build/repair commands (always shown, disabled when they do not apply).
	var status := "OPERATIONAL"
	var status_color := UiPalette.OK
	var cost_text := "-"
	var hints: PackedStringArray = []
	var damage_cost := 0
	if _pad_state == SimPlayer.PAD_NONE:
		status = "NOT BUILT"
		status_color = UiPalette.TEXT_MUTED
		cost_text = "%d MB to build" % SimEconomy.PAD_COST
		if not _is_next_to_build(p):
			hints.append("Pads are built in order; build the lower-numbered pad first.")
	elif _pad_state != SimPlayer.PAD_OK:
		damage_cost = mini(_pad_state, SimEconomy.PAD_COST)
		status = "DESTROYED" if _pad_state >= SimEconomy.PAD_COST else "DAMAGED"
		status_color = UiPalette.DANGER if _pad_state >= SimEconomy.PAD_COST else UiPalette.WARN
		cost_text = "%d MB" % damage_cost
		hints.append(("Destroyed; rebuilding costs %d MB." if _pad_state >= SimEconomy.PAD_COST else "Damaged; repair costs %d MB.") % damage_cost)
	_values["status"].text = status
	_values["status"].add_theme_color_override("font_color", status_color)
	_values["cost"].text = cost_text
	_sheet.get_child(2).text = "BUILD COST" if _pad_state == SimPlayer.PAD_NONE else "REPAIR COST"
	_caption.text = status
	_caption.add_theme_color_override("font_color", status_color)
	var build_why := ""
	if _pad_state != SimPlayer.PAD_NONE:
		build_why = "Already built. This pad stands; damage is put right with Repair."
	elif not _is_next_to_build(p):
		build_why = "Build pad %d first. Pads are built in order." % _first_unbuilt(p)
	elif not SimEconomy.can_buy_pad(p):
		build_why = "Need %d MB. Building a pad costs %d MB; you have %d MB." % [SimEconomy.PAD_COST, SimEconomy.PAD_COST, p.cash]
	var repair_why := ""
	if _pad_state == SimPlayer.PAD_NONE:
		repair_why = "Not built. There is no pad here to repair."
	elif damage_cost <= 0:
		repair_why = "No damage. The pad is operational."
	elif p.cash < damage_cost:
		repair_why = "Need %d MB. The repair costs %d MB; you have %d MB." % [damage_cost, damage_cost, p.cash]
	_status_panel_actions(build_why, repair_why, damage_cost)

	# This season.
	_vehicle = {}
	var pl = p.missions[_pad]
	_values["month"].text = "-"
	_values["readiness"].text = "-"
	_values["readiness"].add_theme_color_override("font_color", UiPalette.TEXT_DIM)
	if pl == null:
		_values["now"].text = "Nothing scheduled"
		_now_brief.text = "NO LAUNCH SCHEDULED FOR %s" % state.date_string().to_upper()
		_now_notes.text = "" if _pad_state == SimPlayer.PAD_OK else "The pad must be operational for a mission to fly from it."
	elif pl.get("part", 1) == 2:
		var primary_pad: int = int(pl.get("primary_pad", _pad))
		var m := SimPlanner.mission_def(state, int(pl["mission_index"]))
		_values["now"].text = str(m["name"]).capitalize()
		_values["month"].text = OpsView.launch_month_name(state, p, primary_pad)
		var primary = p.missions[primary_pad]
		var lines: PackedStringArray = ["MISSION: %s" % str(m["name"]).to_upper(), "SECOND VEHICLE OF THE JOINT MISSION FROM FACILITY %s" % FACILITY[primary_pad]]
		if primary != null:
			var launch := SimPlanner.assemble_with_downgrades(state, p, primary)
			_show_readiness(launch)
			if launch.has("vehicles") and launch["vehicles"].size() > 1:
				_vehicle = launch["vehicles"][1]
				lines.append_array(_vehicle_lines(_vehicle))
		_now_brief.text = "\n".join(lines)
		_now_notes.text = "This is part two of the joint mission launched from Pad %d; the plan and its crews are managed there." % (primary_pad + 1)
	else:
		var m := SimPlanner.mission_def(state, int(pl["mission_index"]))
		_values["now"].text = str(m["name"]).capitalize()
		_values["month"].text = OpsView.launch_month_name(state, p, _pad)
		var launch := SimPlanner.assemble_with_downgrades(state, p, pl)
		_show_readiness(launch)
		var lines: PackedStringArray = ["MISSION: %s" % str(m["name"]).to_upper()]
		if launch.has("vehicles"):
			_vehicle = launch["vehicles"][0]
			for i in launch["vehicles"].size():
				if launch["vehicles"].size() > 1:
					lines.append("VEHICLE %d" % (i + 1))
				lines.append_array(_vehicle_lines(launch["vehicles"][i]))
		_now_brief.text = "\n".join(lines)
		_now_notes.text = "\n".join(_preview_notes(state, p, launch))
	var scrub_why := ""
	if state.ended:
		scrub_why = "Game over. There are no more seasons to play."
	elif pl == null:
		scrub_why = "Nothing scheduled. No mission flies from this pad this season."
	_restyle(_scrub, "Scrub the joint mission" if pl != null and pl.get("part", 1) == 2 else "Scrub mission", scrub_why)
	if scrub_why == "":
		_scrub.tooltip_text = "Take the mission off the pad. Hardware stays in inventory; scrubbing costs %d prestige." % absi(SimGame.SCRUB_PRESTIGE)

	# Next season.
	var when := SimPlanner.launch_date(state)
	var when_text := "%s %d" % ["Spring" if when[1] == SimState.SEASON_SPRING else "Fall", 1900 + when[0]]
	var fut = p.future[_pad]
	var cancel_text := "Cancel next season's plan"
	if fut == null:
		_values["next"].text = "No plan"
		_next_brief.text = "NO PLAN FOR %s" % when_text.to_upper()
		_next_notes.text = "Missions are planned in the Future Missions Office in Administration."
	else:
		var m := SimPlanner.mission_def(state, int(fut["mission_index"]))
		_values["next"].text = str(m["name"]).capitalize()
		if fut.get("part", 1) == 2:
			_next_brief.text = "%s: SECOND VEHICLE OF %s" % [when_text.to_upper(), str(m["name"]).to_upper()]
			_next_notes.text = "Reserved for the joint mission planned on Pad %d." % (int(fut.get("primary_pad", _pad)) + 1)
			cancel_text = "Cancel the joint plan"
		else:
			_next_brief.text = "%s: %s" % [when_text.to_upper(), str(m["name"]).to_upper()]
			var bits: PackedStringArray = []
			bits.append("%d step%s." % [str(m["code"]).length(), "" if str(m["code"]).length() == 1 else "s"])
			if fut.get("joint", false):
				bits.append("Joint mission; Pad %d is reserved for its second vehicle." % (_pad + 2))
			if int(fut.get("rush_months", 0)) > 0:
				bits.append("Rushed by %d month%s." % [int(fut["rush_months"]), "" if int(fut["rush_months"]) == 1 else "s"])
			var pen := SimPlanner.requirement_penalty(state, p, int(fut["mission_index"]), int(fut.get("duration", -1)))
			if int(pen["total"]) > 0 or int(pen["lm"]) > 0:
				bits.append("Requirement penalty -%d%%%s." % [int(pen["total"]), ("; LM penalty -%d%%" % int(pen["lm"])) if int(pen["lm"]) > 0 else ""])
			_next_notes.text = " ".join(bits)
	_restyle(_cancel, cancel_text, "" if fut != null else "No plan. Nothing is planned for this pad next season.")
	if fut != null:
		_cancel.tooltip_text = "Drop the plan for next season; plan again in the Future Missions Office."
	if not _vehicle.is_empty() or pl != null:
		_caption.text = _values["now"].text
		_caption.add_theme_color_override("font_color", UiPalette.TEXT)
	_hint.text = "\n".join(hints)
	_hint.visible = not hints.is_empty()
	_case.queue_redraw()


## Build and repair on the status panel: each go, or blocked with its reason.
func _status_panel_actions(build_why: String, repair_why: String, damage_cost: int) -> void:
	UiAction.go_or_blocked(_build, "Build pad  (%d MB)" % SimEconomy.PAD_COST, build_why)
	if build_why == "":
		_build.tooltip_text = "Build launch pad %d for %d MB." % [_pad + 1, SimEconomy.PAD_COST]
	UiAction.go_or_blocked(_repair, ("Repair pad  (%d MB)" % damage_cost) if damage_cost > 0 else "Repair pad", repair_why)
	if repair_why == "":
		_repair.tooltip_text = "Repair the pad for %d MB." % damage_cost


## A cautious action (scrub, cancel): caution when `why` is empty, otherwise blocked.
func _restyle(b: Button, text: String, why: String) -> void:
	UiAction.style(b, "caution" if why == "" else "blocked", text, why)


func _first_unbuilt(p: SimPlayer) -> int:
	for i in 3:
		if p.pads[i] == SimPlayer.PAD_NONE:
			return i + 1
	return _pad + 1


func _show_readiness(launch: Dictionary) -> void:
	if launch.has("vehicles"):
		_values["readiness"].text = OpsView.readiness_text(launch)
		_values["readiness"].add_theme_color_override("font_color", OpsView.readiness_color(launch))
	else:
		_values["readiness"].text = "Cannot fly"
		_values["readiness"].add_theme_color_override("font_color", UiPalette.DANGER)


## Brief lines for one assembled vehicle: rocket, payload, crew.
func _vehicle_lines(v: Dictionary) -> Array:
	var names: PackedStringArray = []
	for item in OpsView.payload_items(v):
		names.append(str(item["name"]).to_upper())
	var lines: Array = [
		"ROCKET: %s" % OpsView.rocket_name(v).to_upper(),
		"PAYLOAD: %s   (%d OF %d)" % [", ".join(names) if not names.is_empty() else "NONE", OpsView.payload_weight(v), OpsView.lift(v)],
	]
	var crew: PackedStringArray = []
	for a in v["crew"]:
		crew.append(a.name.to_upper())
	lines.append("CREW: %s" % (", ".join(crew) if not crew.is_empty() else "UNMANNED"))
	return lines


## Is this the first unbuilt pad? Pads are built in order.
func _is_next_to_build(p: SimPlayer) -> bool:
	for i in _pad:
		if p.pads[i] == SimPlayer.PAD_NONE:
			return false
	return true


func _preview_notes(_state: SimState, p: SimPlayer, launch: Dictionary) -> Array:
	var lines: Array = []
	if not p.pad_usable(_pad):
		lines.append("The pad is not operational: the mission will be scrubbed at the end of the season unless it is repaired.")
	if not launch.has("vehicles"):
		lines.append("Cannot fly: %s. Buy the missing hardware or assign a crew in the Vehicle Assembly Building, or it will be scrubbed." % launch.get("reason", "unknown"))
		return lines
	if launch.has("downgraded_from"):
		var m := SimPlanner.mission_def(_state, int(launch["mission_index"]))
		lines.append("Would fly as the downgrade %s." % str(m["name"]).capitalize())
	lines.append("Penalties on every step: requirements -%d%%, lunar module -%d%%, rush -%d%%." % [
		int(launch["requirement_penalty"]), int(launch["lm_penalty"]), int(launch["rush_penalty"])])
	return lines


# ----------------------------------------------------------------- drawing

func _draw_case() -> void:
	var side := Session.human_side if Session.has_game() else "usa"
	MissionControl.paint_pad(_case, Rect2(Vector2.ZERO, _case.size), side, _pad_state, _vehicle)


# ----------------------------------------------------------------- commands

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
