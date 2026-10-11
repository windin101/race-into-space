class_name SimPersonnel
extends RefCounted
## Astronauts and cosmonauts: recruiting, basic and advanced training, program and crew
## assignment, compatibility, mood, retirement, and the roster side of mission outcomes.
## Rules: docs/specs/code-derived-rules.md sections 5, 9 and 10; constants.json
## "astronauts" and "crew". Where the spec prose and the upstream C++ disagree the
## upstream numbers are used and the difference is noted inline.
##
## Crews are not stored separately: a crew is the set of astronauts whose
## program_slot and crew_index match, ordered by crew_position (seat 0 = commander).

# Recruiting (ast1.cpp Recruit / AstSel)
const COST_FIRST_GROUP := 20
const COST_LATER_GROUPS := 15
const RECRUIT_DELAY_BY_GROUP := [6, 4, 4, 8, 99]
## ast1.cpp:588 `brandom(10) > 5` is 40%, not the 60% the spec prose says.
const RECRUIT_LOSS_PERCENT := 40
const RECRUIT_SECONDARY_LOSSES := 3
const RECRUIT_SECONDARY_SKILLS := ["lm", "eva", "docking"]
const MOOD_START_BASE := 85
const MOOD_START_STEP := 5
const MOOD_START_STEPS := 4          ## rand(0..3)
const COMPAT_RING := 10
const COMPAT_SPAN_MAX := 2           ## CL / CR 1..2
## Upstream requires at least one woman in the pick while women are offered (groups 1-3).
const WOMAN_REQUIRED_BY_GROUP := [true, true, true, false, false]

# Basic training (start.cpp updateAstronautSkills / AstroTurn)
const BASIC_SEASONS := 3
const BASIC_GAIN_TWO_PERCENT := 30
const WASHOUT_INCIDENT_PERCENT := 5
## start.cpp:437 `num > 74 - 10*Endurance` lands on INJURED: 25% + 10% per Endurance
## point are injured, the rest retire (the spec prose has the direction reversed).
const WASHOUT_INJURY_BASE_PERCENT := 25
const WASHOUT_INJURY_PER_ENDURANCE := 10
const WASHOUT_INJURY_SEASONS := 2
const WASHOUT_INJURY_SHORT_PERCENT_PER_ENDURANCE := 25   ## (Endurance-1)*25% -> 1 season
const WASHOUT_INJURY_LONG_PERCENT := 25                  ## Endurance 0: 25% -> 3 seasons

# Advanced training (ast2.cpp:587, ast3.cpp:515, start.cpp:218)
const ADVANCED_SEASONS := 4
const ADVANCED_SEASONS_SHORT := 3
const ADVANCED_COST := 3
const ADVANCED_COST_SKILL_3 := 2
const ADVANCED_ENTRY_SKILL_3_SEASONS := 2     ## enters at stage 3 of 4
const ADVANCED_REFUND_BY_STAGE := {1: 3, 2: 2, 3: 1, 4: 0}
const ADVANCED_MOOD_BASE := 6                 ## +6 - (astronaut_level + 1)

# Mood (start.cpp:495-585)
const MOOD_MOVED_UP := 5
const MOOD_PROGRAM_FIRST := 5
const MOOD_OWN_FAILURE_BUT_PROGRAM_FIRST := 20
const MOOD_MISSION_SUCCESS := 30
const MOOD_MISSION_SUCCESS_EASY := 35
const MOOD_FALL_BONUS_PERCENT := 5
const MOOD_FALL_BONUS := 5
const MOOD_HERO_IN_CREW := 5
const MOOD_ONE_MAN_TOO_LONG := -4
const ONE_MAN_TOO_LONG_SEASONS := 6
const MOOD_MOVED := -4               ## upstream `Moved == 0`: reassigned this season
const MOOD_NOT_IN_CREW := -6
const MOOD_IN_CREW := -3
const MOOD_SCRUBBED := -5
const MOOD_INJURED := -4
const MOOD_CARD_DEATH_MAX := 2
const MOOD_CONFLICT := -3
const MOOD_CONFLICT_BIG_CAPSULE := -2
const BIG_CAPSULE_SLOTS := [3, 4]    ## minishuttle, four-man

