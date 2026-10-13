class_name UiAction
extends RefCounted
## Colour rules for actions (ui-style-guide section 6), usable on any Button.
##   go       green: proceed, launch, buy, recruit
##   caution  amber: the secondary or cautious choice (scrub, schedule, downgrade)
##   blocked  red: unavailable. The label says why and a click explains in full.
##   neutral  the plain bar style
## A blocked button is never just disabled: it stays enabled and shows the reason.


static func style(b: Button, kind: String, text: String, reason := "") -> void:
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


## Convenience: go when `reason` is empty, otherwise blocked with that reason.
static func go_or_blocked(b: Button, text: String, reason: String) -> void:
	style(b, "go" if reason == "" else "blocked", text, reason)


## True when a press should do nothing because the action is blocked.
static func is_blocked(b: Button) -> bool:
	return b.get_meta("blocked_reason", "") != ""


static func _short(reason: String) -> String:
	var s := reason.split(".")[0]
	return s if s.length() <= 38 else s.substr(0, 36) + "…"
