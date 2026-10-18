extends ScreenPanel
## Preferences: save slots (save, load, delete), the settings screen and quit to title.
## Works from the title screen with no game (only load, settings and back) and in-game.

const SPACEPORT := "res://scenes/spaceport/spaceport.tscn"
const TITLE := "res://scenes/ui/title_screen.tscn"
const SETTINGS := "res://scenes/ui/settings_screen.tscn"

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
	var slots := UiPanel.new("Saved games", "I013")
	slots.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(slots)
	_table = DataTable.new()
	_table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_table.set_columns([
		{"key": "label", "title": "Label", "stretch": 3},
		{"key": "date", "title": "Game date", "stretch": 1.5},
		{"key": "side", "title": "Side"},
		{"key": "saved_at", "title": "Saved", "stretch": 2},
	])
	_table.tooltip_text = "Your saved games. Click a column to sort; double-click a save to load it."
	_table.row_selected.connect(_on_row)
	_table.row_activated.connect(func(_row): _on_load())
	slots.body.add_child(_table)
	_message = Label.new()
	_message.theme_type_variation = "Dim"
	_message.clip_text = true
	_message.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	slots.body.add_child(_message)
	_load = slots.add_action("Load selected", "go", _on_load)
	_delete = slots.add_action("Delete selected", "caution", _on_delete)

	var save_panel := UiPanel.new("Save the current game", "I013")
	content.add_child(save_panel)
	var save_row := HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 12)
	save_panel.body.add_child(save_row)
	var l := Label.new()
	l.text = "LABEL"
	l.theme_type_variation = "Caps"
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	save_row.add_child(l)
	_label_edit = LineEdit.new()
	_label_edit.placeholder_text = "Name for a new save"
	_label_edit.max_length = 40
	_label_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_edit.text_submitted.connect(func(_t): _on_save_new())
	save_row.add_child(_label_edit)
	_save_new = save_panel.add_action("Save to new slot", "go", _on_save_new)
	_save_over = save_panel.add_action("Save over selected", "caution", _on_save_over)

	var settings := Button.new()
	settings.theme_type_variation = "Bar"
	settings.text = "SETTINGS"
	settings.tooltip_text = "Display, sound and playback settings"
	settings.custom_minimum_size = Vector2(170, 40)
	settings.pressed.connect(func(): Screens.push(load(SETTINGS)))
	footer.add_child(settings)
	_quit = Button.new()
	_quit.custom_minimum_size = Vector2(200, 40)
	_quit.pressed.connect(func():
		if not UiAction.is_blocked(_quit):
			_on_quit())
	footer.add_child(_quit)
	set_room("room_admin")
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
			"label": str(meta.get("label", meta["slot"])) + ("  (newer version)" if str(meta.get("unloadable", "")) != "" else ""),
			"_unloadable": str(meta.get("unloadable", "")),
			"date": str(meta.get("date", "")),
			"side": Sides.short(str(meta.get("side", ""))),
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
	var no_game := "No game in progress. Start or load a game first."
	var pick := "No saved games yet." if _table.rows.is_empty() else "Select a saved game in the list first."
	_action(_save_new, "Save to new slot", "go", "" if in_game else no_game,
		"Save the current game to a new slot, named by the label above.")
	_action(_save_over, "Save over selected", "caution", no_game if not in_game else ("" if has_sel else pick),
		"Replace the selected save with the current game.")
	var cant_load := str(_selected.get("_unloadable", "")) if has_sel else pick
	_action(_load, "Load selected", "go", cant_load, "Load the selected save.")
	_action(_delete, "Delete selected", "caution", "" if has_sel else pick, "Delete the selected save permanently.")
	_action(_quit, "Quit to title", "go", "" if in_game else no_game, "Leave this game and return to the title screen.")
	_label_edit.editable = in_game
	_label_edit.tooltip_text = "Name for a new save; empty uses the side and date." if in_game else no_game


## Style an action for its state: `kind` when `reason` is empty, else blocked with it.
func _action(b: Button, text: String, kind: String, reason: String, tip: String) -> void:
	# UiPanel freezes its bar buttons' styleboxes when it rounds their corners, so drop
	# those overrides before restyling and round them again afterwards.
	for state in ["normal", "hover", "pressed", "disabled"]:
		b.remove_theme_stylebox_override(state)
	UiAction.style(b, kind if reason == "" else "blocked", text, reason)
	if reason == "":
		b.tooltip_text = tip
	var panel := b.get_parent().get_parent().get_parent() if b.get_parent() != footer else null
	if panel is UiPanel:
		panel._round_bar()


func _default_label() -> String:
	if not Session.has_game():
		return ""
	return "%s  %s" % [Sides.short(Session.human_side), Session.state().date_string()]


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
