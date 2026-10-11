extends GdUnitTestSuite
## Theme builder, data table sorting and the screen manager stack.

var data: Node


func before() -> void:
	data = load("res://scripts/data/game_data.gd").new()
	add_child(data)
	data.load_all()


func after() -> void:
	data.queue_free()


func test_theme_builds_for_both_sides_with_fonts() -> void:
	for side in ["usa", "ussr"]:
		var t := UiTheme.build(side)
		assert_object(t).is_not_null()
		assert_object(t.default_font).is_not_null()
		assert_bool(t.has_font("font", "Title")).is_true()
		assert_bool(t.has_stylebox("normal", "Accent")).is_true()
		assert_bool(t.has_stylebox("panel", "Card")).is_true()
	var usa_accent: StyleBoxFlat = UiTheme.build("usa").get_stylebox("normal", "Accent")
	var ussr_accent: StyleBoxFlat = UiTheme.build("ussr").get_stylebox("normal", "Accent")
	assert_bool(usa_accent.bg_color == ussr_accent.bg_color).is_false()
	assert_object(UiTheme.get_theme("usa")).is_same(UiTheme.get_theme("usa"))


func test_palette_bands() -> void:
	assert_object(UiPalette.safety_color(80)).is_equal(UiPalette.OK)
	assert_object(UiPalette.safety_color(60)).is_equal(UiPalette.WARN)
	assert_object(UiPalette.safety_color(10)).is_equal(UiPalette.DANGER)
	assert_bool(UiPalette.accent("usa") == UiPalette.accent("ussr")).is_false()


func test_data_table_sorts_and_selects() -> void:
	var table := DataTable.new()
	add_child(table)
	table.set_columns([{"key": "name", "title": "Name"}, {"key": "safety", "title": "Safety", "numeric": true}])
	table.set_rows([{"name": "Titan", "safety": 40}, {"name": "atlas", "safety": 90}, {"name": "Saturn", "safety": 65}])
	table.sort_by("safety", true)
	assert_str(table.rows[0]["name"]).is_equal("atlas")
	assert_str(table.rows[2]["name"]).is_equal("Titan")
	table.sort_by("name")
	assert_str(table.rows[0]["name"]).is_equal("atlas")     # case-insensitive
	assert_str(table.rows[1]["name"]).is_equal("Saturn")
	var got: Array = []
	table.row_selected.connect(func(r): got.append(r["name"]))
	table._on_row_pressed(1)
	assert_array(got).is_equal(["Saturn"])
	assert_str(table.selected_row()["name"]).is_equal("Saturn")
	table.queue_free()


func test_stat_bar_and_cards_accept_sim_objects() -> void:
	var sim := SimState.new(data, 3)
	var p := sim.player(0)
	p.cash = 500
	var atlas := p.program("rocket", 0)
	SimHardware.buy_program(sim, p, atlas)
	var card := HardwareCard.new()
	add_child(card)
	card.set_program(atlas)
	assert_str(card._name.text).is_equal("Atlas")
	assert_int(card._safety.value).is_equal(atlas.safety)
	card.queue_free()
	var a := SimAstronaut.new()
	a.name = "GLENN"
	a.mood = 55
	a.skills["capsule"] = 3
	var ac := AstronautCard.new()
	add_child(ac)
	ac.set_astronaut(a)
	assert_str(ac._name.text).is_equal("Glenn")
	assert_int(ac._skills["capsule"].value).is_equal(3)
	ac.queue_free()
	var bar := StatBar.new("Safety", 150, 100)
	add_child(bar)
	assert_int(int(bar._bar.value)).is_equal(100)
	bar.queue_free()


func test_screen_manager_stack() -> void:
	var mgr: CanvasLayer = load("res://scripts/ui/screen_manager.gd").new()
	add_child(mgr)
	var a := Control.new()
	var b := Control.new()
	mgr.push(a)
	mgr.push(b)
	assert_int(mgr.depth()).is_equal(2)
	assert_object(mgr.current()).is_same(b)
	assert_bool(a.visible).is_false()
	mgr.pop()
	assert_int(mgr.depth()).is_equal(1)
	assert_object(mgr.current()).is_same(a)
	assert_bool(a.visible).is_true()
	mgr.pop()                                   # never pops the last screen
	assert_int(mgr.depth()).is_equal(1)
	mgr.push(Control.new())
	mgr.push(Control.new())
	assert_int(mgr.depth()).is_equal(3)
	mgr.go_home()
	assert_int(mgr.depth()).is_equal(1)
	assert_object(mgr.current()).is_same(a)
	var c := Control.new()
	mgr.reset(c)
	assert_int(mgr.depth()).is_equal(1)
	assert_object(mgr.current()).is_same(c)
	mgr.queue_free()


func test_help_text_strips_layout_directives() -> void:
	var t := UiHelp.text_for("I001")
	assert_str(t).is_not_empty()
	assert_bool(t.begins_with(";")).is_false()
	assert_bool(t.contains("%03")).is_false()
	assert_str(UiHelp.text_for("NOPE")).is_empty()
