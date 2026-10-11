class_name Vignettes
extends RefCounted
## Procedural vector vignettes for mission playback. Each mission step letter maps to a
## painter; a painter draws one frame for progress t in 0..1 onto a CanvasItem, with a
## success or failure flavour. No textures: everything is circles, polygons and lines in
## the palette, so it scales to any resolution.
##
## Phase 7 may replace painters with richer art; the letter map and the paint() contract
## are the stable interface.

const SPACE := Color("05080f")
const EARTH := Color("2f6fb0")
const EARTH_LAND := Color("3f8a4a")
const MOON := Color("b9b6ad")
const MOON_DARK := Color("7d7a72")
const FLAME := Color("ffb347")
const FLAME_CORE := Color("fff2c2")
const METAL := Color("d8dbe0")
const METAL_DARK := Color("8e939b")
const STAR := Color("e8ecf5")

## Step letter -> painter family.
const FAMILY := {
	"A": "launch",
	"B": "insertion", "J": "insertion", "L": "insertion",
	"C": "power_on",
	"D": "reentry", "d": "reentry", "E": "landing",
	"F": "orbit", "G": "orbit", "K": "orbit", "M": "orbit", "N": "orbit", "X": "orbit", "Y": "orbit",
	"f": "orbit", "g": "orbit", "O": "lunar_pass",
	"H": "eva", "P": "lunar_eva",
	"I": "docking",
	"Q": "lm_ops", "R": "lm_descent", "S": "lm_landing", "T": "lm_liftoff", "a": "lm_test",
	"U": "photo",
	"V": "planetary", "W": "planetary", "Z": "planetary", "e": "planetary",
	"b": "duration", "c": "duration",
}

const TITLES := {
	"launch": "Launch", "insertion": "Engine burn", "power_on": "Power-on", "reentry": "Re-entry",
	"landing": "Recovery", "orbit": "Orbital operations", "lunar_pass": "Lunar pass", "eva": "Spacewalk",
	"lunar_eva": "Lunar EVA", "docking": "Docking", "lm_ops": "Lunar module", "lm_descent": "Powered descent",
	"lm_landing": "Touchdown", "lm_liftoff": "Lunar liftoff", "lm_test": "LM thrust test",
	"photo": "Photo reconnaissance", "planetary": "Planetary cruise", "duration": "Duration",
}


static func family_for(letter: String) -> String:
	return FAMILY.get(letter, "orbit")


static func title_for(letter: String) -> String:
	return TITLES.get(family_for(letter), "Mission step")


## Draw one frame. ctx: {side_color, hardware (String), lunar (bool), failure_text}.
static func paint(c: CanvasItem, letter: String, t: float, ok: bool, size: Vector2, ctx: Dictionary) -> void:
	var fam := family_for(letter)
	_stars(c, size, letter.unicode_at(0))
	match fam:
		"launch": _launch(c, t, ok, size, ctx)
		"insertion": _insertion(c, t, ok, size, ctx, letter)
		"power_on": _power_on(c, t, ok, size, ctx)
		"reentry": _reentry(c, t, ok, size, ctx)
		"landing": _landing(c, t, ok, size, ctx)
		"orbit": _orbit(c, t, ok, size, ctx)
		"lunar_pass": _lunar_pass(c, t, ok, size, ctx)
		"eva": _eva(c, t, ok, size, ctx)
		"lunar_eva": _lunar_eva(c, t, ok, size, ctx)
		"docking": _docking(c, t, ok, size, ctx)
		"lm_ops": _lm_ops(c, t, ok, size, ctx)
		"lm_descent": _lm_descent(c, t, ok, size, ctx)
		"lm_landing": _lm_landing(c, t, ok, size, ctx)
		"lm_liftoff": _lm_liftoff(c, t, ok, size, ctx)
		"lm_test": _lm_test(c, t, ok, size, ctx)
		"photo": _photo(c, t, ok, size, ctx)
		"planetary": _planetary(c, t, ok, size, ctx)
		"duration": _duration(c, t, ok, size, ctx)
	if not ok and t > 0.75:
		_failure_tint(c, size, (t - 0.75) / 0.25)


# ---------------------------------------------------------------- helpers

static func _stars(c: CanvasItem, size: Vector2, salt: int) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, size), SPACE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234 + salt
	for i in 70:
		var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
		var r := 0.6 + rng.randf() * 1.4
		c.draw_circle(p, r * size.y / 540.0, STAR.darkened(rng.randf() * 0.5))


