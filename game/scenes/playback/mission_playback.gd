extends Control
## Mission playback, staged as a control room: a painted room for the lower half, a wall
## of monitors above it with the vignette on the big screen and live feeds (capsule,
## booster, crew, tracking) on the small ones, a status strip of step lights between,
## and the telemetry chart and mission log as console panels over the room. Skip, speed
## and a "Full stage" toggle that gives the vignette the whole screen. Pops itself when
## done; TurnFlow pushes the results table beneath it.
##
## ui-style-guide section 10: the controller lamp column on the left (roles lit for the
## active step), the flight crew as portrait lamps and the three status lamps on the
## right, a vertical safety gauge beside the main screen and the step name as a caption
## strip along its top. The roles are presentation only; the sim has no controllers.

const WALL_COLOR := Color(0.05, 0.06, 0.08, 0.80)
const BEZEL := Color("1b1e24")
const BEZEL_EDGE := Color("343a45")
const SCREEN_OFF := Color("05080c")
const FEED_GREEN := Color(0.55, 1.0, 0.65)
const FEED_AMBER := Color(1.0, 0.85, 0.5)
const FEED_GREY := Color(0.85, 0.9, 1.0)
const FEED_NAMES := ["CAPSULE", "BOOSTER", "CREW", "TRACKING"]
var _feed_names: Array = FEED_NAMES.duplicate()
const GAUGE_W := 76.0
## Controller roles on the left lamp column, top to bottom, with what each watches.
const ROLES := {
	"FLIGHT": "Flight director: runs the mission",
	"BOOSTER": "Booster systems engineer",
	"FIDO": "Flight dynamics: trajectory",
	"GUIDO": "Guidance and navigation",
	"RETRO": "Retrofire: return and re-entry",
	"EECOM": "Electrical, environment and consumables",
	"NETWORK": "Tracking network and communications",
	"CAPCOM": "Capsule communicator: the voice to the crew",
	"SURGEON": "Flight surgeon: crew health",
	"EVA": "Spacewalk systems",
	"LM": "Lunar module systems",
}
## Roles at the console for each vignette family (Vignettes.FAMILY).
const FAMILY_ROLES := {
	"launch": ["BOOSTER", "FIDO", "GUIDO"],
	"insertion": ["FIDO", "GUIDO", "BOOSTER"],
	"power_on": ["EECOM", "NETWORK"],
	"reentry": ["RETRO", "FIDO", "SURGEON"],
	"landing": ["RETRO", "CAPCOM", "SURGEON"],
	"orbit": ["CAPCOM", "EECOM"],
	"lunar_pass": ["FIDO", "GUIDO", "NETWORK"],
	"eva": ["EVA", "CAPCOM", "SURGEON"],
	"lunar_eva": ["EVA", "LM", "CAPCOM", "SURGEON"],
	"docking": ["GUIDO", "FIDO", "CAPCOM"],
	"lm_ops": ["LM", "CAPCOM", "EECOM"],
	"lm_descent": ["LM", "GUIDO", "FIDO"],
	"lm_landing": ["LM", "GUIDO", "CAPCOM"],
	"lm_liftoff": ["LM", "GUIDO", "FIDO"],
	"lm_test": ["LM", "EECOM"],
	"photo": ["NETWORK", "EECOM"],
	"planetary": ["NETWORK", "FIDO", "GUIDO"],
	"duration": ["SURGEON", "EECOM", "CAPCOM"],
}
const CREW_ROLES := ["CAPCOM", "SURGEON", "EVA"]

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
var _gauge: Gauge
var _caption: PanelContainer
var _left_col: Control
var _right_col: Control
var _role_lamps: Dictionary = {}     ## role -> Lamp
var _crew_box: VBoxContainer
var _crew_lamps: Dictionary = {}     ## astronaut id -> Lamp
var _status: StatusLamps
var _manned := false
var _failed := false


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

	# The middle row: controller lamps, the monitor wall, crew and status lamps.
	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.size_flags_stretch_ratio = 3.2
	middle.add_theme_constant_override("separation", 0)
	root.add_child(middle)
	_left_col = _build_controllers()
	middle.add_child(_left_col)
	_wall = Control.new()
	_wall.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wall.clip_contents = true
	_wall.draw.connect(_draw_wall)
	_wall.resized.connect(_layout_wall)
	middle.add_child(_wall)
	_right_col = _build_crew_column()
	middle.add_child(_right_col)
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
	_gauge = Gauge.new(true, "Safety of the hardware on this step")
	_gauge.tooltip_text = "Safety of the hardware on this step"
	_gauge.mouse_filter = Control.MOUSE_FILTER_PASS
	_wall.add_child(_gauge)
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
	# The step name as a caption strip along the top of the main screen.
	_caption = PanelContainer.new()
	var cap_sb := UiTheme.flat(Color(UiPalette.BG_DEEP, 0.78), Color.TRANSPARENT, 0, 0)
	cap_sb.border_width_bottom = 1
	cap_sb.border_color = Color(UiPalette.GOLD, 0.5)
	cap_sb.content_margin_left = 14
	cap_sb.content_margin_right = 14
	cap_sb.content_margin_top = 4
	cap_sb.content_margin_bottom = 4
	_caption.add_theme_stylebox_override("panel", cap_sb)
	_caption.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_caption)
	_step_title = Label.new()
	_step_title.theme_type_variation = "CapsBright"
	_step_title.add_theme_color_override("font_color", UiPalette.GOLD)
	_step_title.clip_text = true
	_step_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_caption.add_child(_step_title)

	# Status strip: mission name, step lights, launch counter.
	_strip = HBoxContainer.new()
	_strip.add_theme_constant_override("separation", 20)
	var strip_bg := PanelContainer.new()
	strip_bg.add_theme_stylebox_override("panel", UiTheme.flat(Color("0d1117", 0.92), BEZEL_EDGE, 0, 1))
	strip_bg.add_child(_strip)
	root.add_child(strip_bg)
	_mission_label = Label.new()
	_mission_label.theme_type_variation = "Subheading"
	_strip.add_child(_mission_label)
	_lights = Control.new()
	_lights.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lights.custom_minimum_size.y = 44
	_lights.tooltip_text = "Step lights: green passed, red failed, white the step in flight"
	_lights.draw.connect(_draw_lights)
	_strip.add_child(_lights)
	_subtitle = Label.new()
	_subtitle.theme_type_variation = "Dim"
	_strip.add_child(_subtitle)
	for i in [0, 4]:
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
	slower.tooltip_text = "Slow the playback down"
	slower.pressed.connect(func(): _set_speed(_speed / 1.5))
	controls.add_child(slower)
	var faster := Button.new()
	faster.text = "Faster"
	faster.theme_type_variation = "Flat"
	faster.tooltip_text = "Speed the playback up"
	faster.pressed.connect(func(): _set_speed(_speed * 1.5))
	controls.add_child(faster)
	var mosaic := Button.new()
	mosaic.text = "Full stage"
	mosaic.theme_type_variation = "Flat"
	mosaic.toggle_mode = true
	mosaic.tooltip_text = "Give the main screen the whole display"
	mosaic.toggled.connect(_set_mosaic)
	controls.add_child(mosaic)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(spacer)
	_skip_btn = Button.new()
	UiAction.style(_skip_btn, "neutral", "Skip launch")
	_skip_btn.tooltip_text = "Jump to the end of this launch  (Esc)"
	_skip_btn.custom_minimum_size.x = 170
	_skip_btn.pressed.connect(func(): _skip_requested = true)
	controls.add_child(_skip_btn)
	var skip_all := Button.new()
	UiAction.style(skip_all, "neutral", "Skip all")
	skip_all.tooltip_text = "Jump to the end of every launch this season"
	skip_all.custom_minimum_size.x = 140
	skip_all.pressed.connect(func():
		_skip_all = true
		_skip_requested = true)
	controls.add_child(skip_all)
	_continue_btn = Button.new()
	UiAction.style(_continue_btn, "go", "Continue")
	_continue_btn.tooltip_text = "On to the launch results"
	_continue_btn.custom_minimum_size.x = 170
	_continue_btn.visible = false
	_continue_btn.pressed.connect(func(): Screens.pop())
	controls.add_child(_continue_btn)
	_set_speed(_speed)
	_set_room(Session.human_side if Session.has_game() else "usa")
	_light_roles("", true)
	_status.set_level(StatusLamps.Level.NONE)
	_crew_placeholder("NO FLIGHT")


