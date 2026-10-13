extends ScreenPanel
## Shows every widget with real data so layout and theme can be checked at any size.


func _init() -> void:
	super()
	title = "Widget gallery"


func _ready() -> void:
	super()
	var data = GameData
	var sim := SimState.new(data, 42)
	var p := sim.player(0)
	p.cash = 500
	for pair in [["rocket", 0], ["manned", 1], ["probe", 0], ["misc", 4]]:
		SimHardware.buy_program(sim, p, p.program(pair[0], pair[1]))
	p.program("rocket", 0).safety = 72
	p.program("manned", 1).safety = 48
	SimPersonnel.recruit(sim, p, ["GRISSOM", "SHEPARD", "GLENN", "CARPENTER"])

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 18)
	scroll.add_child(v)

	_add_style_guide(v, p)

	v.add_child(_heading("Type"))
	for variation in ["Title", "Heading", "Subheading", "", "Dim", "Small"]:
		var l := Label.new()
		l.theme_type_variation = variation
		l.text = "%s: The quick brown fox jumps over the lazy dog 0123456789" % (variation if variation != "" else "Body")
		v.add_child(l)

	v.add_child(_heading("Buttons"))
	var row := HBoxContainer.new()
	for variation in ["", "Accent", "Danger", "Flat"]:
		var b := Button.new()
		b.text = variation if variation != "" else "Default"
		b.theme_type_variation = variation
		row.add_child(b)
	var disabled := Button.new()
	disabled.text = "Disabled"
	disabled.disabled = true
	row.add_child(disabled)
	var opt := OptionButton.new()
	for o in ["Basic model", "Historical model", "Random model"]:
		opt.add_item(o)
	row.add_child(opt)
	var check := CheckButton.new()
	check.text = "Toggle"
	check.button_pressed = true
	row.add_child(check)
	v.add_child(row)

	v.add_child(_heading("Stat bars"))
	for pair in [["Safety", 88], ["Caution", 62], ["Danger", 35]]:
		v.add_child(StatBar.new(pair[0], pair[1]))

	v.add_child(_heading("Cards"))
	var cards := HFlowContainer.new()
	cards.add_theme_constant_override("h_separation", 12)
	cards.add_theme_constant_override("v_separation", 12)
	for prog in p.owned_programs():
		if prog.is_photo_recon():
			continue
		var hc := HardwareCard.new()
		hc.set_program(prog)
		cards.add_child(hc)
	var unowned := HardwareCard.new()
	unowned.set_program(p.program("rocket", 2))
	cards.add_child(unowned)
	for a in p.astronauts.slice(0, 3):
		var ac := AstronautCard.new()
		ac.set_astronaut(a)
		cards.add_child(ac)
	v.add_child(cards)

	v.add_child(_heading("Data table (click a header to sort)"))
	var table := DataTable.new()
	table.custom_minimum_size.y = 320
	table.set_columns([
		{"key": "name", "title": "Program", "stretch": 2},
		{"key": "kind", "title": "Type"},
		{"key": "safety", "title": "Safety", "numeric": true, "suffix": "%",
			"color": func(r): return UiPalette.safety_color(int(r["safety"]))},
		{"key": "max_rd", "title": "Max R&D", "numeric": true, "suffix": "%"},
		{"key": "cost", "title": "Program MB", "numeric": true},
		{"key": "unit", "title": "Unit MB", "numeric": true},
	])
	var rows: Array = []
	for prog in p.all_programs():
		rows.append({"name": prog.display_name().capitalize(), "kind": HardwareCard._kind_name(prog),
			"safety": prog.safety if prog.owned else prog.base_safety(), "max_rd": prog.max_rd,
			"cost": prog.program_cost(), "unit": prog.unit_cost()})
	table.set_rows(rows)
	table.sort_by("safety", true)
	v.add_child(table)

	v.add_child(_heading("Dialogs and help"))
	var dialog_row := HBoxContainer.new()
	var ask := Button.new()
	ask.text = "Confirm box"
	ask.pressed.connect(func():
		var yes = await ConfirmBox.ask(self, "Scrub the mission?", "Scrubbing costs 3 prestige. The hardware returns to inventory.")
		set_status("Confirmed" if yes else "Cancelled"))
	dialog_row.add_child(ask)
	var notice := Button.new()
	notice.text = "Notice"
	notice.pressed.connect(func(): ConfirmBox.notice(self, "Mission scrubbed", "The crew stands down."))
	dialog_row.add_child(notice)
	var help := Button.new()
	help.text = "Hover for help text"
	UiHelp.attach(help, "I003")
	dialog_row.add_child(help)
	v.add_child(dialog_row)

	var side := Button.new()
	side.text = "Switch side theme"
	side.pressed.connect(func():
		Session.human_side = "ussr" if Session.human_side == "usa" else "usa"
		get_tree().root.theme = UiTheme.get_theme(Session.human_side))
	footer.add_child(side)


