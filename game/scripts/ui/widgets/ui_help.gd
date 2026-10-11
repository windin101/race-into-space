class_name UiHelp
extends RefCounted
## Tooltips from the help table (text/help.json). Upstream lines carry layout
## directives (";xxxx", "%NN:N", ".NNN") that are stripped here.

static var _index: Dictionary = {}


static func text_for(code: String) -> String:
	if _index.is_empty():
		for entry in GameData.text.get("help", {}).get("help", []):
			_index[entry["code"]] = entry["lines"]
	var lines: Array = _index.get(code, [])
	var out: PackedStringArray = []
	for raw in lines:
		var line: String = str(raw).strip_edges()
		if line.begins_with(";") or line.begins_with("%") or line.begins_with("."):
			continue
		if line.is_empty():
			continue
		out.append(line.capitalize() if line == line.to_upper() else line)
	return "\n".join(out)


## Attach help text as the control's tooltip.
static func attach(control: Control, code: String) -> void:
	var t := text_for(code)
	if t != "":
		control.tooltip_text = t
