extends CanvasLayer
## Autoload "Screens": hub-and-spoke navigation with a back stack.
##
## A screen is any Control scene. push() instantiates it on top, pop() returns to the
## previous one, go_home() clears everything down to the hub. Screens may define
## `func setup(args: Dictionary)` to receive arguments and `func on_resume()` when a
## screen above them closes. Escape pops unless the top screen defines
## `func handles_back() -> bool` and returns true.

signal screen_changed(top: Control)

const FADE_SECONDS := 0.12

var stack: Array[Control] = []
var _root: Control
var _busy := false


func _ready() -> void:
	layer = 1
	_root = Control.new()
	_root.name = "ScreenRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)


func current() -> Control:
	return stack.back() if not stack.is_empty() else null


func depth() -> int:
	return stack.size()


## Instantiate a scene (or add a ready Control) on top of the stack.
func push(screen, args: Dictionary = {}) -> Control:
	var node := _instantiate(screen)
	if node == null:
		return null
	var below := current()
	if below != null:
		below.visible = false
		below.process_mode = Node.PROCESS_MODE_DISABLED
	stack.append(node)
	_root.add_child(node)
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	if node.has_method("setup"):
		node.call("setup", args)
	_fade_in(node)
	if stack.size() > 1:
		Sound.sfx("click", -6.0)
	screen_changed.emit(node)
	return node


## Replace the top screen (no back entry for it).
func replace(screen, args: Dictionary = {}) -> Control:
	if not stack.is_empty():
		var top: Control = stack.pop_back()
		top.queue_free()
	return push(screen, args)


func pop() -> void:
	if stack.size() <= 1:
		return
	var top: Control = stack.pop_back()
	top.queue_free()
	var below := current()
	below.visible = true
	below.process_mode = Node.PROCESS_MODE_INHERIT
	if below.has_method("on_resume"):
		below.call("on_resume")
	_fade_in(below)
	Sound.sfx("back", -8.0)
	screen_changed.emit(below)


## Close everything above the first screen.
func go_home() -> void:
	while stack.size() > 1:
		var top: Control = stack.pop_back()
		top.queue_free()
	var home := current()
	if home != null:
		home.visible = true
		home.process_mode = Node.PROCESS_MODE_INHERIT
		if home.has_method("on_resume"):
			home.call("on_resume")
		_fade_in(home)
		screen_changed.emit(home)


## Clear the stack and start again with a new base screen (title to spaceport, etc.).
func reset(screen, args: Dictionary = {}) -> Control:
	for s in stack:
		s.queue_free()
	stack.clear()
	return push(screen, args)


func _instantiate(screen) -> Control:
	if screen is PackedScene:
		return screen.instantiate() as Control
	if screen is Control:
		return screen
	if screen is String:
		var packed := load(screen)
		if packed is PackedScene:
			return packed.instantiate() as Control
	push_error("Screens: cannot instantiate %s" % str(screen))
	return null


func _fade_in(node: Control) -> void:
	node.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(node, "modulate:a", 1.0, FADE_SECONDS)


func _unhandled_input(event: InputEvent) -> void:
	# Back is everywhere (ui-style-guide section 2): Esc, a right-click on empty space,
	# and the mouse's back button all go back one screen.
	var back := event.is_action_pressed("ui_cancel")
	if event is InputEventMouseButton and event.pressed:
		back = back or event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_XBUTTON1
	if back:
		var top := current()
		if top != null and top.has_method("handles_back") and top.call("handles_back"):
			return
		if stack.size() > 1:
			pop()
			get_viewport().set_input_as_handled()
