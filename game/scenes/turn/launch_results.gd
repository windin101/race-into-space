extends ScreenPanel
## Launch Results: one card per launch the human should see from the end-turn report
## (every launch of their own, and the rival's only when it claimed a prestige first).
## Each card is headed by the mission patch and name, lists the mission steps as lines
## coloured by outcome, and shows the crew as portrait tiles.

const CASE_BG := Color("0a1424")

var _report: Dictionary = {}
var _list: VBoxContainer
var _summary: Label


## A mission patch (ArtAssets.patch) or, when none is painted, a plain roundel.
class PatchTile extends Control:
	var side := "usa"
	var index := -1

	func _init(p_size: float = 84.0) -> void:
		custom_minimum_size = Vector2(p_size, p_size)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var tex: Texture2D = ArtAssets.patch(side, index) if index >= 0 else null
		if tex != null:
			ArtAssets.draw_fit(self, tex, r)
			return
		var c := size / 2.0
		var rad := minf(size.x, size.y) * 0.46
		draw_circle(c, rad, Color("0a1424"))
		draw_arc(c, rad, 0.0, TAU, 40, UiPalette.accent(side), 3.0, true)
		draw_arc(c, rad * 0.7, 0.0, TAU, 40, UiPalette.BORDER_SOFT, 1.0, true)


## A crew portrait (PortraitArt.paint, file first) with the name on a band along the bottom.
class PortraitTile extends Control:
	var who := ""
	var female := false
	var side := "usa"
	var status := ""
	var caption := ""
	var caption_color := UiPalette.TEXT

	func _init(p_size := Vector2(112, 138)) -> void:
		custom_minimum_size = p_size
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color("0a1424"))
		PortraitArt.paint(self, r, who, female, side, status)
		if caption != "":
			draw_rect(Rect2(0, size.y - 24, size.x, 24), Color(0, 0, 0, 0.6))
			draw_string(get_theme_default_font(), Vector2(2, size.y - 7), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x - 4, UiTheme.SIZE_SMALL, caption_color)


func _init() -> void:
	super()
	title = "Launch Results"
	show_back = false


func _ready() -> void:
	super()
	set_room("mission_control_" + (Session.human_side if Session.has_game() else "usa"))
	_summary = Label.new()
	_summary.theme_type_variation = "Dim"
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_summary)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 14)
	scroll.add_child(_list)
	UiHelp.attach(scroll, "I016")
	var go := Button.new()
	go.custom_minimum_size = Vector2(170, 40)
	UiAction.style(go, "go", "Continue")
	go.tooltip_text = "On to the season's news"
	go.pressed.connect(func(): Screens.pop())
	footer.add_child(go)
	_refresh()


func setup(args: Dictionary) -> void:
	var r = args.get("report", {})
	_report = r if r is Dictionary else {}
	_refresh()


func on_resume() -> void:
	_refresh()


func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	if not Session.has_game():
		_summary.text = "No game in progress."
		return
	var me := Session.me()
	var shown := TurnLogic.visible_launches(_report, me.index)
	var date := str(_report.get("date", Session.state().date_string()))
	if shown.is_empty():
		_summary.text = "%s: no launches to report." % date
		var panel := UiPanel.new("Launch results", "I016")
		_list.add_child(panel)
		var banner := PanelContainer.new()
		banner.theme_type_variation = "Sunken"
		panel.body.add_child(banner)
		var none := Label.new()
		none.text = "NO LAUNCHES THIS SEASON"
		none.theme_type_variation = "Heading"
		none.add_theme_color_override("font_color", UiPalette.GOLD)
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		banner.add_child(none)
		return
	_summary.text = "%s: %d launch%s" % [date, shown.size(), "" if shown.size() == 1 else "es"]
	for launch in shown:
		_list.add_child(_section(launch))


static func _outcome_color(oc: String) -> Color:
	return UiPalette.OK if oc == "success" else (UiPalette.WARN if oc == "scrubbed" else UiPalette.DANGER)


