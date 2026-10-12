extends Control
## Mission playback, staged as a control room: a painted room for the lower half, a wall
## of monitors above it with the vignette on the big screen and live feeds (capsule,
## booster, crew, tracking) on the small ones, a status strip of step lights between,
## and the telemetry chart and mission log as console panels over the room. Skip, speed
## and a "Full stage" toggle that gives the vignette the whole screen. Pops itself when
## done; TurnFlow pushes the results table beneath it.

const WALL_COLOR := Color(0.05, 0.06, 0.08, 0.80)
const BEZEL := Color("1b1e24")
const BEZEL_EDGE := Color("343a45")
const SCREEN_OFF := Color("05080c")
const FEED_GREEN := Color(0.55, 1.0, 0.65)
const FEED_AMBER := Color(1.0, 0.85, 0.5)
const FEED_GREY := Color(0.85, 0.9, 1.0)
const FEED_NAMES := ["CAPSULE", "BOOSTER", "CREW", "TRACKING"]
var _feed_names: Array = FEED_NAMES.duplicate()

var _report: Dictionary = {}
var _launches: Array = []
var _current := 0
var _skip_requested := false
var _skip_all := false
var _playing := false
var _speed := 1.0

var _backdrop: TextureRect
var _wall: Control
var _stage: Control
var _feeds: Array = []            ## four Controls on the small monitors
var _feed_tex: Array = [null, null, null, null]
var _crew_tex: Array = []
var _big_rect := Rect2()
var _small_rects: Array = []
var _stage_letter := ""
var _stage_t := 0.0
var _stage_ok := true
var _stage_ctx: Dictionary = {}
var _mission_progress := 0.0      ## 0..1 across the whole launch, for the tracking feed
var _tick := 0.0
var _chart: StepChart
var _log: RichTextLabel
var _step_title: Label
var _lights: Control
var _mission_label: Label
var _subtitle: Label
var _flash: NewsFlash
var _strip: HBoxContainer
var _bottom: HBoxContainer
var _mosaic := false
var _speed_label: Label
var _skip_btn: Button
var _continue_btn: Button
var _steps: Array = []
var _revealed := 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_speed = Settings.animation_speed
	var bg := ColorRect.new()
	bg.color = UiPalette.BG_DEEP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_backdrop = TextureRect.new()
	_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.visible = false
	add_child(_backdrop)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	# The monitor wall.
	_wall = Control.new()
	_wall.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_wall.size_flags_stretch_ratio = 3.2
	_wall.clip_contents = true
	_wall.draw.connect(_draw_wall)
	_wall.resized.connect(_layout_wall)
	root.add_child(_wall)
	_stage = Control.new()
	_stage.clip_contents = true
	_stage.draw.connect(_draw_stage)
	_wall.add_child(_stage)
	for i in 4:
		var feed := Control.new()
		feed.clip_contents = true
		feed.draw.connect(_draw_feed.bind(i))
		_wall.add_child(feed)
		_feeds.append(feed)
	_flash = NewsFlash.new()
	_flash.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_flash.anchor_left = 0.08
	_flash.anchor_right = 0.92
	_flash.anchor_top = 0.72
	_flash.anchor_bottom = 0.72
	_flash.offset_left = 0
	_flash.offset_right = 0
	_flash.grow_vertical = Control.GROW_DIRECTION_BOTH
	_stage.add_child(_flash)

	# Status strip: step title, step lights, mission name.
	_strip = HBoxContainer.new()
	_strip.add_theme_constant_override("separation", 20)
	var strip_bg := PanelContainer.new()
	strip_bg.add_theme_stylebox_override("panel", UiTheme.flat(Color("0d1117", 0.92), BEZEL_EDGE, 0, 1))
	strip_bg.add_child(_strip)
	root.add_child(strip_bg)
	_step_title = Label.new()
	_step_title.theme_type_variation = "Heading"
	_step_title.add_theme_color_override("font_color", UiPalette.GOLD)
	_step_title.custom_minimum_size.x = 360
	_strip.add_child(_step_title)
	_lights = Control.new()
	_lights.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lights.custom_minimum_size.y = 44
	_lights.draw.connect(_draw_lights)
	_strip.add_child(_lights)
	_mission_label = Label.new()
	_mission_label.theme_type_variation = "Subheading"
	_strip.add_child(_mission_label)
	_subtitle = Label.new()
	_subtitle.theme_type_variation = "Dim"
	_strip.add_child(_subtitle)
	for i in [0, 3]:
		var pad := Control.new()
		pad.custom_minimum_size.x = 12
		_strip.add_child(pad)
		_strip.move_child(pad, i)

	# Console panels over the room: telemetry chart and the mission log.
	_bottom = HBoxContainer.new()
	_bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_bottom.size_flags_stretch_ratio = 1.5
	_bottom.add_theme_constant_override("separation", 16)
	var bottom_margin := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		bottom_margin.add_theme_constant_override("margin_" + s, 14)
	bottom_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_margin.size_flags_stretch_ratio = 1.5
	bottom_margin.add_child(_bottom)
	root.add_child(bottom_margin)
	var chart_panel := _console_panel("Telemetry")
	_chart = StepChart.new()
	_chart.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chart_panel.get_child(0).add_child(_chart)
	_bottom.add_child(chart_panel)
	var log_panel := _console_panel("Mission log")
	_log = RichTextLabel.new()
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.scroll_following = true
	_log.bbcode_enabled = true
	log_panel.get_child(0).add_child(_log)
	_bottom.add_child(log_panel)

	# Controls.
	var controls := HBoxContainer.new()
	var controls_bg := PanelContainer.new()
	controls_bg.add_theme_stylebox_override("panel", UiTheme.flat(Color("0d1117", 0.92), BEZEL_EDGE, 0, 1))
	controls_bg.add_child(controls)
	root.add_child(controls_bg)
	_speed_label = Label.new()
	_speed_label.theme_type_variation = "Dim"
	controls.add_child(_speed_label)
	var slower := Button.new()
	slower.text = "Slower"
	slower.theme_type_variation = "Flat"
	slower.pressed.connect(func(): _set_speed(_speed / 1.5))
	controls.add_child(slower)
	var faster := Button.new()
	faster.text = "Faster"
	faster.theme_type_variation = "Flat"
	faster.pressed.connect(func(): _set_speed(_speed * 1.5))
	controls.add_child(faster)
	var mosaic := Button.new()
	mosaic.text = "Full stage"
	mosaic.theme_type_variation = "Flat"
	mosaic.toggle_mode = true
	mosaic.toggled.connect(_set_mosaic)
	controls.add_child(mosaic)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(spacer)
	_skip_btn = Button.new()
	_skip_btn.text = "Skip launch"
	_skip_btn.pressed.connect(func(): _skip_requested = true)
	controls.add_child(_skip_btn)
	var skip_all := Button.new()
	skip_all.text = "Skip all"
	skip_all.pressed.connect(func():
		_skip_all = true
		_skip_requested = true)
	controls.add_child(skip_all)
	_continue_btn = Button.new()
	_continue_btn.text = "Continue"
	_continue_btn.theme_type_variation = "Accent"
	_continue_btn.visible = false
	_continue_btn.pressed.connect(func(): Screens.pop())
	controls.add_child(_continue_btn)
	_set_speed(_speed)
	_set_room(Session.human_side if Session.has_game() else "usa")


