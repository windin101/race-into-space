extends Control
## Mission playback: plays every visible launch of the season as animated vignettes with
## the step chart, a running log and news flashes. Skip, speed and a mosaic (full-stage)
## toggle. Pops itself when done; TurnFlow pushes the results table beneath it.

var _report: Dictionary = {}
var _launches: Array = []
var _current := 0
var _skip_requested := false
var _skip_all := false
var _playing := false
var _speed := 1.0

var _stage: Control
var _stage_letter := ""
var _stage_t := 0.0
var _stage_ok := true
var _stage_ctx: Dictionary = {}
var _chart: StepChart
var _log: RichTextLabel
var _title: Label
var _subtitle: Label
var _flash: NewsFlash
var _side_panel: VBoxContainer
var _bottom: VBoxContainer
var _mosaic := false
var _speed_label: Label
var _skip_btn: Button
var _continue_btn: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_speed = Settings.animation_speed
	var bg := ColorRect.new()
	bg.color = UiPalette.BG_DEEP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + s, 20)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	_title = Label.new()
	_title.theme_type_variation = "Heading"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	_subtitle = Label.new()
	_subtitle.theme_type_variation = "Dim"
	header.add_child(_subtitle)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root.add_child(body)
	var stage_panel := PanelContainer.new()
	stage_panel.theme_type_variation = "Sunken"
	stage_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_panel.size_flags_stretch_ratio = 3.0
	body.add_child(stage_panel)
	_stage = Control.new()
	_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.clip_contents = true
	_stage.draw.connect(_draw_stage)
	_stage.resized.connect(_stage.queue_redraw)
	stage_panel.add_child(_stage)
	_flash = NewsFlash.new()
	_flash.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_flash.anchor_left = 0.15
	_flash.anchor_right = 0.85
	_flash.anchor_top = 0.72
	_flash.anchor_bottom = 0.72
	_flash.offset_left = 0
	_flash.offset_right = 0
	_flash.grow_vertical = Control.GROW_DIRECTION_BOTH
	_stage.add_child(_flash)

	_side_panel = VBoxContainer.new()
	_side_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_side_panel.custom_minimum_size.x = 300
	body.add_child(_side_panel)
	var log_title := Label.new()
	log_title.theme_type_variation = "Subheading"
	log_title.text = "Mission log"
	_side_panel.add_child(log_title)
	_log = RichTextLabel.new()
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.scroll_following = true
	_log.bbcode_enabled = true
	_side_panel.add_child(_log)

	_bottom = VBoxContainer.new()
	root.add_child(_bottom)
	_chart = StepChart.new()
	_bottom.add_child(_chart)

	var controls := HBoxContainer.new()
	root.add_child(controls)
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


func setup(args: Dictionary) -> void:
	_report = args.get("report", {})
	var human := 0 if Session.human_side == "usa" else 1
	_launches = PlaybackScript.visible_launches(_report, human)
	if _launches.is_empty():
		_title.text = "No launches this season"
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
	_side_panel.visible = not on
	_bottom.visible = not on


func _play_all() -> void:
	_playing = true
	for i in _launches.size():
		_current = i
		_skip_requested = false
		await _play_launch(_launches[i])
		if _skip_all:
			break
	_playing = false
	_title.text = "Season complete"
	_subtitle.text = "%d launch%s" % [_launches.size(), "" if _launches.size() == 1 else "es"]
	_skip_btn.visible = false
	_continue_btn.visible = true


func _play_launch(launch: Dictionary) -> void:
	var state := Session.state()
	var mi := int(launch.get("mission_index", 0))
	var side := "USA" if int(launch.get("player", 0)) == 0 else "USSR"
	_title.text = "%s: %s" % [side, PlaybackScript.mission_title(str(state.data.missions[mi]["name"]))]
	_subtitle.text = "Launch %d of %d" % [_current + 1, _launches.size()]
	_log.clear()
	_stage_ctx = PlaybackScript.context_for(launch, state)
	var steps: Array = launch.get("steps", [])
	_chart.set_steps(steps)
	var items := PlaybackScript.sequence(launch, state)
	var shown := 0
	for item in items:
		if _skip_requested:
			break
		match item["kind"]:
			"step":
				shown = item["index"] + 1
				await _play_step(item["step"])
				_chart.reveal(shown)
				_append_log(item["step"])
			"flash", "verdict":
				_log.append_text("[color=#%s]%s: %s[/color]\n" % [item["color"].to_html(false), item["headline"], item["body"]])
				var hold: float = (PlaybackScript.VERDICT_SECONDS if item["kind"] == "verdict" else PlaybackScript.FLASH_SECONDS) / _speed
				await _flash.flash(item["kicker"], item["headline"], item["body"], item["color"], hold)
	if _skip_requested:
		# Reveal everything at once.
		_flash.hide_now()
		_chart.reveal(steps.size())
		_log.clear()
		for st in steps:
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
	_stage_t = 0.0
	var duration := PlaybackScript.STEP_SECONDS / _speed
	var elapsed := 0.0
	while elapsed < duration and not _skip_requested:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		_stage_t = clampf(elapsed / duration, 0.0, 1.0)
		_stage.queue_redraw()
	_stage_t = 1.0
	_stage.queue_redraw()


func _append_log(st: Dictionary) -> void:
	var ok: bool = st.get("success", false)
	var col := UiPalette.OK if ok else UiPalette.DANGER
	_log.append_text("[color=#%s]%s[/color]  %s  (%d%% / roll %d)\n" % [col.to_html(false), "OK" if ok else "FAIL",
			str(st.get("name", "")).capitalize(), int(st.get("safety", 0)), int(st.get("roll", 0))])


func _draw_stage() -> void:
	if _stage_letter == "":
		_stage.draw_rect(Rect2(Vector2.ZERO, _stage.size), Vignettes.SPACE)
		return
	Vignettes.paint(_stage, _stage_letter, _stage_t, _stage_ok, _stage.size, _stage_ctx)
	var font := get_theme_default_font()
	_stage.draw_string(font, Vector2(16, 30), Vignettes.title_for(_stage_letter), HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_SUBHEADING, UiPalette.TEXT)
