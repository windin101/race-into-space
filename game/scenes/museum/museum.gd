extends ScreenPanel
## Space Museum: one hall per tab, each under a gold banner. The Hall of Firsts shows every
## prestige first with the mission patch that claimed it and the date; the Astronaut hall
## hangs the heroes as portrait tiles above the history table; director rating, mission
## records and hardware stay read-only tables.

const CASE_BG := Color("0a1424")
## [tab name, banner, help code, panel title]
const HALLS := [
	["Firsts", "HALL OF FIRSTS", "I029", "Exhibits"],
	["Director rating", "DIRECTOR RATING", "I030", "Directors"],
	["Mission records", "MISSION RECORDS", "I031", "Flights"],
	["Hardware", "HARDWARE EFFICIENCY", "I032", "Programmes"],
	["Astronauts", "ASTRONAUT HALL", "I033", "Corps"],
]

var _tabs: TabContainer
var _pages: Dictionary = {}       ## tab name -> the hall panel's body (VBoxContainer)
var _firsts_chips: HBoxContainer
var _firsts_grid: GridContainer
var _firsts_note: Label
var _rating: DataTable
var _missions: DataTable
var _hardware: DataTable
var _hero_scroll: ScrollContainer
var _heroes_row: HBoxContainer
var _astronauts: DataTable


## A mission patch (ArtAssets.patch) or, when none is painted, a plain roundel.
class PatchTile extends Control:
	var side := "usa"
	var index := -1

	func _init(p_size: float = 56.0) -> void:
		custom_minimum_size = Vector2(p_size, p_size)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func show_patch(p_side: String, p_index: int) -> void:
		side = p_side
		index = p_index
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var tex: Texture2D = ArtAssets.patch(side, index) if index >= 0 else null
		if tex != null:
			ArtAssets.draw_fit(self, tex, r)
			return
		var c := size / 2.0
		var rad := minf(size.x, size.y) * 0.46
		draw_circle(c, rad, Color("0a1424"))
		draw_arc(c, rad, 0.0, TAU, 32, UiPalette.BORDER_SOFT if index < 0 else UiPalette.accent(side), 2.0, true)
		draw_arc(c, rad * 0.7, 0.0, TAU, 32, UiPalette.BORDER_SOFT, 1.0, true)


## A crew portrait (PortraitArt.paint, file first) with the name on a band along the bottom.
class PortraitTile extends Control:
	var who := ""
	var female := false
	var side := "usa"
	var status := ""
	var caption := ""
	var caption_color := UiPalette.TEXT

	func _init(p_size := Vector2(120, 146)) -> void:
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
	title = "Space Museum"
	show_rival_prestige = true


func _ready() -> void:
	super()
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_tabs)
	for hall in HALLS:
		var page := VBoxContainer.new()
		page.name = hall[0]
		page.add_theme_constant_override("separation", 10)
		_tabs.add_child(page)
		page.add_child(_banner(hall[1]))
		var panel := UiPanel.new(hall[3], hall[2])
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		page.add_child(panel)
		_pages[hall[0]] = panel.body

	# Hall of Firsts: a tally per side, then two columns of exhibits, each with its patch.
	_firsts_chips = HBoxContainer.new()
	_firsts_chips.add_theme_constant_override("separation", 8)
	_pages["Firsts"].add_child(_firsts_chips)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_pages["Firsts"].add_child(scroll)
	_firsts_grid = GridContainer.new()
	_firsts_grid.columns = 2
	_firsts_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_firsts_grid.add_theme_constant_override("h_separation", 12)
	_firsts_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_firsts_grid)
	_firsts_note = Label.new()
	_firsts_note.theme_type_variation = "Dim"
	_firsts_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pages["Firsts"].add_child(_firsts_note)

	_rating = _table("Director rating", [
		{"key": "side", "title": "Side", "stretch": 2, "color": func(r): return UiPalette.accent(r["_side"]).lightened(0.3)},
		{"key": "director", "title": "Director", "stretch": 2},
		{"key": "level", "title": "Level"},
		{"key": "prestige", "title": "Prestige", "numeric": true},
		{"key": "score", "title": "Director score", "numeric": true},
		{"key": "review", "title": "Review index", "numeric": true},
	])
	_missions = _table("Mission records", [
		{"key": "when", "title": "Flight", "stretch": 1},
		{"key": "mission", "title": "Mission", "stretch": 3},
		{"key": "outcome", "title": "Outcome", "color": func(r): return UiPalette.OK if r["outcome"] == "Success" else UiPalette.DANGER},
		{"key": "prestige", "title": "Prestige", "numeric": true},
		{"key": "deaths", "title": "Deaths", "numeric": true},
	])
	_hardware = _table("Hardware", [
		{"key": "name", "title": "Program", "stretch": 2},
		{"key": "category", "title": "Category"},
		{"key": "flights", "title": "Flights", "numeric": true},
		{"key": "successes", "title": "Successes", "numeric": true},
		{"key": "failures", "title": "Failures", "numeric": true},
		{"key": "rate", "title": "Success rate", "numeric": true, "format": func(v): return "-" if int(v) < 0 else "%d%%" % int(v)},
		{"key": "safety", "title": "Safety", "numeric": true, "suffix": "%", "color": func(r): return UiPalette.safety_color(int(r["safety"]))},
	])

	# Astronaut hall: heroes as portrait tiles, then the history table.
	var heroes_title := Label.new()
	heroes_title.text = "HEROES"
	heroes_title.theme_type_variation = "Caps"
	_pages["Astronauts"].add_child(heroes_title)
	_hero_scroll = ScrollContainer.new()
	_hero_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_pages["Astronauts"].add_child(_hero_scroll)
	_heroes_row = HBoxContainer.new()
	_heroes_row.add_theme_constant_override("separation", 10)
	_hero_scroll.add_child(_heroes_row)
	_astronauts = _table("Astronauts", [
		{"key": "name", "title": "Name", "stretch": 2},
		{"key": "status", "title": "Status"},
		{"key": "flown", "title": "Missions", "numeric": true},
		{"key": "hero", "title": "Hero"},
		{"key": "mood", "title": "Mood", "numeric": true, "color": func(r): return UiPalette.mood_color(int(r["mood"]))},
	])
	set_room("room_museum")
	_refresh()


