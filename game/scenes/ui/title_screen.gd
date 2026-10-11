extends Control
## Title screen: new game, widget gallery, settings, quit.

const SPACEPORT := "res://scenes/spaceport/spaceport.tscn"
const GALLERY := "res://scenes/ui/widget_gallery.tscn"
const SETTINGS := "res://scenes/ui/settings_screen.tscn"

var _side := "usa"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiPalette.BG_DEEP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
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
	var side_row := HBoxContainer.new()
	side_row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(side_row)
	var usa := Button.new()
	usa.text = "Play USA"
	usa.theme_type_variation = "Accent"
	usa.pressed.connect(_start.bind("usa"))
	side_row.add_child(usa)
	var ussr := Button.new()
	ussr.text = "Play USSR"
	ussr.pressed.connect(_start.bind("ussr"))
	side_row.add_child(ussr)
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


func _start(side: String) -> void:
	Session.new_game(randi(), {"human_side": side})
	Screens.reset(load(SPACEPORT))
