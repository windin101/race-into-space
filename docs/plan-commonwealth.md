# Plan: a third faction, The Commonwealth

Status: proposal, 2026-10-13. Nothing implemented yet.

The Commonwealth joins the race as a third space programme built on real British,
Australian and Commonwealth projects of the 1950s to 1970s: Black Knight and Black
Arrow, Blue Streak, ELDO, high-test peroxide (HTP) and kerosene engines, launching from
Woomera in South Australia. It plays by the same rules as the other two sides, with its
own hardware, astronauts, spaceport, art and text, and the race can be run with any two
sides or all three.

## 1. What has to change, and why it comes first

The game is written for exactly two players. Measured on 2026-10-13:

| assumption | where |
|---|---|
| `SimState.opponent(i)` returns `players[1 - i]` | used by events, the AI, reviews |
| `state.winner = 1 - p.index` when a director is dismissed | `sim_game.gd` |
| `1 - index`, `player(0)` / `player(1)`, `index == 0` | about 25 places |
| `"usa"` / `"ussr"` literals and `side == "usa"` | about 80 places in 38 files |
| per-side data keyed `usa` / `ussr` | `hardware.json`, `roster.json`, `new_game.json`, `review.json`, `event_effects.json` |
| per-side art folders | spaceport, hardware, patches; emblems, flags, rooms, portraits by side |
| prestige ledger pays `first` and `second` only | `sim_prestige.gd`, `prestige.json` |
| UI shows "the rival" as one side | top bar, Intelligence, Museum, Budget graphs, firsts cards, results |

So the work splits into a core phase that makes the game N-sided without changing any
two-player behaviour, then content and art for the new side, then interface, AI and
balance.

## 2. Design decisions

Recommended answers below; the ones marked **(decide)** need your call.

1. **Who plays (decided 2026-10-13).** New Game asks how many sides race (2 or 3) and
   which ones, then which of them the player controls; the rest are AI. The picker is
   built from the side registry, so it lists every faction installed, and the limits
   (minimum 2, maximum = sides available, capped at 3 for now by the screen layouts) live
   in data, not code. Hot-seat for several humans comes with Phase 8's hot-seat work.
2. **Prestige with three sides.** First claim pays `first`, second pays `second`, a third
   side pays the row's trickle value (the amount already paid for repeat successes). No
   new numbers are invented. **(decided 2026-10-13: as proposed)**
3. **Winning.** First side to land a crew on the Moon and return wins, as now. Only a
   human director can be dismissed, and that ends the player's game; the rival in the
   lead is recorded as the winner (in a two-side game, simply the other side).
4. **Faction identity: "on a budget".** Hardware is cheaper to open and buy (about 15%
   less), starts at lower safety (about 5 points less), and reaches the same ceilings, so
   the Commonwealth trades early reliability for money. Its starting budget sits between
   the US and USSR. Exact numbers come from balance runs (Phase 6), with the target that
   each side wins a fair share of AI-versus-AI games at equal difficulty.
   **(decided 2026-10-13: as proposed)**
