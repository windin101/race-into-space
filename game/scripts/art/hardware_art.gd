class_name HardwareArt
extends RefCounted
## Procedural hardware illustrations: one silhouette per program slot, scaled by its
## role, in the side's colours. paint() draws into a rect on any CanvasItem.

const METAL := Color("dde0e5")
const METAL_DARK := Color("8e939b")
const DARK := Color("3b4047")
const GOLD := Color("d4a84b")
const PANEL := Color("2f4f8f")


static func paint(c: CanvasItem, rect: Rect2, group: String, slot: int, side: String) -> void:
	var tex := ArtAssets.hardware(side, group, slot)
	if tex != null:
		ArtAssets.draw_fit(c, tex, rect)
		return
	var accent := UiPalette.accent(side)
	match group:
		"rocket": _rocket(c, rect, slot, accent)
		"manned":
			if slot >= 5:
				_lm(c, rect, slot, accent)
			else:
				_capsule(c, rect, slot, accent)
		"probe": _probe(c, rect, slot, accent)
		"misc": _misc(c, rect, slot, accent)


static func _rocket(c: CanvasItem, r: Rect2, slot: int, accent: Color) -> void:
	# Height and width grow with the rocket class; boosters are a strap-on pair.
	var scale: float = [0.55, 0.7, 0.9, 1.0, 0.45][clampi(slot, 0, 4)]
	var h := r.size.y * 0.9 * scale
	var w := r.size.x * (0.14 + 0.05 * slot) * (0.6 if slot == 4 else 1.0)
	var base := Vector2(r.position.x + r.size.x * 0.5, r.end.y - r.size.y * 0.05)
	if slot == 4:
		for dx: float in [-1.0, 1.0]:
			var bx := base + Vector2(dx * w * 1.2, 0)
			c.draw_rect(Rect2(bx.x - w * 0.5, bx.y - h, w, h), METAL)
			c.draw_colored_polygon(PackedVector2Array([bx + Vector2(-w * 0.5, -h), bx + Vector2(w * 0.5, -h), bx + Vector2(0, -h - w)]), METAL_DARK)
		return
	c.draw_rect(Rect2(base.x - w * 0.5, base.y - h, w, h), METAL)
	var stages := 1 + mini(slot, 2)
	for s in range(1, stages + 1):
		var y := base.y - h * s / (stages + 1.0)
		c.draw_line(Vector2(base.x - w * 0.5, y), Vector2(base.x + w * 0.5, y), METAL_DARK, 1.5)
	c.draw_rect(Rect2(base.x - w * 0.5, base.y - h * 0.3, w, h * 0.08), accent)
	c.draw_colored_polygon(PackedVector2Array([base + Vector2(-w * 0.5, -h), base + Vector2(w * 0.5, -h), base + Vector2(0, -h - w * 1.4)]), METAL_DARK)
	c.draw_colored_polygon(PackedVector2Array([base + Vector2(-w * 0.5, 0), base + Vector2(-w * 1.1, w * 0.5), base + Vector2(-w * 0.5, -h * 0.15)]), DARK)
	c.draw_colored_polygon(PackedVector2Array([base + Vector2(w * 0.5, 0), base + Vector2(w * 1.1, w * 0.5), base + Vector2(w * 0.5, -h * 0.15)]), DARK)
	var engines := 1 + slot
	for e in engines:
		var ex := base.x - w * 0.4 + w * 0.8 * (e + 0.5) / engines
		c.draw_colored_polygon(PackedVector2Array([Vector2(ex - w * 0.12, base.y), Vector2(ex + w * 0.12, base.y), Vector2(ex, base.y + w * 0.25)]), DARK)


static func _capsule(c: CanvasItem, r: Rect2, slot: int, accent: Color) -> void:
	var cx := r.position.x + r.size.x * 0.5
	var s := r.size.y * (0.5 + 0.08 * slot)
	var top := r.position.y + r.size.y * 0.5 - s * 0.45
	match slot:
		3:
			# Minishuttle: delta body with wings.
			var pts := PackedVector2Array([Vector2(cx, top), Vector2(cx + s * 0.55, top + s * 0.9), Vector2(cx + s * 0.2, top + s * 0.95), Vector2(cx - s * 0.2, top + s * 0.95), Vector2(cx - s * 0.55, top + s * 0.9)])
			c.draw_colored_polygon(pts, METAL)
			c.draw_rect(Rect2(cx - s * 0.1, top + s * 0.25, s * 0.2, s * 0.6), accent)
			c.draw_circle(Vector2(cx, top + s * 0.3), s * 0.06, DARK)
		_:
			var wtop := s * (0.25 + 0.03 * slot)
			var wbot := s * (0.5 + 0.06 * slot)
			var pts := PackedVector2Array([Vector2(cx - wtop, top), Vector2(cx + wtop, top), Vector2(cx + wbot, top + s * 0.85), Vector2(cx - wbot, top + s * 0.85)])
			c.draw_colored_polygon(pts, METAL)
			c.draw_rect(Rect2(cx - wbot, top + s * 0.85, wbot * 2, s * 0.1), DARK)
			c.draw_rect(Rect2(cx - wtop, top + s * 0.08, wtop * 2, s * 0.06), accent)
			var seats: int = [1, 2, 3, 3, 4][slot]
			for i in seats:
				c.draw_circle(Vector2(cx - wbot * 0.5 + wbot * (i + 0.5) / seats, top + s * 0.5), s * 0.05, DARK)
			if slot == 4:
				c.draw_rect(Rect2(cx - wbot, top + s * 0.95, wbot * 2, s * 0.25), METAL_DARK)


