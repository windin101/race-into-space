extends Control
## Entry scene. Placeholder until the title screen exists.


func _ready() -> void:
	var win := get_window()
	print("Race Into Space: viewport %s, window %s, scale %.2f" % [
		win.content_scale_size, win.size, win.content_scale_factor])
