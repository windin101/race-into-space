class_name SimAstronaut
extends RefCounted
## One astronaut or cosmonaut on a side's roster. Shared by the personnel module
## (recruiting, training, mood, retirement, crews) and the mission module (skills on
## step rolls, injury and death).

enum Status { ACTIVE, BASIC_TRAINING, ADVANCED_TRAINING, INJURED, RETIRED, DEAD }

const SKILLS := ["capsule", "lm", "eva", "docking", "endurance"]
const SKILL_MAX := 4

var id := -1                      ## index into SimPlayer.astronauts
var name := ""
var female := false
var race := 0
var service := 0

var skills: Dictionary = {"capsule": 0, "lm": 0, "eva": 0, "docking": 0, "endurance": 0}
var mood := 100                   ## 0-100
var compat := 1                   ## 1-10 on a ring
var compat_left := 1              ## CL 1-2
var compat_right := 1             ## CR 1-2

var status: int = Status.BASIC_TRAINING
var seasons_in_status := 0        ## counts up each season in the current status
var injured_until_seasons := 0    ## seasons of injury remaining
var retire_in_seasons := -1       ## countdown to retirement once decided (-1 none)
var retire_reason := ""
var death_reason := ""

var program_group := ""           ## "manned" when assigned to a capsule program
var program_slot := -1            ## which capsule/minishuttle program, -1 unassigned
var crew_index := -1              ## which crew within that program, -1 none
var crew_position := -1           ## seat 0 commander, 1, 2, 3
var seasons_in_program := 0
var previous_program_slot := -1   ## slot before the last move this season (SimPersonnel)
var seasons_active := 0           ## seasons since finishing basic training
var moved_this_season := false

var training_focus := ""          ## advanced training skill
var training_seasons_left := 0

var missions_flown := 0
var hero := false
var medals: Array[String] = []
var mission_history: Array = []   ## {year, season, mission_index, outcome}


static func from_candidate(c: Dictionary) -> SimAstronaut:
	var a := SimAstronaut.new()
	a.name = c["name"]
	a.female = c.get("female", false)
	a.race = c.get("race", 0)
	a.service = c.get("service", 0)
	for s in SKILLS:
		a.skills[s] = int(c.get(s, 0))
	return a


func skill(key: String) -> int:
	return clampi(skills[key], 0, SKILL_MAX)


func is_available() -> bool:
	return status == Status.ACTIVE


func is_alive() -> bool:
	return status != Status.DEAD and status != Status.RETIRED


func in_crew() -> bool:
	return crew_index >= 0


func clear_assignment() -> void:
	program_group = ""
	program_slot = -1
	crew_index = -1
	crew_position = -1
	seasons_in_program = 0


func status_name() -> String:
	return Status.keys()[status].to_lower()


func to_dict() -> Dictionary:
	return {
		"name": name, "female": female, "skills": skills.duplicate(), "mood": mood,
		"status": status_name(), "program_slot": program_slot, "crew_index": crew_index,
		"crew_position": crew_position, "missions_flown": missions_flown, "hero": hero,
	}
