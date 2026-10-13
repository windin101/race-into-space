extends SceneTree
## Plays seeded AI-versus-AI games and prints one fingerprint line per game: every
## season's prestige, cash and launches for each side, the winner and the end reason.
## Used as a regression gate: a refactor that changes no rules must reproduce these
## lines exactly.
##
##   godot --headless --path game -s res://tools/sim_fingerprint.gd -- --games 20 [--sides usa,ussr]

func _init() -> void:
	var games := 20
	var sides := ""
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--games":
			games = int(args[i + 1])
		if args[i] == "--sides":
			sides = args[i + 1]
	var data = load("res://scripts/data/game_data.gd").new()
	data.load_all()
	for g in games:
		var opts := {"model": "basic"}
		if sides != "":
			opts["sides"] = sides.split(",")
		var game := SimGame.new(data, 1000 + g, opts)
		for p in game.state.players:
			p.is_ai = true
		var drivers: Array = []
		for p in game.state.players:
			drivers.append(SimAi.new(p.index))
		var trail := PackedStringArray()
		var guard := 0
		while not game.state.ended and guard < 60:
			for d in drivers:
				d.act(game)
			var report := game.end_turn()
			var row := PackedStringArray()
			for p in game.state.players:
				row.append("%d/%d/%d" % [p.prestige_total, p.cash, p.mission_log.size()])
			trail.append(",".join(row))
			guard += 1
		var h := ";".join(trail).sha256_text().substr(0, 16)
		print("game %d seed %d winner %d reason [%s] turns %d trail %s" % [g, 1000 + g, game.state.winner, game.state.end_reason, guard, h])
	quit()
