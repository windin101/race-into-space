extends ScreenPanel
## Space Museum: firsts, director rating, mission records, hardware efficiency and the
## astronaut history, each a tab of read-only tables.

var _tabs: TabContainer
var _firsts: DataTable
var _rating: DataTable
var _missions: DataTable
var _hardware: DataTable
var _astronauts: DataTable


func _init() -> void:
	super()
	title = "Space Museum"


func _ready() -> void:
	super()
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_tabs)

	_firsts = _tab("Firsts", [
		{"key": "title", "title": "Achievement", "stretch": 3},
		{"key": "first", "title": "First", "stretch": 2},
		{"key": "when", "title": "When", "stretch": 2},
		{"key": "second", "title": "Second", "stretch": 2},
		{"key": "points", "title": "First points", "numeric": true},
	], "I029")
	_rating = _tab("Director rating", [
		{"key": "side", "title": "Side", "stretch": 2},
		{"key": "director", "title": "Director", "stretch": 2},
		{"key": "level", "title": "Level"},
		{"key": "prestige", "title": "Prestige", "numeric": true},
		{"key": "score", "title": "Director score", "numeric": true},
		{"key": "review", "title": "Review index", "numeric": true},
	], "I030")
	_missions = _tab("Mission records", [
		{"key": "when", "title": "Flight", "stretch": 1},
		{"key": "mission", "title": "Mission", "stretch": 3},
		{"key": "outcome", "title": "Outcome", "color": func(r): return UiPalette.OK if r["outcome"] == "Success" else UiPalette.DANGER},
		{"key": "prestige", "title": "Prestige", "numeric": true},
		{"key": "deaths", "title": "Deaths", "numeric": true},
	], "I031")
	_hardware = _tab("Hardware", [
		{"key": "name", "title": "Program", "stretch": 2},
		{"key": "category", "title": "Category"},
		{"key": "flights", "title": "Flights", "numeric": true},
		{"key": "successes", "title": "Successes", "numeric": true},
		{"key": "failures", "title": "Failures", "numeric": true},
		{"key": "rate", "title": "Success rate", "numeric": true, "format": func(v): return "-" if int(v) < 0 else "%d%%" % int(v)},
		{"key": "safety", "title": "Safety", "numeric": true, "suffix": "%", "color": func(r): return UiPalette.safety_color(int(r["safety"]))},
	], "I032")
	_astronauts = _tab("Astronauts", [
		{"key": "name", "title": "Name", "stretch": 2},
		{"key": "status", "title": "Status"},
		{"key": "flown", "title": "Missions", "numeric": true},
		{"key": "hero", "title": "Hero"},
		{"key": "mood", "title": "Mood", "numeric": true, "color": func(r): return UiPalette.mood_color(int(r["mood"]))},
	], "I033")
	_refresh()


func _tab(name: String, columns: Array, help_code: String) -> DataTable:
	var table := DataTable.new()
	table.name = name
	table.set_columns(columns)
	_tabs.add_child(table)
	UiHelp.attach(table, help_code)
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


func _refresh_firsts(state: SimState) -> void:
	var rows: Array = []
	for i in GameData.prestige.size():
		var def: Dictionary = GameData.prestige[i]
		var ledger: Dictionary = state.prestige_rows[i] if i < state.prestige_rows.size() else {}
		var first := int(ledger.get("first", -1))
		rows.append({
			"title": str(def.get("title", def.get("key", ""))).capitalize(),
			"first": _side_label(state, first),
			"when": TurnLogic.date_of(int(ledger.get("first_year", 0)), int(ledger.get("first_season", 0))) if first >= 0 else "-",
			"second": _side_label(state, int(ledger.get("second", -1))),
			"points": int(def.get("first", 0)),
		})
	_firsts.set_rows(rows)


func _refresh_rating(state: SimState) -> void:
	var rows: Array = []
	for p in state.players:
		rows.append({
			"side": TurnLogic.side_name(p.side), "director": p.director_name,
			"level": TurnLogic.level_name(p.level), "prestige": p.prestige_total,
			"score": SimReview.director_score(state, p), "review": p.review_index,
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
	for a in p.astronauts:
		rows.append({
			"name": a.name, "status": a.status_name().capitalize(), "flown": a.missions_flown,
			"hero": "Yes" if a.hero else "", "mood": a.mood,
		})
	_astronauts.set_rows(rows)
