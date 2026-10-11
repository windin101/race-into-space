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
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	v.custom_minimum_size.x = 420
	center.add_child(v)
	var title := Label.new()
	title.theme_type_variation = "Title"
	title.text = "RACE INTO SPACE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := Label.new()
	sub.theme_type_variation = "Dim"
	sub.text = "1957 to 1977. First to the Moon wins."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	v.add_child(_spacer(20))
	var new_game := _button("New game", func(): Screens.push(load(SETUP)))
	new_game.theme_type_variation = "Accent"
	v.add_child(new_game)
	v.add_child(_button("Load game", func(): Screens.push(load(PREFERENCES))))
	v.add_child(_button("Widget gallery", func(): Screens.push(load(GALLERY))))
	v.add_child(_button("Settings", func(): Screens.push(load(SETTINGS))))
	v.add_child(_button("Quit", func(): get_tree().quit()))
	var ver := Label.new()
	ver.theme_type_variation = "Small"
	ver.text = "Phase 3 build   Godot %s" % Engine.get_version_info()["string"]
	ver.anchor_left = 0.0
	ver.anchor_top = 0.95
	ver.anchor_right = 1.0
	ver.anchor_bottom = 1.0
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(ver)


func _button(text: String, on_pressed: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(on_pressed)
	return b


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	return c
