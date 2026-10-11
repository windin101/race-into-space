extends GdUnitTestSuite
## Plays twenty seasons with scripted drivers on both sides and, after every season,
## opens the turn screens with the real report and every building screen with the live
## state. Any script error in a screen fails the run; this is the automated stand-in for
## "a human can play a full game without console errors".

const TURN_SCENES := {
	"res://scenes/turn/launch_results.tscn": "report",
	"res://scenes/turn/newscast.tscn": "",
	"res://scenes/turn/annual_review.tscn": "review",
}
const HUB_SCENES := [
	"res://scenes/spaceport/spaceport.tscn",
	"res://scenes/admin/administration.tscn",
	"res://scenes/admin/budget_office.tscn",
	"res://scenes/admin/hardware_purchase.tscn",
	"res://scenes/admin/future_missions.tscn",
	"res://scenes/admin/recruiting.tscn",
	"res://scenes/admin/preferences.tscn",
	"res://scenes/research/research.tscn",
	"res://scenes/programs/program_office.tscn",
	"res://scenes/vab/vehicle_assembly.tscn",
	"res://scenes/mission_control/mission_control.tscn",
	"res://scenes/astronauts/astronaut_complex.tscn",
	"res://scenes/astronauts/training.tscn",
	"res://scenes/intel/intelligence.tscn",
	"res://scenes/museum/museum.tscn",
]


func test_twenty_seasons_through_every_screen() -> void:
	Session.new_game(1973, {"human_side": "ussr", "level_ussr": 1})
	var drivers := [SimDriver.new(0), SimDriver.new(1)]
	var seasons_with_launches := 0
	for season in 20:
		for d in drivers:
			d.act(Session.game)
		var report := Session.game.end_turn()
		Session.notify_change()
		if not report.get("launches", []).is_empty():
			seasons_with_launches += 1
		for path in TURN_SCENES:
			var key: String = TURN_SCENES[path]
			var args := {}
			if key == "report":
				args = {"report": report}
			elif key == "review" and not Session.me().reviews.is_empty():
				args = {"review": Session.me().reviews.back()}
			await _open(path, args)
		if season % 4 == 3:
			for path in HUB_SCENES:
				await _open(path, {"pad": 0, "title": "Launch Pad 1"} if path.ends_with("launch_pad.tscn") else {})
			for pad in 3:
				await _open("res://scenes/pads/launch_pad.tscn", {"pad": pad, "title": "Launch Pad %d" % (pad + 1)})
		if Session.state().ended:
			await _open("res://scenes/turn/end_game.tscn", {"report": report})
			break
	assert_int(seasons_with_launches).is_greater(5)
	assert_int(Session.me().mission_log.size()).is_greater(3)


func _open(path: String, args: Dictionary) -> void:
	var node: Node = load(path).instantiate()
	add_child(node)
	if node.has_method("setup"):
		node.call("setup", args)
	await await_idle_frame()
	if node.has_method("on_resume"):
		node.call("on_resume")
	await await_idle_frame()
	node.queue_free()
	await await_idle_frame()
