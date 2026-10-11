extends SceneTree
## Headless batch runner: plays scripted games and prints curves for tuning.
##
##   godot --headless --path game -s res://tools/sim_cli.gd -- --games 20 --seed 1 [--model historical] [--verbose]


func _init() -> void:
	var args := _parse_args()
	var games := int(args.get("games", "10"))
	var first_seed := int(args.get("seed", "1"))
	var model: String = args.get("model", "basic")
	var verbose := args.has("verbose")
	var trace := args.has("trace")

	var data = load("res://scripts/data/game_data.gd").new()
	root.add_child(data)
	data.load_all()
	if not data.loaded:
		push_error("data failed to load: %s" % ", ".join(data.load_errors))
		quit(1)
		return

	var landings := [0, 0]
	var landing_years: Array = []
	var budget_by_year: Dictionary = {}      # year -> [sum usa, sum ussr, count]
	var prestige_by_year: Dictionary = {}
	var outcomes: Dictionary = {}
	for g in games:
		var seed_value := first_seed + g
		var game := SimGame.new(data, seed_value, {"model": model, "ai_usa": true, "ai_ussr": true})
		var drivers := [SimDriver.new(0), SimDriver.new(1)]
		var turns := 0
		while not game.state.ended and turns < 50:
			for d in drivers:
				d.act(game)
			var year := game.state.year
			for i in 2:
				var p := game.state.player(i)
				if not budget_by_year.has(year):
					budget_by_year[year] = [0, 0, 0]
					prestige_by_year[year] = [0, 0, 0]
				budget_by_year[year][i] += p.budget
				prestige_by_year[year][i] += p.prestige_total
				if i == 1:
					budget_by_year[year][2] += 1
					prestige_by_year[year][2] += 1
			if trace:
				var st := game.state
				var line := "%s" % st.date_string()
				for i in 2:
					var pp := st.player(i)
					var plans: Array = []
					for pad in 3:
						if pp.future[pad] != null and pp.future[pad].get("part", 1) == 1:
							plans.append(data.missions[pp.future[pad]["mission_index"]]["abbr"].substr(0, 18))
					var owned: Array = []
					for prog in pp.owned_programs():
						if not prog.is_photo_recon():
							owned.append("%s%d" % [prog.display_name().substr(0, 3), prog.safety])
					line += " | P%d cash %3d bud %3d steps %d/%d astro %d plans %s hw %s" % [i, pp.cash, pp.budget,
						drivers[i].manned_step, drivers[i].probe_step, pp.astronauts.size(), str(plans), " ".join(owned)]
				print(line)
			var report := game.end_turn()
			if verbose:
				for l in report["launches"]:
					print("  seed %d %s P%d %s -> %s %s" % [seed_value, report["date"], l["player"],
						data.missions[l["mission_index"]]["name"], l["outcome"],
						("(%+d) dur %d" % [l["prestige"]["total"], l.get("duration_achieved", 0)]) if l.has("prestige") else ("reason: " + str(l.get("reason", "")))])
					if l.has("prestige") and l["outcome"] == "success" and l["prestige"]["total"] < 0:
						print("    goals %s awards %s deaths %d" % [str(l["goals"]), str(l["prestige"]["awards"]), l["deaths"]])
			turns += 1
		var s := game.state
		var key := s.end_reason
		outcomes[key] = outcomes.get(key, 0) + 1
		if s.winner >= 0 and s.end_reason == "lunar landing":
			landings[s.winner] += 1
			landing_years.append(s.full_year())
		print("seed %d: %s, winner %s, %s, prestige %d/%d, budget %d/%d, missions %d/%d" % [
			seed_value, s.date_string(), ["none", "USA", "USSR"][s.winner + 1], s.end_reason,
			s.player(0).prestige_total, s.player(1).prestige_total,
			s.player(0).budget, s.player(1).budget,
			s.player(0).mission_log.size(), s.player(1).mission_log.size()])

	print("\n== %d games, model %s ==" % [games, model])
	print("outcomes: %s" % str(outcomes))
	print("landings USA %d, USSR %d; years %s" % [landings[0], landings[1], str(landing_years)])
	print("year  budget USA  budget USSR  prestige USA  prestige USSR")
	var years := budget_by_year.keys()
	years.sort()
	for y in years:
		var b: Array = budget_by_year[y]
		var pr: Array = prestige_by_year[y]
		var n: int = maxi(1, b[2])
		print("19%02d  %6.1f  %6.1f  %7.1f  %7.1f" % [y, float(b[0]) / n, float(b[1]) / n, float(pr[0]) / n, float(pr[1]) / n])
	quit(0)


func _parse_args() -> Dictionary:
	var out := {}
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		var a: String = args[i]
		if a.begins_with("--"):
			var key := a.substr(2)
			if i + 1 < args.size() and not args[i + 1].begins_with("--"):
				out[key] = args[i + 1]
				i += 1
			else:
				out[key] = "true"
		i += 1
	return out
