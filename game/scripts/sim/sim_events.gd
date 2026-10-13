class_name SimEvents
extends RefCounted
## The newscast: a pre-dealt deck of event cards and their effects.
## Rules: docs/specs/code-derived-rules.md section 15; game/data/event_effects.json.
##
## Astronaut effects (death, injury, retirement, bonus recruits) go through SimPersonnel.

const DECK_SIZE := 100
const OPENING_CODE := 0
const TEXT_OFFSET := 2              ## events.json text index = code + 2
const FILLER_FIRST_TEXT := 102      ## filler lines are texts 102..115, flag bits 1..14
const FILLER_COUNT := 14

## Deck build: [first slot, number of slots, cumulative pool percentages].
const PERIODS := [
	[2, 2, [100, 100, 100, 100, 100]],
	[4, 8, [0, 100, 100, 100, 100]],
	[12, 8, [0, 62, 100, 100, 100]],
	[20, 12, [0, 50, 70, 100, 100]],
	[32, 16, [0, 35, 55, 75, 100]],
	[48, 52, [0, 25, 50, 75, 100]],
]
const POOLS := [[1, 3], [4, 43], [44, 62], [63, 79], [80, 99]]


## Deal the whole game's event sequence. Called once at new game. The upstream deck serves
## two players (even and odd slots); a race of more sides deals one deck per pair, laid end
## to end in state.event_deck, so a two-side game deals exactly as before.
static func build_deck(state: SimState) -> void:
	var all: Array[int] = []
	for pair in ceili(state.players.size() / 2.0):
		all.append_array(_deal_one(state))
	state.event_deck = all


static func _deal_one(state: SimState) -> Array[int]:
	var pools: Array = []
	for range_pair in POOLS:
		var pool: Array[int] = []
		for c in range(range_pair[0], range_pair[1] + 1):
			pool.append(c)
		pools.append(pool)
	var deck: Array[int] = []
	deck.resize(DECK_SIZE)
	deck.fill(OPENING_CODE)
	for period in PERIODS:
		var first: int = period[0]
		var count: int = period[1]
		var cdf: Array = period[2]
		for slot in range(first, first + count):
			var code := _draw_from_pools(state, pools, cdf)
			if code < 0:
				break
			deck[slot] = code
	return deck


static func _draw_from_pools(state: SimState, pools: Array, cdf: Array) -> int:
	var any_left := false
	for pool in pools:
		if not pool.is_empty():
			any_left = true
	if not any_left:
		return -1
	for attempt in 200:
		var r := state.rng.below(100)
		var chosen := -1
		for k in cdf.size():
			if cdf[k] > r:
				chosen = k
				break
		if chosen < 0 or pools[chosen].is_empty():
			continue
		var pool: Array = pools[chosen]
		var idx := state.rng.below(pool.size())
		var code: int = pool[idx]
		pool.remove_at(idx)
		return code
	return -1


## The deck slot a player reads this season: its pair's deck, then even or odd slots.
static func slot_for(state: SimState, p: SimPlayer) -> int:
	return int(p.index / 2) * DECK_SIZE + 2 * state.turn_index() + p.index % 2


static func card_for_code(state: SimState, code: int) -> Dictionary:
	var cards: Array = state.data.event_effects.get("cards", [])
	var idx := code + TEXT_OFFSET
	if idx < 0 or idx >= cards.size():
		return {}
	return cards[idx]


static func text_for(state: SimState, p: SimPlayer, text_index: int) -> Dictionary:
	var lines: Array = state.data.text["events"].get(p.side, state.data.text["events"].get("usa", []))
	if text_index < 0 or text_index >= lines.size():
		return {"text": "", "color": 0}
	return lines[text_index]


## Run this player's newscast for the current turn: budget drift, then the card.
## Returns {code, text_index, text, color, effect, applied, detail}.
static func newscast(state: SimState, p: SimPlayer) -> Dictionary:
	var drift := SimEconomy.newscast_adjustment(state, p)
	var slot := slot_for(state, p)
	var code := OPENING_CODE
	if slot < state.event_deck.size():
		code = state.event_deck[slot]
	var card := card_for_code(state, code)
	var result := {"code": code, "budget_drift": drift, "effect": card.get("effect", "none"),
			"applied": false, "detail": {}}
	var year_ok: bool = card.get("min_year") == null or state.year >= int(card["min_year"])
	var applied := false
	if year_ok and not card.is_empty():
		var outcome := apply_card(state, p, card)
		applied = outcome["ok"]
		result["detail"] = outcome
	if applied or (year_ok and card.get("effect", "none") in ["none", "unimplemented"]):
		result["applied"] = applied
		result["text_index"] = code + TEXT_OFFSET
	else:
		result["effect"] = "filler"
		result["text_index"] = _filler_text(state, p)
	var t := text_for(state, p, result["text_index"])
	result["text"] = t["text"]
	result["color"] = t["color"]
	p.last_news = result
	state.note("%s news: %s" % [p.side, result["effect"]])
	return result


