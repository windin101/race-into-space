class_name TextCase
extends RefCounted
## Sentence case for the upstream prose, which is all capitals. Godot's capitalize() title-
## cases every word and mangles acronyms ("The Kgb", "10 M.b.'s"); this lowercases, applies
## the casing map in data/text/casing.json (proper nouns, acronyms, "I") and capitalises the
## first letter of each sentence. Text already in mixed case is returned unchanged.

const MAP_PATH := "res://data/text/casing.json"
static var _words: Dictionary = {}
static var _loaded := false
static var _token := RegEx.create_from_string("[A-Za-z][A-Za-z0-9.'&-]*[A-Za-z0-9]|[A-Za-z]")


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var f := FileAccess.open(MAP_PATH, FileAccess.READ)
	if f != null:
		var d = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			_words = d.get("words", {})


## True when the text has letters and none of them are lowercase.
static func is_shouting(s: String) -> bool:
	return s != s.to_lower() and s == s.to_upper()


static func sentence(s: String) -> String:
	if not is_shouting(s):
		return s
	_load()
	var out := ""
	var last := 0
	for m in _token.search_all(s):
		out += s.substr(last, m.get_start() - last)
		out += _word(m.get_string())
		last = m.get_end()
	out += s.substr(last)
	return _sentence_starts(out)


static func _word(w: String) -> String:
	var key := w.to_upper()
	var trail := ""
	# a trailing full stop is sentence punctuation unless the dotted form is in the map
	if key.ends_with(".") and not _words.has(key):
		key = key.substr(0, key.length() - 1)
		trail = "."
	if _words.has(key):
		return str(_words[key]) + trail
	return w.to_lower()


static func _sentence_starts(s: String) -> String:
	var chars := s.split("")
	var start := true
	for i in chars.size():
		var c := chars[i]
		if start and c.to_lower() != c.to_upper():
			chars[i] = c.to_upper()
			start = false
		elif c in [".", "!", "?"]:
			start = true
		elif c != " " and c != "\"" and c != "'" and c != "(":
			if c.to_lower() != c.to_upper():
				start = false
	return "".join(chars)