func _build_controllers() -> Control:
	var panel := UiPanel.new("Controllers")
	panel.size_flags_horizontal = Control.SIZE_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.x = 200
	for role in ROLES:
		var lamp := Lamp.new(role)
		lamp.tooltip_text = ROLES[role]
		lamp.custom_minimum_size = Vector2(170, 32)
		panel.body.add_child(lamp)
		_role_lamps[role] = lamp
	return _margin(panel)


func _build_crew_column() -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	var crew := UiPanel.new("Flight crew")
	crew.size_flags_horizontal = Control.SIZE_FILL
	crew.size_flags_vertical = Control.SIZE_EXPAND_FILL
	crew.custom_minimum_size.x = 230
	_crew_box = VBoxContainer.new()
	_crew_box.add_theme_constant_override("separation", 6)
	crew.body.add_child(_crew_box)
	col.add_child(crew)
	var status := UiPanel.new("Status")
	status.size_flags_horizontal = Control.SIZE_FILL
	_status = StatusLamps.new()
	_status.tooltip_text = "Nominal while steps pass, warning when a step is saved or recovered, failure when a step fails"
	status.body.add_child(_status)
	col.add_child(status)
	return _margin(col)


func _margin(c: Control) -> MarginContainer:
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 14)
	m.add_child(c)
	return m


