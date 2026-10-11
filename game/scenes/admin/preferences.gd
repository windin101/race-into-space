extends ScreenPanel
## Preferences: save slots (save, load, delete), the settings screen and quit to title.
## Works from the title screen with no game (only load, settings and back) and in-game.

const SPACEPORT := "res://scenes/spaceport/spaceport.tscn"
const TITLE := "res://scenes/ui/title_screen.tscn"
const SETTINGS := "res://scenes/ui/settings_screen.tscn"
const SIDE_TITLES := {"usa": "USA", "ussr": "USSR"}

var _table: DataTable
var _label_edit: LineEdit
var _message: Label
var _save_new: Button
var _save_over: Button
var _load: Button
var _delete: Button
var _quit: Button
var _selected: Dictionary = {}


func _init() -> void:
	super()
	title = "Preferences"


func _ready() -> void:
	super()
	var heading := Label.new()
	heading.theme_type_variation = "Subheading"
	heading.text = "Saved games"
	content.add_child(heading)

	_table = DataTable.new()
	_table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_table.set_columns([
		{"key": "label", "title": "Label", "stretch": 3},
		{"key": "date", "title": "Game date", "stretch": 1.5},
		{"key": "side", "title": "Side"},
		{"key": "saved_at", "title": "Saved", "stretch": 2},
	])
	_table.row_selected.connect(_on_row)
	_table.row_activated.connect(func(_row): _on_load())
	content.add_child(_table)

	var save_row := HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 10)
	content.add_child(save_row)
	var l := Label.new()
	l.text = "Label"
	save_row.add_child(l)
	_label_edit = LineEdit.new()
	_label_edit.placeholder_text = "Name for a new save"
	_label_edit.max_length = 40
	_label_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_edit.text_submitted.connect(func(_t): _on_save_new())
	save_row.add_child(_label_edit)
	_save_new = Button.new()
	_save_new.text = "Save to new slot"
	_save_new.theme_type_variation = "Accent"
	_save_new.pressed.connect(_on_save_new)
	save_row.add_child(_save_new)
	_save_over = Button.new()
	_save_over.text = "Save over selected"
	_save_over.pressed.connect(_on_save_over)
	save_row.add_child(_save_over)

	var slot_row := HBoxContainer.new()
	slot_row.add_theme_constant_override("separation", 10)
	content.add_child(slot_row)
	_load = Button.new()
	_load.text = "Load selected"
	_load.pressed.connect(_on_load)
	slot_row.add_child(_load)
	_delete = Button.new()
	_delete.text = "Delete selected"
	_delete.theme_type_variation = "Danger"
	_delete.pressed.connect(_on_delete)
	slot_row.add_child(_delete)
	_message = Label.new()
	_message.theme_type_variation = "Dim"
	_message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_message.clip_text = true
	_message.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	slot_row.add_child(_message)

	var settings := Button.new()
	settings.text = "Settings"
	settings.pressed.connect(func(): Screens.push(load(SETTINGS)))
	footer.add_child(settings)
	_quit = Button.new()
	_quit.text = "Quit to title"
	_quit.theme_type_variation = "Danger"
	_quit.pressed.connect(_on_quit)
	footer.add_child(_quit)
	_refresh()


func setup(_args: Dictionary) -> void:
	_refresh()


func on_resume() -> void:
	_refresh()


func _refresh() -> void:
	var keep: String = _selected.get("_slot", "")
	_selected = {}
	var rows: Array = []
	for meta in SimSave.list_slots():
		rows.append({
			"label": str(meta.get("label", meta["slot"])),
			"date": str(meta.get("date", "")),
			"side": SIDE_TITLES.get(meta.get("side", ""), str(meta.get("side", ""))),
			"saved_at": str(meta.get("saved_at", "")).replace("T", " "),
			"_slot": meta["slot"],
		})
	_table.set_rows(rows)
	for i in _table.rows.size():
		if _table.rows[i]["_slot"] == keep:
			_table._on_row_pressed(i)
	if rows.is_empty():
		_message.text = "No saved games yet."
	_update_buttons()


func _on_row(row: Dictionary) -> void:
	_selected = row
	_update_buttons()


func _update_buttons() -> void:
	var in_game := Session.has_game()
	var has_sel := not _selected.is_empty()
	_save_new.disabled = not in_game
	_save_over.disabled = not (in_game and has_sel)
	_load.disabled = not has_sel
	_delete.disabled = not has_sel
	_quit.disabled = not in_game
	_label_edit.editable = in_game


func _default_label() -> String:
	if not Session.has_game():
		return ""
	return "%s  %s" % [SIDE_TITLES.get(Session.human_side, Session.human_side), Session.state().date_string()]


func _new_slot_name() -> String:
	var taken: Array = []
	for meta in SimSave.list_slots():
		taken.append(meta["slot"])
	var base := "save_%d" % int(Time.get_unix_time_from_system())
	var slot := base
	var n := 1
	while slot in taken:
		slot = "%s_%d" % [base, n]
		n += 1
	return slot


func _label_text() -> String:
	var text := _label_edit.text.strip_edges()
	return text if text != "" else _default_label()


func _on_save_new() -> void:
	if not Session.has_game():
		return
	var slot := _new_slot_name()
	var label := _label_text()
	if Session.save_to_slot(slot, label):
		_message.text = "Saved '%s'." % label
		_label_edit.text = ""
	else:
		_message.text = "Could not save the game."
	_refresh_keeping(slot)


func _on_save_over() -> void:
	if not Session.has_game() or _selected.is_empty():
		return
	var slot: String = _selected["_slot"]
	var label: String = _label_edit.text.strip_edges()
	if label == "":
		label = str(_selected.get("label", _default_label()))
	if await ConfirmBox.ask(self, "Overwrite this save?", "'%s' will be replaced by the current game." % _selected.get("label", slot), "Overwrite", "Keep"):
		if Session.save_to_slot(slot, label):
			_message.text = "Saved over '%s'." % label
			_label_edit.text = ""
		else:
			_message.text = "Could not save the game."
		_refresh_keeping(slot)


func _on_load() -> void:
	if _selected.is_empty():
		return
	var slot: String = _selected["_slot"]
	if Session.has_game():
		if not await ConfirmBox.ask(self, "Load this save?", "The current game will be replaced by '%s'." % _selected.get("label", slot), "Load", "Cancel"):
			return
	if Session.load_from_slot(slot):
		Screens.reset(load(SPACEPORT))
	else:
		_message.text = "Could not load '%s'." % _selected.get("label", slot)


func _on_delete() -> void:
	if _selected.is_empty():
		return
	var slot: String = _selected["_slot"]
	if await ConfirmBox.ask(self, "Delete this save?", "'%s' will be removed permanently." % _selected.get("label", slot), "Delete", "Keep"):
		if SimSave.delete_slot(slot):
			_message.text = "Deleted '%s'." % _selected.get("label", slot)
		else:
			_message.text = "Could not delete the save."
		_selected = {}
		_refresh()


func _on_quit() -> void:
	if not Session.has_game():
		return
	if await ConfirmBox.ask(self, "Quit to the title screen?", "Unsaved progress in %s will be lost." % Session.state().date_string(), "Quit", "Stay"):
		Screens.reset(load(TITLE))


func _refresh_keeping(slot: String) -> void:
	var msg := _message.text
	_selected = {"_slot": slot}
	_refresh()
	_message.text = msg
