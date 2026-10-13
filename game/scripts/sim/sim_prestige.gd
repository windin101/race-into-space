class_name SimPrestige
extends RefCounted
## Scoring a finished mission against the 28-row prestige table and setting milestones.
## Rules: docs/specs/code-derived-rules.md sections 1 and 2.
##
## A mission result is a Dictionary:
##   player: int, mission_index: int, manned: bool,
##   goals: Array of {row: int, success: bool}   rows attempted, in order; rows the mission
##                                                could claim but never reached are success=false
##   deaths: int, catastrophic: bool

const ROW_MANNED_SPACE_MISSION := 27
const FLOOR_WITH_DEATH := -10
const FLOOR_NO_DEATH := -7
const OTHER_PAID_WHILE_TOTAL_BELOW := 3

## A first or second on a row silently marks these lower rows as done without paying them.
const CHAIN := {
	18: [0], 22: [20], 20: [19], 19: [7], 7: [1], 1: [18],
	8: [9], 9: [10], 10: [11], 11: [12],
	17: [16], 16: [15], 15: [14], 14: [13],
}

## Prestige row -> milestone index (constants.json milestones.prestige_row_to_milestone).
const ROW_TO_MILESTONE := {0: 0, 27: 1, 18: 2, 1: 3, 7: 4, 19: 5, 20: 6, 22: 7}


## Score the mission, credit the player and update the shared ledger.
## Returns {total: int, awards: Array of {row, kind, points}}.
static func award(state: SimState, result: Dictionary) -> Dictionary:
	var pidx: int = result["player"]
	var p := state.player(pidx)
	var deaths: int = result.get("deaths", 0)
	var awards: Array = []
	var total := 0

	var goals: Array = result.get("goals", []).duplicate(true)
	if deaths > 0:
		for g in goals:
			g["success"] = false

	var any_positive := false
	for g in goals:
		if not g["success"]:
			continue
		var pts := _claim(state, pidx, g["row"], total, awards)
		total += pts
		if pts > 0:
			any_positive = true

	if result.get("manned", false) and any_positive:
		total += _claim(state, pidx, ROW_MANNED_SPACE_MISSION, total, awards)

	# Failure: the single most valuable goal that was attempted and failed pays its penalty once.
	var worst_row := -1
	var worst_value := -1
	for g in goals:
		if g["success"]:
			continue
		var value: int = state.data.prestige[g["row"]]["first"]
		if value > worst_value:
			worst_value = value
			worst_row = g["row"]
	if worst_row >= 0:
		var penalty: int = state.data.prestige[worst_row]["failure"]
		if penalty != 0:
			total += penalty
			awards.append({"row": worst_row, "kind": "failure", "points": penalty})

	total = maxi(total, FLOOR_WITH_DEATH if deaths > 0 else FLOOR_NO_DEATH)
	p.add_prestige(total)
	return {"total": total, "awards": awards}


## Pay a row to the player if they are first, second, or eligible for a trickle award.
static func _claim(state: SimState, pidx: int, row: int, running_total: int, awards: Array) -> int:
	var ledger: Dictionary = state.prestige_rows[row]
	var table: Dictionary = state.data.prestige[row]
	var pts := 0
	var kind := ""
	if ledger["first"] == -1:
		ledger["first"] = pidx
		ledger["first_year"] = state.year
		ledger["first_season"] = state.season
		pts = table["first"]
		kind = "first"
		_mark_chain(state, pidx, row)
		_set_milestone(state, pidx, row)
	elif ledger["second"] == -1 and ledger["first"] != pidx:
		ledger["second"] = pidx
		pts = table["second"]
		kind = "second"
		_mark_chain(state, pidx, row)
		_set_milestone(state, pidx, row)
	elif not _is_achiever(ledger, pidx):
		# A third (or later) side to achieve the row: paid the row's trickle value and
		# counted as having achieved it, so its later missions are not blocked.
		ledger["others"].append(pidx)
		pts = table["other"]
		kind = "later"
		_mark_chain(state, pidx, row)
		_set_milestone(state, pidx, row)
	elif running_total < OTHER_PAID_WHILE_TOTAL_BELOW:
		pts = table["other"]
		kind = "other"
	if kind != "":
		awards.append({"row": row, "kind": kind, "points": pts})
	return pts


static func _mark_chain(state: SimState, pidx: int, row: int) -> void:
	for lower in CHAIN.get(row, []):
		var ledger: Dictionary = state.prestige_rows[lower]
		if ledger["first"] == -1:
			ledger["first"] = pidx
			ledger["first_year"] = state.year
			ledger["first_season"] = state.season
		elif ledger["second"] == -1 and ledger["first"] != pidx:
			ledger["second"] = pidx
		elif not _is_achiever(ledger, pidx):
			ledger["others"].append(pidx)
		_set_milestone(state, pidx, lower)
		_mark_chain(state, pidx, lower)


static func _set_milestone(state: SimState, pidx: int, row: int) -> void:
	if ROW_TO_MILESTONE.has(row):
		state.player(pidx).milestones[ROW_TO_MILESTONE[row]] = 1


## True if the player has achieved the row (first, second or later).
static func achieved(state: SimState, pidx: int, row: int) -> bool:
	return _is_achiever(state.prestige_rows[row], pidx)


static func _is_achiever(ledger: Dictionary, pidx: int) -> bool:
	return ledger["first"] == pidx or ledger["second"] == pidx or ledger.get("others", []).has(pidx)
