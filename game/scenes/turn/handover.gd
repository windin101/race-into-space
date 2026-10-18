extends ScreenPanel
## Hot-seat handover: between two people's turns, a full-screen card in the incoming side's
## colours asks for the controls to be passed on, so nobody sees another player's plans.
## The incoming side's own newscast (and review) follow it; Esc does not skip it.

var _flag: TextureRect
var _emblem: TextureRect
var _side_label: Label
var _who: Label
var _date: Label


func _init() -> void:
	super()
	title = "Pass the controls"
	show_back = false


func _ready() -> void:
	super()
	_sp_chips.modulate.a = 0.0   # hide the incoming side's figures but keep the bar's layout (actions stay right)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	var card := UiPanel.new("Next director", "")
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.custom_minimum_size = Vector2(760, 0)
	content.add_child(card)
	var box := card.body
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	var marks := HBoxContainer.new()
	marks.alignment = BoxContainer.ALIGNMENT_CENTER
	marks.add_theme_constant_override("separation", 28)
	box.add_child(marks)
	_flag = _picture(Vector2(220, 116))
	marks.add_child(_flag)
	_emblem = _picture(Vector2(140, 140))
	marks.add_child(_emblem)
	_side_label = Label.new()
	_side_label.theme_type_variation = "Heading"
	_side_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_side_label)
	_who = Label.new()
	_who.theme_type_variation = "Subheading"
	_who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_who.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_who)
	_date = Label.new()
	_date.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_date.add_theme_color_override("font_color", UiPalette.TEXT_DIM)
	box.add_child(_date)

	var go := Button.new()
	go.custom_minimum_size = Vector2(170, 40)
	UiAction.style(go, "go", "Take the controls")
	go.tooltip_text = "Only the incoming director should be looking from here on"
	go.pressed.connect(func(): Screens.pop())
	footer.add_child(go)
	_refresh()


func _picture(size: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.custom_minimum_size = size
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return t


func setup(_args: Dictionary) -> void:
	_refresh()


## Esc must not skip past the handover.
func handles_back() -> bool:
	return true


## The handover is the first thing the incoming player looks at, so focus starts on it.
func initial_focus() -> Control:
	return footer.get_child(footer.get_child_count() - 1) if footer.get_child_count() > 0 else null


func _refresh() -> void:
	if _side_label == null or not Session.has_game():
		return
	var side := Session.human_side
	var p := Session.me()
	_flag.texture = ArtAssets.icon("flag_%s" % side)
	_emblem.texture = ArtAssets.icon("emblem_%s" % side)
	_side_label.text = Sides.name(side).to_upper()
	_who.text = "Pass the controls to the %s programme director, %s." % [Sides.name(side), p.director_name.capitalize()]
	_date.text = "%s: the other directors should look away until the end of this turn." % Session.state().date_string()
