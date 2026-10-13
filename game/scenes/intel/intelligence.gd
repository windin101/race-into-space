extends ScreenPanel
## Intelligence (CIA / KGB): what the human's agency believes about the rival programme.
## The agency seal heads the briefing; the selected rival programme stands in a display
## case with the estimate sheet beside it, and the full briefing table runs beneath.
## Safety figures are estimates: the true value plus deterministic noise inside the accuracy
## band for the human's difficulty, stable within a turn (TurnLogic.intel_estimates).

const CASE_BG := Color("0a1424")
const STRIP_H := 44.0   ## name strip across the foot of the case

var _table: DataTable
var _accuracy: Label
var _missions: VBoxContainer

var _programs: Array = []      ## rival SimPrograms in briefing order
var _estimates: Dictionary = {}
var _index := -1
var _rival_side := "ussr"
var _rival_pick := -1            ## player index of the rival being briefed (-1: the leader)
var _rival_tabs: HBoxContainer

var _banner: Label
var _case: Control
var _case_name: Label
var _prev: Button
var _next: Button
var _sheet: Dictionary = {}    ## key -> value Label
var _rival_sheet: Dictionary = {}
var _gauge: Gauge


func _init() -> void:
	super()
	title = "Intelligence"
	show_rival_prestige = true


func _ready() -> void:
	super()
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	content.add_child(head)
	var seal := ArtAssets.icon("intel_%s" % (Session.human_side if Session.has_game() else "usa"))
	if seal != null:
		var emblem := TextureRect.new()
		emblem.texture = seal
		emblem.custom_minimum_size = Vector2(80, 80)
		emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		head.add_child(emblem)
	_accuracy = Label.new()
	_accuracy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_accuracy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_accuracy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_accuracy)
	# One tab per rival when more than one side is racing against us.
	_rival_tabs = HBoxContainer.new()
	_rival_tabs.add_theme_constant_override("separation", 10)
	content.add_child(_rival_tabs)
	if Session.has_game() and Session.rivals().size() > 1:
		for r in Session.rivals():
			var b := Button.new()
			b.toggle_mode = true
			b.text = "%s PROGRAMME" % Sides.name(r.side).to_upper()
			b.theme_type_variation = "Bar"
			b.icon = ArtAssets.icon("flag_%s" % r.side)
			b.add_theme_constant_override("icon_max_width", 34)
			b.custom_minimum_size = Vector2(260, 44)
			b.tooltip_text = "Brief on the %s space programme" % Sides.adjective(r.side)
			b.set_meta("player", r.index)
			b.pressed.connect(func():
				_rival_pick = r.index
				_refresh())
			_rival_tabs.add_child(b)
	_rival_tabs.visible = _rival_tabs.get_child_count() > 0

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.size_flags_stretch_ratio = 1.3
	split.add_theme_constant_override("separation", 16)
	content.add_child(split)

	# Viewer for the selected rival programme, its name strip across the case foot.
	var left := UiPanel.new("Rival programme", "I027")
	left.size_flags_stretch_ratio = 1.1
	split.add_child(left)
	var banner_panel := PanelContainer.new()
	banner_panel.theme_type_variation = "Sunken"
	left.body.add_child(banner_panel)
	_banner = Label.new()
	_banner.theme_type_variation = "Heading"
	_banner.add_theme_color_override("font_color", UiPalette.GOLD)
	_banner.clip_text = true
	_banner.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	banner_panel.add_child(_banner)
	var case_panel := PanelContainer.new()
	case_panel.theme_type_variation = "Sunken"
	case_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.body.add_child(case_panel)
	_case = Control.new()
	_case.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_case.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_case.custom_minimum_size.y = 200
	_case.clip_contents = true
	_case.draw.connect(_draw_case)
	_case.resized.connect(_case.queue_redraw)
	case_panel.add_child(_case)
	var nav := HBoxContainer.new()
	nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav.offset_top = -STRIP_H
	nav.offset_left = 6
	nav.offset_right = -6
	nav.add_theme_constant_override("separation", 10)
	_case.add_child(nav)
	_prev = Button.new()
	_prev.text = "◀"
	_prev.theme_type_variation = "Flat"
	_prev.custom_minimum_size.x = 56
	_prev.tooltip_text = "Previous rival programme"
	_prev.pressed.connect(func(): _step(-1))
	nav.add_child(_prev)
	_case_name = Label.new()
	_case_name.theme_type_variation = "CapsBright"
	_case_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_case_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_case_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_case_name.size_flags_vertical = Control.SIZE_FILL
	_case_name.clip_text = true
	_case_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nav.add_child(_case_name)
	_next = Button.new()
	_next.text = "▶"
	_next.theme_type_variation = "Flat"
	_next.custom_minimum_size.x = 56
	_next.tooltip_text = "Next rival programme"
	_next.pressed.connect(func(): _step(1))
	nav.add_child(_next)

	# Estimate (with its gauge), the rival summary and recent missions.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.custom_minimum_size.x = 440
	right.add_theme_constant_override("separation", 12)
	split.add_child(right)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 12)
	right.add_child(cards)
	var est_panel := _sheet_card("Estimate", _sheet, [["category", "CATEGORY"], ["status", "STATUS"], ["range", "LIKELY RANGE"]])
	_gauge = Gauge.new(false, "Estimated safety")
	_gauge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	est_panel.body.add_child(_gauge)
	est_panel.body.move_child(_gauge, 0)
	cards.add_child(est_panel)
	cards.add_child(_sheet_card("Rival", _rival_sheet, [["side", "NATION"], ["prestige", "PRESTIGE"], ["pads", "LAUNCH PADS"], ["crew", "CREW"]]))
	var missions_panel := UiPanel.new("Recent missions", "I027")
	missions_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(missions_panel)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	missions_panel.body.add_child(scroll)
	_missions = VBoxContainer.new()
	_missions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_missions.add_theme_constant_override("separation", 4)
	scroll.add_child(_missions)

	# Briefing table beneath.
	var brief := UiPanel.new("Briefing", "I027")
	brief.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(brief)
	_table = DataTable.new()
	_table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_table.set_columns([
		{"key": "name", "title": "Program", "stretch": 2},
		{"key": "category", "title": "Category"},
		{"key": "status", "title": "Status", "color": func(r): return UiPalette.TEXT if r["status"] == "Active" else UiPalette.TEXT_MUTED},
		{"key": "safety", "title": "Est. safety", "numeric": true, "format": func(v): return "-" if int(v) < 0 else "%d%%" % int(v),
			"color": func(r): return UiPalette.safety_color(int(r["safety"])) if int(r["safety"]) >= 0 else UiPalette.TEXT_MUTED},
	])
	_table.row_selected.connect(_on_row)
	brief.body.add_child(_table)
	UiHelp.attach(_table, "I027")
	set_room("room_intel")
	_refresh()


