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