static func _lm(c: CanvasItem, r: Rect2, slot: int, accent: Color) -> void:
	var cx := r.position.x + r.size.x * 0.5
	var s := r.size.y * (0.42 if slot == 6 else 0.5)
	var base := Vector2(cx, r.end.y - r.size.y * 0.12)
	c.draw_rect(Rect2(cx - s * 0.5, base.y - s * 0.6, s, s * 0.45), GOLD.darkened(0.3))
	c.draw_rect(Rect2(cx - s * 0.35, base.y - s * 1.1, s * 0.7, s * 0.5), METAL)
	c.draw_rect(Rect2(cx - s * 0.35, base.y - s * 0.68, s * 0.7, s * 0.06), accent)
	c.draw_circle(Vector2(cx - s * 0.12, base.y - s * 0.95), s * 0.06, DARK)
	c.draw_circle(Vector2(cx + s * 0.12, base.y - s * 0.95), s * 0.06, DARK)
	for dx: float in [-1.0, 1.0]:
		c.draw_line(base + Vector2(dx * s * 0.4, -s * 0.3), base + Vector2(dx * s * 0.8, 0), METAL_DARK, s * 0.06)
		c.draw_line(base + Vector2(dx * s * 0.8, 0), base + Vector2(dx * s * 0.95, 0), METAL_DARK, s * 0.06)


static func _probe(c: CanvasItem, r: Rect2, slot: int, accent: Color) -> void:
	var cx := r.position.x + r.size.x * 0.5
	var cy := r.position.y + r.size.y * 0.5
	var s := r.size.y * (0.22 + 0.06 * slot)
	match slot:
		0:
			# Small spinning satellite with antennae.
			c.draw_circle(Vector2(cx, cy), s * 0.5, METAL)
			c.draw_circle(Vector2(cx, cy), s * 0.3, accent)
			for a in [0.4, 1.4, 2.6, 3.9]:
				c.draw_line(Vector2(cx, cy), Vector2(cx, cy) + Vector2.RIGHT.rotated(a) * s * 1.2, METAL_DARK, 1.5)
		1:
			c.draw_rect(Rect2(cx - s * 0.3, cy - s * 0.3, s * 0.6, s * 0.6), METAL)
			c.draw_rect(Rect2(cx - s * 1.4, cy - s * 0.18, s * 1.0, s * 0.36), PANEL)
			c.draw_rect(Rect2(cx + s * 0.4, cy - s * 0.18, s * 1.0, s * 0.36), PANEL)
			c.draw_circle(Vector2(cx, cy - s * 0.6), s * 0.25, accent)
		_:
			# Lander: body on tripod legs.
			c.draw_rect(Rect2(cx - s * 0.45, cy - s * 0.3, s * 0.9, s * 0.4), METAL)
			c.draw_rect(Rect2(cx - s * 0.2, cy - s * 0.65, s * 0.4, s * 0.35), accent)
			for dx: float in [-1.0, 0.0, 1.0]:
				c.draw_line(Vector2(cx + dx * s * 0.3, cy + s * 0.1), Vector2(cx + dx * s * 0.75, cy + s * 0.55), METAL_DARK, s * 0.07)


static func _misc(c: CanvasItem, r: Rect2, slot: int, accent: Color) -> void:
	var cx := r.position.x + r.size.x * 0.5
	var cy := r.position.y + r.size.y * 0.5
	var s := r.size.y * 0.4
	match slot:
		0, 1, 2:
			# Kicker stages: short cylinders with a nozzle, bigger per class.
			var w := s * (0.45 + 0.15 * slot)
			var h := s * (0.8 + 0.25 * slot)
			c.draw_rect(Rect2(cx - w * 0.5, cy - h * 0.5, w, h), METAL)
			c.draw_rect(Rect2(cx - w * 0.5, cy - h * 0.1, w, h * 0.12), accent)
			c.draw_colored_polygon(PackedVector2Array([Vector2(cx - w * 0.3, cy + h * 0.5), Vector2(cx + w * 0.3, cy + h * 0.5), Vector2(cx + w * 0.45, cy + h * 0.8), Vector2(cx - w * 0.45, cy + h * 0.8)]), DARK)
		3:
			# EVA suit.
			c.draw_circle(Vector2(cx, cy - s * 0.6), s * 0.3, METAL)
			c.draw_circle(Vector2(cx + s * 0.05, cy - s * 0.62), s * 0.18, accent.darkened(0.4))
			c.draw_rect(Rect2(cx - s * 0.3, cy - s * 0.35, s * 0.6, s * 0.8), METAL)
			c.draw_rect(Rect2(cx - s * 0.5, cy - s * 0.3, s * 0.2, s * 0.6), METAL_DARK)
			c.draw_rect(Rect2(cx + s * 0.3, cy - s * 0.3, s * 0.2, s * 0.6), METAL_DARK)
		4:
			# Docking module: drum with a probe and drogue.
			c.draw_rect(Rect2(cx - s * 0.6, cy - s * 0.3, s * 1.2, s * 0.6), METAL)
			c.draw_rect(Rect2(cx + s * 0.6, cy - s * 0.15, s * 0.3, s * 0.3), METAL_DARK)
			c.draw_rect(Rect2(cx - s * 0.9, cy - s * 0.1, s * 0.3, s * 0.2), METAL_DARK)
			c.draw_rect(Rect2(cx - s * 0.6, cy - s * 0.05, s * 1.2, s * 0.1), accent)
		_:
			# Photo recon: camera lens over a crescent.
			c.draw_arc(Vector2(cx, cy + s * 0.2), s * 0.6, PI * 1.1, PI * 1.9, 24, METAL_DARK, s * 0.12)
			c.draw_circle(Vector2(cx, cy - s * 0.1), s * 0.3, DARK)
			c.draw_circle(Vector2(cx, cy - s * 0.1), s * 0.16, accent)