static func _earth(c: CanvasItem, center: Vector2, radius: float) -> void:
	c.draw_circle(center, radius, EARTH)
	c.draw_circle(center + Vector2(-radius * 0.3, -radius * 0.2), radius * 0.35, EARTH_LAND)
	c.draw_circle(center + Vector2(radius * 0.35, radius * 0.3), radius * 0.25, EARTH_LAND)
	c.draw_arc(center, radius * 1.03, 0, TAU, 64, EARTH.lightened(0.5), radius * 0.03)


static func _moon(c: CanvasItem, center: Vector2, radius: float) -> void:
	c.draw_circle(center, radius, MOON)
	c.draw_circle(center + Vector2(radius * 0.3, -radius * 0.25), radius * 0.18, MOON_DARK)
	c.draw_circle(center + Vector2(-radius * 0.35, radius * 0.3), radius * 0.12, MOON_DARK)
	c.draw_circle(center + Vector2(-radius * 0.1, -radius * 0.45), radius * 0.08, MOON_DARK)


static func _rocket(c: CanvasItem, base: Vector2, h: float, w: float, side: Color, flame: float) -> void:
	# base is the bottom centre; rocket points up.
	c.draw_rect(Rect2(base.x - w / 2, base.y - h, w, h), METAL)
	c.draw_rect(Rect2(base.x - w / 2, base.y - h * 0.55, w, h * 0.08), side)
	c.draw_colored_polygon(PackedVector2Array([base + Vector2(-w / 2, -h), base + Vector2(w / 2, -h), base + Vector2(0, -h - w * 1.3)]), METAL_DARK)
	c.draw_colored_polygon(PackedVector2Array([base + Vector2(-w / 2, 0), base + Vector2(-w * 1.1, w * 0.6), base + Vector2(-w / 2, -h * 0.2)]), METAL_DARK)
	c.draw_colored_polygon(PackedVector2Array([base + Vector2(w / 2, 0), base + Vector2(w * 1.1, w * 0.6), base + Vector2(w / 2, -h * 0.2)]), METAL_DARK)
	if flame > 0.0:
		var fl := h * 0.45 * flame
		c.draw_colored_polygon(PackedVector2Array([base + Vector2(-w * 0.45, 0), base + Vector2(w * 0.45, 0), base + Vector2(0, fl)]), FLAME)
		c.draw_colored_polygon(PackedVector2Array([base + Vector2(-w * 0.2, 0), base + Vector2(w * 0.2, 0), base + Vector2(0, fl * 0.6)]), FLAME_CORE)


static func _capsule(c: CanvasItem, pos: Vector2, s: float, side: Color, angle := 0.0) -> void:
	var pts := PackedVector2Array([Vector2(-s * 0.5, s * 0.5), Vector2(s * 0.5, s * 0.5), Vector2(s * 0.2, -s * 0.6), Vector2(-s * 0.2, -s * 0.6)])
	var rotated := PackedVector2Array()
	for p in pts:
		rotated.append(pos + p.rotated(angle))
	c.draw_colored_polygon(rotated, METAL)
	c.draw_line(pos + Vector2(-s * 0.45, s * 0.45).rotated(angle), pos + Vector2(s * 0.45, s * 0.45).rotated(angle), side, s * 0.12)
	c.draw_circle(pos + Vector2(0, -s * 0.15).rotated(angle), s * 0.12, SPACE)


static func _lm(c: CanvasItem, pos: Vector2, s: float, side: Color, flame: float) -> void:
	c.draw_rect(Rect2(pos.x - s * 0.5, pos.y - s * 0.9, s, s * 0.6), METAL_DARK)
	c.draw_rect(Rect2(pos.x - s * 0.35, pos.y - s * 1.35, s * 0.7, s * 0.5), METAL)
	c.draw_rect(Rect2(pos.x - s * 0.35, pos.y - s * 1.0, s * 0.7, s * 0.08), side)
	for dx in [-1.0, 1.0]:
		c.draw_line(pos + Vector2(dx * s * 0.4, -s * 0.35), pos + Vector2(dx * s * 0.75, 0), METAL, s * 0.07)
		c.draw_line(pos + Vector2(dx * s * 0.75, 0), pos + Vector2(dx * s * 0.9, 0), METAL, s * 0.07)
	if flame > 0.0:
		c.draw_colored_polygon(PackedVector2Array([pos + Vector2(-s * 0.2, -s * 0.3), pos + Vector2(s * 0.2, -s * 0.3), pos + Vector2(0, -s * 0.3 + s * 0.6 * flame)]), FLAME)


