class_name SimPlayer
extends RefCounted
## Everything one side owns: money, prestige, hardware, pads, people and plans.

const PAD_NONE := -1            ## pad not built
const PAD_OK := 0
## pads[i] > 0 means damaged with that repair cost in MB; >= 20 means destroyed (rebuild).

var index: int                  ## 0 USA, 1 USSR
var side: String                ## "usa" / "ussr"
var director_name: String
var level := 0                  ## difficulty 0 easy, 1 medium, 2 hard
var astronaut_level := 0
var is_ai := false

var cash := 0
var budget := 0
var prestige := 0               ## earned this season, folded into budget at season end
var prestige_total := 0
var prestige_history: Array[int] = []
var budget_history: Array[int] = []
var spending_this_season := 0

var programs: Dictionary = {}   ## group -> Array (7 slots; SimProgram or null)
var pads: Array[int] = [PAD_OK, PAD_NONE, PAD_NONE]
var rd_mods_turn := 0
var rd_mods_year := 0
var turn_flags: Dictionary = {} ## event-card flags for this turn, e.g. "half_price": true
var save_cards := 0
var bad_card_flags := 0         ## which filler newscast lines have been used (bits 1-14)
var last_news: Dictionary = {}   ## the newscast shown this turn

var astronauts: Array = []      ## SimAstronaut
var recruit_group := 0          ## next roster group to offer (0-4)
var recruit_delay := 0          ## seasons until the next group is available
var female_allowed := false

var duration_level := 0         ## highest duration level achieved (0 none, 1-6 A-F)
var lm_points := 0
var docking_module_in_orbit := 0   ## seasons remaining
var milestones: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0]

var missions: Array = [null, null, null]      ## this season's missions, one per pad
var future: Array = [null, null, null]        ## planned for next season
var mission_log: Array = []                   ## completed mission results
var catastrophe_flags := 0
var reviews: Array = []                        ## annual review records
var review_index := 8                          ## running review value, lower is better


static func create(p_index: int, data, model: String) -> SimPlayer:
	var p := SimPlayer.new()
	p.index = p_index
	p.side = "usa" if p_index == 0 else "ussr"
	var ng: Dictionary = data.new_game["sides"][p.side]
	p.director_name = ng["director_name"]
	p.budget = ng["starting_budget"]
	p.cash = p.budget
	for group in SimProgram.GROUPS:
		var slots: Array = []
		var specs: Array = data.hardware["models"][model][p.side][group]
		for slot in specs.size():
			slots.append(null if specs[slot] == null else SimProgram.from_spec(group, slot, specs[slot]))
		p.programs[group] = slots
	# Photo reconnaissance is never bought: upstream ships it already owned at its base safety.
	var photo: SimProgram = p.programs["misc"][5]
	if photo != null:
		photo.owned = true
		photo.safety = photo.base_safety()
	return p


func program(group: String, slot: int) -> SimProgram:
	return programs[group][slot]


func owned_programs() -> Array:
	var out: Array = []
	for group in SimProgram.GROUPS:
		for prog in programs[group]:
			if prog != null and prog.owned:
				out.append(prog)
	return out


func all_programs() -> Array:
	var out: Array = []
	for group in SimProgram.GROUPS:
		for prog in programs[group]:
			if prog != null:
				out.append(prog)
	return out


func pad_count() -> int:
	var n := 0
	for p in pads:
		if p != PAD_NONE:
			n += 1
	return n


func pad_usable(i: int) -> bool:
	return pads[i] == PAD_OK


func spend(amount: int) -> bool:
	if amount > cash:
		return false
	cash -= amount
	spending_this_season += amount
	return true


func add_prestige(points: int) -> void:
	prestige += points
	prestige_total += points
