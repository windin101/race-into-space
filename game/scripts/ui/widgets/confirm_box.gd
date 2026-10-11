class_name ConfirmBox
extends ConfirmationDialog
## Modal yes/no question. Usage:
##   if await ConfirmBox.ask(self, "Scrub mission?", "This costs 3 prestige."):


static func ask(host: Node, title: String, text: String, ok_label := "Yes", cancel_label := "No") -> bool:
	var box := ConfirmBox.new()
	box.title = title
	box.dialog_text = text
	box.ok_button_text = ok_label
	box.cancel_button_text = cancel_label
	box.min_size = Vector2i(420, 160)
	host.add_child(box)
	box.popup_centered()
	var result: Array = [false]
	box.confirmed.connect(func(): result[0] = true)
	await box.visibility_changed
	if box.visible:
		await box.visibility_changed
	box.queue_free()
	return result[0]


## One-button notice.
static func notice(host: Node, title: String, text: String) -> void:
	var box := AcceptDialog.new()
	box.title = title
	box.dialog_text = text
	box.min_size = Vector2i(420, 160)
	host.add_child(box)
	box.popup_centered()
	await box.visibility_changed
	if box.visible:
		await box.visibility_changed
	box.queue_free()