func _section(launch: Dictionary) -> Control:
	var state := Session.state()
	var p: SimPlayer = state.player(int(launch.get("player", 0)))
	var mission := int(launch.get("mission_index", -1))
	var oc := str(launch.get("outcome", ""))
	var card := UiPanel.new("%s launch" % TurnLogic.side_name(p.side), "I016")
	var box := card.body

	# Head: patch, mission name banner, side and outcome.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	box.add_child(head)
	var patch := PatchTile.new(84.0)
	patch.side = p.side
	patch.index = mission
	head.add_child(patch)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 2)
	head.add_child(words)
	var banner := PanelContainer.new()
	banner.theme_type_variation = "Sunken"
	words.add_child(banner)
	var name := Label.new()
	name.theme_type_variation = "Heading"
	name.add_theme_color_override("font_color", UiPalette.GOLD)
	name.clip_text = true
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name.text = TurnLogic.mission_name(mission).to_upper()
	banner.add_child(name)
	if launch.has("downgraded_from"):
		var sub := Label.new()
		sub.theme_type_variation = "Small"
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub.text = "DOWNGRADED FROM %s" % TurnLogic.mission_name(int(launch["downgraded_from"])).to_upper()
		sub.add_theme_color_override("font_color", UiPalette.WARN)
		words.add_child(sub)
	var awards := HFlowContainer.new()
	awards.add_theme_constant_override("h_separation", 18)
	awards.add_theme_constant_override("v_separation", 0)
	words.add_child(awards)
	var outcome := Lamp.new(oc, Lamp.State.ON if oc == "success" else (Lamp.State.WARN if oc == "scrubbed" else Lamp.State.FAIL))
	outcome.mouse_filter = Control.MOUSE_FILTER_PASS
	outcome.custom_minimum_size = Vector2(170, 40)
	outcome.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	outcome.tooltip_text = "Mission outcome: %s" % oc
	head.add_child(outcome)

	if oc == "scrubbed":
		var why := Label.new()
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		why.add_theme_color_override("font_color", UiPalette.INFO)
		var reason := str(launch.get("reason", ""))
		why.text = ("Scrubbed: %s. Scrubbing costs %d prestige." % [reason if reason != "" else "could not be assembled", -SimGame.SCRUB_PRESTIGE]).to_upper()
		box.add_child(why)
		return card

	# Brief: prestige and its awards, flowed under the mission name.
	var prestige: Dictionary = launch.get("prestige", {})
	var total := int(prestige.get("total", 0))
	var pl := Label.new()
	pl.text = "PRESTIGE %+d" % total
	pl.theme_type_variation = "Small"
	pl.add_theme_color_override("font_color", UiPalette.INFO if total > 0 else (UiPalette.TEXT_DIM if total == 0 else UiPalette.DANGER))
	awards.add_child(pl)
	for aw in prestige.get("awards", []):
		var row := int(aw.get("row", -1))
		var title_row := str(GameData.prestige[row]["title"]) if row >= 0 and row < GameData.prestige.size() else "Row %d" % row
		var al := Label.new()
		al.theme_type_variation = "Small"
		var kind := str(aw.get("kind", ""))
		al.text = "%s: %s %+d" % [title_row.to_upper(), kind.to_upper(), int(aw.get("points", 0))]
		al.add_theme_color_override("font_color", UiPalette.GOLD if kind == "first" else UiPalette.INFO)
		awards.add_child(al)

	# Body: step lines on the left, crew tiles on the right.
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 20)
	box.add_child(body)
	var steps: Array = launch.get("steps", [])
	var steps_panel := PanelContainer.new()
	steps_panel.theme_type_variation = "Sunken"
	steps_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(steps_panel)
	steps_panel.add_child(_steps_grid(steps))

	var crew: Dictionary = launch.get("crew_outcomes", {})
	if not crew.is_empty():
		var crew_box := VBoxContainer.new()
		crew_box.add_theme_constant_override("separation", 6)
		body.add_child(crew_box)
		var ct := Label.new()
		ct.text = "CREW"
		ct.theme_type_variation = "Caps"
		crew_box.add_child(ct)
		var tiles := HBoxContainer.new()
		tiles.add_theme_constant_override("separation", 8)
		crew_box.add_child(tiles)
		for id in crew:
			tiles.add_child(_crew_tile(p, id, str(crew[id])))
		var deaths := int(launch.get("deaths", 0))
		if deaths > 0:
			var dl := Label.new()
			dl.text = "%d KILLED" % deaths
			dl.add_theme_color_override("font_color", UiPalette.DANGER)
			crew_box.add_child(dl)
	return card