static func _filler_text(state: SimState, p: SimPlayer) -> int:
	var free: Array[int] = []
	for bit in range(1, FILLER_COUNT + 1):
		if (p.bad_card_flags & (1 << bit)) == 0:
			free.append(bit)
	if free.is_empty():
		p.bad_card_flags = 0
		for bit in range(1, FILLER_COUNT + 1):
			free.append(bit)
	var bit: int = state.rng.pick(free)
	p.bad_card_flags |= (1 << bit)
	return FILLER_FIRST_TEXT + bit - 1


## Parse "4d6" or an int. Returns the rolled or fixed amount.
static func _amount(state: SimState, params: Dictionary) -> int:
	if params.has("amount") and typeof(params["amount"]) != TYPE_STRING:
		return int(params["amount"])
	if params.has("dice"):
		var parts: PackedStringArray = str(params["dice"]).split("d")
		if parts.size() == 2:
			var total := 0
			for i in int(parts[0]):
				total += state.rng.d(int(parts[1]))
			return total
	return 0


static func _candidates(p: SimPlayer, group: String) -> Array:
	var out: Array = []
	var specs: Array = []
	match group:
		"nmod_probe", "dam_probe": specs = [["probe", 0, 2]]
		"nmod_rocket", "dam_rocket", "save_rocket": specs = [["rocket", 0, 3]]
		"nmod_manned": specs = [["manned", 0, 6]]
		"dam_manned": specs = [["manned", 0, 4]]
		"save_capsule": specs = [["manned", 0, 3]]
		"save_lem": specs = [["manned", 4, 6]]
		"nmod_any", "dam_any", "rdcost_any": specs = [["probe", 0, 2], ["rocket", 0, 3], ["manned", 0, 6], ["misc", 0, 3]]
		"save_all": specs = [["probe", 0, 2], ["rocket", 0, 3], ["manned", 0, 6]]
		_: specs = []
	var need_above_base := group.begins_with("dam_") or group == "rdcost_any"
	for spec in specs:
		for slot in range(spec[1], spec[2] + 1):
			var prog: SimProgram = p.program(spec[0], slot)
			if prog == null or not prog.owned:
				continue
			if need_above_base and prog.safety <= prog.base_safety():
				continue
			out.append(prog)
	return out


## "Most advanced" = the last candidate in probes < rockets < manned < misc order.
static func _most_advanced(p: SimPlayer, group: String, filter: Callable = Callable()) -> SimProgram:
	var cands := _candidates(p, group)
	for i in range(cands.size() - 1, -1, -1):
		if filter.is_null() or filter.call(cands[i]):
			return cands[i]
	return null