static func _probe(c: CanvasItem, pos: Vector2, s: float, side: Color) -> void:
	c.draw_rect(Rect2(pos.x - s * 0.3, pos.y - s * 0.3, s * 0.6, s * 0.6), METAL)
	c.draw_rect(Rect2(pos.x - s * 1.2, pos.y - s * 0.15, s * 0.8, s * 0.3), side.darkened(0.2))
	c.draw_rect(Rect2(pos.x + s * 0.4, pos.y - s * 0.15, s * 0.8, s * 0.3), side.darkened(0.2))
	c.draw_line(pos + Vector2(0, -s * 0.3), pos + Vector2(0, -s * 0.8), METAL_DARK, s * 0.06)


static func _astronaut(c: CanvasItem, pos: Vector2, s: float, side: Color) -> void:
	c.draw_circle(pos + Vector2(0, -s * 0.6), s * 0.25, METAL)
	c.draw_circle(pos + Vector2(s * 0.05, -s * 0.62), s * 0.14, side.darkened(0.4))
	c.draw_rect(Rect2(pos.x - s * 0.22, pos.y - s * 0.35, s * 0.44, s * 0.6), METAL)
	c.draw_line(pos + Vector2(-s * 0.22, -s * 0.25), pos + Vector2(-s * 0.5, s * 0.05), METAL, s * 0.12)
	c.draw_line(pos + Vector2(s * 0.22, -s * 0.25), pos + Vector2(s * 0.5, -s * 0.4), METAL, s * 0.12)
	c.draw_line(pos + Vector2(-s * 0.1, s * 0.25), pos + Vector2(-s * 0.15, s * 0.7), METAL, s * 0.12)
	c.draw_line(pos + Vector2(s * 0.1, s * 0.25), pos + Vector2(s * 0.2, s * 0.7), METAL, s * 0.12)


static func _explosion(c: CanvasItem, pos: Vector2, s: float, k: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in 9:
		var ang := rng.randf() * TAU
		var d := s * (0.2 + rng.randf()) * k
		var r := s * (0.25 + rng.randf() * 0.4) * (1.2 - k * 0.6)
		var col := FLAME if i % 2 == 0 else Color("e05020")
		c.draw_circle(pos + Vector2.RIGHT.rotated(ang) * d, r, col.lerp(SPACE, k * 0.5))
	c.draw_circle(pos, s * 0.35 * (1.0 - k * 0.5), FLAME_CORE)


static func _failure_tint(c: CanvasItem, size: Vector2, k: float) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, size), Color(0.6, 0.05, 0.05, 0.25 * k))


static func _orbit_point(center: Vector2, rx: float, ry: float, phase: float) -> Vector2:
	return center + Vector2(cos(phase) * rx, sin(phase) * ry)


# ---------------------------------------------------------------- families

static func _launch(c: CanvasItem, t: float, ok: bool, size: Vector2, ctx: Dictionary) -> void:
	var side: Color = ctx.get("side_color", METAL)
	var ground := size.y * 0.86
	c.draw_rect(Rect2(0, ground, size.x, size.y - ground), Color("1b2a1f"))
	var pad_x := size.x * 0.5
	c.draw_rect(Rect2(pad_x - size.x * 0.06, ground - size.y * 0.02, size.x * 0.12, size.y * 0.02), METAL_DARK)
	c.draw_rect(Rect2(pad_x + size.x * 0.05, ground - size.y * 0.42, size.x * 0.012, size.y * 0.4), METAL_DARK)
	var h := size.y * 0.34
	var w := size.x * 0.03
	var rise := pow(maxf(t - 0.15, 0.0) / 0.85, 2.2) * size.y * 1.4
	var fail_at := 0.55
	if not ok and t > fail_at:
		rise = pow(maxf(fail_at - 0.15, 0.0) / 0.85, 2.2) * size.y * 1.4
		var base := Vector2(pad_x, ground - size.y * 0.02 - rise)
		var k := (t - fail_at) / (1.0 - fail_at)
		if k < 0.5:
			_rocket(c, base, h, w, side, 0.3)
		_explosion(c, base + Vector2(0, -h * 0.5), size.y * 0.12, k)
		return
	var base := Vector2(pad_x, ground - size.y * 0.02 - rise)
	var flame := 0.0 if t < 0.1 else 0.8 + 0.2 * sin(t * 90.0)
	_rocket(c, base, h, w, side, flame)
	if t > 0.05 and t < 0.5:
		var smoke := (t - 0.05) / 0.45
		for i in 6:
			c.draw_circle(Vector2(pad_x + (i - 2.5) * size.x * 0.03 * (0.5 + smoke), ground - size.y * 0.02 - size.y * 0.02 * smoke), size.y * (0.03 + 0.05 * smoke), Color(0.85, 0.85, 0.85, 0.6 * (1.0 - smoke)))


