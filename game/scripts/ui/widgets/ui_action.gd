class_name UiAction
extends RefCounted
## Colour rules for actions (ui-style-guide section 6), usable on any Button.
##   go       green: proceed, launch, buy, recruit
##   caution  amber: the secondary or cautious choice (scrub, schedule, downgrade)
##   blocked  red: unavailable. The label says why and a click explains in full.
##   neutral  the plain bar style
## A blocked button is never just disabled: it stays enabled and shows the reason.


static func style(b: Button, kind: String, text: String, reason := "") -> void:
	# Drop any stylebox overrides left by an earlier style so the new variation shows.
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.remove_theme_stylebox_override(st)
	b.set_meta("blocked_reason", "")
	b.disabled = false
	match kind:
		"go":
			b.theme_type_variation = "Go"
		"caution":
			b.theme_type_variation = "Caution"
		"blocked":
			b.theme_type_variation = "Blocked"
			b.set_meta("blocked_reason", reason if reason != "" else "Not available")
		_:
			b.theme_type_variation = "Bar"
	if kind == "blocked":
		b.text = ("UNAVAILABLE: " + _short(reason)).to_upper() if reason != "" else text.to_upper()
		b.tooltip_text = reason
		if not b.has_meta("blocked_hooked"):
			b.set_meta("blocked_hooked", true)
			b.pressed.connect(func():
				var why: String = b.get_meta("blocked_reason", "")
				if why != "":
					ConfirmBox.notice(b, "Not available", why))
	else:
		b.text = text.to_upper()
		if b.tooltip_text == "" or b.tooltip_text == b.get_meta("last_reason", ""):
			b.tooltip_text = ""
	b.set_meta("last_reason", reason)
	if b.has_meta("bar_corners"):
		apply_corners(b)


## Square a bar button's corners except those recorded in its "bar_corners" meta
## (Vector2i(left, right) as 0/1), matching the panel's rounded bottom edge.
static func apply_corners(b: Button) -> void:
	# Out of the tree the theme is not resolved yet, so the variation's styleboxes would
	# read as the plain button style. Defer until the button is in the tree.
	if not b.is_inside_tree():
		if not b.is_connected("tree_entered", apply_corners.bind(b)):
			b.tree_entered.connect(apply_corners.bind(b), CONNECT_ONE_SHOT)
		return
	var corners: Vector2i = b.get_meta("bar_corners", Vector2i.ZERO)
	for state in ["normal", "hover", "pressed", "disabled"]:
		b.remove_theme_stylebox_override(state)
		var sb := b.get_theme_stylebox(state)
		if sb is StyleBoxFlat:
			var c := (sb as StyleBoxFlat).duplicate() as StyleBoxFlat
			c.set_corner_radius_all(0)
			c.corner_radius_bottom_left = 10 if corners.x == 1 else 0
			c.corner_radius_bottom_right = 10 if corners.y == 1 else 0
			b.add_theme_stylebox_override(state, c)


## Convenience: go when `reason` is empty, otherwise blocked with that reason.
static func go_or_blocked(b: Button, text: String, reason: String) -> void:
	style(b, "go" if reason == "" else "blocked", text, reason)


## True when a press should do nothing because the action is blocked.
static func is_blocked(b: Button) -> bool:
	return b.get_meta("blocked_reason", "") != ""


static func _short(reason: String) -> String:
	var s := reason.split(".")[0]
	return s if s.length() <= 38 else s.substr(0, 36) + "…"
