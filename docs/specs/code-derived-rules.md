# Code-derived rules: what the upstream engine does that the data files do not say

Companion to `game/data/constants.json` (same facts as data) and `docs/upstream-reference-map.md`
section 5. All `file:line` pointers are under `reference/raceintospace/src/game/` at HEAD `e1fbccc`.
"Manual" = `original/manuals/rules-of-play-1993.txt` (1993); "RIS manual" = `doc/manual/manual.md`.
Numbers are quoted from the code; nothing here is inferred unless marked.

## 1. Prestige rows and award logic

- The 28 rows are named in code only (`endgame.cpp:50`, `museum.cpp:56`); order follows
  `enum PrestigeValues` (`data.h:1105`). `Prestige_Duration_A = -1` is deliberately absent from the
  table (Duration A earns nothing) and `Prestige_LunarMoonwalk = 40` is only a hero flag.
- `Add[0..3]` = first in the world / second nation / subsequent / failure (`prest.cpp:318-430`).
  First requires `Place == -1`; second requires `mPlace == -1` and the first was the other side;
  "subsequent" (`Add[2]`) is paid only while the running mission total is still below 3.
- A first or second on a chained row silently marks the lower rows done without paying them:
  Manned Orbital -> Orbital Satellite -> ... and Lunar Landing -> Lunar Orbit -> Pass -> Probe
  Landing -> Lunar Flyby -> Manned Orbital; Duration F -> E -> D -> C -> B; Four-Person ->
  Minishuttle -> Three -> Two -> One (`prest.cpp:432-480`).
- Failure: the single highest manned milestone attempted and failed pays `Add[3]` once
  (`NegGoal`, `prest.cpp:531`, `PrestNeg :609`). Goals never tried count as failures (`:730`).
- A death turns every success on the mission into a failure (`:718-724`); the mission total is
  floored at -10, or at -7 when nobody died (`:912-918`). Any step with `StepInfo >= 3000`
  (a death code) makes the whole mission "catastrophic" for prestige (`:647-654`).
- Every manned mission that scores a positive goal also tries row 27 Manned Space Mission
  (`:844-850`), and capsule firsts (rows 13-17) are paid per launch (`:868-888`).
- Downgrading a mission costs **0** prestige: `pNeg[plr][pad] = 1` is commented out at
  `rush.cpp:189`. **Manual differs**: "-3 prestige" (`rules-of-play-1993.txt:800`).

## 2. Milestones and the three requirement penalties

Milestones (`data.h:1137`): 0 Orbital Satellite, 1 Man in Space, 2 Earth Orbit, 3 Lunar Flyby,
4 Lunar Probe Landing, 5 Lunar Pass, 6 Lunar Orbit, 7 Lunar Landing. Mapped from prestige rows
0/27/18/1/7/19/20/22 (`prest.cpp:265`). Set when the player is first **or** second nation on
that row (`:331-427`). Which missions require which: every milestone numbered lower than the
highest milestone in the mission's `PCat[]` list is "required" - the chain is linear, there is no
per-mission table.

- **Milestone skip**: -3 safety per required milestone with `Mile == 0` (`:122-146`). Matches the
  manual (-3%).
- **Duration skip**: required level = `Days - 1`, raised to 3 (hold C) for a Lunar Pass and to 4
  (hold D) for Lunar Orbit / Landing; penalty = 5 x levels short (`:87-110`). Matches manual (-5%).
  `Days` in `mission.json` is the minimum duration level (0 unmanned, 1-6 = A-F); `Dur == 1` plans
  let the player raise it up to F (`future.cpp:884,1043`). A one-man capsule is capped at B
  (`mc.cpp:237`).
- **New mission**: 1 + own difficulty level (1/2/3) if the mission carries any unmet milestone
  (`:164-174`). **Not in the manual** as a separate item; the manual's worked example "first
  mission manned orbital = -9%" equals 2 skipped milestones (6) + new-mission 3 only on Hard.
