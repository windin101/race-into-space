#!/usr/bin/env python3
"""Convert the upstream raceintospace port's gamedata JSON into this project's data files.

Usage:
    python3 -I tools/import_upstream.py --upstream reference/raceintospace --out game/data

Reads only; never executes anything from the upstream tree. Output files are plain JSON
with snake_case keys, cereal's "valueN" wrappers unrolled into lists, and BARIS text
control characters ('*' = newline, leading/trailing 'x' = string terminators) converted.

Every output file carries a "_source" block naming the upstream file it came from.
constants.json (code-derived rules) is produced separately, by hand, and is not touched.
"""

import argparse
import json
import re
import subprocess
from pathlib import Path

GROUPS = ("Probe", "Rocket", "Manned", "Misc")
SIDES = ("usa", "ussr")

# Prestige row names are not in any upstream data file; they come from the hardcoded
# string tables in src/game/endgame.cpp (PF[]) and src/game/museum.cpp (tame[]),
# in Prestige_* enum order (src/game/data.h). Transcribed via docs/upstream-reference-map.md.
PRESTIGE_ROWS = [
    "orbital_satellite", "lunar_flyby", "mercury_flyby", "venus_flyby", "mars_flyby",
    "jupiter_flyby", "saturn_flyby", "lunar_probe_landing", "duration_f", "duration_e",
    "duration_d", "duration_c", "duration_b", "one_person_craft", "two_person_craft",
    "three_person_craft", "minishuttle", "four_person_craft", "manned_orbital",
    "manned_lunar_pass", "manned_lunar_orbit", "manned_rescue_attempt",
    "manned_lunar_landing", "orbiting_lab", "manned_docking", "woman_in_space",
    "spacewalk", "manned_space_mission",
]
PRESTIGE_TITLES = [
    "Orbital Satellite", "Lunar Flyby", "Mercury Flyby", "Venus Flyby", "Mars Flyby",
    "Jupiter Flyby", "Saturn Flyby", "Lunar Probe Landing", "Duration F", "Duration E",
    "Duration D", "Duration C", "Duration B", "One-Person Craft", "Two-Person Craft",
    "Three-Person Craft", "Minishuttle", "Four-Person Craft", "Manned Orbital",
    "Manned Lunar Pass", "Manned Lunar Orbit", "Manned Rescue Attempt",
    "Manned Lunar Landing", "Orbiting Lab", "Manned Docking", "Woman in Space",
    "Spacewalk", "Manned Space Mission",
]


def unroll(obj):
    """Turn cereal's {"value0":..,"value1":..} fixed-array objects into lists, recursively."""
    if isinstance(obj, dict):
        keys = list(obj.keys())
        if keys and all(re.fullmatch(r"value\d+", k) for k in keys):
            return [unroll(obj[f"value{i}"]) for i in range(len(keys))]
        return {k: unroll(v) for k, v in obj.items() if k != "cereal_class_version"}
    if isinstance(obj, list):
        return [unroll(x) for x in obj]
    return obj


def clean_text(s: str) -> str:
    """BARIS text: '*' is a line break; a leading or trailing 'x' is a terminator."""
    if s.startswith("x"):
        s = s[1:]
    if s.endswith("x"):
        s = s[:-1]
    return s.replace("*", "\n").strip()


