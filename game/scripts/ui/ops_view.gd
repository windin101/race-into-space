class_name OpsView
extends RefCounted
## Derived view logic shared by the operations screens (Research, Program Offices,
## Launch Pad, Vehicle Assembly, Mission Control). Pure functions over sim state so the
## screens stay thin and the numbers they show can be unit tested. Every rule number is
## read from the rule modules; nothing here is a tunable of its own.

const MONTH_NAMES := ["January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December"]
const MONTHS_PER_SEASON := 6
const ROLE_TITLES := {"cap": "Capsule", "lm": "LM", "eva": "EVA", "dock": "Docking"}
const CREW_TITLES := ["Primary", "Backup"]


# --- launches and months -------------------------------------------------------------

## Pads with a primary (part 1) mission scheduled this season, in pad order. This is the
## order SimGame uses to hand out launch months.
static func scheduled_pads(p: SimPlayer) -> Array:
	var pads: Array = []
	for pad in 3:
		if p.missions[pad] != null and p.missions[pad].get("part", 1) == 1:
			pads.append(pad)
	return pads


## Launch month (0-based within the season) for the mission in `position` of
## `n_scheduled` launches, less the rush months, as SimGame._ordered_launches computes it.
static func launch_month(n_scheduled: int, position: int, rush_months: int) -> int:
	var months: Array = SimGame.DEFAULT_MONTHS.get(n_scheduled, SimGame.DEFAULT_MONTHS[1])
	var base: int = months[clampi(position, 0, months.size() - 1)]
	return maxi(0, base - rush_months)


## Calendar name of a season-relative month: 0 is January in spring and July in fall.
static func month_name(month: int, season: int) -> String:
	var m := month + (MONTHS_PER_SEASON if season == SimState.SEASON_FALL else 0)
	return MONTH_NAMES[clampi(m, 0, MONTH_NAMES.size() - 1)]


## Launch month name for the primary mission on `pad` this season.
static func launch_month_name(state: SimState, p: SimPlayer, pad: int) -> String:
	var pads := scheduled_pads(p)
	var position := pads.find(pad)
	if position < 0:
		return ""
	var rush: int = int(p.missions[pad].get("rush_months", 0))
	return month_name(launch_month(pads.size(), position, rush), state.season)


static func rush_label(months: int) -> String:
	if months == 0:
		return "No rush"
	return "%d month%s earlier  (%d MB, -%d%%)" % [months, "" if months == 1 else "s",
		months * SimPlanner.RUSH_COST_PER_MONTH, months * SimPlanner.RUSH_PENALTY_PER_MONTH]


## Missions the plan may be flown as: the planned one first, then its downgrade chain.
## A joint plan keeps joint alternatives and a single-pad plan keeps single-pad ones, so
## the second pad of a joint mission is never left dangling.
static func downgrade_options(state: SimState, pl: Dictionary) -> Array:
	var out: Array = [int(pl["mission_index"])]
	var joint: bool = pl.get("joint", false)
	for alt in SimPlanner.mission_def(state, int(pl["mission_index"]))["downgrades"]:
		if int(alt) == SimPlanner.MISSION_NONE:
			break
		if (SimPlanner.mission_def(state, int(alt))["joint"] == 1) != joint:
			continue
		if not out.has(int(alt)):
			out.append(int(alt))
	return out


# --- research ----------------------------------------------------------------------

## Die size for this season's R&D rolls.
static func rd_die(p: SimPlayer) -> int:
	return maxi(1, SimHardware.RD_DIE + p.rd_mods_turn)


## Average safety gain from `teams` teams each rolling the season's die.
static func expected_gain(teams: int, rd_mods_turn: int) -> float:
	var die := maxi(1, SimHardware.RD_DIE + rd_mods_turn)
	return teams * (die + 1) / 2.0


static func expected_gain_text(teams: int, rd_mods_turn: int) -> String:
	var die := maxi(1, SimHardware.RD_DIE + rd_mods_turn)
	return "Expected gain about +%.1f%%  (%d team%s x %.1f average on 1d%d each)" % [
		expected_gain(teams, rd_mods_turn), teams, "" if teams == 1 else "s", (die + 1) / 2.0, die]


## Why a program cannot take teams this season, or "" when it can.
static func research_block_reason(p: SimPlayer, prog: SimProgram) -> String:
	if not prog.owned:
		return "Not owned."
	if prog.spec["max_rd"] <= 0:
		return "This hardware cannot be improved by research."
	if prog.researched_this_season:
		return "Teams have already been assigned this season."
	if prog.safety >= prog.max_rd:
		return "Already at Max R&D; only flights can raise it further."
	if SimHardware.max_teams(p, prog) <= 0:
		return "No teams can be assigned this season."
	return ""


# --- hardware descriptions -----------------------------------------------------------

