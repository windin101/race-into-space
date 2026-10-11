class_name AstronautCard
extends PanelContainer
## Summary card for one astronaut: name, status, mood and the five skills.

signal pressed(astronaut: SimAstronaut)

const SKILL_TITLES := {"capsule": "Capsule", "lm": "LM", "eva": "EVA", "docking": "Docking", "endurance": "Endurance"}

var astronaut: SimAstronaut

var _name: Label
var _status: Label
var _mood: StatBar
var _skills: Dictionary = {}
var _button: Button


func _init() -> void:
	theme_type_variation = "Card"
	custom_minimum_size = Vector2(280, 210)
	var v := VBoxContainer.new()
	add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	_name = Label.new()
	_name.theme_type_variation = "Subheading"
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_name)
	_status = Label.new()
	_status.theme_type_variation = "Dim"
	top.add_child(_status)
	_mood = StatBar.new("Mood")
	_mood.label_width = 80
	v.add_child(_mood)
	for key in SKILL_TITLES:
		var bar := StatBar.new(SKILL_TITLES[key], 0, SimAstronaut.SKILL_MAX, "")
		bar.label_width = 80
		bar.fixed_color = UiPalette.INFO
		v.add_child(bar)
		_skills[key] = bar
	_button = Button.new()
	_button.theme_type_variation = "Flat"
	_button.flat = true
	_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	_button.focus_mode = Control.FOCUS_NONE
	_button.pressed.connect(func(): pressed.emit(astronaut))
	add_child(_button)


func set_astronaut(a: SimAstronaut) -> void:
	astronaut = a
	_name.text = a.name.capitalize()
	_status.text = a.status_name().replace("_", " ")
	_mood.value = a.mood
	_mood.fixed_color = UiPalette.mood_color(a.mood)
	for key in _skills:
		_skills[key].value = a.skill(key)
		_skills[key].suffix = "/%d" % SimAstronaut.SKILL_MAX