# Retirement
const MOOD_UNHAPPY := 20
const UNHAPPY_DELAY_USA := 2
const MUSTER_FROM_ACTIVE_SEASON := 8
const MUSTER_PERCENT := 10
const MUSTER_DELAY_USA := 3
const MUSTER_DELAY_USSR := 2
const MUSTER_REASON_COUNT := 6       ## upstream reasons 1-6 = first six news lines
const REASON_UNHAPPY := "low morale"
const REASON_WASHOUT := "washout"
const REASON_MISSION := "mission"

# Missions
const MISSION_INJURY_SEASONS := 3
const MISSION_RETIRE_DELAY := 1
const DEATH_REASON_MISSION := "mission"

# Crews
const MAX_CREWS_PER_PROGRAM := 8
const CAPSULE_SLOTS := 5
const ROLE_KEYS := {"capsule": "cap", "lm": "lm", "eva": "eva", "docking": "dock"}
const ROLE_SLOTS_DEFAULT := {
	1: {"cap": 0, "lm": 0, "eva": 0, "dock": null},
	2: {"cap": 0, "dock": 0, "lm": 1, "eva": 1},
	3: {"cap": 0, "lm": 1, "eva": 1, "dock": 2},
	4: {"cap": 0, "lm": 1, "eva": 2, "dock": 3},
}


# --- recruiting -------------------------------------------------------------------

static func _groups(state: SimState, p: SimPlayer) -> Array:
	return state.data.roster["sides"][p.side]


## Candidates of the current group, or [] while the previous group's delay runs or no
## groups are left. Women are offered only when the side allows them.
static func available_recruits(state: SimState, p: SimPlayer) -> Array:
	if p.recruit_delay > 0:
		return []
	var groups := _groups(state, p)
	if p.recruit_group < 0 or p.recruit_group >= groups.size():
		return []
	var out: Array = []
	for c in groups[p.recruit_group]["candidates"]:
		if c.get("female", false) and not p.female_allowed:
			continue
		out.append(c)
	return out


static func recruit_cost(p: SimPlayer, state: SimState = null) -> int:
	var costs: Dictionary = _c(state, ["astronauts", "recruitment", "group_cost_mb"], {})
	if p.recruit_group == 0:
		return costs.get("first_group", COST_FIRST_GROUP)
	return costs.get("later_groups", COST_LATER_GROUPS)


static func woman_required(p: SimPlayer) -> bool:
	return p.female_allowed and p.recruit_group < WOMAN_REQUIRED_BY_GROUP.size() \
		and WOMAN_REQUIRED_BY_GROUP[p.recruit_group]


## Recruit the named candidates from the current group. Picks beyond number_to_choose
## are dropped; unknown names are ignored. Refused without cash, with no valid pick, or
## when a woman is required and none was chosen.
static func recruit(state: SimState, p: SimPlayer, names: Array) -> bool:
	var pool := available_recruits(state, p)
	if pool.is_empty():
		return false
	var group: Dictionary = _groups(state, p)[p.recruit_group]
	var limit: int = group["number_to_choose"]
	var chosen: Array = []
	for n in names:
		if chosen.size() >= limit:
			break
		for c in pool:
			if c["name"] == n and not chosen.has(c):
				chosen.append(c)
				break
	if chosen.is_empty():
		return false
	if woman_required(p):
		var any_woman := false
		for c in chosen:
			if c.get("female", false):
				any_woman = true
		if not any_woman:
			return false
	if not p.spend(recruit_cost(p, state)):
		return false
	for c in chosen:
		var a := SimAstronaut.from_candidate(c)
		_apply_recruit_losses(state, a)
		a.mood = MOOD_START_BASE + MOOD_START_STEP * state.rng.below(MOOD_START_STEPS)
		a.compat = state.rng.d(COMPAT_RING)
		a.compat_left = state.rng.d(COMPAT_SPAN_MAX)
		a.compat_right = state.rng.d(COMPAT_SPAN_MAX)
		a.status = SimAstronaut.Status.BASIC_TRAINING
		a.training_seasons_left = _c(state, ["astronauts", "basic_training", "seasons"], BASIC_SEASONS)
		a.id = p.astronauts.size()
		p.astronauts.append(a)
	state.note("%s recruits %d (group %d)" % [p.side, chosen.size(), p.recruit_group + 1])
	var delays: Array = _c(state, ["astronauts", "recruitment", "delay_seasons_after_group"], RECRUIT_DELAY_BY_GROUP)
	p.recruit_delay = group.get("recruiting_delay", delays[p.recruit_group])
	p.recruit_group += 1
	return true


