class_name StoryCard
extends Control
## A story beat (ui-style-guide section 7): a centred 900x560 card with the illustration
## filling the top two-thirds, tinted to the side, a title banner in caps with the side
## emblem, a short paragraph and a Proceed bar. Modal; one at a time.
##
##   await StoryCard.show_card(self, "Sputnik is in orbit", body_text, texture, "ussr")

signal closed


static func show_card(host: Node, title: String, text: String, picture: Texture2D, side: String) -> void:
	var card := StoryCard.new()
	card._build(title, text, picture, side)
	# Its own layer above the screen stack (Screens is CanvasLayer 1), so the card is seen
	# and clickable whatever screen is showing.
	var layer := CanvasLayer.new()
	layer.layer = 50
	layer.add_child(card)
	host.get_tree().root.add_child(layer)
	await card.closed
	layer.queue_free()


func _build(title: String, text: String, picture: Texture2D, side: String) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.get_theme(side)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var panel := UiPanel.new()
	panel.hide_title()
	panel.custom_minimum_size = Vector2(900, 560)
	centre.add_child(panel)
	var banner_row := HBoxContainer.new()
	panel.body.add_child(banner_row)
	var banner := Label.new()
	banner.theme_type_variation = "Heading"
	banner.add_theme_color_override("font_color", UiPalette.GOLD)
	banner.text = title.to_upper()
	banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner_row.add_child(banner)
	var emblem := TextureRect.new()
	emblem.texture = ArtAssets.icon("emblem_" + side)
	emblem.custom_minimum_size = Vector2(64, 64)
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	banner_row.add_child(emblem)
	if picture != null:
		var pic := TextureRect.new()
		pic.texture = picture
		pic.custom_minimum_size = Vector2(0, 300)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pic.clip_contents = true
		var mat := ShaderMaterial.new()
		mat.shader = load("res://scripts/ui/monotone.gdshader")
		mat.set_shader_parameter("tint", UiPalette.ROOM_TINT_USA if side == "usa" else UiPalette.ROOM_TINT_USSR)
		mat.set_shader_parameter("strength", 0.55)
		mat.set_shader_parameter("brightness", 0.85)
		pic.material = mat
		panel.body.add_child(pic)
	var body := Label.new()
	body.text = text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 860
	panel.body.add_child(body)
	var go := panel.add_action("Proceed", "go", func(): closed.emit())
	go.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		closed.emit()
