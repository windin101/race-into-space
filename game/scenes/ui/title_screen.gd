extends Control
## Title screen: new game, load game, widget gallery, settings, quit.

const SETUP := "res://scenes/setup/new_game_setup.tscn"
const PREFERENCES := "res://scenes/admin/preferences.tscn"
const GALLERY := "res://scenes/ui/widget_gallery.tscn"
const SETTINGS := "res://scenes/ui/settings_screen.tscn"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiPalette.BG_DEEP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var key_art := ArtAssets.backdrop("title")
	if key_art != null:
		var art := TextureRect.new()
		art.texture = key_art
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(art)
	# The logo, top right, where the original put it.
	var logo := TitleLogo.new(132.0)
	logo.anchor_left = 1.0
	logo.anchor_right = 1.0
	logo.anchor_top = 0.0
	logo.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	logo.offset_right = -48
	logo.offset_top = 40
	add_child(logo)
	# The menu beneath it on the right, over the Earth's limb.
	var menu_panel := PanelContainer.new()
	var msb := UiTheme.flat(Color(0.03, 0.04, 0.07, 0.72), Color(1, 1, 1, 0.08), 8, 1)
	msb.set_content_margin_all(18)
	menu_panel.add_theme_stylebox_override("panel", msb)
	menu_panel.anchor_left = 1.0
	menu_panel.anchor_right = 1.0
	menu_panel.anchor_top = 1.0
	menu_panel.anchor_bottom = 1.0
	menu_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	menu_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	menu_panel.offset_right = -48
	menu_panel.offset_bottom = -44
	add_child(menu_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 9)
	v.custom_minimum_size.x = 380
	menu_panel.add_child(v)
	var sub := Label.new()
	sub.theme_type_variation = "Dim"
	sub.text = "1957 to 1977. First to the Moon wins."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var new_game := _button("New game", "Choose a side and settings, then start the race", func(): Screens.push(load(SETUP)))
	UiAction.style(new_game, "go", "New game")
	new_game.custom_minimum_size.y = 52
	v.add_child(new_game)
	v.add_child(_button("Load game", "Continue from a saved game", func(): Screens.push(load(PREFERENCES))))
	v.add_child(_button("Settings", "Display, sound and playback settings", func(): Screens.push(load(SETTINGS))))
	v.add_child(_button("Widget gallery", "The interface components on one page", func(): Screens.push(load(GALLERY))))
	v.add_child(_button("Quit", "Close the game", func(): get_tree().quit()))
	var ver := Label.new()
	ver.theme_type_variation = "Small"
	ver.text = "A hobby remake of the 1993 classic  ·  Godot %s" % Engine.get_version_info()["string"]
	ver.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	ver.anchor_left = 1.0
	ver.anchor_right = 1.0
	ver.anchor_top = 1.0
	ver.anchor_bottom = 1.0
	ver.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	ver.grow_vertical = Control.GROW_DIRECTION_BEGIN
	ver.offset_right = -52
	ver.offset_bottom = -12
	add_child(ver)


## A menu button: a Bar in the wide caps face.
func _button(text: String, tip: String, on_pressed: Callable) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.theme_type_variation = "Bar"
	b.custom_minimum_size.y = 44
	b.pressed.connect(on_pressed)
	b.tooltip_text = tip
	return b


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	return c