static func _insertion(c: CanvasItem, t: float, ok: bool, size: Vector2, ctx: Dictionary, letter: String) -> void:
	var side: Color = ctx.get("side_color", METAL)
	var body_center := Vector2(size.x * 0.3, size.y * 0.55)
	var r := size.y * 0.3
	if letter == "L":
		_moon(c, body_center, r)
	else:
		_earth(c, body_center, r)
	var rx := r * 1.6
	var ry := r * 1.25
	var phase := -PI * 0.9 + t * PI * 1.1
	var pos := _orbit_point(body_center, rx, ry, phase)
	c.draw_arc(body_center, (rx + ry) / 2.0, -PI * 0.9, phase, 40, METAL_DARK.darkened(0.3), 2.0)
	var burning := t > 0.3 and t < 0.65
	if letter == "J" and t > 0.65:
		pos += Vector2(size.x * 0.4, -size.y * 0.1) * ((t - 0.65) / 0.35)
	if ctx.get("hardware_kind", "capsule") == "probe":
		_probe(c, pos, size.y * 0.05, side)
	else:
		_capsule(c, pos, size.y * 0.08, side, phase + PI * 0.5)
	if burning and (ok or t < 0.5):
		c.draw_circle(pos + Vector2(0, size.y * 0.06).rotated(phase + PI * 0.5), size.y * 0.025, FLAME)
	if not ok and t > 0.5:
		_explosion(c, pos, size.y * 0.07, (t - 0.5) / 0.5)


static func _power_on(c: CanvasItem, t: float, ok: bool, size: Vector2, ctx: Dictionary) -> void:
	var side: Color = ctx.get("side_color", METAL)
	_earth(c, Vector2(size.x * 0.5, size.y * 1.35), size.y * 0.9)
	var pos := Vector2(size.x * 0.5, size.y * 0.4)
	var s := size.y * 0.09
	var open := clampf(t / 0.6, 0.0, 1.0)
	c.draw_rect(Rect2(pos.x - s * 0.4, pos.y - s * 0.4, s * 0.8, s * 0.8), METAL)
	c.draw_rect(Rect2(pos.x - s * 0.5 - s * 1.6 * open, pos.y - s * 0.2, s * 1.6 * open, s * 0.4), side.darkened(0.2))
	c.draw_rect(Rect2(pos.x + s * 0.5, pos.y - s * 0.2, s * 1.6 * open, s * 0.4), side.darkened(0.2))
	if t > 0.6 and ok:
		for i in 3:
			var k := fmod(t * 3.0 + i * 0.33, 1.0)
			c.draw_arc(pos, s * (0.6 + k * 1.5), -PI * 0.75, -PI * 0.25, 20, Color(STAR, 1.0 - k), 3.0)
	if not ok and t > 0.6:
		c.draw_line(pos + Vector2(-s, -s), pos + Vector2(s, s), UiPalette.DANGER, 4.0)
		c.draw_line(pos + Vector2(s, -s), pos + Vector2(-s, s), UiPalette.DANGER, 4.0)


static func _reentry(c: CanvasItem, t: float, ok: bool, size: Vector2, ctx: Dictionary) -> void:
	var side: Color = ctx.get("side_color", METAL)
	_earth(c, Vector2(size.x * 0.5, size.y * 1.6), size.y * 1.2)
	var start := Vector2(size.x * 0.1, size.y * 0.15)
	var end := Vector2(size.x * 0.65, size.y * 0.75)
	var pos := start.lerp(end, t)
	var s := size.y * 0.08
	var angle := PI * 0.75
	if not ok:
		angle += t * 6.0
	_capsule(c, pos, s, side, angle)
	var glow := clampf((t - 0.2) / 0.4, 0.0, 1.0) * (1.0 - clampf((t - 0.8) / 0.2, 0.0, 1.0))
	if glow > 0.0:
		for i in 5:
			c.draw_circle(pos + Vector2(-s * 0.6 * i, -s * 0.5 * i), s * (0.6 - i * 0.08), Color(FLAME, 0.5 * glow))
	if not ok and t > 0.6:
		_explosion(c, pos, s, (t - 0.6) / 0.4)


