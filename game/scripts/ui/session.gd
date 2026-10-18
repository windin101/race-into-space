extends Node
## Autoload "Session": the running game (a SimGame) and the human player's side.
## Screens read state through here and send commands to the sim modules.

signal game_started
signal turn_ended(report: Dictionary)
signal state_changed

var game: SimGame
var human_side := "usa"      ## side id of the human player
var drivers: Array = []       ## SimAi for each computer side


func has_game() -> bool:
	return game != null


## options.sides: the line-up (side ids, default from data/sides.json); options.human_side:
## which of them the player controls. Every other side is run by the AI.
func new_game(p_seed: int, options: Dictionary = {}) -> void:
	var opts := options.duplicate()
	var lineup: Array = Array(opts.get("sides", Sides.default_lineup()))
	opts["sides"] = lineup
	human_side = str(opts.get("human_side", lineup[0]))
	if not lineup.has(human_side):
		human_side = str(lineup[0])
	for side in lineup:
		opts["ai_%s" % side] = side != human_side
	game = SimGame.new(GameData, p_seed, opts)
	_make_drivers()
	_apply_theme()
	game_started.emit()
	state_changed.emit()


## Resume a game rebuilt by SimSave (or any ready SimGame) as the given side.
func load_game(p_game: SimGame, p_human_side: String) -> void:
	game = p_game
	human_side = p_human_side
	for p in game.state.players:
		p.is_ai = p.side != human_side
	_make_drivers()
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
	return game.state.player_for_side(human_side)


## Every other side in the race.
func rivals() -> Array[SimPlayer]:
	if game == null:
		return []
	return game.state.rivals(me().index)


## The leading rival (the only one in a two-side game).
func rival() -> SimPlayer:
	if game == null:
		return null
	return game.state.leading_rival(me().index)


func _make_drivers() -> void:
	drivers.clear()
	for p in game.state.players:
		if p.is_ai:
			drivers.append(SimAi.new(p.index))


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
	UiTheme.apply(get_tree(), human_side)
