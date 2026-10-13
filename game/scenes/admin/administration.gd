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
const BUILDING_HELP := {"usa": "I702", "ussr": "I703"}   ## upstream help pages; other sides use the first

var _buttons: Dictionary = {}


func _init() -> void:
	super()
	title = "Administration"


func _ready() -> void:
	super()
	set_room("room_admin")
	var side := Session.human_side if Session.has_game() else "usa"
	UiHelp.attach(content, BUILDING_HELP.get(side, "I702"))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var centre := CenterContainer.new()
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(centre)
	var board := UiPanel.new("The offices", BUILDING_HELP.get(side, "I702"))
	board.custom_minimum_size.x = 1080
	centre.add_child(board)
	var intro := Label.new()
	intro.theme_type_variation = "Dim"
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.text = "The offices that run the programme between launches. Hover an office for help."
	board.body.add_child(intro)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	board.body.add_child(column)
	for office in OFFICES:
		column.add_child(_entry(office, side))


func _entry(office: Dictionary, side: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	var button := Button.new()
	button.text = office_title(office, side).to_upper()
	button.theme_type_variation = "Bar"
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(420, 72)
	var glyph := ArtAssets.icon(office["id"])
	if glyph != null:
		button.icon = glyph
		button.add_theme_constant_override("icon_max_width", 40)
		button.add_theme_constant_override("h_separation", 16)
	button.pressed.connect(_open.bind(office))
	row.add_child(button)
	_buttons[office["id"]] = button
	var text := Label.new()
	text.text = office["text"]
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(text)
	button.tooltip_text = office["text"]
	UiHelp.attach(text, office["help"])
	UiHelp.attach(button, office["help"])
	return row


## Recruiting is named for the side's word for its crews (astronaut, cosmonaut, ...).
static func office_title(office: Dictionary, side: String) -> String:
	if office["id"] == "recruiting":
		return "%s Recruiting" % str(Sides.field(side, "people", "astronaut")).capitalize()
	return office["title"]


func _open(office: Dictionary) -> void:
	var scene: String = office["scene"]
	if ResourceLoader.exists(scene):
		Screens.push(load(scene), {"id": office["id"], "title": office["title"], "help": office["help"]})
	else:
		ConfirmBox.notice(self, office["title"], "This office is not built yet.")
