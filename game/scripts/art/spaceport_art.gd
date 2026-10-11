class_name SpaceportArt
extends RefCounted
## Procedural painting of the two spaceports. Draws sky, sea or steppe, horizon, pads with
## gantries and the buildings in the layout file, each as flat-shaded vector shapes in a
## side-specific palette. Resolution independent: paint() takes the canvas size.
##
## Layout rectangles come from data/ui/spaceport_layout.json as canvas fractions, so the
## hotspots and the painting always agree.

const SKY_USA_TOP := Color("6fa6d9")
const SKY_USA_BOTTOM := Color("dfe9f1")
const SEA := Color("2a6b9c")
const SAND := Color("d9c9a3")
const SCRUB := Color("8ea86c")
const SKY_USSR_TOP := Color("8a9db5")
const SKY_USSR_BOTTOM := Color("e3dccd")
const STEPPE := Color("b9a76f")
const STEPPE_DARK := Color("9a8a5a")
const CONCRETE := Color("c9c6bd")
const CONCRETE_DARK := Color("9a978f")
const ROOF := Color("8c8f94")
const WALL := Color("e6e2d8")
const WALL_SHADE := Color("b8b3a7")
const WINDOW := Color("3d4a5c")
const STEEL := Color("5c6470")
const ROAD := Color("6d6a63")
const SHADOW := Color(0, 0, 0, 0.18)


## Paint the whole scene. buildings: Array of layout dicts with x, y, w, h, id, built (bool).
static func paint(c: CanvasItem, size: Vector2, side: String, buildings: Array, pads_state: Array, season: int = 0) -> void:
	var usa := side == "usa"
	# Sky gradient as horizontal bands.
	var horizon := size.y * 0.36
	var top: Color = SKY_USA_TOP if usa else SKY_USSR_TOP
	var bottom: Color = SKY_USA_BOTTOM if usa else SKY_USSR_BOTTOM
	var bands := 24
	for i in bands:
		var y0 := horizon * i / bands
		var y1 := horizon * (i + 1) / bands
		c.draw_rect(Rect2(0, y0, size.x, y1 - y0 + 1), top.lerp(bottom, float(i) / bands))
	_clouds(c, size, horizon, usa)
	if usa:
		# Atlantic beyond the Cape, then sand and scrub.
		c.draw_rect(Rect2(0, horizon, size.x, size.y * 0.05), SEA)
		c.draw_rect(Rect2(0, horizon + size.y * 0.05, size.x, size.y * 0.025), SAND)
		c.draw_rect(Rect2(0, horizon + size.y * 0.075, size.x, size.y - horizon), SCRUB)
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in 60:
			var px := rng.randf() * size.x
			var py := horizon + size.y * 0.08 + rng.randf() * (size.y - horizon - size.y * 0.08)
			c.draw_circle(Vector2(px, py), size.y * (0.004 + rng.randf() * 0.01), SCRUB.darkened(0.25))
	else:
		c.draw_rect(Rect2(0, horizon, size.x, size.y - horizon), STEPPE)
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		for i in 50:
			var px := rng.randf() * size.x
			var py := horizon + rng.randf() * (size.y - horizon)
			c.draw_rect(Rect2(px, py, size.x * (0.01 + rng.randf() * 0.03), size.y * 0.004), STEPPE_DARK)
		if season == 1:
			c.draw_rect(Rect2(0, horizon, size.x, size.y - horizon), Color(1, 1, 1, 0.12))
	# Roads linking the compound to the pads.
	c.draw_line(Vector2(size.x * 0.2, size.y * 0.78), Vector2(size.x * 0.9, size.y * 0.78), ROAD, size.y * 0.012)
	c.draw_line(Vector2(size.x * 0.52, size.y * 0.78), Vector2(size.x * 0.7, size.y * 0.52), ROAD, size.y * 0.01)
	c.draw_line(Vector2(size.x * 0.7, size.y * 0.52), Vector2(size.x * 0.9, size.y * 0.76), ROAD, size.y * 0.01)
	# Buildings and pads from the layout.
	for b in buildings:
		var r := Rect2(Vector2(b["x"] * size.x, b["y"] * size.y), Vector2(b["w"] * size.x, b["h"] * size.y))
		var id: String = b["id"]
		var built: bool = b.get("built", true)
		if id.begins_with("pad_"):
			var idx := int(id.substr(4)) - 1
			var st: int = pads_state[idx] if idx < pads_state.size() else -1
			_pad(c, r, st, side)
		elif built:
			_building(c, r, id, side)
		else:
			_plot(c, r)
	_flag(c, size, side)


