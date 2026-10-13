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
	# Firsts, ours and the rival's, arrive as story cards, one at a time, before the
	# season's screens.
	for card in firsts_for(report, state, Session.me().index, Session.human_side):
		var tree := Engine.get_main_loop() as SceneTree
		if tree == null:
			break
		await StoryCard.show_card(tree.root, card["title"], card["text"], card["picture"], Session.human_side)
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


## Story cards for every prestige first in an end-turn report, one card per flight in
## flight order: the human's own firsts as a celebration, the rival's as a news report
## (a first the rival takes is lost to us, so it must never pass unnoticed).
## Returns [{title, text, picture, rival}]. `player` and `side` are the human's.
static func firsts_for(report: Dictionary, state: SimState, player: int, side: String) -> Array:
	var cards: Array = []
	for result in report.get("launches", []):
		var flier := int(result.get("player", -1))
		var flier_side := "usa" if flier == 0 else "ussr"
		var rival := flier != player
		var titles: PackedStringArray = []
		var points := 0
		for aw in result.get("prestige", {}).get("awards", []):
			if aw.get("kind", "") != "first":
				continue
			var row: int = int(aw.get("row", -1))
			if row >= 0 and row < state.data.prestige.size():
				titles.append(str(state.data.prestige[row].get("title", "")).to_lower())
			points += int(aw.get("points", 0))
		if titles.is_empty():
			continue
		var mi: int = int(result.get("mission_index", -1))
		var mission_name := ""
		if mi >= 0 and mi < state.data.missions.size():
			mission_name = PlaybackScript.mission_title(state.data.missions[mi]["name"])
		var nation := "The United States" if flier_side == "usa" else "The Soviet Union"
		var listed := titles[0] if titles.size() == 1 else ", ".join(titles.slice(0, titles.size() - 1)) + " and " + titles[-1]
		var title: String
		var text: String
		if rival:
			title = "%s first: %s" % ["American" if flier_side == "usa" else "Soviet", mission_name]
			text = "%s %s. %s claims the first %s in history and gains %d prestige. The record is lost to us; the race goes on." % [
				"Washington announces" if flier_side == "usa" else "Radio Moscow announces",
				"a successful %s" % mission_name.to_lower(), nation, listed, points]
		else:
			title = "First: " + mission_name
			text = "%s claims the first %s in history and gains %d prestige." % [nation, listed, points]
		# The Moon-landing celebration only for our own lunar landings; else the key art.
		var landing := mi >= 0 and "LANDING" in str(state.data.missions[mi].get("name", "")).to_upper() and int(state.data.missions[mi].get("lunar", 0)) == 1
		var pic: Texture2D = ArtAssets.backdrop("endgame_%s_win" % side if landing and not rival else "title")
		if pic == null and mi >= 0:
			pic = ArtAssets.patch(flier_side, mi)
		cards.append({"title": title, "text": text, "picture": pic, "rival": rival})
	return cards


## Show the opening newscast when a new game starts.
static func on_new_game() -> void:
	_push_if_exists(NEWSCAST, {})


static func _push_if_exists(path: String, args: Dictionary) -> void:
	if ResourceLoader.exists(path):
		Screens.push(load(path), args)
