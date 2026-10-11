extends ScreenPanel
## Administration building: a sub-menu of the five offices. Each entry is a large button
## with a one-line description; the help tooltips come from text/help.json.

## Office entries: id, title, scene, help code, description. The recruiting title and
## the building help differ by side (I702 USA / I703 USSR; K601 / K602 key maps).
const OFFICES := [
	{"id": "budget", "title": "Budget Office", "scene": "res://scenes/admin/budget_office.tscn", "help": "I007",
		"text": "Prestige and budget graphs for both sides, plus this season's cash and spending."},
	{"id": "hardware", "title": "Hardware Purchase", "scene": "res://scenes/admin/hardware_purchase.tscn", "help": "I008",
		"text": "Open new programs and buy rockets, capsules, probes and support hardware."},
	{"id": "future", "title": "Future Missions", "scene": "res://scenes/admin/future_missions.tscn", "help": "I011",
		"text": "Schedule next season's launches: pick a pad, a mission and its duration."},
	{"id": "recruiting", "title": "Astronaut Recruiting", "scene": "res://scenes/admin/recruiting.tscn", "help": "I012",
		"text": "Hire the next group of candidates for basic training."},
	{"id": "preferences", "title": "Preferences", "scene": "res://scenes/admin/preferences.tscn", "help": "I013",
		"text": "Game options: sound, music, animation and astronaut editing."},
]
const BUILDING_HELP := {"usa": "I702", "ussr": "I703"}

var _buttons: Dictionary = {}


func _init() -> void:
	super()
	title = "Administration"


func _ready() -> void:
	super()
	var side := Session.human_side if Session.has_game() else "usa"
	UiHelp.attach(content, BUILDING_HELP.get(side, "I702"))

	var intro := Label.new()
	intro.theme_type_variation = "Dim"
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.text = "The offices that run the programme between launches. Hover an office for help."
	content.add_child(intro)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var centre := CenterContainer.new()
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(centre)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.custom_minimum_size.x = 900
	centre.add_child(column)

	for office in OFFICES:
		column.add_child(_entry(office, side))


func _entry(office: Dictionary, side: String) -> Control:
	var card := PanelContainer.new()
	card.theme_type_variation = "Card"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	card.add_child(row)
	var button := Button.new()
	button.text = office_title(office, side)
	button.theme_type_variation = "Accent"
	button.custom_minimum_size = Vector2(300, 64)
	button.pressed.connect(_open.bind(office))
	row.add_child(button)
	_buttons[office["id"]] = button
	var text := Label.new()
	text.text = office["text"]
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(text)
	UiHelp.attach(card, office["help"])
	UiHelp.attach(button, office["help"])
	return card


## Soviet side recruits cosmonauts; everything else reads the same.
static func office_title(office: Dictionary, side: String) -> String:
	if office["id"] == "recruiting" and side == "ussr":
		return "Cosmonaut Recruiting"
	return office["title"]


func _open(office: Dictionary) -> void:
	var scene: String = office["scene"]
	if ResourceLoader.exists(scene):
		Screens.push(load(scene), {"id": office["id"], "title": office["title"], "help": office["help"]})
	else:
		ConfirmBox.notice(self, office["title"], "This office is not built yet.")