func _sheet_card(heading: String, store: Dictionary, keys: Array) -> UiPanel:
	var card := UiPanel.new(heading, "I027")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 4)
	card.body.add_child(grid)
	for pair in keys:
		var k := Label.new()
		k.text = pair[1]
		k.theme_type_variation = "Caps"
		k.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		grid.add_child(k)
		var val := Label.new()
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(val)
		store[pair[0]] = val
	return card


func setup(_args: Dictionary) -> void:
	_refresh()


func on_resume() -> void:
	_refresh()


# ----------------------------------------------------------------- drawing

func _selected() -> SimProgram:
	return _programs[_index] if _index >= 0 and _index < _programs.size() else null


func _draw_case() -> void:
	var size := _case.size
	_case.draw_rect(Rect2(Vector2.ZERO, size), CASE_BG)
	var centre := size / 2.0
	for i in range(6, 0, -1):
		_case.draw_circle(centre, minf(size.x, size.y) * 0.08 * i, Color(UiPalette.accent(_rival_side), 0.025))
	var prog := _selected()
	if prog == null:
		_case.draw_string(get_theme_default_font(), Vector2(0, centre.y), "No programme on file", HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTheme.SIZE_SUBHEADING, UiPalette.TEXT_MUTED)
		_draw_strip()
		return
	var stage := Vector2(size.x, size.y - STRIP_H)
	var rect := Rect2(Vector2.ZERO, stage).grow(-minf(stage.x, stage.y) * 0.08)
	HardwareArt.paint(_case, rect, prog.group, prog.slot, _rival_side)
	_case.draw_line(Vector2(size.x * 0.15, stage.y - 8), Vector2(size.x * 0.85, stage.y - 8), UiPalette.BORDER_SOFT, 2.0)
	if not prog.owned:
		# No activity seen: the exhibit is shown greyed behind a stamp.
		_case.draw_rect(Rect2(Vector2.ZERO, size), Color(CASE_BG, 0.65))
		_case.draw_string(get_theme_default_font(), Vector2(0, centre.y), "NO ACTIVITY DETECTED", HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTheme.SIZE_SUBHEADING, UiPalette.TEXT_DIM)
	_draw_strip()


## The name strip's backing across the foot of the case.
func _draw_strip() -> void:
	var size := _case.size
	_case.draw_rect(Rect2(0, size.y - STRIP_H, size.x, STRIP_H), Color(0, 0, 0, 0.55))
	_case.draw_line(Vector2(0, size.y - STRIP_H), Vector2(size.x, size.y - STRIP_H), UiPalette.BORDER_SOFT, 1.0)


# ----------------------------------------------------------------- state

func _step(delta: int) -> void:
	if _programs.is_empty():
		return
	_index = posmod(_index + delta, _programs.size())
	_mark_row()
	_refresh_detail()


func _on_row(row: Dictionary) -> void:
	_index = _programs.find(row.get("_program"))
	_refresh_detail()


