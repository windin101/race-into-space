# BARIS: Core Game Structure and Economy (design reference)

Scope: how a game of Buzz Aldrin's Race Into Space (Interplay / Strategic Visions, 1993) is structured from the player's point of view, and how its economy and progression work, with exact numbers where documentation gives them.

Primary sources recovered (all documentation, no source code):

- **MANUAL** – the original 51-page floppy-edition "Rules of Play" by Fritz Bronner (PDF scan with text layer, 7.2 MB), hosted at [oldgames.sk download 1988](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988). Page numbers below are the manual's own.
- **REFCARD** – the 3-page "Player's Aid / Reference Card" (hardware & R&D cost tables for Basic and Historical models, prestige table, duration bands, skip penalties, 57-mission list, keyboard map), hosted at [oldgames.sk download 5387](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/5387).
- **CDMAN** – the CD-edition text manual (~3,000 words, a condensed version of MANUAL with the same numbers), at [oldgames.sk download 5388](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/5388).
- **LP** – a 49-part 2011 Let's Play (both sides played, with per-turn hardware/budget tables) at [lparchive.org](https://lparchive.org/Buzz-Aldrins-Race-Into-Space). Note: the LP was played on the fan Windows port, not the DOS original, so its numbers are corroborating evidence, not primary.
- Reviews/forums: [COMPUTE! Oct 1993](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php), [Space Sector 2013 review](https://www.spacesector.com/blog/?p=9465), [Scientific Gamer](https://scientificgamer.com/in-praise-of-buzz-aldrins-race-into-space), [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space), [Orbiter-Forum AAR](https://webmail.orbiter-forum.com/goto/post?id=336463) and [follow-up post](https://webmail.orbiter-forum.com/goto/post?id=336467), [Home of the Underdogs](https://www.homeoftheunderdogs.net/game.php?id=160), [elisoftware.org CD box listing](https://elisoftware.org/wiki/Buzz_Aldrin%27s_Race_Into_Space_(PC,_CD-ROM)_Interplay_Productions_-_1993_USA,_Canada_Release), [oldgames.sk game page](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space).

Cleanroom compliance note: I did not open GitHub/SourceForge, any fork or port repository, or any extracted data file. The archive.org software items were inspected only at the metadata (file-listing) level and their zips were not opened. `raceintospace.org` is now a squatted spam domain with no game content ([checked](https://www.raceintospace.org/)). The KSP forum thread and the Orbiter-Forum thread index returned HTTP 403; only the two individual Orbiter posts above were readable.

---

## 1. Turn structure, phase order, and end-of-game

### Takeaway
A turn is one six-month season (Spring/Fall), from Spring 1957 to a Spring 1977 cut-off (max 41 seasons). Each player's turn runs: Turn Announcement, Network News, free-order spaceport actions, Mission Control (launch resolution of missions scheduled the previous season), then lowering the flag. The first manned lunar landing and safe return wins; dismissal by the Capitol/Politburo at Level 2–3 vs the computer loses.

### Cited Findings
- "Each turn, or season, is six months in length. The game begins in Spring 1957. You have until Spring 1977 to complete your victory conditions; successfully landing astronauts on the moon, and returning them safely to the Earth." — [MANUAL p.4](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- "The first country to successfully complete a manned lunar landing and return to Earth wins the game." — [MANUAL p.1](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Player one (the side listed first; the US in the default setup) takes the first turn each season; the default configuration is "Level One U.S. Human player vs. a Soviet Computer opponent"; options are US Human vs Soviet Human, US Human vs Soviet Computer, US Computer vs Soviet Human. — [MANUAL p.3](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Phase order within a player's turn, as laid out by the manual's section order and its "Suggested Mission Director's Checklist" (p.39): (1) Turn Announcement; (2) Network News (Space News, Astronaut News, World Events); (3) Spaceport, in any order: Purchase hardware (Administration), R&D (Research Park), Plan future missions (Administration), Astronaut management (Complex, program buildings, training), Review Presidential approval / intelligence / budget / museum; (4) VAB/VIB assemble payloads+rockets for this season's launches; (5) Mission Control launch review, decide rush/downgrade/scrub; (6) End Turn by clicking the flag. — [MANUAL p.39](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988); same sequence in [CDMAN](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/5388)
- "If you have missions scheduled this season, you'll be directed to go to Mission Control to confirm launches. You can then end your turn by lowering the flag." — [MANUAL p.19](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Missions are always planned one season ahead: "All space missions must be planned one season in advance. If it is Spring you will be scheduling space missions for the Fall season. On the first turn of the game, Spring 1957, it would be impossible to launch any missions until the Fall 1957." — [MANUAL p.9](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Launch month within the season (Figure 2, "Launch scheduling"): one scheduled launch flies in the 5th month of the next season; two independent single launches fly in the 4th and 6th months; three singles fly 3rd, 4th, 5th; a joint launch (two pads) flies in the 5th; a single plus a joint fly 4th (single) and 6th (joint). — [MANUAL p.10](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988) (figure text is partly OCR-garbled; the first three rows are legible)
- Missions scheduled in a season "always happen the next season". — [LP Update 01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001)
- Launches of both sides resolve between turns and are shown as video with a bar chart of rolls. — [Space Sector](https://www.spacesector.com/blog/?p=9465)
- You only see the computer opponent's mission footage "if it has a successful prestige first"; its normal missions and failures are kept secret. — [MANUAL p.17](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Capitol/Politburo review happens once a year: "A successful year can bring praise and increases in funding, while failure can cause great disappointment. At Level 1 difficulty, if your performance is extremely poor, the President will suggest you retire. At higher levels against a computer opponent, a poor performance will result in dismissal and end the game. Human vs. Human only suggests dismissal. A chart displays your recent prestige swings. As in real life, public opinion of the government moves slowly." — [MANUAL p.15](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Difficulty text repeats: "do badly enough on Level 2 or 3 and you can get fired, which loses the game." — [MANUAL p.3](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- The game ends when someone lands on the Moon, at the end of 1977, or when a player is dismissed ("rare, and only for a human player doing essentially nothing"). — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- "The game ends in 1977 or when someone lands on the Moon, allowing at most forty turns... If your opponent reaches the Moon first, it is game over." — [Scientific Gamer](https://scientificgamer.com/in-praise-of-buzz-aldrins-race-into-space)
- Director's Rating Chart (Space Museum): "The country listed at the top is the declared victor. Your total points will vary depending on game level." — [MANUAL p.14](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- A completed US game reported a "Director Rating at end of game: 204 pts" after a Spring 1969 landing, with 29 missions flown. — [Orbiter-Forum AAR](https://webmail.orbiter-forum.com/goto/post?id=336463)
- COMPUTE!: "single turns, each equal to six months' time, for a maximum of 20 years"; "Fall too far behind, and you'll be fired." — [COMPUTE!](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- LP end-state (two different games): Real-world game US 9 firsts / 112 prestige vs USSR 8 / 93; mirror game US 8 / 72 vs USSR 9 / 134; final gap in the main game "less than 20 points". — [LP index](https://lparchive.org/Buzz-Aldrins-Race-Into-Space), [LP Update 49](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2049)
- Mission scale as marketed: "over 12,000 possible missions, or about 50 million outcomes once failure modes were included"; development 28 months; shipped March 1993; CD-ROM 1994 added footage and multiplayer modes. — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)

### Inferences
- Spring 1957 to Spring 1977 inclusive is 41 seasons; sources variously say "40 turns"/"20 years". A reimplementation should allow the Spring 1977 turn to be played (the manual says "until Spring 1977").
- Because the manual only ever describes a win by landing, and the Director's Rating chart "declares" a victor, the most defensible rule for the no-landing-by-1977 case is: higher Director's Rating / prestige wins (inferred, not documented).
- The computer opponent's turn appears to be resolved invisibly between the human's turns; the only visible artefacts are news items, intelligence reports and prestige-first footage (inferred from MANUAL p.17 and the Space Sector review).

### Gaps
- No source states what happens if neither side lands by Spring 1977, or how ties in prestige are broken.
- No source gives the formula behind the Director's Rating, beyond "varies depending on game level".
- The exact point at which the computer's missions resolve relative to the human's (before or after the human's Mission Control) is not documented.

---

## 2. Budget and money

### Takeaway
Currency is the "MegaBuck" (MB). Both sides start at 60 MB. Funding is granted annually (each Spring, after the Capitol/Politburo review) and scales with prestige/performance; documented figures from play run from 60 MB in 1957 to roughly 110–160 MB per year by the mid/late 1960s. No published formula exists.

### Cited Findings
- "A megabuck or MB was designed as the universal monetary standard." — [MANUAL p.2 Designer's Notes](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- "Your budget starts at 60 MB." — [MANUAL p.6](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988); confirmed "60 MegaBucks... the standard starting budget for all space programs" and the Soviets also start with 60 MB in the Basic model — [LP Update 01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001), [LP Update 03](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2003)
- Funding cadence: "The budget is granted once a year, every Spring. Money spent in Spring is all you have for the year." — [LP Update 01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001); "Funding arrives at the start of every year and depends on how well the program is doing." — [Space Sector](https://www.spacesector.com/blog/?p=9465)
- Prestige drives funding: "Prestige raises your ratings and increases funding." — [COMPUTE!](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php); "You receive a yearly budget. Its size depends on your prior achievements and accumulated prestige." — [Scientific Gamer](https://scientificgamer.com/in-praise-of-buzz-aldrins-race-into-space); "A successful year can bring praise and increases in funding" — [MANUAL p.15](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Budget Office shows: comparative past prestige vs opponent; expenditures by category (Satellites, Manned Spacecraft, Rocket, Miscellaneous Hardware); history of your budget plus your intelligence agency's estimate of the opponent's budget; the CD text adds "projected budget". — [MANUAL p.6](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Observed US budgets in one playthrough (available funds at start of the season, Basic model, Level 1): Spring 1957: 60; Spring 1958: 80/90/95 depending on an event decision; Spring 1961: 111 and 113; Fall 1961 remaining: 58; Spring 1962: 141; Fall 1963: 81; Spring 1965: 128; Fall 1965: 47; Spring 1966: 127 (+8 from a news event); Fall 1966: 68 ("extra money from news"); Spring 1967: 128; Spring 1969: 143. — [LP 01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001), [LP 06](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2006), [LP 14](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2014), [LP 18](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2018), [LP 20](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2020), [LP 22](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2022), [LP 28](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2028), [LP 34](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2034), [LP 36](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2036), [LP 38](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2038), [LP 40](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2040), [LP 42](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2042), [LP 48](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2048)
- Soviet side, same playthrough: Spring 1967: 116 MB after a successful Venus flyby; Fall 1967: 5 MB left after setting up a mission. — [LP Update 43](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2043)
- A different full US game reported "Average budget: 89 MB; Last year's budget: 160 MB" (1957–1969). — [Orbiter-Forum AAR](https://webmail.orbiter-forum.com/goto/post?id=336463)
- Money sinks with fixed prices: rushing a launch 3 MB per month (1 or 2 months); advanced training 3 MB per astronaut; launch pads; astronaut groups; hardware program initial cost, unit cost and R&D cost per team (tables in section 4). — [MANUAL pp.17, 21](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Extra pads cost 20 MB each (up to two more), "and this price never increases". — [LP Update 01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001)
- Astronaut group costs seen: Group I (Spring 1958) 7 astronauts for 20 MB from 11 candidates; a later class 15 MB for 9 of 18 candidates. — [LP Update 06](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2006), [LP Update 18](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2018)
- "Pay for safety" style events debit the budget: paying 10 MB up front avoids a 10% safety penalty on the Atlas's next mission (Spring 1958); a Titan "Pay or Safety" decision cost 10 MB (141 shown as 131) in Spring 1962. — [LP Update 06](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2006), [LP Update 22](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2022)
- Historical Model: "American hardware has a higher cost and better reliability and Soviet hardware is less expensive and has worse reliability." — [MANUAL p.3](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Strategy advice confirming the economy loop: "Success breeds confidence and more support, meaning funding and growth... Get that budget up with several unmanned missions." — [MANUAL pp.35, 37](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)

### Inferences
- The budget is an annual grant, credited at the Spring turn; the Fall figures in the LP are unspent balances carried within the year, so money carries over season to season (the Fall 1961 "58 left" and Fall 1963 "81 to work with" are consistent with this).
- A plausible modelling envelope: 60 MB year 1, rising roughly linearly with cumulative prestige to ~110–145 MB by years 5–12, with occasional +/- event adjustments of single-digit MB; 160 MB is the highest documented single-year grant.
- The Historical Model's cost differences are fully enumerated in the REFCARD table (section 4) rather than a global multiplier.

### Gaps
- No source gives the budget formula (base, prestige multiplier, difficulty modifier, or how "public opinion moves slowly" is implemented).
- Whether the Soviets get "slightly more seed money" in the Historical model (one LP remark) is unconfirmed; in the Basic model both start at 60.
- Launch-pad repair cost is not stated anywhere I found.

---

## 3. Prestige: earning, losing, and the firsts table

### Takeaway
Prestige is scored per mission against a 27-row table with columns 1st / 2nd / Other / Failure. The biggest awards are Manned Lunar Landing (40/15/8/−10), Manned Lunar Orbit (20/7/1/−10), Minishuttle and Four-Person Craft (20/8/0/0), Lunar Probe Landing (16/9/2/−5), and Manned Space Mission / Three-Person Craft (15/5/0). Scrubbing costs 3, downgrading costs 3, dummy tests score nothing, and multiple firsts can stack on one mission.

### Cited Findings
- Full prestige table (MANUAL p.28, identical on REFCARD p.1; both read directly from the scans):

| # | Prestige name | 1st | 2nd | Other | Failure |
|---|---|---|---|---|---|
| 1 | Orbital Satellite | 12 | 5 | 1 | −3 |
| 2 | Lunar Flyby | 5 | 3 | 2 | −3 |
| 3 | Mercury Flyby | 5 | 2 | 2 | −3 |
| 4 | Venus Flyby | 7 | 4 | 2 | −3 |
| 5 | Mars Flyby | 7 | 4 | 2 | −3 |
| 6 | Jupiter Flyby | 8 | 4 | 2 | −3 |
| 7 | Saturn Flyby | 9 | 4 | 2 | −3 |
| 8 | Lunar Probe Landing | 16 | 9 | 2 | −5 |
| 9 | Duration Level 'F' | 7 | 7 | 0 | 0 |
| 10 | Duration Level 'E' | 5 | 5 | 0 | 0 |
| 11 | Duration Level 'D' | 1 | 1 | 0 | 0 |
| 12 | Duration Level 'C' | 5 | 5 | 0 | 0 |
| 13 | Duration Level 'B' | 3 | 3 | 0 | 0 |
| 14 | One-Person Craft | 3 | 1 | 0 | 0 |
| 15 | Two-Person Craft | 7 | 2 | 0 | 0 |
| 16 | Three-Person Craft | 15 | 5 | 0 | 0 |
| 17 | Minishuttle | 20 | 8 | 0 | 0 |
| 18 | Four-Person Craft | 20 | 8 | 0 | 0 |
| 19 | Manned Orbital | 12 | 5 | 1 | −10 |
| 20 | Manned Lunar Pass | 12 | 5 | 2 | −10 |
| 21 | Manned Lunar Orbit | 20 | 7 | 1 | −10 |
| 22 | Manned Lunar Landing | 40 | 15 | 8 | −10 |
| 23 | Experimental Orbiting Lab | 6 | 4 | 0 | −10 |
| 24 | Manned Docking | 8 | 4 | 1 | −3 |
| 25 | Woman In Space | 8 | 0 | 0 | −4 |
| 26 | Space Walk | 8 | 4 | 1 | −3 |
| 27 | Manned Space Mission | 15 | 5 | 0 | −10 |

— [MANUAL p.28](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988); [REFCARD p.1](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/5387)
- Duration bands (REFCARD "Need-to-Knows" and MANUAL p.34): A = 1–2 days, B = 3–5, C = 6–7, D = 8–12, E = 13–16, F = 17–20. — [REFCARD](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/5387), [MANUAL p.34](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Firsts stack: Manned Orbital "can be combined with manned space mission for additional prestige points, e.g. Yuri Gagarin, first man in space and manned orbital". "Multiple milestones can be attempted on a single mission or joint launches." — [MANUAL pp.32, 34](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Milestone prose values (consistent with the table): Orbital Satellite 12 pts; Sub-Orbital/Manned Space Mission 15 pts; Manned Orbital 12 pts; Lunar Satellite Fly-by 5 pts; Lunar Probe Landing 16 pts; Manned Lunar Pass 12 pts; Manned Lunar Orbital 20 pts; Manned Lunar Landing 40 pts; Spacewalk 8 pts; (Manned) Docking 8 pts; Duration 'D' 1 pt; LM Tests n/a ("little prestige is awarded"); Photo Reconnaissance n/a. — [MANUAL pp.32–34](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Scrub penalty: "You will be penalized three Prestige points for scrubbing a mission." Downgrade: "a less complicated safer mission but you lose 3 prestige. You can only downgrade a mission once." — [MANUAL pp.16–17](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Dummy Tests (unmanned sub-orbital, orbital, unmanned docking) "Prestige points are not gained or lost on dummy tests, but if the hardware is successful on one mission step, the safety factor improves 1%." — [MANUAL p.12](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Empirical per-mission scores from a complete US game, matching the table: Explorer I failure −3 (pad destroyed); Explorer II failure −3; Explorer III (first orbital satellite, achieved 2nd?) 12; Explorer IV–VI 1 each; Mercury I suborbital 18 (= 15 Manned Space Mission + 3 One-Person Craft); Mercury II Earth orbital 12; Mercury IV duration B 3; Mercury VI 1; Gemini III failure −7; Gemini IV (two-man, duration C, first EVA, first manned docking) 28 (= 7 + 5 + 8 + 8); Gemini V–IX 1 each; Ranger III lunar flyby 5; Ranger V, VII 2 each; Ranger VI failure −3; Apollo I (first three-man) 15; Apollo II manned lunar pass 12; Apollo III manned lunar orbit 20; Apollo IV LM test partial failure 1; Apollo V manned lunar landing 40. — [Orbiter-Forum AAR](https://webmail.orbiter-forum.com/goto/post?id=336463), [follow-up](https://webmail.orbiter-forum.com/goto/post?id=336467)
- LP commentary: a failed atmosphere-exit attempt scored −10 (Fall 1966); "the first four-person capsule in space is worth 20 Prestige points"; a Venus flyby "was worth more Prestige than they had realized". — [LP Update 40](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2040), [LP Update 42](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2042), [LP Update 38](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2038)
- Space Museum reporting: Prestige Summary shows which country was first on each major first/milestone with cumulative points per category; Space History shows "total prestige points gained" per mission; Hardware Efficiency shows success ratios and prestige per hardware program. — [MANUAL p.14](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- "Being first to accomplish something earns a large amount, while catastrophic, death-causing failures cost a large amount." — [LP index](https://lparchive.org/Buzz-Aldrins-Race-Into-Space); "Failed missions reduce prestige. Losing a crew is especially costly." — [Space Sector](https://www.spacesector.com/blog/?p=9465)
- Second-place and later awards: "The second successful mission of a type usually earns some points, and later ones earn few or none." — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- Prestige also unlocks spaceport growth: "As you purchase more programs and obtain more prestige, more buildings will appear." — [MANUAL p.5](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Morale link: "Successful (milestone first) missions improve the overall morale of the corps." — [MANUAL p.22](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)

### Inferences
- The "Failure" column appears to be applied per prestige category attempted, and the observed −7 for a failed Gemini launch suggests failures sum across the categories the mission was going for (e.g. −3 orbital-type items plus a −4), while a failed manned lunar-class step costs −10 per the table. Exact stacking of failure penalties is not documented.
- "Other" is the award for every success after the second in that category (e.g. the stream of 1-point Gemini/Explorer flights in the AAR).
- Deaths: no separate numeric prestige penalty is documented; the −10 "Failure" values on manned categories plus morale/resignation effects are the documented consequences.

### Gaps
- How failure penalties combine when a mission targets several categories is not stated.
- Whether "Woman In Space" also pays the usual mission prestige (the 2nd column is 0, implying only the first ever counts) is only inferable from the table.
- No source quantifies how prestige translates to budget.

---

## 4. Hardware catalogue, costs, safety factors, and R&D

### Takeaway
Each program has an Initial (program) cost, Unit cost, R&D cost per engineer team, Weight or Payload Lift, Max R&D (ceiling reachable by research) and Max Safety (absolute ceiling, reached only by flying it: +1% per successful step). Up to 5 teams per program per season; 6 units max in inventory per type. The full Basic and Historical tables are on the Reference Card and are reproduced below.

### Cited Findings
- Field definitions: Quantity (max 6 of any type); Initial Cost "start-up cost of developing a new program"; Unit Cost "cost of each additional unit"; Safety Factor "current safety (reliability)"; R&D Cost per Team "(total of five teams available)"; Weight (payload, n/a for launch vehicles); Maximum Payload; Max R&D "maximum level of safety that the program can achieve by R&D"; Max Safety: "To obtain a higher safety factor than Max R&D, the hardware must be used and tested on actual space missions... When successful, the program safety is increased by 1%. It can never exceed the Max Safety level. The mission can be manned or unmanned (dummy tests)... the mission does not have to be successful, just the hardware." — [MANUAL pp.7–8](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Research Park: "No more than five teams of engineers can be assigned to an R&D program, once per season... The more teams selected, the better chance of improvement." — [MANUAL p.16](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988); R&D keyboard: "0-5 Engineer Teams" — [REFCARD](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/5387)
- Technology transfer: "If you develop the Atlas rocket and R&D it up to 75% or greater, and then purchase the Titan Program, the Titan's initial safety factor will start at a higher level (25%). If you had purchased the Titan program first, it would start at an initial safety of 5%. (See the Player's Aid Card for technology transfer figures.)" — [MANUAL p.6](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Observed starting safety on purchase (port): Explorer satellite 40%, Atlas rocket 10% ("a 10% rocket would be very risky to launch"); the game reports how much safety each R&D investment added. — [LP Update 02](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2002)
- Contradicting claim: "A newly purchased item starts with a safety factor of zero... R&D alone caps the safety factor at roughly 75–85%." — [Scientific Gamer](https://scientificgamer.com/in-praise-of-buzz-aldrins-race-into-space) (contradicted by MANUAL p.6 and LP Update 02 on the starting value; the R&D cap range is consistent with the tables)
- Each successful flight check "raises that equipment's overall safety factor by 1%". — [Scientific Gamer](https://scientificgamer.com/in-praise-of-buzz-aldrins-race-into-space); "Reusing a hardware type improves its safety beyond the maximum researchable value." — [Space Sector](https://www.spacesector.com/blog/?p=9465)
- Docking Module cannot be R&D'd: "Docking safety cannot be improved by R&D, rather only by actual missions and practice. The beginning safety factor for docking is 40%. When docking is attempted during a space mission (multiple attempts during an actual space mission count for one) the skill is increased 5%. A successful dock increases the skill another 5% (for a total of 10%). The highest safety for docking is 98%. With successful power-ons, DMs have an operating life of one year (the season it's launched plus the next season). Any number of friendly craft or mini-shuttles may attempt to dock... The DM can be launched separately or attached to Gemini/Voskhod, Apollo/Soyuz, mini-shuttles and LMs." Program cost 18, R&D n/a, weight 300; "requires satellite technology for it to be functional, 'Power-on' (the DM power-on skill is equal to the orbital satellite technology)." — [MANUAL p.29](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988). Conflict: REFCARD lists Docking Module Max Safety 93% (Basic; 93% US / 94% Soviet Historical), and the LP's docking module topped out at 93%. — [REFCARD](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/5387), [LP Update 48](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2048)
- **Basic Model table** (REFCARD p.2, read from scan; Cost = program initial cost, Unit = unit cost, R&D = cost per team, all in MB; bracketed Max R&D values are printed on the card for the manned capsules without explanation):

| Program | Cost | Unit | R&D | Weight | Payload Lift | Max R&D | Max Safety |
|---|---|---|---|---|---|---|---|
| Explorer / Sputnik | 6 | 1 | 1 | 300 | n/a | 95% | 98% |
| Ranger / Cosmos | 24 | 4 | 3 | 700 | n/a | 90% | 93% |
| Surveyor / Luna | 30 | 6 | 4 | 1200 | n/a | 85% | 88% |
| Atlas / A-Series | 24 | 3 | 2 | n/a | 600 | 84% | 98% |
| Titan / Proton | 60 | 12 | 4 | n/a | 1500 | 90% | 98% |
| Saturn V / N-1 | 84 | 18 | 6 | n/a | 3200 | 95% | 98% |
| Nova / Vulkon | 150 | 30 | 8 | n/a | 4800 | 95% | 98% |
| B. Strap-On / B. Stage (booster) | 12 | 3 | 2 | n/a | +1000 | 85% | 98% |
| Mercury / Vostok | 18 | 2 | 1 | 500 | n/a | 76% (80%) | 90% |
| Gemini / Voskhod | 24 | 6 | 2 | 1200 | n/a | 81% (84%) | 94% |
| Apollo / Soyuz | 36 | 12 | 5 | 1600 | n/a | 84% (87%) | 94% |
| XMS-2 / Lapot (mini-shuttle) | 60 | 30 | 7 | 1500 | n/a | 91% | 94% |
| Jupiter / Kvartet (direct ascent) | 60 | 30 | 8 | 4300 | n/a | 89% | 94% |
| Eagle LM / Duet LM (2-man) | 30 | 8 | 2 | 1500 | n/a | 90% | 94% |
| Cricket / L-3 (1-man LM) | 42 | 8 | 4 | 1000 | n/a | 90% | 94% |
| U.S. Kicker-A / Soviet Kicker-A | 12 | 3 | 1 | 300 | n/a | 94% | 97% |
| U.S. Kicker-B / Soviet Kicker-B | 18 | 6 | 2 | 600 | n/a | 94% | 96% |
| Soviet Kicker-C | 40 | 20 | 4 | 2500 | n/a | 90% | 95% |
| U.S. / Soviet EVA Suit | 18 | — | 1 | n/a | n/a | 91% | 94% |
| U.S. / Soviet Docking Module | 18 | 2 | n/a | 300 | n/a | n/a | 93% |

— [REFCARD p.2](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/5387)
- **Historical Model table** (REFCARD p.2):

| Program | Cost | Unit | R&D | Weight | Payload Lift | Max R&D | Max Safety |
|---|---|---|---|---|---|---|---|
| Explorer | 6 | 1 | 1 | 200 | n/a | 95% | 98% |
| Sputnik | 6 | 1 | 1 | 400 | n/a | 95% | 98% |
| Ranger | 24 | 5 | 3 | 700 | n/a | 90% | 93% |
| Cosmos | 20 | 3 | 3 | 1000 | n/a | 88% | 93% |
| Surveyor | 30 | 7 | 4 | 1200 | n/a | 85% | 88% |
| Luna | 26 | 6 | 4 | 1500 | n/a | 85% | 88% |
| Atlas | 26 | 3 | 2 | n/a | 500 | 87% | 98% |
| A-Series | 20 | 3 | 2 | n/a | 800 | 85% | 98% |
| Titan | 60 | 12 | 4 | n/a | 1200 | 91% | 98% |
| Proton | 60 | 12 | 4 | n/a | 1900 | 90% | 98% |
| Saturn V | 90 | 18 | 6 | n/a | 3500 | 95% | 98% |
| N-1 | 84 | 18 | 7 | n/a | 3900 | 93% | 98% |
| Nova | 150 | 30 | 8 | n/a | 4800 | 94% | 98% |
| Vulkon | 150 | 30 | 8 | n/a | 5500 | 94% | 98% |
| B. Strap-On (US) | 18 | 4 | 2 | n/a | +800 | 85% | 98% |
| B. Stage (Soviet) | 15 | 4 | 2 | n/a | +1200 | 87% | 98% |
| Mercury | 20 | 3 | 1 | 500 | n/a | 78% (82%) | 92% |
| Vostok | 18 | 3 | 1 | 700 | n/a | 76% | 92% |
| Gemini | 30 | 7 | 2 | 1200 | n/a | 83% (86%) | 94% |
| Voskhod | 24 | 6 | 2 | 1400 | n/a | 80% | 92% |
| Apollo | 40 | 14 | 5 | 1700 | n/a | 89% | 94% |
| Soyuz | 36 | 12 | 5 | 1900 | n/a | 85% | 94% |
| XMS-2 | 55 | 30 | 7 | 1400 | n/a | 91% | 94% |
| Lapot | 65 | 30 | 7 | 1800 | n/a | 87% | 94% |
| Jupiter | 65 | 30 | 8 | 4600 | n/a | 89% | 94% |
| Kvartet | 60 | 30 | 9 | 5300 | n/a | 89% | 94% |
| Eagle LM | 30 | 8 | 2 | 1500 | n/a | 90% | 94% |
| Duet LM | 35 | 8 | 2 | 1700 | n/a | 91% | 94% |
| Cricket | 42 | 9 | 4 | 1100 | n/a | 89% | 94% |
| L-3 | 48 | 9 | 4 | 1500 | n/a | 90% | 93% |
| U.S. Kicker-A | 12 | 3 | 1 | 300 | n/a | 92% | 97% |
| Soviet Kicker-A | 12 | 3 | 1 | 500 | n/a | 91% | 95% |
| U.S. Kicker-B | 18 | 6 | 2 | 700 | n/a | 94% | 97% |
| Soviet Kicker-B | 18 | 6 | 2 | 700 | n/a | 91% | 95% |
| Soviet Kicker-C | 40 | 20 | 4 | 3000 | n/a | 90% | 94% |
| U.S. / Soviet EVA Suit | 18 | — | 1 | n/a | n/a | 91% | 94% |
| U.S. Docking Module | 18 | 3 | n/a | 300 | n/a | n/a | 93% |
| Soviet Docking Module | 15 | 2 | n/a | 300 | n/a | n/a | 94% |

— [REFCARD p.2](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/5387)
- Hardware capabilities (MANUAL pp.29–31, Basic-model costs): Explorer/Sputnik: lightest payload, orbital-satellite missions only, launchable on any rocket. Ranger/Cosmos: interplanetary satellite to Moon, Mercury, Venus, Mars, Jupiter, Saturn "during available launch windows"; requires at least Titan/Proton; successful lunar flybys improve photo recon. Surveyor/Luna: unmanned soft lander, requires at least Titan/Proton. Atlas/A-Series: "smallest lift capability... can only be launched sub-orbital or into low Earth orbit. They cannot be used for lunar or interplanetary missions"; can lift orbital satellites, DMs, Mercury/Vostok and, with boosters, Gemini/Voskhod, Apollo/Soyuz, mini-shuttles and LMs. Titan/Proton: sub-orbital, Earth-orbital, lunar or interplanetary. Saturn/N-1: "extremely powerful". Nova/Vulkan: greatest lift; boosters cannot be added. Strap-ons/Boosters: only with Atlas/A-Series, Titan/Proton or Saturn/N-1; add 1000 lift. Kicker-A: propels one spacecraft (capsule or LM) from Earth orbit to lunar orbit; Gemini/Voskhod, mini-shuttles and LMs need a kicker to reach lunar orbit; kickers are dead weight at launch. Kicker-B: propels a spacecraft+LM combo or one craft to lunar orbit. Kicker-C (Soviet, cost 40, R&D 4): docks only with a Soyuz in lunar orbit and lands the whole package; "LM tests, LMs, Kickers A & B or DMs are not required"; docking experience strongly recommended. Mercury/Vostok: one man, max duration 5 days (B), no docking or lunar. Gemini/Voskhod: two men, max 14 days (E); sub-orbital, orbital, EVA, docking, duration, most lunar; needs Kicker A or B for lunar; one-man LM + DM for LM tests/landings; single-launch landing with Gemini+DM+LM needs Kicker-B. Apollo/Soyuz: three men, max 18 days (F); no kicker needed; service module can propel an LM to lunar orbit; built-in docking adapter for LMs; may use a DM for practice dockings. XMS-2/Lapot: three-man reusable mini-shuttle, max 12 days (D); needs Kicker A or B for lunar; reused once per season unless heavily damaged/destroyed. Jupiter/Kvartet: four-man direct-ascent lander, max 20 days (F); lands on the Moon but "doesn't dock with any other craft. No docking skills or LM tests are required... requires the massive Nova/Vulkan rocket"; no kicker. Eagle/Duet LM: two-man, max 5 days, used with Apollo/Soyuz and XMS-2/Lapot, only for LM tests and landings. Cricket/L-3: one-man LM, max 3 days, used with Gemini/Voskhod, Apollo/Soyuz and XMS-2/Lapot ("more expensive program since it would require additional automated systems"). EVA Suit: program cost 18, R&D 1, max duration 6 hours; required for all spacewalks and lunar excursions. — [MANUAL pp.29–31](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Program buildings confirm crew sizes: Mercury one-man, Gemini two-man, Apollo three-man, XMS-2 three-man mini-shuttle, Jupiter four-man direct-ascent lander; Soviet Vostok/Voskhod/Soyuz one/two/three-man, Lapot three-man mini-shuttle, Kvartet four-man. — [MANUAL pp.25–27](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Gemini seat roles: "Seat 1 Capsule Pilot/Docking; Seat 2 LM Pilot/EVA Specialist". — [MANUAL p.21](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Corroboration of Basic-model numbers from play (port): Explorer unit 1 / R&D 1 / weight 300 / max R&D 95 / max safety 98; Atlas 3/2/payload 600/84/98; Titan 12/4/1500/90/98; Saturn V 18/6/3200/95/98; Mercury 2/1/500/80/90; Gemini 6/2/1200/84/94; Cricket 8/4/1000/90/94; Kicker-B 6/2/600/94/96; EVA Suits unit 0, R&D 1 early then 3 later; Docking Module 2/n-a/300/n-a/93; Ranger 4/3/700/90/93. — [LP Update 14](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2014), [LP Update 48](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2048)
- Observed R&D progression (port): Titan 30% (Spring 1961) -> 48% (Fall 1960) -> 68% (Spring 1961) -> 86% (Fall 1961) -> 91%–98% later; Gemini 34% -> 57% -> 73% -> 85% -> 94%; Cricket 30% -> 32% -> 47% -> 62% -> 79% -> 93%; Saturn V 60% -> 75% -> 86% -> 96% -> 98%. — [LP 16](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2016), [LP 18](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2018), [LP 20](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2020), [LP 22](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2022), [LP 32](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2032), [LP 36](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2036), [LP 40](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2040), [LP 42](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2042), [LP 48](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2048)
- "Rushing" in BARIS refers to launches, not R&D: Mission Control lets you "rush a launch (lowering the safety factor by 3% for all hardware on each step)... Each mission you have scheduled can be rushed one or two months. This costs additional funds (3MB) and a loss of safety (-3%) for each month rushed. On joint missions, rushing would move both missions up and safety would be lowered on both launches." — [MANUAL p.17](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988); observed: May = no cost; April = 3 MB and −3 to all steps; March = 6 MB and −6. — [LP Update 06](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2006)
- Research-boost events exist: "Operation Paperclip boosted R&D for one turn." — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space); "A German scientist was acquired for R&D" (USSR, Fall 1959); "Research booster awarded"; "A research boost applies this season". — [LP Update 13](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2013), [LP Update 18](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2018), [LP Update 24](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2024)
- Marketing counts: "over 30 types of space hardware and more than 300 mission types" (CD box). — [elisoftware.org](https://elisoftware.org/wiki/Buzz_Aldrin%27s_Race_Into_Space_(PC,_CD-ROM)_Interplay_Productions_-_1993_USA,_Canada_Release); "twenty different ways to send 'nauts to the moon". — [MANUAL p.36](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)

### Inferences
- The bracketed Max R&D values for Mercury/Gemini/Apollo (e.g. 76% (80%)) are the Max R&D the port displays (LP shows Mercury 80%, Gemini 84%), so the bracketed figure is probably the effective ceiling after some unlocking condition (inferred; the card does not explain it).
- Per-team R&D gain is random; given 5 teams and the LP's observed +15–25 points per season on fresh programs, a model of "each team rolls for a small gain, diminishing as safety nears Max R&D" fits the evidence but is not documented.
- Starting safety on purchase appears to be hardware-class dependent (satellite 40%, rocket 10% in the port; manual cites 5% for Titan without transfer, 25% with).

### Gaps
- The exact R&D roll (points per team, randomness, diminishing returns) is undocumented.
- Full technology-transfer pairings/figures beyond Atlas->Titan are referred to the "Player's Aid Card" but do not appear on the recovered reference card.
- Starting safety for each program on purchase is not tabulated.

---

## 5. Missions, milestone penalties and the step-check system

### Takeaway
There are 57 mission types. Each mission is a sequence of lettered steps; each step checks one piece of hardware's safety (plus crew skill, max +4 per skill) against a roll. Skipping a milestone costs −3% per skipped milestone on every step of the mission (cumulative); skipping a duration step costs −5% each (−5% to −8% depending on crew endurance); each skipped LM test −3%.

### Cited Findings
- "The mission-selection arrows cycle through all fifty-seven types of space missions." The mission penalty box "displays the loss of safety percentage that will be applied to every step on all hardware during the space mission... the worst-case scenario." — [MANUAL pp.9–10](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- The 57 missions (MANUAL pp.40–41 / REFCARD p.3): 0 None; 1 Orbital Satellite; 2 Manned Sub-orbital; 3 Unmanned Sub-orbital; 4 Manned Orbital; 5 Unmanned Orbital; 6 Manned Orbital EVA; 7 Lunar Flyby; 8 Lunar Probe Landing; 9 Venus Flyby; 10 Mars Flyby; 11 Mercury Flyby; 12 Jupiter Flyby; 13 Saturn Flyby; 14 Manned Orbital Docking; 15 Unmanned Orbital Docking; 16 Jt Manned Orbital Docking; 17 Manned Orbital Docking (DM in orbit); 18 Jt Unmanned Docking; 19 Jt Manned Orbitals Docking; 20 Manned Orbital Docking EVA; 21 Jt Manned Orbital Docking EVA; 22 Jt Manned Orbitals Docking EVA; 23 Jt Manned Orbitals Docking Jt EVA; 24 Manned Orbital Docking (orbit) EVA; 25 Manned Orbital Duration; 26 Manned Orbital EVA Duration; 27 Manned Orbital Docking Duration; 28 Manned Orbital Docking (orbit) Duration; 29 Manned Orbital Docking (orbit) EVA Duration; 30 Jt Manned Orbitals EVA Docking Duration; 31 Jt Manned Orbital Docking Duration; 32 Jt Manned Orbiting Lab; 33 Manned Orbital Docking EVA Duration; 34 Jt Manned Orbital Docking EVA Duration; 35 Jt Manned Orbitals Docking EVA Duration; 36 Jt Manned Orbiting Lab EVA; 37 Jt Manned Orbitals Docking Duration; 38 Manned Earth Orbital LM Test; 39 Jt Manned Earth Orbital LM Test; 40 Manned Earth Orbital LM Test EVA Duration; 41 Jt Manned Earth Orbital LM Test EVA Duration; 42 Unmanned Lunar Pass; 43 Manned Lunar Pass; 44 Jt Manned Lunar Pass EOR; 45 Unmanned Lunar Orbital; 46 Manned Lunar Orbital; 47 Jt Manned Lunar Orbital EOR; 48 Manned Lunar Orbital LM Test; 49 Jt Manned Lunar Orbital LM Test LOR; 50 Manned Lunar Orbital LM Test EVA; 51 Jt Manned Lunar Orbital LM Test EVA; 52 Jt Manned Lunar Orbital LM Test EOR/LOR; 53 Historical Manned Lunar Landing; 54 Direct Ascent Lunar Landing (Jupiter/Kvartet, Nova/Vulkan, EVA suit); 55 Jt Lunar Landing EOR; 56 Jt Lunar Landing LOR; 57 Soyuz Lunar Landing (Soyuz, Docking Skill, Kicker C). Requirements per mission list spacecraft, astronauts, rocket(s), DM, LM, kicker, EVA suit as applicable. — [MANUAL pp.40–41](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Step counts observed (port): Orbital Satellite 3 steps (2 checks vs rocket, 1 vs satellite); Unmanned Sub-orbital 3; Unmanned Orbital 3; Manned Sub-orbital 3; Manned Orbital 6; Manned Orbital EVA 7; Manned Orbital Duration 7; Manned Orbital Duration EVA 8. — [LP Update 18](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2018); "A satellite launch has three steps; a Moon landing has more than twenty." — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space); "Early missions have about 3–4 steps; late Moon missions have about 20." — [Space Sector](https://www.spacesector.com/blog/?p=9465)
- Milestone skip penalties: "There are no restrictions on mission order other than a -3% safety factor for each milestone skipped, for all steps involved in that mission. Penalties from multiple milestones skipped are cumulative... Skipped milestones reduce safety by 3%; skipped duration steps reduce safety by 5% each." REFCARD "Penalties for Skipping Steps": −3% Orbital Satellites; −3% Manned Sub-Orbital; −3% Manned Orbital; −5% Duration 'B'; −5% Duration 'C'; −3% Lunar Satellite Fly-by; −3% Lunar Probe Landing; −3% Manned Lunar Pass; −5% Duration 'D'; −3% Manned Lunar Orbital; −3% LM Tests (minimum 2); −3% Manned Lunar Landing. — [MANUAL p.32](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988), [REFCARD p.1](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/5387)
- Milestone Hurdles ordering: "Durations B and C must be completed in that order after manned orbitals and before a manned lunar pass; duration D must be completed before manned lunar orbital. LM tests must be completed after manned orbital and before manned lunar landings." Worked examples: first mission manned orbital = −9%; manned orbital 'B' done then manned lunar pass = −14%; manned orbital duration 'D' done then manned lunar landing = −12%. — [MANUAL p.34](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Duration skip formula: "A formula averages the flight crew's endurance skill with the number of steps skipped. The penalty can range from -5% to -8% per step." — [MANUAL p.34](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- LM tests: Earth-orbital test = 1 point, lunar-orbital test = 2 points; need at least 3 points before a manned landing "or safety is lowered on the LM during lunar landings"; "For every skipped LM test the lunar landing is penalized -3% safety"; valid strategies: three Earth-orbital tests; one Earth-orbital + one lunar-orbital (Apollo 9 and 10); two lunar-orbital. Direct ascent needs none. — [MANUAL pp.23, 34](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988); the player's Apollo V landing was computed as 90% R&D −9% for 0 LM points +4% Aldrin skill = 85%. — [Orbiter-Forum AAR](https://webmail.orbiter-forum.com/goto/post?id=336463)
- Photo recon: "begins with base safety of 55%. Every successful interplanetary fly-by of the moon, manned lunar pass or lunar orbital increases photo recon by 5%. Successful lunar landing probes increase photo recon by 15%. Lunar probes that fail landing but still manage to make a lunar orbit burn increase photo recon by 5%." No cost. — [MANUAL p.33](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988); 55% starting value confirmed — [LP Update 01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001)
- Step resolution display: "The safety range is displayed in blue. Green is the tolerance level and yellow is the astronaut skill. If green tolerance rises above the blue range, it changes to red and the mission step is in failure mode." Then an explosion animation or a Failure Mode screen; "Sometimes you will have to make a decision to abort or continue a mission." — [MANUAL p.18](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- "Safety is a percentage. Each roll above it triggers something bad... A roll that beats the normal result but falls below the crew's value produces a mission accident, which gives modifiers to later rolls and may force an abort." Flight-experience modifier: "a manned mission before Sputnik carries a -20% safety modifier." Backup crews substitute if a primary is lost to an event. — [Space Sector](https://www.spacesector.com/blog/?p=9465)
- "A failed check triggers a hidden second roll that determines how severe the failure is"; crew skill adds 0–4% to the safety check; capsule max safety 94% so "a very competent pilot can reach 98%". — [Orbiter-Forum AAR](https://webmail.orbiter-forum.com/goto/post?id=336463)
- Crew skill: "Each skill point of an astronaut are additional percentages that can be added to corresponding safety factor during a space mission... The maximum level in each skill category is 4." — [MANUAL p.12](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Mission penalty box values observed in play (port, 1961): Manned Sub-orbital −1, Manned Orbital −4, Manned Orbital EVA −4, Manned Orbital Duration −14, Manned Orbital Duration EVA −14 (before any manned flight); later: Earth-orbit LM test 0, Lunar Orbit −7, lunar landing with Gemini −10, "Attempt to end the game" −4. — [LP Update 18](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2018), [LP Update 40](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2040), [LP Update 36](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2036), [LP Update 43](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2043)
- Joint missions need two pads and are limited to pad pairs 1:2 or 2:3, never 1:3; with only one pad joint missions are not offered. — [MANUAL p.10](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Docking missions require a DM "placed in orbit in the previous mission or season. Docking modules have a lifespan of two seasons in space." — [MANUAL p.11](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Planet flyby windows: "Due to orbital mechanics some planets are not available each season." — [MANUAL p.9](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Crew rules: primary and backup crew per manned mission; two manned missions with the same spacecraft need four crews; "A flight crew can be assigned (primary or backup) on a mission once per year"; crews "must have already been trained with the spacecraft a season earlier". — [MANUAL pp.12, 22](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Wikipedia's summary of the mechanic: the safety factor is "compared to a random number, adjusted by astronaut skill bonuses (crewed missions), safety penalties, and other factors. Failures range from catastrophic to harmless." — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)

### Inferences
- The port's −1/−4 penalties for sub-orbital/orbital before any manned flight do not match a pure 3%-per-milestone rule, so the displayed penalty box likely folds in other factors (e.g. the hardware's own class, the pre-Sputnik modifier) — treat the −3/−5 rule as the designed core and the box as a composite.
- The "manned orbital first = −9%" example is consistent with three skipped milestones (orbital satellite, manned sub-orbital, plus one more), i.e. three × −3%.

### Gaps
- The exact dice model (range of the roll, how the hidden severity roll maps to outcomes, abort probabilities) is undocumented outside source code.
- The per-mission step lists for all 57 missions are not published (only counts for the eight simplest).

---

## 6. Facilities: pads, VAB/VIB, Administration, and other buildings

### Takeaway
You start with Pad A and can buy Pads B and C (20 MB each in play); one mission per pad per season; damaged pads must be repaired before reuse. The VAB/VIB enforces payload weight <= rocket lift and offers Auto Purchase; the Administration building holds the Budget Office, Hardware Purchase, Future Missions, Astronaut Recruiting, Preferences and Time Capsule (save/load).

### Cited Findings
- "You start with one operational launch pad (A) and can purchase two more for a total of three launch facilities. They will list current missions scheduled for this season. You may also scrub missions from this location. Damaged launch pads can be repaired at this site." — [MANUAL p.16](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988); "Pads damaged by errant rockets or adverse conditions must be repaired before they become available again." — [MANUAL p.9](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Pad price: "You can buy up to two more for 20MB each, and this price never increases." — [LP Update 01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001)
- Pad destruction happens on launch failures: Explorer I "failure, -3 pts (pad destroyed)". — [Orbiter-Forum AAR](https://webmail.orbiter-forum.com/goto/post?id=336463); "Launch-pad explosions require a costly rebuild." — [Scientific Gamer](https://scientificgamer.com/in-praise-of-buzz-aldrins-race-into-space); keyboard map has "F Fix Launch Pad" under Launch Facility. — [REFCARD](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/5387)
- VAB/VIB: assembles payload + rocket for current-season missions; shows mission goals and crew roster; "VAB will not accept a launch configuration if the payload is heavier than the capabilities of the rocket. Either select a more powerful rocket and/or booster combination or scrub the mission"; Assign moves the stack to the pad; Scrub = −3 prestige; "The Auto Purchase button conveniently purchases the current hardware displayed in VAB/VIB, but you must of course already have the program developed." — [MANUAL pp.15–16](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Administration Building offices: Budget Office; Hardware Purchase (four category boxes: unmanned/satellites, rockets, capsules/manned, miscellaneous); Future Missions Office (incl. pad purchase and five lockable mission-filter icons: Manned/Unmanned/Duration, Docking, EVA, LM, Joint); Astronaut Recruiting; Preferences (music/sound/animation only in play); Time Capsule (save/load/quit). — [MANUAL pp.6–14](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Other buildings: Space Museum (Director's Rating, Space History with mission replay, Mission Records across games, Prestige Summary, Hardware Efficiency, Astronaut History); Pentagon/KGB (Library: opponent hardware/upcoming missions, "may not always be accurate"; CIA/KGB Statistics: your inventory vs the opponent's known hardware); Capitol/Politburo (annual review); Research Park ("grows from a small facility... to a cluster"); The Moon (photo recon); Mission Control; Arlington Cemetery/Kremlin Wall; Flag; Viewing Stand (chronology of news); Front Gate/Security Gate (quit). — [MANUAL pp.14–19, 24–27](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Astronaut buildings appear after recruiting Group I: Basic Training (up to 3 seasons; cannot return once withdrawn), Astronaut Complex/Cosmonaut Center (assign to programs or advanced training; unassigned crews bounce back and lose a season), Medical Center/Infirmary, five Advanced Training buildings (Centrifuge = endurance, EVA Training, LM Training, Pilot Training Air Field = capsule/mini-shuttle piloting, Planetarium = navigation/docking) constructed "one season after you recruited your Group I"; Advanced Training = 2-year term, 3 MB per astronaut, once per career, improves one skill; program buildings (Mercury, Gemini, Apollo, XMS-2, Jupiter / Vostok, Voskhod, Soyuz, Lapot, Kvartet), LM Facilities, Satellite Building. — [MANUAL pp.19–27](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Spaceport growth: buildings appear "after you purchase new Space Hardware Programs and Recruit Astronauts"; the port "will appear small, with only a few key buildings" at the start. — [MANUAL pp.5, 19](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Recruiting: a new group every two to three years; up to five groups; 106 astronauts per side (random events can add three military pilots and female astronauts, "63 out of 109"); you must take a full group; only some skills are visible before basic training. — [MANUAL p.12](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988); in play only Capsule Pilot and Endurance are visible before hiring at astronaut level 1; recruiting unavailable until Spring 1958. — [LP Update 06](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2006), [LP Update 01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001)
- Wikipedia notes four historical NASA facilities were merged into "one superfacility" and Redstone was removed. — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)

### Inferences
- Pad repair is a paid action from the Launch Facility screen (the keyboard map has a dedicated "Fix Launch Pad" command), so the reimplementation needs a repair cost parameter; the LP never shows one.

### Gaps
- Pad repair cost and the probability that a given failure mode damages/destroys the pad are not documented.
- Whether more than one astronaut group can be hired in the same year is not stated.

---

## 7. News and random events

### Takeaway
Every turn opens with a Network News screen (Space News, Astronaut News, World Events). Events include R&D boosts, budget adjustments (+8 MB seen), "pay or lose safety" demands (10 MB vs −10% on a program's next mission), astronaut injuries/washouts, retirements, deaths outside missions, extra recruit pools, and defection-style events; the manual itself lists almost none of them.

### Cited Findings
- "A series of news briefs will inform you on Space News, Astronaut News and World Events." — [MANUAL p.5](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988); "Each turn, a random card gives historical information and sometimes a positive or negative effect. For example, Operation Paperclip boosted R&D for one turn." — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space); "The first turn has no good or bad event... Events range from an astronaut dying in a car crash to a failure mode found on a rocket type." — [Space Sector](https://www.spacesector.com/blog/?p=9465)
- Events documented in the manual: random extra recruits (three military pilots, female astronauts); astronaut deaths affect corps morale and may cause resignations. — [MANUAL pp.12, 22](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Observed events (port): Spring 1958 US: pay 10 MB or Atlas's next mission takes −10% safety, giving budget outcomes of 80/90/95 MB; Fall 1958: Schirra washed out (injury); Fall 1959 USSR: German scientist acquired for R&D; Fall 1961: EVA research costs rose, Lovell physical washout, an astronaut injured in a fall; Spring 1962: Titan "Pay or Safety", Kincheloe retiring; Fall 1962: research boost; Spring 1966: +8 MB; Fall 1966: news added money (68 MB available); Spring 1967 USSR: a China world event; Fall 1967 USSR: a fighter pilot recruit event. — [LP 06](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2006), [LP 10](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2010), [LP 13](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2013), [LP 20](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2020), [LP 22](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2022), [LP 24](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2024), [LP 38](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2038), [LP 40](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2040), [LP 43](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2043)
- The EVA Suit R&D cost per team changed from 1 to 3 MB mid-game after a news item ("EVA research costs have gone up"). — [LP Update 20](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2020) vs [LP Update 26](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2026)
- Non-mission astronaut death: "Casualties: 1 (Glenn, automobile accident)". — [Orbiter-Forum AAR](https://webmail.orbiter-forum.com/goto/post?id=336463)
- Many news items are flavour with no effect ("Ben-Hur won an Oscar", "news is described as mostly fluff"). — [LP Update 10](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2010), [LP Update 40](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2040)
- Intelligence: CIA/KGB reports "arrive every two to three years, along with an update to the comparison graph. Reports are not fully accurate." — [Space Sector](https://www.spacesector.com/blog/?p=9465); "Even photographs can be altered for deception. Sometimes early mockups of space proposals were misinterpreted by rival intelligence agencies as primary programs." — [MANUAL p.15](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Astronaut mood colours Green/Yellow/Red/Black (burned-out, will retire); "Yellow" observed as mood <= 65 on a 0–99 scale in the port; advanced training gave +2 skill points to everyone but did not freeze mood. — [MANUAL p.22](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988), [LP Update 34](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2034)

### Inferences
- Event effects fall into a small set of mechanical levers: budget +/- MB, one-turn R&D bonus, forced choice (pay MB or take a safety penalty), R&D cost change for a program, astronaut status change (injury, washout, retirement, death), extra recruits, and flavour. A reimplementation can model events as records with (text, side, effect-type, magnitude).

### Gaps
- No published list of the event deck, probabilities, or which events are side-specific (budget cuts, strikes, Congress/Politburo pressure, defections are referenced by reviewers only in general terms).

---

## 8. The computer opponent

### Takeaway
Documentation says the AI plays by the same rules and is subject to the same annual review; reviewers describe difficulty levels as handicaps rather than smarter play, the AI as roughly human-strength, and note it tends to repeat a failed mission type before changing approach.

### Cited Findings
- "The computer opponent operates under the same conditions as you so don't feel too bad when things go wrong. It's happening to the other side; you just won't always hear about it." — [MANUAL p.3](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Opponent's successful/failed non-first missions are hidden; prestige-first footage is shown and feeds Pentagon/KGB hardware analysis. — [MANUAL p.17](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- "Three AI difficulty levels. The review says they act as handicaps, and the AI remains strong even on easy for the player... the AI plays about as well as a normal human, but it tends to repeat failed mission types before trying something new." — [Space Sector](https://www.spacesector.com/blog/?p=9465)
- "the AI is actually pretty good at playing the game." — [LP index](https://lparchive.org/Buzz-Aldrins-Race-Into-Space); in the LP the computer USSR took the lead in Space Firsts in 1966 and was "neck and neck" at the end. — [LP Update 38](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2038), [LP Update 49](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2049)
- In another player's game the computer Soviets were "not even a nuisance". — [Orbiter-Forum follow-up](https://webmail.orbiter-forum.com/goto/post?id=336467)
- The game credits list "Artificial Intelligence Written by" two named programmers, so the AI is a dedicated subsystem. — [MANUAL p.A-3 credits](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- COMPUTE!: "Each side has one player, who can be human or computer-controlled. Game types and difficulty levels balance mismatched skill levels or raise the challenge against the computer." — [COMPUTE!](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)

### Inferences
- Because the AI is subject to dismissal only "at higher levels against a computer opponent" from the human's perspective, the AI itself is never fired (inferred from MANUAL p.15 wording).

### Gaps
- No documentation describes the AI's planning (which programs it buys, how it sequences milestones, when it rushes); this must be designed from scratch.

---

## 9. Difficulty levels and game models

### Takeaway
Each side independently has difficulty Level 1 (easiest) to 3 (hardest), giving nine combinations; three separate "astronaut difficulty" levels control how much recruit data is shown; Basic vs Historical model controls whether the two sides' hardware tables are identical or historically skewed. The CD edition marketing adds a "Quick Start beginner level".

### Cited Findings
- "Three levels of difficulty can be chosen for each side. Level 1 is the easiest and 3 is the hardest. For handicapping either opponent, switch them to a higher level. The variations give you nine different levels to play." — [MANUAL p.3](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Level effects documented: dismissal possible only at Level 2–3 vs a computer; Director's Rating "total points will vary depending on game level". — [MANUAL pp.3, 14–15](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988); Level 1 "makes things slightly less likely to go horrifically wrong at every possible moment". — [LP Update 01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001)
- "Astronaut Difficulty - There are three levels of astronaut personnel data. By selecting the lowest level, you are provided with the most data on your astronauts. The higher the level, the less information is provided." — [MANUAL p.3](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- "The Basic Model starts both countries with equal circumstances and costs. The Historical Model builds in the historical advantages and relative costs for each country." — [MANUAL p.3](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988); "Basic Model makes both sides identical except for equipment names. The Historical Model makes American hardware more expensive and Soviet hardware more likely to explode." — [LP Update 01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001)
- "Three difficulty settings affect overall conditions and performance levels. Difficulty also raises official expectations." — [COMPUTE!](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- CD box: "Three levels, including a new Quick Start beginner level"; also claims 140+ astronauts/cosmonauts (vs 106 per side in the manual). — [elisoftware.org](https://elisoftware.org/wiki/Buzz_Aldrin%27s_Race_Into_Space_(PC,_CD-ROM)_Interplay_Productions_-_1993_USA,_Canada_Release)
- Historical roster vs custom roster; custom roster edits cannot raise total skill points; one custom roster can be saved. — [MANUAL pp.3–4](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space/download/1988)
- Modern port config exposes a crew-compatibility difficulty 1–10 (default 10 hardest) — port-only, not in the original docs. — [Orbiter-Forum follow-up](https://webmail.orbiter-forum.com/goto/post?id=336467)
- The game "was widely criticized as extremely difficult" despite being marketed to 10-year-olds. — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space); "extremely difficult, with frequent mission failures that seem unreasonable even with the best rockets and astronauts". — [Home of the Underdogs](https://www.homeoftheunderdogs.net/game.php?id=160)

### Inferences
- Beyond dismissal eligibility and the score multiplier, the levels most likely scale failure likelihood (LP author's remark) and funding/expectations (COMPUTE!'s "raises official expectations"), consistent with the reviewer description of levels as handicaps; the precise modifiers are undocumented.

### Gaps
- No source gives the numeric effect of Level 1/2/3 on budget, safety rolls, or the dismissal threshold.
- Whether "Quick Start" in the CD edition is a true fourth difficulty or a renamed Level 1 with the Help Box is unclear.
