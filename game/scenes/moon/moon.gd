extends ScreenPanel
## The Moon (original spaceport overlay 30, ast0.cpp Moon): the photo-reconnaissance
## level and a picture of the Moon whose detail grows with it, in the original's 14 steps
## ((level - 55) / 3, clamped 0..13). Recon is the success chance of the photo step on
## lunar missions; lunar flybys, probes and crewed lunar passes raise it.

const STEPS := 14
const STEP_FROM := 55
const STEP_SIZE := 3

var _view: MoonView
var _level: Label
var _detail: Label
var _gauge: Gauge
var _how: Label


## Detail step 0..13 for a recon level, as the original picks its Moon image.
static func recon_step(level: int) -> int:
	return clampi(int((level - STEP_FROM) / STEP_SIZE), 0, STEPS - 1)


class MoonView extends Control:
	## The Moon disc through the recon filter, with a survey grid and candidate landing
	## sites that appear as the detail improves.
	var step := 0
	var tex: Texture2D
	var _rect: TextureRect

	func _init() -> void:
		custom_minimum_size = Vector2(520, 520)
		# Space and the Moon draw behind this control, so the grid and sites go on top.
		var space := ColorRect.new()
		space.color = Color("05080f")
		space.show_behind_parent = true
		space.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		space.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(space)
		_rect = TextureRect.new()
		_rect.show_behind_parent = true
		_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		mat.shader = load("res://scripts/ui/recon_blur.gdshader")
		_rect.material = mat
		add_child(_rect)

	func set_step(s: int) -> void:
		step = s
		var t := float(step) / float(STEPS - 1)
		_rect.texture = _photo(tex, t)
		(_rect.material as ShaderMaterial).set_shader_parameter("disc", tex)
		# Coarse and flat early on, clearing quickly at first then finishing slowly.
		(_rect.material as ShaderMaterial).set_shader_parameter("haze", 0.55 * pow(1.0 - t, 1.6))
		queue_redraw()

	## The Moon as a photograph of a given quality (0 coarse .. 1 full detail): shrunk to
	## a low resolution and scaled back up, like the original's 14 reconnaissance images.
	static func _photo(src: Texture2D, t: float) -> Texture2D:
		if src == null:
			return null
		var img := src.get_image()
		if img.is_compressed():
			img.decompress()
		var full := img.get_width()
		var px := int(round(20.0 * pow(float(full) / 20.0, t)))
		if px >= full:
			return src
		var small := img.duplicate() as Image
		small.resize(px, px, Image.INTERPOLATE_LANCZOS)
		small.resize(full, full, Image.INTERPOLATE_CUBIC)
		return ImageTexture.create_from_image(small)

	func _draw() -> void:
		var s := minf(size.x, size.y)
		var c := size / 2.0
		var r := s * 0.5 - 1.0
		if tex == null:
			draw_circle(c, r, Color(0.6, 0.6, 0.62))
		# Survey grid from the middle of the range, landing sites near the top.
		var t := float(step) / float(STEPS - 1)
		if step >= 5:
			var a := clampf((t - 0.35) * 1.6, 0.0, 0.55)
			var grid := Color(UiPalette.INFO, a)
			draw_arc(c, r, 0, TAU, 96, grid, 1.0)
			for i in range(-3, 4):
				var y := c.y + r * i / 4.0
				var half := sqrt(maxf(r * r - (y - c.y) * (y - c.y), 0.0))
				draw_line(Vector2(c.x - half, y), Vector2(c.x + half, y), grid, 1.0)
			draw_line(Vector2(c.x, c.y - r), Vector2(c.x, c.y + r), grid, 1.0)
			for k in [0.3, 0.6, 0.85]:
				_meridian(c, r, r * k, grid)
		if step >= 10:
			var sites := [Vector2(-0.18, 0.05), Vector2(0.22, -0.12), Vector2(0.05, 0.28)]
			for p in sites.slice(0, step - 9):
				var q: Vector2 = c + p * r * 2.0
				var col := UiPalette.GOLD
				draw_arc(q, 12, 0, TAU, 32, col, 2.0)
				draw_line(q + Vector2(-18, 0), q + Vector2(-6, 0), col, 2.0)
				draw_line(q + Vector2(6, 0), q + Vector2(18, 0), col, 2.0)
				draw_line(q + Vector2(0, -18), q + Vector2(0, -6), col, 2.0)
				draw_line(q + Vector2(0, 6), q + Vector2(0, 18), col, 2.0)

	func _meridian(c: Vector2, r: float, w: float, col: Color) -> void:
		# An ellipse of half-width w through the poles.
		var pts := PackedVector2Array()
		for k in 49:
			var a := PI * k / 48.0 - PI / 2.0
			pts.append(c + Vector2(w * cos(a), r * sin(a)))
		draw_polyline(pts, col, 1.0)
		var back := PackedVector2Array()
		for p in pts:
			back.append(Vector2(2.0 * c.x - p.x, p.y))
		draw_polyline(back, col, 1.0)