## 40% lose one Capsule or Endurance point (50/50); then three points come off LM, EVA
## or Docking at random. Skills may go negative until basic training floors them.
static func _apply_recruit_losses(state: SimState, a: SimAstronaut) -> void:
	if state.rng.chance(RECRUIT_LOSS_PERCENT):
		var key: String = "endurance" if state.rng.below(2) == 0 else "capsule"
		a.skills[key] -= 1
	for i in RECRUIT_SECONDARY_LOSSES:
		a.skills[state.rng.pick(RECRUIT_SECONDARY_SKILLS)] -= 1


# --- per-season processing --------------------------------------------------------

## Start of a turn: recruiting delay, training steps, injury and retirement countdowns,
## and the season counters.
static func start_of_season(state: SimState, p: SimPlayer) -> void:
	if p.recruit_delay > 0:
		p.recruit_delay -= 1
	for a in p.astronauts:
		if not a.is_alive():
			continue
		var old_status: int = a.status
		a.moved_this_season = false
		a.previous_program_slot = a.program_slot
		match a.status:
			SimAstronaut.Status.BASIC_TRAINING:
				_basic_training_step(state, p, a)
			SimAstronaut.Status.ADVANCED_TRAINING:
				_advanced_training_step(state, p, a)
			SimAstronaut.Status.INJURED:
				a.injured_until_seasons -= 1
				if a.injured_until_seasons <= 0:
					a.injured_until_seasons = 0
					a.status = SimAstronaut.Status.ACTIVE
					state.note("%s returns to duty" % a.name)
		if a.retire_in_seasons > 0 and a.status != SimAstronaut.Status.INJURED and a.is_alive():
			a.retire_in_seasons -= 1
			if a.retire_in_seasons == 0:
				_retire(state, p, a)
		if a.status == old_status:
			a.seasons_in_status += 1
		else:
			a.seasons_in_status = 0
		if a.is_alive() and a.status != SimAstronaut.Status.BASIC_TRAINING:
			a.seasons_active += 1
		if a.program_slot >= 0:
			a.seasons_in_program += 1


## One season of basic training: one random skill below the cap gains +1 (70%) or +2;
## negatives are floored; after the last season the astronaut becomes active. While
## still in training, 5% chance of an incident: injury (25% + 10% per Endurance point,
## 2 seasons, shortened or lengthened by Endurance as upstream) or a washout retirement.
static func _basic_training_step(state: SimState, p: SimPlayer, a: SimAstronaut) -> void:
	var delta := 2 if state.rng.chance(_c(state, ["astronauts", "basic_training", "gain_two_percent"], BASIC_GAIN_TWO_PERCENT)) else 1
	var choices: Array = []
	for s in SimAstronaut.SKILLS:
		if a.skills[s] < SimAstronaut.SKILL_MAX:
			choices.append(s)
	if not choices.is_empty():
		var gained: String = state.rng.pick(choices)
		a.skills[gained] = mini(a.skills[gained] + delta, SimAstronaut.SKILL_MAX)
	_floor_skills(a)
	a.training_seasons_left -= 1
	if a.training_seasons_left <= 0:
		a.training_seasons_left = 0
		a.status = SimAstronaut.Status.ACTIVE
		state.note("%s completes basic training" % a.name)
		return
	if state.rng.chance(WASHOUT_INCIDENT_PERCENT):
		var endurance := maxi(0, a.skills["endurance"])
		if state.rng.chance(WASHOUT_INJURY_BASE_PERCENT + WASHOUT_INJURY_PER_ENDURANCE * endurance):
			a.status = SimAstronaut.Status.INJURED
			a.injured_until_seasons = WASHOUT_INJURY_SEASONS
			if state.rng.below(100) < (endurance - 1) * WASHOUT_INJURY_SHORT_PERCENT_PER_ENDURANCE:
				a.injured_until_seasons = 1
			if endurance < 1 and state.rng.chance(WASHOUT_INJURY_LONG_PERCENT):
				a.injured_until_seasons = 3
			a.training_seasons_left = 0
			state.note("%s injured in training" % a.name)
		else:
			a.retire_reason = REASON_WASHOUT
			_retire(state, p, a)


