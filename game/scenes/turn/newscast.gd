extends ScreenPanel
## Network News, on the studio backdrop: the anchor as a portrait tile beside the season
## card, then this turn's newscast for the human side, with the budget drift, the card's
## effect in plain English and a button to pay off event damage.

const ANCHOR := "Carter Walcrite"   ## fallback; each side names its own newsreader in data/sides.json
const CASE_BG := Color("0a1424")

var _date_card: Label
var _anchor_tile: Control
var _anchor_side := "usa"
var _anchor: Label
var _news: Label
var _budget: Label
var _effect: Label
var _damage_box: VBoxContainer


func _init() -> void:
	super()
	title = "Network News"
	show_back = false


func _ready() -> void:
	super()
	# The anchor's portrait tile beside the date card.
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	content.add_child(top)
	var anchor_panel := UiPanel.new("Anchor")
	anchor_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	top.add_child(anchor_panel)
	_anchor_tile = Control.new()
	_anchor_tile.custom_minimum_size = Vector2(170, 204)
	_anchor_tile.tooltip_text = _anchor_name()
	_anchor_tile.draw.connect(_draw_anchor)
	anchor_panel.body.add_child(_anchor_tile)
	var card := UiPanel.new("Network news", "I001")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(card)
	var card_box := card.body
	card_box.alignment = BoxContainer.ALIGNMENT_CENTER
	card_box.add_theme_constant_override("separation", 6)
	var banner := Label.new()
	banner.theme_type_variation = "Heading"
	banner.add_theme_color_override("font_color", UiPalette.GOLD)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.text = "NETWORK NEWS"
	card_box.add_child(banner)
	_date_card = Label.new()
	_date_card.theme_type_variation = "Title"
	_date_card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_date_card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_box.add_child(_date_card)
	_anchor = Label.new()
	_anchor.theme_type_variation = "Dim"
	_anchor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_anchor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_box.add_child(_anchor)

	# Sized to the story, not the screen, so the studio shows beneath it.
	var body := UiPanel.new("This season", "I001")
	content.add_child(body)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = 300
	body.body.add_child(scroll)
	var lines := VBoxContainer.new()
	lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lines.add_theme_constant_override("separation", 12)
	scroll.add_child(lines)
	_news = Label.new()
	_news.theme_type_variation = "Subheading"
	_news.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lines.add_child(_news)
	_budget = Label.new()
	_budget.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lines.add_child(_budget)
	_effect = Label.new()
	_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lines.add_child(_effect)
	_damage_box = VBoxContainer.new()
	_damage_box.add_theme_constant_override("separation", 8)
	lines.add_child(_damage_box)

	var go := Button.new()
	go.custom_minimum_size = Vector2(170, 40)
	UiAction.style(go, "go", "Continue")
	go.tooltip_text = "On to the spaceport"
	go.pressed.connect(func(): Screens.pop())
	footer.add_child(go)
	_refresh()


func setup(_args: Dictionary) -> void:
	_refresh()


func on_resume() -> void:
	_refresh()


func _refresh() -> void:
	if not Session.has_game():
		_date_card.text = "No game"
		return
	var state := Session.state()
	var p := Session.me()
	var news: Dictionary = p.last_news
	set_backdrop("newscast_%s" % p.side)
	_date_card.text = state.date_string()
	_anchor.text = "%s reporting for the %s network" % [_anchor_name(), TurnLogic.side_name(p.side)]
	_anchor_side = p.side
	_anchor_tile.queue_redraw()
	var raw := str(news.get("text", ""))
	_news.text = TurnLogic.resolve_placeholders(raw, news, p, state.year).capitalize() if raw != "" else "No news this season."
	_news.add_theme_color_override("font_color", TurnLogic.news_colour(int(news.get("color", 0))))
	var drift := int(news.get("budget_drift", 0))
	_budget.text = "Budget revised to %d MB (%+d MB this season)" % [p.budget, drift]
	var effect := TurnLogic.effect_line(news)
	_effect.text = "Effect: " + effect if effect != "" else ""
	_effect.visible = effect != ""
	_refresh_damage(p)


func _draw_anchor() -> void:
	var size := _anchor_tile.size
	_anchor_tile.draw_rect(Rect2(Vector2.ZERO, size), CASE_BG)
	PortraitArt.paint(_anchor_tile, Rect2(Vector2.ZERO, size), _anchor_name(), false, _anchor_side)
	_anchor_tile.draw_rect(Rect2(0, size.y - 26, size.x, 26), Color(0, 0, 0, 0.6))
	_anchor_tile.draw_string(get_theme_default_font(), Vector2(0, size.y - 8), _anchor_name().to_upper(), HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTheme.SIZE_SMALL, UiPalette.GOLD)


func _refresh_damage(p: SimPlayer) -> void:
	for c in _damage_box.get_children():
		c.queue_free()
	for prog in p.owned_programs():
		if prog.damage == 0:
			continue
		var b := Button.new()
		var label := "Pay %d MB to clear the damage to %s" % [prog.damage_cost, prog.display_name().capitalize()]
		var reason := "" if p.cash >= prog.damage_cost else "Not enough cash: clearing the damage costs %d MB and you have %d MB." % [prog.damage_cost, p.cash]
		UiAction.go_or_blocked(b, label, reason)
		if reason == "":
			b.tooltip_text = "Repair the event damage now; otherwise it lowers this hardware's safety on its next mission"
		b.custom_minimum_size.y = 40
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		b.pressed.connect(func():
			if not UiAction.is_blocked(b):
				_on_pay(prog))
		_damage_box.add_child(b)


func _on_pay(prog: SimProgram) -> void:
	if SimEvents.pay_damage(Session.me(), prog):
		Session.notify_change()
		_refresh()


func _anchor_name() -> String:
	var side := Session.human_side if Session.has_game() else _anchor_side
	return str(Sides.field(side, "anchor", ANCHOR))