func _mark_row() -> void:
	var prog := _selected()
	for i in _table.rows.size():
		if _table.rows[i].get("_program") == prog:
			_table.select_index(i)


func _refresh() -> void:
	if not Session.has_game():
		return
	var state := Session.state()
	var me := Session.me()
	var rival := Session.rival()
	for r in Session.rivals():
		if r.index == _rival_pick:
			rival = r
	_rival_pick = rival.index
	for b in _rival_tabs.get_children():
		b.button_pressed = int(b.get_meta("player")) == rival.index
	_rival_side = rival.side
	var agency: String = TurnLogic.agency(me.side)
	title = "%s Intelligence" % agency
	_accuracy.text = "%s briefing on the %s programme. Estimates are accurate to within %d safety points (%d%% accuracy at %s level) and are refreshed each season." % [
		agency, TurnLogic.side_name(rival.side), TurnLogic.intel_max_deviation(me.level), TurnLogic.intel_accuracy(me.level), TurnLogic.level_name(me.level)]
	var estimates := TurnLogic.intel_estimates(state, rival, me.level)
	_estimates = estimates
	var previous := _selected()
	_programs = rival.all_programs()
	var rows: Array = []
	for prog in _programs:
		var key := "%s/%d" % [prog.group, prog.slot]
		rows.append({
			"name": prog.display_name().capitalize(),
			"category": prog.group.capitalize(),
			"status": "Active" if prog.owned else "Not started",
			"safety": int(estimates.get(key, -1)),
			"_program": prog,
		})
	_table.set_rows(rows)
	_index = _programs.find(previous)
	if _index < 0:
		for i in _programs.size():
			if _programs[i].owned:
				_index = i
				break
	if _index < 0 and not _programs.is_empty():
		_index = 0
	_mark_row()

	var living := 0
	for a in rival.astronauts:
		if a.is_alive():
			living += 1
	var crew_word := "%ss" % str(Sides.field(rival.side, "people", "astronaut")).capitalize()
	_rival_sheet["side"].text = TurnLogic.side_name(rival.side)
	_rival_sheet["prestige"].text = str(rival.prestige_total)
	_rival_sheet["pads"].text = str(rival.pad_count())
	_rival_sheet["crew"].text = "%d of %d" % [living, rival.astronauts.size()]
	_rival_sheet["crew"].tooltip_text = "%s alive, of the whole corps" % crew_word

	for c in _missions.get_children():
		c.queue_free()
	var log: Array = rival.mission_log
	for i in range(log.size() - 1, maxi(-1, log.size() - 7), -1):
		var idx := int(log[i].get("mission_index", -1))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var patch := TextureRect.new()
		patch.texture = ArtAssets.patch(rival.side, idx) if idx >= 0 else null
		patch.custom_minimum_size = Vector2(32, 32)
		patch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		patch.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(patch)
		var l := Label.new()
		l.text = TurnLogic.mission_name(idx)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.clip_text = true
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(l)
		_missions.add_child(row)
	if log.is_empty():
		var none := Label.new()
		none.text = "No missions flown yet."
		none.theme_type_variation = "Dim"
		_missions.add_child(none)
	_refresh_detail()


func _refresh_detail() -> void:
	_case.queue_redraw()
	_prev.disabled = _programs.size() < 2
	_next.disabled = _programs.size() < 2
	_prev.tooltip_text = "Only one programme on file" if _prev.disabled else "Previous rival programme"
	_next.tooltip_text = "Only one programme on file" if _next.disabled else "Next rival programme"
	var prog := _selected()
	if prog == null:
		_banner.text = "PROGRAM: -"
		_case_name.text = "NOTHING ON FILE"
		_gauge.value = 0
		_gauge.modulate.a = 0.4
		for key in _sheet:
			_sheet[key].text = "-"
		return
	_banner.text = "PROGRAM: %s" % prog.display_name().to_upper()
	_case_name.text = "%s   %s" % [prog.display_name().to_upper(), OpsView.kind_name(prog).to_upper()]
	_sheet["category"].text = prog.group.capitalize()
	_sheet["status"].text = "Active" if prog.owned else "Not started"
	var est := int(_estimates.get("%s/%d" % [prog.group, prog.slot], -1))
	var dev := TurnLogic.intel_max_deviation(Session.me().level)
	if est < 0:
		_gauge.value = 0
		_gauge.modulate.a = 0.4
		_gauge.label = "No safety estimate: no activity seen"
		_sheet["range"].text = "-"
	else:
		_gauge.value = est
		_gauge.modulate.a = 1.0
		_gauge.label = "Estimated safety %d%% (likely %d-%d%%)" % [est, clampi(est - dev, 1, 100), clampi(est + dev, 1, 100)]
		_sheet["range"].text = "%d-%d%%" % [clampi(est - dev, 1, 100), clampi(est + dev, 1, 100)]
