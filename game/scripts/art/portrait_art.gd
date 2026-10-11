class_name PortraitArt
extends RefCounted
## Deterministic procedural portraits. The same name always gives the same face: skin,
## hair, eyes, features and a suit in the side's colour. Flat-shaded vector shapes so it
## scales with the UI. Phase 7 art can replace this with illustrated portraits keyed by
## name without changing callers.

const SKINS := [Color("f1d2b6"), Color("e2b48f"), Color("c68c5b"), Color("8d5a3a"), Color("5c3b24"), Color("f5e0cf")]
const HAIRS := [Color("2b1d14"), Color("4a2f1b"), Color("8a5a2b"), Color("c99b5a"), Color("e9d9a6"), Color("3a3a3a"), Color("9a9a9a")]
const EYES := [Color("3b2a1a"), Color("2f5d8a"), Color("4c7a3c"), Color("5a4a3a")]
const BG := Color("1b2740")


## The features a name maps to; the same name always gives the same dictionary.
static func features(name: String, female: bool) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(name.to_lower())
	return {
		"skin": SKINS[rng.randi() % SKINS.size()],
		"hair": HAIRS[rng.randi() % HAIRS.size()],
		"eye": EYES[rng.randi() % EYES.size()],
		"face_w": 0.3 + rng.randf() * 0.08,
		"face_h": 0.36 + rng.randf() * 0.08,
		"jaw": 0.6 + rng.randf() * 0.35,
		"hair_style": rng.randi() % 4,
		"brow": rng.randf(),
		"glasses": rng.randf() < 0.18,
		"moustache": (not female) and rng.randf() < 0.25,
	}


