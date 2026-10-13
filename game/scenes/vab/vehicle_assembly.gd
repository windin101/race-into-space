extends ScreenPanel
## Vehicle Assembly Building, laid out like the original: a launch facility banner and
## mission brief on the left with the hardware manifest (primary, kicker, LM, payload,
## rocket: name, safety, units), auto-purchase and scrub; and on the right the vehicle
## as it will stand on the pad, payload stack beside its booster. Choices the plan allows
## (capsule, crews) are made in the manifest. Rules come from SimPlanner and OpsView.

const AUTO_CAPSULE := -1
const FACILITY := ["A", "B", "C"]
const CASE_BG := Color("0a1424")

var _pads: Array = []
var _pad := -1
var _pad_tabs: HBoxContainer
var _tab_buttons: Dictionary = {}
var _banner: Label
var _brief: Label
var _chips: HBoxContainer
var _weight_chip: StatChip
var _crew_chip: StatChip
var _ready_label: Label
var _lamps: StatusLamps
var _gauge: Gauge
var _manifest_panel: UiPanel
var _manifest: GridContainer
var _choices: VBoxContainer
var _notes: Label
var _vehicle_panel: UiPanel
var _case: Control
var _launch: Dictionary = {}
var _auto: Button
var _scrub: Button
var _empty: Label
var _split: HBoxContainer


func _init() -> void:
	super()
	title = "Vehicle Assembly"


func _ready() -> void:
	super()
	set_room("room_hangar")
	_pad_tabs = HBoxContainer.new()
	_pad_tabs.add_theme_constant_override("separation", 8)
	content.add_child(_pad_tabs)
	UiHelp.attach(_pad_tabs, "I012")
	_empty = Label.new()
	_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty.theme_type_variation = "Dim"
	content.add_child(_empty)

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 16)
	content.add_child(split)
	_split = split

	# Left: banner, brief with readiness, manifest.
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.custom_minimum_size.x = 640
	left.add_theme_constant_override("separation", 12)
	split.add_child(left)
	var banner_panel := PanelContainer.new()
	banner_panel.theme_type_variation = "Sunken"
	left.add_child(banner_panel)
	_banner = Label.new()
	_banner.theme_type_variation = "Heading"
	_banner.add_theme_color_override("font_color", UiPalette.GOLD)
	banner_panel.add_child(_banner)

	var brief_panel := UiPanel.new("Mission brief", "I012")
	left.add_child(brief_panel)
	var brief_row := HBoxContainer.new()
	brief_row.add_theme_constant_override("separation", 16)
	brief_panel.body.add_child(brief_row)
	var brief_col := VBoxContainer.new()
	brief_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brief_col.add_theme_constant_override("separation", 8)
	brief_row.add_child(brief_col)
	_brief = Label.new()
	_brief.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_brief.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_brief.add_theme_color_override("font_color", UiPalette.INFO)
	brief_col.add_child(_brief)
	_chips = HBoxContainer.new()
	_chips.add_theme_constant_override("separation", 8)
	brief_col.add_child(_chips)
	_weight_chip = StatChip.new("weight", "-", "Payload weight against the rocket's maximum payload")
	_chips.add_child(_weight_chip)
	_crew_chip = StatChip.new("crew", "-", "Crew flying on this launch")
	_chips.add_child(_crew_chip)
	var ready_col := VBoxContainer.new()
	ready_col.add_theme_constant_override("separation", 6)
	ready_col.custom_minimum_size.x = 210
	ready_col.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	brief_row.add_child(ready_col)
	_ready_label = Label.new()
	_ready_label.theme_type_variation = "Caps"
	_ready_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ready_col.add_child(_ready_label)
	_lamps = StatusLamps.new()
	_lamps.tooltip_text = "Readiness: the lowest step safety after penalties. Nominal at %d%% and above, warning from %d%%, failure below." % [SimPlanner.READY_AOK, SimPlanner.READY_CAUTION]
	ready_col.add_child(_lamps)
	_gauge = Gauge.new(false, "Lowest safety on any step, after penalties")
	_gauge.custom_minimum_size = Vector2(210, 40)
	_gauge.mouse_filter = Control.MOUSE_FILTER_PASS
	_gauge.tooltip_text = "Lowest safety on any step, after penalties"
	ready_col.add_child(_gauge)

	_manifest_panel = UiPanel.new("Mission hardware", "I012")
	_manifest_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(_manifest_panel)
	_manifest = GridContainer.new()
	_manifest.columns = 4
	_manifest.add_theme_constant_override("h_separation", 18)
	_manifest.add_theme_constant_override("v_separation", 4)
	_manifest_panel.body.add_child(_manifest)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 6)
	_manifest_panel.body.add_child(_choices)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_manifest_panel.body.add_child(spacer)
	_notes = Label.new()
	_notes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notes.theme_type_variation = "Small"
	_manifest_panel.body.add_child(_notes)
	_auto = _manifest_panel.add_action("Autopurchase missing units", "go", _on_auto_purchase)
	_scrub = _manifest_panel.add_action("Scrub mission", "caution", _on_scrub)
	_scrub.tooltip_text = "Take this mission off the pad. Hardware stays in inventory; scrubbing costs %d prestige." % absi(SimGame.SCRUB_PRESTIGE)

	# Right: the vehicle on display.
	_vehicle_panel = UiPanel.new("Vehicle on the pad", "I012")
	_vehicle_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vehicle_panel.size_flags_stretch_ratio = 1.1
	split.add_child(_vehicle_panel)
	_case = Control.new()
	_case.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_case.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_case.clip_contents = true
	_case.draw.connect(_draw_case)
	_case.resized.connect(_case.queue_redraw)
	_vehicle_panel.body.add_child(_case)
	_refresh()