- The three are summed, floored at 0, and subtracted from `MisSaf` of every distinct hardware
  item on the mission (`mc2.cpp:944-975`).
- **LM tests** (`prest.cpp:184-192`, `mc2.cpp:800-815`): each successful LEM-thrust-test step
  (loc 26) is 1 point; missions 48-52 (lunar-orbital LM tests) are counted twice. Fewer than 3
  points costs the LM program -9/-6/-3 for 0/1/2 points on lunar landings (mission code >= 53,
  LM ID[1] >= '5'). Matches the manual (-3 per missing point; EO test 1 pt, LO test 2 pts).
- **Docking** (`prest.cpp:756-768`, `:1083-1094`): base 40 (data), +10 on a successful docking,
  +5 on a failed one, capped at MaxSafety 93; MaxRD is 0 so it cannot be researched. Matches manual.
- **Photo recon** (`prest.cpp:709-715`, `:1060-1075`): base 55 (data); +5 for a successful manned
  lunar pass/orbit, +5 for an unmanned lunar flyby or probe whose photo step succeeded, +10 more for
  a probe that landed safely (so 15 total), cap 99. Manual says +5 / +15 / +5 for a failed lander
  that still orbited - the code gives the failed lander +5 only if its photo step (loc 20) or the
  planetary step at index 4 succeeded (`Check_Photo :195`).

## 3. Rush penalties (`rush.cpp`, `mc2.cpp:982`)

3 MB and -3 safety per month rushed, 1 or 2 months, applied to every distinct hardware item on
both launches (shared items once). Refunded if un-rushed (`rush.cpp:388-395`). Matches manual.
Default launch months (0-based, + 6 x season): one mission month 4; two: 3 and 5; three: 2, 3, 4
(`rush.cpp:558`).

## 4. Budget (`game_main.cpp:738-782`, `news_suq.cpp:87-115`)

- Start: Budget 60 (data), Cash = Budget (`game_main.cpp:468`).
- End of every season: `Budget += Prestige` for each side, then `Budget = min(Budget, 180)`;
  season prestige is zeroed.
- End of the fall season only: `Cash += Budget`; if Cash > 999 it is set to 900.
- Newscast each turn (`REvent`): Budget floored at 40, then band j by `range = {0,50,90,110,140,160}`
  (`range[k] < Budget <= range[k+1]`, j = 5 above 160) and `Budget += ntable[j*10 + rand(0..9)]`.
  `ntable.json` holds 3 blocks x 6 bands x 10; only block 0 (indices 0-59) is used, for both
  players; the +60/+120 blocks are a TODO for difficulty. Band means of block 0: +15, +2.5, +1.3,
  -0.8, -6.3, -10.
- Event card "half-price sale" (`TurnOnly == 3`) halves program and unit costs, min 1
  (`rdplex.cpp:1491`).

## 5. Difficulty effects (every `Def.Lev*` / `Def.Ast*` branch found by grep)

Game level (0 easy, 1 medium, 2 hard), per side:

| Effect | Numbers | Where |
|---|---|---|
| Mission step die | easy: `MisRandom()` = uniform 1-65, else Gaussian (mean 57, sd 31.6) clipped to 66-100; else uniform 1-100 (AI 1-98) | `mc2.cpp:493`, `mis_m.cpp:211`, `game_main.cpp:1003` |
| New-mission penalty | 1 / 2 / 3 | `prest.cpp:170` |
| Crew death | easy: hardware Safety halved; else reset to Base; MaxRD reset to original (`MSF`) | `mis_m.cpp:719` |
| R&D teams | hard: always 5 allowed; else `min(MaxRD - Safety, 5)` | `rdplex.cpp:806` |
| Intel accuracy | 60 / 50 / 40 % | `intel.cpp:1369` |
| Review on a <= -10 season | intended `+1 + level`; precedence bug makes it `+Lev1` (USA) / `+Lev2` (USSR) | `review.cpp:356` |
| Score | x1 / x2 / x3 prestige with +-1/3 cross terms; landing bonus by year 50/25, 75/50/25, 150/75/50 | `hardef.cpp:1594` |
| AI cash bonus | AI gets +25 MB injections and extra R&D only if the human is not on easy | `aimast.cpp:69,264,589` |
| Firing | review can fire a human only vs AI and when not on easy | `game_main.cpp:558` |
| `EASYMODE` flag | set when levels are 0 vs 2; never read | `mc.cpp:339` |

