class_name TurnLogic
extends RefCounted
## Derived view logic shared by the turn, intelligence and museum screens, kept out of
## the scenes so it can be unit-tested (game/test/ui/test_turn_screens.gd).
##
## Nothing here changes game state.

const ENDGAME_NO_LANDING_FIRST := 10      ## endgame.json lines 10 (USA) / 11 (USSR)
const ENDGAME_LAST_BAND := 4


# -------------------------------------------------------------------- launch results

## A launch is shown to the human when it is theirs, or when the rival's flight claimed
## a prestige "first" (manual p.17: the other side's routine flights stay hidden).
static func launch_visible(launch: Dictionary, human_index: int) -> bool:
	if int(launch.get("player", -1)) == human_index:
		return true
	for aw in launch.get("prestige", {}).get("awards", []):
		if aw.get("kind", "") == "first":
			return true
	return false


static func visible_launches(report: Dictionary, human_index: int) -> Array:
	var out: Array = []
	for launch in report.get("launches", []):
		if launch is Dictionary and launch_visible(launch, human_index):
			out.append(launch)
	return out


# -------------------------------------------------------------------- end of game

## review.json end_game_no_landing.landing_ending_text: band 0 for year <= 65, 1 for
## 66-67, 2 for 68-69, 3 for 70-71, 4 for >= 72 (two-digit years).
static func endgame_band(year: int) -> int:
	if year <= 65:
		return 0
	if year <= 67:
		return 1
	if year <= 69:
		return 2
	if year <= 71:
		return 3
	return ENDGAME_LAST_BAND


## Line of text/endgame.json to narrate the ending for `side_index`'s reader.
## With a winner the line is band * 2 + winner; with no landing it is 10 for the USA
## and 11 for the USSR.
## winner and side are text slots (Sides.text_slot), -1 for no winner. Slots 0 and 1 use
## the upstream layout (band*2 + slot, then 10 and 11 for no landing); every later slot has
## its own block of six after them: five win bands, then its no-landing line.
static func endgame_text_index(year: int, winner: int, side_index: int) -> int:
	if winner < 0:
		if side_index >= 2:
			return 12 + (side_index - 2) * 6 + 5
		return ENDGAME_NO_LANDING_FIRST + clampi(side_index, 0, 1)
	if winner >= 2:
		return 12 + (winner - 2) * 6 + endgame_band(year)
	return endgame_band(year) * 2 + clampi(winner, 0, 1)


# -------------------------------------------------------------------- intelligence

## Intel briefing accuracy by the human's level: constants.json difficulty
## effects_game_level "(6 - level)/10 -> 60% / 50% / 40%" (upstream intel.cpp:1369-1373).
static func intel_accuracy(level: int) -> int:
	return (6 - clampi(level, 0, 2)) * 10


## Largest deviation (safety points) an estimate may have from the true value.
static func intel_max_deviation(level: int) -> int:
	return int((100 - intel_accuracy(level)) / 2.0)


## Seed for the per-turn intelligence noise: stable within a turn, different each turn.
static func intel_seed(state: SimState) -> int:
	return state.seed_value + state.turn_index()


## Estimated safety for every program the rival owns, keyed "group/slot". Estimates are
## the true safety plus deterministic noise within +-intel_max_deviation(level), clamped
## to 1..100, drawn from one SimRng seeded by intel_seed(state) in program order.
static func intel_estimates(state: SimState, rival: SimPlayer, level: int) -> Dictionary:
	var rng := SimRng.new(intel_seed(state))
	var dev := intel_max_deviation(level)
	var out: Dictionary = {}
	for prog in rival.all_programs():
		if not prog.owned:
			continue
		var noise := rng.between(-dev, dev) if dev > 0 else 0
		out["%s/%d" % [prog.group, prog.slot]] = clampi(prog.safety + noise, 1, 100)
	return out


# -------------------------------------------------------------------- annual review

## review.json portrait_rule: USA shows the President for index <= 4 or >= 11, the Vice
## President for 5..10; USSR the General Secretary for <= 4 or >= 12, the Politburo 5..11.
static func review_portrait(side: String, index: int) -> String:
	return Sides.reviewer(side, index)


## Bar colour for a review index from the review.json table ("good" / "poor").
static func review_chart_colour(review_data: Dictionary, index: int) -> Color:
	for row in review_data.get("review_index", {}).get("table", []):
		if int(row.get("index", -1)) == index:
			return UiPalette.OK if row.get("chart_colour", "good") == "good" else UiPalette.DANGER
	return UiPalette.OK if index <= SimReview.START_INDEX else UiPalette.DANGER


# -------------------------------------------------------------------- newscast