static func kind_name(prog: SimProgram) -> String:
	if prog.is_rocket():
		return "Rocket"
	if prog.is_capsule():
		return "Capsule"
	if prog.is_lm():
		return "Lunar module"
	if prog.is_probe():
		return "Probe"
	if prog.is_kicker():
		return "Kicker"
	if prog.is_eva_suit():
		return "EVA suits"
	if prog.is_docking_module():
		return "Docking module"
	return "Photo recon"


## Every distinct program on an assembled launch (rockets, boosters and payload).
static func launch_programs(launch: Dictionary) -> Array:
	var out: Array = []
	for v in launch.get("vehicles", []):
		var items: Array = [v["rocket"], v["boosters"]]
		for k in v["payload"]:
			items.append(v["payload"][k])
		for prog in items:
			if prog != null and not out.has(prog):
				out.append(prog)
	return out


## Payload items of one vehicle as {name, weight, program}, in payload order.
static func payload_items(vehicle: Dictionary) -> Array:
	var out: Array = []
	for k in vehicle["payload"]:
		var prog: SimProgram = vehicle["payload"][k]
		if prog != null:
			out.append({"name": prog.display_name().capitalize(), "weight": int(prog.spec.get("unit_weight", 0)), "program": prog})
	return out


static func payload_weight(vehicle: Dictionary) -> int:
	var w := 0
	for item in payload_items(vehicle):
		w += int(item["weight"])
	return w


static func lift(vehicle: Dictionary) -> int:
	var total: int = int(vehicle["rocket"].spec["max_payload"])
	if vehicle["boosters"] != null:
		total += int(vehicle["boosters"].spec["max_payload"])
	return total


static func rocket_name(vehicle: Dictionary) -> String:
	var s: String = vehicle["rocket"].display_name().capitalize()
	if vehicle["boosters"] != null:
		s += " + " + vehicle["boosters"].display_name().capitalize()
	return s


## Role names carried by each seat of a capsule with `capacity` seats, from the
## personnel module's default seat table.
static func seat_roles(capacity: int) -> Array:
	var out: Array = []
	var table: Dictionary = SimPersonnel.ROLE_SLOTS_DEFAULT.get(capacity, {})
	for seat in capacity:
		var roles: PackedStringArray = []
		for key in ROLE_TITLES:
			if table.get(key) != null and int(table[key]) == seat:
				roles.append(ROLE_TITLES[key])
		out.append(", ".join(roles))
	return out


## "Primary", "Backup", then "Crew 3"...
static func crew_title(crew_index: int) -> String:
	if crew_index >= 0 and crew_index < CREW_TITLES.size():
		return CREW_TITLES[crew_index]
	return "Crew %d" % (crew_index + 1)


static func crew_lines(vehicle: Dictionary) -> Array:
	var out: Array = []
	var crew: Array = vehicle["crew"]
	var capsule: SimProgram = vehicle["payload"]["capsule"]
	var roles := seat_roles(capsule.crew_capacity()) if capsule != null else []
	for i in crew.size():
		var a: SimAstronaut = crew[i]
		var role: String = roles[i] if i < roles.size() else ""
		var seat := "Commander" if i == 0 else "Seat %d" % (i + 1)
		out.append("%s: %s%s" % [seat, a.name.capitalize(), ("  (%s)" % role) if role != "" else ""])
	return out


## Readiness as text and colour for an assembled launch.
static func readiness_text(launch: Dictionary) -> String:
	var r := SimPlanner.readiness(launch)
	return "%s  %d%%" % [str(r["band"]).to_upper(), int(r["lowest_safety"])]


static func readiness_color(launch: Dictionary) -> Color:
	return UiPalette.safety_color(int(SimPlanner.readiness(launch)["lowest_safety"]))


# --- auto purchase -------------------------------------------------------------------

## Programs the plan would use that have no unit in inventory. Assembly only considers
## stocked hardware, so the list is found by assembling as if every owned program had a
## unit and keeping those that really have none. Inventory is restored before returning.
static func shopping_list(state: SimState, p: SimPlayer, pl: Dictionary) -> Array:
	var empty: Array = []
	for prog in p.owned_programs():
		if prog.units == 0 and not (prog.is_eva_suit() or prog.is_photo_recon()):
			empty.append(prog)
			prog.units = 1
	var launch := SimPlanner.assemble(state, p, pl)
	for prog in empty:
		prog.units = 0
	var out: Array = []
	if launch.has("vehicles"):
		for prog in launch_programs(launch):
			if empty.has(prog):
				out.append(prog)
	return out


## Buy one unit of each program on the list. Returns the ones that could not be bought.
static func auto_purchase(p: SimPlayer, programs: Array) -> Array:
	var failed: Array = []
	for prog in programs:
		if not SimHardware.buy_unit(p, prog):
			failed.append(prog)
	return failed
