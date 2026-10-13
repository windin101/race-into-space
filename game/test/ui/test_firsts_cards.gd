extends GdUnitTestSuite
## Every prestige first in a season's report gets a story card, the rival's included.


func _season_with_rival_first() -> Dictionary:
	Session.new_game(7, {"human_side": "usa"})
	var ai := SimDriver.new(1)
	for t in 30:
		ai.act(Session.game)
		var report := Session.game.end_turn()
		for l in report.get("launches", []):
			for aw in l.get("prestige", {}).get("awards", []):
				if aw.get("kind", "") == "first" and int(l.get("player", -1)) == 1:
					return report
	return {}


func test_rival_first_gets_a_news_card() -> void:
	var report := _season_with_rival_first()
	assert_bool(report.is_empty()).override_failure_message("the Soviet AI never claimed a first in 30 seasons").is_false()
	var cards := TurnFlow.firsts_for(report, Session.state(), 0, "usa")
	assert_int(cards.size()).is_greater(0)
	var card: Dictionary = cards[0]
	assert_bool(card["rival"]).is_true()
	assert_str(card["title"]).starts_with("Soviet first")
	assert_str(card["text"]).contains("Radio Moscow")


func test_rival_card_carries_the_rival_side() -> void:
	var report := _season_with_rival_first()
	var cards := TurnFlow.firsts_for(report, Session.state(), 0, "usa")
	assert_str(cards[0]["side"]).is_equal("ussr")


## The card must draw above the screen stack (Screens is CanvasLayer 1); it once sat under
## it, invisible, and held the whole end-of-turn chain waiting for a click nobody could make.
func test_story_card_is_above_the_screens() -> void:
	StoryCard.show_card(self, "Title", "Body", null, "usa")
	await await_idle_frame()
	var cards := get_tree().root.find_children("*", "StoryCard", true, false)
	assert_int(cards.size()).is_greater(0)
	var card: Control = cards[0]
	var layer = card.get_parent()
	assert_bool(layer is CanvasLayer).is_true()
	assert_int((layer as CanvasLayer).layer).is_greater(Screens.layer)
	card.emit_signal("closed")
	await await_idle_frame()


## After a season with launches the player watches the playback first, then the results,
## then the newscast; the playback must not run hidden under the others.
func test_season_screens_open_with_the_playback() -> void:
	var report := _season_with_rival_first()
	Screens.reset(load("res://scenes/spaceport/spaceport.tscn"))
	var was_skip := Settings.skip_launch_animation
	Settings.skip_launch_animation = false
	await TurnFlow.after_end_turn_screens_only(report)
	Settings.skip_launch_animation = was_skip
	var order: Array = []
	for s in Screens.stack:
		order.append(s.scene_file_path.get_file().get_basename())
	assert_str(order.back()).is_equal("mission_playback")
	assert_int(order.find("launch_results")).is_equal(order.size() - 2)
	assert_bool(order.find("newscast") < order.find("launch_results")).is_true()
	Screens.go_home()


func test_firsts_wait_for_the_results_screen() -> void:
	var report := _season_with_rival_first()
	Screens.reset(load("res://scenes/spaceport/spaceport.tscn"))
	TurnFlow.after_end_turn(report)
	await await_idle_frame()
	# No card is on screen yet; it waits until Launch Results closes.
	assert_int(get_tree().root.find_children("*", "StoryCard", true, false).size()).is_equal(0)
	assert_int(TurnFlow.pending_cards.size()).is_greater(0)
	TurnFlow.pending_cards = []
	Screens.go_home()