Astronaut level (`Ast1/Ast2`): recruit stat visibility (all: Cap+Endurance; <2: +Docking; <1:
+LM+EVA, `ast1.cpp:510`); crew-compatibility display detail (`ast4.cpp:96-158`); advanced-training
mood +5/+4/+3 per season (`start.cpp:144,218`); successful-mission mood: the code runs two
branches so USA-easy = +35, USSR-easy = +35, anything else +30 (`start.cpp:506-518`).

## 6. R&D (`rdplex.cpp`)

- 1-5 teams (`MAX_RD_TEAMS = 5`, `:59`) at `RDCost` MB each, once per program per season, only
  while `Safety < MaxRD` (`:632-650`, `:874`).
- Each team rolls `1d(6 + RD_Mods_For_Turn)`; the sum is added to Safety, capped at MaxRD
  (`:881-910`). Expected +3.5 per team at no modifier.
- Modifiers come only from event cards (`news_suq.cpp:205-224`): +1 (cards 15-18), -1 for a year
  (3, 61, 62), -2 this turn (19), -2 for a year (41), RDCost +1 on the best program (42, 43).
  Only positive year modifiers survive into the next turn (`start.cpp:729`).
- After a mission, every hardware item with a successful step gains +1 Safety (cap MaxSafety) and,
  because `cheat_addMaxS` defaults to 1, +1 MaxRD capped at MaxSafety - 2 (`mc2.cpp:859-942`).
  Docking module and photo recon are excluded from the +1 Safety.
- **Technology transfer** (`rdplex.cpp:1517-2060`): buying a new program sets its starting Safety
  from related programs: `base + min(cap, (related.Safety - threshold)/divisor)`. Probes: base 40,
  (n-40)/3.5 cap 10 from the other two, (n-40)/7 cap 5 from the orbital probe. Rockets: Atlas base
  10 (cap 25 from any other rocket); Titan base 10, cap 15 from Atlas/Boosters, cap 30 from
  Saturn/Nova, fixed 65 if both groups >= 75; Saturn base 5, fixed 60; Nova base 5, fixed 35;
  Boosters base 10 cap 20. Capsules base 5 (caps 15-35), four-man fixed 35, three-man fixed 40;
  LMs base 10 (cap 20-30 from the other LM or Jupiter); kickers base 10; minishuttle none.
- Purchases: `InitCost` opens a program (Num 1); `UnitCost` per extra unit up to 6; a program
  with `Delay > 0` (only from event cards, 2 seasons) cannot be bought (`:1380`, `:1503-1514`).

## 7. Mission step letters and tokens (`mc2.cpp:87-166`, `:188-585`; names `game_main.cpp:106`)

Tokens: `+1`/`+2` switch to launch 1/2 of a joint mission; `@x` duration step (as `b`); `%x`
orbiting-lab step (as `c`); `~nX` repeat step X n times (interplanetary coast); `!` ends the
main path (later steps are an alternate branch, prestige on them is invalidated except `L`);
`|` terminates; `I` always resets to the primary pad; `d` is an alternate-path marker that sets
the previous step's goto from `Alt[step]`.

