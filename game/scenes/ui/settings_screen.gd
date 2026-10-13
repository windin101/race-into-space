extends ScreenPanel
## Settings: UI scale, window mode, pixel mode, audio, animation speed.


func _init() -> void:
	super()
	title = "Settings"


func _ready() -> void:
	super()
	var panels := HBoxContainer.new()
	panels.add_theme_constant_override("separation", 16)
	content.add_child(panels)
	var display := _panel(panels, "Display")
	var sound := _panel(panels, "Sound")
	var playback := _panel(panels, "Playback")

	_row(display, "UI scale", _slider(0.75, 2.0, 0.05, Settings.ui_scale, func(v):
		Settings.ui_scale = v
		Settings.apply()
		Settings.save_settings(), "%.2fx"), "Size of the whole interface")
	var mode := OptionButton.new()
	mode.add_item("Windowed")
	mode.add_item("Fullscreen")
	mode.selected = 1 if Settings.window_mode == "fullscreen" else 0
	mode.item_selected.connect(func(i):
		Settings.window_mode = "fullscreen" if i == 1 else "windowed"
		Settings.apply()
		Settings.save_settings())
	_row(display, "Window", mode, "Run in a window or full screen")
	var pixel := CheckButton.new()
	pixel.text = "Integer scaling (pixel art mode)"
	pixel.button_pressed = Settings.pixel_mode
	pixel.toggled.connect(func(on):
		Settings.pixel_mode = on
		Settings.apply()
		Settings.save_settings())
	_row(display, "Rendering", pixel, "Scale the canvas by whole steps only, for crisp pixel art")
	_row(sound, "Master", _slider(0.0, 1.0, 0.05, Settings.master_volume, func(v):
		Settings.master_volume = v
		Settings.apply()
		Settings.save_settings(), "%.0f%%", 100.0), "Overall volume")
	_row(sound, "Music", _slider(0.0, 1.0, 0.05, Settings.music_volume, func(v):
		Settings.music_volume = v
		Settings.apply()
		Settings.save_settings(), "%.0f%%", 100.0), "Volume of the music")
	_row(sound, "Effects", _slider(0.0, 1.0, 0.05, Settings.sfx_volume, func(v):
		Settings.sfx_volume = v
		Settings.apply()
		Settings.save_settings(), "%.0f%%", 100.0), "Volume of sound effects")
	_row(playback, "Speed", _slider(0.5, 3.0, 0.25, Settings.animation_speed, func(v):
		Settings.animation_speed = v
		Settings.save_settings(), "%.2fx"), "How fast mission playback runs; 1x holds each step long enough to follow")
	var skip := CheckButton.new()
	skip.text = "Skip launch animations"
	skip.button_pressed = Settings.skip_launch_animation
	skip.toggled.connect(func(on):
		Settings.skip_launch_animation = on
		Settings.save_settings())
	_row(playback, "Launches", skip, "Go straight to the launch results without the playback")
	var info := Label.new()
	info.theme_type_variation = "Small"
	info.text = "Window %s, UI scale %.2f, logical canvas %s" % [str(get_window().size), Settings.ui_scale, str(Settings.logical_size().round())]
	content.add_child(info)
	get_window().size_changed.connect(func():
		info.text = "Window %s, UI scale %.2f, logical canvas %s" % [str(get_window().size), Settings.ui_scale, str(Settings.logical_size().round())])
	set_room("room_admin")


## A titled panel holding a two-column grid of settings rows.
func _panel(parent: Control, heading: String) -> GridContainer:
	var p := UiPanel.new(heading)
	p.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	parent.add_child(p)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 14)
	p.body.add_child(grid)
	return grid


func _row(grid: GridContainer, label: String, control: Control, tip := "") -> void:
	var l := Label.new()
	l.text = label.to_upper()
	l.theme_type_variation = "Caps"
	l.custom_minimum_size.x = 150
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.tooltip_text = tip
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	grid.add_child(l)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.tooltip_text = tip
	for c in control.get_children():
		if c is Control:
			(c as Control).tooltip_text = tip
	grid.add_child(control)


func _slider(lo: float, hi: float, step: float, value: float, on_change: Callable, fmt: String, scale := 1.0) -> Control:
	var h := HBoxContainer.new()
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = value
	s.custom_minimum_size.x = 160
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var v := Label.new()
	v.custom_minimum_size.x = 70
	v.text = fmt % (value * scale)
	s.value_changed.connect(func(val):
		v.text = fmt % (val * scale)
		on_change.call(val))
	h.add_child(s)
	h.add_child(v)
	return h