static func _clouds(c: CanvasItem, size: Vector2, horizon: float, usa: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3 if usa else 5
	for i in 7:
		var cx := rng.randf() * size.x
		var cy := horizon * (0.15 + rng.randf() * 0.5)
		var w := size.x * (0.05 + rng.randf() * 0.08)
		for j in 4:
			c.draw_circle(Vector2(cx + (j - 1.5) * w * 0.35, cy + (j % 2) * w * 0.08), w * (0.22 + rng.randf() * 0.1), Color(1, 1, 1, 0.75))


static func _building(c: CanvasItem, r: Rect2, id: String, side: String) -> void:
	var depth := r.size.y * 0.22
	# Drop shadow, then the front face and the roof slab.
	c.draw_rect(Rect2(r.position + Vector2(r.size.x * 0.03, r.size.y * 0.06), r.size), SHADOW)
	var front := Rect2(r.position + Vector2(0, depth), Vector2(r.size.x, r.size.y - depth))
	c.draw_rect(front, WALL)
	c.draw_rect(Rect2(front.position, Vector2(front.size.x * 0.08, front.size.y)), WALL_SHADE)
	var roof := PackedVector2Array([r.position + Vector2(0, depth), r.position + Vector2(r.size.x * 0.12, 0), r.position + Vector2(r.size.x, 0), r.position + Vector2(r.size.x * 0.88, depth)])
	c.draw_colored_polygon(roof, ROOF)
	match id:
		"vab":
			# Tall assembly hall with a vertical door stripe and side accent.
			c.draw_rect(Rect2(front.position + Vector2(front.size.x * 0.4, front.size.y * 0.15), Vector2(front.size.x * 0.2, front.size.y * 0.85)), STEEL)
			c.draw_rect(Rect2(front.position + Vector2(front.size.x * 0.12, front.size.y * 0.1), Vector2(front.size.x * 0.2, front.size.y * 0.12)), UiPalette.accent(side))
			c.draw_rect(Rect2(front.position + Vector2(front.size.x * 0.68, front.size.y * 0.1), Vector2(front.size.x * 0.2, front.size.y * 0.12)), UiPalette.accent(side))
		"mission_control":
			_windows(c, front, 6, 2)
			c.draw_circle(Vector2(r.position.x + r.size.x * 0.85, r.position.y + depth * 0.4), r.size.y * 0.12, STEEL)
			c.draw_line(Vector2(r.position.x + r.size.x * 0.85, r.position.y + depth * 0.4), Vector2(r.position.x + r.size.x * 0.85, r.position.y + depth), STEEL, 2.0)
		"administration":
			_windows(c, front, 7, 3)
			c.draw_rect(Rect2(front.position + Vector2(front.size.x * 0.42, front.size.y * 0.55), Vector2(front.size.x * 0.16, front.size.y * 0.45)), WINDOW)
		"research":
			_windows(c, front, 5, 2)
			c.draw_rect(Rect2(r.position + Vector2(r.size.x * 0.3, -r.size.y * 0.25), Vector2(r.size.x * 0.05, r.size.y * 0.3)), STEEL)
			c.draw_circle(r.position + Vector2(r.size.x * 0.325, -r.size.y * 0.25), r.size.y * 0.06, STEEL)
		"astronaut_complex":
			_windows(c, front, 8, 2)
			c.draw_rect(Rect2(front.position + Vector2(front.size.x * 0.1, front.size.y * 0.7), Vector2(front.size.x * 0.8, front.size.y * 0.08)), UiPalette.accent(side))
		"training":
			_windows(c, front, 4, 2)
			c.draw_circle(front.position + Vector2(front.size.x * 0.8, front.size.y * 0.5), front.size.y * 0.3, STEEL)
		"museum":
			for i in 5:
				c.draw_rect(Rect2(front.position + Vector2(front.size.x * (0.1 + i * 0.18), front.size.y * 0.1), Vector2(front.size.x * 0.05, front.size.y * 0.9)), WALL_SHADE)
		"intelligence":
			c.draw_rect(front, WALL_SHADE.darkened(0.2))
			_windows(c, front, 3, 1)
		"programs":
			_windows(c, front, 6, 2)
			c.draw_rect(Rect2(front.position + Vector2(0, front.size.y * 0.45), Vector2(front.size.x, front.size.y * 0.06)), UiPalette.accent_dark(side))
		_:
			_windows(c, front, 5, 2)


static func _windows(c: CanvasItem, front: Rect2, cols: int, rows: int) -> void:
	var pad := front.size.x * 0.06
	var w := (front.size.x - pad * 2) / cols
	var h := (front.size.y - pad * 2) / (rows + 1)
	for r in rows:
		for col in cols:
			c.draw_rect(Rect2(front.position + Vector2(pad + col * w + w * 0.2, pad + r * h + h * 0.25), Vector2(w * 0.6, h * 0.5)), WINDOW)


static func _plot(c: CanvasItem, r: Rect2) -> void:
	# Cleared ground where a building will go.
	c.draw_rect(r, Color(CONCRETE_DARK, 0.25))
	c.draw_rect(r, Color(CONCRETE_DARK, 0.5), false, 1.5)


static func _pad(c: CanvasItem, r: Rect2, state: int, side: String) -> void:
	var apron := Rect2(r.position + Vector2(0, r.size.y * 0.55), Vector2(r.size.x, r.size.y * 0.45))
	if state == -1:
		c.draw_rect(apron, Color(CONCRETE_DARK, 0.3))
		c.draw_rect(apron, Color(CONCRETE_DARK, 0.6), false, 1.5)
		return
	c.draw_rect(Rect2(apron.position + Vector2(apron.size.x * 0.03, apron.size.y * 0.1), apron.size), SHADOW)
	c.draw_rect(apron, CONCRETE)
	c.draw_rect(Rect2(apron.position, Vector2(apron.size.x, apron.size.y * 0.12)), CONCRETE_DARK)
	# Gantry tower.
	var tx := r.position.x + r.size.x * 0.7
	c.draw_rect(Rect2(tx, r.position.y, r.size.x * 0.1, r.size.y * 0.6), STEEL)
	for i in 5:
		var y := r.position.y + r.size.y * 0.1 * (i + 1)
		c.draw_line(Vector2(tx, y), Vector2(tx + r.size.x * 0.1, y - r.size.y * 0.05), STEEL.lightened(0.3), 1.5)
	c.draw_line(Vector2(tx, r.position.y + r.size.y * 0.15), Vector2(r.position.x + r.size.x * 0.4, r.position.y + r.size.y * 0.15), STEEL, r.size.y * 0.03)
	if state > 0:
		# Damage: scorched apron and a bent tower.
		c.draw_rect(apron, Color(0.1, 0.08, 0.06, 0.55))
		c.draw_line(Vector2(tx + r.size.x * 0.05, r.position.y + r.size.y * 0.3), Vector2(tx + r.size.x * 0.3, r.position.y), UiPalette.DANGER, 3.0)
	else:
		c.draw_circle(Vector2(r.position.x + r.size.x * 0.4, r.position.y + r.size.y * 0.6), r.size.x * 0.05, UiPalette.accent(side))


static func _flag(c: CanvasItem, size: Vector2, side: String) -> void:
	var base := Vector2(size.x * 0.935, size.y * 0.24)
	c.draw_line(base, base + Vector2(0, -size.y * 0.14), STEEL, size.y * 0.004)
	var fw := size.x * 0.035
	var fh := size.y * 0.035
	var top := base + Vector2(0, -size.y * 0.14)
	if side == "usa":
		for i in 7:
			c.draw_rect(Rect2(top + Vector2(0, fh * i / 7.0), Vector2(fw, fh / 7.0)), Color("c0392b") if i % 2 == 0 else Color.WHITE)
		c.draw_rect(Rect2(top, Vector2(fw * 0.4, fh * 0.55)), Color("1f3a93"))
	else:
		c.draw_rect(Rect2(top, Vector2(fw, fh)), Color("c0392b"))
		c.draw_circle(top + Vector2(fw * 0.25, fh * 0.35), fh * 0.12, UiPalette.GOLD)