def source_block(upstream: Path, *files: str) -> dict:
    rev = "unknown"
    try:
        rev = subprocess.run(
            ["git", "-C", str(upstream), "rev-parse", "--short", "HEAD"],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass
    return {
        "project": "raceintospace/raceintospace (GPL-2.0-or-later)",
        "revision": rev,
        "files": [f"data/gamedata/{f}" for f in files],
        "converter": "tools/import_upstream.py",
    }


def equipment_record(slot: int, e: dict):
    if not e.get("Name"):
        return None
    # A named slot with no program cost and no safety ceiling is a placeholder for a
    # program this side cannot buy (e.g. the US Kicker-C in the Historical model).
    if e["InitCost"] == 0 and e["MaxSafety"] == 0:
        return None
    rec = {
        "slot": slot,
        "name": e["Name"],
        "base_safety": e["Base"],
        "program_cost": e["InitCost"],
        "unit_cost": e["UnitCost"],
        "rd_cost_per_team": e["RDCost"],
        "unit_weight": e["UnitWeight"],
        "max_payload": e["MaxPay"],
        "max_rd": e["MaxRD"],
        "max_safety": e["MaxSafety"],
    }
    if e.get("Duration"):
        rec["max_days"] = e["Duration"]
    return rec


def import_hardware(gd: Path, out: Path, upstream: Path):
    urast = unroll(json.load(open(gd / "urast.json"))["value0"])
    hist = unroll(json.load(open(gd / "hist.json")))
    models = {"basic": {}, "historical": {}}
    for si, side in enumerate(SIDES):
        models["basic"][side] = {
            g.lower(): [equipment_record(i, e) for i, e in enumerate(urast["P"][si][g])]
            for g in GROUPS
        }
        models["historical"][side] = {
            g.lower(): [equipment_record(i, e) for i, e in enumerate(hist[f"Data->P[{si}].{g}"])]
            for g in GROUPS
        }
    data = {
        "_source": source_block(upstream, "urast.json", "hist.json"),
        "_notes": {
            "slot": "Index within its group; upstream engine logic indexes hardware by slot, so keep it.",
            "base_safety": "Starting safety factor % when the program is bought.",
            "program_cost": "One-off purchase cost in MB.",
            "unit_cost": "Cost per unit in MB.",
            "rd_cost_per_team": "Cost per engineer team per season in MB (max 5 teams).",
            "max_payload": "Lift capacity, rockets only.",
            "max_rd": "Safety ceiling reachable by R&D.",
            "max_safety": "Safety ceiling reachable only by successful flights.",
            "max_days": "Maximum mission duration in days (capsules and LMs).",
            "null": "Empty slot.",
        },
        "models": models,
    }
    json.dump(data, open(out / "hardware.json", "w"), indent=2)
    return models


def import_prestige(gd: Path, out: Path, upstream: Path):
    urast = unroll(json.load(open(gd / "urast.json"))["value0"])
    rows = urast["Prestige"]
    assert len(rows) == len(PRESTIGE_ROWS) == 28, len(rows)
    table = []
    for i, (row, key, title) in enumerate(zip(rows, PRESTIGE_ROWS, PRESTIGE_TITLES)):
        first, second, other, failure = row["Add"]
        table.append({
            "index": i, "key": key, "title": title,
            "first": first, "second": second, "other": other, "failure": failure,
        })
    data = {
        "_source": {
            **source_block(upstream, "urast.json"),
            "row_names": "src/game/endgame.cpp PF[] and src/game/museum.cpp tame[], enum order from src/game/data.h",
        },
        "rows": table,
    }
    json.dump(data, open(out / "prestige.json", "w"), indent=2)
    return table


def import_missions(gd: Path, out: Path, upstream: Path):
    raw = unroll(json.load(open(gd / "mission.json"))["missionData"])
    downgrades = {d["mission"]: d["downgrades"] for d in json.load(open(gd / "downgrades.json"))["missions"]}
    diagram_default = None
    diagram = {}
    for line in json.load(open(gd / "missSteps.json"))["missSteps"]:
        m = re.match(r"^(\d+)\s*(.*)$", line)
        if m:
            diagram[int(m.group(1))] = m.group(2).split()
        diagram_default = line  # last line is the fallback for missing missions
    missions = []
    for r in raw:
        idx = r["Index"]
        missions.append({
            "index": idx,
            "name": r["Name"].strip(),
            "abbr": r["Abbr"].strip(),
            "code": r["Code"],
            "alt": r["Alt"],
            "alt_d": r["AltD"],
            "days": r["Days"],
            "dur": r["Dur"],
            "docking": r["Doc"],
            "eva": r["EVA"],
            "lm": r["LM"],
            "joint": r["Jt"],
            "lunar": r["Lun"],
            "m_eq": r["mEq"],
            "crew": r["mCrew"],
            "m_vab": r["mVab"],
            "prestige_categories": [c for c in r["PCat"] if c >= 0],
            "lm_ad": r["LMAd"],
            "downgrades": downgrades.get(idx, [0]),
            "diagram": diagram.get(idx, diagram_default.split() if diagram_default else []),
        })
    data = {
        "_source": source_block(upstream, "mission.json", "downgrades.json", "missSteps.json"),
        "_notes": {
            "code": "Mission step string: one letter per step; +1/+2 switch joint-launch part; ! marks end; | terminates. Letter semantics are in constants.json (step_letters).",
            "alt": "Per-step alternate/abort step index: -1 none, -2 continue, -3 end (36 slots).",
            "days": "Duration level required: 0 none, 1-6 = A-F (confirm in constants.json).",
            "prestige_categories": "Indices into prestige.json rows that this mission can claim.",
            "downgrades": "Ordered mission indices this mission falls back to when hardware is missing; 0 = none.",
            "diagram": "Future Missions bubble-diagram tokens (upstream missSteps.json).",
        },
        "missions": missions,
    }
    json.dump(data, open(out / "missions.json", "w"), indent=2)
    return missions


def import_failures(gd: Path, out: Path, upstream: Path):
    raw = unroll(json.load(open(gd / "fails.json"))["value0"])
    rows = [{
        "step": r["MissionStep"],
        "percentage": r["percentage"],
        "code": r["code"],
        "val": r["val"],
        "xtra": r["xtra"],
        "fail": r["fail"],
        "text": clean_text(r["text"]),
    } for r in raw]
    data = {
        "_source": source_block(upstream, "fails.json"),
        "_notes": {
            "step": "Failure-step code (F000.. pad/launch, F1xx capsule, F2xx/F3xx variants). Meaning of code/val/xtra/fail is in constants.json (failure_codes).",
            "percentage": "Roll band; -1 means default row.",
        },
        "failures": rows,
    }
    json.dump(data, open(out / "failures.json", "w"), indent=2)
    return rows


def import_roster(gd: Path, out: Path, upstream: Path):
    raw = json.load(open(gd / "roster.json"))
    crew_flat = unroll(json.load(open(gd / "crew.json"))["value0"])
    sides = {}
    for p in raw:
        side = SIDES[p["player"]]
        groups = []
        for gi, g in enumerate(p["groups"]):
            groups.append({
                "group": gi + 1,
                "number_to_choose": g["number_to_choose"],
                "recruiting_delay": g["recruiting_delay"],
                "candidates": [{
                    "name": e["name"].strip(),
                    # 29 entries carry an explicit "female" flag, one (Schweickart) has no
                    # sex/race/service keys at all; default to male/0/civilian.
                    "female": bool(e.get("female", e.get("sex", 0))),
                    "race": e.get("race", 0),
                    "service": e.get("service", 0),
                    "capsule": e["capsule"],
                    "lm": e["lunar"],
                    "eva": e["eva"],
                    "docking": e["docking"],
                    "endurance": e["endurance"],
                } for e in g["entries"]],
            })
        sides[side] = groups
    # Sanity: crew.json is the same people flattened.
    flat_names = sorted(c["Name"].strip() for c in crew_flat)
    roster_names = sorted(c["name"] for g in sides.values() for grp in g for c in grp["candidates"])
    if flat_names != roster_names:
        # Known: GUBARYEV/GUBAREV, KOVALYONOK/KOVALYANOK transliterations and a
        # PETERSON duplicate in crew.json vs PETERSEN in roster.json. roster.json wins.
        print("note: crew.json and roster.json name sets differ:",
              sorted(set(flat_names) - set(roster_names)), "vs",
              sorted(set(roster_names) - set(flat_names)))
    data = {
        "_source": source_block(upstream, "roster.json", "crew.json"),
        "_notes": {
            "service": "0 civilian, 1-3 service branch (upstream encoding).",
            "recruiting_delay": "Seasons before this group becomes available after the previous one; 99 = never automatically.",
            "skills": "capsule, lm, eva, docking, endurance: 0-4.",
        },
        "sides": sides,
    }
    json.dump(data, open(out / "roster.json", "w"), indent=2)
    return sides


def import_text(gd: Path, out: Path, upstream: Path):
    (out / "text").mkdir(exist_ok=True)
    ev = json.load(open(gd / "event.json"))
    events = {
        "_source": source_block(upstream, "event.json"),
        "_notes": {"color": "0 neutral, 1 good, 2 bad (upstream newscast colouring)."},
        "usa": [{"text": clean_text(e["text"]), "color": e["color"]} for e in ev["us_event"]],
        "ussr": [{"text": clean_text(e["text"]), "color": e["color"]} for e in ev["sov_event"]],
    }
    json.dump(events, open(out / "text" / "events.json", "w"), indent=2)

    nw = json.load(open(gd / "news.json"))
    news = {
        "_source": source_block(upstream, "news.json"),
        "astronaut_news": {"usa": [clean_text(s) for s in nw["astro_news"]],
                           "ussr": [clean_text(s) for s in nw["cosmo_news"]]},
        "retirement_reasons": {"usa": [clean_text(s) for s in nw["us_reasons"]],
                               "ussr": [clean_text(s) for s in nw["sov_reasons"]]},
        "filler_news": {"usa": [clean_text(s) for s in nw["us_news"]],
                        "ussr": [clean_text(s) for s in nw["sov_news"]]},
    }
    json.dump(news, open(out / "text" / "news.json", "w"), indent=2)

    rv = json.load(open(gd / "p_rev.json"))["review"]
    json.dump({"_source": source_block(upstream, "p_rev.json"),
               "_notes": {"order": "Indexed by review outcome in upstream src/game/review.cpp; see constants.json."},
               "review": [clean_text(s) for s in rv]},
              open(out / "text" / "reviews.json", "w"), indent=2)

    eg = json.load(open(gd / "endgame.json"))["text"]
    json.dump({"_source": source_block(upstream, "endgame.json"),
               "endgame": [clean_text(s) for s in eg]},
              open(out / "text" / "endgame.json", "w"), indent=2)

    hp = unroll(json.load(open(gd / "help.json"))["value0"])
    json.dump({"_source": source_block(upstream, "help.json"),
               "_notes": {"description": "Raw lines with upstream layout directives (%NN:N column, .NNN colour); strip when rendering."},
               "help": [{"code": h["Code"], "lines": h["description"]} for h in hp]},
              open(out / "text" / "help.json", "w"), indent=2)


def import_budget_table(gd: Path, out: Path, upstream: Path):
    flat = json.load(open(gd / "ntable.json"))["value0"]
    assert len(flat) == 180
    blocks = [[flat[b * 60 + band * 10:(b * 60 + band * 10) + 10] for band in range(6)] for b in range(3)]
    data = {
        "_source": source_block(upstream, "ntable.json"),
        "_notes": {
            "shape": "3 blocks x 6 budget bands x 10 random picks, per docs/upstream-reference-map.md; indexing confirmed in constants.json (budget_adjustment).",
            "bands_mb": ["0-50", "50-90", "90-110", "110-140", "140-160", "160+"],
        },
        "flat": flat,
        "blocks": blocks,
    }
    json.dump(data, open(out / "budget_adjustments.json", "w"), indent=2)


def import_new_game(gd: Path, out: Path, upstream: Path):
    u = unroll(json.load(open(gd / "urast.json"))["value0"])
    data = {
        "_source": source_block(upstream, "urast.json"),
        "start_year": 1900 + u["Year"],
        "start_season": u["Season"],
        "sides": {
            SIDES[i]: {"director_name": u["P"][i]["Name"], "starting_budget": u["P"][i]["Budget"]}
            for i in range(2)
        },
        "default_difficulty": {"usa": u["Def"]["Lev1"], "ussr": u["Def"]["Lev2"]},
        "default_astronaut_level": {"usa": u["Def"]["Ast1"], "ussr": u["Def"]["Ast2"]},
    }
    json.dump(data, open(out / "new_game.json", "w"), indent=2)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--upstream", required=True, type=Path, help="path to the raceintospace clone")
    ap.add_argument("--out", required=True, type=Path, help="output directory (game/data)")
    a = ap.parse_args()
    gd = a.upstream / "data" / "gamedata"
    if not gd.is_dir():
        raise SystemExit(f"not a raceintospace clone: {gd} missing")
    a.out.mkdir(parents=True, exist_ok=True)

    models = import_hardware(gd, a.out, a.upstream)
    prestige = import_prestige(gd, a.out, a.upstream)
    missions = import_missions(gd, a.out, a.upstream)
    failures = import_failures(gd, a.out, a.upstream)
    roster = import_roster(gd, a.out, a.upstream)
    import_text(gd, a.out, a.upstream)
    import_budget_table(gd, a.out, a.upstream)
    import_new_game(gd, a.out, a.upstream)

    n_hw = sum(1 for m in models.values() for s in m.values() for g in s.values() for e in g if e)
    n_cand = sum(len(g["candidates"]) for s in roster.values() for g in s)
    print(f"hardware: {n_hw} programs across 2 models x 2 sides")
    print(f"prestige: {len(prestige)} rows")
    print(f"missions: {len(missions)}")
    print(f"failures: {len(failures)}")
    print(f"roster: {n_cand} candidates")
    print(f"written to {a.out}")


if __name__ == "__main__":
    main()
