class_name MusicLibrary
extends RefCounted
## Resolves what music plays where (data/audio/music_map.json) for the chosen soundtrack.
## The original game's music is read from a folder the player chooses, at runtime, and is
## never copied into the project or bundled with it. Matching is case-insensitive and
## accepts .ogg (the port's format), .mp3 and .wav. A track missing from the folder falls
## back to our own soundtrack for that place.

const MAP_PATH := "res://data/audio/music_map.json"
const EXTENSIONS := ["ogg", "mp3", "wav"]

static var _map: Dictionary = {}
static var _index_dir := ""
static var _index: Dictionary = {}     ## lower-case stem -> absolute path


static func map() -> Dictionary:
	if _map.is_empty():
		var f := FileAccess.open(MAP_PATH, FileAccess.READ)
		if f != null:
			var d = JSON.parse_string(f.get_as_text())
			_map = d if d is Dictionary else {}
	return _map


## Every original track stem the map can use, for the "N of M found" check.
static func original_tracks() -> PackedStringArray:
	var out: PackedStringArray = []
	for group in ["screens", "events"]:
		for key in map().get(group, {}):
			for stem in map()[group][key].get("original", []):
				if not out.has(stem):
					out.append(stem)
	out.sort()
	return out


## Index a folder: lower-case file stem -> absolute path for the supported formats.
static func index_folder(dir_path: String) -> Dictionary:
	if dir_path == _index_dir and not _index.is_empty():
		return _index
	var out: Dictionary = {}
	var dir := DirAccess.open(dir_path)
	if dir != null:
		dir.list_dir_begin()
		var name := dir.get_next()
		while name != "":
			if not dir.current_is_dir() and name.get_extension().to_lower() in EXTENSIONS:
				var stem := name.get_basename().to_lower()
				if not out.has(stem) or name.get_extension().to_lower() == "ogg":
					out[stem] = dir_path.path_join(name)
			name = dir.get_next()
	_index_dir = dir_path
	_index = out
	return out


static func clear_index() -> void:
	_index_dir = ""
	_index = {}


## {found: [stems], missing: [stems]} for a folder against the map. A place counts as
## covered when any of its candidate names is present, so alternative spellings (r&d / rd,
## usport2 / usport) are never reported missing when one of them is there.
static func check_folder(dir_path: String) -> Dictionary:
	clear_index()
	var idx := index_folder(dir_path)
	var found: PackedStringArray = []
	var missing: PackedStringArray = []
	for group in ["screens", "events"]:
		for key in map().get(group, {}):
			var cands: Array = map()[group][key].get("original", [])
			if cands.is_empty():
				continue
			var hit := ""
			for stem in cands:
				if idx.has(str(stem).to_lower()):
					hit = str(stem)
					break
			if hit != "":
				if not found.has(hit):
					found.append(hit)
			elif not missing.has(str(cands[0])):
				missing.append(str(cands[0]))
	for stem in found:
		missing.erase(stem)
	found.sort()
	missing.sort()
	return {"found": found, "missing": missing}


## The map entry for a key ("research", "spaceport_usa", "@launch_success").
static func entry(key: String) -> Dictionary:
	var group := "events" if key.begins_with("@") else "screens"
	return map().get(group, {}).get(key, {})


## Resolve a key to {source: "original"|"ours"|"", path or stem}. `source` is the player's
## setting; `dir` the original-music folder.
static func resolve(key: String, source: String, dir: String) -> Dictionary:
	var e := entry(key)
	if e.is_empty():
		return {"source": ""}
	if source == "original" and dir != "":
		var idx := index_folder(dir)
		for stem in e.get("original", []):
			if idx.has(str(stem).to_lower()):
				return {"source": "original", "path": idx[str(stem).to_lower()], "stem": str(stem)}
	var ours := str(e.get("ours", ""))
	return {"source": "ours", "stem": ours} if ours != "" else {"source": ""}


## Load an audio file from anywhere on disk (outside res://).
static func load_external(path: String) -> AudioStream:
	match path.get_extension().to_lower():
		"ogg":
			return AudioStreamOggVorbis.load_from_file(path)
		"mp3":
			var mp3 := AudioStreamMP3.new()
			mp3.data = FileAccess.get_file_as_bytes(path)
			return mp3 if not mp3.data.is_empty() else null
		"wav":
			return AudioStreamWAV.load_from_file(path)
	return null