static func _landing(c: CanvasItem, t: float, ok: bool, size: Vector2, ctx: Dictionary) -> void:
	var side: Color = ctx.get("side_color", METAL)
	c.draw_rect(Rect2(0, 0, size.x, size.y), Color("7fb7e8"))
	var sea := size.y * 0.78
	c.draw_rect(Rect2(0, sea, size.x, size.y - sea), Color("1e4d8a"))
	var pos := Vector2(size.x * 0.5, size.y * 0.05 + (sea - size.y * 0.12) * t)
	var s := size.y * 0.08
	if t > 0.25:
		var open := clampf((t - 0.25) / 0.2, 0.0, 1.0)
		if ok:
			var top := pos + Vector2(0, -s * 2.6 * open)
			c.draw_colored_polygon(PackedVector2Array([top + Vector2(-s * 1.8 * open, 0), top + Vector2(s * 1.8 * open, 0), top + Vector2(0, -s * 1.1 * open)]), side)
			c.draw_arc(top, s * 1.8 * open, PI, TAU, 24, side, s * 0.9 * open)
			c.draw_line(top + Vector2(-s * 1.6 * open, 0), pos, METAL_DARK, 2.0)
			c.draw_line(top + Vector2(s * 1.6 * open, 0), pos, METAL_DARK, 2.0)
		else:
			var top := pos + Vector2(0, -s * 1.5)
			c.draw_line(top, pos, METAL_DARK, 2.0)
			c.draw_line(top + Vector2(-s, -s * 0.5), top + Vector2(s, s * 0.3), side, 4.0)
	_capsule(c, pos, s, side, 0.0 if ok else t * 4.0)
	if t > 0.92:
		var k := (t - 0.92) / 0.08
		c.draw_circle(Vector2(pos.x - s * 1.5 * k, sea), s * 0.5 * k, Color(1, 1, 1, 0.8))
		c.draw_circle(Vector2(pos.x + s * 1.5 * k, sea), s * 0.5 * k, Color(1, 1, 1, 0.8))


static func _orbit(c: CanvasItem, t: float, ok: bool, size: Vector2, ctx: Dictionary) -> void:
	var side: Color = ctx.get("side_color", METAL)
	var lunar: bool = ctx.get("lunar", false)
	var center := Vector2(size.x * 0.5, size.y * 0.55)
	var r := size.y * 0.28
	if lunar:
		_moon(c, center, r)
	else:
		_earth(c, center, r)
	var phase := t * TAU * 0.9 - PI
	var pos := _orbit_point(center, r * 1.5, r * 1.15, phase)
	c.draw_arc(center, r * 1.32, 0, TAU, 64, METAL_DARK.darkened(0.4), 1.5)
	if ctx.get("hardware_kind", "capsule") == "probe":
		_probe(c, pos, size.y * 0.05, side)
	else:
		_capsule(c, pos, size.y * 0.075, side, phase + PI * 0.5)
	if not ok and t > 0.55:
		_explosion(c, pos, size.y * 0.06, (t - 0.55) / 0.45)


static func _lunar_pass(c: CanvasItem, t: float, ok: bool, size: Vector2, ctx: Dictionary) -> void:
	var side: Color = ctx.get("side_color", METAL)
	_earth(c, Vector2(size.x * 0.1, size.y * 0.8), size.y * 0.22)
	var moon_c := Vector2(size.x * 0.78, size.y * 0.45)
	_moon(c, moon_c, size.y * 0.2)
	var phase := PI * 1.5 - t * PI * 1.4
	var pos := _orbit_point(moon_c, size.y * 0.38, size.y * 0.3, phase)
	c.draw_arc(moon_c, size.y * 0.34, PI * 0.1, PI * 1.5, 40, METAL_DARK.darkened(0.4), 1.5)
	_capsule(c, pos, size.y * 0.07, side, phase - PI * 0.5)
	if not ok and t > 0.6:
		_explosion(c, pos, size.y * 0.06, (t - 0.6) / 0.4)