`loc = letter - 'A'` (a..g = 26..32). Failure table key `F0xx` = loc; `F1xx/F2xx/F3xx` are
special variants (minishuttle launch/landing, Vostok landing, one-man lunar EVA, LEM after
landing, etc., `mc2.cpp:593-670`). Hardware rolled against:

| Letter | Step | Hardware | Prestige row set on the step |
|---|---|---|---|
| A | Launch | primary rocket (x boosters) | - |
| B / J / L | orbital insertion / TLI / lunar orbit insertion | kicker, else capsule, else LM, else probe-DM | B: 18 Manned Orbital; L: 20 Lunar Orbit (capsule only) |
| C | hardware power-on | kicker-C, else LM, else probe/DM | 0 Orbital Satellite (orbital probe only) |
| D E F G K M N O X Y f g | reentry, landing, EO activities, de-orbit, TEI, lunar activities, mid-course, rendezvous, corrections | capsule (kicker-C if fitted) | D: 27 Manned Space Mission; O: 19 Lunar Pass |
| H / P | orbital / lunar EVA | EVA suits | 26 Spacewalk |
| I | docking | docking module (probe-DM slot) | 24 Manned Docking (manned) |
| Q R S T | LEM activities, lunar de-orbit, landing, liftoff | kicker-C, else LM, else capsule, else probe | S: 7 Probe Landing (lunar probe); T: 22 Lunar Landing |
| U | photo reconnaissance | photo recon | - |
| V W Z e | planet orbit burn, planetary activities, trans-planetary injection, probe correction | probe | W: 1-6 by mission |
| a | LEM thrust test | LM (1 LM point each) | - |
| b / c | duration / joint duration | capsule (crew Endurance as skill; joint uses the average) | - |

`missSteps.json` tokens are Future-Missions diagram drawing commands (`futbub.cpp:145`), not rules.

## 8. Mission resolution and failure codes (`mis_m.cpp`)

- Per step: safety = hardware `MisSaf` (+ boosters combined as rocket x booster / 100 by default,
  average in classic) + crew skill 0-4 for the role, cap 99; die 1-100; failure if die > safety
  (`:313-330`, `:586-615`). A `SaveCard` (event card) cancels one failure.
- Failure type: manned steps roll 1-10000 and take the first `fails.json` row for the step whose
  `percentage` exceeds the roll (rows are cumulative upper bounds); unmanned steps roll -(1..5)
  and need an exact `percentage` match (`:95-120`, `:367`).
- `fail` is the two-digit **animation** suffix for `fseq.json` (`mis_c.cpp:126`), not an outcome;
  `code` is the outcome, `val`/`xtra` its parameters. The 35 `fail` IDs cluster by severity in the
  data: 96 -> code 0 (172 of 178 rows harmless), 97 -> codes 4/15 (abort or offer scrub), 98 ->
  safety cuts (6/26), 10/11/20/25/30 -> code 2 (mission ends), 60-64/91/99 -> code 3/17/33 (crew
  lost or dying), 15/31/55 -> 12/13 (pad destroyed), 5 -> 24 (hardware recovered, Safety cut),
  70/71/80/81/90 -> 17/23 (injury, retirement). Full code table in `constants.json`
  `failure_codes.code`. Highlights (`:782-1200`):
  0/1/8/10/11/14/20/21/27/28/29 continue; 2 ends the mission; 3/5/33 kill the crew; 4/18/23/26/40
  branch to the alternate step (`Alt`, -1 end, -2 next); 6 cuts `MisSaf` by `val`; 9/19 re-roll
  the step; 12/13 destroy the pad for `xtra`/`val` MB; 15 cuts 1-20 and offers a scrub; 16 harms
  `val`% of the crew, `xtra`% of those die; 17 retires `xtra`%, then each survives with `val`%;
  22 the EVA astronaut survives with `val`%; 24/26 cut permanent Safety by 0-9; 30 ends the
  duration; 31 kills the LM crew. Unmanned missions end on any failure.
