class_name SimSave
extends RefCounted
## Save and load a whole game. to_dict() captures everything SimGame needs to resume
## (seed, options, RNG state, calendar, prestige ledger, event deck and both players);
## from_dict() rebuilds it. Slots are JSON files under user://saves/.
##
## Only JSON-safe values are written. Godot's JSON reads every number back as a float, so
## integral floats are turned back into ints on load; Dictionary keys that were ints
## (astronaut ids in crew_outcomes) are tagged with INT_KEY_PREFIX so they come back as
## ints too. The 64-bit RNG state and the seed are stored as strings because JSON numbers
## lose precision above 2^53.

const SAVE_DIR := "user://saves"
const FORMAT := 1
const INT_KEY_PREFIX := "#"

## Plain SimPlayer vars copied field by field (untyped arrays and dictionaries included).
const PLAYER_FIELDS := [
	"index", "side", "director_name", "level", "astronaut_level", "is_ai",
	"cash", "budget", "prestige", "prestige_total", "spending_this_season",
	"rd_mods_turn", "rd_mods_year", "turn_flags", "save_cards", "bad_card_flags", "last_news",
	"recruit_group", "recruit_delay", "female_allowed",
	"duration_level", "lm_points", "docking_module_in_orbit",
	"missions", "future", "mission_log", "catastrophe_flags", "reviews", "review_index",
]
## SimPlayer typed arrays (restored with Array.assign so the element type is kept).
const PLAYER_TYPED_ARRAYS := ["prestige_history", "budget_history", "pads", "milestones"]

## SimProgram runtime vars (spec is rebuilt from the hardware table).
const PROGRAM_FIELDS := [
	"owned", "safety", "max_rd", "max_rd_original", "units", "delay", "researched_this_season",
	"mission_safety", "damage", "damage_cost", "unit_cost_extra", "rd_cost_extra",
	"max_safety_extra", "flights", "successes", "failures",
]

const ASTRONAUT_FIELDS := [
	"id", "name", "female", "race", "service", "skills", "mood", "compat", "compat_left",
	"compat_right", "status", "seasons_in_status", "injured_until_seasons", "retire_in_seasons",
	"retire_reason", "death_reason", "program_group", "program_slot", "crew_index",
	"crew_position", "seasons_in_program", "previous_program_slot", "seasons_active",
	"moved_this_season", "training_focus", "training_seasons_left", "missions_flown", "hero",
	"mission_history",
]
const ASTRONAUT_TYPED_ARRAYS := ["medals"]


# --- game <-> dictionary -----------------------------------------------------------

static func to_dict(game: SimGame) -> Dictionary:
	var state := game.state
	var players: Array = []
	for p in state.players:
		players.append(_player_to_dict(p))
	return {
		"format": FORMAT,
		"seed": str(state.seed_value),
		"options": _pack(state.options),
		"model": state.model,
		"rng_state": str(state.rng.save_state()),
		"year": state.year,
		"season": state.season,
		"turn_number": game.turn_number,
		"ended": state.ended,
		"winner": state.winner,
		"end_reason": state.end_reason,
		"turn_log": Array(state.turn_log),
		"last_turn_report": _pack(game.last_turn_report),
		"prestige_rows": _pack(state.prestige_rows),
		"event_deck": Array(state.event_deck),
		"players": players,
	}


## Rebuild a game. SimGame's constructor deals a deck and runs the first turn's
## newscast; everything it touched is overwritten here and begin_turn is not re-run.
static func from_dict(data, d: Dictionary) -> SimGame:
	d = _unpack(d)
	var options: Dictionary = d.get("options", {})
	var game := SimGame.new(data, _to_int(d.get("seed", 0)), options)
	var state := game.state
	state.model = d.get("model", state.model)
	state.rng.restore_state(_to_int(d.get("rng_state", 0)))
	state.year = int(d.get("year", state.year))
	state.season = int(d.get("season", state.season))
	game.turn_number = int(d.get("turn_number", game.turn_number))
	state.ended = bool(d.get("ended", false))
	state.winner = int(d.get("winner", -1))
	state.end_reason = str(d.get("end_reason", ""))
	state.turn_log.assign(d.get("turn_log", []))
	game.last_turn_report = d.get("last_turn_report", {})
	state.prestige_rows = d.get("prestige_rows", state.prestige_rows)
	state.event_deck.assign(d.get("event_deck", []))
	var players: Array = d.get("players", [])
	for i in mini(players.size(), state.players.size()):
		_player_from_dict(state.players[i], players[i])
	return game


static func _player_to_dict(p: SimPlayer) -> Dictionary:
	var out := {}
	for f in PLAYER_FIELDS:
		out[f] = _pack(p.get(f))
	for f in PLAYER_TYPED_ARRAYS:
		out[f] = Array(p.get(f))
	var programs := {}
	for group in SimProgram.GROUPS:
		var slots: Array = []
		for prog in p.programs[group]:
			slots.append(null if prog == null else _program_to_dict(prog))
		programs[group] = slots
	out["programs"] = programs
	var astronauts: Array = []
	for a in p.astronauts:
		astronauts.append(_astronaut_to_dict(a))
	out["astronauts"] = astronauts
	return out


static func _player_from_dict(p: SimPlayer, d: Dictionary) -> void:
	for f in PLAYER_FIELDS:
		if d.has(f):
			p.set(f, d[f])
	for f in PLAYER_TYPED_ARRAYS:
		if d.has(f):
			p.get(f).assign(d[f])
	var programs: Dictionary = d.get("programs", {})
	for group in SimProgram.GROUPS:
		var slots: Array = programs.get(group, [])
		for slot in mini(slots.size(), p.programs[group].size()):
			var prog: SimProgram = p.programs[group][slot]
			if prog != null and slots[slot] != null:
				_program_from_dict(prog, slots[slot])
	p.astronauts = []
	for ad in d.get("astronauts", []):
		p.astronauts.append(_astronaut_from_dict(ad))


