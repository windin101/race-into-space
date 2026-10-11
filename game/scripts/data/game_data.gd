extends Node
## Autoload "GameData": loads every table in res://data/ once at startup.
##
## The simulation reads from these dictionaries and never from the upstream clone.
## All numbers in the game come from here (or from constants.json), never from literals.

const DATA_DIR := "res://data/"

var hardware: Dictionary        ## hardware.json  -> models.basic/historical . usa/ussr . group . [slot]
var prestige: Array             ## prestige.json  -> rows[28]
var missions: Array             ## missions.json  -> missions[62], index == array position
var failures: Array             ## failures.json  -> failures[925]
var roster: Dictionary          ## roster.json    -> sides.usa/ussr . [group]
var budget_adjustments: Dictionary
var new_game: Dictionary
var constants: Dictionary       ## constants.json -> code-derived rules (may be absent during early dev)
var text: Dictionary = {}       ## text/*.json keyed by basename

var loaded := false
var load_errors: PackedStringArray = []


func _ready() -> void:
	load_all()


func load_all() -> void:
	load_errors.clear()
	hardware = _load_json("hardware.json")
	prestige = _load_json("prestige.json").get("rows", [])
	missions = _load_json("missions.json").get("missions", [])
	failures = _load_json("failures.json").get("failures", [])
	roster = _load_json("roster.json")
	budget_adjustments = _load_json("budget_adjustments.json")
	new_game = _load_json("new_game.json")
	constants = _load_json("constants.json", true)
	for name in ["events", "news", "reviews", "endgame", "help"]:
		text[name] = _load_json("text/%s.json" % name)
	loaded = load_errors.is_empty()
	if not loaded:
		push_error("GameData: %d file(s) failed to load: %s" % [load_errors.size(), ", ".join(load_errors)])


## Hardware record for a side, model, group and slot; null for an empty slot.
func equipment(model: String, side: String, group: String, slot: int) -> Variant:
	var groups: Dictionary = hardware["models"][model][side]
	return groups[group][slot]


## Every non-empty hardware record for a side and model, as a flat array.
func equipment_list(model: String, side: String) -> Array:
	var out: Array = []
	for group in ["probe", "rocket", "manned", "misc"]:
		for rec in hardware["models"][model][side][group]:
			if rec != null:
				out.append(rec)
	return out


func prestige_row(key: String) -> Dictionary:
	for row in prestige:
		if row["key"] == key:
			return row
	push_error("GameData: no prestige row '%s'" % key)
	return {}


func mission(index: int) -> Dictionary:
	return missions[index]


func _load_json(rel_path: String, optional := false) -> Variant:
	var path := DATA_DIR + rel_path
	if not FileAccess.file_exists(path):
		if not optional:
			load_errors.append(rel_path + " (missing)")
		return {}
	var raw := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	var err := json.parse(raw)
	if err != OK:
		load_errors.append("%s (line %d: %s)" % [rel_path, json.get_error_line(), json.get_error_message()])
		return {}
	return _intify(json.data)


## Godot's JSON parser yields every number as float. Every table value in this project
## is an integer, so convert integral floats back to int recursively.
static func _intify(value: Variant) -> Variant:
	match typeof(value):
		TYPE_FLOAT:
			return int(value) if value == floor(value) else value
		TYPE_ARRAY:
			var arr: Array = []
			for v in value:
				arr.append(_intify(v))
			return arr
		TYPE_DICTIONARY:
			var dict: Dictionary = {}
			for k in value:
				dict[k] = _intify(value[k])
			return dict
	return value