static func _eva(c: CanvasItem, t: float, ok: bool, size: Vector2, ctx: Dictionary) -> void:
	var side: Color = ctx.get("side_color", METAL)
	_earth(c, Vector2(size.x * 0.5, size.y * 1.45), size.y)
	var cap := Vector2(size.x * 0.4, size.y * 0.42)
	_capsule(c, cap, size.y * 0.16, side, PI * 0.5)
	var out := clampf(t / 0.5, 0.0, 1.0)
	var drift := Vector2(size.x * 0.18, -size.y * 0.1) * out + Vector2(sin(t * 6.0) * size.y * 0.02, cos(t * 4.0) * size.y * 0.02)
	var a := cap + drift
	var tether_end := a if ok or t < 0.6 else cap + drift * 0.4
	c.draw_line(cap + Vector2(size.y * 0.06, 0), tether_end, METAL, 2.5)
	if not ok and t > 0.6:
		a += Vector2(size.x * 0.25, -size.y * 0.25) * ((t - 0.6) / 0.4)
	_astronaut(c, a, size.y * 0.09, side)


static func _lunar_eva(c: CanvasItem, t: float, ok: bool, size: Vector2, ctx: Dictionary) -> void:
	var side: Color = ctx.get("side_color", METAL)
	var ground := size.y * 0.8
	c.draw_rect(Rect2(0, ground, size.x, size.y - ground), MOON_DARK)
	c.draw_rect(Rect2(0, ground, size.x, size.y * 0.02), MOON)
	_earth(c, Vector2(size.x * 0.85, size.y * 0.18), size.y * 0.08)
	_lm(c, Vector2(size.x * 0.3, ground), size.y * 0.14, side, 0.0)
	var walk := clampf(t / 0.7, 0.0, 1.0)
	var a := Vector2(size.x * 0.4 + size.x * 0.2 * walk, ground - size.y * 0.05)
	_astronaut(c, a, size.y * 0.09, side)
	if t > 0.7:
		var fx := size.x * 0.68
		c.draw_line(Vector2(fx, ground), Vector2(fx, ground - size.y * 0.16), METAL, 2.5)
		c.draw_rect(Rect2(fx, ground - size.y * 0.16, size.x * 0.05, size.y * 0.035), side)
	if not ok and t > 0.5:
		c.draw_circle(a + Vector2(0, -size.y * 0.06), size.y * 0.03 * ((t - 0.5) / 0.5), UiPalette.DANGER)


static func _docking(c: CanvasItem, t: float, ok: bool, size: Vector2, ctx: Dictionary) -> void:
	var side: Color = ctx.get("side_color", METAL)
	_earth(c, Vector2(size.x * 0.5, size.y * 1.5), size.y * 1.05)
	var mid := Vector2(size.x * 0.5, size.y * 0.42)
	var gap := size.x * 0.3 * (1.0 - clampf(t / 0.8, 0.0, 1.0))
	if not ok and t > 0.7:
		gap = size.x * 0.05 + size.x * 0.1 * ((t - 0.7) / 0.3)
	var s := size.y * 0.1
	_capsule(c, mid + Vector2(-gap - s * 0.6, 0), s, side, PI * 0.5)
	c.draw_rect(Rect2(mid.x + gap, mid.y - s * 0.35, s * 1.3, s * 0.7), METAL)
	c.draw_rect(Rect2(mid.x + gap + s * 1.3, mid.y - s * 0.25, s * 0.5, s * 0.5), METAL_DARK)
	c.draw_rect(Rect2(mid.x + gap - s * 0.9, mid.y - s * 0.1, s * 0.9, s * 0.2), METAL_DARK)
	if ok and t > 0.85:
		c.draw_circle(mid + Vector2(-s * 0.1, 0), s * 0.2, UiPalette.OK)


static func _lm_ops(c: CanvasItem, t: float, ok: bool, size: Vector2, ctx: Dictionary) -> void:
	var side: Color = ctx.get("side_color", METAL)
	var center := Vector2(size.x * 0.5, size.y * 0.6)
	_moon(c, center, size.y * 0.3)
	var phase := -PI + t * PI * 0.9
	var pos := _orbit_point(center, size.y * 0.45, size.y * 0.36, phase)
	_lm(c, pos, size.y * 0.09, side, 0.0)
	_capsule(c, pos + Vector2(size.y * 0.16, -size.y * 0.02), size.y * 0.06, side, PI * 0.5)
	if not ok and t > 0.6:
		_explosion(c, pos, size.y * 0.06, (t - 0.6) / 0.4)


