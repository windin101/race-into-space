extends SceneTree
## Faction balance: plays all-AI games for a line-up and reports each side's wins, lunar
## landing year and final prestige.
##
##   godot --headless --path game -s res://tools/sim_balance.gd -- --sides usa,ussr,cwth --games 300 [--level 0]

func _init() -> void:
	var games := 300
	var sides := "usa,ussr,cwth"
	var level := 0
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		match args[i]:
			"--games": games = int(args[i + 1])
			"--sides": sides = args[i + 1]
			"--level": level = int(args[i + 1])
	var data = load("res://scripts/data/game_data.gd").new()
	data.load_all()
	var lineup := sides.split(",")
	var wins := {}
	var prestige := {}
	var land_year := {}
	var landings := {}
	for s in lineup:
		wins[s] = 0
		prestige[s] = 0
		land_year[s] = 0
		landings[s] = 0
	var nobody := 0
	for g in games:
		var opts := {"model": "basic", "sides": Array(lineup)}
		for s in lineup:
			opts["level_%s" % s] = level
		var game := SimGame.new(data, 5000 + g, opts)
		var drivers: Array = []
		for p in game.state.players:
			p.is_ai = true
			drivers.append(SimAi.new(p.index))
		var guard := 0
		while not game.state.ended and guard < 60:
			for d in drivers:
				d.act(game)
			game.end_turn()
			guard += 1
		var w := game.state.winner
		if w < 0:
			nobody += 1
		else:
			var ws: String = game.state.player(w).side
			wins[ws] += 1
			land_year[ws] += 1900 + game.state.year
			landings[ws] += 1
		for p in game.state.players:
			prestige[p.side] += p.prestige_total
	print("lineup %s  games %d  level %d  no winner %d" % [sides, games, level, nobody])
	for s in lineup:
		var avg_year: float = float(land_year[s]) / landings[s] if landings[s] > 0 else 0.0
		print("  %-5s wins %4d (%5.1f%%)  avg landing %6.1f  avg prestige %6.1f" % [s, wins[s], 100.0 * wins[s] / games, avg_year, float(prestige[s]) / games])
	quit()