## The style-guide components: panels with action bars, the four action kinds, stat
## chips, lamps, status lamps, both gauges and a story card.
func _add_style_guide(v: VBoxContainer, p: SimPlayer) -> void:
	v.add_child(_heading("Panels and actions"))
	var panels := HBoxContainer.new()
	panels.add_theme_constant_override("separation", 16)
	v.add_child(panels)
	var hw := UiPanel.new("Hardware", "I008")
	var hw_text := Label.new()
	hw_text.text = "A panel: title strip in caps with a help badge, a body, and a full-width action bar."
	hw_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hw_text.custom_minimum_size.x = 300
	hw.body.add_child(hw_text)
	hw.add_action("Purchase program (24 MB)", "go", func(): set_status("Purchased"))
	hw.add_action("Schedule", "caution", func(): set_status("Scheduled"))
	panels.add_child(hw)
	var blocked := UiPanel.new("Launch", "I003")
	var bl_text := Label.new()
	bl_text.text = "A blocked bar names the reason; clicking it explains in full."
	bl_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bl_text.custom_minimum_size.x = 300
	blocked.body.add_child(bl_text)
	blocked.add_action("Launch", "blocked", Callable(), "No capsule. Buy a capsule programme in Hardware Purchase first.")
	panels.add_child(blocked)
	var kinds := UiPanel.new("Action kinds")
	var kinds_row := VBoxContainer.new()
	kinds_row.add_theme_constant_override("separation", 8)
	kinds.body.add_child(kinds_row)
	for k in [["go", "Recruit", ""], ["caution", "Scrub", ""], ["blocked", "Research", "Not enough cash for a research roll."], ["neutral", "Spaceport", ""]]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(320, 40)
		UiAction.style(b, k[0], k[1], k[2])
		if k[2] == "":
			b.tooltip_text = "A %s action" % k[0]
		kinds_row.add_child(b)
	panels.add_child(kinds)

	v.add_child(_heading("Stat chips"))
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 10)
	chips.add_theme_constant_override("v_separation", 10)
	var samples := {"money": "%d MB" % p.cash, "pad": "2/3", "crew": "4/7", "review": "8", "star": "42",
		"teams": "3", "safety": "72%", "weight": "300", "seats": "2", "cost": "24 MB",
		"seasons": "3", "controllers": "2", "rocket": "Atlas", "date": "Spring 1961", "info": "Info"}
	for icon in samples:
		chips.add_child(StatChip.new(icon, samples[icon], icon.capitalize()))
	var blocking := StatChip.new("cost", "", "Cost: more than the cash on hand")
	blocking.set_value("900 MB", true)
	chips.add_child(blocking)
	v.add_child(chips)

	v.add_child(_heading("Lamps, status lamps and gauges"))
	var lamps_row := HBoxContainer.new()
	lamps_row.add_theme_constant_override("separation", 24)
	v.add_child(lamps_row)
	var lamp_col := VBoxContainer.new()
	lamp_col.add_theme_constant_override("separation", 6)
	for pair in [["Off", Lamp.State.OFF], ["Assigned", Lamp.State.ON], ["Weak", Lamp.State.WARN], ["Failed", Lamp.State.FAIL]]:
		var lamp := Lamp.new(pair[0], pair[1])
		lamp.tooltip_text = "Lamp: %s" % pair[0].to_lower()
		lamp.pressed.connect(func():
			lamp.set_state((lamp.state + 1) % 4))
		lamp_col.add_child(lamp)
	lamps_row.add_child(lamp_col)
	for level in [StatusLamps.Level.NOMINAL, StatusLamps.Level.WARNING, StatusLamps.Level.FAILURE]:
		var sl := StatusLamps.new()
		sl.set_level(level)
		lamps_row.add_child(sl)
	var vg := Gauge.new(true, "Safety (vertical gauge)")
	vg.value = 72
	lamps_row.add_child(vg)
	var hg_col := VBoxContainer.new()
	hg_col.add_theme_constant_override("separation", 10)
	for val in [88, 62, 35]:
		var hg := Gauge.new(false, "Reliability (horizontal gauge)")
		hg.value = val
		hg_col.add_child(hg)
	lamps_row.add_child(hg_col)

	v.add_child(_heading("Story card"))
	var story := Button.new()
	story.custom_minimum_size = Vector2(260, 40)
	UiAction.style(story, "go", "Show a story card")
	story.tooltip_text = "Open a sample story card for a historic first"
	story.pressed.connect(func():
		var side := Session.human_side
		await StoryCard.show_card(self, "First: Orbital satellite",
			"The first satellite circles the Earth. The programme gains 12 prestige.",
			ArtAssets.backdrop("endgame_%s_win" % side), side))
	story.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(story)


func _heading(text: String) -> Label:
	var l := Label.new()
	l.theme_type_variation = "Heading"
	l.text = text
	return l
