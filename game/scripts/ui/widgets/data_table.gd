class_name DataTable
extends VBoxContainer
## Sortable data table. Columns are declared once; rows are Dictionaries keyed by column.
##
##   table.set_columns([{"key": "name", "title": "Name", "stretch": 2},
##                      {"key": "safety", "title": "Safety", "numeric": true, "suffix": "%"}])
##   table.set_rows(rows)
##   table.row_selected.connect(func(row): ...)

signal row_selected(row: Dictionary)
signal row_activated(row: Dictionary)

const ROW_MIN_HEIGHT := 30.0

var columns: Array = []
var rows: Array = []
var sort_key := ""
var sort_descending := false
var selected_index := -1

var _header: HBoxContainer
var _scroll: ScrollContainer
var _body: VBoxContainer
var _row_nodes: Array = []


func _init() -> void:
	add_theme_constant_override("separation", 0)
	_header = HBoxContainer.new()
	_header.add_theme_constant_override("separation", 2)
	add_child(_header)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 1)
	_scroll.add_child(_body)


func set_columns(cols: Array) -> void:
	columns = cols
	for c in _header.get_children():
		c.queue_free()
	for col in columns:
		var b := Button.new()
		b.text = col.get("title", col["key"])
		b.theme_type_variation = "Flat"
		b.alignment = HORIZONTAL_ALIGNMENT_RIGHT if col.get("numeric", false) else HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_stretch_ratio = float(col.get("stretch", 1.0))
		b.pressed.connect(_on_header_pressed.bind(col["key"]))
		_header.add_child(b)
	_refresh_header_titles()


func set_rows(p_rows: Array) -> void:
	rows = p_rows.duplicate()
	selected_index = -1
	if sort_key != "":
		_sort()
	_rebuild()


func sort_by(key: String, descending := false) -> void:
	sort_key = key
	sort_descending = descending
	_sort()
	_rebuild()
	_refresh_header_titles()


## Highlight a row by index without emitting signals (used to reflect state on open).
func select_index(i: int) -> void:
	selected_index = i if i >= 0 and i < rows.size() else -1
	_paint_selection()


func selected_row() -> Dictionary:
	return rows[selected_index] if selected_index >= 0 and selected_index < rows.size() else {}


func _on_header_pressed(key: String) -> void:
	if sort_key == key:
		sort_descending = not sort_descending
	else:
		sort_key = key
		sort_descending = false
	_sort()
	_rebuild()
	_refresh_header_titles()


func _sort() -> void:
	var key := sort_key
	var desc := sort_descending
	rows.sort_custom(func(a, b):
		var va = a.get(key)
		var vb = b.get(key)
		if typeof(va) == TYPE_STRING and typeof(vb) == TYPE_STRING:
			va = va.to_lower()
			vb = vb.to_lower()
		if va == vb:
			return false
		var less: bool = va < vb
		return not less if desc else less)


func _refresh_header_titles() -> void:
	for i in columns.size():
		var col: Dictionary = columns[i]
		var b: Button = _header.get_child(i)
		var title: String = col.get("title", col["key"])
		if col["key"] == sort_key:
			title += "  ▼" if sort_descending else "  ▲"
		b.text = title


func _rebuild() -> void:
	for n in _row_nodes:
		n.queue_free()
	_row_nodes.clear()
	for i in rows.size():
		var row: Dictionary = rows[i]
		var line := Button.new()
		line.theme_type_variation = "Flat"
		line.custom_minimum_size.y = ROW_MIN_HEIGHT
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.pressed.connect(_on_row_pressed.bind(i))
		var h := HBoxContainer.new()
		h.set_anchors_preset(Control.PRESET_FULL_RECT)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_theme_constant_override("separation", 2)
		for col in columns:
			var l := Label.new()
			l.text = _format(row.get(col["key"]), col)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			l.size_flags_stretch_ratio = float(col.get("stretch", 1.0))
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			l.clip_text = true
			l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if col.get("numeric", false) else HORIZONTAL_ALIGNMENT_LEFT
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			if col.has("color"):
				var c = col["color"]
				var colour: Color = c.call(row) if c is Callable else c
				l.set_meta("cell_color", colour)
				l.add_theme_color_override("font_color", colour)
			h.add_child(l)
		line.add_child(h)
		_body.add_child(line)
		_row_nodes.append(line)


func _format(value, col: Dictionary) -> String:
	if value == null:
		return "-"
	if col.has("format") and col["format"] is Callable:
		return col["format"].call(value)
	var s := str(value)
	if col.has("prefix"):
		s = str(col["prefix"]) + s
	if col.has("suffix"):
		s += str(col["suffix"])
	return s


func _on_row_pressed(i: int) -> void:
	if selected_index == i:
		row_activated.emit(rows[i])
		return
	selected_index = i
	_paint_selection()
	row_selected.emit(rows[i])


## Highlight the selected row. Its cells drop their per-column colours so the text stays
## readable on the accent fill; the other rows get their colours back.
func _paint_selection() -> void:
	for j in _row_nodes.size():
		var line: Control = _row_nodes[j]
		line.theme_type_variation = "Accent" if j == selected_index else "Flat"
		for l in line.find_children("*", "Label", true, false):
			if j == selected_index:
				l.remove_theme_color_override("font_color")
			elif l.has_meta("cell_color"):
				l.add_theme_color_override("font_color", l.get_meta("cell_color"))