func _banner(text: String) -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "Sunken"
	var l := Label.new()
	l.text = text
	l.theme_type_variation = "Heading"
	l.add_theme_color_override("font_color", UiPalette.GOLD)
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	panel.add_child(l)
	return panel


func _table(hall: String, columns: Array) -> DataTable:
	var table := DataTable.new()
	table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table.tooltip_text = "Click a column heading to sort."
	table.set_columns(columns)
	_pages[hall].add_child(table)
	return table


func setup(_args: Dictionary) -> void:
	_refresh()


func on_resume() -> void:
	_refresh()


func _refresh() -> void:
	if not Session.has_game():
		return
	var state := Session.state()
	var me := Session.me()
	_refresh_firsts(state)
	_refresh_rating(state)
	_refresh_missions(me)
	_refresh_hardware(me)
	_refresh_astronauts(me)


func _side_label(state: SimState, index: int) -> String:
	return TurnLogic.side_name(state.player(index).side) if index >= 0 and index < state.players.size() else "-"


## The mission that claimed a row's first: the first side's flight that season, preferring
## the one whose award names the row. -1 when the log has no match (a chained first).
func _first_mission(state: SimState, row: int, first: int, year: int, season: int) -> int:
	if first < 0 or first >= state.players.size():
		return -1
	var fallback := -1
	for r in state.player(first).mission_log:
		if int(r.get("year", -1)) != year or int(r.get("season", -1)) != season:
			continue
		for aw in r.get("prestige", {}).get("awards", []):
			if int(aw.get("row", -1)) == row and str(aw.get("kind", "")) == "first":
				return int(r.get("mission_index", -1))
		if fallback < 0 and str(r.get("outcome", "")) == "success":
			fallback = int(r.get("mission_index", -1))
	return fallback


func _refresh_firsts(state: SimState) -> void:
	for c in _firsts_grid.get_children():
		c.queue_free()
	var claimed := 0
	for i in GameData.prestige.size():
		var def: Dictionary = GameData.prestige[i]
		var ledger: Dictionary = state.prestige_rows[i] if i < state.prestige_rows.size() else {}
		var first := int(ledger.get("first", -1))
		var year := int(ledger.get("first_year", 0))
		var season := int(ledger.get("first_season", 0))
		if first >= 0:
			claimed += 1
		var side: String = state.player(first).side if first >= 0 and first < state.players.size() else "usa"
		var mission := _first_mission(state, i, first, year, season)
		_firsts_grid.add_child(_first_exhibit(state, def, ledger, side, mission))
	for c in _firsts_chips.get_children():
		c.queue_free()
	for pi in state.players.size():
		var won := 0
		for i in GameData.prestige.size():
			var ledger: Dictionary = state.prestige_rows[i] if i < state.prestige_rows.size() else {}
			if int(ledger.get("first", -1)) == pi:
				won += 1
		var side: String = state.player(pi).side
		var chip := StatChip.new("star", "%s  %d" % [TurnLogic.side_name(side).to_upper(), won], "Firsts claimed by %s" % TurnLogic.side_name(side))
		chip.set_value("%s  %d" % [TurnLogic.side_name(side).to_upper(), won], false, UiPalette.accent(side).lightened(0.35))
		_firsts_chips.add_child(chip)
	_firsts_chips.add_child(StatChip.new("info", "UNCLAIMED  %d" % (GameData.prestige.size() - claimed), "Firsts nobody has claimed yet"))
	_firsts_note.text = "%d of %d firsts claimed. The number on each exhibit is the prestige paid for the first." % [claimed, GameData.prestige.size()]