## Apply one card. Returns {ok, ...details}; ok false means a "bad card" (no effect).
static func apply_card(state: SimState, p: SimPlayer, card: Dictionary) -> Dictionary:
	var effect: String = card.get("effect", "none")
	var params: Dictionary = card.get("params", {})
	var rival := state.leading_rival(p.index)
	match effect:
		"none":
			return {"ok": true}
		"unimplemented":
			return {"ok": true}
		"cash_delta":
			var amt := _amount(state, params)
			p.cash += amt
			return {"ok": true, "amount": amt}
		"cash_pct":
			if p.cash < int(params.get("min_cash", 0)):
				return {"ok": false}
			var loss: int = int(p.cash * int(params["pct"]) / 100.0)
			p.cash -= loss
			return {"ok": true, "amount": -loss}
		"budget_delta":
			var amt := _amount(state, params)
			p.budget += amt
			return {"ok": true, "amount": amt}
		"budget_pct":
			var loss: int = mini(int(p.budget * int(params["pct"]) / 100.0), int(params.get("cap", 999)))
			p.budget -= loss
			return {"ok": true, "amount": -loss}
		"rd_mod_turn", "rd_mod_year":
			var amt := int(params.get("amount", 0))
			p.rd_mods_turn += amt
			if effect == "rd_mod_year":
				p.rd_mods_year = amt
			return {"ok": true, "amount": amt}
		"rd_cost_up":
			var prog := _most_advanced(p, "rdcost_any")
			if prog == null:
				return {"ok": false}
			prog.rd_cost_extra += int(params.get("amount", 1))
			return {"ok": true, "program": prog.display_name()}
		"tech_steal", "tech_leak":
			var cands: Array = []
			for prog in p.owned_programs():
				var theirs: SimProgram = rival.program(prog.group, prog.slot)
				if theirs == null or not theirs.owned or theirs.safety <= prog.safety:
					continue
				var gap: int = theirs.safety - prog.safety
				if effect == "tech_leak" and prog.safety - gap < prog.base_safety():
					continue
				cands.append([prog, gap])
			if cands.is_empty():
				return {"ok": false}
			var pick: Array = state.rng.pick(cands)
			var prog: SimProgram = pick[0]
			var gap: int = pick[1]
			prog.safety += gap if effect == "tech_steal" else -gap
			return {"ok": true, "program": prog.display_name(), "amount": gap}
		"program_safety_delta":
			var amt := _amount(state, params)
			var prog := _most_advanced(p, str(params.get("group", "nmod_any")),
					func(c: SimProgram) -> bool: return amt <= 0 or c.safety + amt <= c.max_safety())
			if prog == null:
				return {"ok": false}
			prog.safety = clampi(prog.safety + amt, prog.base_safety(), prog.max_safety())
			return {"ok": true, "program": prog.display_name(), "amount": amt}
		"program_safety_halved":
			var prog := _most_advanced(p, "nmod_rocket", func(c: SimProgram) -> bool: return c.safety > 50)
			if prog == null:
				return {"ok": false}
			var loss: int = int(prog.safety / 2.0)
			prog.safety -= loss
			return {"ok": true, "program": prog.display_name(), "amount": -loss, "new_safety": prog.safety}
		"program_max_safety_up":
			var amt := int(params.get("amount", 5))
			for slot in 3:
				var prog: SimProgram = p.program("probe", slot)
				if prog != null:
					prog.max_safety_extra += amt
					prog.max_rd = mini(prog.max_rd + amt, prog.max_safety())
			return {"ok": true, "amount": amt}
		"program_delay":
			for slot in 5:
				var prog: SimProgram = p.program("rocket", slot)
				if prog != null:
					prog.delay = int(params.get("seasons", 2))
			return {"ok": true}
		"program_unit_cost_up":
			var m := RegEx.new()
			m.compile("(Probe|Rocket|Manned|Misc)\\[(\\d)\\]")
			var found := m.search(str(params.get("program", "")))
			if found == null:
				return {"ok": false}
			var prog: SimProgram = p.program(found.get_string(1).to_lower(), int(found.get_string(2)))
			if prog == null or not prog.owned:
				return {"ok": false}
			prog.unit_cost_extra += int(params.get("amount", 1))
			return {"ok": true, "program": prog.display_name()}
		"pay_or_penalty":
			var prog := _most_advanced(p, str(params.get("group", "dam_any")))
			if prog == null:
				return {"ok": false}
			prog.damage = int(params.get("safety_penalty", -10))
			prog.damage_cost = int(params.get("cost", 10))
			return {"ok": true, "program": prog.display_name(), "cost": prog.damage_cost, "penalty": prog.damage}
		"save_card":
			var prog := _most_advanced(p, str(params.get("group", "save_all")))
			if prog == null:
				return {"ok": false}
			p.save_cards += 1
			return {"ok": true, "program": prog.display_name()}
		"half_price_sale":
			p.turn_flags["half_price"] = true
			return {"ok": true}
		"female_astronauts":
			p.female_allowed = true
			return {"ok": true}
		"mission_scrub":
			var pads := _scheduled_pads(p)
			if pads.is_empty():
				return {"ok": false}
			var pad: int = state.rng.pick(pads)
			scrub_scheduled(p, pad)
			return {"ok": true, "pad": pad}
		"mission_delay":
			var pads: Array = []
			for pad in _scheduled_pads(p):
				var mi: int = p.missions[pad]["mission_index"]
				var m: Dictionary = state.data.missions[mi]
				if m["joint"] == 1:
					continue
				if SimPlanner.PLANET_MISSIONS.has(mi):
					var when := SimPlanner.launch_date(state)
					if not SimCalendar.window_open(SimPlanner.PLANET_MISSIONS[mi], when[0], when[1]):
						continue
				pads.append(pad)
			if pads.is_empty():
				return {"ok": false}
			var pad: int = state.rng.pick(pads)
			p.future[pad] = p.missions[pad]
			p.missions[pad] = null
			return {"ok": true, "pad": pad}
		"mission_crew_swap":
			for pad in _scheduled_pads(p):
				var plan: Dictionary = p.missions[pad]
				var m: Dictionary = state.data.missions[plan["mission_index"]]
				if int(m["crew_mode"]) in [2, 3, 4]:
					plan["crew_choice"] = [1, 1]
					return {"ok": true, "pad": pad}
			return {"ok": false}
		"pad_damage":
			var pad := -1
			if typeof(params.get("pad", 0)) == TYPE_STRING:
				# "random operational pad with no mission this season", up to 20 tries.
				for attempt in 20:
					var candidate := state.rng.below(3)
					if p.pads[candidate] == SimPlayer.PAD_OK and p.missions[candidate] == null:
						pad = candidate
						break
			else:
				pad = int(params.get("pad", 0))
				if p.pads[pad] != SimPlayer.PAD_OK or p.missions[pad] != null:
					pad = -1
			if pad < 0:
				return {"ok": false}
			p.pads[pad] = int(params.get("repair_cost", 15))
			return {"ok": true, "pad": pad}
		"astronaut_death", "astronaut_injury", "astronaut_retire", "astronaut_recruit":
			return _astronaut_effect(state, p, effect, params)
	return {"ok": false, "unknown": effect}