func on_resume() -> void:
	_refresh()


# ----------------------------------------------------------------- refresh

func _refresh() -> void:
	if not Session.has_game():
		return
	var state := Session.state()
	var p := Session.me()
	_pads = OpsView.scheduled_pads(p)
	for c in _pad_tabs.get_children():
		c.queue_free()
	_tab_buttons.clear()
	for pad in _pads:
		var b := Button.new()
		var m := SimPlanner.mission_def(state, int(p.missions[pad]["mission_index"]))
		b.text = "FACILITY %s:  %s" % [FACILITY[pad], str(m["name"]).to_upper()]
		b.theme_type_variation = "Bar"
		b.custom_minimum_size.y = 40
		b.tooltip_text = "Show the launch from Launch Facility %s: %s" % [FACILITY[pad], str(m["name"]).capitalize()]
		b.toggle_mode = true
		b.pressed.connect(func():
			_pad = pad
			_refresh())
		_pad_tabs.add_child(b)
		_tab_buttons[pad] = b
	if not _pads.has(_pad):
		_pad = _pads[0] if not _pads.is_empty() else -1
	for pad in _tab_buttons:
		_tab_buttons[pad].button_pressed = pad == _pad
	_empty.visible = _pads.is_empty()
	_split.visible = not _pads.is_empty()
	if _pads.is_empty():
		_empty.text = "Nothing is scheduled for %s. Plan next season's missions in the Future Missions Office in Administration." % state.date_string()
		_launch = {}
		return
	_refresh_pad(state, p)


