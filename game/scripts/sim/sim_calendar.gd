class_name SimCalendar
extends RefCounted
## Season advance and the planetary launch windows.
## Rules: docs/specs/code-derived-rules.md section 11.

## Years (two-digit) and seasons in which a planetary flyby may be launched.
## Mars: spring 60/62/64/66, fall 69/71/73. Saturn: 61/66/72. Jupiter: 60/64/68/72/73/77.
## Upstream gives Jupiter and Saturn years without a season, so both seasons are allowed.
const WINDOWS := {
	"mars": [[60, 0], [62, 0], [64, 0], [66, 0], [69, 1], [71, 1], [73, 1]],
	"jupiter": [[60, -1], [64, -1], [68, -1], [72, -1], [73, -1], [77, -1]],
	"saturn": [[61, -1], [66, -1], [72, -1]],
}

## Seasons after launch at which each flyby resolves (constants calendar / spec section 11).
const FLYBY_DELAY := {"mercury": 0, "venus": 0, "mars": 2, "jupiter": 4, "saturn": 7}


## Move to the next season. Returns false when the calendar has run out (after Fall 1977).
static func advance(state: SimState) -> bool:
	if state.season == SimState.SEASON_SPRING:
		state.season = SimState.SEASON_FALL
	else:
		state.season = SimState.SEASON_SPRING
		state.year += 1
	return state.year <= SimState.LAST_YEAR


static func is_last_turn(state: SimState) -> bool:
	return state.year == SimState.LAST_YEAR and state.season == SimState.SEASON_FALL


static func window_open(planet: String, year: int, season: int) -> bool:
	if planet in ["mercury", "venus"]:
		return true
	for w in WINDOWS[planet]:
		if w[0] == year and (w[1] == -1 or w[1] == season):
			return true
	return false


## The annual review happens at the start of every spring except the first.
static func is_review_time(state: SimState) -> bool:
	return state.season == SimState.SEASON_SPRING and state.year > SimState.FIRST_YEAR