- `StepInfo` codes: 1 success, 50 harmless, 1000-2999 abort/branch, 3000+ death, 4xxx whole crew,
  1999 scrubbed, 5000 lost probe (`mc.cpp:519-545`).
- Deaths: `Status DEAD`, reason 8; the hardware Safety is halved (easy) or reset to Base, MaxRD
  reset to its original (`:706-760`). Injury on a mission = 3 seasons; retirement = next season.

## 9. Crews (`ast4.cpp:58`, `hardware.cpp:34`, `mc.cpp:195-226`)

Capacity per program 1-5: 1, 2, 3, 3 (minishuttle), 4; LMs 2 (Eagle/LKM) and 1 (Cricket/LK).
`mCrew` in `mission.json`: 0 unmanned, 1 unmanned capsule, 2 manned, 3 joint one manned, 4 joint
both manned, 5 joint unmanned capsule. Role slots: 1 crew = commander does everything; 2 = cmdr
(capsule, docking) + #2 (LM, EVA); 3 = cmdr, #2 LM+EVA, #3 docking; 4 = cmdr, LM, EVA, docking.
LM crew is the LM specialist plus the commander for a two-person LM. A manned mission whose
primary and backup crews are gone is scrubbed.

## 10. Astronauts (`ast1.cpp`, `ast2.cpp`, `ast3.cpp`, `start.cpp`, `astros.cpp`)

- Recruiting: 20 MB for the first group, 15 after; next group available after 6/4/4/8/99 seasons
  (`ast1.cpp:636,1189`; matches `roster.json`). Each recruit: 60% chance to lose 1 Cap or
  Endurance, then 3 random points off LM/EVA/Docking (negatives floored to 0 after basic
  training); Mood 85-100; Compat 1-10 with CL, CR 1-2 (`:556-627`).
- Compatibility: A likes B if B.Compat lies in [A.Compat - CL, A.Compat + CR] on a ring of 10; not
  symmetric (`astros.cpp:102`). Each incompatible crewmate costs 3 mood per season (2 in the
  minishuttle/four-man programs).
- Basic training: 3 seasons; each season one random skill below 4 gains +1 (70%) or +2 (30%);
  5% chance per season of an incident, 75% (minus 10% per Endurance point) injury for 2 seasons,
  else retired (`start.cpp:166-205`, `:432-480`).
- Advanced training: 3 MB, 4 seasons (3 with the short option), +1 to the focus skill at season 2
  and on completion; 2 MB and entry at season 3 if the skill is already 3; blocked at 4; refunds
  3/2/1 on withdrawal (`ast2.cpp:587`, `ast3.cpp:515`). RIS manual says 2 years / +2 / 3 MB.