func _refresh_pad(state: SimState, p: SimPlayer) -> void:
	var pl: Dictionary = p.missions[_pad]
	var m := SimPlanner.mission_def(state, int(pl["mission_index"]))
	_banner.text = "LAUNCH FACILITY: %s" % FACILITY[_pad]
	_launch = SimPlanner.assemble(state, p, pl)
	var lines: PackedStringArray = ["MISSION: %s" % str(m["name"]).to_upper()]
	var kind := "Manned" if int(m["m_eq"]) > 0 else "Unmanned"
	lines.append("%s mission, %s" % [kind, OpsView.launch_month_name(state, p, _pad)])
	if _launch.has("vehicles"):
		var crew_lines: Array = []
		var weight := 0
		var lift := 0
		for v in _launch["vehicles"]:
			crew_lines.append_array(OpsView.crew_lines(v))
			weight += OpsView.payload_weight(v)
			lift += OpsView.lift(v)
		lines.append("CREW: %s" % ("UNMANNED" if crew_lines.is_empty() else "\n".join(crew_lines).to_upper()))
		_weight_chip.set_value("%d / %d" % [weight, lift], weight > lift)
		_crew_chip.set_value(str(crew_lines.size()) if not crew_lines.is_empty() else "None")
		var r := SimPlanner.readiness(_launch)
		var band := str(r["band"])
		_ready_label.text = "READINESS  %d%%" % int(r["lowest_safety"])
		_ready_label.add_theme_color_override("font_color", OpsView.readiness_color(_launch))
		_lamps.set_level(StatusLamps.Level.NOMINAL if band == "a-ok" else (StatusLamps.Level.WARNING if band == "caution" else StatusLamps.Level.FAILURE))
		_gauge.value = maxi(0, int(r["lowest_safety"]))
	else:
		lines.append("CREW: -")
		_weight_chip.set_value("-")
		_crew_chip.set_value("-")
		_ready_label.text = "CANNOT FLY"
		_ready_label.add_theme_color_override("font_color", UiPalette.DANGER)
		_lamps.set_level(StatusLamps.Level.FAILURE)
		_gauge.value = 0
	_brief.text = "\n".join(lines)

	# Actions: auto-purchase (go, or blocked with the reason) and scrub (caution).
	var wanted := OpsView.shopping_list(state, p, pl)
	var cost := 0
	var cheapest := -1
	for prog in wanted:
		var price := SimHardware.unit_price(p, prog)
		cost += price
		cheapest = price if cheapest < 0 else mini(cheapest, price)
	var why := ""
	if wanted.is_empty():
		why = "Nothing missing. Every program on this launch already has a unit in inventory, or the launch cannot be assembled for another reason."
	elif p.cash < cheapest:
		why = "Not enough cash. The missing units cost %d MB; you have %d MB." % [cost, p.cash]
	_set_actions("Autopurchase missing units  (%d MB)" % cost, why)
	if why == "":
		_auto.tooltip_text = "Buy one unit of each program the launch is missing: %d MB of your %d MB.%s" % [
			cost, p.cash, "  Not everything is affordable; what can be bought is bought." if cost > p.cash else ""]

	_refresh_manifest(state, p, pl, m)
	var notes: PackedStringArray = []
	if _launch.has("vehicles"):
		notes.append("Penalties on every step: requirements -%d%%, lunar module -%d%%, rush -%d%%." % [
			int(_launch["requirement_penalty"]), int(_launch["lm_penalty"]), int(_launch["rush_penalty"])])
	else:
		notes.append("Not assembled: %s. The mission is scrubbed at the end of the season unless this is fixed." % _launch.get("reason", "unknown"))
		var alt := SimPlanner.assemble_with_downgrades(state, p, pl)
		if alt.has("downgraded_from"):
			var alt_m := SimPlanner.mission_def(state, int(alt["mission_index"]))
			notes.append("It would fly as the downgrade %s instead (readiness %s)." % [str(alt_m["name"]).capitalize(), OpsView.readiness_text(alt)])
	_notes.text = "\n".join(notes)
	_notes.add_theme_color_override("font_color", UiPalette.TEXT_DIM if _launch.has("vehicles") else UiPalette.DANGER)
	_case.queue_redraw()


## Auto-purchase on the manifest's action bar: go, or blocked with the reason.
func _set_actions(auto_text: String, auto_reason: String) -> void:
	UiAction.go_or_blocked(_auto, auto_text, auto_reason)


func _manifest_row(label: String, prog: SimProgram) -> void:
	var k := Label.new()
	k.text = label.to_upper()
	k.theme_type_variation = "Caps"
	k.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_manifest.add_child(k)
	var name := Label.new()
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name.text = prog.display_name().capitalize() if prog != null else "None"
	_manifest.add_child(name)
	if prog != null:
		var safety := StatChip.new("safety", "", "Safety of this program")
		safety.size_flags_horizontal = Control.SIZE_SHRINK_END
		safety.set_value("%d%%" % prog.safety, false, UiPalette.safety_color(prog.safety))
		_manifest.add_child(safety)
	else:
		_manifest.add_child(Control.new())
	var units := Label.new()
	units.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	units.custom_minimum_size.x = 70
	units.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	units.text = ("%d unit%s" % [prog.units, "" if prog.units == 1 else "s"]) if prog != null else "-"
	units.tooltip_text = "Units in inventory; each launch uses one"
	units.mouse_filter = Control.MOUSE_FILTER_PASS
	if prog != null and prog.units == 0:
		units.add_theme_color_override("font_color", UiPalette.DANGER)
	_manifest.add_child(units)