func _first_exhibit(state: SimState, def: Dictionary, ledger: Dictionary, side: String, mission: int) -> Control:
	var first := int(ledger.get("first", -1))
	var panel := PanelContainer.new()
	panel.theme_type_variation = "Card"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var patch := PatchTile.new(56.0)
	patch.show_patch(side, mission if first >= 0 else -1)
	row.add_child(patch)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 0)
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(words)
	var name := Label.new()
	name.text = str(def.get("title", def.get("key", ""))).to_upper()
	name.theme_type_variation = "Subheading"
	name.clip_text = true
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	words.add_child(name)
	var sub := Label.new()
	sub.theme_type_variation = "Small"
	sub.clip_text = true
	sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var bits: PackedStringArray = []
	if mission >= 0:
		bits.append(TurnLogic.mission_name(mission))
	var second := int(ledger.get("second", -1))
	if second >= 0:
		bits.append("Second: %s" % _side_label(state, second))
	for later in ledger.get("others", []):
		bits.append("Then: %s" % _side_label(state, int(later)))
	sub.text = "  ·  ".join(bits) if not bits.is_empty() else ("Unclaimed" if first < 0 else "")
	sub.add_theme_color_override("font_color", UiPalette.TEXT_DIM)
	words.add_child(sub)
	var who := VBoxContainer.new()
	who.custom_minimum_size.x = 170
	who.alignment = BoxContainer.ALIGNMENT_CENTER
	who.add_theme_constant_override("separation", 0)
	row.add_child(who)
	var side_l := Label.new()
	side_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	side_l.clip_text = true
	side_l.text = _side_label(state, first) if first >= 0 else ""
	side_l.add_theme_color_override("font_color", UiPalette.accent(side).lightened(0.3) if first >= 0 else UiPalette.TEXT_MUTED)
	who.add_child(side_l)
	var when := Label.new()
	when.theme_type_variation = "Small"
	when.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	when.clip_text = true
	when.text = TurnLogic.date_of(int(ledger.get("first_year", 0)), int(ledger.get("first_season", 0))) if first >= 0 else "Not yet"
	when.add_theme_color_override("font_color", UiPalette.INFO if first >= 0 else UiPalette.TEXT_DIM)
	who.add_child(when)
	var pts := Label.new()
	pts.custom_minimum_size.x = 64
	pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pts.clip_text = true
	pts.text = "%d" % int(def.get("first", 0))
	pts.tooltip_text = "Prestige for the first"
	pts.theme_type_variation = "Subheading"
	pts.add_theme_color_override("font_color", UiPalette.GOLD if first >= 0 else UiPalette.TEXT_MUTED)
	row.add_child(pts)
	if first < 0:
		panel.modulate = Color(1, 1, 1, 0.75)
	return panel


func _refresh_rating(state: SimState) -> void:
	var rows: Array = []
	for p in state.players:
		rows.append({
			"side": TurnLogic.side_name(p.side), "director": p.director_name,
			"level": TurnLogic.level_name(p.level), "prestige": p.prestige_total,
			"score": SimReview.director_score(state, p), "review": p.review_index, "_side": p.side,
		})
	_rating.set_rows(rows)


func _refresh_missions(p: SimPlayer) -> void:
	var rows: Array = []
	for i in p.mission_log.size():
		var r: Dictionary = p.mission_log[i]
		var when := "#%d" % (i + 1)
		if r.has("year"):
			when = TurnLogic.date_of(int(r["year"]), int(r.get("season", 0)))
		rows.append({
			"when": when,
			"mission": TurnLogic.mission_name(int(r.get("mission_index", -1))),
			"outcome": str(r.get("outcome", "")).capitalize(),
			"prestige": int(r.get("prestige", {}).get("total", 0)),
			"deaths": int(r.get("deaths", 0)),
		})
	_missions.set_rows(rows)


func _refresh_hardware(p: SimPlayer) -> void:
	var rows: Array = []
	for prog in p.owned_programs():
		rows.append({
			"name": prog.display_name().capitalize(), "category": prog.group.capitalize(),
			"flights": prog.flights, "successes": prog.successes, "failures": prog.failures,
			"rate": int(100.0 * prog.successes / prog.flights) if prog.flights > 0 else -1,
			"safety": prog.safety,
		})
	_hardware.set_rows(rows)


func _refresh_astronauts(p: SimPlayer) -> void:
	var rows: Array = []
	for c in _heroes_row.get_children():
		c.queue_free()
	var heroes := 0
	for a in p.astronauts:
		rows.append({
			"name": a.name, "status": a.status_name().capitalize(), "flown": a.missions_flown,
			"hero": "Yes" if a.hero else "", "mood": a.mood,
		})
		if a.hero:
			heroes += 1
			var tile := PortraitTile.new(Vector2(120, 150))
			tile.who = a.name
			tile.female = a.female
			tile.side = p.side
			tile.status = a.status_name()
			tile.caption = a.name.to_upper()
			tile.caption_color = UiPalette.GOLD
			tile.tooltip_text = "%s: %d mission%s flown" % [a.name.capitalize(), a.missions_flown, "" if a.missions_flown == 1 else "s"]
			_heroes_row.add_child(tile)
	_hero_scroll.custom_minimum_size.y = 172 if heroes > 0 else 0
	if heroes == 0:
		var none := Label.new()
		none.text = "No heroes yet. Crews who claim the great manned firsts are honoured here."
		none.theme_type_variation = "Dim"
		_heroes_row.add_child(none)
	_astronauts.set_rows(rows)
