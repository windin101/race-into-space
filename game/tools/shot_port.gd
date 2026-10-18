extends SceneTree
## Screenshots a side's spaceport fully built and fresh, for checking art in place.
##   SIDE=cwth OUT=/abs/dir godot --path game -s res://tools/shot_port.gd
## Writes <side>_full.png (every program owned, three pads built, an astronaut) and
## <side>_fresh.png (a new game). Needs a display (not --headless).
var frames := 0
var idx := 0
var side := "usa"


func _init() -> void:
	side = OS.get_environment("SIDE") if OS.get_environment("SIDE") != "" else "usa"
	process_frame.connect(_tick)


func _start(full: bool) -> void:
	var lineup := ["usa", "ussr"] if side != "cwth" else ["cwth", "usa"]
	root.get_node("Session").new_game(7, {"human_side": side, "sides": lineup})
	UiTheme.apply(self, side)
	var me = root.get_node("Session").me()
	if full:
		for group in me.programs:
			for prog in me.programs[group]:
				if prog != null:
					prog.owned = true
		me.astronauts.append(SimAstronaut.new())
		for i in 3:
			me.pads[i] = 0
	root.get_node("Screens").push(load("res://scenes/spaceport/spaceport.tscn").instantiate())


func _tick() -> void:
	frames += 1
	if frames == 5:
		root.size = Vector2i(1920, 1080)
		_start(idx == 0)
	elif frames == 40:
		root.get_texture().get_image().save_png(OS.get_environment("OUT") + "/%s_%s.png" % [side, "full" if idx == 0 else "fresh"])
		root.get_node("Screens").pop()
		idx += 1
		if idx >= 2:
			quit()
		else:
			frames = 4