## Controller roles at the console for a step letter (presentation only). `manned` keeps
## the crew-facing roles; unmanned flights drop them.
static func controller_roles(letter: String, manned := true) -> Array:
	var roles: Array = ["FLIGHT"]
	if letter == "":
		return roles
	for r in FAMILY_ROLES.get(Vignettes.family_for(letter), ["CAPCOM"]):
		if manned or r not in CREW_ROLES:
			roles.append(r)
	return roles


## Light the roles for the active step: green when it passes, amber when saved or
## recovered, red when it fails.
func _light_roles(letter: String, idle: bool, state: int = Lamp.State.ON) -> void:
	var lit: Array = [] if idle else controller_roles(letter, _manned)
	for role in _role_lamps:
		_role_lamps[role].set_state(state if role in lit else Lamp.State.OFF)


## Status level for one step record: failure, warning (saved by a card, or a problem the
## mission recovered from), or nominal.
static func step_level(step: Dictionary) -> int:
	if step.get("success", false):
		return StatusLamps.Level.WARNING if step.get("save_card", false) else StatusLamps.Level.NOMINAL
	if int(step.get("step_info", 0)) < SimMission.INFO_MISSION_END:
		return StatusLamps.Level.WARNING
	return StatusLamps.Level.FAILURE


func _show_step_result(step: Dictionary) -> void:
	var level := step_level(step)
	if level == StatusLamps.Level.FAILURE:
		_failed = true
	_status.set_level(StatusLamps.Level.FAILURE if _failed else level)
	var lamp_state: int = [Lamp.State.ON, Lamp.State.WARN, Lamp.State.FAIL][level]
	_light_roles(str(step.get("letter", "")), false, lamp_state)


func _build_crew(launch: Dictionary, state: SimState) -> void:
	for c in _crew_box.get_children():
		c.queue_free()
	_crew_lamps.clear()
	var p := state.player(int(launch.get("player", 0)))
	var ids: Array = launch.get("crew_outcomes", {}).keys()
	_manned = not ids.is_empty()
	if ids.is_empty():
		_crew_placeholder("UNMANNED")
		return
	for id in ids:
		var a: SimAstronaut = null
		for cand in p.astronauts:
			if cand.id == int(id):
				a = cand
		if a == null:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var tile := TextureRect.new()
		tile.texture = ArtAssets.portrait(a.name)
		tile.custom_minimum_size = Vector2(48, 48)
		tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tile.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tile.clip_contents = true
		row.add_child(tile)
		var lamp := Lamp.new(a.name, Lamp.State.ON)
		lamp.custom_minimum_size = Vector2(150, 40)
		lamp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lamp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lamp.mouse_filter = Control.MOUSE_FILTER_PASS
		lamp.tooltip_text = "%s: in flight" % a.name
		row.add_child(lamp)
		_crew_box.add_child(row)
		_crew_lamps[int(id)] = lamp


