extends ScreenPanel
## Settings: UI scale, window mode, pixel mode, audio, animation speed.


func _init() -> void:
	super()
	title = "Settings"


func _ready() -> void:
	super()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 14)
	content.add_child(grid)

	_row(grid, "UI scale", _slider(0.75, 2.0, 0.05, Settings.ui_scale, func(v):
		Settings.ui_scale = v
		Settings.apply()
		Settings.save_settings(), "%.2fx"))
	var mode := OptionButton.new()
	mode.add_item("Windowed")
	mode.add_item("Fullscreen")
	mode.selected = 1 if Settings.window_mode == "fullscreen" else 0
	mode.item_selected.connect(func(i):
		Settings.window_mode = "fullscreen" if i == 1 else "windowed"
		Settings.apply()
		Settings.save_settings())
	_row(grid, "Window", mode)
	var pixel := CheckButton.new()
	pixel.text = "Integer scaling (pixel art mode)"
	pixel.button_pressed = Settings.pixel_mode
	pixel.toggled.connect(func(on):
		Settings.pixel_mode = on
		Settings.apply()
		Settings.save_settings())
	_row(grid, "Rendering", pixel)
	_row(grid, "Master volume", _slider(0.0, 1.0, 0.05, Settings.master_volume, func(v):
		Settings.master_volume = v
		Settings.apply()
		Settings.save_settings(), "%.0f%%", 100.0))
	_row(grid, "Music volume", _slider(0.0, 1.0, 0.05, Settings.music_volume, func(v):
		Settings.music_volume = v
		Settings.apply()
		Settings.save_settings(), "%.0f%%", 100.0))
	_row(grid, "Effects volume", _slider(0.0, 1.0, 0.05, Settings.sfx_volume, func(v):
		Settings.sfx_volume = v
		Settings.apply()
		Settings.save_settings(), "%.0f%%", 100.0))
	_row(grid, "Mission playback speed", _slider(0.5, 3.0, 0.25, Settings.animation_speed, func(v):
		Settings.animation_speed = v
		Settings.save_settings(), "%.2fx"))
	var skip := CheckButton.new()
	skip.text = "Skip launch animations"
	skip.button_pressed = Settings.skip_launch_animation
	skip.toggled.connect(func(on):
		Settings.skip_launch_animation = on
		Settings.save_settings())
	_row(grid, "Launches", skip)
	var info := Label.new()
	info.theme_type_variation = "Small"
	info.text = "Window %s, UI scale %.2f, logical canvas %s" % [str(get_window().size), Settings.ui_scale, str(Settings.logical_size().round())]
	content.add_child(info)
	get_window().size_changed.connect(func():
		info.text = "Window %s, UI scale %.2f, logical canvas %s" % [str(get_window().size), Settings.ui_scale, str(Settings.logical_size().round())])


func _row(grid: GridContainer, label: String, control: Control) -> void:
	var l := Label.new()
	l.text = label
	l.custom_minimum_size.x = 220
	grid.add_child(l)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(control)


func _slider(lo: float, hi: float, step: float, value: float, on_change: Callable, fmt: String, scale := 1.0) -> Control:
	var h := HBoxContainer.new()
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = value
	s.custom_minimum_size.x = 260
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
