class_name ArtAssets
extends RefCounted
## Drop-in art loader. Every painter asks here first; when a file exists under
## res://assets/art/ it is used, otherwise the painter draws procedurally. Paths and
## naming follow docs/art-asset-list.md. Lookups are cached, including misses.

const ROOT := "res://assets/art/"

static var _cache: Dictionary = {}
static var _frames_cache: Dictionary = {}


static func texture(rel: String) -> Texture2D:
	var path := ROOT + rel
	if _cache.has(path):
		return _cache[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			tex = res
	_cache[path] = tex
	return tex


static func has(rel: String) -> bool:
	return texture(rel) != null


static func spaceport_layer(side: String, layer: String) -> Texture2D:
	return texture("spaceport/%s/%s.png" % [side, layer])


static func hardware(side: String, group: String, slot: int) -> Texture2D:
	return texture("hardware/%s/%s_%d.png" % [side, group, slot])


static func portrait(name: String) -> Texture2D:
	return texture("portraits/%s.png" % name.to_upper())


static func backdrop(name: String) -> Texture2D:
	return texture("backdrops/%s.png" % name)


## Mission patch for a side and mission index (assets/art/patches/<side>/mission_<i>.png).
static func patch(side: String, index: int) -> Texture2D:
	return texture("patches/%s/mission_%d.png" % [side, index])


static func icon(name: String) -> Texture2D:
	var svg := texture("icons/%s.svg" % name)
	return svg if svg != null else texture("icons/%s.png" % name)


## Frames of a vignette clip, or [] when none are provided. Tries, in order,
## vignettes/<family>_<ok|fail>/<side>/<slot>/, then /<side>/, then the family folder, each
## holding frame_*.{png,webp,jpg} sorted by name; the first that has frames wins.
static func vignette_frames(family: String, ok: bool, side: String = "", slot: String = "") -> Array:
	var key := "%s_%s" % [family, "ok" if ok else "fail"]
	var candidates: Array = []
	if side != "" and slot != "":
		candidates.append("%s/%s/%s" % [key, side, slot])
	if side != "":
		candidates.append("%s/%s" % [key, side])
	candidates.append(key)
	for rel in candidates:
		var frames := _frames_in(rel)
		if not frames.is_empty():
			return frames
	return []


static func _frames_in(rel: String) -> Array:
	if _frames_cache.has(rel):
		return _frames_cache[rel]
	var frames: Array = []
	var dir := DirAccess.open(ROOT + "vignettes/" + rel)
	if dir != null:
		var names: Array = []
		dir.list_dir_begin()
		var entry := dir.get_next()
		while entry != "":
			if not dir.current_is_dir() and entry.begins_with("frame_") and (entry.ends_with(".png") or entry.ends_with(".webp") or entry.ends_with(".jpg")):
				names.append(entry)
			entry = dir.get_next()
		names.sort()
		for n in names:
			var tex: Texture2D = texture("vignettes/%s/%s" % [rel, n])
			if tex != null:
				frames.append(tex)
	_frames_cache[rel] = frames
	return frames


## Draw a texture scaled to cover a rect, preserving aspect and centring (crop overflow
## is the caller's job via clip_contents).
static func draw_cover(c: CanvasItem, tex: Texture2D, rect: Rect2) -> void:
	var ts := tex.get_size()
	if ts.x <= 0 or ts.y <= 0:
		return
	var scale := maxf(rect.size.x / ts.x, rect.size.y / ts.y)
	var size := ts * scale
	var pos := rect.position + (rect.size - size) / 2.0
	c.draw_texture_rect(tex, Rect2(pos, size), false)


## Draw a texture fitted inside a rect, preserving aspect and centring.
static func draw_fit(c: CanvasItem, tex: Texture2D, rect: Rect2) -> void:
	var ts := tex.get_size()
	if ts.x <= 0 or ts.y <= 0:
		return
	var scale := minf(rect.size.x / ts.x, rect.size.y / ts.y)
	var size := ts * scale
	var pos := rect.position + (rect.size - size) / 2.0
	c.draw_texture_rect(tex, Rect2(pos, size), false)


static func clear_cache() -> void:
	_cache.clear()
	_frames_cache.clear()
