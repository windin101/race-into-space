# Simulation tuning notes

How the headless simulation behaves against the only published reference curves, and
which knobs remain open. Regenerate the numbers with:

```
godot --headless --path game -s res://tools/sim_cli.gd -- --games 12 --seed 100
godot --headless --path game -s res://tools/sim_cli.gd -- --games 1 --seed 101 --verbose --trace
```

## Reference points

From the research report (`docs/reports/`): a full Let's Play on the open-source port
reported budgets of 60 MB in 1957, 80 to 95 in 1958, 111 to 141 in 1961-62 and 143 by
1969; another complete game reported an average budget of 89 MB and a final budget of
160. Historical milestones: satellite 1957, man in orbit 1961, EVA 1965, docking 1966,
lunar orbit 1968, landing 1969.

## Scripted batch, 12 games, Basic model, both sides scripted (2026-10-11)

| year | budget USA | budget USSR | prestige USA | prestige USSR |
|---|---|---|---|---|
| 1957 | 63 | 65 | 0 | 0 |
| 1958 | 70 | 71 | 0 | 0 |
| 1960 | 88 | 86 | 6 | 5 |
| 1961 | 107 | 100 | 21 | 15 |
| 1965 | 119 | 113 | 24 | 20 |
| 1969 | 132 | 109 | 45 | 32 |
| 1973 | 122 | 108 | 64 | 34 |
| 1977 | 118 | 121 | 72 | 57 |

Outcomes: 3 lunar landings (USA 1974, 1977, 1977), 9 games timed out with no landing.
A typical scripted game flies 60 to 85 missions per side.

## Reading

- **The economy matches the reference.** Budget reaches 107 by 1961 and 132 by 1969
  against the Let's Play's 111 to 141 and 143. The budget formula (prestige added each
  season, capped at 180, paid yearly) and the newscast drift need no tuning.
- **Prestige income is low** because the scripted driver flies one goal at a time and
  fails long missions often. A human in the Let's Play banks far more "firsts" by 1965.
  This is a driver limitation, not a rules problem: the per-mission awards match the
  manual's table in every tested case.
- **The driver lands about one game in four**, always five to eight years behind history.
  The slow phases are docking (the module starts at 40% and only improves by flying) and
  the 12-step lunar missions flown at 65 to 80% hardware safety. A better planner would
  test unmanned docking from the first Gemini, and hold lunar flights until 85%+.
- **No Soviet landings in 12 games.** The Basic model is symmetric and both sides run the
  same driver, so the asymmetry comes from turn order (the USA flies first on month ties
  and takes the firsts) and possibly from roster skills or the event deck's odd slots.
  Worth a dedicated batch before Phase 6.

## Project decisions already taken (differ from upstream)

- Annual review uses the intended `1 + own level` step on a bad year, not the upstream
  precedence bug.
- Downgrading a mission costs no prestige (upstream); scrubbing costs 3 (manual).
- An abort that brings the crew home is a failed mission for prestige and outcome.
- Save cards are held per player, not per program.
- Event-card damage lowers the affected hardware's safety for one flight, then clears.

## Open knobs

- Mission-success mood: spec section 14 suspects +20/+15 was intended rather than the
  +35/+30 the upstream code produces. Currently +35/+30.
- Readiness bands (A-OK at 75, Caution at 50) are a project rule; upstream thresholds are
  undocumented.
- Planetary flybys resolve in one call instead of two to seven seasons later.
- The Random hardware model is not implemented.
- The three astronaut-data levels only gate recruit stat visibility so far.