## One season of advanced training. Stages mirror upstream ADV_1..ADV_4: +1 to the focus
## skill after stage 2 and on completion.
static func _advanced_training_step(state: SimState, p: SimPlayer, a: SimAstronaut) -> void:
	var stage := _training_stage(state, a)
	a.training_seasons_left -= 1
	if stage == 2:
		_raise_focus(a)
	if a.training_seasons_left <= 0:
		a.training_seasons_left = 0
		_raise_focus(a)
		a.status = SimAstronaut.Status.ACTIVE
		state.note("%s completes advanced %s training" % [a.name, a.training_focus])


static func _raise_focus(a: SimAstronaut) -> void:
	if a.training_focus != "":
		a.skills[a.training_focus] = mini(a.skills[a.training_focus] + 1, SimAstronaut.SKILL_MAX)


## Upstream stage 1-4 of the current advanced course, from the seasons done and left.
static func _training_stage(state: SimState, a: SimAstronaut) -> int:
	var elapsed := a.seasons_in_status
	var total := elapsed + a.training_seasons_left
	if total <= ADVANCED_ENTRY_SKILL_3_SEASONS:
		return 3 + elapsed
	if total == _advanced_seasons_short(state):
		return [1, 2, 4][mini(elapsed, 2)]
	return mini(1 + elapsed, 4)


static func _advanced_seasons_short(state: SimState) -> int:
	return _c(state, ["astronauts", "advanced_training", "seasons_short_option"], ADVANCED_SEASONS_SHORT)


static func _floor_skills(a: SimAstronaut) -> void:
	for s in SimAstronaut.SKILLS:
		if a.skills[s] < 0:
			a.skills[s] = 0


static func _retire(state: SimState, p: SimPlayer, a: SimAstronaut) -> void:
	_remove_from_crew(p, a)
	a.clear_assignment()
	a.status = SimAstronaut.Status.RETIRED
	a.retire_in_seasons = 0
	a.training_seasons_left = 0
	state.note("%s retires (%s)" % [a.name, a.retire_reason])


## End of a turn: mood for every living astronaut, then the retirement decisions.
## Turn flags read from p.turn_flags: "program_first" (a first this turn) and
## "card_death" (an event-card death).
static func end_of_season(state: SimState, p: SimPlayer) -> void:
	var program_first: bool = p.turn_flags.get("program_first", false)
	var card_death: bool = p.turn_flags.get("card_death", false)
	for a in p.astronauts:
		if not a.is_alive():
			continue
		var mood: int = a.mood
		var mates: Array = crew(p, a.program_slot, a.crew_index) if a.in_crew() else []
		if a.moved_this_season and a.program_slot > a.previous_program_slot:
			mood += MOOD_MOVED_UP
		if program_first:
			mood += MOOD_PROGRAM_FIRST
			if _mission_outcome_this_season(state, a) == "failure":
				mood += MOOD_OWN_FAILURE_BUT_PROGRAM_FIRST
		if state.season == SimState.SEASON_FALL and state.rng.chance(MOOD_FALL_BONUS_PERCENT):
			mood += MOOD_FALL_BONUS
		for mate in mates:
			if mate.hero:
				mood += MOOD_HERO_IN_CREW
				break
		if a.program_slot == 0 and a.seasons_in_program >= ONE_MAN_TOO_LONG_SEASONS:
			mood += MOOD_ONE_MAN_TOO_LONG
		if a.moved_this_season:
			mood += MOOD_MOVED
		if a.status == SimAstronaut.Status.INJURED:
			mood += MOOD_INJURED
		else:
			mood += MOOD_IN_CREW if a.in_crew() else MOOD_NOT_IN_CREW
		if card_death:
			mood -= state.rng.d(MOOD_CARD_DEATH_MAX)
		if a.in_crew():
			var per := MOOD_CONFLICT_BIG_CAPSULE if a.program_slot in BIG_CAPSULE_SLOTS else MOOD_CONFLICT
			mood += per * conflicts_for(a, mates)
		if a.status == SimAstronaut.Status.ADVANCED_TRAINING:
			mood += ADVANCED_MOOD_BASE - (p.astronaut_level + 1)
		a.mood = clampi(mood, 0, 100)

	for a in p.astronauts:
		if a.status != SimAstronaut.Status.ACTIVE or a.retire_in_seasons > 0:
			continue
		if a.mood < MOOD_UNHAPPY:
			a.retire_reason = REASON_UNHAPPY
			if p.index == 0:
				a.retire_in_seasons = UNHAPPY_DELAY_USA
			else:
				_retire(state, p, a)
			continue
		if a.seasons_active >= MUSTER_FROM_ACTIVE_SEASON and a.seasons_active % 2 == 0 \
				and state.rng.chance(MUSTER_PERCENT):
			a.retire_in_seasons = MUSTER_DELAY_USA if p.index == 0 else MUSTER_DELAY_USSR
			a.retire_reason = _pick_retirement_reason(state, p)


