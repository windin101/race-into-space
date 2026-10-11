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


static func icon(name: String) -> Texture2D:
	var svg := texture("icons/%s.svg" % name)
	return svg if svg != null else texture("icons/%s.png" % name)


## Frames of a vignette clip, or [] when none are provided. Looks for
## vignettes/<family>_<ok|fail>/frame_*.png sorted by name.
static func vignette_frames(family: String, ok: bool) -> Array:
	var key := "%s_%s" % [family, "ok" if ok else "fail"]
	if _frames_cache.has(key):
		return _frames_cache[key]
	var frames: Array = []
	var dir_path := ROOT + "vignettes/" + key
	var dir := DirAccess.open(dir_path)
	if dir != null:
		var names: Array = []
		dir.list_dir_begin()
		var entry := dir.get_next()
		while entry != "":
			if not dir.current_is_dir() and entry.begins_with("frame_") and entry.ends_with(".png"):
				names.append(entry)
			entry = dir.get_next()
		names.sort()
		for n in names:
			var tex: Texture2D = texture("vignettes/%s/%s" % [key, n])
			if tex != null:
				frames.append(tex)
	_frames_cache[key] = frames
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