static func _program_to_dict(prog: SimProgram) -> Dictionary:
	var out := {"group": prog.group, "slot": prog.slot}
	for f in PROGRAM_FIELDS:
		out[f] = prog.get(f)
	return out


static func _program_from_dict(prog: SimProgram, d: Dictionary) -> void:
	for f in PROGRAM_FIELDS:
		if d.has(f):
			prog.set(f, d[f])


static func _astronaut_to_dict(a: SimAstronaut) -> Dictionary:
	var out := {}
	for f in ASTRONAUT_FIELDS:
		out[f] = _pack(a.get(f))
	for f in ASTRONAUT_TYPED_ARRAYS:
		out[f] = Array(a.get(f))
	return out


static func _astronaut_from_dict(d: Dictionary) -> SimAstronaut:
	var a := SimAstronaut.new()
	for f in ASTRONAUT_FIELDS:
		if d.has(f):
			a.set(f, d[f])
	for f in ASTRONAUT_TYPED_ARRAYS:
		if d.has(f):
			a.get(f).assign(d[f])
	return a


# --- slots on disk ------------------------------------------------------------------

static func slot_path(slot: String) -> String:
	return "%s/%s.json" % [SAVE_DIR, slot]


## The side the human plays: the first non-AI player, or USA when both are AI.
static func human_side_of(game: SimGame) -> String:
	for p in game.state.players:
		if not p.is_ai:
			return p.side
	return "usa"


static func save_slot(game: SimGame, slot: String, label: String) -> bool:
	if game == null or not _valid_slot(slot):
		return false
	var base := DirAccess.open("user://")
	if base == null or base.make_dir_recursive("saves") != OK:
		push_error("SimSave: cannot create %s" % SAVE_DIR)
		return false
	var file := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("SimSave: cannot write %s (%s)" % [slot_path(slot), error_string(FileAccess.get_open_error())])
		return false
	var payload := {
		"meta": {
			"label": label,
			"side": human_side_of(game),
			"date": game.state.date_string(),
			"saved_at": Time.get_datetime_string_from_system(false, true),
			"seed": game.state.seed_value,
		},
		"game": to_dict(game),
	}
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return true


static func load_slot(data, slot: String) -> SimGame:
	var payload := _read_slot(slot)
	if payload.is_empty() or not payload.get("game") is Dictionary:
		return null
	return from_dict(data, payload["game"])


## Metadata of every slot, newest first. Each entry carries its "slot" name.
static func list_slots() -> Array:
	var out: Array = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return out
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.ends_with(".json"):
			var slot := entry.get_basename()
			var payload := _read_slot(slot)
			if payload.get("meta") is Dictionary:
				var meta: Dictionary = payload["meta"].duplicate()
				meta["slot"] = slot
				out.append(meta)
		entry = dir.get_next()
	dir.list_dir_end()
	out.sort_custom(func(a, b): return str(a.get("saved_at", "")) > str(b.get("saved_at", "")))
	return out


static func delete_slot(slot: String) -> bool:
	if not _valid_slot(slot):
		return false
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null or not dir.file_exists(entry_name(slot)):
		return false
	return dir.remove(entry_name(slot)) == OK


static func entry_name(slot: String) -> String:
	return slot + ".json"


static func _read_slot(slot: String) -> Dictionary:
	if not _valid_slot(slot) or not FileAccess.file_exists(slot_path(slot)):
		return {}
	var raw := FileAccess.get_file_as_string(slot_path(slot))
	var json := JSON.new()
	if json.parse(raw) != OK:
		push_error("SimSave: %s line %d: %s" % [slot_path(slot), json.get_error_line(), json.get_error_message()])
		return {}
	if not json.data is Dictionary:
		return {}
	return _unpack(json.data)


static func _valid_slot(slot: String) -> bool:
	return slot != "" and slot.is_valid_filename() and not slot.begins_with(".")


# --- JSON-safe conversion ----------------------------------------------------------

## Deep copy keeping only JSON types; int keys are tagged so they survive the trip.
static func _pack(value: Variant) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			var dict := {}
			for k in value:
				var key: String
				if typeof(k) == TYPE_INT:
					key = INT_KEY_PREFIX + str(k)
				else:
					key = str(k)
				dict[key] = _pack(value[k])
			return dict
		TYPE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, \
				TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_BYTE_ARRAY:
			var arr: Array = []
			for v in value:
				arr.append(_pack(v))
			return arr
		TYPE_STRING_NAME:
			return String(value)
		TYPE_OBJECT:
			push_warning("SimSave: object %s dropped from save data" % str(value))
			return null
	return value


## Inverse of _pack after JSON parsing: integral floats to int, tagged keys to int.
static func _unpack(value: Variant) -> Variant:
	match typeof(value):
		TYPE_FLOAT:
			return int(value) if value == floor(value) else value
		TYPE_ARRAY:
			var arr: Array = []
			for v in value:
				arr.append(_unpack(v))
			return arr
		TYPE_DICTIONARY:
			var dict := {}
			for k in value:
				var key: Variant = k
				if typeof(k) == TYPE_STRING and k.begins_with(INT_KEY_PREFIX) and k.substr(1).is_valid_int():
					key = int(k.substr(1))
				dict[key] = _unpack(value[k])
			return dict
	return value


static func _to_int(v: Variant) -> int:
	if typeof(v) == TYPE_STRING:
		return v.to_int()
	return int(v)
