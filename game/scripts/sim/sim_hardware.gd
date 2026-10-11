class_name SimHardware
extends RefCounted
## Buying programs and units, research, and per-season hardware upkeep.
## Rules: docs/specs/code-derived-rules.md section 6; constants.json "rnd", "hardware_turn".

const MAX_UNITS := 6
const MAX_TEAMS := 5
const RD_DIE := 6


static func half_price(p: SimPlayer) -> bool:
	return p.turn_flags.get("half_price", false)


static func program_price(p: SimPlayer, prog: SimProgram) -> int:
	var cost := prog.program_cost()
	return maxi(1, int(cost / 2.0)) if half_price(p) else cost


static func unit_price(p: SimPlayer, prog: SimProgram) -> int:
	var cost := prog.unit_cost()
	return maxi(1, int(cost / 2.0)) if half_price(p) else cost


static func can_buy_program(p: SimPlayer, prog: SimProgram) -> bool:
	return not prog.owned and prog.delay == 0 and p.cash >= program_price(p, prog)


## Open a program: pay the program cost, get one unit, set the starting safety from
## the base and any technology transfer from related programs already owned.
static func buy_program(state: SimState, p: SimPlayer, prog: SimProgram) -> bool:
	if not can_buy_program(p, prog):
		return false
	p.spend(program_price(p, prog))
	prog.owned = true
	prog.units = 1
	prog.safety = starting_safety(state, p, prog)
	prog.max_rd = prog.spec["max_rd"]
	prog.max_rd_original = prog.spec["max_rd"]
	state.note("%s opens %s program at %d%% safety" % [p.side, prog.display_name(), prog.safety])
	return true


static func can_buy_unit(p: SimPlayer, prog: SimProgram) -> bool:
	return prog.owned and prog.delay == 0 and prog.units < MAX_UNITS and p.cash >= unit_price(p, prog)


static func buy_unit(p: SimPlayer, prog: SimProgram) -> bool:
	if not can_buy_unit(p, prog):
		return false
	p.spend(unit_price(p, prog))
	prog.units += 1
	return true


## Starting safety for a newly bought program. Uses game/data/tech_transfer.json when
## present; otherwise the program's base safety.
static func starting_safety(state: SimState, p: SimPlayer, prog: SimProgram) -> int:
	var base := prog.base_safety()
	var table: Dictionary = state.data.tech_transfer
	if table.is_empty():
		return base
	for rule in table.get("rules", []):
		if rule["target"]["group"] != prog.group or rule["target"]["slot"] != prog.slot:
			continue
		base = rule.get("base", base)
		for fixed in rule.get("fixed", []):
			var all_met := true
			for cond in fixed["when_all"]:
				var donor: SimProgram = p.program(cond["group"], cond["slot"])
				if donor == null or not donor.owned or donor.safety < cond["min_safety"]:
					all_met = false
					break
			if all_met:
				return mini(fixed["value"], prog.max_safety())
		var combine: String = rule.get("combine", "sum")
		var bonus := 0
		var best := 0
		for src in rule.get("sources", []):
			var donor: SimProgram = p.program(src["group"], src["slot"])
			if donor == null or not donor.owned:
				continue
			if src.has("condition_min_safety") and donor.safety < src["condition_min_safety"]:
				continue
			var contrib := int(floor(maxf(0.0, (donor.safety - src["threshold"]) / float(src["divisor"]))))
			contrib = mini(contrib, src["cap"])
			if combine == "max":
				best = maxi(best, contrib)
			elif combine == "first":
				if contrib > 0:
					best = contrib
					break
			else:
				bonus += contrib
		return mini(base + (best if combine != "sum" else bonus), prog.max_safety())
	return base


## How many teams a player may assign this season: hard difficulty always allows five,
## otherwise no more than the points still available below Max R&D.
static func max_teams(p: SimPlayer, prog: SimProgram) -> int:
	if not prog.can_research():
		return 0
	if p.level >= 2:
		return MAX_TEAMS
	return mini(MAX_TEAMS, prog.max_rd - prog.safety)


static func research_cost(p: SimPlayer, prog: SimProgram, teams: int) -> int:
	return teams * (prog.rd_cost() + p.turn_flags.get("rd_cost_surcharge_" + prog.display_name(), 0))


## Assign teams for one season: each team rolls 1d(6 + turn modifier), the sum is added
## to safety and capped at Max R&D. Returns the gain, or -1 if the purchase was refused.
static func research(state: SimState, p: SimPlayer, prog: SimProgram, teams: int) -> int:
	if teams < 1 or teams > max_teams(p, prog) or prog.researched_this_season:
		return -1
	var cost := research_cost(p, prog, teams)
	if not p.spend(cost):
		return -1
	var die := maxi(1, RD_DIE + p.rd_mods_turn)
	var gain := 0
	for i in teams:
		gain += state.rng.d(die)
	var before := prog.safety
	prog.safety = mini(prog.safety + gain, prog.max_rd)
	prog.researched_this_season = true
	return prog.safety - before


## Per-season upkeep, run at the start of a turn.
static func start_of_season(p: SimPlayer) -> void:
	for prog in p.all_programs():
		if prog.delay > 0:
			prog.delay -= 1
		prog.researched_this_season = false
		if prog.owned:
			prog.safety = clampi(prog.safety, prog.base_safety(), prog.max_safety())
	p.turn_flags.clear()
	p.rd_mods_turn = maxi(p.rd_mods_year, 0)


## After a mission: hardware with a successful step gains +1 safety (cap max safety) and
## +1 Max R&D (cap max safety - 2). Docking module and photo recon do not gain safety.
static func reward_success(prog: SimProgram) -> void:
	prog.flights += 1
	prog.successes += 1
	if not (prog.is_docking_module() or prog.is_photo_recon()):
		prog.safety = mini(prog.safety + 1, prog.max_safety())
	prog.max_rd = mini(prog.max_rd + 1, prog.max_safety() - 2)


## After a crew death on this hardware: easy halves the safety, otherwise it resets to base.
## Max R&D returns to its original value.
static func punish_death(p: SimPlayer, prog: SimProgram) -> void:
	prog.failures += 1
	if p.level == 0:
		prog.safety = maxi(prog.base_safety(), int(prog.safety / 2.0))
	else:
		prog.safety = prog.base_safety()
	prog.max_rd = prog.max_rd_original
