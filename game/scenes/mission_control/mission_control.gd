extends ScreenPanel
## Mission Control, laid out like the original: three launch facility bays side by side,
## each showing the pad with this season's vehicle standing on it, the mission brief and
## readiness, and beneath it the rush, downgrade and scrub commands. The flag that ends
## the season is in the footer. Rules come from SimPlanner, OpsView and SimGame.

const FACILITY := ["A", "B", "C"]
const CASE_BG := Color("0a1424")
## Where the painted placeholder rocket stands in each side's pad_ok cutout, as a
## fraction of the image. That part of the picture is left out and the real vehicle is
## drawn in its place.
const ROCKET_HOLE := {
	"usa": Rect2(0.468, 0.134, 0.098, 0.487),
	"ussr": Rect2(0.478, 0.130, 0.098, 0.390),
}
## Height (fraction of the image) of the launch table the vehicle stands on.
const ROCKET_BASE := {"usa": 0.621, "ussr": 0.580}

var _bays: HBoxContainer
var _empty: Label
var _flag: Button


func _init() -> void:
	super()
	title = "Mission Control"


func _ready() -> void:
	super()
	_empty = Label.new()
	_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty.theme_type_variation = "Dim"
	content.add_child(_empty)
	_bays = HBoxContainer.new()
	_bays.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_bays.add_theme_constant_override("separation", 16)
	content.add_child(_bays)
	UiHelp.attach(_bays, "I010")
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
	for c in _bays.get_children():
		c.queue_free()
	var state := Session.state()
	var p := Session.me()
	_flag.disabled = state.ended
	var pads := OpsView.scheduled_pads(p)
	_empty.visible = pads.is_empty()
	if pads.is_empty():
		_empty.text = "No launches are scheduled for %s. Lower the flag to end the season, or plan next season's missions in the Future Missions Office." % state.date_string()
	for pad in 3:
		_bays.add_child(_make_bay(state, p, pad))


# ----------------------------------------------------------------- bays

