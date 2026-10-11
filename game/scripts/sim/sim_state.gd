class_name SimState
extends RefCounted
## The whole game: calendar, both players, the shared prestige ledger and the RNG.
## Pure data plus small accessors; rules live in the static modules (SimEconomy etc.).

const SEASON_SPRING := 0
const SEASON_FALL := 1
const FIRST_YEAR := 57
const LAST_YEAR := 77

var data                        ## GameData (autoload or a test instance)
var rng: SimRng
var seed_value: int
var model: String               ## "basic" or "historical"
var options: Dictionary

var year := FIRST_YEAR          ## two-digit, 57..77
var season := SEASON_SPRING
var players: Array[SimPlayer] = []

## One entry per prestige row: who was first/second and when. -1 = nobody yet.
var prestige_rows: Array = []

var ended := false
var winner := -1                ## player index, or -1 for no winner
var end_reason := ""
var turn_log: Array[String] = []   ## human-readable event log for the current turn


func _init(p_data, p_seed: int = 0, p_options: Dictionary = {}) -> void:
	data = p_data
	seed_value = p_seed
	rng = SimRng.new(p_seed)
	options = p_options
	model = p_options.get("model", "basic")
	for i in 2:
		var p := SimPlayer.create(i, data, model)
		p.level = p_options.get("level_%s" % p.side, 0)
		p.astronaut_level = p_options.get("astronaut_level_%s" % p.side, 0)
		p.is_ai = p_options.get("ai_%s" % p.side, i == 1)
		players.append(p)
	for i in data.prestige.size():
		prestige_rows.append({"first": -1, "second": -1, "first_year": 0, "first_season": 0})


func player(i: int) -> SimPlayer:
	return players[i]


func opponent(i: int) -> SimPlayer:
	return players[1 - i]


## 0 for Spring 1957, 1 for Fall 1957, ... 40 for Spring 1977, 41 for Fall 1977.
func turn_index() -> int:
	return (year - FIRST_YEAR) * 2 + season


func full_year() -> int:
	return 1900 + year


func season_name() -> String:
	return "Spring" if season == SEASON_SPRING else "Fall"


func date_string() -> String:
	return "%s %d" % [season_name(), full_year()]


func constants() -> Dictionary:
	return data.constants


func note(msg: String) -> void:
	turn_log.append(msg)