static func _scheduled_pads(p: SimPlayer) -> Array:
	var pads: Array = []
	for pad in 3:
		if p.missions[pad] != null and p.missions[pad].get("part", 1) == 1:
			pads.append(pad)
	return pads


## Remove a scheduled mission (and its joint half) from this season's pads.
static func scrub_scheduled(p: SimPlayer, pad: int) -> void:
	var plan = p.missions[pad]
	if plan == null:
		return
	if plan.get("part", 1) == 2:
		pad = plan["primary_pad"]
		plan = p.missions[pad]
	p.missions[pad] = null
	if plan != null and plan.get("joint", false) and pad + 1 < 3 and p.missions[pad + 1] != null:
		p.missions[pad + 1] = null


static func _living(p: SimPlayer) -> Array:
	var out: Array = []
	for a in p.astronauts:
		if a.is_alive():
			out.append(a)
	return out


static func _astronaut_effect(state: SimState, p: SimPlayer, effect: String, params: Dictionary) -> Dictionary:
	if effect == "astronaut_recruit":
		var bonus: Array = params.get(p.side, [])
		for b in bonus:
			var a := SimAstronaut.new()
			a.id = p.astronauts.size()
			a.name = b["name"]
			a.skills = {"capsule": b["cap"], "lm": b["lm"], "eva": b["eva"], "docking": b["dock"], "endurance": b["end"]}
			a.mood = 85 + 5 * state.rng.below(4)
			a.compat = state.rng.d(10)
			a.compat_left = state.rng.d(2)
			a.compat_right = state.rng.d(2)
			a.status = SimAstronaut.Status.BASIC_TRAINING
			p.astronauts.append(a)
		return {"ok": true, "count": bonus.size()}
	var living := _living(p)
	if living.is_empty():
		return {"ok": false}
	var a: SimAstronaut = state.rng.pick(living)
	var outcome := ""
	match effect:
		"astronaut_death":
			outcome = "dead"
			p.budget += int(params.get("budget_delta", -5))
			p.catastrophe_flags |= 2
			for pad in _scheduled_pads(p):
				var m: Dictionary = state.data.missions[p.missions[pad]["mission_index"]]
				if int(m["crew_mode"]) in [2, 3, 4]:
					scrub_scheduled(p, pad)
		"astronaut_injury":
			outcome = "injured"
		"astronaut_retire":
			outcome = "retired"
			p.budget += int(params.get("budget_delta", -5))
			a.mood = int(params.get("mood_set", 10))
	SimPersonnel.on_mission_outcome(state, p, a, outcome, -1)
	return {"ok": true, "astronaut": a.name, "outcome": outcome}


## Pay to clear event-card damage on a program before it flies.
static func pay_damage(p: SimPlayer, prog: SimProgram) -> bool:
	if prog.damage == 0 or not p.spend(prog.damage_cost):
		return false
	prog.damage = 0
	prog.damage_cost = 0
	return true
