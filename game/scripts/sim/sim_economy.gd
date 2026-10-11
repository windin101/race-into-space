class_name SimEconomy
extends RefCounted
## Money: budget growth from prestige, the yearly grant, the newscast adjustment and pads.
## Rules: docs/specs/code-derived-rules.md section 4; constants.json "budget", "launch_pads".

const BUDGET_CAP := 180
const BUDGET_FLOOR_FOR_NEWS := 40
const CASH_OVERFLOW_LIMIT := 999
const CASH_OVERFLOW_RESET := 900
const PAD_COST := 20
const BAND_EDGES := [0, 50, 90, 110, 140, 160]


## End of every season: prestige earned this season raises the budget, capped.
## End of fall: the budget is paid into cash for the coming year.
static func end_of_season(state: SimState) -> void:
	for p in state.players:
		p.prestige_history.append(p.prestige)
		p.budget = mini(p.budget + p.prestige, BUDGET_CAP)
		p.prestige = 0
		p.budget_history.append(p.budget)
		p.spending_this_season = 0
		if state.season == SimState.SEASON_FALL:
			p.cash += p.budget
			if p.cash > CASH_OVERFLOW_LIMIT:
				p.cash = CASH_OVERFLOW_RESET


## Budget band 0..5 for the newscast adjustment table: range[k] < budget <= range[k+1].
static func budget_band(budget: int) -> int:
	for k in range(BAND_EDGES.size() - 1):
		if budget > BAND_EDGES[k] and budget <= BAND_EDGES[k + 1]:
			return k
	return 5


## Newscast: floor the budget at 40 then add a random entry from the band's ten picks.
## Only block 0 of the upstream table is used (blocks 1 and 2 are an upstream TODO).
static func newscast_adjustment(state: SimState, p: SimPlayer) -> int:
	p.budget = maxi(p.budget, BUDGET_FLOOR_FOR_NEWS)
	var band := budget_band(p.budget)
	var picks: Array = state.data.budget_adjustments["blocks"][0][band]
	var delta: int = state.rng.pick(picks)
	p.budget += delta
	return delta


static func can_buy_pad(p: SimPlayer) -> bool:
	return p.pad_count() < 3 and p.cash >= PAD_COST


static func buy_pad(p: SimPlayer) -> bool:
	if not can_buy_pad(p):
		return false
	for i in 3:
		if p.pads[i] == SimPlayer.PAD_NONE:
			p.spend(PAD_COST)
			p.pads[i] = SimPlayer.PAD_OK
			return true
	return false


## Repair a damaged pad for its stored cost; a destroyed pad (cost >= 20) is rebuilt at 20.
static func repair_pad(p: SimPlayer, i: int) -> bool:
	var cost: int = p.pads[i]
	if cost <= 0:
		return false
	cost = mini(cost, PAD_COST)
	if not p.spend(cost):
		return false
	p.pads[i] = SimPlayer.PAD_OK
	return true