static func _pick_retirement_reason(state: SimState, p: SimPlayer) -> String:
	var reasons: Array = state.data.text.get("news", {}).get("retirement_reasons", {}).get(p.side, [])
	if reasons.is_empty():
		return "personal reasons"
	return state.rng.pick(reasons.slice(0, mini(MUSTER_REASON_COUNT, reasons.size())))


static func _mission_outcome_this_season(state: SimState, a: SimAstronaut) -> String:
	for i in range(a.mission_history.size() - 1, -1, -1):
		var h: Dictionary = a.mission_history[i]
		if h["year"] == state.year and h["season"] == state.season:
			return h["outcome"]
		if h["year"] < state.year or h["season"] < state.season:
			break
	return ""


# --- programs and crews -----------------------------------------------------------

## Owned capsule programs (manned slots 0-4), in slot order.
static func capsule_programs(p: SimPlayer) -> Array:
	var out: Array = []
	for slot in CAPSULE_SLOTS:
		var prog: SimProgram = p.program("manned", slot)
		if prog != null and prog.owned:
			out.append(prog)
	return out


static func _capsule(p: SimPlayer, slot: int) -> SimProgram:
	if slot < 0 or slot >= CAPSULE_SLOTS:
		return null
	var prog: SimProgram = p.program("manned", slot)
	return prog if prog != null and prog.owned else null


## Put an active, unassigned astronaut into a capsule program's pool.
static func assign_to_program(p: SimPlayer, a: SimAstronaut, slot: int) -> bool:
	if a.status != SimAstronaut.Status.ACTIVE or a.program_slot >= 0 or _capsule(p, slot) == null:
		return false
	_mark_moved(a)
	a.program_group = "manned"
	a.program_slot = slot
	a.seasons_in_program = 0
	return true


## Take an astronaut out of their program (and crew).
static func unassign(p: SimPlayer, a: SimAstronaut) -> void:
	if a.program_slot < 0:
		return
	_remove_from_crew(p, a)
	_mark_moved(a)
	a.clear_assignment()


static func _mark_moved(a: SimAstronaut) -> void:
	if not a.moved_this_season:
		a.previous_program_slot = a.program_slot
		a.moved_this_season = true


static func max_crews(state: SimState = null) -> int:
	return _c(state, ["crew", "max_crews_per_program"], MAX_CREWS_PER_PROGRAM)


## Form crew crew_index of the program in slot from members (seat order; seat 0 is the
## commander). Every member must be active, assigned to that program and not in another
## crew; the size must equal the capsule's capacity. Replaces any crew at that index.
static func set_crew(p: SimPlayer, slot: int, crew_index: int, members: Array, state: SimState = null) -> bool:
	var prog := _capsule(p, slot)
	if prog == null or crew_index < 0 or crew_index >= max_crews(state):
		return false
	if members.size() != prog.crew_capacity():
		return false
	for i in members.size():
		var a: SimAstronaut = members[i]
		if a.status != SimAstronaut.Status.ACTIVE or a.program_slot != slot:
			return false
		if a.crew_index >= 0 and a.crew_index != crew_index:
			return false
		if members.find(a) != i:
			return false
	clear_crew(p, slot, crew_index)
	for i in members.size():
		var a: SimAstronaut = members[i]
		a.crew_index = crew_index
		a.crew_position = i
	return true


