extends ScreenPanel
## The memorial (the original's Cemetery / Kremlin Wall, spaceport overlay 3): a plaque
## for every member of your programme who has died, with when and how. Women's names are
## shown in light blue, as on the original's wall.

const PLAQUE_W := 300.0
const PORTRAIT := Vector2(84, 100)
const CASE_BG := Color("0a1424")

var _grid: GridContainer
var _empty: Label
var _count: Label


## The fallen of a player's programme as rows for the plaques, earliest death first:
## {name, female, hero, year, season, mission_index, flights}.
static func fallen(p: SimPlayer) -> Array:
	var out: Array = []
	for a in p.astronauts:
		if a.status != SimAstronaut.Status.DEAD:
			continue
		var when := {"year": 0, "season": 0, "mission_index": -1}
		var flights := 0
		for h in a.mission_history:
			if int(h.get("mission_index", -1)) >= 0 and h.get("outcome", "") != "scrubbed":
				flights += 1
			if h.get("outcome", "") == "dead":
				when = h
		out.append({"astronaut": a, "name": a.name, "female": a.female, "hero": a.hero,
			"year": int(when.get("year", 0)), "season": int(when.get("season", 0)),
			"mission_index": int(when.get("mission_index", -1)), "flights": flights})
	out.sort_custom(func(x, y): return x["year"] * 2 + x["season"] < y["year"] * 2 + y["season"])
	return out


## How a plaque says they died: the mission's name, or on duty for a newscast loss.
static func cause(row: Dictionary) -> String:
	var mi: int = row["mission_index"]
	if mi < 0:
		return "Died on duty"
	return "Lost on %s" % TurnLogic.mission_name(mi)


func _init() -> void:
	super()
	title = "Memorial"


func _ready() -> void:
	super()
	var side := Session.human_side if Session.has_game() else "usa"
	title = "%s Memorial" % str(Sides.field(side, "people", "astronaut")).capitalize()
	var panel := UiPanel.new("In memory", "I020")
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(panel)
	_count = Label.new()
	_count.theme_type_variation = "Heading"
	_count.add_theme_color_override("font_color", UiPalette.GOLD)
	panel.body.add_child(_count)
	_empty = Label.new()
	_empty.theme_type_variation = "Dim"
	_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.body.add_child(_empty)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.body.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(_grid)
	resized.connect(_fit_columns)

	var go := Button.new()
	go.custom_minimum_size = Vector2(170, 40)
	UiAction.style(go, "go", "Continue")
	go.tooltip_text = "Back to the spaceport"
	go.pressed.connect(func(): Screens.pop())
	footer.add_child(go)
	set_room("room_museum")
	_refresh()


func _fit_columns() -> void:
	if _grid:
		_grid.columns = maxi(1, int((size.x - 80.0) / (PLAQUE_W + 14.0)))


func _refresh() -> void:
	for c in _grid.get_children():
		c.queue_free()
	if not Session.has_game():
		return
	var people: String = str(Sides.field(Session.me().side, "people", "astronaut"))
	var rows := fallen(Session.me())
	_count.text = "%d FALLEN" % rows.size() if not rows.is_empty() else "NO NAMES ON THE WALL"
	_empty.visible = rows.is_empty()
	_empty.text = "No %s has died in your programme. May it stay that way." % people
	for row in rows:
		_grid.add_child(_plaque(row))
	_fit_columns()


func _plaque(row: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.theme_type_variation = "Card"
	card.custom_minimum_size = Vector2(PLAQUE_W, 0)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	card.add_child(h)
	var a: SimAstronaut = row["astronaut"]
	var face := Control.new()
	face.custom_minimum_size = PORTRAIT
	face.draw.connect(func():
		face.draw_rect(Rect2(Vector2.ZERO, face.size), CASE_BG)
		PortraitArt.paint(face, Rect2(Vector2.ZERO, face.size), a.name, a.female, Session.me().side, ""))
	h.add_child(face)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	h.add_child(v)
	var name := Label.new()
	name.theme_type_variation = "Subheading"
	name.text = str(row["name"]).capitalize() + ("  ★" if row["hero"] else "")
	name.add_theme_color_override("font_color", UiPalette.INFO if row["female"] else UiPalette.GOLD)
	name.clip_text = true
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(name)
	for line in [cause(row), TurnLogic.date_of(row["year"], row["season"]) if row["year"] > 0 else "",
			"%d mission%s flown" % [row["flights"], "" if row["flights"] == 1 else "s"]]:
		if line == "":
			continue
		var l := Label.new()
		l.text = line
		l.theme_type_variation = "Small"
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
	if row["hero"]:
		card.tooltip_text = "A hero of the programme"
	return card