func _refresh_manifest(state: SimState, p: SimPlayer, pl: Dictionary, m: Dictionary) -> void:
	for c in _manifest.get_children():
		c.queue_free()
	for c in _choices.get_children():
		c.queue_free()
	var vehicles: Array = _launch.get("vehicles", [])
	for vi in vehicles.size():
		var v: Dictionary = vehicles[vi]
		if vehicles.size() > 1:
			var sub := Label.new()
			sub.text = "VEHICLE %d" % (vi + 1)
			sub.theme_type_variation = "CapsBright"
			_manifest.add_child(sub)
			for i in 3:
				_manifest.add_child(Control.new())
		var pay: Dictionary = v["payload"]
		_manifest_row("Primary", pay.get("capsule"))
		_manifest_row("Kicker", pay.get("kicker"))
		_manifest_row("L.M.", pay.get("lm"))
		var extras: Array = []
		for key in ["probe", "docking", "eva", "photo"]:
			if pay.get(key) != null:
				extras.append(pay[key])
		_manifest_row("Payload", extras[0] if not extras.is_empty() else null)
		for i in range(1, extras.size()):
			_manifest_row("", extras[i])
		_manifest_row("Rocket", v["rocket"])
		if v["boosters"] != null:
			_manifest_row("Boosters", v["boosters"])
	if vehicles.is_empty():
		for label in ["Primary", "Kicker", "L.M.", "Payload", "Rocket"]:
			_manifest_row(label, null)

	# Choices the plan allows: capsule and crews.
	var capsule_slot := -1
	if int(m["m_eq"]) > 0:
		var candidates: Array = SimPlanner._capsule_candidates(p, int(m["m_eq"]))
		var forced: int = int(pl.get("capsule_slot", AUTO_CAPSULE))
		if forced >= 0:
			var forced_prog: SimProgram = p.program("manned", forced)
			if forced_prog != null and forced_prog.owned and not candidates.has(forced_prog):
				candidates.append(forced_prog)
		if not vehicles.is_empty() and vehicles[0]["payload"]["capsule"] != null:
			capsule_slot = vehicles[0]["payload"]["capsule"].slot
		elif forced >= 0:
			capsule_slot = forced
		elif not candidates.is_empty():
			capsule_slot = candidates[0].slot
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		_choices.add_child(row)
		var cap_label := Label.new()
		cap_label.text = "CAPSULE"
		cap_label.theme_type_variation = "Caps"
		cap_label.custom_minimum_size.x = 120
		row.add_child(cap_label)
		var cap := OptionButton.new()
		cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cap.tooltip_text = "Which capsule flies. Automatic picks the safest one with a unit in inventory."
		cap.add_item("Automatic (safest)", AUTO_CAPSULE)
		for prog in candidates:
			cap.add_item("%s  %d%%  (%d unit%s)" % [prog.display_name().capitalize(), prog.safety, prog.units, "" if prog.units == 1 else "s"], prog.slot)
		cap.select(cap.get_item_index(forced) if forced >= 0 and cap.get_item_index(forced) >= 0 else 0)
		cap.item_selected.connect(func(idx: int): _set_capsule(pl, cap.get_item_id(idx)))
		row.add_child(cap)

	var n_vehicles: int = vehicles.size() if not vehicles.is_empty() else (2 if pl.get("joint", false) else 1)
	for vi in n_vehicles:
		var manned: bool = int(m["m_eq"]) > 0 and capsule_slot >= 0
		if not vehicles.is_empty():
			manned = not vehicles[vi]["crew"].is_empty() or (vehicles[vi]["payload"]["capsule"] != null and int(m["crew_mode"]) != 0)
		if not manned:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		_choices.add_child(row)
		var crew_label := Label.new()
		crew_label.text = "CREW" if n_vehicles == 1 else "CREW %d" % (vi + 1)
		crew_label.theme_type_variation = "Caps"
		crew_label.custom_minimum_size.x = 120
		row.add_child(crew_label)
		var opt := OptionButton.new()
		opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		opt.tooltip_text = "Which assigned crew flies%s" % ("" if n_vehicles == 1 else " in vehicle %d" % (vi + 1))
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
			opt.tooltip_text = "No crews are assigned to this capsule. Assign crews in the Astronaut Complex."
		elif opt.get_item_index(current) >= 0:
			opt.select(opt.get_item_index(current))
		else:
			opt.select(-1)
		opt.item_selected.connect(func(idx: int): _set_crew(pl, vi, opt.get_item_id(idx)))
		row.add_child(opt)


