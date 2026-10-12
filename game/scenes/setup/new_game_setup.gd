extends ScreenPanel
## New Game: pick a side, the difficulty and astronaut level for each side, the hardware
## model, director names and the seed, then start. Defaults come from new_game.json.

const SPACEPORT := "res://scenes/spaceport/spaceport.tscn"
const PREFERENCES := "res://scenes/admin/preferences.tscn"
const SIDES := ["usa", "ussr"]
const SIDE_TITLES := {"usa": "United States", "ussr": "Soviet Union"}
const LEVEL_NAMES := ["Easy", "Medium", "Hard"]
const MODEL_NAMES := {"basic": "Basic", "historical": "Historical"}
const SEED_MAX := 2147483647

var _side: OptionButton
var _emblem: TextureRect
var _model: OptionButton
var _seed: SpinBox
var _director: Dictionary = {}     ## side -> LineEdit
var _level: Dictionary = {}        ## side -> OptionButton
var _astro_level: Dictionary = {}  ## side -> OptionButton
var _models: Array = []


func _init() -> void:
	super()
	title = "New Game"


func _ready() -> void:
	super()
	var ng: Dictionary = GameData.new_game
	var intro := Label.new()
	intro.theme_type_variation = "Dim"
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.text = "The race runs from Spring %d to Fall %d. The first side to land on the Moon and bring the crew home wins." % [SimState.FIRST_YEAR + 1900, SimState.LAST_YEAR + 1900]
	content.add_child(intro)

	var top := GridContainer.new()
	top.columns = 2
	top.add_theme_constant_override("h_separation", 24)
	top.add_theme_constant_override("v_separation", 12)
	content.add_child(top)
	_side = OptionButton.new()
	for s in SIDES:
		_side.add_item(SIDE_TITLES[s])
		var flag := ArtAssets.icon("flag_%s" % s)
		if flag != null:
			_side.set_item_icon(_side.item_count - 1, flag)
	_side.selected = 0
	_side.add_theme_constant_override("icon_max_width", 38)
	var side_row := HBoxContainer.new()
	side_row.add_theme_constant_override("separation", 16)
	_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_row.add_child(_side)
	_emblem = TextureRect.new()
	_emblem.custom_minimum_size = Vector2(72, 72)
	_emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	side_row.add_child(_emblem)
	_side.item_selected.connect(func(_i): _refresh_emblem())
	_refresh_emblem()
	_row(top, "Your side", side_row)
	_model = OptionButton.new()
	_models = GameData.hardware.get("models", {}).keys()
	for m in _models:
		_model.add_item(MODEL_NAMES.get(m, str(m).capitalize()))
	_model.selected = maxi(0, _models.find("basic"))
	_row(top, "Hardware model", _model)
	var seed_row := HBoxContainer.new()
	_seed = SpinBox.new()
	_seed.min_value = 0
	_seed.max_value = SEED_MAX
	_seed.step = 1
	_seed.custom_minimum_size.x = 200
	_seed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_row.add_child(_seed)
	var random := Button.new()
	random.text = "Random"
	random.pressed.connect(_randomise_seed)
	seed_row.add_child(random)
	_row(top, "Seed", seed_row)
	_randomise_seed()

	var sides_heading := Label.new()
	sides_heading.theme_type_variation = "Subheading"
	sides_heading.text = "Sides"
	content.add_child(sides_heading)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 12)
	content.add_child(grid)
	grid.add_child(_label(""))
	for s in SIDES:
		var h := _label(SIDE_TITLES[s])
		h.theme_type_variation = "Subheading"
		grid.add_child(h)
	grid.add_child(_label("Director"))
	for s in SIDES:
		var e := LineEdit.new()
		e.text = ng["sides"][s]["director_name"]
		e.max_length = 24
		e.custom_minimum_size.x = 220
		e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(e)
		_director[s] = e
	grid.add_child(_label("Difficulty"))
	for s in SIDES:
		var o := _levels(int(ng.get("default_difficulty", {}).get(s, 0)))
		grid.add_child(o)
		_level[s] = o
	grid.add_child(_label("Astronaut level"))
	for s in SIDES:
		var o := _levels(int(ng.get("default_astronaut_level", {}).get(s, 0)))
		grid.add_child(o)
		_astro_level[s] = o

	var note := Label.new()
	note.theme_type_variation = "Small"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.text = "Difficulty sets the budget, R&D limits and failure consequences for that side. The astronaut level sets the quality of the recruit pool. The same seed and settings replay the same game."
	content.add_child(note)
	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(filler)

	var load_btn := Button.new()
	load_btn.text = "Load game"
	load_btn.pressed.connect(func(): Screens.push(load(PREFERENCES)))
	footer.add_child(load_btn)
	var start := Button.new()
	start.text = "Start the race"
	start.theme_type_variation = "Accent"
	start.pressed.connect(_on_start)
	footer.add_child(start)


func _refresh_emblem() -> void:
	var tex := ArtAssets.icon("emblem_%s" % SIDES[_side.selected])
	_emblem.texture = tex
	_emblem.visible = tex != null


func _row(grid: GridContainer, label: String, control: Control) -> void:
	grid.add_child(_label(label))
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(control)


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.custom_minimum_size.x = 160
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
	return SIDES[_side.selected]


## The options dictionary Session.new_game receives.
func game_options() -> Dictionary:
	var ng: Dictionary = GameData.new_game
	var opts := {"human_side": human_side(), "model": _models[_model.selected] if not _models.is_empty() else "basic"}
	for s in SIDES:
		opts["level_%s" % s] = _level[s].selected
		opts["astronaut_level_%s" % s] = _astro_level[s].selected
		var director: String = _director[s].text.strip_edges()
		opts["director_name_%s" % s] = director if director != "" else String(ng["sides"][s]["director_name"])
	return opts


func _on_start() -> void:
	var opts := game_options()
	Session.new_game(int(_seed.value), opts)
	for p in Session.state().players:
		p.director_name = opts["director_name_%s" % p.side]
	Session.notify_change()
	Screens.reset(load(SPACEPORT))
	TurnFlow.on_new_game()