## One line per mission step: letter and name, hardware, safety, roll, result and any
## failure text, the whole line in the outcome's colour.
func _steps_grid(steps: Array) -> Control:
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 4)
	if steps.is_empty():
		var none := Label.new()
		none.text = "No steps flown."
		none.theme_type_variation = "Dim"
		grid.columns = 1
		grid.add_child(none)
		return grid
	for h in ["STEP", "HARDWARE", "SAFETY", "ROLL", "RESULT", "FAILURE"]:
		var l := Label.new()
		l.text = h
		l.theme_type_variation = "Caps"
		if h in ["SAFETY", "ROLL"]:
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(l)
	for s in steps:
		var f = s.get("failure")
		var ok: bool = s.get("success", false)
		var saved: bool = s.get("save_card", false)
		var result := "OK" if ok else ("SAVED" if saved else "FAIL")
		var col := UiPalette.OK if ok else (UiPalette.WARN if saved else UiPalette.DANGER)
		var cells := [
			"%s  %s" % [str(s.get("letter", "")), str(s.get("name", "")).capitalize()],
			str(s.get("hardware", "")).capitalize(),
			"%d%%" % int(s.get("safety", 0)),
			str(int(s.get("roll", 0))),
			result,
			str(f.get("text", "")).capitalize() if f is Dictionary else "",
		]
		for i in cells.size():
			if i == 4:
				var lamp := Lamp.new(result, Lamp.State.ON if ok else (Lamp.State.WARN if saved else Lamp.State.FAIL))
				lamp.custom_minimum_size = Vector2(96, 28)
				lamp.mouse_filter = Control.MOUSE_FILTER_PASS
				lamp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				lamp.tooltip_text = "Step %s: %s" % [str(s.get("letter", "")), "succeeded" if ok else ("failed, saved by a save card" if saved else "failed")]
				grid.add_child(lamp)
				continue
			var l := Label.new()
			l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			l.text = cells[i]
			l.add_theme_color_override("font_color", col if i != 1 else col.lerp(UiPalette.TEXT, 0.5))
			if i == 2 or i == 3:
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			if i == 5:
				l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				l.theme_type_variation = "Small"
				l.custom_minimum_size.x = 160
			grid.add_child(l)
	return grid


func _crew_tile(p: SimPlayer, id, outcome: String) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	var tile := PortraitTile.new()
	var i := int(id)
	var a: SimAstronaut = p.astronauts[i] if i >= 0 and i < p.astronauts.size() else null
	tile.who = a.name if a != null else TurnLogic.astronaut_name(p, id)
	tile.female = a.female if a != null else false
	tile.side = p.side
	tile.status = a.status_name() if a != null else ""
	tile.caption = TurnLogic.astronaut_name(p, id).to_upper()
	tile.tooltip_text = "%s: %s" % [TurnLogic.astronaut_name(p, id).capitalize(), outcome]
	v.add_child(tile)
	var ol := Label.new()
	ol.text = outcome.to_upper()
	ol.theme_type_variation = "Small"
	ol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ol.clip_text = true
	ol.custom_minimum_size.x = tile.custom_minimum_size.x
	var good := outcome == "ok" or outcome == "success"
	ol.add_theme_color_override("font_color", UiPalette.OK if good else (UiPalette.DANGER if outcome == "dead" else UiPalette.WARN))
	v.add_child(ol)
	return v