func _crew_placeholder(text: String) -> void:
	var none := Label.new()
	none.text = text
	none.theme_type_variation = "Caps"
	none.tooltip_text = "No crew aboard"
	_crew_box.add_child(none)


## Crew lamps at the end of a launch: green home safe, amber injured, red lost.
func _show_crew_outcomes(launch: Dictionary) -> void:
	var outcomes: Dictionary = launch.get("crew_outcomes", {})
	for id in outcomes:
		var lamp: Lamp = _crew_lamps.get(int(id))
		if lamp == null:
			continue
		var o := str(outcomes[id])
		lamp.set_state({"injured": Lamp.State.WARN, "dead": Lamp.State.FAIL}.get(o, Lamp.State.ON))
		lamp.tooltip_text = "%s: %s" % [lamp.text.capitalize(), {"injured": "injured", "dead": "lost", "retired": "retired"}.get(o, "safe")]


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
		_gauge.visible = false
		_wall.queue_redraw()
		return
	var m := 18.0
	var caption := 22.0
	var g := GAUGE_W
	var big_h := h - m * 2 - caption
	var big_w := minf((w - g) * 0.58, big_h * 16.0 / 9.0)
	big_h = big_w * 9.0 / 16.0
	_big_rect = Rect2((w - g - big_w) / 2.0, m + (h - m * 2 - caption - big_h) / 2.0, big_w, big_h)
	var col_w := _big_rect.position.x - m * 2
	var small_h := (h - m * 2 - caption * 2 - m) / 2.0
	var small_w := minf(col_w, small_h * 4.0 / 3.0)
	small_h = small_w * 3.0 / 4.0
	var total_h := small_h * 2 + caption * 2 + m
	var y0 := (h - total_h) / 2.0
	_small_rects = [
		Rect2(m + (col_w - small_w) / 2.0, y0, small_w, small_h),
		Rect2(m + (col_w - small_w) / 2.0, y0 + small_h + caption + m, small_w, small_h),
		Rect2(_big_rect.end.x + g + m + (col_w - small_w) / 2.0, y0, small_w, small_h),
		Rect2(_big_rect.end.x + g + m + (col_w - small_w) / 2.0, y0 + small_h + caption + m, small_w, small_h),
	]
	_gauge.visible = true
	_gauge.position = Vector2(_big_rect.end.x + 14, _big_rect.position.y)
	_gauge.size = Vector2(g - 18, _big_rect.size.y)
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
	_wall.draw_string(font, Vector2(_gauge.position.x - 8, _big_rect.end.y + 17), "SAFETY", HORIZONTAL_ALIGNMENT_CENTER, _gauge.size.x + 16, UiTheme.SIZE_SMALL, UiPalette.TEXT_DIM)


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
		for a in p.astronauts:
			if a.id == int(id):
				var tex := ArtAssets.portrait(a.name)
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
	_left_col.visible = not on
	_right_col.visible = not on
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
	_build_crew(launch, state)
	_failed = false
	_status.set_level(StatusLamps.Level.NOMINAL)
	_light_roles("", true)
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
				_show_step_result(item["step"])
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
		var worst: int = StatusLamps.Level.NOMINAL
		for st in _steps:
			worst = maxi(worst, step_level(st))
		_status.set_level(worst)
		_light_roles("", true)
		_gauge.value = 0.0
		if not _skip_all:
			await get_tree().create_timer(0.6).timeout
	_show_crew_outcomes(launch)


func _play_step(step: Dictionary) -> void:
	_stage_letter = str(step.get("letter", "A"))
	_stage_ok = step.get("success", false)
	_stage_ctx["hardware_kind"] = PlaybackScript.hardware_kind(step)
	var hw := str(step.get("hardware", ""))
	_step_title.text = (Vignettes.title_for(_stage_letter) + ("  ·  " + hw if hw != "" else "")).to_upper()
	_gauge.value = float(step.get("safety", 0))
	_light_roles(_stage_letter, false, Lamp.State.ON)
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
