extends ScreenPanel
## New Game: how many sides race and which ones, the side the player directs (the computer
## runs the rest), difficulty and astronaut level per side, the hardware model, director
## names and the seed. Every list of sides comes from the registry (data/sides.json), so a
## faction added there appears here with no code change. Defaults come from new_game.json.

const SPACEPORT := "res://scenes/spaceport/spaceport.tscn"
const PREFERENCES := "res://scenes/admin/preferences.tscn"
const LEVEL_NAMES := ["Easy", "Medium", "Hard"]
const MODEL_NAMES := {"basic": "Basic", "historical": "Historical"}
const SEED_MAX := 2147483647

var _count: OptionButton
var _pick_box: HBoxContainer
var _picks: Dictionary = {}         ## side -> Button (toggle)
var _pick_note: Label
var _side: OptionButton
var _emblem: TextureRect
var _model: OptionButton
var _seed: SpinBox
var _sides_grid: GridContainer
var _director: Dictionary = {}     ## side -> LineEdit
var _level: Dictionary = {}        ## side -> OptionButton
var _astro_level: Dictionary = {}  ## side -> OptionButton
var _models: Array = []
var _start: Button
var _lineup: Array = []            ## chosen sides in registry order


func _init() -> void:
	super()
	title = "New Game"


func _ready() -> void:
	super()
	var intro := Label.new()
	intro.theme_type_variation = "Dim"
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.text = "The race runs from Spring %d to Fall %d. The first side to land on the Moon and bring the crew home wins." % [SimState.FIRST_YEAR + 1900, SimState.LAST_YEAR + 1900]
	content.add_child(intro)

	# The race: how many sides and which.
	var race := UiPanel.new("The race", "I013")
	content.add_child(race)
	var race_row := HBoxContainer.new()
	race_row.add_theme_constant_override("separation", 20)
	race.body.add_child(race_row)
	var count_box := VBoxContainer.new()
	race_row.add_child(count_box)
	count_box.add_child(_label("Sides racing"))
	_count = OptionButton.new()
	for n in range(Sides.min_sides(), Sides.max_sides() + 1):
		_count.add_item("%d sides" % n, n)
	_count.tooltip_text = "How many space programmes take part"
	_count.item_selected.connect(func(_i): _on_count_changed())
	count_box.add_child(_count)
	_pick_box = HBoxContainer.new()
	_pick_box.add_theme_constant_override("separation", 12)
	_pick_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	race_row.add_child(_pick_box)
	for s in Sides.ids():
		var b := Button.new()
		b.toggle_mode = true
		b.text = Sides.name(s).to_upper()
		b.theme_type_variation = "Bar"
		b.icon = ArtAssets.icon("flag_%s" % s)
		b.expand_icon = false
		b.add_theme_constant_override("icon_max_width", 44)
		b.custom_minimum_size = Vector2(230, 64)
		b.tooltip_text = "%s, from %s" % [Sides.name(s), str(Sides.field(s, "site", ""))]
		b.toggled.connect(func(_on): _on_pick_changed())
		_pick_box.add_child(b)
		_picks[s] = b
	_pick_note = Label.new()
	_pick_note.theme_type_variation = "Small"
	race.body.add_child(_pick_note)

	var panels := HBoxContainer.new()
	panels.add_theme_constant_override("separation", 16)
	content.add_child(panels)
	var game := UiPanel.new("The game", "I013")
	game.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panels.add_child(game)
	var top := GridContainer.new()
	top.columns = 2
	top.add_theme_constant_override("h_separation", 20)
	top.add_theme_constant_override("v_separation", 12)
	game.body.add_child(top)
	_side = OptionButton.new()
	_side.add_theme_constant_override("icon_max_width", 38)
	_side.tooltip_text = "The side you direct; the computer plays the others"
	var side_row := HBoxContainer.new()
	side_row.add_theme_constant_override("separation", 16)
	_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_side.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	side_row.add_child(_side)
	_emblem = TextureRect.new()
	_emblem.custom_minimum_size = Vector2(72, 72)
	_emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	side_row.add_child(_emblem)
	_side.item_selected.connect(func(_i): _refresh_emblem())
	_row(top, "Your side", side_row)
	_model = OptionButton.new()
	_models = GameData.hardware.get("models", {}).keys()
	for m in _models:
		_model.add_item(MODEL_NAMES.get(m, str(m).capitalize()))
	_model.selected = maxi(0, _models.find("basic"))
	_model.tooltip_text = "Which hardware rules the game uses: the original's basic model or the historical one"
	_row(top, "Hardware model", _model)
	var seed_row := HBoxContainer.new()
	seed_row.add_theme_constant_override("separation", 10)
	_seed = SpinBox.new()
	_seed.min_value = 0
	_seed.max_value = SEED_MAX
	_seed.step = 1
	_seed.custom_minimum_size.x = 200
	_seed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_seed.tooltip_text = "The same seed and settings replay the same game"
	seed_row.add_child(_seed)
	var random := Button.new()
	random.text = "RANDOM"
	random.theme_type_variation = "Bar"
	random.tooltip_text = "Pick a new random seed"
	random.pressed.connect(_randomise_seed)
	seed_row.add_child(random)
	_row(top, "Seed", seed_row)
	_randomise_seed()

	var sides := UiPanel.new("The sides", "I013")
	sides.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	sides.size_flags_stretch_ratio = 1.6
	panels.add_child(sides)
	_sides_grid = GridContainer.new()
	_sides_grid.add_theme_constant_override("h_separation", 20)
	_sides_grid.add_theme_constant_override("v_separation", 12)
	sides.body.add_child(_sides_grid)
	var note := Label.new()
	note.theme_type_variation = "Small"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.text = "Difficulty sets the budget, R&D limits and failure consequences for that side. The astronaut level sets the quality of the recruit pool. The same seed and settings replay the same game."
	sides.body.add_child(note)
	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(filler)

	var load_btn := Button.new()
	load_btn.text = "LOAD GAME"
	load_btn.theme_type_variation = "Bar"
	load_btn.tooltip_text = "Open the saved games instead"
	load_btn.custom_minimum_size = Vector2(170, 40)
	load_btn.pressed.connect(func(): Screens.push(load(PREFERENCES)))
	footer.add_child(load_btn)
	_start = Button.new()
	_start.custom_minimum_size = Vector2(220, 40)
	_start.pressed.connect(_on_start)
	footer.add_child(_start)
	set_backdrop("title")

	# Start from the registry's default line-up.
	var default := Sides.default_lineup()
	for s in _picks:
		_picks[s].set_pressed_no_signal(default.has(s))
	_count.select(maxi(0, _count.get_item_index(default.size())))
	_on_pick_changed()


