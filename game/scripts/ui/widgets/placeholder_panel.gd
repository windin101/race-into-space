extends ScreenPanel
## Stand-in for a building screen that Phase 4 has not built yet.

var building_id := ""


func setup(args: Dictionary) -> void:
	building_id = args.get("id", "")
	title = args.get("title", "Building")
	var l := Label.new()
	l.theme_type_variation = "Dim"
	l.text = "The %s screen arrives in Phase 4." % title.to_lower()
	content.add_child(l)
	if args.has("help"):
		var h := Label.new()
		h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		h.text = UiHelp.text_for(args["help"])
		content.add_child(h)