# ----------------------------------------------------------------- display case

func _draw_case() -> void:
	var size := _case.size
	_case.draw_rect(Rect2(Vector2.ZERO, size), CASE_BG)
	# Hangar floor line and a faint grid.
	for i in range(1, 8):
		_case.draw_line(Vector2(0, size.y * i / 8.0), Vector2(size.x, size.y * i / 8.0), Color(1, 1, 1, 0.03), 1.0)
	var floor_y := size.y * 0.9
	_case.draw_line(Vector2(size.x * 0.05, floor_y), Vector2(size.x * 0.95, floor_y), UiPalette.BORDER_SOFT, 2.0)
	var vehicles: Array = _launch.get("vehicles", [])
	if vehicles.is_empty():
		_case.draw_string(get_theme_default_font(), Vector2(0, size.y / 2.0), "Nothing on the pad", HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTheme.SIZE_SUBHEADING, UiPalette.TEXT_MUTED)
		return
	var side := Session.human_side
	var slot_w := size.x / vehicles.size()
	for vi in vehicles.size():
		var v: Dictionary = vehicles[vi]
		var x0 := slot_w * vi
		var top := size.y * 0.08
		var h := floor_y - top
		# Payload stack on the left half, rocket on the right half.
		var stack: Array = []
		for key in ["capsule", "lm", "kicker", "probe", "docking", "eva", "photo"]:
			var prog: SimProgram = v["payload"].get(key)
			if prog != null:
				stack.append(prog)
		var stack_w := slot_w * 0.42
		var rocket_w := slot_w * 0.42
		if not stack.is_empty():
			var item_h := minf(minf(h / stack.size(), stack_w), h * 0.36)
			var y := floor_y - item_h * stack.size()
			for prog in stack:
				var r := Rect2(x0 + slot_w * 0.06, y, stack_w, item_h).grow(-item_h * 0.06)
				HardwareArt.paint(_case, r, prog.group, prog.slot, side)
				y += item_h
		var rr := Rect2(x0 + slot_w * 0.54, top, rocket_w, h).grow(-h * 0.03)
		HardwareArt.paint(_case, rr, v["rocket"].group, v["rocket"].slot, side)
		if v["boosters"] != null:
			var br := Rect2(x0 + slot_w * 0.54 + rocket_w * 0.55, floor_y - h * 0.45, rocket_w * 0.45, h * 0.45)
			HardwareArt.paint(_case, br, v["boosters"].group, v["boosters"].slot, side)
		var font := get_theme_default_font()
		_case.draw_string(font, Vector2(x0, floor_y + 24), OpsView.rocket_name(v).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, slot_w, UiTheme.SIZE_SMALL, UiPalette.TEXT_DIM)


# ----------------------------------------------------------------- commands

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


func _on_scrub() -> void:
	if _pad < 0:
		return
	var state := Session.state()
	var p := Session.me()
	var m := SimPlanner.mission_def(state, int(p.missions[_pad]["mission_index"]))
	if await ConfirmBox.ask(self, "Scrub the mission?", "%s on Launch Facility %s comes off the pad. Hardware stays in inventory; scrubbing costs %d prestige." % [
			str(m["name"]).capitalize(), FACILITY[_pad], absi(SimGame.SCRUB_PRESTIGE)]):
		if Session.game.scrub(p, _pad):
			Session.notify_change()
			_refresh()


func _on_auto_purchase() -> void:
	if _pad < 0:
		return
	var state := Session.state()
	var p := Session.me()
	var pl = p.missions[_pad]
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
