# BARIS Mission System: Mission Types, Planning, Execution and Failure Modes

Research notes for a cleanroom reimplementation of Buzz Aldrin's Race Into Space (BARIS, Interplay / Strategic Visions, 1993). Everything below is taken from the player's point of view: reviews, a Something Awful Let's Play (archived at lparchive.org), fan rules write-ups on the Kerbal Space Program and Orbiter forums, and Wikipedia.

**Cleanroom compliance.** No source code, data file, or GitHub/SourceForge repository page of the game was opened. One search hit pointed at the rewritten port manual hosted *inside* the game's GitHub repository (`https://github.com/raceintospace/raceintospace/blob/master/doc/manual/manual.md`); because the brief forbids browsing the game's GitHub repositories, that page was **not opened** and nothing here is derived from it. The search snippet for it (not the page) said only that the manual defines Earth-Orbital Rendezvous as a joint mission where capsule and lander launch separately and meet in Earth orbit, that skipped milestones are penalised, and that 8-12 day duration flights are prerequisites for lunar orbital and landing missions. The original 1993 manual and Bronner's 132-page *The Conquest of Space* companion were not found online in any readable form (archive.org search returned no scan; replacementdocs returned nothing). raceintospace.org is now a squatted/unrelated domain, and web.archive.org could not be fetched from this environment. Something Awful's own forum thread (which holds the LP author's full "possible missions" list) is behind an archives paywall; the Giant Bomb wiki, MobyGames reviews and KSP forum blocked direct fetches (the KSP threads were read through a text-reader proxy).

**Source key (used throughout):**
- WIKI = https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space
- SG = https://scientificgamer.com/in-praise-of-buzz-aldrins-race-into-space
- SS = https://www.spacesector.com/blog/?p=9465
- COMPUTE = https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php
- LPnn = https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%20nn (Something Awful LP by Frankomatic; index at https://lparchive.org/Buzz-Aldrins-Race-Into-Space/)
- KSP-RULES = https://forum.kerbalspaceprogram.com/topic/4762-race-into-space (fan "rules of the game" write-up, explicitly "from memory")
- KSP-WON = https://forum.kerbalspaceprogram.com/topic/51772-race-into-space-i-won
- OF-A = https://webmail.orbiter-forum.com/goto/post?id=336463 ; OF-B = https://webmail.orbiter-forum.com/goto/post?id=336467
- HOTU = https://www.homeoftheunderdogs.net/game.php?id=160
- GB = https://www.giantbomb.com/buzz-aldrins-race-into-space/3030-10819/
- FLATHUB = https://flathub.org/en/apps/org.raceintospace.Raceintospace

Caveat on versions: the LP and the Orbiter/KSP posts were played on the open-source *Race Into Space* port (RIS), which the port maintainers say "includes some improvements over the original game" ([FLATHUB](https://flathub.org/en/apps/org.raceintospace.Raceintospace)). Numbers from those sources may differ slightly from the 1993 DOS release; the reviews (SG, SS, COMPUTE, HOTU) describe the DOS/CD original.

---

## 1. The catalogue of mission types (hardware, prerequisites, launches, prestige)

### Takeaway
The game's Future Missions screen offers roughly sixty mission types (the box claimed "more than 300 variations"), from a 3-step Orbital Satellite to 20+-step lunar landings; each is defined by a step count, the hardware it consumes, the number of launch pads it occupies (1, or 2 for "joint" missions), a displayed safety penalty, and prestige that is large for a "first" and small-to-zero afterwards. The complete official list with per-mission prestige was not recoverable from documentation; the tables below are assembled from player-reported readouts.

### Cited Findings

**Scale of the catalogue**
- "The Future Missions tab lists 'sixty-odd' possible missions, from simple orbital satellites to full lunar landings," including planet flybys, lunar recon, probe landings, direct ascent; lunar landings via Earth Orbit Rendezvous or Lunar Orbit Rendezvous — [SG](https://scientificgamer.com/in-praise-of-buzz-aldrins-race-into-space)
- 1993 packaging advertised "over 30 different types of space hardware and more than 300 mission types"; mission types "included planetary and lunar flybys, LEM tests, lift-offs, space walks, lunar orbits and landings, splashdowns and more" — [WIKI](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space); COMPUTE also cites "more than 300 mission variations" — [COMPUTE](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- HOTU's list of mission families: sub-orbital and orbital (manned and unmanned), planetary and lunar flybys, LEM tests, lunar passes, lunar orbits, lunar landings; "twenty different approaches to the Moon" — [HOTU](https://www.homeoftheunderdogs.net/game.php?id=160)
- "A satellite placement has three steps. A Moon landing has well over twenty." — [WIKI](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space); SS says "Early missions have three or four steps. Late-game moon missions can reach around 20." — [SS](https://www.spacesector.com/blog/?p=9465)

**Early (Earth-orbit) mission types as read off the Future Missions screen by the LP author (steps / hardware / displayed penalty at that moment)**
- Orbital Satellite: 3 steps, "2 checks v Rocket, 1 check v Satellite"; requires 1 Rocket + 1 Satellite; 0 penalty — [LP06](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2006), [LP10](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2010)
- Unmanned Suborbital: 3 steps; 1 Rocket + 1 Capsule; 0 penalty — [LP14](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2014)
- Unmanned Orbital: 3 steps; 1 Rocket + 1 Capsule; 0 penalty — [LP14](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2014)
- Manned Suborbital: 3 steps; 1 Rocket + 1 Capsule + Primary/Backup crews; -1 penalty — [LP14](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2014)
- Manned Orbital: 6 steps; 1 Rocket + 1 Capsule + Primary/Backup crews; -4 penalty — [LP14](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2014)
- Manned Orbital EVA: 7 steps; adds 1 EVA Suit; -4 penalty — [LP14](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2014)
- Manned Orbital Duration: 7 steps; 1 Rocket + 1 Capsule + crew; -14 penalty (before any duration had been flown) — [LP16](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2016), [LP18](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2018)
- Manned Orbital Duration EVA: 8 steps; adds EVA suit; -14 penalty — [LP16](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2016)
- Mission names actually scheduled in the LP, showing further types: "Orbital EVA Duration (B)", "Manned Orbital Duration C", "Manned Orbital Duration (D)", "Unmanned Orbital Docking", "Lunar Flyby", "Manned Lunar Pass", "Manned Earth Orbital LM Test", "Manned Lunar Orbital", "Historical Lunar Landing" — [LP18](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2018), [LP22](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2022), [LP28](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2028), [LP34](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2034), [LP36](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2036), [LP38](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2038), [LP42](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2042), [LP48](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2048)
- The KSP winner used an "Agena test vehicle" for docking practice: "cheaper and could launch on an Atlas" — [KSP-WON](https://forum.kerbalspaceprogram.com/topic/51772-race-into-space-i-won)

**Unmanned probe / planetary missions (prestige only, do not unlock the Moon)**
- Ranger satellite "is for the various Flyby missions" (unit cost 4, R&D cost/team 3, weight 700, max safety 93%) — [LP34](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2034), [LP38](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2038)
- Planetary flybys per KSP-RULES: Mercury flyby 5 pts; Venus flyby 7; Mars flyby 7 (takes 2 seasons); Jupiter flyby 8 (7 seasons); Saturn flyby 9 (7 seasons); "gas giant missions take more than 3 years (7 turns)"; they "do not unlock the Moon, except for testing hardware", but "can help rebuild prestige after manned failures" — [KSP-RULES](https://forum.kerbalspaceprogram.com/topic/4762-race-into-space)
- LP author: "Venus was worth more Prestige than they realized" — [LP38](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2038)
- Orbiter player's log: Ranger III lunar flyby success = 5 pts; Ranger VI lunar flyby failure = -3 pts; Explorer III orbital satellite = 12 pts; Explorer I failure = -3 pts and "pad destroyed" — [OF-A](https://webmail.orbiter-forum.com/goto/post?id=336463), [OF-B](https://webmail.orbiter-forum.com/goto/post?id=336467)
- Probes to other planets "earn extra prestige" — [SS](https://www.spacesector.com/blog/?p=9465)

**Manned orbital laboratory / joint missions**
- "Manned orbital laboratory: requires docking two spacecraft and a joint duration of level C. Awards 6 points and requires two launches." — [KSP-RULES](https://forum.kerbalspaceprogram.com/topic/4762-race-into-space)
- "With two launchpads, you can fly joined missions: two launches for one mission." Max 3 missions per season with 3 pads (6/year) — [KSP-RULES](https://forum.kerbalspaceprogram.com/topic/4762-race-into-space)
- "It's possible to have three launch pads and three launches going on at the same time." — [SS](https://www.spacesector.com/blog/?p=9465)

**Lunar landing approaches (as the player sees them)**
- Historical manned landing: "one launch (usually Saturn V or N-1), one spacecraft, and one LM. Extra hardware may be needed, such as a Centaur stage for the Gemini 'Kicker-B' or a Docking Module for the MiniShuttle." — [KSP-RULES](https://forum.kerbalspaceprogram.com/topic/4762-race-into-space)
- LOR (lunar orbit rendezvous): "two launches, rendezvous in lunar orbit." EOR (Earth orbit rendezvous): "two launches, rendezvous in Earth orbit." — [KSP-RULES](https://forum.kerbalspaceprogram.com/topic/4762-race-into-space)
- Direct ascent: "one SuperBooster and one capsule/lander. No LM and no docking are needed. It is 'very expensive.'" — [KSP-RULES](https://forum.kerbalspaceprogram.com/topic/4762-race-into-space); "a direct ascent (the rocket itself lands on the moon)" — [GB](https://www.giantbomb.com/buzz-aldrins-race-into-space/3030-10819/)
- "Soyuz Landing: Soviet Special": "uses the Soviet 'Kicker-C' booster. The Soyuz docks with it, and the booster/lander reaches the surface. Docking is required, but no LM is needed." — [KSP-RULES](https://forum.kerbalspaceprogram.com/topic/4762-race-into-space)
- The LP's USSR side won with "Direct Ascent success in one try"; the US flew "Historical Lunar Landing" on both pads in Spring 1969 — [LP48](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2048), [LP49](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2049)
- Wikipedia: approaches include "lunar orbit rendezvous, Earth orbit rendezvous (in a different form), and direct ascent"; players may use "re-usable entry vehicles as a primary spacecraft (i.e. shuttles)... or even making the attempt using a 2-person spacecraft" — [WIKI](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- Historical landing prestige: "Historical Manned Lunar Landing, success, 40 pts" — [OF-B](https://webmail.orbiter-forum.com/goto/post?id=336467)

**Hardware eligibility rules shown in the in-game hardware descriptions (as transcribed by the LP author)**
- Mercury: "One man capsule. No Lunar Landings or Docking ability." — [LP14](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2014)
- Gemini: "Two man capsule. Can make it to the moon with a kicker and also dock. Can use a 1 man LM." — [LP16](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2016)
- Cricket Module: "1 man LM. Can be used with Gemini, Apollo, or XMS-2." (unit cost 8, weight 1000) — [LP34](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2034), [LP38](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2038)
- Kicker-B: "Need either this or Kicker-A for Lunar Missions not involving the Apollo or Jupiter." (cost 6, weight 600); "a very necessary piece of equipment for the Gemini/Shuttle school of Lunar Landings" — [LP28](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2028), [LP23](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2023)
- Docking Module: "Required for most of the Lunar Landing mission types." "The only thing that CANNOT be researched. All safety improvement comes from live testing." (cost 2, weight 300, max safety 93%) — [LP22](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2022), [LP34](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2034)
- EVA Suits: "Needed for EVA stuff." unit cost 0, weight 0, max safety 94% — [LP14](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2014)
- Capsule crew sizes: "Mercury and Vostok seat one, Gemini two, Apollo three, and Jupiter four." — [SS](https://www.spacesector.com/blog/?p=9465); Vostok/Mercury "have no docking port" — [KSP-RULES](https://forum.kerbalspaceprogram.com/topic/4762-race-into-space)
- "the first 4 man capsule in space is worth 20 points of Prestige for no obvious reason... Pretty sure it has to not explode for it to count though." — [LP42](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2042)
- Rocket payload caps seen: Atlas max payload 600; Titan 1500; Saturn V 3200 (an earlier LP table lists Saturn V as 3200 in LP38) — [LP14](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2014), [LP38](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2038); payload weights: Explorer 300, Mercury 500, Gemini 1200, Ranger 700, Cricket 1000, Kicker-B 600, Docking Module 300 — [LP14](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2014), [LP16](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2016), [LP38](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2038)
- Some rockets "like the Atlas, only suit short-range missions"; RIS config `altasLunar` "enables Atlas rockets for lunar missions, which are otherwise excluded" — [SS](https://www.spacesector.com/blog/?p=9465), [OF-A](https://webmail.orbiter-forum.com/goto/post?id=336463)
- Lunar missions are expensive because "each one has like 4 parts to buy" — [LP43](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2043)

**Prestige values for firsts, from one Orbiter player's log (historical US run)**
- Mercury I suborbital 18; Explorer III orbital satellite 12; Mercury II Earth orbit 12; Gemini IV (first two-man craft + first EVA + first manned docking stacked) 28; Gemini III docking failure -7; Ranger III lunar flyby 5; Apollo I "first manned spacecraft" 15; Apollo II manned lunar flyby 12; Apollo III manned lunar orbit 20; Apollo IV LM test in Earth orbit (partial failure) 1; Apollo V historical landing 40; Duration B/C/D and routine docking/EVA missions "small point amounts, such as 1 to 3 pts" — [OF-B](https://webmail.orbiter-forum.com/goto/post?id=336467), [OF-A](https://webmail.orbiter-forum.com/goto/post?id=336463)
- Final LP tallies: Real World US 9 firsts/112 prestige vs USSR 8/93; Mirror World US 8/72 vs USSR 9/134 — [LP index](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/)

### Inferences
- The "penalty" numbers next to each mission on the Future Missions list (0, -1, -4, -14, -7, -10) are the milestone/prerequisite penalty the game will apply to that mission's steps at that moment; they shrink as prerequisite missions are flown (e.g. LM test "-7... expected to drop after a successful Lunar Pass", LP43). (Inferred from LP readouts.)
- The hardware list implies a lunar mission needs: a rocket big enough for the summed payload weights, a capsule, an LM (unless Direct Ascent/Soyuz), a Docking Module (unless Direct Ascent), and a Kicker for Gemini/mini-shuttle lunar missions. (Inferred.)
- Prestige per first appears tiered by difficulty: satellite ~12, first man in space ~18, first manned lunar orbit ~20, landing 40; the Orbiter player's values are from one run, so they may include first/second-place scaling. (Inferred.)

### Gaps
- No documentation source gave the full official list of ~60 mission types with name, exact step count and prestige. The LP author's complete list exists only in a paywalled Something Awful post.
- Exact prestige table (first vs second vs later achievement) was not found in any readable documentation.
- Definitions of "hybrid" and "Jupiter-style"/mini-shuttle landing variants were not found beyond the one-line hardware notes above.

---

## 2. Milestones, prerequisite penalties and duration levels

### Takeaway
A fixed ladder of milestones (satellite → man in space → orbit → EVA → lunar flyby → duration B/C/D → manned lunar pass → manned lunar orbit → LM tests → landing) gates the landing; skipping any one applies a flat negative modifier to every step of dependent missions, scaled by how many steps were skipped (a fresh landing attempt starts around -45%). Duration is a ladder of lettered levels (B, C, D, ... with D = 8-12 days) that must be climbed in order; lunar pass needs C and lunar orbit needs D.

### Cited Findings
- "Skipping a milestone gives a safety penalty to any mission that depends on it. For example, skipping a crewed lunar orbital mission adds a safety penalty to all steps of a Moon landing." — [WIKI](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- "Advanced missions require intermediate steps. For example, crewed orbital flights should follow sub-orbital flights. Skipping steps applies a safety penalty to every check, scaled by how many steps were skipped." A direct lunar landing attempt from scratch is "highly unlikely to succeed." — [SG](https://scientificgamer.com/in-praise-of-buzz-aldrins-race-into-space)
- "a series of mission milestones, like rungs on a technological ladder... you can skip some or cut them short" and "fudge the recommended safety factor" — [COMPUTE](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- Milestone list (fan write-up, "from memory"): Orbital satellite; Manned mission (suborbital acceptable); Man in Earth orbit; EVA; Lunar flyby; Duration D flight (8-12 days) with B and C flown first; Manned lunar pass (Duration C); Manned lunar orbit (Duration D); LM tests. "Milestones award prestige, and several can be combined in one mission." — [KSP-RULES](https://forum.kerbalspaceprogram.com/topic/4762-race-into-space)
- "The initial safety malus for a Lunar Landing is -45%, described as 'suicidal.' The target is a -1% to -4% range." — [KSP-RULES](https://forum.kerbalspaceprogram.com/topic/4762-race-into-space)
- LM test penalty: "without them, every LM-dependent step has a -9% penalty. Three points cancel it, each point removing 3%. An LEO LM test gives 1 point, and a lunar orbit LM test gives 2." — [KSP-RULES](https://forum.kerbalspaceprogram.com/topic/4762-race-into-space); corroborated by the Orbiter player's calculation "90% (R&D) minus 9% (a penalty for having 0 LM points), plus 4% (Aldrin's skill), for 85% reliability" — [OF-B](https://webmail.orbiter-forum.com/goto/post?id=336467)
- Docking experience: "Docking: safety starts at 40%. Successful docking adds 10%, and a failed attempt adds 5%." — [KSP-RULES](https://forum.kerbalspaceprogram.com/topic/4762-race-into-space)
- Lunar reconnaissance ("Moon Landing Zones" knowledge): starts at 55%; "Lunar Flybys, Manned Lunar Passes, and Lunar Probes will all add to this assuming they're at least somewhat successful" — [LP01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001); per KSP-RULES "Successful probes add 5% each, and a robot lander adds 15% (5% if it orbits but fails to land). A manned lunar pass adds 5%, and a manned lunar orbit adds 10%." — [KSP-RULES](https://forum.kerbalspaceprogram.com/topic/4762-race-into-space); LP: the moon is "Mostly complete, will probably be close to topped out with the Lunar Pass and eventual orbital" — [LP42](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2042)
- Penalty readouts observed on the LP's Future Missions screen over time: Manned Orbital Duration -14 before any duration flight (LP16); "Earth Orbit LM test is at 0 penalty. Lunar Orbit [LM test] is at -7" (LP40); "all Lunar Landing missions you guys could do with the Gemini are currently at -10" (LP36); landing attempt "showing at -4" the turn before launch (LP43); Duration D "I'm honestly not sure if there's any penalty... as it doesn't update appropriately for the level you're trying", estimated "-1 at worst" if Duration C succeeds (LP23) — [LP16](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2016), [LP40](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2040), [LP36](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2036), [LP43](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2043), [LP23](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2023)
- "Flight experience: without earlier missions, expect modifiers such as '-20% off your safety factor.'" — [SS](https://www.spacesector.com/blog/?p=9465)
- Duration levels: "Duration B and C are prerequisites for Duration D"; "Duration D flight (8-12 days)"; orbital lab needs "joint duration of level C" — [KSP-RULES](https://forum.kerbalspaceprogram.com/topic/4762-race-into-space); the KSP winner ran Gemini "Endurance B through E" — [KSP-WON](https://forum.kerbalspaceprogram.com/topic/51772-race-into-space-i-won); LP scheduled "Orbital EVA Duration (B)", "Duration C", "Duration (D)" in that order (LP18, LP22, LP28). The Future Missions planner has "pie slices above the reset button" that increase mission duration, "which builds flight experience quickly" — [SS](https://www.spacesector.com/blog/?p=9465)
- Unmanned test flights: the player can run "Unmanned Suborbital" and "Unmanned Orbital" versions of capsule flights (0 penalty, 3 steps) and "Unmanned Orbital Docking" — [LP14](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2014), [LP22](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2022)

### Inferences
- Duration levels are lettered A-F (brief's premise); sources confirm B, C, D, E exist and that D = 8-12 days; A is presumably the trivial sub-day flight and F the longest. (Inferred; A and F unconfirmed.)
- The displayed penalty = sum of missing-milestone components (e.g. -9 for no LM points, step-skip components, duration-skip components), and it is recomputed each turn from the current record. (Inferred from the readouts changing as milestones were flown.)

### Gaps
- Exact day ranges for Duration A, B, C, E, F not found.
- The exact per-skipped-milestone penalty value (e.g. how -45% is composed) was not found in any documentation source.
- Whether a *successful* higher duration retroactively credits lower levels (the brief's "how duration is built up") was not confirmed for BARIS; one forum post describing that rule was about a different game and was excluded.

---

## 3. Mission scheduling: Future Missions, Vehicle Assembly Building, Mission Control

### Takeaway
Missions are planned a full turn ahead: pick the pad and mission in Future Missions (Administration), end turn, then next turn assemble the hardware in the VAB (with an AutoPurchase button) and assign crews, set the launch month in Mission Control (May = free, April = -3 MB and -3 safety on every step, March = -6/-6), end turn, and the launch resolves at the start of the next turn. A scheduled mission can be scrubbed at no cost.

### Cited Findings
- Workflow as described by a player: "1. Open the Administration building and go to the Future Missions screen. 2. Use the arrows to pick a mission. The 'A-OK/Danger/Caution' rating indicates how likely it is to succeed. 3. End your turn. 4. Next turn, go to the VAB, find the mission, and click 'Assemble Hardware.' If you have all the parts, click assign. Otherwise, use the autopurchase button. 5. Go to the Mission Control building and assign a launch date. 6. End your turn. On the following turn, the rocket launches." — [KSP-WON](https://forum.kerbalspaceprogram.com/topic/51772-race-into-space-i-won)
- "To schedule a mission, go to mission control, select Future Missions, choose a launch pad, then select the mission." Early moon attempts: "there will be a hefty penalty on your launch." — [SS](https://www.spacesector.com/blog/?p=9465)
- "Anything scheduled will always happen next season." — [LP01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001)
- Pads: start with one Launch Facility, buy up to two more for 20 MB each, "This price will never go up" — [LP01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001); max 3 missions/season — [KSP-RULES](https://forum.kerbalspaceprogram.com/topic/4762-race-into-space)
- VAB: "shows the rocket carrying the payload... You can buy everything a mission needs in one click. Manned missions get a mission patch that appears in the astronauts' mission history." — [SS](https://www.spacesector.com/blog/?p=9465); "The assembly screen shows what a mission requires and lets you change options when several exist. 'AutoPurchase' buys any missing components directly from that screen." — [LP06](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2006)
- Rushing (Mission Control launch month): "A mission launched in May has no cost or penalty. Launching in April costs 3 MB and applies a -3 Rushing Penalty to all steps of the mission. Launching in March costs 6 MB and applies a -6 Rushing Penalty to all steps." — [LP06](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2006); "Rushing a mission increases the cost and decreases the safety" — [SS](https://www.spacesector.com/blog/?p=9465)
- Scrubbing: "The Orbital Satellite mission can be launched again for 4 MB in hardware costs, or scrubbed for no cost." — [LP08](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2008); weather can cancel a season's missions ("Cancelled due to weather") — [LP16](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2016)
- Crews: manned missions list "Primary/Backup teams" as a requirement; "Assign a backup flight crew so a random event, like a fatal accident, doesn't scrub the mission." — [LP14](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2014), [SS](https://www.spacesector.com/blog/?p=9465)
- Pre-launch "Pay or Safety" event: "Pay 10 MBs up front, or suffer a 10% safety factor penalty on the Atlas's next mission" — [LP06](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2006); a windfall event "will let you ignore one failure in a future Mercury based mission" — [LP08](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2008)
- Each hardware item shows "Unit Cost, R&D Cost Per Team, Unit Weight or Max Payload, Current Safety, Max R&D, Max Safety" — [LP22](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2022)

### Inferences
- The one-turn lead means a mission's hardware must exist (or be auto-purchased) in the turn *after* planning and *before* launch; hardware safety is therefore the value at launch, after that turn's R&D. (Inferred.)
- "A-OK / Caution / Danger" is a coarse readout of the net safety after penalties, shown on the Future Missions screen. (Player description; exact thresholds unknown.)

### Gaps
- "Downgrading" a mission (changing a scheduled mission to a lesser one in the VAB/Mission Control) was not described in any source found.
- Thresholds for A-OK/Caution/Danger not found.

---

## 4. Mission execution: step sequence, rolls, penalties and failure handling

### Takeaway
A mission is a linear list of steps (3 for a satellite, 6-8 for manned orbital, ~20+ for a landing); each step rolls a percentile against the safety of the specific hardware that step uses, modified by crew skill, milestone/skip penalties and rush penalties. A failed roll triggers a hidden severity roll ranging from no effect through aborts and hardware loss to crew death; the player is mostly a spectator but is occasionally offered an abort/proceed choice.

### Cited Findings
- "Missions depend on dice-style checks. At each step, a component's safety factor is compared against a random number, adjusted by crew skill bonuses (for crewed missions), safety penalties, and other factors. A failed check causes an error, which can range from catastrophic mission failure to no effect... Missions are mostly non-interactive. During an incident, the player may occasionally choose to abort or proceed." — [WIKI](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- "Each step rolls against a component's safety: reentry against the capsule, lunar landing against the LM, docking against the docking module. Rolls are made against the safety factor, a percentage. Rolling above it triggers something bad, with severity depending on the step." — [SS](https://www.spacesector.com/blog/?p=9465)
- Step examples: "Each flight has stages (launch, orbital insertion burn, re-entry, etc.), and each stage runs a safety check." "Failing a launch check can mean an explosion minutes after liftoff or on the pad, which requires a costly rebuild." Outcomes "range from trivial (an astronaut tripping on the lunar module ladder) to catastrophic (total loss of crew and craft)." — [SG](https://scientificgamer.com/in-praise-of-buzz-aldrins-race-into-space)
- Orbital Satellite = "3 steps, 2 checks v Rocket, 1 check v Satellite" — [LP06](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2006)
- Severity: "A failed check triggers a hidden second roll that determines how severe the failure is." Experienced crews "more often survive serious problems", e.g. "negative ignition, but crew was able to perform a makeshift burn"; "For fresh recruits, a major problem usually means death." — [OF-B](https://webmail.orbiter-forum.com/goto/post?id=336467), [OF-A](https://webmail.orbiter-forum.com/goto/post?id=336463)
- Accident band: "if the roll lands above your normal roll but below the crew skill, you get an accident instead. It applies modifiers to future rolls and can force an abort." — [SS](https://www.spacesector.com/blog/?p=9465)
- Failure examples seen: "Minor: failing to reach a high enough orbit, then re-entering for a safe landing. Severe: the rocket exploding on the launch pad. Rare: astronauts falling and breaking their visor on the lunar surface." — [SS](https://www.spacesector.com/blog/?p=9465); "Good ole' Neil died due to an erratic thruster"; crew can be injured (hospital) — [KSP-WON](https://forum.kerbalspaceprogram.com/topic/51772-race-into-space-i-won); "Failed atmosphere exit" cost -10 prestige; a failed Lunar Pass "shaken Morale" — [LP40](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2040); Explorer I failure "-3 pts, pad destroyed" — [OF-A](https://webmail.orbiter-forum.com/goto/post?id=336463)
- Mid-mission scrub prompt: the LP author asks readers how to handle "a mid-mission failure that offers a scrub", noting such prompts appear most during Lunar Landings — [LP48](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2048); on the final launch "another 100. No Scrubbing won the day in the voting though" (a roll of 100 shown on the launch screen) — [LP49](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2049)
- Composition of a step's effective chance (player calculation): "90% (R&D) minus 9% (a penalty for having 0 LM points), plus 4% (Aldrin's skill), for 85% reliability" — [OF-B](https://webmail.orbiter-forum.com/goto/post?id=336467)
- Rush penalty applies "to all steps of the mission" (-3 April, -6 March) — [LP06](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2006)
- "Once a rocket launches, you have no direct control, but you watch each stage unfold." — [COMPUTE](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- Difficulty: "Game Level One makes things 'slightly less likely' to go wrong"; "Historical Model makes American equipment more expensive and Soviet equipment more likely to explode" — [LP01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001); "A 'basic' model equalizes costs and safety factors between the two sides." — [WIKI](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)

### Inferences
- Effective pass chance per step ≈ hardware current safety + crew-skill bonus (0 to +4, section 6) − milestone/skip penalty − rush penalty − event penalty; a d100 roll at or below that passes. (Inferred from the quoted pieces; the exact order of operations and clamping are unknown.)
- A plausible manned-orbital 6-step list consistent with the sources: launch (rocket), staging/orbit insertion (rocket), orbital ops (capsule), [EVA (suit)], [docking (docking module)], retro/re-entry (capsule), recovery (capsule). The lunar landing adds translunar injection, lunar orbit insertion, LM separation/descent (LM), surface EVA (suit), ascent and docking (LM/docking module), trans-Earth injection and re-entry. (Inferred from the component-to-step mapping in SS and step counts; exact names not documented.)

### Gaps
- The verbatim step names for each mission type and the exact count for lunar missions were only available in LP screenshots, which are not readable here.
- The severity table (which outcomes are possible per step, and their probabilities) was not found in documentation.
- No source explains a separate "new mission" (first-flight-of-type) penalty distinct from the milestone penalty.

---

## 5. Safety factor from the player's view

### Takeaway
New hardware starts low (10% for a rocket, 40% for a satellite in the LP), R&D raises it each turn up to a per-item "Max R&D" (typically 75-85%, up to 95% for simple satellites), and only flight experience lifts it beyond that toward "Max Safety" (90-98%); each successful check adds about 1%, failures cost "a large chunk", and the Docking Module cannot be researched at all.

### Cited Findings
- "A new program starts with a safety factor of 0%. A first launch attempt is guaranteed to explode on the pad. R&D raises the factor, but there is a hard ceiling, typically 75-85%. Further gains require test flights. Each successful flight check increases the equipment's safety factor by 1%." — [SG](https://scientificgamer.com/in-praise-of-buzz-aldrins-race-into-space)
- LP: "when you first buy things, they get a base level of Safety added to them." Satellite starts at 40%, rocket at 10%. R&D "handily tells you how much safety you gained for your investment." — [LP02](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2002)
- Observed Max R&D / Max Safety pairs: Explorer 95/98; Atlas 84/98; Titan 90/98; Saturn V 95/98; Mercury 80/90; Gemini 84/94; Cricket LM 90/94; Kicker-B 94/96; EVA Suits 91/94; Ranger 90/93; Docking Module "NOT POSSIBLE"/93 — [LP14](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2014), [LP16](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2016), [LP22](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2022), [LP34](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2034)
- "Reusing a rocket, capsule, or satellite gradually improves its safety beyond the maximum researchable level." "Losing a crew... costs prestige, skilled astronauts, and a large chunk of safety." — [SS](https://www.spacesector.com/blog/?p=9465)
- "Reliability rises only about 1% per successful launch, which one player felt made unmanned flights impractical." — [KSP-WON](https://forum.kerbalspaceprogram.com/topic/51772-race-into-space-i-won)
- "A spacecraft's safety caps at 94%. Pilot skill adds 0-4%... which can push safety to 98%. Voskhod has a maximum safety of 92%." — [OF-A](https://webmail.orbiter-forum.com/goto/post?id=336463)
- Research spillover: "If a program reaches over 75% safety, the next program gets an R&D start bonus... Apollo starts at 5% alone, but at 40% if Mercury and Gemini both exceed 75%. Apollo's R&D maximum is 89%." — [KSP-RULES](https://forum.kerbalspaceprogram.com/topic/4762-race-into-space); RIS v1.1 "technology transfer now gives partial credit for components below 75%" — [OF-B](https://webmail.orbiter-forum.com/goto/post?id=336467)
- Docking Module: "The only thing that CANNOT be researched. All safety improvement comes from live testing." Observed climbing 60% → 80% → 90% → 93% over the LP via Unmanned Orbital Docking flights — [LP28](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2028), [LP34](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2034), [LP40](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2040), [LP48](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2048)
- Kicker-B dropped 94% → 88% between LP42 and LP48 (after lunar missions), illustrating a failure lowering safety — [LP42](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2042), [LP48](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2048)
- "Spamming unmanned Mercury launches builds the safety factor for later crewed flights." — [SG](https://scientificgamer.com/in-praise-of-buzz-aldrins-race-into-space); "Research before manned flights. Otherwise, 'unless you want them coming back in a box.'" — [SS](https://www.spacesector.com/blog/?p=9465)
- "the failure rate of missions is much higher than it really was in the US/Soviet space race" (MobyGames reviewer quoted in search summary) — [WIKI/search](https://www.mobygames.com/game/8276/)

### Inferences
- "Safe" in practice: players flew manned missions at ≥80% and lunar landings at an average 91% component safety (OF-B); the LP waited until Gemini and Titan were at their 94%/98% caps before lunar missions. (Inferred target band ~85-94%.)
- Base safety on purchase likely varies by item class (satellite 40, rocket 10 in LP02; capsule Apollo 5 per KSP-RULES). (Inferred.)

### Gaps
- Exact rule for how much safety a *failed* check removes was not documented (only "a large chunk" and the observed Kicker-B drop).
- Whether safety gain per successful step is exactly +1% in the DOS original vs the port was not separately confirmed.

---

## 6. Astronaut skill effects on mission steps

### Takeaway
Each astronaut has five skills (Capsule Pilot, LM Pilot, EVA, Docking, Endurance) rated 0-4; the relevant skill is added on top of the dice roll for the step that uses it (0 to +4%), Endurance applies to everyone on all missions, and experienced crews also appear to get more survivable failure outcomes.

### Cited Findings
- "Astronauts have five stats: pilot, EVA, LM, Docking, and Endurance. Endurance applies to all astronauts. Pilot is required for every mission. EVA and pilot matter all round. LM and Docking are late-game skills. Crew skill is added on top of dice rolls. A low LM pilot could crash the lander." — [SS](https://www.spacesector.com/blog/?p=9465)
- "Pilot skill adds 0 to 4%, so a highly skilled pilot can reach 98%" over the 94% cap — [OF-A](https://webmail.orbiter-forum.com/goto/post?id=336463)
- COMPUTE: astronauts "are rated on capsule handling, lunar module piloting, spacewalking, docking, and endurance, and are sent to training facilities to improve those ratings" — [COMPUTE](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- Observed stat ranges 0-4 (e.g. Grissom Cap 3/LM 0/EVA 0/Dock 3/End 2; Slayton Cap 4), plus a Mood score (67-81) — [LP14](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2014); only Capsule Pilot and Endurance are visible before hiring — [LP06](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2006)
- Training: new hires sit in Basic Training until their 4th season; Advanced Training (e.g. "ADV Dock") raises a skill; "Leave a crew about a year to learn a capsule before flying them." — [LP06](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2006), [LP28](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2028), [SS](https://www.spacesector.com/blog/?p=9465)
- "Astronaut and cosmonaut skills and morale affect mission performance." — [WIKI](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space); crew compatibility ("astronaut chemistry") is rated — [GB](https://www.giantbomb.com/buzz-aldrins-race-into-space/3030-10819/); RIS config `compt_nauts` 1-10 (default 10 hardest) — [OF-A](https://webmail.orbiter-forum.com/goto/post?id=336463)
- Winner's practice: "kept pilots at level 4 in their assigned skill"; "Train at least four astronauts in docking" — [KSP-WON](https://forum.kerbalspaceprogram.com/topic/51772-race-into-space-i-won)

### Inferences
- Skill-to-step mapping (inferred from SS): Capsule Pilot → launch/orbit/re-entry steps; EVA → EVA steps; Docking → docking steps; LM Pilot → LM descent/landing/ascent; Endurance → duration steps.

### Gaps
- Whether the skill bonus is the single relevant crew member's skill or a crew sum/average was not documented.
- Mood/morale's numeric effect on rolls not documented.

---

## 7. The Mission Control / launch screen

### Takeaway
Launches play back between turns as a non-interactive movie: digitised launch footage or stop-motion animation on top, a per-step readout/bar chart of the dice rolls along the bottom, and the only player input is an occasional abort/continue prompt on an incident.

### Cited Findings
- "Launches play as a video between turns. A bar chart at the bottom shows the dice rolls, and the top shows real launch footage. Footage doesn't exist for every craft combination." — [SS](https://www.spacesector.com/blog/?p=9465)
- "Once a rocket launches, you have no direct control, but you watch each stage unfold. Stop-motion animations and digitized launch rumbles provide the visuals and sound" ("makeshift" animations) — [COMPUTE](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- "Missions are mostly non-interactive. During an incident, the player may occasionally choose to abort or proceed." — [WIKI](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- The LP author reports seeing "another 100" (a roll of 100) on the launch screen and that scrub prompts appear most on Lunar Landings — [LP49](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2049), [LP48](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2048)
- The game "uses crude FMV and pre-recorded audio. A special edition CD-ROM had better FMV" — [GB](https://www.giantbomb.com/buzz-aldrins-race-into-space/3030-10819/)

### Inferences
- The bar chart is the per-step pass/fail readout: each bar is one step's roll against that step's threshold. (Inferred.)

### Gaps
- Exact on-screen labels of the step readouts and the news-flash layout were only in LP screenshots (not readable).

---

## 8. Post-mission results: prestige, firsts, safety and crew consequences

### Takeaway
After the launch replay a news flash/results screen reports success or failure; prestige is added (large for a first, "much smaller, or possibly nothing" for second), subtracted for failures (more for deaths), the hardware's safety moves up (+1% per passed check) or down, and crews gain flight history, morale changes, injuries or deaths.

### Cited Findings
- "Being first at a space milestone... gives a 'hefty prestige bonus' that raises funding and score. Coming second gives a much smaller bonus, or possibly nothing." — [SG](https://scientificgamer.com/in-praise-of-buzz-aldrins-race-into-space)
- "The second successful mission of a given type usually earns some points. Later ones earn few or none. Mission failures cost prestige, especially those causing astronaut or cosmonaut deaths." — [WIKI](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- Prestige is "effectively the score and determines funding"; "Failed missions reduce prestige. Losing a crew is worse: it costs prestige, skilled astronauts, and a large chunk of safety." — [SS](https://www.spacesector.com/blog/?p=9465)
- Budget is granted once a year each spring and depends on prestige — [LP01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001); the Budget Office graphs US vs USSR Prestige, Expenditures and Budget — [LP01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001)
- Observed deltas: Explorer I failure -3; Gemini III docking failure -7; failed atmosphere exit -10; a failed Lunar Pass "shaken Morale"; Soviet Mercury Satellite first "put them back in the lead for Space Firsts" — [OF-A](https://webmail.orbiter-forum.com/goto/post?id=336463), [LP40](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2040), [LP38](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2038)
- Stacking firsts: one Gemini IV flight scored 28 for "two-manned spacecraft, first EVA, first manned docking"; "Crewing a single mission with multiple firsts... stacked points" — [OF-B](https://webmail.orbiter-forum.com/goto/post?id=336467)
- Crew consequences: death (erratic thruster), hospital, retirement for health/personal reasons, "Washed Out: Injury", morale drops after failures — [KSP-WON](https://forum.kerbalspaceprogram.com/topic/51772-race-into-space-i-won), [LP34](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2034), [LP10](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2010)
- Being fired: "falling too far behind can get you fired" — [COMPUTE](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php); one player was fired despite first satellite and first man in space — [KSP-WON](https://forum.kerbalspaceprogram.com/topic/51772-race-into-space-i-won); Wikipedia says dismissal is rare and "only happens to a human player doing essentially nothing" — [WIKI](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- Game end: a successful crewed landing ends the game; "the earlier you win, the higher your score"; one run ended with "Director Rating of 204 pts" — [WIKI](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space), [KSP-RULES](https://forum.kerbalspaceprogram.com/topic/4762-race-into-space), [OF-A](https://webmail.orbiter-forum.com/goto/post?id=336463)

### Inferences
- A mission patch is attached to each manned mission and appears in crew histories (SS), so the results screen likely also records the mission in astronaut flight logs. (Inferred.)

### Gaps
- Layout/text of the results screen and the "first" announcement was not described in prose by any source.

---

## 9. Known strategy and progression

### Takeaway
The consensus progression is: satellite → unmanned capsule tests → manned suborbital → manned orbital → EVA → duration B/C/D (Mercury then Gemini) → unmanned docking tests (cheap Agena-type target on Atlas) → lunar flyby probes → manned lunar pass → manned lunar orbit → LM tests (LEO then lunar orbit) → landing with every penalty driven to about -1 to -4 and components near their 94-98% caps; the USSR has the Soyuz/Kicker-C and Direct Ascent shortcuts, the US the Gemini+Kicker route.

### Cited Findings
- "Use Gemini as the core program, and focus on docking and EVAs while advancing Apollo/Saturn. Train at least four astronauts in docking... Accept some risk in Mercury/Explorer if Gemini is strong." Mercury: "Do all possible missions with Mercury" (Suborbital, Orbital, EVA, Duration B); Gemini: "Endurance B through E, then docking and EVA"; Pioneer/Ranger probes alongside; "Apollo/Saturn: rushed through with the minimum number of missions needed." — [KSP-WON](https://forum.kerbalspaceprogram.com/topic/51772-race-into-space-i-won)
- Landing target: drive the lunar landing malus from -45% to "-1% to -4%"; LM points: LEO test = 1, lunar-orbit test = 2, 3 cancel the -9%; dockings +10%/+5%; recon to raise landing-zone knowledge — [KSP-RULES](https://forum.kerbalspaceprogram.com/topic/4762-race-into-space)
- Soviet-specific: "Soyuz Landing: Soviet Special" (Kicker-C, docking but no LM); Voskhod's 92% cap makes it "risky for lunar missions"; docking "was added to Voskhod" as a balance simplification — [KSP-RULES](https://forum.kerbalspaceprogram.com/topic/4762-race-into-space), [OF-A](https://webmail.orbiter-forum.com/goto/post?id=336463), [WIKI](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- LP's winning timeline (US): docking module live-tested from 1962 via Unmanned Orbital Docking; Lunar Flybys 1965-66; Manned Lunar Pass and LM tests 1966-67; Manned Lunar Orbital 1967; two Historical Lunar Landings on pads A and B in Spring 1969 — [LP22](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2022), [LP34](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2034), [LP40](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2040), [LP42](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2042), [LP43](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2043), [LP48](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2048)
- Risk thresholds players quote: 94% spacecraft cap, 98% with a 4-skill pilot; average 91% on a successful landing; "0% ... guaranteed to explode"; "Mercury started around 80% reliability" before manned flight — [OF-A](https://webmail.orbiter-forum.com/goto/post?id=336463), [SG](https://scientificgamer.com/in-praise-of-buzz-aldrins-race-into-space), [KSP-WON](https://forum.kerbalspaceprogram.com/topic/51772-race-into-space-i-won)
- "The core tension is flying safely versus advancing quickly to beat the rival"; "if your opponent ends up on the Moon before you do it's game over." — [SG](https://scientificgamer.com/in-praise-of-buzz-aldrins-race-into-space)
- Don't spread thin on planetary probes; use them to rebuild prestige after manned disasters — [KSP-RULES](https://forum.kerbalspaceprogram.com/topic/4762-race-into-space)

### Inferences
- The "usual safe threshold" players aim for before committing crews is roughly 80%+ for early capsules and ~90%+ (near cap) for lunar hardware, with all displayed penalties ≤ 4. (Inferred from the quoted practices.)

### Gaps
- No published risk table (probability of mission success by component safety and step count) was found; players reason step-by-step from the displayed percentages.
