extends ScreenPanel
## Vehicle Assembly Building: for each mission scheduled this season, the launch as it
## would be assembled (rocket, payload against lift, crews with seat roles), the
## readiness band and penalties, and the choices the plan allows: capsule, crews and
## auto-purchase of missing units.

const AUTO_CAPSULE := -1

var _list: VBoxContainer
var _empty: Label


func _init() -> void:
	super()
	title = "Vehicle Assembly"


func _ready() -> void:
	super()
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	UiHelp.attach(scroll, "I012")
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 14)
	scroll.add_child(_list)
	_empty = Label.new()
	_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty.theme_type_variation = "Dim"
	_list.add_child(_empty)
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
	var pads := OpsView.scheduled_pads(p)
	_empty.visible = pads.is_empty()
	if pads.is_empty():
		_empty.text = "Nothing is scheduled for %s. Plan next season's missions in the Future Missions Office in Administration." % state.date_string()
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
	var patch := ArtAssets.patch(p.side, int(pl["mission_index"]))
	if patch != null:
		var badge := TextureRect.new()
		badge.texture = patch
		badge.custom_minimum_size = Vector2(72, 72)
		badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		head.add_child(badge)
	var name_label := Label.new()
	name_label.theme_type_variation = "Subheading"
	name_label.text = "%s   (Pad %d)" % [str(m["name"]).capitalize(), pad + 1]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.add_child(name_label)
	var ready_label := Label.new()
	ready_label.theme_type_variation = "Subheading"
	head.add_child(ready_label)

	var launch := SimPlanner.assemble(state, p, pl)
	if launch.has("vehicles"):
		ready_label.text = "Readiness " + OpsView.readiness_text(launch)
		ready_label.add_theme_color_override("font_color", OpsView.readiness_color(launch))
		for i in launch["vehicles"].size():
			_add_vehicle(v, launch["vehicles"][i], i, launch["vehicles"].size() > 1)
		var pen := Label.new()
		pen.theme_type_variation = "Small"
		pen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pen.text = "Penalties on every step: requirements -%d%%, lunar module -%d%%, rush -%d%%." % [
			int(launch["requirement_penalty"]), int(launch["lm_penalty"]), int(launch["rush_penalty"])]
		v.add_child(pen)
	else:
		ready_label.text = "Cannot fly"
		ready_label.add_theme_color_override("font_color", UiPalette.DANGER)
		var why := Label.new()
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		why.text = "Not assembled: %s. The mission is scrubbed at the end of the season unless this is fixed." % launch.get("reason", "unknown")
		why.add_theme_color_override("font_color", UiPalette.DANGER)
		v.add_child(why)
		var alt := SimPlanner.assemble_with_downgrades(state, p, pl)
		if alt.has("downgraded_from"):
			var alt_m := SimPlanner.mission_def(state, int(alt["mission_index"]))
			var note := Label.new()
			note.theme_type_variation = "Small"
			note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			note.text = "It would fly as the downgrade %s instead (readiness %s)." % [str(alt_m["name"]).capitalize(), OpsView.readiness_text(alt)]
			v.add_child(note)

	_add_controls(v, state, p, pad, pl, m, launch)
	return panel


func _add_vehicle(v: VBoxContainer, vehicle: Dictionary, index: int, joint: bool) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	v.add_child(box)
	if joint:
		var sub := Label.new()
		sub.theme_type_variation = "Dim"
		sub.text = "Vehicle %d" % (index + 1)
		box.add_child(sub)
	var weight := OpsView.payload_weight(vehicle)
	var lift := OpsView.lift(vehicle)
	var rocket := Label.new()
	rocket.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rocket.text = "Rocket: %s   lift %d, payload %d" % [OpsView.rocket_name(vehicle), lift, weight]
	rocket.add_theme_color_override("font_color", UiPalette.OK if lift >= weight else UiPalette.DANGER)
	box.add_child(rocket)
	var items := OpsView.payload_items(vehicle)
	var payload := Label.new()
	payload.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if items.is_empty():
		payload.text = "Payload: none"
	else:
		var parts: PackedStringArray = []
		for item in items:
			parts.append("%s %d%%%s" % [item["name"], item["program"].safety, (" (%d)" % int(item["weight"])) if int(item["weight"]) > 0 else ""])
		payload.text = "Payload: " + ", ".join(parts)
	box.add_child(payload)
	var crew_lines := OpsView.crew_lines(vehicle)
	if not crew_lines.is_empty():
		var crew := Label.new()
		crew.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		crew.theme_type_variation = "Small"
		crew.text = "Crew   " + "   ".join(crew_lines)
		box.add_child(crew)


