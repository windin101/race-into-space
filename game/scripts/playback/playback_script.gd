class_name PlaybackScript
extends RefCounted
## Turns a season's launch report into the sequence of things the playback screen shows.
## Pure functions, so the sequencing is testable without a scene.

const STEP_SECONDS := 1.6
const FLASH_SECONDS := 2.2
const VERDICT_SECONDS := 2.6

const PLANET_COLORS := {9: Color("e8d9a0"), 10: Color("c9603a"), 11: Color("a8a39b"), 12: Color("d9b48a"), 13: Color("e0cf9c")}


## Launches the human should watch: own launches always, the rival's only when it took
## a first (the rest of its programme stays hidden, as in the manual).
static func visible_launches(report: Dictionary, human_index: int) -> Array:
	var out: Array = []
	for l in report.get("launches", []):
		if int(l.get("player", -1)) == human_index:
			out.append(l)
			continue
		for aw in l.get("prestige", {}).get("awards", []):
			if aw.get("kind", "") == "first":
				out.append(l)
				break
	return out


## Context the vignettes need for one launch.
static func context_for(launch: Dictionary, state: SimState) -> Dictionary:
	var pidx := int(launch.get("player", 0))
	var side := "usa" if pidx == 0 else "ussr"
	var mi := int(launch.get("mission_index", 0))
	var m: Dictionary = state.data.missions[mi] if mi < state.data.missions.size() else {}
	var ctx := {
		"side": side,
		"side_color": UiPalette.accent(side),
		"lunar": int(m.get("lunar", 0)) == 1,
		"manned": launch.get("manned", false),
		"days": _days_for(state, int(launch.get("duration_achieved", 0))),
		"planet_color": PLANET_COLORS.get(mi, Color("c9a46a")),
		"ringed": mi == 13,
	}
	return ctx


static func _days_for(state: SimState, level: int) -> int:
	var ranges: Dictionary = state.data.constants.get("duration_levels", {}).get("days_range", {})
	var key: String = ["", "A", "B", "C", "D", "E", "F"][clampi(level, 0, 6)]
	if ranges.has(key):
		return int(ranges[key][1])
	return 5


## Hardware kind for a step, for the painter (capsule, probe, lm, rocket).
static func hardware_kind(step: Dictionary) -> String:
	var hw := str(step.get("hardware", "")).to_upper()
	for probe_name in ["EXPLORER", "SPUTNIK", "RANGER", "COSMOS", "SURVEYOR", "LUNA"]:
		if hw.begins_with(probe_name):
			return "probe"
	for lm_name in ["EAGLE", "LKM", "CRICKET", "LK"]:
		if hw == lm_name:
			return "lm"
	return "capsule"


## Items to play for one launch, in order.
##   {"kind": "step", "step": {...}, "index": i}
##   {"kind": "flash", "kicker": .., "headline": .., "body": .., "color": Color}
##   {"kind": "verdict", ...flash fields}
static func sequence(launch: Dictionary, state: SimState) -> Array:
	var items: Array = []
	if launch.get("outcome", "") == "scrubbed":
		items.append({"kind": "verdict", "kicker": "Scrubbed", "headline": "Mission scrubbed",
				"body": str(launch.get("reason", "")), "color": UiPalette.WARN})
		return items
	var steps: Array = launch.get("steps", [])
	var awards: Array = launch.get("prestige", {}).get("awards", [])
	var awarded_rows: Dictionary = {}
	for aw in awards:
		if aw.get("kind", "") == "first":
			awarded_rows[int(aw["row"])] = aw
	var claimed: Dictionary = {}
	for i in steps.size():
		var st: Dictionary = steps[i]
		items.append({"kind": "step", "step": st, "index": i})
		var failure = st.get("failure", null)
		if not st.get("success", false) and failure != null:
			items.append({"kind": "flash", "kicker": "Mission Control", "headline": str(st.get("name", "Step")) + " failure",
					"body": str(failure.get("text", "")), "color": UiPalette.DANGER})
		# Announce a first on the step that earned it.
		var row := _row_for_step(st, launch, state)
		if row >= 0 and awarded_rows.has(row) and not claimed.has(row) and st.get("success", false):
			claimed[row] = true
			var title: String = state.data.prestige[row]["title"]
			items.append({"kind": "flash", "kicker": "FIRST", "headline": title,
					"body": "+%d prestige" % int(awarded_rows[row]["points"]), "color": UiPalette.GOLD})
	var total := int(launch.get("prestige", {}).get("total", 0))
	var ok: bool = launch.get("outcome", "") == "success"
	var deaths := int(launch.get("deaths", 0))
	var headline := "Mission accomplished" if ok else "Mission failed"
	if deaths > 0:
		headline = "Crew lost" if deaths > 1 else "Astronaut lost"
	items.append({"kind": "verdict", "kicker": "Verdict", "headline": headline,
			"body": "%+d prestige" % total, "color": UiPalette.OK if ok else UiPalette.DANGER})
	return items


## Best-effort: which prestige row a step corresponds to, by its letter.
static func _row_for_step(st: Dictionary, launch: Dictionary, state: SimState) -> int:
	var letter := str(st.get("letter", ""))
	var mi := int(launch.get("mission_index", 0))
	match letter:
		"B": return 18
		"C": return 0
		"D": return 27
		"H", "P": return 26
		"I": return 24
		"L": return 20
		"O": return 19
		"S": return 7
		"T": return 22
		"W":
			return {7: 1, 9: 3, 10: 4, 11: 2, 12: 5, 13: 6}.get(mi, -1)
	return -1


## Readable mission name: title case with the game's abbreviations kept.
static func mission_title(raw: String) -> String:
	var out := raw.capitalize()
	for pair in [["Jt ", "Joint "], ["Lor", "LOR"], ["Eor", "EOR"], ["Lm ", "LM "], ["Eva", "EVA"], ["(orbit)", "(Orbit)"], ["Lm$", "LM"]]:
		out = out.replace(pair[0], pair[1])
	if out.ends_with(" Lm"):
		out = out.substr(0, out.length() - 2) + "LM"
	return out


static func total_seconds(items: Array, speed: float) -> float:
	var s := 0.0
	for it in items:
		match it["kind"]:
			"step": s += STEP_SECONDS
			"flash": s += FLASH_SECONDS
			"verdict": s += VERDICT_SECONDS
	return s / maxf(speed, 0.1)