static func clear_crew(p: SimPlayer, slot: int, crew_index: int) -> void:
	for a in crew(p, slot, crew_index):
		a.crew_index = -1
		a.crew_position = -1


## Members of a crew in seat order; [] if none.
static func crew(p: SimPlayer, slot: int, crew_index: int) -> Array:
	if slot < 0 or crew_index < 0:
		return []
	var out: Array = []
	for a in p.astronauts:
		if a.program_slot == slot and a.crew_index == crew_index:
			out.append(a)
	out.sort_custom(func(x, y): return x.crew_position < y.crew_position)
	return out


## Crew indices in use for a program.
static func crews_of(p: SimPlayer, slot: int) -> Array:
	var seen: Array = []
	for a in p.astronauts:
		if a.program_slot == slot and a.crew_index >= 0 and not seen.has(a.crew_index):
			seen.append(a.crew_index)
	seen.sort()
	return seen


## Dissolve the crew the astronaut is in, as upstream CheckFlightCrews does; the
## crewmates keep their program assignment.
static func _remove_from_crew(p: SimPlayer, a: SimAstronaut) -> void:
	if a.in_crew():
		clear_crew(p, a.program_slot, a.crew_index)


## A likes B when B's compat lies in [A.compat - CL, A.compat + CR] on the ring of 10.
## Not symmetric.
static func compatible(a: SimAstronaut, b: SimAstronaut) -> bool:
	var low := a.compat - a.compat_left
	var high := a.compat + a.compat_right
	for offset: int in [0, COMPAT_RING, -COMPAT_RING]:
		var c: int = b.compat + offset
		if c >= low and c <= high:
			return true
	return false


## Crewmates this astronaut is unhappy with.
static func conflicts_for(a: SimAstronaut, crew_members: Array) -> int:
	var n := 0
	for mate in crew_members:
		if mate != a and not compatible(a, mate):
			n += 1
	return n


## Total conflicts in a crew: the sum over members of the crewmates each dislikes, so an
## asymmetric pair counts once and a mutual one twice.
static func crew_conflicts(crew_members: Array) -> int:
	var n := 0
	for a in crew_members:
		n += conflicts_for(a, crew_members)
	return n


## The skill the crew brings to a role on a mission step. "endurance" is the crew
## average rounded to nearest (mc2.cpp CrewEndurance); the other roles belong to the
## seat in constants crew.role_slots_by_crew_size.
static func crew_skill(crew_members: Array, role: String, state: SimState = null) -> int:
	var size := crew_members.size()
	if size == 0:
		return 0
	if role == "endurance":
		var total := 0
		for a in crew_members:
			total += a.skill("endurance")
		return int(float(total) / float(size) + 0.5)
	if not ROLE_KEYS.has(role):
		return 0
	var table: Dictionary = _c(state, ["crew", "role_slots_by_crew_size"], ROLE_SLOTS_DEFAULT)
	var slots: Variant = table.get(str(size), table.get(size, null))
	if slots == null:
		return 0
	var seat: Variant = slots.get(ROLE_KEYS[role], null)
	if seat == null or int(seat) >= size:
		return 0
	return crew_members[int(seat)].skill(role)


# --- advanced training ------------------------------------------------------------

static func _adv(state: SimState, key: String, default: int) -> int:
	return _c(state, ["astronauts", "advanced_training", key], default)


