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
	_round_bar()
	return b


func clear_actions() -> void:
	for c in _bar.get_children():
		c.queue_free()
	_bar.visible = false


func _round_bar() -> void:
	# Bar buttons are square except the outer bottom corners, which follow the panel.
	var n := _bar.get_child_count()
	for i in n:
		var b: Button = _bar.get_child(i)
		for state in ["normal", "hover", "pressed", "disabled"]:
			var sb := b.get_theme_stylebox(state)
			if sb is StyleBoxFlat:
				var c := (sb as StyleBoxFlat).duplicate() as StyleBoxFlat
				c.set_corner_radius_all(0)
				if i == 0:
					c.corner_radius_bottom_left = 10
				if i == n - 1:
					c.corner_radius_bottom_right = 10
				b.add_theme_stylebox_override(state, c)
