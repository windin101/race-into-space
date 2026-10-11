extends Node
## Autoload "Settings": user preferences persisted to user://settings.cfg and applied to
## the window (UI scale, window mode, integer scaling), audio buses and animation speed.

signal changed

const PATH := "user://settings.cfg"
const DESIGN_SIZE := Vector2i(1920, 1080)

var ui_scale := 1.0            ## multiplies the content scale factor (0.75 .. 2.0)
var window_mode := "windowed"  ## "windowed" | "fullscreen"
var pixel_mode := false        ## integer viewport scaling for pixel art (default: crisp vectors)
var master_volume := 1.0
var music_volume := 0.8
var sfx_volume := 1.0
var animation_speed := 1.0     ## 0.5 .. 3.0, multiplies mission playback speed
var skip_launch_animation := false


func _ready() -> void:
	load_settings()
	apply()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	ui_scale = cfg.get_value("display", "ui_scale", ui_scale)
	window_mode = cfg.get_value("display", "window_mode", window_mode)
	pixel_mode = cfg.get_value("display", "pixel_mode", pixel_mode)
	master_volume = cfg.get_value("audio", "master", master_volume)
	music_volume = cfg.get_value("audio", "music", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
	animation_speed = cfg.get_value("game", "animation_speed", animation_speed)
	skip_launch_animation = cfg.get_value("game", "skip_launch_animation", skip_launch_animation)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "ui_scale", ui_scale)
	cfg.set_value("display", "window_mode", window_mode)
	cfg.set_value("display", "pixel_mode", pixel_mode)
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("game", "animation_speed", animation_speed)
	cfg.set_value("game", "skip_launch_animation", skip_launch_animation)
	cfg.save(PATH)


## Push the settings to the window and audio buses.
func apply() -> void:
	var win := get_window()
	if win == null:
		return
	win.content_scale_size = DESIGN_SIZE
	if pixel_mode:
		win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		win.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER
	else:
		win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		win.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	win.content_scale_factor = clampf(ui_scale, 0.5, 3.0)
	if not DisplayServer.get_name() == "headless":
		win.mode = Window.MODE_FULLSCREEN if window_mode == "fullscreen" else Window.MODE_WINDOWED
	_set_bus("Master", master_volume)
	_set_bus("Music", music_volume)
	_set_bus("SFX", sfx_volume)
	changed.emit()


func _set_bus(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(idx, linear <= 0.0001)


## Logical viewport size the UI lays out against, after aspect expansion.
func logical_size() -> Vector2:
	var win := get_window()
	return Vector2(win.size) / win.content_scale_factor / _base_scale(win)


func _base_scale(win: Window) -> float:
	var s := Vector2(win.size) / Vector2(DESIGN_SIZE)
	return minf(s.x, s.y)
