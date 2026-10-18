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
	var colours := OptionButton.new()
	colours.add_item("Standard")
	colours.add_item("Colour-blind friendly")
	colours.selected = 1 if Settings.colour_mode == "colour_blind" else 0
	colours.item_selected.connect(func(i):
		Settings.colour_mode = "colour_blind" if i == 1 else "standard"
		Settings.apply()
		Settings.save_settings())
	_row(display, "Status colours", colours, "Green, amber and red for good, caution and failure, or blue, yellow and orange, which stay distinct for colour-blind players. Applies to screens opened afterwards.")
	_row(sound, "Master", _slider(0.0, 1.0, 0.05, Settings.master_volume, func(v):
		Settings.master_volume = v
		Settings.apply()
		Settings.save_settings(), "%.0f%%", 100.0), "Overall volume")
	_row(sound, "Music", _slider(0.0, 1.0, 0.05, Settings.music_volume, func(v):
		Settings.music_volume = v
		Settings.apply()
		Settings.save_settings()
		if _music_status != null:
			_refresh_music_status(), "%.0f%%", 100.0), "Volume of the music")
	_row(sound, "Effects", _slider(0.0, 1.0, 0.05, Settings.sfx_volume, func(v):
		Settings.sfx_volume = v
		Settings.apply()
		Settings.save_settings(), "%.0f%%", 100.0), "Volume of sound effects")
	_build_music_source(sound)
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


# ----------------------------------------------------------------- music source

var _source_opt: OptionButton
var _folder_btn: Button
var _music_status: Label


## Soundtrack choice: ours, or the original game's music from the player's own folder.
## The files are read where they are; nothing is copied into the game.
func _build_music_source(grid: GridContainer) -> void:
	_source_opt = OptionButton.new()
	_source_opt.add_item("Race Into Space soundtrack")
	_source_opt.add_item("Original game music")
	_source_opt.selected = 1 if Settings.music_source == "original" else 0
	_source_opt.item_selected.connect(func(i):
		if i == 1 and Settings.original_music_dir == "":
			_pick_folder()
			return
		_set_source("original" if i == 1 else "ours"))
	_row(grid, "Soundtrack", _source_opt, "Use the bundled soundtrack, or the original 1993 game's music from your own copy")
	_folder_btn = Button.new()
	_folder_btn.text = "CHOOSE FOLDER"
	_folder_btn.theme_type_variation = "Bar"
	_folder_btn.tooltip_text = "The folder holding the original music files (theme.ogg, usport2.ogg, assembly.ogg and so on)"
	_folder_btn.pressed.connect(_pick_folder)
	_row(grid, "Music folder", _folder_btn, "Where your copy of the original music lives")
	_music_status = Label.new()
	_music_status.theme_type_variation = "Small"
	_music_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_music_status.custom_minimum_size.x = 300
	_row(grid, "", _music_status, "")
	_refresh_music_status()


func _pick_folder() -> void:
	var dlg := FileDialog.new()
	dlg.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	dlg.access = FileDialog.ACCESS_FILESYSTEM
	dlg.title = "Folder with the original game's music"
	dlg.use_native_dialog = true
	if Settings.original_music_dir != "":
		dlg.current_dir = Settings.original_music_dir
	add_child(dlg)
	dlg.dir_selected.connect(func(path: String):
		Settings.original_music_dir = path
		_set_source("original")
		dlg.queue_free())
	dlg.canceled.connect(func():
		_source_opt.selected = 1 if Settings.music_source == "original" else 0
		dlg.queue_free())
	dlg.popup_centered_ratio(0.6)


func _set_source(src: String) -> void:
	Settings.music_source = src
	if src == "original" and MusicLibrary.check_folder(Settings.original_music_dir)["found"].is_empty():
		Settings.music_source = "ours"
	Settings.save_settings()
	_source_opt.selected = 1 if Settings.music_source == "original" else 0
	_refresh_music_status()
	Sound.refresh_music()


func _refresh_music_status() -> void:
	var dir := Settings.original_music_dir
	_folder_btn.text = ("FOLDER: " + dir.get_file().to_upper()) if dir != "" else "CHOOSE FOLDER"
	if dir == "":
		_music_status.text = "Original music needs your own copy of the files; the game never includes them."
		return
	var r := MusicLibrary.check_folder(dir)
	var total: int = r["found"].size() + r["missing"].size()
	if r["found"].is_empty():
		_music_status.text = "No original music found in %s. Using the Race Into Space soundtrack." % dir
		_music_status.add_theme_color_override("font_color", UiPalette.WARN)
	elif r["missing"].is_empty():
		_music_status.text = "All %d original tracks the game uses were found." % total
		_music_status.add_theme_color_override("font_color", UiPalette.OK)
	else:
		_music_status.text = "%d of %d tracks found; missing ones use our soundtrack: %s." % [r["found"].size(), total, ", ".join(r["missing"])]
		_music_status.remove_theme_color_override("font_color")
	if Settings.music_volume <= 0.001 and not r["found"].is_empty():
		_music_status.text += "  Music volume is at 0%: raise the Music slider to hear it."
		_music_status.add_theme_color_override("font_color", UiPalette.WARN)