## Plain-English line for an applied event effect, or "" when there is nothing to say.
static func effect_line(news: Dictionary) -> String:
	if not news.get("applied", false):
		return ""
	var effect: String = news.get("effect", "none")
	var d: Dictionary = news.get("detail", {})
	var amt := int(d.get("amount", 0))
	var prog := str(d.get("program", "")).capitalize()
	var pad := int(d.get("pad", -1)) + 1
	match effect:
		"cash_delta", "cash_pct":
			return "%+d MB cash" % amt
		"budget_delta", "budget_pct":
			return "%+d MB budget" % amt
		"rd_mod_turn":
			return "R&D teams roll %s this season" % ("better" if amt > 0 else "worse")
		"rd_mod_year":
			return "R&D teams roll %s this year" % ("better" if amt > 0 else "worse")
		"rd_cost_up":
			return "R&D on %s now costs more per team" % prog
		"tech_steal":
			return "%s gains %d%% safety from the rival's work" % [prog, amt]
		"tech_leak":
			return "%s loses %d%% safety to the rival" % [prog, amt]
		"program_safety_delta", "program_safety_halved":
			return "%s safety %+d%%" % [prog, amt]
		"program_max_safety_up":
			return "Probe safety ceilings raised by %d%%" % amt
		"program_delay":
			return "Rocket purchases are blocked for a while"
		"program_unit_cost_up":
			return "%s units now cost more" % prog
		"pay_or_penalty":
			return "%s damaged: %d%% on its next flight unless %d MB is paid" % [prog, int(d.get("penalty", 0)), int(d.get("cost", 0))]
		"save_card":
			return "A save card protects %s" % prog
		"half_price_sale":
			return "Hardware is half price this season"
		"female_astronauts":
			return "Women may now be recruited"
		"mission_scrub":
			return "Mission on pad %d scrubbed" % pad
		"mission_delay":
			return "Mission on pad %d delayed a season" % pad
		"mission_crew_swap":
			return "Backup crew will fly the mission on pad %d" % pad
		"pad_damage":
			return "Pad %d damaged" % pad
		"astronaut_death":
			return "%s killed" % d.get("astronaut", "")
		"astronaut_injury":
			return "%s injured" % d.get("astronaut", "")
		"astronaut_retire":
			return "%s retired" % d.get("astronaut", "")
		"astronaut_recruit":
			return "%d new recruit%s joined" % [int(d.get("count", 0)), "" if int(d.get("count", 0)) == 1 else "s"]
	return ""


## Heads of state by two-digit year, used for the newscast "g" placeholder. The year
## bands are the portrait bands in review.json portrait_rule.
static func head_of_state(side: String, year: int) -> String:
	return Sides.head_of_state(side, year)


## Fill the upstream placeholder letters in an event line (event_effects.json
## "placeholders": a/d/f/i/j = the amount, b = pad ordinal, h = PRIMARY/SECONDARY/THIRD,
## c/e = program or astronaut name, g = head of state, m = the director's name).
static func resolve_placeholders(text: String, news: Dictionary, p: SimPlayer, year: int) -> String:
	var d: Dictionary = news.get("detail", {})
	var amount := absi(int(d.get("amount", d.get("cost", d.get("count", 0)))))
	var pad := int(d.get("pad", 0))
	var name := str(d.get("program", d.get("astronaut", "")))
	var ordinals := ["FIRST", "SECOND", "THIRD"]
	var pad_names := ["PRIMARY", "SECONDARY", "THIRD"]
	var values := {
		"a": str(amount), "d": str(amount), "f": str(amount), "i": str(amount), "j": str(amount),
		"b": ordinals[clampi(pad, 0, 2)], "h": pad_names[clampi(pad, 0, 2)],
		"c": name.to_upper(), "e": name.to_upper(),
		"g": head_of_state(p.side, year).to_upper(), "m": p.director_name.to_upper(),
	}
	var re := RegEx.new()
	re.compile("(?<![A-Za-z'])([a-z])(?![A-Za-z'])")
	var out := ""
	var last := 0
	for m in re.search_all(text):
		out += text.substr(last, m.get_start() - last) + str(values.get(m.get_string(1), m.get_string(1)))
		last = m.get_end()
	return out + text.substr(last)


static func news_colour(color_code: int) -> Color:
	match color_code:
		1:
			return UiPalette.OK
		2:
			return UiPalette.DANGER
	return UiPalette.TEXT


# -------------------------------------------------------------------- shared helpers

static func side_name(side: String) -> String:
	return Sides.name(side)


static func agency(side: String) -> String:
	return str(Sides.field(side, "agency", "Intelligence"))


static func mission_name(index: int) -> String:
	if index < 0 or index >= GameData.missions.size():
		return "Mission %d" % index
	return str(GameData.missions[index]["name"]).capitalize()


static func level_name(level: int) -> String:
	return str(GameData.constants.get("difficulty", {}).get("levels", {}).get(str(level), str(level))).capitalize()


static func astronaut_name(p: SimPlayer, id) -> String:
	var i := int(id)
	if p == null or i < 0 or i >= p.astronauts.size():
		return "Astronaut %s" % str(id)
	return p.astronauts[i].name


static func date_of(year: int, season: int) -> String:
	return "%s %d" % ["Spring" if season == SimState.SEASON_SPRING else "Fall", 1900 + year]