func _init() -> void:
	super()
	title = "The Moon"


func _ready() -> void:
	super()
	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 20)
	content.add_child(split)

	var left := UiPanel.new("Photo reconnaissance", "I029")
	left.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	split.add_child(left)
	_view = MoonView.new()
	_view.tex = ArtAssets.texture("diagram/moon.png")
	_view.tooltip_text = "The Moon as your reconnaissance shows it: sharper as the recon level rises"
	left.body.add_child(_view)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	split.add_child(right)

	var level_panel := UiPanel.new("Recon level", "I029")
	right.add_child(level_panel)
	var lbox := level_panel.body
	lbox.add_theme_constant_override("separation", 10)
	_level = Label.new()
	_level.theme_type_variation = "Heading"
	_level.add_theme_color_override("font_color", UiPalette.GOLD)
	lbox.add_child(_level)
	_gauge = Gauge.new(false, "")
	_gauge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbox.add_child(_gauge)
	_detail = Label.new()
	_detail.theme_type_variation = "Dim"
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbox.add_child(_detail)

	var how_panel := UiPanel.new("Raising it")
	how_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(how_panel)
	_how = Label.new()
	_how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	how_panel.body.add_child(_how)

	var go := Button.new()
	go.custom_minimum_size = Vector2(170, 40)
	UiAction.style(go, "go", "Continue")
	go.tooltip_text = "Back to the spaceport"
	go.pressed.connect(func(): Screens.pop())
	footer.add_child(go)
	set_room("room_museum")
	_refresh()


func _refresh() -> void:
	if not Session.has_game():
		return
	var photo: SimProgram = Session.me().program("misc", 5)
	var level: int = photo.safety if photo != null else 0
	var step := recon_step(level)
	_view.set_step(step)
	_level.text = "CURRENT RECON LEVEL: %d%%" % level
	_gauge.value = level
	var stage := "Survey complete: candidate landing sites are mapped." if step >= 10 \
		else ("The survey grid is taking shape." if step >= 5 else "Only the broad features are known.")
	_detail.text = "Detail %d of %d. %s" % [step + 1, STEPS, stage]
	var k: Dictionary = Session.state().constants().get("photo_recon", {})
	_how.text = "Recon is the success chance of the photo-reconnaissance step on lunar missions, up to %d%%.\n\n" % int(k.get("cap", 99)) \
		+ "  +%d  a successful photo step on an unmanned lunar flyby or lunar probe\n" % int(k.get("unmanned_lunar_flyby_or_probe_photo_step_success", 5)) \
		+ "  +%d  more when a lunar probe also lands safely\n" % int(k.get("lunar_probe_safe_landing_extra", 10)) \
		+ "  +%d  a crewed mission that completes a lunar pass or orbit" % int(k.get("manned_lunar_pass_or_orbit_success", 5))
