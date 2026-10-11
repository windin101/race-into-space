class_name TurnFlow
extends RefCounted
## What the player sees between seasons: launch results, then the end of the game or the
## annual review, then the new season's newscast. Each screen pops itself when done; the
## chain is pushed in reverse so the first to show sits on top.

const LAUNCH_RESULTS := "res://scenes/turn/launch_results.tscn"
const PLAYBACK := "res://scenes/playback/mission_playback.tscn"
const NEWSCAST := "res://scenes/turn/newscast.tscn"
const ANNUAL_REVIEW := "res://scenes/turn/annual_review.tscn"
const END_GAME := "res://scenes/turn/end_game.tscn"


static func after_end_turn(report: Dictionary) -> void:
	var state := Session.state()
	if state == null:
		return
	var chain: Array = []
	if state.ended:
		chain.append([END_GAME, {"report": report}])
	else:
		chain.append([NEWSCAST, {}])
		if SimCalendar.is_review_time(state) and not Session.me().reviews.is_empty():
			chain.append([ANNUAL_REVIEW, {"review": Session.me().reviews.back()}])
	if not report.get("launches", []).is_empty():
		chain.append([LAUNCH_RESULTS, {"report": report}])
		if not Settings.skip_launch_animation:
			chain.append([PLAYBACK, {"report": report}])
	# Push bottom-up: the last element is shown first.
	chain.reverse()
	for entry in chain:
		_push_if_exists(entry[0], entry[1])


## Show the opening newscast when a new game starts.
static func on_new_game() -> void:
	_push_if_exists(NEWSCAST, {})


static func _push_if_exists(path: String, args: Dictionary) -> void:
	if ResourceLoader.exists(path):
		Screens.push(load(path), args)
