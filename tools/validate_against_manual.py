#!/usr/bin/env python3
"""Cross-check game/data against values read from the 1993 Rules of Play and reference card.

Usage:
    python3 -I tools/validate_against_manual.py --data game/data

The manual scans are OCR'd text with dropped digits, so this does not parse them. Instead
EXPECTED holds values a human read from the legible lines (file:line given for each) and
the script reports every mismatch. Known, accepted discrepancies are listed in KNOWN so
they are reported as "known" rather than failures.
"""

import argparse
import json
from pathlib import Path

# (section, key, expected, where-read)
EXPECTED_PRESTIGE = {
    # rules-of-play-1993.txt lines ~1218-1275, p.28 prestige table: first/second/other/failure
    "orbital_satellite": (12, 5, 1, -3),
    "lunar_flyby": (5, 3, 2, -3),
    "mercury_flyby": (5, 2, 2, -3),
    "venus_flyby": (7, 4, 2, -3),
    "mars_flyby": (7, 4, 2, -3),
    "jupiter_flyby": (8, 4, 2, -3),
    "saturn_flyby": (9, 4, 2, -3),
    "lunar_probe_landing": (16, 9, 2, -5),
    "duration_f": (7, 7, 0, 0),
    "duration_e": (5, 5, 0, 0),
    "duration_d": (1, 1, 0, 0),
    "duration_c": (5, 5, 0, 0),
    "duration_b": (3, 3, 0, 0),
    "one_person_craft": (3, 1, 0, 0),
    "two_person_craft": (7, 2, 0, 0),
    "three_person_craft": (15, 5, 0, 0),
    "minishuttle": (20, 8, 0, 0),
    "four_person_craft": (20, 8, 0, 0),
    "manned_orbital": (12, 5, 1, -10),
    "manned_lunar_pass": (12, 5, 2, -10),
    "manned_lunar_orbit": (20, 7, 1, -10),
    "manned_lunar_landing": (40, 15, 8, -10),
    "orbiting_lab": (6, 4, 0, -10),
    "manned_docking": (8, 4, 1, -3),
    "woman_in_space": (8, 0, 0, -4),
    "spacewalk": (8, 4, 1, -3),
    "manned_space_mission": (15, 5, 0, -10),
}

# Basic model, manual pp.29-31 hardware cards (rules-of-play-1993.txt ~1285-1425):
# name -> {field: value}
EXPECTED_BASIC_USA = {
    "EXPLORER": {"program_cost": 6, "rd_cost_per_team": 1, "unit_weight": 300},
    "RANGER": {"program_cost": 24, "rd_cost_per_team": 3, "unit_weight": 700},
    "SURVEYOR": {"program_cost": 30, "rd_cost_per_team": 4, "unit_weight": 1200},
    "ATLAS": {"program_cost": 24, "rd_cost_per_team": 2, "max_payload": 600},
    "TITAN": {"program_cost": 60, "rd_cost_per_team": 4},
    "KICKER-C": {"program_cost": 40, "rd_cost_per_team": 4},
    "DOCKING": {"program_cost": 18, "unit_weight": 300, "base_safety": 40},
    "PHOTO RECON": {"base_safety": 55},
}

# Reference card p.2 hardware table (players-reference-card.txt lines 196-199):
# program cost, unit, R&D, lift, Max R&D, Max Safety
EXPECTED_CARD = {
    ("basic", "usa", "ATLAS"): {"program_cost": 24, "unit_cost": 3, "rd_cost_per_team": 2, "max_payload": 600, "max_rd": 84, "max_safety": 98},
    ("basic", "usa", "TITAN"): {"program_cost": 60, "unit_cost": 12, "rd_cost_per_team": 4, "max_payload": 1500, "max_rd": 90, "max_safety": 98},
    ("historical", "ussr", "R-7"): {"program_cost": 20, "unit_cost": 3, "rd_cost_per_team": 2, "max_payload": 800, "max_rd": 85, "max_safety": 98},
    ("historical", "ussr", "PROTON"): {"program_cost": 60, "unit_cost": 12, "rd_cost_per_team": 4, "max_payload": 1900, "max_rd": 90, "max_safety": 98},
}

# Accepted differences between the printed manual and the upstream data.
KNOWN = {
    "docking max_safety": "manual p.29 says docking tops out at 98%; reference card and upstream say 93% (US) / 94% (USSR). Using upstream.",
}


def find(models, model, side, name):
    for group in models[model][side].values():
        for rec in group:
            if rec and rec["name"] == name:
                return rec
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", required=True, type=Path)
    a = ap.parse_args()
    problems = 0
    checks = 0

    prestige = {r["key"]: r for r in json.load(open(a.data / "prestige.json"))["rows"]}
    for key, (f, s, o, fail) in EXPECTED_PRESTIGE.items():
        row = prestige[key]
        got = (row["first"], row["second"], row["other"], row["failure"])
        checks += 1
        if got != (f, s, o, fail):
            problems += 1
            print(f"MISMATCH prestige {key}: data {got} vs manual {(f, s, o, fail)}")

    models = json.load(open(a.data / "hardware.json"))["models"]
    for name, fields in EXPECTED_BASIC_USA.items():
        rec = find(models, "basic", "usa", name)
        if rec is None:
            problems += 1
            print(f"MISSING basic usa {name}")
            continue
        for field, want in fields.items():
            checks += 1
            if rec[field] != want:
                problems += 1
                print(f"MISMATCH basic usa {name}.{field}: data {rec[field]} vs manual {want}")
    for (model, side, name), fields in EXPECTED_CARD.items():
        rec = find(models, model, side, name)
        for field, want in fields.items():
            checks += 1
            if rec[field] != want:
                problems += 1
                print(f"MISMATCH {model} {side} {name}.{field}: data {rec[field]} vs card {want}")

    for k, v in KNOWN.items():
        print(f"known: {k}: {v}")
    print(f"{checks} checks, {problems} mismatches")
    raise SystemExit(1 if problems else 0)


if __name__ == "__main__":
    main()