## Paint a portrait of `name` into `rect`. female selects hair styles; side colours the suit.
static func paint(c: CanvasItem, rect: Rect2, name: String, female: bool, side: String, status: String = "") -> void:
	var tex := ArtAssets.portrait(name)
	if tex != null:
		c.draw_rect(rect, BG)
		ArtAssets.draw_cover(c, tex, rect)
		if status == "dead":
			c.draw_rect(rect, Color(0, 0, 0, 0.45))
			c.draw_rect(Rect2(rect.position + Vector2(0, rect.size.y * 0.9), Vector2(rect.size.x, rect.size.y * 0.1)), Color.BLACK)
		elif status == "retired":
			c.draw_rect(rect, Color(0.1, 0.1, 0.1, 0.3))
		return
	var f := features(name, female)
	var skin: Color = f["skin"]
	var hair: Color = f["hair"]
	var eye: Color = f["eye"]
	var face_w: float = f["face_w"]
	var face_h: float = f["face_h"]
	var jaw: float = f["jaw"]
	var hair_style: int = f["hair_style"]
	var brow: float = f["brow"]
	var glasses: bool = f["glasses"]
	var moustache: bool = f["moustache"]
	var s := rect.size
	var cx := rect.position.x + s.x * 0.5
	var cy := rect.position.y + s.y * 0.45

	c.draw_rect(rect, BG)
	# Suit and collar.
	var suit := UiPalette.accent_dark(side)
	c.draw_colored_polygon(PackedVector2Array([Vector2(rect.position.x + s.x * 0.1, rect.end.y), Vector2(cx - s.x * 0.2, cy + s.y * 0.28), Vector2(cx + s.x * 0.2, cy + s.y * 0.28), Vector2(rect.end.x - s.x * 0.1, rect.end.y)]), suit)
	c.draw_rect(Rect2(cx - s.x * 0.08, cy + s.y * 0.3, s.x * 0.16, s.y * 0.25), skin.darkened(0.1))
	c.draw_line(Vector2(cx - s.x * 0.2, cy + s.y * 0.3), Vector2(cx, cy + s.y * 0.42), Color.WHITE, s.x * 0.03)
	c.draw_line(Vector2(cx + s.x * 0.2, cy + s.y * 0.3), Vector2(cx, cy + s.y * 0.42), Color.WHITE, s.x * 0.03)
	# Hair back layer.
	var fw := s.x * face_w
	var fh := s.y * face_h
	if hair_style == 2 or female:
		c.draw_circle(Vector2(cx, cy - fh * 0.1), fw * 1.25, hair)
		if female:
			c.draw_rect(Rect2(cx - fw * 1.2, cy - fh * 0.1, fw * 2.4, fh * 1.1), hair)
	# Face: ellipse approximated by a polygon with a jaw taper.
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		var x := cos(a) * fw
		var y := sin(a) * fh
		if y > 0:
			x *= lerpf(1.0, jaw, y / fh)
		pts.append(Vector2(cx + x, cy + y))
	c.draw_colored_polygon(pts, skin)
	# Ears.
	c.draw_circle(Vector2(cx - fw * 0.98, cy), fw * 0.14, skin.darkened(0.08))
	c.draw_circle(Vector2(cx + fw * 0.98, cy), fw * 0.14, skin.darkened(0.08))
	# Hair front.
	match hair_style:
		0:
			c.draw_colored_polygon(PackedVector2Array([Vector2(cx - fw, cy - fh * 0.3), Vector2(cx - fw * 0.9, cy - fh * 1.05), Vector2(cx + fw * 0.9, cy - fh * 1.05), Vector2(cx + fw, cy - fh * 0.3), Vector2(cx + fw * 0.6, cy - fh * 0.55), Vector2(cx - fw * 0.6, cy - fh * 0.55)]), hair)
		1:
			c.draw_colored_polygon(PackedVector2Array([Vector2(cx - fw, cy - fh * 0.4), Vector2(cx - fw * 0.8, cy - fh * 1.0), Vector2(cx + fw * 0.95, cy - fh * 1.0), Vector2(cx + fw, cy - fh * 0.5), Vector2(cx - fw * 0.1, cy - fh * 0.6)]), hair)
		2:
			c.draw_colored_polygon(PackedVector2Array([Vector2(cx - fw * 1.05, cy - fh * 0.2), Vector2(cx - fw * 0.9, cy - fh * 1.1), Vector2(cx + fw * 0.9, cy - fh * 1.1), Vector2(cx + fw * 1.05, cy - fh * 0.2), Vector2(cx + fw * 0.8, cy - fh * 0.5), Vector2(cx - fw * 0.8, cy - fh * 0.5)]), hair)
		3:
			c.draw_arc(Vector2(cx, cy - fh * 0.2), fw * 0.98, PI * 1.05, PI * 1.95, 24, hair, fw * 0.18)
	# Eyes and brows.
	for dx: float in [-0.4, 0.4]:
		var ex: float = cx + fw * dx
		var ey: float = cy - fh * 0.1
		c.draw_circle(Vector2(ex, ey), fw * 0.13, Color.WHITE)
		c.draw_circle(Vector2(ex, ey), fw * 0.07, eye)
		c.draw_circle(Vector2(ex, ey), fw * 0.035, Color.BLACK)
		c.draw_line(Vector2(ex - fw * 0.17, ey - fh * (0.2 + brow * 0.08)), Vector2(ex + fw * 0.17, ey - fh * 0.22), hair.darkened(0.2), fw * 0.05)
		if glasses:
			c.draw_arc(Vector2(ex, ey), fw * 0.2, 0, TAU, 20, Color("2a2a2a"), fw * 0.03)
	if glasses:
		c.draw_line(Vector2(cx - fw * 0.2, cy - fh * 0.1), Vector2(cx + fw * 0.2, cy - fh * 0.1), Color("2a2a2a"), fw * 0.03)
	# Nose and mouth.
	c.draw_line(Vector2(cx, cy - fh * 0.05), Vector2(cx - fw * 0.08, cy + fh * 0.22), skin.darkened(0.25), fw * 0.05)
	var smile := 0.0 if status == "dead" or status == "injured" else 1.0
	c.draw_arc(Vector2(cx, cy + fh * 0.35), fw * 0.28, PI * 0.15 * smile + 0.1, PI - 0.1 - PI * 0.15 * smile, 12, skin.darkened(0.45), fw * 0.05)
	if moustache:
		c.draw_rect(Rect2(cx - fw * 0.3, cy + fh * 0.3, fw * 0.6, fh * 0.07), hair)
	if status == "dead":
		c.draw_rect(rect, Color(0, 0, 0, 0.45))
		c.draw_rect(Rect2(rect.position + Vector2(0, s.y * 0.9), Vector2(s.x, s.y * 0.1)), Color.BLACK)
	elif status == "retired":
		c.draw_rect(rect, Color(0.1, 0.1, 0.1, 0.3))
