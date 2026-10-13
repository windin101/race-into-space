class_name Sides
extends RefCounted
## The faction registry (data/sides.json). Everything that varies by side and is not a
## game rule lives there: names, colours, sites, agencies, reviewers, which text-deck slot
## and personnel rules a side uses. Code asks this class; it never names a side.

const PATH := "res://data/sides.json"

static var _data: Dictionary = {}
static var _by_id: Dictionary = {}


static func _load() -> void:
	if not _data.is_empty():
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text()) if f != null else null
	_data = parsed if parsed is Dictionary else {"sides": [], "default": ["usa", "ussr"], "min_sides": 2, "max_sides": 2}
	for s in _data.get("sides", []):
		_by_id[s["id"]] = s


## Register an extra side at runtime (tests use this to prove the game is not tied to a
## fixed set). Overrides an existing id.
static func register(entry: Dictionary) -> void:
	_load()
	var list: Array = _data["sides"]
	for i in list.size():
		if list[i]["id"] == entry["id"]:
			list.remove_at(i)
			break
	list.append(entry)
	_by_id[entry["id"]] = entry


static func unregister(id: String) -> void:
	_load()
	var list: Array = _data["sides"]
	for i in list.size():
		if list[i]["id"] == id:
			list.remove_at(i)
			break
	_by_id.erase(id)


## Every side id, in registry order.
static func ids() -> PackedStringArray:
	_load()
	var out: PackedStringArray = []
	for s in _data["sides"]:
		out.append(s["id"])
	return out


static func default_lineup() -> PackedStringArray:
	_load()
	return PackedStringArray(_data.get("default", ["usa", "ussr"]))


static func min_sides() -> int:
	_load()
	return int(_data.get("min_sides", 2))


static func max_sides() -> int:
	_load()
	return mini(int(_data.get("max_sides", 2)), ids().size())


static func exists(id: String) -> bool:
	_load()
	return _by_id.has(id)


static func get_entry(id: String) -> Dictionary:
	_load()
	return _by_id.get(id, {})


static func field(id: String, key: String, fallback: Variant = "") -> Variant:
	return get_entry(id).get(key, fallback)


static func name(id: String) -> String:
	return str(field(id, "name", id.to_upper()))


static func short(id: String) -> String:
	return str(field(id, "short", id.to_upper()))


static func adjective(id: String) -> String:
	return str(field(id, "adjective", name(id)))


static func nation(id: String) -> String:
	return str(field(id, "nation", name(id)))


static func colour(id: String, key := "accent") -> Color:
	return Color(str(field(id, key, "888888")))


static func text_slot(id: String) -> int:
	return int(field(id, "text_slot", 0))


static func rules(id: String) -> String:
	return str(field(id, "rules", id))


## Head of state for a two-digit year, from the side's [[last_year, name], ...] list.
static func head_of_state(id: String, year: int) -> String:
	for band in field(id, "heads_of_state", []):
		if year <= int(band[0]):
			return str(band[1])
	return ""


## Reviewer shown for a review index: the deputy inside [from, to], else the head.
static func reviewer(id: String, index: int) -> String:
	var from := int(field(id, "reviewer_deputy_from", 99))
	var to := int(field(id, "reviewer_deputy_to", -1))
	if index >= from and index <= to:
		return str(field(id, "reviewer_deputy", ""))
	return str(field(id, "reviewer", ""))


## A per-side data block (hardware, roster, new game, text decks) for `id`, with a load-
## time error that names the side and the file when it is missing.
static func block(source: Dictionary, id: String, what: String) -> Variant:
	if not source.has(id):
		push_error("Side '%s' has no entry in %s" % [id, what])
		return null
	return source[id]