func _on_count_changed() -> void:
	# Trim or top up the picks to match the new count, keeping earlier choices.
	var want := _count.get_item_id(_count.selected)
	var chosen := _chosen()
	for s in Sides.ids():
		if chosen.size() > want and chosen.has(s) and s != chosen[0]:
			chosen.erase(s)
	for s in Sides.ids():
		if chosen.size() < want and not chosen.has(s):
			chosen.append(s)
	for s in _picks:
		_picks[s].set_pressed_no_signal(chosen.has(s))
	_on_pick_changed()


func _chosen() -> Array:
	var out: Array = []
	for s in Sides.ids():
		if _picks[s].button_pressed:
			out.append(s)
	return out


func _on_pick_changed() -> void:
	_lineup = _chosen()
	var want := _count.get_item_id(_count.selected)
	var ok := _lineup.size() == want
	_pick_note.text = "Choose %d sides." % want if not ok else "%s." % " vs ".join(_lineup.map(func(s): return Sides.name(s)))
	_pick_note.add_theme_color_override("font_color", UiPalette.TEXT_DIM if ok else UiPalette.WARN)
	if ok:
		UiAction.style(_start, "go", "Start the race")
		_start.tooltip_text = "Begin in Spring %d with these settings" % (SimState.FIRST_YEAR + 1900)
	else:
		UiAction.style(_start, "blocked", "Start the race", "Choose exactly %d sides to race." % want)
	var keep := human_side()
	_side.clear()
	for s in _lineup:
		_side.add_item(Sides.name(s))
		var flag := ArtAssets.icon("flag_%s" % s)
		if flag != null:
			_side.set_item_icon(_side.item_count - 1, flag)
	var at := _lineup.find(keep)
	_side.select(at if at >= 0 else 0)
	_refresh_emblem()
	_build_sides_grid()