func _console_panel(title: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", UiTheme.flat(Color(UiPalette.PANEL_SUNKEN, 0.80), BEZEL_EDGE, 6, 1))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)
	var head := Label.new()
	head.theme_type_variation = "Dim"
	head.text = title.to_upper()
	v.add_child(head)
	return panel


func _set_room(side: String) -> void:
	var tex := ArtAssets.backdrop("mission_control_%s" % side)
	_backdrop.texture = tex
	_backdrop.visible = tex != null


func _process(delta: float) -> void:
	_tick += delta
	if _playing and not _mosaic:
		for f in _feeds:
			f.queue_redraw()
		_lights.queue_redraw()


# ----------------------------------------------------------------- monitor wall

func _layout_wall() -> void:
	var w := _wall.size.x
	var h := _wall.size.y
	if _mosaic:
		_stage.position = Vector2.ZERO
		_stage.size = _wall.size
		for f in _feeds:
			f.visible = false
		_wall.queue_redraw()
		return
	var m := 18.0
	var caption := 22.0
	var big_h := h - m * 2 - caption
	var big_w := minf(w * 0.56, big_h * 16.0 / 9.0)
	big_h = big_w * 9.0 / 16.0
	_big_rect = Rect2((w - big_w) / 2.0, m + (h - m * 2 - caption - big_h) / 2.0, big_w, big_h)
	var col_w := _big_rect.position.x - m * 2
	var small_h := (h - m * 2 - caption * 2 - m) / 2.0
	var small_w := minf(col_w, small_h * 4.0 / 3.0)
	small_h = small_w * 3.0 / 4.0
	var total_h := small_h * 2 + caption * 2 + m
	var y0 := (h - total_h) / 2.0
	_small_rects = [
		Rect2(m + (col_w - small_w) / 2.0, y0, small_w, small_h),
		Rect2(m + (col_w - small_w) / 2.0, y0 + small_h + caption + m, small_w, small_h),
		Rect2(_big_rect.end.x + m + (col_w - small_w) / 2.0, y0, small_w, small_h),
		Rect2(_big_rect.end.x + m + (col_w - small_w) / 2.0, y0 + small_h + caption + m, small_w, small_h),
	]
	var inset := 12.0
	_stage.position = _big_rect.position + Vector2(inset, inset)
	_stage.size = _big_rect.size - Vector2(inset * 2, inset * 2)
	for i in 4:
		var f: Control = _feeds[i]
		f.visible = true
		f.position = _small_rects[i].position + Vector2(inset * 0.7, inset * 0.7)
		f.size = _small_rects[i].size - Vector2(inset * 1.4, inset * 1.4)
	_wall.queue_redraw()


func _draw_wall() -> void:
	if _mosaic:
		return
	_wall.draw_rect(Rect2(Vector2.ZERO, _wall.size), WALL_COLOR)
	var font := get_theme_default_font()
	_draw_bezel(_big_rect)
	for i in 4:
		var r: Rect2 = _small_rects[i]
		_draw_bezel(r)
		_wall.draw_string(font, Vector2(r.position.x, r.end.y + 17), _feed_names[i], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, UiTheme.SIZE_SMALL, UiPalette.TEXT_DIM)
	_wall.draw_string(font, Vector2(_big_rect.position.x, _big_rect.end.y + 17), "MAIN SCREEN", HORIZONTAL_ALIGNMENT_CENTER, _big_rect.size.x, UiTheme.SIZE_SMALL, UiPalette.TEXT_DIM)


func _draw_bezel(r: Rect2) -> void:
	var sb := UiTheme.flat(BEZEL, BEZEL_EDGE, 10, 2)
	_wall.draw_style_box(sb, r.grow(4))
	_wall.draw_rect(r.grow(-6), SCREEN_OFF)
	# A thin glass highlight along the top edge.
	_wall.draw_line(r.position + Vector2(10, 2), Vector2(r.end.x - 10, r.position.y + 2), Color(1, 1, 1, 0.06), 2.0)


func _draw_lights() -> void:
	var n := _steps.size()
	if n == 0:
		return
	var r := 7.0
	var gap := minf(26.0, _lights.size.x / maxf(n, 1))
	var x0 := (_lights.size.x - gap * (n - 1)) / 2.0
	var y := _lights.size.y / 2.0
	for i in n:
		var c := Vector2(x0 + gap * i, y)
		var col := UiPalette.TEXT_MUTED.darkened(0.4)
		if i < _revealed:
			col = UiPalette.OK if _steps[i].get("success", false) else UiPalette.DANGER
		elif i == _revealed and _playing:
			col = UiPalette.TEXT if fmod(_tick, 0.8) < 0.4 else UiPalette.TEXT_MUTED
		_lights.draw_circle(c, r + 2, Color(0, 0, 0, 0.5))
		_lights.draw_circle(c, r, col)


func _draw_stage() -> void:
	if _stage_letter == "":
		_stage.draw_rect(Rect2(Vector2.ZERO, _stage.size), Vignettes.SPACE)
		return
	Vignettes.paint(_stage, _stage_letter, _stage_t, _stage_ok, _stage.size, _stage_ctx)
	if _mosaic:
		_stage.draw_string(get_theme_default_font(), Vector2(16, 30), Vignettes.title_for(_stage_letter), HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_SUBHEADING, UiPalette.TEXT)


func _draw_feed(index: int) -> void:
	var f: Control = _feeds[index]
	var size := f.size
	f.draw_rect(Rect2(Vector2.ZERO, size), SCREEN_OFF)
	var tint: Color = [FEED_GREEN, FEED_AMBER, FEED_GREY, FEED_GREEN][index]
	match index:
		0, 1:
			var tex: Texture2D = _feed_tex[index]
			if tex != null:
				f.draw_rect(Rect2(Vector2.ZERO, size), Color(tint, 0.08))
				_draw_fit_tinted(f, tex, Rect2(Vector2.ZERO, size).grow(-size.y * 0.08), tint)
			else:
				_draw_static(f, size)
		2:
			if _crew_tex.is_empty():
				f.draw_rect(Rect2(Vector2.ZERO, size), Color(tint, 0.06))
				f.draw_string(get_theme_default_font(), Vector2(0, size.y / 2.0 + 6), "UNMANNED", HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTheme.SIZE_SMALL, Color(tint, 0.7))
			else:
				var n := _crew_tex.size()
				var slot_w := size.x / n
				for i in n:
					_draw_fit_tinted(f, _crew_tex[i], Rect2(slot_w * i, 0, slot_w, size.y).grow(-3), tint)
		3:
			_draw_tracking(f, size, tint)
	# CRT scanlines and a vignette edge.
	var y := 0.0
	while y < size.y:
		f.draw_line(Vector2(0, y), Vector2(size.x, y), Color(0, 0, 0, 0.16), 1.0)
		y += 3.0
	f.draw_rect(Rect2(Vector2.ZERO, size), Color(tint, 0.25), false, 2.0)


func _draw_fit_tinted(c: CanvasItem, tex: Texture2D, rect: Rect2, tint: Color) -> void:
	var ts := tex.get_size()
	var s := minf(rect.size.x / ts.x, rect.size.y / ts.y)
	var d := ts * s
	var pos := rect.position + (rect.size - d) / 2.0
	c.draw_texture_rect(tex, Rect2(pos, d), false, Color(tint, 0.9))


func _draw_static(c: CanvasItem, size: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_tick * 20.0)
	var cell := 4.0
	var y := 0.0
	while y < size.y:
		var x := 0.0
		while x < size.x:
			var v := rng.randf()
			c.draw_rect(Rect2(x, y, cell, cell), Color(v, v, v, 0.5))
			x += cell
		y += cell


func _draw_tracking(c: CanvasItem, size: Vector2, tint: Color) -> void:
	# A ground-track plot: latitude/longitude grid, a sine track, the craft's position.
	var grid := Color(tint, 0.18)
	for i in range(1, 6):
		var x := size.x * i / 6.0
		c.draw_line(Vector2(x, 0), Vector2(x, size.y), grid, 1.0)
	for i in range(1, 4):
		var y := size.y * i / 4.0
		c.draw_line(Vector2(0, y), Vector2(size.x, y), grid, 1.0)
	var pts := PackedVector2Array()
	for i in 41:
		var u := i / 40.0
		pts.append(Vector2(u * size.x, size.y * (0.5 + 0.3 * sin(u * TAU * 1.5))))
	c.draw_polyline(pts, Color(tint, 0.5), 1.5)
	var p := _mission_progress
	var dot := Vector2(p * size.x, size.y * (0.5 + 0.3 * sin(p * TAU * 1.5)))
	c.draw_circle(dot, 4.0, tint)
	c.draw_arc(dot, 8.0 + fmod(_tick * 10.0, 8.0), 0.0, TAU, 24, Color(tint, 0.5), 1.0)


# ----------------------------------------------------------------- feeds data

func _prepare_feeds(launch: Dictionary, state: SimState) -> void:
	_feed_tex = [null, null, null, null]
	_feed_names = FEED_NAMES.duplicate()
	_crew_tex = []
	var pidx := int(launch.get("player", 0))
	var side := "usa" if pidx == 0 else "ussr"
	var steps: Array = launch.get("steps", [])
	var names: Array = []
	for st in steps:
		var hw := str(st.get("hardware", ""))
		if hw != "" and not names.has(hw):
			names.append(hw)
	for hw in names:
		var found := _find_hardware(state, side, hw)
		if found.is_empty():
			continue
		if found["group"] == "rocket" and _feed_tex[1] == null:
			_feed_tex[1] = ArtAssets.hardware(side, "rocket", found["slot"])
		elif found["group"] in ["manned", "probe"] and _feed_tex[0] == null:
			_feed_tex[0] = ArtAssets.hardware(side, found["group"], found["slot"])
			_feed_names[0] = "PAYLOAD" if found["group"] == "probe" else "CAPSULE"
	var p := state.player(pidx)
	for id in launch.get("crew_outcomes", {}).keys():
		var idx := int(id)
		if idx >= 0 and idx < p.astronauts.size():
			var tex := ArtAssets.portrait(p.astronauts[idx].name)
			if tex != null:
				_crew_tex.append(tex)
	for f in _feeds:
		f.queue_redraw()
	_wall.queue_redraw()


func _find_hardware(state: SimState, side: String, name: String) -> Dictionary:
	var models: Dictionary = state.data.hardware.get("models", {})
	for model_key in [state.model, "basic"]:
		if not models.has(model_key):
			continue
		for group in ["rocket", "manned", "probe", "misc"]:
			var specs: Array = models[model_key][side].get(group, [])
			for slot in specs.size():
				var spec = specs[slot]
				if spec != null and str(spec.get("name", "")).to_upper() == name.to_upper():
					return {"group": group, "slot": slot}
	return {}


# ----------------------------------------------------------------- flow

func setup(args: Dictionary) -> void:
	_report = args.get("report", {})
	var human := 0 if Session.human_side == "usa" else 1
	_launches = PlaybackScript.visible_launches(_report, human)
	if _launches.is_empty():
		_step_title.text = "NO LAUNCHES"
		_mission_label.text = "Nothing flew this season"
		_continue_btn.visible = true
		_skip_btn.visible = false
		return
	call_deferred("_play_all")


func handles_back() -> bool:
	# Escape skips rather than closing mid-flight.
	if _playing:
		_skip_requested = true
		return true
	return false


func _set_speed(v: float) -> void:
	_speed = clampf(v, 0.25, 8.0)
	_speed_label.text = "Speed %.2fx" % _speed


func _set_mosaic(on: bool) -> void:
	_mosaic = on
	_strip.get_parent().visible = not on
	_bottom.get_parent().visible = not on
	_layout_wall()
	_stage.queue_redraw()


func _play_all() -> void:
	_playing = true
	for i in _launches.size():
		_current = i
		_skip_requested = false
		await _play_launch(_launches[i])
		if _skip_all:
			break
	_playing = false
	_step_title.text = "SEASON COMPLETE"
	_subtitle.text = "%d launch%s" % [_launches.size(), "" if _launches.size() == 1 else "es"]
	_skip_btn.visible = false
	_continue_btn.visible = true
	_lights.queue_redraw()


func _play_launch(launch: Dictionary) -> void:
	var state := Session.state()
	var mi := int(launch.get("mission_index", 0))
	var side := "USA" if int(launch.get("player", 0)) == 0 else "USSR"
	_mission_label.text = "%s: %s" % [side, PlaybackScript.mission_title(str(state.data.missions[mi]["name"]))]
	_subtitle.text = "Launch %d of %d" % [_current + 1, _launches.size()]
	_set_room("usa" if side == "USA" else "ussr")
	_log.clear()
	_stage_ctx = PlaybackScript.context_for(launch, state)
	_steps = launch.get("steps", [])
	_revealed = 0
	_mission_progress = 0.0
	_chart.set_steps(_steps)
	_prepare_feeds(launch, state)
	var items := PlaybackScript.sequence(launch, state)
	var shown := 0
	for item in items:
		if _skip_requested:
			break
		match item["kind"]:
			"step":
				shown = item["index"] + 1
				if item["step"].get("letter", "") == "A":
					Sound.sfx("launch", -4.0)
				if not item["step"].get("success", false):
					Sound.sfx("explosion", -6.0)
				await _play_step(item["step"])
				_revealed = shown
				_chart.reveal(shown)
				_append_log(item["step"])
			"flash", "verdict":
				if item["kind"] == "verdict":
					Sound.sfx("success" if item["color"] == UiPalette.OK else "failure")
				elif item["kicker"] == "FIRST":
					Sound.sfx("first")
				_log.append_text("[color=#%s]%s: %s[/color]\n" % [item["color"].to_html(false), item["headline"], item["body"]])
				var hold: float = (PlaybackScript.VERDICT_SECONDS if item["kind"] == "verdict" else PlaybackScript.FLASH_SECONDS) / _speed
				await _flash.flash(item["kicker"], item["headline"], item["body"], item["color"], hold)
	if _skip_requested:
		# Reveal everything at once.
		_flash.hide_now()
		_revealed = _steps.size()
		_mission_progress = 1.0
		_chart.reveal(_steps.size())
		_log.clear()
		for st in _steps:
			_append_log(st)
		var verdict: Dictionary = items.back() if not items.is_empty() else {}
		if verdict.get("kind", "") == "verdict":
			_log.append_text("[color=#%s]%s: %s[/color]\n" % [verdict["color"].to_html(false), verdict["headline"], verdict["body"]])
		if not _skip_all:
			await get_tree().create_timer(0.6).timeout


func _play_step(step: Dictionary) -> void:
	_stage_letter = str(step.get("letter", "A"))
	_stage_ok = step.get("success", false)
	_stage_ctx["hardware_kind"] = PlaybackScript.hardware_kind(step)
	_step_title.text = Vignettes.title_for(_stage_letter).to_upper()
	_stage_t = 0.0
	var index := int(step.get("index", _revealed))
	var n := maxi(_steps.size(), 1)
	var duration := PlaybackScript.STEP_SECONDS / _speed
	var elapsed := 0.0
	while elapsed < duration and not _skip_requested:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		_stage_t = clampf(elapsed / duration, 0.0, 1.0)
		_mission_progress = clampf((index + _stage_t) / n, 0.0, 1.0)
		_stage.queue_redraw()
	_stage_t = 1.0
	_stage.queue_redraw()


func _append_log(st: Dictionary) -> void:
	var ok: bool = st.get("success", false)
	var col := UiPalette.OK if ok else UiPalette.DANGER
	_log.append_text("[color=#%s]%s[/color]  %s  (%d%% / roll %d)\n" % [col.to_html(false), "OK" if ok else "FAIL",
			str(st.get("name", "")).capitalize(), int(st.get("safety", 0)), int(st.get("roll", 0))])
