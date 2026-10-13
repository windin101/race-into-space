class_name UiPanel
extends PanelContainer
## The one panel anatomy (ui-style-guide section 4): a title strip in the wide caps face
## with an optional (i) help badge, a body, and an optional full-width action bar along
## the bottom edge. Add content to `body`; add actions with add_action().
##
##   var p := UiPanel.new("Hardware", "I008")
##   p.body.add_child(...)
##   p.add_action("Purchase program (24 MB)", "go", _on_buy)

var body: VBoxContainer
var _title: Label
var _strip: PanelContainer
var _bar: HBoxContainer
var _help := ""


func _init(title_text := "", help_code := "") -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := UiTheme.flat(Color(UiPalette.PANEL, 0.86), UiPalette.BORDER_SOFT, 10, 1)
	sb.set_content_margin_all(0)
	add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	add_child(v)
	_strip = PanelContainer.new()
	var strip_sb := UiTheme.flat(UiPalette.PANEL_SUNKEN, Color.TRANSPARENT, 0, 0)
	strip_sb.corner_radius_top_left = 10
	strip_sb.corner_radius_top_right = 10
	strip_sb.content_margin_left = 14
	strip_sb.content_margin_right = 10
	strip_sb.content_margin_top = 5
	strip_sb.content_margin_bottom = 5
	_strip.add_theme_stylebox_override("panel", strip_sb)
	v.add_child(_strip)
	var strip_row := HBoxContainer.new()
	_strip.add_child(strip_row)
	_title = Label.new()
	_title.theme_type_variation = "Caps"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.clip_text = true
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	strip_row.add_child(_title)
	if help_code != "":
		_help = help_code
		var badge := Button.new()
		badge.icon = ArtAssets.icon("chip_info")
		badge.theme_type_variation = "Flat"
		badge.tooltip_text = "Help for this panel"
		badge.focus_mode = Control.FOCUS_NONE
		badge.add_theme_constant_override("icon_max_width", 20)
		badge.pressed.connect(func(): UiHelp.show_code(self, _help))
		strip_row.add_child(badge)
		UiHelp.attach(self, help_code)
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 12)
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(pad)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pad.add_child(body)
	_bar = HBoxContainer.new()
	_bar.add_theme_constant_override("separation", 0)
	_bar.visible = false
	v.add_child(_bar)
	set_title(title_text)


func set_title(text: String) -> void:
	_title.text = text.to_upper()
	_strip.visible = text != "" or _help != ""


## Hide the title strip entirely (for viewers that carry their own name strip).
func hide_title() -> void:
	_strip.visible = false


## Add a full-width action. kind: "go", "caution", "blocked", "neutral". Several actions
## share the bar equally. A blocked action stays clickable and explains `reason`.
func add_action(text: String, kind := "go", callback: Callable = Callable(), reason := "") -> Button:
	var b := Button.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size.y = 44
	UiAction.style(b, kind, text, reason)
	if callback.is_valid():
		b.pressed.connect(func():
			if b.get_meta("blocked_reason", "") == "":
				callback.call())
	_bar.add_child(b)
	_bar.visible = true
	b.visibility_changed.connect(refresh_bar)
	_round_bar()
	return b


func clear_actions() -> void:
	for c in _bar.get_children():
		c.queue_free()
	_bar.visible = false


func _round_bar() -> void:
	# Bar buttons are square except the outer bottom corners of the first and last
	# visible button, which follow the panel. Recorded on each button so UiAction.style()
	# keeps them when it restyles.
	var shown: Array = []
	for c in _bar.get_children():
		if c is Button and c.visible and not c.is_queued_for_deletion():
			shown.append(c)
	_bar.visible = not shown.is_empty()
	for i in shown.size():
		var b: Button = shown[i]
		b.set_meta("bar_corners", Vector2i(1 if i == 0 else 0, 1 if i == shown.size() - 1 else 0))
		UiAction.apply_corners(b)


## Re-round the bar after showing or hiding an action (also runs automatically).
func refresh_bar() -> void:
	_round_bar()


## Restyle an action created with add_action (kept for callers that used the workaround).
func restyle_action(b: Button, kind: String, text: String, reason := "") -> void:
	UiAction.style(b, kind, text, reason)