func _build_sides_grid() -> void:
	var ng: Dictionary = GameData.new_game
	var old_names := {}
	for s in _director:
		old_names[s] = _director[s].text
	for c in _sides_grid.get_children():
		c.queue_free()
	_director.clear()
	_level.clear()
	_astro_level.clear()
	_sides_grid.columns = _lineup.size() + 1
	_sides_grid.add_child(_label(""))
	for s in _lineup:
		var h := _label(Sides.name(s))
		h.theme_type_variation = "CapsBright"
		h.add_theme_color_override("font_color", UiPalette.accent(s).lightened(0.3))
		_sides_grid.add_child(h)
	_sides_grid.add_child(_label("Director"))
	for s in _lineup:
		var e := LineEdit.new()
		e.text = old_names.get(s, str(ng.get("sides", {}).get(s, {}).get("director_name", "")))
		e.max_length = 24
		e.custom_minimum_size.x = 180
		e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		e.tooltip_text = "The %s programme director's name" % Sides.name(s)
		_sides_grid.add_child(e)
		_director[s] = e
	_sides_grid.add_child(_label("Difficulty"))
	for s in _lineup:
		var o := _levels(int(ng.get("default_difficulty", {}).get(s, 0)))
		o.tooltip_text = "%s: budget, R&D limits and failure consequences" % Sides.name(s)
		_sides_grid.add_child(o)
		_level[s] = o
	_sides_grid.add_child(_label("Astronaut level"))
	for s in _lineup:
		var o := _levels(int(ng.get("default_astronaut_level", {}).get(s, 0)))
		o.tooltip_text = "%s: quality of the recruit pool" % Sides.name(s)
		_sides_grid.add_child(o)
		_astro_level[s] = o


func _refresh_emblem() -> void:
	var tex := ArtAssets.icon("emblem_%s" % human_side()) if human_side() != "" else null
	_emblem.texture = tex
	_emblem.visible = tex != null


func _row(grid: GridContainer, label: String, control: Control) -> void:
	grid.add_child(_label(label))
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(control)


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text.to_upper()
	l.theme_type_variation = "Caps"
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.custom_minimum_size.x = 150
	return l


func _levels(selected: int) -> OptionButton:
	var o := OptionButton.new()
	for lvl in LEVEL_NAMES:
		o.add_item(lvl)
	o.selected = clampi(selected, 0, LEVEL_NAMES.size() - 1)
	o.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return o


func _randomise_seed() -> void:
	_seed.value = randi() % (SEED_MAX + 1)


func human_side() -> String:
	if _side == null or _side.selected < 0 or _side.selected >= _lineup.size():
		return _lineup[0] if not _lineup.is_empty() else ""
	return _lineup[_side.selected]


## The options dictionary Session.new_game receives.
func game_options() -> Dictionary:
	var ng: Dictionary = GameData.new_game
	var opts := {"sides": _lineup.duplicate(), "human_side": human_side(),
			"model": _models[_model.selected] if not _models.is_empty() else "basic"}
	for s in _lineup:
		opts["level_%s" % s] = _level[s].selected
		opts["astronaut_level_%s" % s] = _astro_level[s].selected
		var director: String = _director[s].text.strip_edges()
		opts["director_name_%s" % s] = director if director != "" else str(ng.get("sides", {}).get(s, {}).get("director_name", ""))
	return opts


func _on_start() -> void:
	if UiAction.is_blocked(_start):
		return
	var opts := game_options()
	Session.new_game(int(_seed.value), opts)
	for p in Session.state().players:
		p.director_name = opts["director_name_%s" % p.side]
	Session.notify_change()
	Screens.reset(load(SPACEPORT))
	TurnFlow.on_new_game()