func _make_bay(state: SimState, p: SimPlayer, pad: int) -> Control:
	var bay := VBoxContainer.new()
	bay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bay.add_theme_constant_override("separation", 8)

	var banner := PanelContainer.new()
	banner.theme_type_variation = "Sunken"
	bay.add_child(banner)
	var banner_label := Label.new()
	banner_label.theme_type_variation = "Heading"
	banner_label.add_theme_color_override("font_color", UiPalette.GOLD)
	banner_label.text = "LAUNCH FACILITY: %s" % FACILITY[pad]
	banner.add_child(banner_label)

	# What flies from this pad: a primary plan, the second vehicle of a joint plan, or nothing.
	var pl = p.missions[pad]
	var primary_pad := pad
	if pl != null and pl.get("part", 1) == 2:
		primary_pad = int(pl.get("primary_pad", pad - 1))
	var primary = p.missions[primary_pad] if pl != null else null
	var launch: Dictionary = {}
	if primary != null:
		launch = SimPlanner.assemble_with_downgrades(state, p, primary)
	var vehicle_index := 1 if primary_pad != pad else 0
	var vehicle: Dictionary = {}
	if launch.has("vehicles") and vehicle_index < launch["vehicles"].size():
		vehicle = launch["vehicles"][vehicle_index]

	var case_panel := PanelContainer.new()
	case_panel.theme_type_variation = "Sunken"
	case_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	case_panel.custom_minimum_size.y = 220
	bay.add_child(case_panel)
	var case := Control.new()
	case.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	case.size_flags_vertical = Control.SIZE_EXPAND_FILL
	case.clip_contents = true
	var side := p.side
	var pad_state: int = p.pads[pad]
	case.draw.connect(func(): paint_pad(case, Rect2(Vector2.ZERO, case.size), side, pad_state, vehicle))
	case.resized.connect(case.queue_redraw)
	case_panel.add_child(case)

	var brief := Label.new()
	brief.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	brief.add_theme_color_override("font_color", UiPalette.INFO)
	brief.custom_minimum_size.y = 140
	bay.add_child(brief)
	var ready_label := Label.new()
	ready_label.theme_type_variation = "Subheading"
	bay.add_child(ready_label)
	var notes := Label.new()
	notes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notes.theme_type_variation = "Small"
	notes.custom_minimum_size.y = 62
	bay.add_child(notes)

	# Commands board: rush, fly as, scrub. Always shown; disabled when they do not apply.
	var rush_title := _board_title(bay, "RUSH  (%d MB, -%d%% A MONTH)" % [SimPlanner.RUSH_COST_PER_MONTH, SimPlanner.RUSH_PENALTY_PER_MONTH])
	rush_title.tooltip_text = "Launch earlier in the season; each month costs cash and safety on every step."
	var rush_row := HBoxContainer.new()
	rush_row.add_theme_constant_override("separation", 6)
	bay.add_child(rush_row)
	var current_rush: int = int(primary.get("rush_months", 0)) if primary != null else -1
	var can_command: bool = pl != null and pl.get("part", 1) == 1 and not state.ended
	for months in range(0, SimPlanner.RUSH_MAX_MONTHS + 1):
		var b := Button.new()
		b.text = "No rush" if months == 0 else "%d month%s" % [months, "" if months == 1 else "s"]
		b.tooltip_text = OpsView.rush_label(months)
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.button_pressed = months == current_rush
		b.disabled = not can_command
		b.pressed.connect(_set_rush.bind(pad, months))
		rush_row.add_child(b)
	_board_title(bay, "FLY AS")
	var fly := OptionButton.new()
	fly.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fly.clip_text = true
	bay.add_child(fly)
	var scrub := Button.new()
	scrub.theme_type_variation = "Danger"
	scrub.text = "Scrub mission"
	scrub.disabled = not can_command
	scrub.pressed.connect(_on_scrub.bind(pad))
	bay.add_child(scrub)

	# Fill in the brief.
	var lines: PackedStringArray = []
	var bits: PackedStringArray = []
	if pad_state == SimPlayer.PAD_NONE:
		lines.append("STATUS: NOT BUILT")
		bits.append("Pads are built from the Launch Pad screens at the spaceport.")
	elif pl == null:
		lines.append("STATUS: %s" % ("IDLE" if pad_state == SimPlayer.PAD_OK else "DAMAGED"))
		lines.append("NO LAUNCH SCHEDULED")
		bits.append("Plan missions in the Future Missions Office in Administration.")
	else:
		var m := SimPlanner.mission_def(state, int(primary["mission_index"]))
		lines.append("MISSION: %s" % str(m["name"]).to_upper())
		if primary_pad != pad:
			lines.append("SECOND VEHICLE, FROM FACILITY %s" % FACILITY[primary_pad])
		lines.append("LAUNCH: %s" % OpsView.launch_month_name(state, p, primary_pad).to_upper())
		if not vehicle.is_empty():
			var names: PackedStringArray = []
			for item in OpsView.payload_items(vehicle):
				names.append(str(item["name"]).to_upper())
			lines.append("VEHICLE: %s" % OpsView.rocket_name(vehicle).to_upper())
			lines.append("PAYLOAD: %s" % (", ".join(names) if not names.is_empty() else "NONE"))
			var crew: PackedStringArray = []
			for a in vehicle["crew"]:
				crew.append(a.name.to_upper())
			lines.append("CREW: %s" % (", ".join(crew) if not crew.is_empty() else "UNMANNED"))
		if pad_state != SimPlayer.PAD_OK:
			lines.append("PAD DAMAGED")
	brief.text = "\n".join(lines)

	if pl != null and launch.has("vehicles"):
		ready_label.text = "Readiness  " + OpsView.readiness_text(launch)
		ready_label.add_theme_color_override("font_color", OpsView.readiness_color(launch))
		if launch.has("downgraded_from"):
			bits.append("Hardware is missing for the plan; it would fly as the downgrade %s." % str(SimPlanner.mission_def(state, int(launch["mission_index"]))["name"]).capitalize())
		bits.append("Penalties on every step: requirements -%d%%, lunar module -%d%%, rush -%d%%." % [
			int(launch["requirement_penalty"]), int(launch["lm_penalty"]), int(launch["rush_penalty"])])
	elif pl != null:
		ready_label.text = "Cannot fly"
		ready_label.add_theme_color_override("font_color", UiPalette.DANGER)
		bits.append("Not assembled: %s. It will be scrubbed at the end of the season." % launch.get("reason", "unknown"))
	else:
		ready_label.text = "Readiness  -"
		ready_label.add_theme_color_override("font_color", UiPalette.TEXT_MUTED)
	if pl != null and pl.get("part", 1) == 1 and pl.get("joint", false):
		bits.append("Joint mission; the second vehicle flies from Facility %s." % FACILITY[mini(pad + 1, 2)])
	elif primary_pad != pad:
		bits.append("Rush, downgrade and scrub are commanded from Facility %s." % FACILITY[primary_pad])
	notes.text = "\n".join(bits)

	if primary != null:
		var options := OpsView.downgrade_options(state, primary)
		for alt in options:
			fly.add_item(str(SimPlanner.mission_def(state, int(alt))["name"]).capitalize(), int(alt))
		fly.select(fly.get_item_index(int(primary["mission_index"])))
		fly.tooltip_text = "Downgrade chain: " + " > ".join(PackedStringArray(options.map(func(alt): return str(SimPlanner.mission_def(state, int(alt))["name"]).capitalize()))) + "."
		fly.item_selected.connect(func(idx: int): _set_mission(pad, fly.get_item_id(idx)))
	else:
		fly.add_item("No mission")
	fly.disabled = not can_command or fly.item_count < 2
	return bay


