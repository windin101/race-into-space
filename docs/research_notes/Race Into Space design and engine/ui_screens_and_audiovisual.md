# Buzz Aldrin's Race Into Space (1993/1994): UI screens, flow and audiovisual presentation

Research notes for a cleanroom reimplementation. Everything below is from the player's point of view, drawn from reviews, box copy, a screenshot-driven Let's Play, and retrospective articles. **No source code, forks, data files or GitHub repositories were opened.** Where a search engine returned a snippet from a GitHub release-notes page, that is flagged inline and the page itself was not fetched.

Sourcing caveats that apply throughout:
- MobyGames (both `mobygames.com/game/1264/...` and `mobygames.com/game/8276/`) returned HTTP 403 / a bot-check interstitial on every attempt (direct, via Wayback, via a text proxy), so credits and the screenshot gallery there could not be read. The URLs are still listed in the "where to find screenshots" section as pointers for a human.
- `raceintospace.org` no longer belongs to the game project; it now hosts an unrelated "game development studio" marketing site with casino-sponsor links. Do not send the design team there. — [raceintospace.org (fetched 2026-10-11)](https://www.raceintospace.org/)
- The Something Awful Let's Play (lparchive.org) is of the open-source *Race Into Space* port rather than the DOS original, but its screens are the same screens; it is the most detailed screen-by-screen walkthrough available in text form. Treat exact layouts described from it as "port-era" unless corroborated by a 1993/1994 source.
- The original manual (floppy or CD) was not found online in a fetchable form; replacementdocs and archive.org searches returned nothing usable, and archive.org is blocked from this environment.

---

## Key Question 1: Screen inventory and navigation (title/setup, Spaceport map, every building/screen, where each navigates)

### Takeaway
The game is a hub-and-spoke "menu that looks like a place": a static aerial/isometric painting of Cape Canaveral or Baikonur on which each building is a clickable hotspot that opens a dedicated full-screen panel; the flagpole ends the turn. There are "nearly 30 information-packed screens" in total, almost all static, reached from the spaceport hub or from shortcut buttons inside related buildings (e.g. Purchasing has a button to R&D).

### Cited Findings

**Overall structure and navigation model**
- "Each player controls a space center, which doubles as a navigational menu, and directs funding toward purchasing hardware, research and development, recruiting and training astronauts, and conducting launches." — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- "The main navigation is an aerial view of each side's spaceport, Cape Canaveral or Baikonur. New buildings appear as programs grow." Landmarks visible on the map include the Capitol or Kremlin, the Pentagon or KGB headquarters, Arlington National Cemetery and the Kremlin Wall. The game has "nearly 30 information-packed screens" and "consists almost entirely of static screens." — [COMPUTE! Oct 1993, Scott A. May](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- The space centre "looks sparse at the start and grows with the program"; astronaut facilities appear as the program develops. "Clicking a building opens a separate screen"; the reviewer describes "a simple UI that makes it easy to navigate them." "Buildings have shortcut buttons to related buildings, such as the purchasing building linking to R&D." — [SpaceSector review, 2013](https://www.spacesector.com/blog/?p=9465)
- The LP author describes the game as "pretty menu based" and does most updates "in screenshot form." — [LP Archive index](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/)
- The Cape is "your base of operations"; buildings are clicked to open them; cash on hand is shown in the bottom-right corner of the Cape screen; starting budget is 60 MegaBucks. — [LP Update 01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001/)
- Baikonur: "Here's where us Soviets make our magic happen, Baikonur. Functionally, it's exactly the same as the Cape, just laid out differently." — [LP Update 03](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2003/)
- The map grows: after buying the Explorer program "a new building in the middle of the view" appears that "serves as the building for all the unmanned items." Clicking it shows the satellite program's stats. — [LP Update 04](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2004/)
- By Fall 1958 (after recruiting) the Cape is "getting a little busy": new buildings at bottom centre are the Astronaut Center and Basic Training; upper-right facilities are Advanced Training. — [LP Update 08](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2008/)
- End of turn: the player ends the turn by clicking the flagpole on the spaceport map ("patriotically click on the flagpole"). — [LP Update 02](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2002/)

**Title / game setup screen**
- The setup screen shows player names at the top (default name in the LP's port build was "Goons"; the author later changed it), a Game Level setting, an "Astro/Cosmonaut Selection Level" setting, and Model/Roster options: "Basic Model" makes both sides identical apart from equipment names; "Historical Roster" offers mostly real astronauts. — [LP Update 01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001/)
- New Game presents "a number of options": three AI difficulty settings that act as handicaps rather than weakening the AI; an option to make the other faction human-controlled (hot-seat); two game modes, Historical (US hardware pricier but more reliable, Soviet cheaper but less reliable) and Basic (balanced); and an astronaut difficulty setting that controls how much information you get when recruiting. — [SpaceSector](https://www.spacesector.com/blog/?p=9465)
- Period description of the same options: "Basic Model: Both sides start on equal ground. Historical Model: U.S. costs are higher and U.S. reliability is better. Either model can use historical or custom astronaut and cosmonaut rosters. Game types and difficulty levels balance human and computer opponents. One player controls each side." Three difficulty settings "affect overall conditions and performance and raise official expectations." — [COMPUTE! Oct 1993](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- CD-ROM box: "Select one of three difficulty levels, including a new Quick Start beginner level"; "Play as the U.S. or Soviets against a human or computer opponent"; "Race a friend by full modem or e-mail play." — [Eli's Software Encyclopedia, CD-ROM box text](https://elisoftware.org/wiki/Buzz_Aldrin%27s_Race_Into_Space_(PC,_CD-ROM)_Interplay_Productions_-_1993_USA,_Canada_Release)
- Wikipedia's infobox caption refers to a "selection screen (v1.1.0.2 Pandora version)" i.e. a side-selection screen exists in the port; no further description. — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)

**Turn-start sequence: season/year card, then newscast**
- "The first screen each turn shows the Season and Year, followed by the news." The game runs through 1977. — [LP Update 01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001/)
- "Each turn begins with a randomly chosen 'event card,' usually with historical information and sometimes a positive or negative effect." — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- "Each turn opens with a newscast from 'Carter Walcrite,' a nod to Walter Cronkite." — [The Digital Antiquarian](https://filfre.net/?p=4158)
- "Each turn opens with a new video representing a randomly drawn event card. Events range from an astronaut dying in a car crash to a rocket failure mode. The first turn has no good or bad news." Videos "get repetitive quickly, especially for the Soviet Union." — [SpaceSector](https://www.spacesector.com/blog/?p=9465)
- The Soviet newscast has its own copy and a sidebar ticker; the LP quotes "The Soviets buzz as a new head of their Space Program is named" and a joke sidebar line about Soviet citizens vs "fat capitalist pig" Americans. — [LP Update 03](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2003/)
- Some news items carry a hidden second page (the LP shows a `News2` screenshot: "Schirra was a washout" and "Ben-Hur won an Oscar"). — [LP Update 10](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2010/)
- Some turns open with a forced decision prompt before the news: "Pay 10 MBs up front, or suffer a 10% safety factor penalty on the Atlas's next mission." — [LP Update 06](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2006/)
- News can also deliver mechanical windfalls ("you get an event that will let you ignore one failure in a future Mercury based mission"; "the 'You can research better' event"). — [LP Update 08](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2008/); [LP Update 04](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2004/)

**Administration building (sub-menu)**
- Clicking Administration opens a menu with: **Budget Office** (graphs comparing "US Prestige, Expenditures, and Budgeting" with the Soviets; empty on turn 1), **Hardware Purchase** (invest in equipment projects from an equipment list), **Future Missions** (schedule missions for the next season), **Astronaut Recruiting** (not available until Spring 1958), and **Options, Save, and leave menu**. — [LP Update 01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001/)
- Budget screen (USSR side) shows budget projections; both sides start with 60 MB. — [LP Update 03](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2003/)
- Prestige "acts as the score"; funding is set at the start of each year based on performance, and prestige affects funding. — [SpaceSector](https://www.spacesector.com/blog/?p=9465)
- Money is abstracted to "MegaBucks"; the yearly budget is based on "Prestige" gained from missions. — [LP Archive index](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/)

**Hardware Purchase (Equipment list) screen**
- After purchase, the item gets a base Safety rating and "a new picture for the item" (Explorer satellite 40%, Atlas rocket 10% in the LP). — [LP Update 02](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2002/)
- Each program entry carries Unit Cost, R&D Cost Per Team, Unit Weight or Max Payload, Current Safety, Max R&D and Max Safety, plus a descriptive note (e.g. Mercury: "One man capsule. No Lunar Landings or Docking ability."; EVA Suits: "It's a spacesuit. Needed for EVA stuff."). — [LP Update 08](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2008/); [LP Update 20](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2020/)
- Over 30 types of space hardware; over 300 mission types. — [Eli's / CD box](https://elisoftware.org/wiki/Buzz_Aldrin%27s_Race_Into_Space_(PC,_CD-ROM)_Interplay_Productions_-_1993_USA,_Canada_Release)

**Research & Development**
- Players spend money each season to improve equipment safety, choosing a team count that affects both cost and result. "You cannot research anything you have not yet purchased." — [LP Update 01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001/)
- The R&D result screen shows how much Safety the investment gained, "so you can decide if you want to feel ripped off or not." — [LP Update 02](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2002/)
- "Each hardware type has a safety percentage, and research raises it." Research is "pretty simplistic." — [SpaceSector](https://www.spacesector.com/blog/?p=9465)

**Program buildings (e.g. unmanned/satellite building, capsule program)**
- A per-program building shows that program's stats (safety, weight, duration overview). — [LP Update 04](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2004/); the "capsule program screen gives an overview of safety percentage, weight, and duration" — [SpaceSector](https://www.spacesector.com/blog/?p=9465)

**Launch facilities / launch pads**
- The US starts with one Launch Facility; up to two more can be bought at 20 MB each, a price that "will never go up." — [LP Update 01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001/)
- "Up to three pads can run at once." — [SpaceSector](https://www.spacesector.com/blog/?p=9465)

**Moon / landing-zone information screen**
- A Moon photo screen shows "what you currently know about possible landing zones on the Moon"; knowledge starts below 55% and is raised by flybys, manned passes and probes. — [LP Update 01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001/)

**Astronaut Complex: recruiting, training, roster**
- Recruiting: hire seven astronauts for 20 MB; hired astronauts enter Basic Training until their fourth season (or until withdrawn early). Each astronaut has five stats: Capsule Pilot, LM Pilot, EVA, Docking, Endurance. Before hiring "you can only see Capsule Pilot and Endurance." — [LP Update 06](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2006/)
- "Astronauts are rated on five skills: capsule handling, lunar module piloting, spacewalking, docking, and endurance. Crews are assigned to training facilities, and their morale and compatibility must be managed." — [COMPUTE! Oct 1993](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- Over 140 astronauts and cosmonauts to choose from. — [Eli's / CD box](https://elisoftware.org/wiki/Buzz_Aldrin%27s_Race_Into_Space_(PC,_CD-ROM)_Interplay_Productions_-_1993_USA,_Canada_Release)
- "Recruitment shows names and stats, with the detail level set by astronaut difficulty. Primary and backup flight crews are assigned here or in mission scheduling." Advanced Training is "a separate building where astronauts train in specific skills," unlocked the turn after the astronaut complex. — [SpaceSector](https://www.spacesector.com/blog/?p=9465)
- A training screen lists astronauts and their status (e.g. "Washed Out: Injury"); a separate screen shows "that Mood stat ... also your movement option for your guys" (moving astronauts between programs/training). — [LP Update 10](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2010/); [LP Update 12](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2012/)
- A medical screen appears for injured astronauts ("Look, there he is! He probably fell down some stairs"). Astronaut locations shown include "Mercury Program", "Gemini Program", "Basic II/III", "Nowhere", "Retired". — [LP Update 20](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2020/); [LP Update 34](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2034/)

**Mission Control / Future Missions planner**
- "Future missions are planned by choosing a launch pad, then a mission. The duration planner has 'little pie slices' beside the reset button to lengthen missions." — [SpaceSector](https://www.spacesector.com/blog/?p=9465)
- Missions are listed by type with step counts, checks and penalties (e.g. "Orbital Satellite: 3 steps, 2 checks v Rocket, 1 check v Satellite"; "Manned Orbital: 6 steps, -4 Penalty"; "Manned Orbital Duration: 7 steps, -14 penalty"). Docking missions do not appear until a Docking Module is funded. — [LP Update 06](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2006/); [LP Update 20](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2020/)
- Missions are shown per pad ("Pad A: Orbital EVA Duration (B). Pad B: Unmanned Orbital Docking."). — [LP Update 20](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2020/)

**Vehicle Assembly (mission hardware) screen**
- The assembly screen "will show you both what you need for the mission and allow you to change it up a bit if there are multiple options"; if parts are missing you can "click AutoPurchase to buy it all up right from here." — [LP Update 06](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2006/)
- "Vehicle assembly shows the rocket carrying the payload. It can buy all mission parts in one click. Manned missions get a mission patch that appears in astronaut history." — [SpaceSector](https://www.spacesector.com/blog/?p=9465)

**Mission schedule / rush screen**
- Launch in May at no cost, or pay to launch earlier: April costs 3 MB with a -3 "Rushing Penalty" to all mission steps; March costs 6 MB with -6. Scheduled missions can be kept or scrubbed each season (scrubbing "for no cost"). — [LP Update 06](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2006/); [LP Update 08](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2008/)
- "Missions can be rushed, which raises cost and lowers safety." — [SpaceSector](https://www.spacesector.com/blog/?p=9465)

**Intelligence (CIA / KGB)**
- "KGB or CIA reports arrive every two to three years and update a comparison graph." The reviewer says the system "lacks depth." — [SpaceSector](https://www.spacesector.com/blog/?p=9465)
- Early intelligence is near-useless: "Don't feel too bad about your Central Idiocy Intelligence Agency data though, the KGB are just as clueless." — [LP Update 03](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2003/)

**Museum / Hall of Fame (outside the complex)**
- The Museum "includes a timeline, director ranking, mission records, a summary, a hardware efficiency screen, and astronaut history with flight badges and medals." — [SpaceSector](https://www.spacesector.com/blog/?p=9465)

**Prestige standings / end-game screens**
- Final screens in the LP: a "final prestige standings" screen (the race was close, under 20 points apart), a USSR victory screen (an alternate-history ending the author calls "needlessly evil and ominous"), a "USSR final stats" screen, and a "Complete Failure" screen. — [LP Update 49](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2049/)
- "Falling too far behind gets you fired." — [COMPUTE! Oct 1993](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php); "you can be fired after disastrous failures." — [Digital Antiquarian](https://filfre.net/?p=4158)

### Inferences
- (Inferred) The information architecture is three levels deep at most: Spaceport hub -> building panel -> sub-panel (e.g. Administration -> Budget Office; Future Missions -> Assembly -> Schedule). Shortcut buttons between related panels (Purchase <-> R&D; Astronaut Complex <-> Mission scheduling for crew assignment) are the only cross-links.
- (Inferred) Administration doubling as the home of Options/Save/Load means the original has no persistent system menu bar; a modern UI could keep that "in-world" placement but should also expose a conventional system menu.
- (Inferred from the LP's text-only "Status Report" summaries that the author had to compile by hand each turn) The original UI has no single overview screen showing all purchased programs, their safety, astronaut roster and scheduled missions at once; players must visit several buildings to assemble that picture. This is the most obvious "hidden information" gap a modern UI could fix with a dashboard.
- (Inferred) The season/year splash -> newscast -> spaceport order is fixed and modal; the player cannot act until the news is dismissed.

### Gaps
- No source describes the title screen / main menu itself (what options it holds beyond New Game, and whether Load appears there). The LP skipped it and reviews do not mention it.
- The exact contents of the Options panel (speed/sound/animation toggles) were not found; see Key Question 7.
- No source describes a dedicated "Mission Review/Replay" screen in the original; the Museum's "mission records" may be the equivalent (unconfirmed).
- The Soviet-side building names (Design Bureau equivalents) are not given in any source; only "functionally identical, laid out differently."

---

## Key Question 2: The Mission Control launch sequence (step display, animations/video, news flash overlay)

### Takeaway
Launches are non-interactive and play between turns: the screen's top-middle shows the launch footage/animation for the current step while the bottom-centre shows a bar-chart of the per-step roll versus the component's safety; the mission runs 3-20 steps, and occasionally pauses for an abort-or-proceed prompt. Results then feed a prestige screen and the newscast.

### Cited Findings
- "Launches play as a video between turns, after the player ends the turn. The bottom centre shows a bar chart of the dice rolls. The top middle shows launch footage. The footage is real, but not every spacecraft combination has matching footage. Missions have multiple steps, usually three or four early and about 20 in late-game lunar attempts. Each step is a roll against a component's safety." — [SpaceSector](https://www.spacesector.com/blog/?p=9465)
- "Missions are dice-based. Each step checks a component's safety factor against a random number, adjusted for astronaut skill, safety penalties, and other factors. Missions are generally non-interactive, though the player is occasionally offered an abort-or-proceed choice during an incident." — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- "Once a rocket launches, you have no direct control. The reviewer says it is 'tremendously exciting to watch each stage unfold.'" Over 300 mission variations. — [COMPUTE! Oct 1993](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- "Once a mission starts, the player has no decisions to make and is a 'helpless bystander' until it ends. Failure screens appear often." — [Digital Antiquarian](https://filfre.net/?p=4158)
- The CD-ROM's launches "combine actual footage (when available) with computer-generated ships overlaid on real space scenes. A 'mosaic' technique lets you switch to full-screen, full-motion video." — [COMPUTE! Feb 1994, Denny Atkin](https://www.atarimagazines.com/compute/issue161/96_Three_from_Interplay.php)
- Floppy version: "Stop-motion animations are used instead of video ... 'makeshift' but they 'add substantial flavor'"; "a far cry from realtime video." Praised: "Digitized launch rumbles and mission control chatter." — [COMPUTE! Oct 1993](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- The LP's final update shows two "Launch step display" screenshots for the lunar landing (`6-USSpring1969Launch1.png`, `7-USSpring1969Launch2.png`), noting a "100" point result; a "No Scrubbing" option existed at launch time. The author also linked two YouTube captures of the launch sequence (port version): [Spring 1969 Launches](http://www.youtube.com/watch?v=mn1lV86UaE4) and [Mirror World Spring 1969 Launch](http://www.youtube.com/watch?v=V7l9-T0fnY8). — [LP Update 49](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2049/)
- The Soviet side has less footage and "the game sometimes substitutes American launch footage." — [Digital Antiquarian](https://filfre.net/?p=4158)
- Mission step types the box advertises: "planetary and lunar flybys, LEM tests, lift-offs, space walks, lunar orbits and landings, and splashdowns." — [Eli's / CD box](https://elisoftware.org/wiki/Buzz_Aldrin%27s_Race_Into_Space_(PC,_CD-ROM)_Interplay_Productions_-_1993_USA,_Canada_Release)
- "Successful historical missions earn prestige points, which bring higher ratings and more funding." — [COMPUTE! Oct 1993](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- Orchestral music plays "on the loading screen and when the AI gets a prestige first." — [SpaceSector](https://www.spacesector.com/blog/?p=9465)

### Inferences
- (Inferred) The launch screen is a fixed three-zone layout: video/animation window top-centre, step-result bar chart bottom-centre, and (inferred from the "step" vocabulary and the LP's "100 point result") a text readout of the current step name and its safety number somewhere near the chart. The exact placement of the step list and the abort prompt was not described by any source.
- (Inferred) A "prestige first" fanfare screen exists as a discrete beat after a mission achieves a milestone first, because the orchestral cue is tied to "when the AI gets a prestige first."
- (Inferred) The "news flash" for the other side's missions is delivered through the normal start-of-turn newscast rather than a separate overlay; the LP labels the Soviet launch announcement a "Soviet news flash" screenshot inside the newscast flow. Unconfirmed.

### Gaps
- No source gives the step-by-step on-screen text format (e.g. step name, roll number, pass/fail wording), nor what the abort/proceed prompt looks like.
- No source confirms whether a post-mission "Mission Review" summary screen with crew/prestige breakdown exists separately from the prestige screen.
- The YouTube captures were not viewable from this environment; a human should watch them to confirm layout.

---

## Key Question 3: Top-level HUD/status (date, cash, prestige, side) and the interaction model

### Takeaway
There is no persistent HUD. The season/year is shown on its own card at turn start, cash on hand sits in the bottom-right of the spaceport screen, prestige is only visible in the Budget Office graphs and the standings/prestige screens, and the side is implied by which spaceport (and colour) you are looking at. Input is mouse-driven point-and-click on hotspots and buttons.

### Cited Findings
- "The first screen each turn shows the Season and Year, followed by the news." "The bottom-right corner [of the Cape] shows cash on hand." "Prestige appears only as a Budget Office graph topic." — [LP Update 01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001/)
- The SpaceSector review "does not describe a persistent HUD showing date, cash, or prestige"; prestige acts as the score; funding is set at the start of each year. — [SpaceSector](https://www.spacesector.com/blog/?p=9465)
- "Turns have no time limit, but the reviewer says the game 'instills momentum with its subtle sense of urgency.'" — [COMPUTE! Oct 1993](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- CD-ROM system requirements list "Mouse: Recommended." — [Eli's / CD box](https://elisoftware.org/wiki/Buzz_Aldrin%27s_Race_Into_Space_(PC,_CD-ROM)_Interplay_Productions_-_1993_USA,_Canada_Release)
- "Clicking a building opens a separate screen." Buildings have shortcut buttons to related buildings. — [SpaceSector](https://www.spacesector.com/blog/?p=9465)
- Six-month turns from Spring 1957; up to 20 years / end of 1977. — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space); [COMPUTE! Oct 1993](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)

### Inferences
- (Inferred) Because "Mouse: Recommended" rather than "required", a keyboard fallback exists, but no source documents keyboard shortcuts.
- (Inferred) A modern UI should add a persistent status bar (season/year, cash, prestige, side) since the original scatters these across three screens; this is a presentation change that does not alter information architecture.

### Gaps
- No source documents keyboard controls, hotkeys, or whether buttons have keyboard accelerators.
- No source states whether the spaceport screen also shows the date; the LP implies the date is only on the season card.

---

## Key Question 4: Visual style (resolution, pixel art, isometric spaceport, portraits, hardware art, red/blue theming, fonts)

### Takeaway
The game is a VGA/MCGA 256-colour title with no SVGA option, built from a mix of hand-drawn bitmaps, digitized photographs (over 1,000 on floppy, "10,000" claimed on CD) and ray-traced images; the spaceports are static aerial paintings that gain buildings over time. 320x200 is strongly implied but no source states the number outright.

### Cited Findings
- CD-ROM system requirements: "Graphics mode: VGA 256 Color or MCGA"; CPU 386, 4 MB RAM, 565K conventional free, 6.5 MB hard-disk free, MPC CD speed. — [Eli's / CD box](https://elisoftware.org/wiki/Buzz_Aldrin%27s_Race_Into_Space_(PC,_CD-ROM)_Interplay_Productions_-_1993_USA,_Canada_Release)
- "The artwork mixes bitmapped, digitized, and raytraced images." The reviewer praises the design as "extremely well designed" but notes "the designers also did not double the graphic resolution or offer an SVGA option" and that "the game consists almost entirely of static screens." Over 1,000 historical photos are included. — [COMPUTE! Oct 1993](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- "The main navigation is an aerial view of each side's spaceport ... New buildings appear as programs grow"; landmarks (Capitol/Kremlin, Pentagon/KGB HQ, Arlington, Kremlin Wall) are part of the map art. — [COMPUTE! Oct 1993](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- "The game relies heavily on photographs, video, and sound from NASA and Soviet archives, which were public domain ... The floppy release used digitized still photographs in place of most of that video. Interplay's art team produced most of the non-digitized graphics." — [Digital Antiquarian](https://filfre.net/?p=4158)
- Purchased hardware items get "a new picture for the item" in the purchase screen; the Moon screen is a photograph of the lunar surface with landing-zone knowledge overlaid. — [LP Update 02](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2002/); [LP Update 01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001/)
- Manned missions get "a mission patch that appears in astronaut history"; the Museum shows "astronaut history with flight badges and medals." — [SpaceSector](https://www.spacesector.com/blog/?p=9465)
- "Graphics just ok" is a recurring player complaint on MobyGames (search snippet; page itself blocked). — [MobyGames via search snippet](https://www.mobygames.com/game/8276/)
- Giant Bomb's description (search snippet; page returned 403) calls the graphics and sound "ahead of their time, using an uncommon amount of both (crude) FMV and pre-recorded audio," and notes "a special CD-ROM edition had better FMV." — [Giant Bomb](https://www.giantbomb.com/wd/3030-10819)
- The floppy version omitted "about 100 MB of photographs and animations cut for space." — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)

### Inferences
- (Inferred) Native resolution is 320x200 with a 256-colour palette: "VGA 256 Color or MCGA" is the standard MCGA mode 13h, and COMPUTE! explicitly says the resolution was not doubled and there is no SVGA mode. No source prints "320x200" verbatim.
- (Inferred) The spaceport is a painted aerial/oblique view rather than a true tile-based isometric map; sources say "aerial view" and describe it as a single static image that is swapped as buildings are added. A reimplementation can treat it as one background with layered building sprites and hotspot regions.
- (Inferred) Colour theming: no source explicitly states "US blue / USSR red" UI chrome. The LP's Soviet newscast copy and "Baikonur laid out differently" show side-specific content, and the USSR victory screen is described as "ominous", but the palette split should be confirmed from screenshots before being treated as canon.
- (Inferred) Astronaut portraits: no source mentions portrait art for astronauts; recruiting is described as "names and stats." Treat portraits as absent unless screenshots show otherwise.
- (Inferred) Fonts: no source discusses typography. Expect a single small bitmap UI font typical of 320x200 titles; confirm from screenshots.

### Gaps
- No source states native resolution or pixel aspect explicitly.
- No source describes the fonts, button styling, or panel chrome.
- No source describes whether astronauts have portraits.
- The Wikipedia/MobyGames screenshot galleries could not be opened from this environment (MobyGames 403; Wikipedia page text only). The design team should view them directly (URLs in Key Question 9).

---

## Key Question 5: The CD-ROM edition's full-motion video and voice vs the floppy version

### Takeaway
The floppy release (March 1993) substituted "stop-motion" animations and digitized stills for most video; the CD-ROM (released ~14 months later, 1994) restored real NASA/Soviet archival footage for launches (with CG ships composited over real footage where no footage existed), a full-screen "mosaic" video mode, more varied digitized Mission Control chatter, digitized voice, an orchestral score on two tracks, a historical multimedia book, and modem/e-mail play.

### Cited Findings
- Floppy: "Stop-motion animations are used instead of video ... a far cry from realtime video." — [COMPUTE! Oct 1993](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- CD-ROM: "Full-motion video replaces the original's 'jerky animation.' Launches combine actual footage (when available) with computer-generated ships overlaid on real space scenes. A 'mosaic' technique lets you switch to full-screen, full-motion video. Sound is improved. The CD-ROM's extra space allows more variety in Mission Control's digitized play-by-play." Adds modem and e-mail play; a beginner level "tames the random-number generator." — [COMPUTE! Feb 1994](https://www.atarimagazines.com/compute/issue161/96_Three_from_Interplay.php)
- CD-ROM box: "Hundreds of historic NASA video sequences, plus never-before-seen film footage of the Soviet space program"; "Over 10,000 historical photos and digitized images"; "Digitized voice"; "a 45-piece orchestrated musical score"; "Read a historical book on the space race, with photos, biographies, missions, and blueprints." — [Eli's / CD box](https://elisoftware.org/wiki/Buzz_Aldrin%27s_Race_Into_Space_(PC,_CD-ROM)_Interplay_Productions_-_1993_USA,_Canada_Release)
- Wikipedia: the 1994 CD-ROM "incorporated the floppy updates, 'a few new updates, improved video of the mission launches,' and 'new multiplayer modes.'" — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- "The CD-ROM version arrived fourteen months after the March 1993 floppy release, which the article suggests was the first time players could see the game as its designer intended." The original 1991 demo "was non-interactive video of rockets soaring and exploding." — [Digital Antiquarian](https://filfre.net/?p=4158)
- Home of the Underdogs: the game uses "digitized footage of lift-offs, space walks, lunar landings, and splashdowns"; the CD-ROM "adds a large archive of historical footage ... (about 600MB)." — [HOTU](https://www.homeoftheunderdogs.net/game.php?id=160)
- Newscasts: "Each turn opens with a newscast from 'Carter Walcrite'" with narration. — [Digital Antiquarian](https://filfre.net/?p=4158). In the port, "the movie's video better matches the voice of the newscaster" (v2.0.0 release-notes snippet returned by the search engine; the GitHub page was NOT opened). — [GitHub release page, snippet only](https://github.com/raceintospace/raceintospace/releases/tag/v2.0.0)
- Orchestral versions "exist for only two tracks, due to size limits. They play on the loading screen and when the AI gets a prestige first ... the orchestral version was only on the CD release." — [SpaceSector](https://www.spacesector.com/blog/?p=9465)
- Release-date discrepancy: floppy 11 March 1993 per Wikipedia/oldgames.sk; SourceForge and Fedora package pages say "disk in 1992 and CD-ROM in 1994"; Eli's lists the CD-ROM with a 1993 copyright. — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space); [oldgames.sk](https://oldgames.sk/en/game/buzz-aldrins-race-into-space); [SourceForge homepage](https://raceintospace.sourceforge.net/); [Fedora](https://packages.fedoraproject.org/pkgs/raceintospace/raceintospace-doc)

### Inferences
- (Inferred) The newscast on floppy was a still anchor image plus text, with the CD adding a voiced, video newscast; the sources establish a voiced newscaster and a newscast "movie" but do not state explicitly that the floppy newscast was silent/still.
- (Inferred) "Mosaic" full-screen mode means the CD video normally plays in a sub-window (consistent with the "top middle shows launch footage" layout) and can be expanded to fill the 320x200 screen.

### Gaps
- No source itemises exactly which mission steps had video vs stills on floppy.
- No source describes the on-disc "historical book" viewer UI.
- No source confirms whether the newscaster was voiced on the floppy version.

---

## Key Question 6: Audio (music composer, track count, style; sound effects; voice)

### Takeaway
The floppy soundtrack was MIDI-style music (AdLib/Sound Blaster/Roland MT-32/LAPC-1/SCC-1 supported) that one 1993 reviewer called "bland" and advised turning off; the CD added a "45-piece orchestrated" score for two cues plus digitized voice and more Mission Control chatter. The composer could not be identified because the MobyGames credits page was unreachable.

### Cited Findings
- Supported audio hardware: "AdLib, SoundBlaster, SoundBlaster Pro, SoundBlaster 16, ProAudio Spectrum, Roland MT-32, Roland LAPC-1, Roland SCC-1." Box: "Listen to a 45-piece orchestrated score, sound effects, and digitized voice." — [Eli's / CD box](https://elisoftware.org/wiki/Buzz_Aldrin%27s_Race_Into_Space_(PC,_CD-ROM)_Interplay_Productions_-_1993_USA,_Canada_Release)
- "Digitized launch rumbles and mission control chatter are praised. The music is criticized as 'bland.' The reviewer advises turning it off." — [COMPUTE! Oct 1993](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- "The reviewer praises the audio as far ahead of its time. Orchestral versions exist for only two tracks, due to size limits. They play on the loading screen and when the AI gets a prestige first. The open source version lets players switch between original and orchestral themes." — [SpaceSector](https://www.spacesector.com/blog/?p=9465)
- "The game's music was released as freeware after the 2005 bankruptcy of Interplay." — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- "The CD-ROM's extra space allows more variety in Mission Control's digitized play-by-play." — [COMPUTE! Feb 1994](https://www.atarimagazines.com/compute/issue161/96_Three_from_Interplay.php)
- In the port, "screens played their tunes" (i.e. music is per-screen) and a Soviet music/newscast timing fix is mentioned (search snippet of GitHub release notes; page not opened). — [GitHub release page, snippet only](https://github.com/raceintospace/raceintospace/releases/tag/v2.0.0)
- MobyGames lists an "Original Music by" credit for the DOS version, but the name was cut off in the search snippet and the page returned 403. — [MobyGames](https://www.mobygames.com/game/8276/)

### Inferences
- (Inferred) Music is screen-scoped: each building/screen has its own looping theme, which is why the port had bugs with tunes bleeding between screens.
- (Inferred) Voice is limited to the newscaster and Mission Control call-outs; there is no evidence of voiced astronauts or advisors.

### Gaps
- Composer name, exact track count, and track titles: not found. The MobyGames credits page (https://www.mobygames.com/game/1264/buzz-aldrins-race-into-space/credits/dos/) is the recommended next stop for a human.
- No source lists the sound-effect inventory beyond "launch rumbles" and "mission control chatter."

---

## Key Question 7: Game options (speed, sound toggles, animation toggles, quick play / easy mode)

### Takeaway
Confirmed options are the New Game settings (difficulty level x3, astronaut selection level, Basic/Historical model, historical/custom roster, human/computer opponent, CD-only Quick Start beginner level and modem/e-mail play) plus an Options/Save entry inside Administration. In-game speed, sound and animation toggles are implied by the "turn the music off" advice but their UI was not described.

### Cited Findings
- New Game options: Game Level, Astro/Cosmonaut Selection Level, Basic Model, Historical Roster, player names. — [LP Update 01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001/)
- Three AI difficulty settings (handicaps), human-controlled opponent (hot seat), Historical vs Basic, astronaut difficulty controlling recruiting information. — [SpaceSector](https://www.spacesector.com/blog/?p=9465)
- Administration menu ends with "Options, Save, and leave menu." — [LP Update 01](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001/)
- "Select one of three difficulty levels, including a new Quick Start beginner level"; modem (9,600 bps+) and Internet e-mail two-player. — [Eli's / CD box](https://elisoftware.org/wiki/Buzz_Aldrin%27s_Race_Into_Space_(PC,_CD-ROM)_Interplay_Productions_-_1993_USA,_Canada_Release)
- "Setting the game to beginner level tames the random-number generator." — [COMPUTE! Feb 1994](https://www.atarimagazines.com/compute/issue161/96_Three_from_Interplay.php)
- The music can be turned off ("The reviewer advises turning it off"). — [COMPUTE! Oct 1993](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- Early buyers complained about difficulty and "Interplay released a patch that adjusted the numbers." — [Digital Antiquarian](https://filfre.net/?p=4158)
- Modem play "was cut from the floppy version"; its restoration on CD is "not confirmed" by Wikipedia, but COMPUTE! Feb 1994 and the CD box both state modem/e-mail play is present. — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space) vs [COMPUTE! Feb 1994](https://www.atarimagazines.com/compute/issue161/96_Three_from_Interplay.php)

### Inferences
- (Inferred) The Options panel contains at least a music on/off toggle; sound-effect, animation-skip and game-speed toggles are plausible but unconfirmed.

### Gaps
- No source enumerates the Options panel contents (speed, SFX, animation, video skip).
- No source describes the Save/Load screen layout or slot count.

---

## Key Question 8: Existing remasters, fan mock-ups, SDL-port scaling, and community UI criticism

### Takeaway
The only modern version is the volunteer open-source *Race Into Space* port (Windows/Linux/Mac, Flathub, v2.0 in 2025), which keeps the original screens and art and adds quality-of-life fixes and an original/orchestral music switch; no high-resolution remaster or fan UI mock-up was found. Community criticism centres on difficulty, lack of tutorial, repetitive videos, shallow intelligence, and the successor game's interface being only "a slight improvement on the original BARIS."

### Cited Findings
- "The project, now called Race Into Space, is hosted on GitHub and has been ported to modern operating systems and other platforms, including the Pandora console. Version 2.0 (2025) converted the code from C to C++, fixed bugs, added quality-of-life features, and corrected some historical inaccuracies." Downloaded over 90,000 times from SourceForge 2005-2017. "Later improvements have made the game less difficult." — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- Flathub listing: "a port to modern operating systems of Buzz Aldrin's Race Into Space"; Aldrin's name and imagery dropped because permission was limited to the DOS game; manual rewritten; desktop-only, x86_64 and aarch64; one screenshot: https://imgproxy.flathub.org/insecure/dpr:1/f:webp/rs:fit:640:401/aHR0cHM6Ly9kbC5mbGF0aHViLm9yZy9tZWRpYS9vcmcvcmFjZWludG9zcGFjZS9SYWNlaW50b3NwYWNlL2YzOWZmOWQ0ZmM3OTM4MWZjYTE5MTQxNDY5MWQ3NGUwL3NjcmVlbnNob3RzL2ltYWdlLTFfb3JpZy5wbmc ; the page says nothing about display scaling. — [Flathub](https://flathub.org/en/apps/org.raceintospace.Raceintospace)
- The SourceForge homepage links a "BARIS Wiki (maintained by Peyre)" and a blog; the original source copyright is "2005 Michael K. McCarty & Fritz Bronner." (Doxygen/code links on that page were deliberately not followed.) — [SourceForge homepage](https://raceintospace.sourceforge.net/)
- "The open source version lets players switch between original and orchestral themes." Criticisms: videos "get repetitive quickly, especially for the Soviet Union"; intelligence and political systems "lack depth"; the game is "very difficult for new players" and landing on the Moon is "painfully hard"; readers note "the lack of a tutorial." — [SpaceSector](https://www.spacesector.com/blog/?p=9465)
- A Slitherine forum thread on the 2014 successor is titled "Fun game, poor interface"; one poster says its interface is "a slight improvement on the original BARIS." — [Slitherine forum](https://forum.slitherine.com/viewtopic.php?p=504599)
- A GOG user review of the successor says "the interface is more modern and the level of detail is much greater than in BARIS." — [GOG](https://www.gog.com/en/game/buzz_aldrins_space_program_manager)
- 1993 criticism: "almost entirely static screens"; no resolution doubling or SVGA option; "makeshift" stop-motion animation; "bland" music. — [COMPUTE! Oct 1993](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- 1994 criticism: original "so hard to win"; "lack-luster animation" on floppy. — [COMPUTE! Feb 1994](https://www.atarimagazines.com/compute/issue161/96_Three_from_Interplay.php)
- Period praise: "the most successful piece of 'educational' software available for the PC" (PC Gamer UK, 90/100, 26th best PC game 1994); "rather lifeless" (The Guardian). — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- Searches for Reddit, VOGONS and fan high-resolution/UI-mock-up discussion returned nothing relevant (the only hits were Flathub mirrors and unrelated SDL-scaling threads for other games).

### Inferences
- (Inferred) The port renders at the original 320x200 logical resolution and scales up; nothing in any fetched page describes a widescreen or hi-res UI mode, and the Flathub screenshot is 640x401 (a 2x of 320x200). Unconfirmed; a human should run the Flatpak to check scaling behaviour.
- (Inferred) The successor's (2014 Space Program Manager) interface being only "a slight improvement" suggests the community's main UI pain points are shared: dense static panels, little at-a-glance status, and multi-screen navigation to answer simple questions.

### Gaps
- No fan UI mock-ups or hi-res remaster projects were found.
- The port's actual scaling method (integer, nearest-neighbour, aspect correction, fullscreen) was not documented on any non-code page fetched; PCGamingWiki returned 403.
- The "BARIS Wiki (maintained by Peyre)" URL was not surfaced by search; it may hold further screen documentation.

---

## Key Question 9: Where to find screenshots (URLs for the design team)

### Takeaway
The best text-indexed screenshot set is the Something Awful LP (49 updates, named PNGs per screen); MobyGames and Wikipedia hold galleries that must be opened in a browser; YouTube captures of launches exist via the LP.

### Cited Findings
- **LP Archive (screen-by-screen, port version):** index https://lparchive.org/Buzz-Aldrins-Race-Into-Space/ ; Update 01 (setup, season card, news, Cape, Administration menu, R&D, launch pads, Moon screen): https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2001/ ; Update 02 (purchase and R&D result screens, flagpole end-turn): https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2002/ ; Update 03 (USSR newscast, Baikonur, budget, intelligence): https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2003/ ; Update 04 (unmanned program building): https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2004/ ; Update 06 (assembly, schedule/rush, recruiting, stats): https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2006/ ; Update 08 (grown Cape with training buildings): https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2008/ ; Update 10 (training screen): https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2010/ ; Update 12 (mood/movement screen): https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2012/ ; Update 20 (medical screen): https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2020/ ; Update 49 (mission schedule, future missions, launch step displays, final prestige, USSR victory, failure screen): https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2049/ . Image files are relative to each update URL (e.g. `Update%2001/4-CapeMain1957.png`). — [LP Archive](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/)
- **YouTube launch captures (port):** http://www.youtube.com/watch?v=mn1lV86UaE4 and http://www.youtube.com/watch?v=V7l9-T0fnY8 — linked from [LP Update 49](https://lparchive.org/Buzz-Aldrins-Race-Into-Space/Update%2049/)
- **MobyGames** (blocked from this environment; open in a browser): game page https://www.mobygames.com/game/1264/buzz-aldrins-race-into-space/ ; screenshots https://www.mobygames.com/game/1264/buzz-aldrins-race-into-space/screenshots/dos/ ; credits https://www.mobygames.com/game/1264/buzz-aldrins-race-into-space/credits/dos/ ; alternate id https://www.mobygames.com/game/8276/
- **Wikipedia** article with infobox screenshot: https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space
- **oldgames.sk** lists 11 screenshots and one video for the DOS version (gallery is JS-loaded; only the cover thumbnail was extractable): https://oldgames.sk/en/game/buzz-aldrins-race-into-space
- **Flathub** (port screenshot): https://flathub.org/en/apps/org.raceintospace.Raceintospace
- **Home of the Underdogs** entry: https://www.homeoftheunderdogs.net/game.php?id=160
- **Period reviews with screenshots in print (text only online):** COMPUTE! Oct 1993 https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php ; COMPUTE! Feb 1994 https://www.atarimagazines.com/compute/issue161/96_Three_from_Interplay.php
- **Retrospectives:** SpaceSector 2013 review https://www.spacesector.com/blog/?p=9465 ; Digital Antiquarian https://filfre.net/?p=4158
- **CD-ROM box scan/text:** https://elisoftware.org/wiki/Buzz_Aldrin%27s_Race_Into_Space_(PC,_CD-ROM)_Interplay_Productions_-_1993_USA,_Canada_Release

### Inferences
- (Inferred) The LP image filenames double as a de facto screen list: Setup, Season card, News (and News2), Cape/Baikonur, Admin menu, Budget, R&D menu/result, Purchase result, Launchpad/BuyNewPad, MoonPhoto, SatBuild (program building), Assemb (assembly), Schedule, Mans (recruit), Stats, Training, ManMood, Medical, MisSch (mission schedule), FutMis, Launch1/2, FinalPres, Victory, FinalStats, CompleteFailure.

### Gaps
- Direct image URLs for MobyGames and oldgames.sk galleries could not be extracted.
- No Computer Gaming World (Aug 1993) scan was reachable (archive.org blocked).
- The original floppy/CD manual, which COMPUTE! says is "heavily illustrated with itemized screen shots and charts," was not found online; it would be the single best reference for original screen layouts if a scan can be located (archive.org / replacementdocs should be checked by a human).