5. **Look.** Blue and gold (changed from green 2026-10-13 at the player's request): gold
   accent (`#c9a227`) on a navy room tint (`#26386b`), so it stays distinct from the US
   blue. Flag: a blue ensign with the Union Jack and a gold sunburst globe. Patches are
   crowned badges in the style of an RAF station badge. Flight suits in RAF blue-grey (the
   portraits keep the green collar stripe they were painted with). The emblem and agency
   seal are fictional, as with the other two sides.
6. **Spaceport.** Woomera: red desert, gibber plain, saltbush, a dry lake on the horizon.
   It's the southern hemisphere, so in-game spring is painted with autumn light. Same
   layout solver and seasonal colour grade as the Cape and Baikonur.

## 2a. Built to take more factions later (decided 2026-10-13)

The core work is done so that a fourth side, say the European Space Research
Organisation or Japan, is added with data and art and **no code changes**:

- **One registry, `data/sides.json`.** Each side lists its id, display names, adjective,
  accent and room-tint colours, flight-suit colour, spaceport name, agency and reviewer
  titles, music keys, and which emblem, flag and art folders it uses. Code never names a
  side; it asks the registry.
- **Per-side data is keyed by side id** in the existing files (`hardware.json`,
  `roster.json`, `new_game.json`, `review.json`, `event_effects.json`, the text decks).
  A missing entry is a load-time error that names the side and the file, not a crash
  mid-game.
- **Per-side art lives in `assets/art/<kind>/<side>/`** and every art tool takes the side
  list from the registry: portraits, hardware, patches, spaceport, rooms, emblems.
- **No pairwise logic.** Rules work over "all sides" and "the other sides": firsts pay
  first, second, then the trickle for everyone after; Intelligence has a tab per rival;
  graphs and the Museum add a series or column per side.
- **Layouts with headroom.** Screens that show every side (New Game, Museum, Budget,
  results) are laid out for up to four sides even though three is the current cap, so
  raising the cap is a data change.
- **A test that adds a fake fourth side** (`test_sides_extensible.gd`): a minimal side
  defined only in test data must start a game, play twenty seasons with the AI and save
  and load. That keeps the promise honest as the code changes.

A short "Adding a faction" checklist goes into `docs/` at the end of Phase A: the
registry entry, the data blocks, the art folders and which tool generates each.

## 3. Hardware: slot by slot

Every side has the same 21 hardware slots, which is what lets missions and rules stay
shared. The names below follow your outline, and the slots it didn't cover use real
British and Commonwealth project names where one fits. Numbers start as copies of the
US entries and are then tuned (Phase 6).

| group | slot | USA | USSR | Commonwealth | notes |
|---|---|---|---|---|---|
| probes | 0 | Explorer | Sputnik | **Ariel-Alpha** | first satellite (after the real Ariel 1) |
| probes | 1 | Ranger | Cosmos | **Wayfarer** | lunar flyby / impactor |
| probes | 2 | Surveyor | Luna | **Surveyor-Dominion** | lunar soft lander |
| rockets | 0 | Atlas | R-7 | **Monarch I** | Black Knight / Black Arrow roots, HTP-kerosene |
| rockets | 1 | Titan | Proton | **Monarch II** | Blue Streak first stage + Black Arrow upper stage |
| rockets | 2 | Saturn | N1 | **Super-Monarch** | four Blue Streak engines, ELDO / Europa lineage |
| rockets | 3 | Nova | UR-700 | **Magna-Imperial** | super-heavy, five engines |
| rockets | 4 | Boosters | Boosters | **Gauntlet boosters** | strap-on HTP boosters |
| capsules | 0 | Mercury | Vostok | **Spriteship** | one-man, RAE Farnborough design |
| capsules | 1 | Gemini | Voskhod | **Highlander** | two-man, duration, EVA, docking |
| capsules | 2 | Apollo | Soyuz | **Resolve** | three-man command and service module |
| capsules | 3 | XMS-2 | Lapot | **Mustard** | minishuttle; after BAC's real 1960s MUSTARD spaceplane |
| capsules | 4 | Jupiter | LK-700 | **Sovereign** | direct-ascent lander-capsule |
| capsules | 5 | Eagle | LKM | **Endeavour** | two-man lunar module |
| capsules | 6 | Cricket | LK | **Kestrel** | one-man lunar module |
| misc | 0 | Kicker-A | Kicker-A | **Waxwing** | after the real Waxwing solid apogee motor |
| misc | 1 | Kicker-B | Kicker-B | **Gamma** | after Black Arrow's Gamma engine |
| misc | 2 | Kicker-C | Kicker-C | **Stentor** | after the real Stentor engine |
| misc | 3 | EVA suits | EVA suits | EVA suits | |
| misc | 4 | Docking | Docking | Docking | |
| misc | 5 | Photo recon | Photo recon | Photo recon | |

Cartographer, the lunar orbiter in your outline, has no slot of its own because the game
doesn't model a separate orbiter. It becomes the name used in Commonwealth newscasts
when a lunar-orbit probe mission flies.

## 4. Phases

### Phase A: N-sided core (no visible change) — done 2026-10-13

- `SimState.rivals(i)` replaces `opponent(i)`. Everything that used the one opponent
  either loops over rivals or picks the leading rival: events that target "the other
  side", intel estimates, AI threat checks.
- Win and dismissal logic for N sides (decision 3). Prestige ledger gains a third place
  (decision 2).
- The `Sides` registry from section 2a, replacing the `"usa"`/`"ussr"` literals and the
  hard-coded colour pairs in `UiPalette`.
- New Game: choose 2 or 3 sides, which ones, and which one you play (decision 1).
- The fake-fourth-side test from section 2a.
- Saves gain a version number; an old two-player save loads unchanged.
- **Gate:** the full test suite passes, and seeded two-player simulation runs produce
  identical results to today (same launches, prestige and winner over 20 seeds). That
  proves the refactor changed nothing.

### Phase B: Commonwealth data — done 2026-10-13

- `hardware.json`: the 21 slots above for both hardware models, numbers copied from US
  entries, then tuned in Phase F.
- `roster.json`: about 112 fictional candidates across five recruit groups, with names
  drawn from Britain, Australia, Canada, New Zealand, India and the wider Commonwealth.
  No real astronauts' names.
- `new_game.json`: starting cash, budget and pads.
- `review.json` and review text: the reviewer is the Prime Minister or the Minister of
  Aviation, in a Cabinet room.
- `event_effects.json` and `text/news.json`: the newscast card deck. The US and Soviet
  decks have about 80 cards each, so this is the biggest writing job. Plan: reuse each
  card's game effect, rewrite its text in a BBC-newsreader voice, and add a dozen
  Commonwealth-specific cards (a Woomera dust storm, a Treasury cut, an ELDO partner pulls
  out).
- `text/endgame.json`: win, lose and failed-objective narration.

### Phase C: Commonwealth art (local AI pipeline, same as the other sides) — done 2026-10-13

| asset | count | tool |
|---|---|---|
| Woomera spring background, plus autumn grade | 1 + 1 | `comfy_batch backdrops`, `season_grade.py` |
| spaceport buildings, pads, flag | 14 | `comfy_batch spaceport`, then `spaceport_layout.py` |
| hardware icons | 21 | `comfy_batch hardware` with new descriptions |
| portraits (blue-grey suits) | about 112 | `comfy_batch portraits` |
| mission patches (crowned RAF-style badges, navy, blue and gold) | 61 | `comfy_batch patches` |
| emblem, agency seal | 2 | `comfy_batch icons` |
| flag (Commonwealth banner, our own SVG design) | 1 | hand-drawn SVG |
| mission control room, newscast studio, review chamber | 3 | `comfy_batch backdrops` |
| endgame win and lose paintings | 2 | `comfy_batch backdrops` |
| reviewer and anchor portraits | 3 | figure prompt |

The vignettes and diagram bodies are shared by all sides. Roughly four hours of GPU time
in total, run in the background.

### Phase D: interface for three sides — done 2026-10-13 (side-picker thumbnails 2026-10-18)

- New Game styling for the side picker: flags, emblems and each side's spaceport as a thumbnail.
- Top bar: prestige for every rival on race screens. Budget graphs: one line per side.
- Intelligence: a tab per rival.
- Museum: firsts and records with a column per side.
- Launch Results and the firsts story cards: up to two rival flights per season.
- Hub themes, room tints, newscast studio and review chamber picked from the side
  registry.
- Music: the Commonwealth uses our soundtrack. The original game has no Commonwealth
  tracks, so with original music selected it falls back to ours.

### Phase E: AI for three sides — not needed

`SimAi` never read "the opponent" to decide how hard to push; its only rival read is the
cash handicap, which already loops over every rival. Its success estimate uses each
program's real safety, so the Commonwealth's lower starting safety is handled without
special cases. Three-way AI races are even (see Phase F).

Original plan:


- `SimAi` reads the leading rival rather than "the opponent" when deciding how hard to
  push, and treats the Commonwealth's cheaper, less safe hardware correctly when
  scheduling research.

### Phase F: balance — done 2026-10-13

Results and method in `docs/specs/tuning-notes.md` ("Three sides and the Commonwealth").
Balance runs found and fixed a seat bias (tie priority and seat-keyed failure tables), not
a faction problem. Runs were at level 0 only; other difficulty levels are unchecked.

Original plan:


- Batch AI-versus-AI runs with `sim_cli`, about 300 games per setup, for each pairing and
  the 3-way race at each difficulty. Tune the Commonwealth's cost and safety offsets
  until each side's win rate is within a few points of even, and check that games still
  end on time.
- Record the method and results in `docs/specs/tuning-notes.md`.

### Phase G: polish

- Newscast and review text read-through, help texts, tutorial mentions.
- Screenshots of every screen for all three sides through `ui_screenshots`; zero layout
  problems.

## 5. Effort and order

| phase | size | depends on |
|---|---|---|
| A: N-sided core | large; touches about 40 files, mostly mechanical, with the regression gate | none |
| B: data | medium; the newscast cards are most of it | A |
| C: art | medium; mostly background GPU time and review | B for names and descriptions |
| D: interface | medium | A, B |
| E: AI | small to medium | A |
| F: balance | small, but needs runs | B, E |
| G: polish | small | everything else |

Phases B and C can run in parallel once A lands, and D and E can too, so the sensible
order is A, then B with C, then D with E, then F, then G. Each phase ends with the
test suite passing and a commit, as before.

## 6. Risks

- **Two-player regressions.** Mitigated by the seeded-simulation gate in Phase A.
- **Three-way pacing.** With three sides claiming firsts, prestige spreads thinner and
  budgets grow more slowly. The balance runs in Phase F check that games still reach the
  Moon within the 1977 deadline, and the trickle rule (decision 2) is the lever if not.
- **Writing volume.** About 80 newscast cards is the long pole. Reusing each existing
  card's game effect keeps the rules safe while the text is rewritten.
- **Original music.** Has no Commonwealth tracks; the fallback to ours covers it.
