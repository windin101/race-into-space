class_name SimReview
extends RefCounted
## The annual Capitol / Politburo review, dismissal, and the director's score.
## Rules: game/data/review.json (upstream review.cpp CalcPresRev, game_main.cpp:545-583,
## hardef.cpp CalcScore). The review index is a running value, 8 at the start, lower is
## better; each spring it moves by last year's two season prestige sums.
##
## Project decision: the <= -10 step uses the intended "1 + own level" rather than the
## upstream precedence bug that adds the USA level for both sides.

const START_INDEX := 8
const FIRED_AT := 16
const TEXT_PER_SIDE := 18


## Process both players in order, as upstream does (the USA compares with the USSR's
## previous index, the USSR with the USA's new one).
static func annual_reviews(state: SimState) -> void:
	for p in state.players:
		annual_review(state, p)


static func annual_review(state: SimState, p: SimPlayer) -> Dictionary:
	var hist := p.prestige_history
	var spring: int = hist[hist.size() - 2] if hist.size() >= 2 else 0
	var fall: int = hist[hist.size() - 1] if hist.size() >= 1 else 0
	var hi := maxi(spring, fall)
	var lo := mini(spring, fall)
	var val: int
	if (spring >= 0 and fall >= 0) or (spring <= 0 and fall <= 0):
		val = hi + lo
	else:
		val = int(hi / 2.0) + lo        # truncates toward zero like C
	var ip := p.review_index
	if val < 0 and ip < 4:
		ip += 1
	elif val >= 2 and val <= 10:
		ip -= 1
	elif val >= 11 and val <= 20:
		ip -= 1 if ip < 4 else 2
	elif val >= 21:
		ip -= 1 if ip < 4 else 3
	elif val >= -9 and val <= 0:
		ip += 1
	elif val <= -10:
		ip += 1 + p.level
	ip = clampi(ip, 1, FIRED_AT)
	# Doing worse than the best-reviewed rival costs a further point.
	var best_rival := 99
	for r in state.rivals(p.index):
		best_rival = mini(best_rival, r.review_index)
	if ip > best_rival:
		ip += 1
	p.review_index = ip
	var review := {"year": state.year, "spring": spring, "fall": fall, "value": val,
			"index": ip, "text_index": text_index(state, p, ip), "bad": ip > 8}
	p.reviews.append(review)
	state.note("%s review index %d" % [p.side, ip])
	return review


## Line in text/reviews.json for this side and index. Fired players get the dismissal
## line, or the harsher one when two or more astronauts have died.
static func text_index(state: SimState, p: SimPlayer, index: int) -> int:
	var base := TEXT_PER_SIDE * Sides.text_slot(p.side)
	if index >= FIRED_AT:
		var dead := 0
		for a in p.astronauts:
			if a.status == SimAstronaut.Status.DEAD:
				dead += 1
		return base + (17 if dead >= 2 else 16)
	return base + clampi(index, 1, 15)


## Only a human playing the computer above easy can be dismissed.
static func dismissed(state: SimState, p: SimPlayer) -> bool:
	if p.is_ai or p.level == 0:
		return false
	for r in state.rivals(p.index):
		if not r.is_ai:
			return false
	return p.review_index >= FIRED_AT


## Director's score: positive mission prestige weighted by both sides' difficulty, plus a
## landing bonus for the side that made the manned lunar landing, by year.
static func director_score(state: SimState, p: SimPlayer) -> int:
	var lv_a := p.level + 1
	var lv_b := 1
	for r in state.rivals(p.index):
		lv_b = maxi(lv_b, r.level + 1)
	var total := 0
	for r in p.mission_log:
		var pr: int = r.get("prestige", {}).get("total", 0)
		if pr <= 0:
			continue
		match lv_a:
			1:
				total += pr
			2:
				if lv_b == 1:
					total += 2 * pr + int(pr / 3.0)
				elif lv_b == 3:
					total += pr + int(2 * pr / 3.0)
				else:
					total += 2 * pr
			3:
				if lv_b == 1:
					total += 3 * pr + int(2 * pr / 3.0)
				elif lv_b == 2:
					total += 3 * pr + int(pr / 3.0)
				else:
					total += 3 * pr
	var landing: Dictionary = state.prestige_rows[SimGame.ROW_LUNAR_LANDING]
	if landing["first"] != p.index:
		return total
	var y := state.year
	match lv_a:
		1:
			total += 50 if y <= 67 else (25 if y <= 69 else 0)
		2:
			total += 75 if y <= 67 else (50 if y <= 69 else (25 if y <= 73 else 0))
		3:
			total += 150 if y <= 67 else (75 if y <= 69 else (50 if y <= 73 else 0))
	return total