static func _lm_descent(c: CanvasItem, t: float, ok: bool, size: Vector2, ctx: Dictionary) -> void:
	var side: Color = ctx.get("side_color", METAL)
	var ground := size.y * 0.85
	c.draw_rect(Rect2(0, ground, size.x, size.y - ground), MOON_DARK)
	c.draw_rect(Rect2(0, ground, size.x, size.y * 0.015), MOON)
	var pos := Vector2(size.x * 0.25 + size.x * 0.3 * t, size.y * 0.1 + (ground - size.y * 0.25) * t)
	_lm(c, pos, size.y * 0.14, side, 0.8 + 0.2 * sin(t * 80.0))
	if not ok and t > 0.6:
		_explosion(c, pos + Vector2(0, -size.y * 0.08), size.y * 0.1, (t - 0.6) / 0.4)


static func _lm_landing(c: CanvasItem, t: float, ok: bool, size: Vector2, ctx: Dictionary) -> void:
	var side: Color = ctx.get("side_color", METAL)
	var ground := size.y * 0.85
	c.draw_rect(Rect2(0, ground, size.x, size.y - ground), MOON_DARK)
	c.draw_rect(Rect2(0, ground, size.x, size.y * 0.015), MOON)
	var drop := clampf(t / 0.7, 0.0, 1.0)
	var pos := Vector2(size.x * 0.5, ground - size.y * 0.3 * (1.0 - drop * drop))
	var flame := (1.0 - drop) * 0.9
	if not ok and t > 0.5:
		pos.x += size.x * 0.1 * ((t - 0.5) / 0.5)
		_lm(c, pos, size.y * 0.14, side, 0.0)
		_explosion(c, pos + Vector2(0, -size.y * 0.1), size.y * 0.12, (t - 0.5) / 0.5)
		return
	_lm(c, pos, size.y * 0.14, side, flame)
	if drop > 0.6:
		var k := (drop - 0.6) / 0.4
		for i in 6:
			c.draw_circle(Vector2(pos.x + (i - 2.5) * size.x * 0.04 * k, ground - size.y * 0.01), size.y * 0.02 * k, Color(MOON, 0.6 * (1.0 - k)))
	if t > 0.75:
		c.draw_string(ThemeDB.fallback_font, Vector2(size.x * 0.5 - size.x * 0.1, size.y * 0.2), "CONTACT LIGHT", HORIZONTAL_ALIGNMENT_CENTER, size.x * 0.2, int(size.y * 0.05), UiPalette.OK)


static func _lm_liftoff(c: CanvasItem, t: float, ok: bool, size: Vector2, ctx: Dictionary) -> void:
	var side: Color = ctx.get("side_color", METAL)
	var ground := size.y * 0.85
	c.draw_rect(Rect2(0, ground, size.x, size.y - ground), MOON_DARK)
	c.draw_rect(Rect2(0, ground, size.x, size.y * 0.015), MOON)
	var base := Vector2(size.x * 0.5, ground)
	var s := size.y * 0.14
	c.draw_rect(Rect2(base.x - s * 0.5, base.y - s * 0.9, s, s * 0.6), METAL_DARK)
	for dx in [-1.0, 1.0]:
		c.draw_line(base + Vector2(dx * s * 0.4, -s * 0.35), base + Vector2(dx * s * 0.75, 0), METAL, s * 0.07)
	var rise := pow(maxf(t - 0.1, 0.0), 1.8) * size.y * 1.2
	var top := base + Vector2(0, -s * 0.9 - rise)
	c.draw_rect(Rect2(top.x - s * 0.35, top.y - s * 0.5, s * 0.7, s * 0.5), METAL)
	c.draw_rect(Rect2(top.x - s * 0.35, top.y - s * 0.15, s * 0.7, s * 0.08), side)
	if t > 0.1:
		c.draw_colored_polygon(PackedVector2Array([top + Vector2(-s * 0.2, 0), top + Vector2(s * 0.2, 0), top + Vector2(0, s * 0.5)]), FLAME)
	if not ok and t > 0.55:
		_explosion(c, top, size.y * 0.1, (t - 0.55) / 0.45)