func _board_title(parent: Control, text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = "Subheading"
	l.add_theme_color_override("font_color", UiPalette.GOLD)
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(l)
	return l


# ----------------------------------------------------------------- pad painting

## The launch pad display case: the side's pad cutout for the pad's state (site, ready or
## damaged) on the case background, with `vehicle` (an assembled vehicle, or {}) standing
## on it in place of the painted placeholder rocket. Shared with the Launch Pad screen.
static func paint_pad(c: CanvasItem, rect: Rect2, side: String, pad_state: int, vehicle: Dictionary) -> void:
	c.draw_rect(rect, CASE_BG)
	var centre := rect.get_center()
	for i in range(6, 0, -1):
		c.draw_circle(centre, minf(rect.size.x, rect.size.y) * 0.08 * i, Color(UiPalette.accent(side), 0.025))
	var floor_y := rect.end.y - rect.size.y * 0.05
	c.draw_line(Vector2(rect.position.x + rect.size.x * 0.08, floor_y), Vector2(rect.end.x - rect.size.x * 0.08, floor_y), UiPalette.BORDER_SOFT, 2.0)
	var layer := "pad_ok"
	if pad_state == SimPlayer.PAD_NONE:
		layer = "pad_site"
	elif pad_state != SimPlayer.PAD_OK:
		layer = "pad_damaged"
	var tex := ArtAssets.spaceport_layer(side, layer)
	var area := Rect2(rect.position.x + rect.size.x * 0.04, rect.position.y + rect.size.y * 0.04, rect.size.x * 0.92, floor_y - rect.position.y - rect.size.y * 0.04)
	var stand := Rect2()   # where the vehicle stands, in case coordinates
	if tex == null:
		# Procedural pad: a slab and a gantry.
		var slab := Rect2(area.position.x + area.size.x * 0.15, area.end.y - area.size.y * 0.12, area.size.x * 0.7, area.size.y * 0.12)
		c.draw_rect(slab, UiPalette.PANEL_RAISED)
		if layer != "pad_site":
			c.draw_rect(Rect2(slab.position.x + slab.size.x * 0.25, area.position.y + area.size.y * 0.2, slab.size.x * 0.06, slab.position.y - area.position.y - area.size.y * 0.2), UiPalette.BORDER)
		stand = Rect2(slab.position.x + slab.size.x * 0.4, area.position.y + area.size.y * 0.1, slab.size.x * 0.25, slab.position.y - area.position.y - area.size.y * 0.1)
	else:
		var ts := tex.get_size()
		var scale := minf(area.size.x / ts.x, area.size.y / ts.y)
		var size := ts * scale
		var dest := Rect2(Vector2(area.get_center().x - size.x / 2.0, area.end.y - size.y), size)
		if layer == "pad_ok" and ROCKET_HOLE.has(side):
			var hole: Rect2 = ROCKET_HOLE[side]
			# Draw the picture in four pieces around the placeholder rocket.
			var cols := [0.0, hole.position.x, hole.end.x, 1.0]
			var rows := [0.0, hole.position.y, hole.end.y, 1.0]
			for ci in 3:
				for ri in 3:
					if ci == 1 and ri == 1:
						continue
					var src := Rect2(Vector2(cols[ci], rows[ri]) * ts, Vector2(cols[ci + 1] - cols[ci], rows[ri + 1] - rows[ri]) * ts)
					var dst := Rect2(dest.position + Vector2(cols[ci], rows[ri]) * size, Vector2(cols[ci + 1] - cols[ci], rows[ri + 1] - rows[ri]) * size)
					c.draw_texture_rect_region(tex, dst, src)
			var base_y: float = ROCKET_BASE.get(side, hole.end.y)
			stand = Rect2(dest.position + hole.position * size, Vector2(hole.size.x, base_y - hole.position.y) * size)
		else:
			c.draw_texture_rect(tex, dest, false)
			stand = Rect2(dest.position + Vector2(0.45, 0.15) * size, Vector2(0.1, 0.45) * size)
	if vehicle.is_empty() or layer != "pad_ok":
		return
	# The rocket stands in the hole; boosters beside it; the payload hangs in the sky
	# above the service building, as the original's pad shot showed the stack.
	var base := Vector2(stand.get_center().x, stand.end.y)
	var tall := stand.size.y * 1.08
	var rocket: SimProgram = vehicle["rocket"]
	if vehicle["boosters"] != null:
		var boosters: SimProgram = vehicle["boosters"]
		_paint_standing(c, base + Vector2(-tall * 0.32, 0), Vector2(tall * 0.5, tall * 0.55), boosters.group, boosters.slot, side)
	_paint_standing(c, base, Vector2(tall * 0.9, tall), rocket.group, rocket.slot, side)
	var items := OpsView.payload_items(vehicle)
	if items.is_empty():
		return
	var px := stand.end.x + stand.size.y * 0.35
	var pw := minf(rect.end.x - px - rect.size.x * 0.03, stand.size.y * 0.42)
	if pw < 16.0:
		return
	var py := rect.position.y + rect.size.y * 0.06
	var ph := minf(pw, stand.size.y * 0.9 / items.size())
	for item in items:
		var prog: SimProgram = item["program"]
		HardwareArt.paint(c, Rect2(px, py, pw, ph), prog.group, prog.slot, side)
		py += ph


## Hardware art scaled to fit `max_size` with its foot on `base` (the art files carry a
## little transparent margin, so the picture is nudged down onto the base line).
static func _paint_standing(c: CanvasItem, base: Vector2, max_size: Vector2, group: String, slot: int, side: String) -> void:
	var tex := ArtAssets.hardware(side, group, slot)
	if tex == null:
		HardwareArt.paint(c, Rect2(base - Vector2(max_size.x / 2.0, max_size.y), max_size), group, slot, side)
		return
	var ts := tex.get_size()
	var scale := minf(max_size.x / ts.x, max_size.y / ts.y)
	var size := ts * scale
	HardwareArt.paint(c, Rect2(Vector2(base.x - size.x / 2.0, base.y - size.y * 0.955), size), group, slot, side)


# ----------------------------------------------------------------- commands

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
	var m := SimPlanner.mission_def(Session.state(), int(p.missions[pad]["mission_index"]))
	if await ConfirmBox.ask(self, "Scrub the mission?", "%s on Launch Facility %s comes off the pad. Hardware stays in inventory; scrubbing costs %d prestige." % [
			str(m["name"]).capitalize(), FACILITY[pad], absi(SimGame.SCRUB_PRESTIGE)]):
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