## Send an active astronaut who is not in a crew to advanced training in one skill.
## 3 MB for 4 seasons (3 with options.short_training); 2 MB and the last two seasons
## when the skill is already 3; refused at 4.
static func start_advanced_training(state: SimState, p: SimPlayer, a: SimAstronaut, skill: String) -> bool:
	if a.status != SimAstronaut.Status.ACTIVE or a.in_crew() or not SimAstronaut.SKILLS.has(skill):
		return false
	var level := a.skill(skill)
	if level >= SimAstronaut.SKILL_MAX:
		return false
	var cost := _adv(state, "cost_mb", ADVANCED_COST)
	var seasons := _adv(state, "seasons", ADVANCED_SEASONS)
	if state.options.get("short_training", false):
		seasons = _advanced_seasons_short(state)
	if level == SimAstronaut.SKILL_MAX - 1:
		cost = _adv(state, "cost_if_skill_already_3", ADVANCED_COST_SKILL_3)
		seasons = ADVANCED_ENTRY_SKILL_3_SEASONS
	if not p.spend(cost):
		return false
	unassign(p, a)
	a.status = SimAstronaut.Status.ADVANCED_TRAINING
	a.seasons_in_status = 0
	a.training_focus = skill
	a.training_seasons_left = seasons
	return true


## Pull an astronaut out of advanced training early. Returns the refund (3/2/1/0 by
## stage), paid to the player.
static func withdraw_training(state: SimState, p: SimPlayer, a: SimAstronaut) -> int:
	if a.status != SimAstronaut.Status.ADVANCED_TRAINING:
		return 0
	var stage := _training_stage(state, a)
	var refunds: Dictionary = _c(state, ["astronauts", "advanced_training", "refund_on_withdrawal"], {})
	var refund: int = ADVANCED_REFUND_BY_STAGE[stage]
	match stage:
		1: refund = refunds.get("after_season_1", refund)
		2: refund = refunds.get("after_season_2", refund)
		3: refund = refunds.get("after_season_3", refund)
	p.cash += refund
	a.status = SimAstronaut.Status.ACTIVE
	a.seasons_in_status = 0
	a.training_focus = ""
	a.training_seasons_left = 0
	_floor_skills(a)
	return refund


# --- missions ---------------------------------------------------------------------

## Apply a mission's result to one crew member. outcome is one of "success", "failure",
## "scrubbed", "injured", "dead" or "retired".
static func on_mission_outcome(state: SimState, p: SimPlayer, a: SimAstronaut, outcome: String, mission_index: int) -> void:
	a.mission_history.append({
		"year": state.year, "season": state.season, "mission_index": mission_index, "outcome": outcome,
	})
	if outcome != "scrubbed":
		a.missions_flown += 1
	match outcome:
		"success":
			a.mood = clampi(a.mood + (MOOD_MISSION_SUCCESS_EASY if p.astronaut_level == 0 else MOOD_MISSION_SUCCESS), 0, 100)
		"scrubbed":
			a.mood = clampi(a.mood + MOOD_SCRUBBED, 0, 100)
		"injured":
			_remove_from_crew(p, a)
			a.clear_assignment()
			a.status = SimAstronaut.Status.INJURED
			a.seasons_in_status = 0
			a.injured_until_seasons = MISSION_INJURY_SEASONS
			state.note("%s injured on a mission" % a.name)
		"dead":
			_remove_from_crew(p, a)
			a.clear_assignment()
			a.status = SimAstronaut.Status.DEAD
			a.seasons_in_status = 0
			a.death_reason = DEATH_REASON_MISSION
			a.retire_in_seasons = 0
			state.note("%s killed on a mission" % a.name)
		"retired":
			_remove_from_crew(p, a)
			a.clear_assignment()
			a.retire_in_seasons = MISSION_RETIRE_DELAY
			a.retire_reason = REASON_MISSION
			state.note("%s will retire after a mission" % a.name)


static func make_hero(a: SimAstronaut) -> void:
	a.hero = true


# --- queries ----------------------------------------------------------------------

## {"active": n, "basic_training": n, ..., "total": n}
static func roster_summary(p: SimPlayer) -> Dictionary:
	var out: Dictionary = {}
	for key in SimAstronaut.Status.keys():
		out[key.to_lower()] = 0
	for a in p.astronauts:
		out[a.status_name()] += 1
	out["total"] = p.astronauts.size()
	return out


## Walk constants.json by path; the module default when the key is missing.
static func _c(state: SimState, path: Array, default: Variant) -> Variant:
	if state == null:
		return default
	var node: Variant = state.constants()
	for key in path:
		if typeof(node) != TYPE_DICTIONARY or not node.has(key):
			return default
		node = node[key]
	return node