- Mood per season (`start.cpp:495-585`): +5 moved up a program, +5 program first (+20 more if
  the astronaut's own mission failed), +30 successful mission (see section 5), 5% chance of +5 in
  fall, +5 hero in crew; -4 six-plus seasons in the one-man program, -4 not moved, -6 not in a
  crew, -3 in a crew, -5 scrubbed, -4 injured, -5 catastrophic death (bit never set), -1..-2 card
  death, conflicts as above. Clamped 0-100.
- Retirement: Mood < 20 -> USA leaves in 2 seasons, USSR immediately (reason 13); from the 8th
  active season, every even season 10% chance (USA delay 3, USSR 2); the "scared" check after a
  mission death is unreachable because bit 1 of `MissionCatastrophicFailureOnTurn` is never set.
- Heroes: crew of a first Manned Space Mission, Woman in Space, Manned Orbital, Lunar Pass, Lunar
  Landing; the EVA specialist for a first Spacewalk / Lunar EVA (`prest.cpp:297`).

## 11. Calendar and end of game

Start spring 1957 (`Year 57, Season 0`, data); two seasons a year; the review is computed at the
start of each spring (`game_main.cpp:527`, `review.cpp:326`) from the two previous seasons;
index 1-16, 16 = fired. The game ends on the first successful Manned Lunar Landing
(`game_main.cpp:591,693`) or with no winner in fall 1977 (`:731`). Planet windows: Mars spring
60/62/64/66 and fall 69/71/73; Jupiter 60/64/68/72/73/77; Saturn 61/66/72
(`mission_util.cpp:330-370`); their flybys resolve 2/4/7 seasons later with a yearly
`rand(100) > Saf` loss test (`mc.cpp:377`, `start.cpp:803`). Launch pads: 3, 20 MB each; a
damaged pad stores its repair cost (>= 20 = destroyed).

## 12. AI knobs (names only)

`AIStrategy[10]` slots used: 0 orbital satellite, 1 end-stage location, 2 lunar module,
3 strategy (0 none / 1 / 2), 4 beginning strategy, 5 larger-rocket strategy (`data.h:444`);
plus `AILunar`, `AIPrim`, `AISec`. Difficulty cash bonus 25 MB; AI die 1-98.

## 13. Differences from the 1993 manual

| Topic | Manual | Code |
|---|---|---|
| Downgrade | -3 prestige | 0 (disabled, `rush.cpp:189`) |
| New-mission penalty | not listed; examples imply it | 1/2/3 by difficulty |
| Duration endurance formula | "-5% to -8% per step, averaged with crew endurance" | flat -5 per level; Endurance instead adds 0-4 to the duration step's safety |
| Failed lunar lander photo recon | +5 if it made a lunar orbit burn | +5 only if the photo step or step index 4 succeeded |
| Advanced training length | 2 years | 4 seasons (= 2 years) or 3 with `short_training` |
| Milestone example "-9%" | first mission manned orbital | 6 + new-mission (1-3) = 7-9 |

## 14. Not found / ambiguous

- No day count anywhere in the engine for duration levels; the A-F day table exists only in the
  manuals. Capsule `Duration` (5/14/21/15/24 days) is display-only (`ast4.cpp:287`).
- Failure `code 7` ("reduce safety permanently") only sets `StepInfo`; no Safety change found.
- `MissionCatastrophicFailureOnTurn` bit 1 is never set; the -5 mood and "scared" retirements
  that depend on it never run. Bit 2 is set by event-card deaths (`news_suq.cpp:593,626`).
- `ntable.json` blocks 1 and 2 (indices 60-179) are unused; their intended difficulty mapping is
  a TODO comment (`news_suq.cpp:109`).
- `EASYMODE` is set but never read.
- `review.cpp:356` has an operator-precedence bug; the intended rule is "+1 + level".
- The mission-success mood block adds both branches; the intended value is presumably +20 easy /
  +15 otherwise, not +35/+30.
- The AI algorithm (`aimast.cpp`, `aimis.cpp`, `aipur.cpp`) and the Random hardware generator
  (`randomize.cpp`) were not transcribed beyond their named parameters.

## 15. Event cards (`news_suq.cpp:87-777`, `news_sup.cpp:45-429`, `start.cpp:55-118`, `news.cpp:121-136,806-831`)

Full transcription: `game/data/event_effects.json` (one object per `events.json` text index).

- **Index mapping.** `Data->Events[]` holds a card *code* 0-113; the newscast shows
  `events.json` text `code + 2` (`news.cpp:166`). Texts 0 and 1 are the intro/outro lines.
- **Deck.** `InitializeEvents` deals one shared sequence of 100 slots at game start, no reshuffle.
  Slots 0-1 are code 0 (opening card, both players, Spring 1957). Slots 2-99 are filled in six
  periods of 2, 8, 8, 12, 16, 52 cards from five pools (codes 1-3, 4-43, 44-62, 63-79, 80-99) by
  cumulative percentages per period: {100,100,100,100,100}, {0,100,...}, {0,62,100,...},
  {0,50,70,100,100}, {0,35,55,75,100}, {0,25,50,75,100}; an empty pool is re-rolled. Cards are
  removed from the pool when dealt, so every code appears at most once per game, for one side only.
- **Draw.** Each player reads slot `2 * (2 * (Year - 57) + Season) + player` at the start of their
  turn (`game_main.cpp:643`), USA even, USSR odd (swapped by `MAIL_INVERTED`). The AI side draws the
  same way without a broadcast. The game ends at slot 83; slots 84-99 are dealt but unread.
- **Gates.** No difficulty gating. Year gates in `REvent`: code > 44 needs 1961, > 63 needs 1963,
  > 80 needs 1966; an early draw is a bad card. The budget drift of section 4 runs first, always.
- **Bad cards.** A card whose precondition fails (nothing owned, nothing scheduled, nobody alive,
  year gate) returns 1. `ResolveEvent` then picks a filler slot 1-14 not yet set in
  `BadCardEventFlag[15]` (cleared after 30 misses), overwrites the slot with code `99 + slot`, and
  the broadcast shows filler text 102-115. The flag only prevents repeated filler; it never changes
  what is drawn. Nothing lets a player force, skip or redraw a card.
- **Timing.** News runs before crew checks, the damage-repair prompt and the turn proper
  (`game_main.cpp:608-618`), so R&D modifiers, the half-price sale, scrubs and delays hit the turn
  being played. `RD_Mods_For_Turn` and `TurnOnly` are zeroed at season end (`start.cpp:728-735`).
- **Effect families** (counts over codes 0-99): none 23 (plus 14 filler, 1 unreachable);
  R&D die +1 this season 9, -1 or -2 "for a year" 4 (one season in practice: only positive year
  mods carry over), RDCost +1 permanent 2; budget +15/+5/+20/+2d10/-5 and -20%/-30%/-25% capped
  at 20/30/25 MB; cash +1d10, +3d6, -10%; safety +4d6/+6d6 or -25/-20/-15 points on the most
  advanced program of a group 9; "pay N MB or -X% on the next mission" 8 (the only player
  choice, via `Damage`/`DCost`); save card 4; half-price sale 2; rocket or capsule purchase
  delay 2 seasons; two-man/three-man capsule UnitCost +2/+3; pad repair cost 15 (pad 1) or 10
  (random idle pad); mission scrub, delay, or primary-crew swap; astronaut death 2, injury 2,
  retirement 2, three free recruits, female astronauts allowed; tech steal/leak against the rival.
- **"Most advanced"** always means the highest equipment index passing the test, in the order
  probes < rockets < capsules < misc, so the all-programs cards (40, 42/43, 79) hit EVA suits or a
  kicker before a capsule. Capsule safety cards (22, 26, 34, 84, 94) include the LMs; damage and
  save-card capsule groups do not. The "LEM" save card (93) covers the four-man capsule too.
- **Side differences.** Same effect per code for both sides; only the retirement cards (49, 89:
  USSR retires at once, USA after two season-ends) and the bonus astronauts' names/stats differ.

**Not found / quirks**

- Code 4 (next launch must be manned, +10 MB): only statement is commented out; no effect.
- Code 58 (50% pad explosion): sets `TurnOnly = 5`, consumer at `mc2.cpp:488` is commented out.
- Code 82 (extra Duration E required): sets `FuturePlans = 5`, which nothing reads.
- Code 35 (one launch only): pad bits are `i*2` not `1<<i`, so it only ever scrubs pad 3 when
  pads 2 and 3 are both scheduled; otherwise a bad card.
- Codes 3, 41, 61, 62 "for a year": `RD_Mods_For_Year` negative values are never applied.
- Code 20 shows the amount removed where the text says "down to i%".
- Code 114 (text 116) is unreachable. `TurnOnly` values 1, 2, 4, 6 and `FuturePlans` 1-4 in the
  `data.h` comments are never set by any card.
