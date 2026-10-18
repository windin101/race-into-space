extends GdUnitTestSuite
## Screens sit under the Screens CanvasLayer, which stops theme inheritance from the window.
## UiTheme.apply must still put the project theme on every pushed screen (it once did not,
## and every button in the game drew in Godot's default grey).


func test_a_pushed_screen_uses_the_project_theme() -> void:
	UiTheme.apply(Engine.get_main_loop() as SceneTree, "usa")
	var screen := Control.new()
	var b := Button.new()
	b.theme_type_variation = "Go"
	screen.add_child(b)
	Screens.push(screen)
	var sb := b.get_theme_stylebox("normal") as StyleBoxFlat
	assert_object(sb).is_not_null()
	assert_that(sb.bg_color).is_equal(UiPalette.OK.darkened(0.35))
	Screens.pop()


func test_colour_blind_mode_changes_the_go_colour() -> void:
	UiPalette.set_colour_mode("colour_blind")
	var cb := (UiTheme.get_theme("usa").get_stylebox("normal", "Go") as StyleBoxFlat).bg_color
	UiPalette.set_colour_mode("standard")
	var std := (UiTheme.get_theme("usa").get_stylebox("normal", "Go") as StyleBoxFlat).bg_color
	assert_that(cb).is_not_equal(std)
	assert_that(std).is_equal(Color("4caf50").darkened(0.35))