static func _lm_test(c: CanvasItem, t: float, ok: bool, size: Vector2, ctx: Dictionary) -> void:
	var side: Color = ctx.get("side_color", METAL)
	var lunar: bool = ctx.get("lunar", false)
	var center := Vector2(size.x * 0.5, size.y * 1.4)
	if lunar:
		_moon(c, center, size.y * 0.95)
	else:
		_earth(c, center, size.y * 0.95)
	var pos := Vector2(size.x * 0.45 + size.x * 0.1 * t, size.y * 0.42)
	var firing := t > 0.3 and t < 0.75
	_lm(c, pos, size.y * 0.12, side, (0.8 + 0.2 * sin(t * 70.0)) if firing else 0.0)
	if not ok and t > 0.6:
		_explosion(c, pos + Vector2(0, -size.y * 0.06), size.y * 0.08, (t - 0.6) / 0.4)


static func _photo(c: CanvasItem, t: float, ok: bool, size: Vector2, ctx: Dictionary) -> void:
	var side: Color = ctx.get("side_color", METAL)
	var center := Vector2(size.x * 0.55, size.y * 0.95)
	_moon(c, center, size.y * 0.6)
	var pos := Vector2(size.x * 0.2 + size.x * 0.5 * t, size.y * 0.25)
	_probe(c, pos, size.y * 0.05, side)
	var n := int(t * 5.0)
	for i in n:
		var fx := size.x * 0.25 + size.x * 0.1 * i
		c.draw_rect(Rect2(fx, size.y * 0.5, size.x * 0.08, size.y * 0.06), Color(1, 1, 1, 0.25), false, 2.0)
	if ok and fmod(t * 5.0, 1.0) < 0.15 and t < 0.95:
		c.draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.35))
	if not ok and t > 0.6:
		c.draw_line(pos + Vector2(-size.y * 0.05, -size.y * 0.05), pos + Vector2(size.y * 0.05, size.y * 0.05), UiPalette.DANGER, 4.0)


static func _planetary(c: CanvasItem, t: float, ok: bool, size: Vector2, ctx: Dictionary) -> void:
	var side: Color = ctx.get("side_color", METAL)
	var planet: Color = ctx.get("planet_color", Color("c9a46a"))
	_earth(c, Vector2(size.x * 0.08, size.y * 0.7), size.y * 0.15)
	var pc := Vector2(size.x * 0.88, size.y * 0.4)
	c.draw_circle(pc, size.y * 0.18, planet)
	if ctx.get("ringed", false):
		c.draw_arc(pc, size.y * 0.26, 0, TAU, 48, planet.lightened(0.3), size.y * 0.025)
	var pos := Vector2(size.x * 0.15, size.y * 0.65).lerp(Vector2(size.x * 0.7, size.y * 0.45), t)
	c.draw_line(Vector2(size.x * 0.15, size.y * 0.65), pos, METAL_DARK.darkened(0.3), 1.5)
	_probe(c, pos, size.y * 0.05, side)
	if not ok and t > 0.6:
		c.draw_line(pos + Vector2(-size.y * 0.05, -size.y * 0.05), pos + Vector2(size.y * 0.05, size.y * 0.05), UiPalette.DANGER, 4.0)
		c.draw_line(pos + Vector2(size.y * 0.05, -size.y * 0.05), pos + Vector2(-size.y * 0.05, size.y * 0.05), UiPalette.DANGER, 4.0)


static func _duration(c: CanvasItem, t: float, ok: bool, size: Vector2, ctx: Dictionary) -> void:
	var side: Color = ctx.get("side_color", METAL)
	var center := Vector2(size.x * 0.5, size.y * 0.55)
	var r := size.y * 0.28
	_earth(c, center, r)
	var phase := t * TAU * 2.5 - PI
	var pos := _orbit_point(center, r * 1.5, r * 1.15, phase)
	c.draw_arc(center, r * 1.32, 0, TAU, 64, METAL_DARK.darkened(0.4), 1.5)
	_capsule(c, pos, size.y * 0.075, side, phase + PI * 0.5)
	var days: int = ctx.get("days", 5)
	var shown := int(ceil(t * days))
	c.draw_string(ThemeDB.fallback_font, Vector2(size.x * 0.78, size.y * 0.15), "Day %d" % maxi(shown, 1), HORIZONTAL_ALIGNMENT_LEFT, -1, int(size.y * 0.06), STAR)
	if not ok and t > 0.6:
		c.draw_circle(pos, size.y * 0.03 * ((t - 0.6) / 0.4), UiPalette.DANGER)
