extends Node
## Autoload "Session": the running game (a SimGame) and the human player's side.
## Screens read state through here and send commands to the sim modules.

signal game_started
signal turn_ended(report: Dictionary)
signal state_changed

var game: SimGame
var human_side := "usa"      ## side at the controls now: the player, or in hot-seat play the one whose turn it is
var humans: Array = []       ## sides played by people, in line-up order (one, or several for hot-seat)
var drivers: Array = []       ## SimAi for each computer side


func has_game() -> bool:
	return game != null


## options.sides: the line-up (side ids, default from data/sides.json); options.humans:
## the sides played by people (default [options.human_side], else the first side). Every
## other side is run by the AI. With more than one human the game is hot-seat: each takes
## their turn in line-up order before the season plays out.
func new_game(p_seed: int, options: Dictionary = {}) -> void:
	var opts := options.duplicate()
	var lineup: Array = Array(opts.get("sides", Sides.default_lineup()))
	opts["sides"] = lineup
	var asked: Array = Array(opts.get("humans", [str(opts.get("human_side", lineup[0]))]))
	humans = lineup.filter(func(side): return asked.has(side))
	if humans.is_empty():
		humans = [lineup[0]]
	human_side = str(humans[0])
	for side in lineup:
		opts["ai_%s" % side] = not humans.has(side)
	opts["active_side"] = human_side
	game = SimGame.new(GameData, p_seed, opts)
	_make_drivers()
	_apply_theme()
	game_started.emit()
	state_changed.emit()


## Resume a game rebuilt by SimSave (or any ready SimGame). Who is human comes from the
## save's players; p_human_side is the side at the controls when no saved turn says so.
func load_game(p_game: SimGame, p_human_side: String) -> void:
	game = p_game
	humans = []
	for p in game.state.players:
		if not p.is_ai:
			humans.append(p.side)
	if humans.is_empty():   # a rebuilt game with every side on the AI: hand one to the player
		humans = [p_human_side]
		for p in game.state.players:
			p.is_ai = p.side != p_human_side
	var active := str(game.state.options.get("active_side", p_human_side))
	human_side = active if humans.has(active) else str(humans[0])
	_make_drivers()
	_apply_theme()
	game_started.emit()
	state_changed.emit()


func is_hot_seat() -> bool:
	return humans.size() > 1


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


## The side at the controls has finished its season. In hot-seat play, until every human
## has had their turn this only passes the controls on and returns {"handover": side}.
## After the last human the AI sides act, the season plays out and the report is returned,
## with the controls back with the first human.
func end_turn() -> Dictionary:
	if game == null or game.state.ended:
		return {}
	var i := humans.find(human_side)
	if i >= 0 and i < humans.size() - 1:
		_set_active(str(humans[i + 1]))
		state_changed.emit()
		return {"handover": human_side}
	for d in drivers:
		d.act(game)
	_set_active(str(humans[0]))
	var report := game.end_turn()
	turn_ended.emit(report)
	state_changed.emit()
	return report


func notify_change() -> void:
	state_changed.emit()


func _set_active(side: String) -> void:
	human_side = side
	game.state.options["active_side"] = side
	_apply_theme()


func _apply_theme() -> void:
	UiTheme.apply(get_tree(), human_side)
