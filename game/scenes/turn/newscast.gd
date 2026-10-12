extends ScreenPanel
## Network News: the season card and this turn's newscast for the human side, with the
## budget drift, the card's effect in plain English and a button to pay off event damage.

var _date_card: Label
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
	var card := PanelContainer.new()
	card.theme_type_variation = "Card"
	content.add_child(card)
	var card_box := VBoxContainer.new()
	card_box.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(card_box)
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

	var body := PanelContainer.new()
	body.theme_type_variation = "Sunken"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(body)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
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
	lines.add_child(_damage_box)
	UiHelp.attach(body, "I001")

	var go := Button.new()
	go.text = "Continue"
	go.theme_type_variation = "Accent"
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
	_anchor.text = "Carter Walcrite reporting for the %s network" % TurnLogic.side_name(p.side)
	var raw := str(news.get("text", ""))
	_news.text = TurnLogic.resolve_placeholders(raw, news, p, state.year).capitalize() if raw != "" else "No news this season."
	_news.add_theme_color_override("font_color", TurnLogic.news_colour(int(news.get("color", 0))))
	var drift := int(news.get("budget_drift", 0))
	_budget.text = "Budget revised to %d MB (%+d MB this season)" % [p.budget, drift]
	var effect := TurnLogic.effect_line(news)
	_effect.text = "Effect: " + effect if effect != "" else ""
	_effect.visible = effect != ""
	_refresh_damage(p)


func _refresh_damage(p: SimPlayer) -> void:
	for c in _damage_box.get_children():
		c.queue_free()
	for prog in p.owned_programs():
		if prog.damage == 0:
			continue
		var b := Button.new()
		b.text = "Pay %d MB to clear the damage to %s" % [prog.damage_cost, prog.display_name().capitalize()]
		b.theme_type_variation = "Danger"
		b.disabled = p.cash < prog.damage_cost
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		b.pressed.connect(_on_pay.bind(prog))
		_damage_box.add_child(b)


func _on_pay(prog: SimProgram) -> void:
	if SimEvents.pay_damage(Session.me(), prog):
		Session.notify_change()
		_refresh()
