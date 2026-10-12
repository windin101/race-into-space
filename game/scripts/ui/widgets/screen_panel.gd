class_name ScreenPanel
extends Control
## Base for full-screen panels: a header with title and back button, a content area and
## a footer for actions. Subclasses add children to `content` and `footer`.

var title := "":
	set(v):
		title = v
		if _title:
			_title.text = v
var show_back := true

var content: VBoxContainer
var footer: HBoxContainer
var _backdrop: TextureRect
var _panel: PanelContainer
var _title: Label
var _back: Button
var _status: Label


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiPalette.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_backdrop = TextureRect.new()
	_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.modulate = Color(0.65, 0.65, 0.65)
	_backdrop.visible = false
	add_child(_backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	margin.add_child(v)
	var header := HBoxContainer.new()
	v.add_child(header)
	_back = Button.new()
	_back.text = "◀ Back"
	_back.theme_type_variation = "Flat"
	_back.pressed.connect(_on_back)
	header.add_child(_back)
	_title = Label.new()
	_title.theme_type_variation = "Heading"
	_title.text = title
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	_status = Label.new()
	_status.theme_type_variation = "Dim"
	header.add_child(_status)
	_panel = PanelContainer.new()
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_panel)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	_panel.add_child(content)
	footer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(footer)


func _ready() -> void:
	_back.visible = show_back
	_refresh_status()
	if Session.has_game():
		Session.state_changed.connect(_refresh_status)


## Show a full-screen painting behind the panel (assets/art/backdrops/<name>.png) when one
## exists; the content panel turns translucent so the art reads through. No file, no change.
func set_backdrop(name: String) -> void:
	var tex := ArtAssets.backdrop(name)
	_backdrop.texture = tex
	_backdrop.visible = tex != null
	if tex != null:
		_panel.add_theme_stylebox_override("panel", UiTheme.flat(Color(UiPalette.PANEL, 0.72), UiPalette.BORDER_SOFT))
		_make_translucent(content)
	else:
		_panel.remove_theme_stylebox_override("panel")


## Nested panels (Sunken, Card) would hide the art, so they get a see-through copy of
## their own stylebox. Called once the subclass has built its content.
func _make_translucent(node: Node) -> void:
	for child in node.get_children():
		if child is PanelContainer and not child.has_theme_stylebox_override("panel"):
			var sb: StyleBox = child.get_theme_stylebox("panel")
			if sb is StyleBoxFlat:
				var copy := sb.duplicate() as StyleBoxFlat
				copy.bg_color = Color(copy.bg_color, 0.78)
				child.add_theme_stylebox_override("panel", copy)
		_make_translucent(child)


func set_status(text: String) -> void:
	_status.text = text


func _refresh_status() -> void:
	if Session.has_game():
		var me := Session.me()
		_status.text = "%s   Cash %d MB   Budget %d MB" % [Session.state().date_string(), me.cash, me.budget]


func _on_back() -> void:
	Screens.pop()
