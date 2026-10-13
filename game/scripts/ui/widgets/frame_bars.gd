class_name FrameBars
extends RefCounted
## The fixed frame (ui-style-guide section 2): a 48 px top bar (back arrow, breadcrumb of
## at most two levels, prestige and date) and a 56 px bottom resource bar (money with its
## per-season change, pads, crews, review index; each chip opens the screen that manages
## it) with one context action at the right. Built here so ScreenPanel, the spaceport and
## anything else full-screen share them.

const BUDGET := "res://scenes/admin/budget_office.tscn"
const COMPLEX := "res://scenes/astronauts/astronaut_complex.tscn"
const CONTROL := "res://scenes/mission_control/mission_control.tscn"
const BAR_BG := Color("070e1b")


static func bar_style(top: bool) -> StyleBoxFlat:
	var sb := UiTheme.flat(Color(BAR_BG, 0.94), Color.TRANSPARENT, 0, 0)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.border_color = UiPalette.BORDER_SOFT
	if top:
		sb.border_width_bottom = 1
	else:
		sb.border_width_top = 1
	return sb


## Top bar. Returns {node, crumbs (HBoxContainer), right (HBoxContainer), back (Button)}.
static func make_top(on_back: Callable) -> Dictionary:
	var bar := PanelContainer.new()
	bar.custom_minimum_size.y = 48
	bar.add_theme_stylebox_override("panel", bar_style(true))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	bar.add_child(row)
	var back := Button.new()
	back.text = "◀"
	back.theme_type_variation = "Flat"
	back.tooltip_text = "Back  (Esc, right-click or mouse back)"
	back.custom_minimum_size = Vector2(40, 36)
	back.pressed.connect(on_back)
	row.add_child(back)
	var crumbs := HBoxContainer.new()
	crumbs.add_theme_constant_override("separation", 6)
	crumbs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(crumbs)
	var right := HBoxContainer.new()
	right.add_theme_constant_override("separation", 18)
	row.add_child(right)
	return {"node": bar, "crumbs": crumbs, "right": right, "back": back}


## Fill the breadcrumb from the screen stack: the screen below (clickable) and this one.
static func fill_crumbs(crumbs: HBoxContainer, own_title: String, owner: Control) -> void:
	for c in crumbs.get_children():
		c.queue_free()
	var stack: Array = Screens.stack
	var idx := stack.find(owner)
	var parent_title := ""
	if idx > 0:
		parent_title = title_of(stack[idx - 1])
	if parent_title != "":
		var p := Button.new()
		p.text = parent_title.to_upper()
		p.theme_type_variation = "Flat"
		p.add_theme_font_override("font", UiTheme.font(UiTheme.FONT_LABEL))
		p.add_theme_font_size_override("font_size", UiTheme.SIZE_SMALL)
		p.add_theme_color_override("font_color", UiPalette.TEXT_DIM)
		p.tooltip_text = "Back to " + parent_title
		p.pressed.connect(func(): Screens.pop())
		crumbs.add_child(p)
		var sep := Label.new()
		sep.text = "›"
		sep.theme_type_variation = "Dim"
		crumbs.add_child(sep)
	var me := Label.new()
	me.text = own_title.to_upper()
	me.theme_type_variation = "CapsBright"
	me.add_theme_font_size_override("font_size", 18)
	me.clip_text = true
	me.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	me.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crumbs.add_child(me)


static func title_of(screen: Control) -> String:
	if screen == null:
		return ""
	var t = screen.get("title")
	if t is String and t != "":
		return t
	var n := String(screen.name).to_lower()
	if "spaceport" in n or screen.has_method("_on_end_turn"):
		return "Spaceport"
	return ""


## Prestige (gold star) and date on the right of the top bar; the rival's prestige too
## when `with_rival`.
static func fill_top_right(right: HBoxContainer, with_rival := false) -> void:
	for c in right.get_children():
		c.queue_free()
	if not Session.has_game():
		return
	var state := Session.state()
	var me := Session.me()
	var star := StatChip.new("star", str(me.prestige_total), "Prestige")
	star.set_value(str(me.prestige_total), false, UiPalette.GOLD)
	right.add_child(star)
	if with_rival:
		for rival in state.rivals(me.index):
			var rs := StatChip.new("star", str(rival.prestige_total), "%s prestige" % Sides.name(rival.side))
			rs.set_value(str(rival.prestige_total), false, UiPalette.accent(rival.side))
			right.add_child(rs)
	var date := Label.new()
	date.text = state.date_string().to_upper()
	date.theme_type_variation = "CapsBright"
	date.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right.add_child(date)


## Bottom bar. Returns {node, chips (HBoxContainer), action (HBoxContainer)}. Put the one
## context action into `action` (ScreenPanel's `footer` is that container).
static func make_bottom() -> Dictionary:
	var bar := PanelContainer.new()
	bar.custom_minimum_size.y = 56
	bar.add_theme_stylebox_override("panel", bar_style(false))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	bar.add_child(row)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 10)
	chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(chips)
	var action := HBoxContainer.new()
	action.alignment = BoxContainer.ALIGNMENT_END
	action.add_theme_constant_override("separation", 10)
	row.add_child(action)
	return {"node": bar, "chips": chips, "action": action}


static func fill_chips(chips: HBoxContainer) -> void:
	for c in chips.get_children():
		c.queue_free()
	if not Session.has_game():
		return
	var state := Session.state()
	var p := Session.me()
	var drift := int(p.last_news.get("budget_drift", 0))
	var money := StatChip.new("money", "", "Cash on hand, and this season's budget change. Opens the Budget Office.")
	money.set_value("%d MB  (%+d)" % [p.cash, drift], false, UiPalette.TEXT)
	_link(money, BUDGET, {"id": "budget", "title": "Budget Office", "help": "I007"})
	chips.add_child(money)
	var budget := StatChip.new("cost", "Budget %d" % p.budget, "Budget for the season")
	_link(budget, BUDGET, {"id": "budget", "title": "Budget Office", "help": "I007"})
	chips.add_child(budget)
	var usable := 0
	for i in 3:
		if p.pad_usable(i):
			usable += 1
	var pads := StatChip.new("pad", "Pads %d/3" % usable, "Launch pads ready to fly. Opens Mission Control.")
	_link(pads, CONTROL, {})
	chips.add_child(pads)
	var active := 0
	var alive := 0
	for a in p.astronauts:
		if a.is_alive():
			alive += 1
		if a.status == SimAstronaut.Status.ACTIVE:
			active += 1
	var crew := StatChip.new("crew", "Crew %d/%d" % [active, alive],
		"Active astronauts of those alive. Opens the Astronaut Complex.")
	_link(crew, COMPLEX, {"id": "complex", "title": "Astronaut Complex", "help": "I020"})
	chips.add_child(crew)
	var review := StatChip.new("review", "", "Review index, lower is better; reviewed every spring.")
	review.set_value("Review %d" % p.review_index, p.review_index >= 12, UiPalette.TEXT)
	_link(review, BUDGET, {"id": "budget", "title": "Budget Office", "help": "I007"})
	chips.add_child(review)


static func _link(chip: StatChip, scene: String, args: Dictionary) -> void:
	chip.set_clickable(true)
	chip.pressed.connect(func():
		var top: Control = Screens.current()
		if top != null and top.scene_file_path == scene:
			return
		Screens.push(load(scene), args))
