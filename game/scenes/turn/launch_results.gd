extends ScreenPanel
## Launch Results: one section per launch the human should see from the end-turn report:
## every launch of their own, and the rival's only when it claimed a prestige first.

var _report: Dictionary = {}
var _list: VBoxContainer
var _summary: Label


func _init() -> void:
	super()
	title = "Launch Results"
	show_back = false


func _ready() -> void:
	super()
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
	go.text = "Continue"
	go.theme_type_variation = "Accent"
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
		var none := Label.new()
		none.text = "No launches this season."
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list.add_child(none)
		return
	_summary.text = "%s: %d launch%s" % [date, shown.size(), "" if shown.size() == 1 else "es"]
	for launch in shown:
		_list.add_child(_section(launch))


func _section(launch: Dictionary) -> Control:
	var state := Session.state()
	var p: SimPlayer = state.player(int(launch.get("player", 0)))
	var card := PanelContainer.new()
	card.theme_type_variation = "Card"
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)

	var head := HBoxContainer.new()
	box.add_child(head)
	var name := Label.new()
	name.theme_type_variation = "Subheading"
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title_text := "%s: %s" % [TurnLogic.side_name(p.side), TurnLogic.mission_name(int(launch.get("mission_index", -1)))]
	if launch.has("downgraded_from"):
		title_text += "  (downgraded from %s)" % TurnLogic.mission_name(int(launch["downgraded_from"]))
	name.text = title_text
	head.add_child(name)
	var outcome := Label.new()
	var oc := str(launch.get("outcome", ""))
	outcome.text = oc.capitalize()
	outcome.add_theme_color_override("font_color", UiPalette.OK if oc == "success" else (UiPalette.WARN if oc == "scrubbed" else UiPalette.DANGER))
	head.add_child(outcome)

	if oc == "scrubbed":
		var why := Label.new()
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var reason := str(launch.get("reason", ""))
		why.text = "Scrubbed: %s. Scrubbing costs %d prestige." % [reason if reason != "" else "could not be assembled", -SimGame.SCRUB_PRESTIGE]
		box.add_child(why)
		return card

	var prestige: Dictionary = launch.get("prestige", {})
	var total := int(prestige.get("total", 0))
	var pl := Label.new()
	pl.text = "Prestige %+d" % total
	pl.add_theme_color_override("font_color", UiPalette.OK if total > 0 else (UiPalette.TEXT_DIM if total == 0 else UiPalette.DANGER))
	box.add_child(pl)
	for aw in prestige.get("awards", []):
		var row := int(aw.get("row", -1))
		var title_row := str(GameData.prestige[row]["title"]) if row >= 0 and row < GameData.prestige.size() else "Row %d" % row
		var al := Label.new()
		al.theme_type_variation = "Small"
		al.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		al.text = "  %s: %s %+d" % [title_row, str(aw.get("kind", "")), int(aw.get("points", 0))]
		box.add_child(al)

	var steps: Array = launch.get("steps", [])
	if not steps.is_empty():
		var table := DataTable.new()
		table.set_columns([
			{"key": "step", "title": "Step", "stretch": 2},
			{"key": "hardware", "title": "Hardware", "stretch": 2},
			{"key": "safety", "title": "Safety", "numeric": true, "suffix": "%"},
			{"key": "roll", "title": "Roll", "numeric": true},
			{"key": "result", "title": "Result", "color": func(r): return UiPalette.OK if r["result"] == "OK" else UiPalette.DANGER},
			{"key": "failure", "title": "Failure", "stretch": 3},
		])
		var rows: Array = []
		for s in steps:
			var f = s.get("failure")
			rows.append({
				"step": "%s %s" % [str(s.get("letter", "")), str(s.get("name", "")).capitalize()],
				"hardware": str(s.get("hardware", "")).capitalize(),
				"safety": int(s.get("safety", 0)), "roll": int(s.get("roll", 0)),
				"result": "OK" if s.get("success", false) else ("Saved" if s.get("save_card", false) else "Fail"),
				"failure": str(f.get("text", "")).capitalize() if f is Dictionary else "",
			})
		table.set_rows(rows)
		# Header button is about two row heights tall; show every step without inner scrolling.
		table.custom_minimum_size.y = DataTable.ROW_MIN_HEIGHT * (rows.size() + 2) + 12
		box.add_child(table)

	var crew: Dictionary = launch.get("crew_outcomes", {})
	if not crew.is_empty():
		var deaths := int(launch.get("deaths", 0))
		var cl := Label.new()
		cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var parts: PackedStringArray = []
		for id in crew:
			parts.append("%s (%s)" % [TurnLogic.astronaut_name(p, id), str(crew[id])])
		cl.text = "Crew: " + ", ".join(parts)
		if deaths > 0:
			cl.text += "   %d killed" % deaths
			cl.add_theme_color_override("font_color", UiPalette.DANGER)
		box.add_child(cl)
	return card
