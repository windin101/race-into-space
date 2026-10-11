extends GdUnitTestSuite
## Opens every scene under res://scenes with a live game a few seasons in, calls setup()
## with default arguments, lets it run a frame and closes it. Catches scenes that crash on
## open or leave orphans.

const SETUP_ARGS := {
	"launch_pad": {"pad": 0, "title": "Launch Pad 1"},
	"launch_results": {"report": {}},
	"annual_review": {},
	"end_game": {"report": {}},
}
const SKIP := ["main"]


func before() -> void:
	Session.new_game(11, {"human_side": "usa"})
	var drivers := [SimDriver.new(0), SimDriver.new(1)]
	for t in 8:
		for d in drivers:
			d.act(Session.game)
		Session.game.end_turn()
	Session.notify_change()


func _discover(dir_path: String) -> Array:
	var out: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full := dir_path.path_join(entry)
		if dir.current_is_dir():
			out.append_array(_discover(full))
		elif entry.ends_with(".tscn"):
			out.append(full)
		entry = dir.get_next()
	return out


func test_every_scene_opens_with_a_live_game() -> void:
	var scenes := _discover("res://scenes")
	assert_array(scenes).is_not_empty()
	for path in scenes:
		var scene_name: String = path.get_file().get_basename()
		if scene_name in SKIP:
			continue
		var packed := load(path)
		assert_object(packed).override_failure_message("cannot load " + path).is_not_null()
		var node: Node = packed.instantiate()
		add_child(node)
		if node.has_method("setup"):
			node.call("setup", SETUP_ARGS.get(scene_name, {}))
		await await_idle_frame()
		if node.has_method("on_resume"):
			node.call("on_resume")
		await await_idle_frame()
		node.queue_free()
		await await_idle_frame()