func _add_controls(v: VBoxContainer, state: SimState, p: SimPlayer, pad: int, pl: Dictionary, m: Dictionary, launch: Dictionary) -> void:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 12)
	row.add_theme_constant_override("v_separation", 6)
	v.add_child(row)

	var capsule_slot := -1
	if int(m["m_eq"]) > 0:
		var candidates: Array = SimPlanner._capsule_candidates(p, int(m["m_eq"]))
		var forced: int = int(pl.get("capsule_slot", AUTO_CAPSULE))
		if forced >= 0:
			var forced_prog: SimProgram = p.program("manned", forced)
			if forced_prog != null and forced_prog.owned and not candidates.has(forced_prog):
				candidates.append(forced_prog)
		if launch.has("vehicles") and launch["vehicles"][0]["payload"]["capsule"] != null:
			capsule_slot = launch["vehicles"][0]["payload"]["capsule"].slot
		elif forced >= 0:
			capsule_slot = forced
		elif not candidates.is_empty():
			capsule_slot = candidates[0].slot
		var cap_label := Label.new()
		cap_label.text = "Capsule"
		row.add_child(cap_label)
		var cap := OptionButton.new()
		cap.add_item("Automatic (safest)", AUTO_CAPSULE)
		for prog in candidates:
			cap.add_item("%s  %d%%  (%d unit%s)" % [prog.display_name().capitalize(), prog.safety, prog.units, "" if prog.units == 1 else "s"], prog.slot)
		cap.select(cap.get_item_index(forced) if forced >= 0 and cap.get_item_index(forced) >= 0 else 0)
		cap.item_selected.connect(func(idx: int): _set_capsule(pl, cap.get_item_id(idx)))
		row.add_child(cap)

	var n_vehicles: int = launch["vehicles"].size() if launch.has("vehicles") else (2 if pl.get("joint", false) else 1)
	for vi in n_vehicles:
		var manned: bool = int(m["m_eq"]) > 0 and capsule_slot >= 0
		if launch.has("vehicles"):
			manned = not launch["vehicles"][vi]["crew"].is_empty() or (launch["vehicles"][vi]["payload"]["capsule"] != null and int(m["crew_mode"]) != 0)
		if not manned:
			continue
		var crew_label := Label.new()
		crew_label.text = "Crew" if n_vehicles == 1 else "Crew (vehicle %d)" % (vi + 1)
		row.add_child(crew_label)
		var opt := OptionButton.new()
		var crews: Array = SimPersonnel.crews_of(p, capsule_slot)
		var choice: Array = pl.get("crew_choice", [0, 0])
		var current: int = int(choice[vi]) if vi < choice.size() else 0
		for ci in crews:
			var names: PackedStringArray = []
			for a in SimPersonnel.crew(p, capsule_slot, ci):
				names.append(a.name.capitalize())
			opt.add_item("%s: %s" % [OpsView.crew_title(ci), ", ".join(names)], ci)
		if crews.is_empty():
			opt.add_item("No crews assigned to this capsule", -1)
			opt.disabled = true
		elif opt.get_item_index(current) >= 0:
			opt.select(opt.get_item_index(current))
		else:
			opt.select(-1)
		opt.item_selected.connect(func(idx: int): _set_crew(pl, vi, opt.get_item_id(idx)))
		row.add_child(opt)

	var auto := Button.new()
	auto.text = "Auto-purchase missing units"
	auto.pressed.connect(_on_auto_purchase.bind(pad))
	row.add_child(auto)


func _set_capsule(pl: Dictionary, slot: int) -> void:
	if slot == AUTO_CAPSULE:
		pl.erase("capsule_slot")
	else:
		pl["capsule_slot"] = slot
	Session.notify_change()
	_refresh()


func _set_crew(pl: Dictionary, vehicle: int, crew_index: int) -> void:
	if crew_index < 0:
		return
	var choice: Array = pl.get("crew_choice", [0, 0]).duplicate()
	while choice.size() <= vehicle:
		choice.append(0)
	choice[vehicle] = crew_index
	pl["crew_choice"] = choice
	Session.notify_change()
	_refresh()


func _on_auto_purchase(pad: int) -> void:
	var state := Session.state()
	var p := Session.me()
	var pl = p.missions[pad]
	if pl == null:
		return
	var wanted := OpsView.shopping_list(state, p, pl)
	if wanted.is_empty():
		await ConfirmBox.notice(self, "Auto-purchase", "Nothing is missing: every program on this launch already has a unit in inventory, or the launch cannot be assembled for another reason.")
		return
	var failed := OpsView.auto_purchase(p, wanted)
	Session.notify_change()
	_refresh()
	var bought: PackedStringArray = []
	for prog in wanted:
		if not failed.has(prog):
			bought.append("%s (%d MB)" % [prog.display_name().capitalize(), SimHardware.unit_price(p, prog)])
	var text := ""
	if not bought.is_empty():
		text += "Bought: " + ", ".join(bought) + "."
	if not failed.is_empty():
		var missing: PackedStringArray = []
		for prog in failed:
			missing.append("%s (%d MB)" % [prog.display_name().capitalize(), SimHardware.unit_price(p, prog)])
		text += ("\n" if text != "" else "") + "Could not afford or buy: " + ", ".join(missing) + ".  Cash %d MB." % p.cash
	await ConfirmBox.notice(self, "Auto-purchase", text)
