extends Node
## Autoload "Session": the running game (a SimGame) and the human player's side.
## Screens read state through here and send commands to the sim modules.

signal game_started
signal turn_ended(report: Dictionary)
signal state_changed

var game: SimGame
var human_side := "usa"
var drivers: Array = []       ## SimAi for each computer side


func has_game() -> bool:
	return game != null


func new_game(p_seed: int, options: Dictionary = {}) -> void:
	human_side = options.get("human_side", "usa")
	var opts := options.duplicate()
	opts["ai_usa"] = human_side != "usa"
	opts["ai_ussr"] = human_side != "ussr"
	game = SimGame.new(GameData, p_seed, opts)
	drivers.clear()
	for i in 2:
		if game.state.player(i).is_ai:
			drivers.append(SimAi.new(i))
	_apply_theme()
	game_started.emit()
	state_changed.emit()


## Resume a game rebuilt by SimSave (or any ready SimGame) as the given side.
func load_game(p_game: SimGame, p_human_side: String) -> void:
	game = p_game
	human_side = p_human_side
	for i in 2:
		var p := game.state.player(i)
		p.is_ai = p.side != human_side
	drivers.clear()
	for i in 2:
		if game.state.player(i).is_ai:
			drivers.append(SimAi.new(i))
	_apply_theme()
	game_started.emit()
	state_changed.emit()


func save_to_slot(slot: String, label: String) -> bool:
	if game == null:
		return false
	return SimSave.save_slot(game, slot, label)


func load_from_slot(slot: String) -> bool:
	var loaded := SimSave.load_slot(GameData, slot)
	if loaded == null:
		return false
	load_game(loaded, SimSave.human_side_of(loaded))
	return true


func state() -> SimState:
	return game.state if game != null else null


func me() -> SimPlayer:
	if game == null:
		return null
	return game.state.player(0 if human_side == "usa" else 1)


func rival() -> SimPlayer:
	if game == null:
		return null
	return game.state.player(1 if human_side == "usa" else 0)


## Let the AI sides act, then roll the season over.
func end_turn() -> Dictionary:
	if game == null or game.state.ended:
		return {}
	for d in drivers:
		d.act(game)
	var report := game.end_turn()
	turn_ended.emit(report)
	state_changed.emit()
	return report


func notify_change() -> void:
	state_changed.emit()


func _apply_theme() -> void:
	get_tree().root.theme = UiTheme.get_theme(human_side)
