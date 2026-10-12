extends GdUnitTestSuite
## ConfirmBox.ask must report Yes when the OK button is really clicked. AcceptDialog hides
## itself before it emits `confirmed`, which once made every prompt answer No.


func _ask_and_press(use_ok: bool) -> bool:
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(host)
	var answer: Array = [null]
	_run_ask(host, answer)
	for i in 3:
		await await_idle_frame()
	var box: Window = null
	for c in host.get_children():
		if c is Window:
			box = c
	assert_object(box).is_not_null()
	# Press the dialog's own button: AcceptDialog then hides and emits exactly as a click would.
	var button: Button = box.get_ok_button() if use_ok else box.get_cancel_button()
	button.pressed.emit()
	for i in 4:
		await await_idle_frame()
	host.queue_free()
	assert_bool(answer[0] != null).override_failure_message("ask() never returned").is_true()
	return answer[0] == true


func _run_ask(host: Control, answer: Array) -> void:
	answer[0] = await ConfirmBox.ask(host, "Question?", "Body")


func test_clicking_yes_returns_true() -> void:
	assert_bool(await _ask_and_press(true)).is_true()


func test_clicking_no_returns_false() -> void:
	assert_bool(await _ask_and_press(false)).is_false()
