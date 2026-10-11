class_name NewsFlash
extends PanelContainer
## Overlay banner for firsts, failures and the mission verdict. Slides in, holds, slides
## out; show() returns after the banner has gone.

var _kicker: Label
var _headline: Label
var _body: Label


func _init() -> void:
	theme_type_variation = "Card"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	add_child(v)
	_kicker = Label.new()
	_kicker.theme_type_variation = "Small"
	v.add_child(_kicker)
	_headline = Label.new()
	_headline.theme_type_variation = "Heading"
	_headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_headline)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_body)


## Show a banner for `hold` seconds (already divided by speed by the caller).
func flash(kicker: String, headline: String, body: String, color: Color, hold: float) -> void:
	_kicker.text = kicker
	_kicker.add_theme_color_override("font_color", color)
	_headline.text = headline
	_headline.add_theme_color_override("font_color", color)
	_body.text = body
	_body.visible = body != ""
	visible = true
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.15)
	tw.tween_interval(maxf(hold, 0.05))
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	await tw.finished
	visible = false


func hide_now() -> void:
	visible = false
