extends Node
## Autoload "Sound": music and effects. Streams live under res://assets/audio and play
## on the Music and SFX buses that Settings controls. Missing files are ignored so the
## game runs without audio assets.

const MUSIC_DIR := "res://assets/audio/music/"
const SFX_DIR := "res://assets/audio/sfx/"
const CROSSFADE := 1.2

var _music: AudioStreamPlayer
var _music_next: AudioStreamPlayer
var _current_track := ""
var _sfx_pool: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}


func _ready() -> void:
	_music = _make_player("Music")
	_music_next = _make_player("Music")
	for i in 6:
		_sfx_pool.append(_make_player("SFX"))
	if Screens != null:
		Screens.screen_changed.connect(_on_screen_changed)


func _make_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus if AudioServer.get_bus_index(bus) >= 0 else "Master"
	add_child(p)
	return p


func _stream(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path)
	_cache[path] = s
	return s


## Play an effect by name (file stem under assets/audio/sfx).
func sfx(name: String, volume_db := 0.0) -> void:
	var s := _stream(SFX_DIR + name + ".ogg")
	if s == null:
		return
	for p in _sfx_pool:
		if not p.playing:
			p.stream = s
			p.volume_db = volume_db
			p.play()
			return
	_sfx_pool[0].stream = s
	_sfx_pool[0].play()


## Crossfade to a music track (file stem under assets/audio/music); same track is a no-op.
func music(name: String) -> void:
	if name == _current_track:
		return
	_current_track = name
	var s := _stream(MUSIC_DIR + name + ".ogg")
	if s == null:
		_fade_out(_music)
		return
	if s is AudioStreamOggVorbis:
		s.loop = true
	_music_next.stream = s
	_music_next.volume_db = -40.0
	_music_next.play()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_music_next, "volume_db", 0.0, CROSSFADE)
	if _music.playing:
		tw.tween_property(_music, "volume_db", -40.0, CROSSFADE)
	tw.chain().tween_callback(func():
		_music.stop()
		var tmp := _music
		_music = _music_next
		_music_next = tmp)


func stop_music() -> void:
	_current_track = ""
	_fade_out(_music)


func _fade_out(p: AudioStreamPlayer) -> void:
	if not p.playing:
		return
	var tw := create_tween()
	tw.tween_property(p, "volume_db", -40.0, CROSSFADE)
	tw.tween_callback(p.stop)


## Pick music by the screen that just became active.
func _on_screen_changed(top: Control) -> void:
	if top == null:
		return
	var scene_name := top.scene_file_path.get_file().get_basename() if top.scene_file_path != "" else top.name.to_lower()
	match scene_name:
		"title_screen", "new_game_setup":
			music("title_theme")
		"mission_playback":
			music("mission")
		"spaceport":
			music("spaceport_day")
		"end_game":
			music("title_theme")
