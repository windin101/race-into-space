class_name SimProgram
extends RefCounted
## One hardware program (a rocket, capsule, probe, kicker, LM, EVA suit, docking module or
## photo recon) as owned by one side. Static numbers come from the spec record in
## hardware.json; the rest is per-game state.

const GROUPS := ["probe", "rocket", "manned", "misc"]

var group: String
var slot: int
var spec: Dictionary            ## record from hardware.json

var owned := false
var safety := 0                 ## current safety factor %
var max_rd := 0                 ## research ceiling, grows +1 per successful flight step
var max_rd_original := 0
var units := 0                  ## units in inventory (cap 6)
var delay := 0                  ## seasons during which the program cannot be bought (event cards)
var researched_this_season := false
var mission_safety := 0         ## transient: safety after mission penalties, set at launch
var flights := 0
var successes := 0
var failures := 0


static func from_spec(p_group: String, p_slot: int, p_spec: Dictionary) -> SimProgram:
	var p := SimProgram.new()
	p.group = p_group
	p.slot = p_slot
	p.spec = p_spec
	p.max_rd = p_spec["max_rd"]
	p.max_rd_original = p_spec["max_rd"]
	return p


func display_name() -> String:
	return spec["name"]


func program_cost() -> int:
	return spec["program_cost"]


func unit_cost() -> int:
	return spec["unit_cost"]


func rd_cost() -> int:
	return spec["rd_cost_per_team"]


func max_safety() -> int:
	return spec["max_safety"]


func base_safety() -> int:
	return spec["base_safety"]


func is_rocket() -> bool:
	return group == "rocket"


func is_capsule() -> bool:
	return group == "manned" and slot <= 4


func is_lm() -> bool:
	return group == "manned" and slot >= 5


func is_probe() -> bool:
	return group == "probe"


func is_kicker() -> bool:
	return group == "misc" and slot <= 2


func is_eva_suit() -> bool:
	return group == "misc" and slot == 3


func is_docking_module() -> bool:
	return group == "misc" and slot == 4


func is_photo_recon() -> bool:
	return group == "misc" and slot == 5


## Programs whose safety cannot be raised by R&D (max_rd 0): docking module, photo recon.
func can_research() -> bool:
	return owned and spec["max_rd"] > 0 and safety < max_rd


## Crew seats for capsules and LMs, 0 otherwise.
func crew_capacity() -> int:
	if group != "manned":
		return 0
	# Slots: 0 one-man, 1 two-man, 2 three-man, 3 minishuttle (3), 4 four-man,
	# 5 two-man LM, 6 one-man LM (constants crew.capacity_by_hardware).
	return [1, 2, 3, 3, 4, 2, 1][slot]


func to_dict() -> Dictionary:
	return {
		"group": group, "slot": slot, "owned": owned, "safety": safety, "max_rd": max_rd,
		"units": units, "delay": delay, "flights": flights, "successes": successes,
		"failures": failures,
	}
