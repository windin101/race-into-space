extends ScreenPanel
## Intelligence (CIA / KGB): what the human's agency believes about the rival programme.
## Safety figures are estimates: the true value plus deterministic noise inside the accuracy
## band for the human's difficulty, stable within a turn (TurnLogic.intel_estimates).

var _table: DataTable
var _summary: Label
var _accuracy: Label
var _missions: Label


func _init() -> void:
	super()
	title = "Intelligence"


func _ready() -> void:
	super()
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	content.add_child(head)
	var seal := ArtAssets.icon("intel_%s" % (Session.human_side if Session.has_game() else "usa"))
	if seal != null:
		var emblem := TextureRect.new()
		emblem.texture = seal
		emblem.custom_minimum_size = Vector2(96, 96)
		emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		head.add_child(emblem)
	_accuracy = Label.new()
	_accuracy.theme_type_variation = "Dim"
	_accuracy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_accuracy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_accuracy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_accuracy)

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 16)
	content.add_child(split)
	_table = DataTable.new()
	_table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_table.size_flags_stretch_ratio = 2.0
	_table.set_columns([
		{"key": "name", "title": "Program", "stretch": 2},
		{"key": "category", "title": "Category"},
		{"key": "status", "title": "Status"},
		{"key": "safety", "title": "Est. safety", "numeric": true, "format": func(v): return "-" if int(v) < 0 else "%d%%" % int(v),
			"color": func(r): return UiPalette.safety_color(int(r["safety"])) if int(r["safety"]) >= 0 else UiPalette.TEXT_MUTED},
	])
	split.add_child(_table)
	UiHelp.attach(_table, "I027")

	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.custom_minimum_size.x = 300
	side.add_theme_constant_override("separation", 10)
	split.add_child(side)
	var card := PanelContainer.new()
	card.theme_type_variation = "Card"
	side.add_child(card)
	_summary = Label.new()
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(_summary)
	var mt := Label.new()
	mt.theme_type_variation = "Subheading"
	mt.text = "Recent missions"
	mt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(mt)
	_missions = Label.new()
	_missions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_missions.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_missions.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	side.add_child(_missions)
	_refresh()


func setup(_args: Dictionary) -> void:
	_refresh()


func on_resume() -> void:
	_refresh()


func _refresh() -> void:
	if not Session.has_game():
		return
	var state := Session.state()
	var me := Session.me()
	var rival := Session.rival()
	var agency: String = TurnLogic.AGENCY.get(me.side, "CIA")
	title = "%s Intelligence" % agency
	_accuracy.text = "%s briefing on the %s programme. Estimates are accurate to within %d safety points (%d%% accuracy at %s level) and are refreshed each season." % [
		agency, TurnLogic.side_name(rival.side), TurnLogic.intel_max_deviation(me.level), TurnLogic.intel_accuracy(me.level), TurnLogic.level_name(me.level)]
	var estimates := TurnLogic.intel_estimates(state, rival, me.level)
	var rows: Array = []
	for prog in rival.all_programs():
		var key := "%s/%d" % [prog.group, prog.slot]
		rows.append({
			"name": prog.display_name().capitalize(),
			"category": prog.group.capitalize(),
			"status": "Active" if prog.owned else "Not started",
			"safety": int(estimates.get(key, -1)),
		})
	_table.set_rows(rows)
	var living := 0
	for a in rival.astronauts:
		if a.is_alive():
			living += 1
	_summary.text = "%s\nPrestige: %d\nLaunch pads: %d\n%s: %d (%d in corps)" % [
		TurnLogic.side_name(rival.side), rival.prestige_total, rival.pad_count(),
		"Cosmonauts" if rival.side == "ussr" else "Astronauts", living, rival.astronauts.size()]
	var names: PackedStringArray = []
	var log: Array = rival.mission_log
	for i in range(log.size() - 1, maxi(-1, log.size() - 7), -1):
		names.append(TurnLogic.mission_name(int(log[i].get("mission_index", -1))))
	_missions.text = "\n".join(names) if not names.is_empty() else "No missions flown yet."
