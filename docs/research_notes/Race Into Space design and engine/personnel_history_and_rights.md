# BARIS: Personnel System, Release History, Rights and Cleanroom Landscape

Research date: 2026-10-11. Scope: (A) astronaut/cosmonaut personnel system of *Buzz Aldrin's Race Into Space* (BARIS, 1993); (B) release history, versions, rights ownership and the legal landscape for a cleanroom reimplementation based in New Zealand.

**Cleanroom compliance statement.** No source code, data file, or repository page of the 2005 GPL release or any fork was opened. Specifically NOT opened: `github.com/raceintospace/*` (including `doc/manual/manual.md`, which search results surfaced as the fullest description of personnel rules), `raceintospace.sourceforge.net/doxygen/*` (Doxygen-rendered README), the OSDN mirrors of `NautRoster.txt` (an astronaut roster data file) and `Readme.txt`, `git.tdem.in`, and `github.com/joequant/raceintospace`. The consequence is that the finest-grained personnel numbers (group sizes/timings, recruitment cost, exact skill ranges, mood thresholds) could not be sourced and are listed under Gaps rather than guessed. Everything below comes from Wikipedia, magazine reviews, retrospectives, package-index prose, forum posts, store pages and legal commentary.

**Important site note.** `raceintospace.org`, the domain cited as "home page" by the SourceForge project page, Fedora and others, now serves an unrelated "game studio" template page padded with online-casino and crypto links and has no project content — [raceintospace.org](https://www.raceintospace.org/). Treat any citation to that domain as dead/hijacked (inferred: domain lapsed and was re-registered). The project's live prose home is the SourceForge page and its GitHub organisation (not browsed).

---

## A1. Recruitment: when groups become available, group sizes, cost, candidate attributes

### Takeaway
Players recruit their entire corps themselves from a game start in spring 1957; the roster offers historical profiles (COMPUTE! says 106 per side; Home of the Underdogs says 140 total) or custom-created characters, and recruitment is a budget line. Group timings, group sizes and per-recruit cost were not obtainable from non-repository sources.

### Cited Findings
- Play begins in spring 1957, with six-month turns, for up to 20 years — [COMPUTE! Oct 1993 review](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- Players can use a historical roster of "106 simplified profiles (per side) of real-life flyboys" or create customized characters — [COMPUTE! Oct 1993](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php); Home of the Underdogs instead says "you recruit and train 140 astronauts and cosmonauts" — [HotU](https://www.homeoftheunderdogs.net/game.php?id=160). (Conflict: 106/side vs 140 total; neither states group structure.)
- Each player's space center "doubles as a navigational menu" and the player "directs funding toward purchasing hardware, research and development, recruiting and training astronauts, and conducting launches" — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- "Since the game starts before spaceflight, you recruit all your own astronauts, watching them go through training and the different manned programs" — [Orbiter-Forum thread via search](https://webmail.orbiter-forum.com/goto/post?id=336463)
- Hiring is "simple" and "it's very much possible to hire people on their name alone" — [SpaceSector review](https://www.spacesector.com/blog/wp-json/wp/v2/posts/9465)
- Bronner added "a roster of astronauts to be recruited and trained" with "differing strengths and weaknesses" — [Digital Antiquarian, Jan 2020](https://www.filfre.net/2020/01/buzz-aldrins-race-into-space-and-space-program-games-in-general/)
- Astronaut skills and morale were added around August 1991 (late in development); before that they had no effect on mission performance, and skills "were initially randomized at the start of each game" — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- A design trade-off noted by reviewers: "skipping crucial test missions to catch up versus recruiting more inexperienced astronauts" — [HotU](https://www.homeoftheunderdogs.net/game.php?id=160)

### Inferences
- (Inferred) Because skills were originally randomised and the historical roster is "simplified profiles," the historical names are a presentation layer over a stat block; a spec can treat roster entries as {name, nationality-side, 5 skills, gender} without any loss of mechanical fidelity.
- (Inferred from the "hire on name alone" remark) The recruitment screen shows candidate names and at least some attributes before purchase, so the name carries signalling value to players who know spaceflight history.

### Gaps
- When astronaut groups become available (which turn/year), how many per group, whether group availability is tied to a prestige/milestone trigger, and the recruitment cost per candidate: not found outside the repository-hosted manual (not opened per cleanroom rule). The original Interplay manual is not on archive.org as a text item; the software items listed there (e.g. `msdos_Buzz_Aldrins_Race_into_Space_1993`, `BARISCD`, `cdrinc_Buzz_Aldrins_Race_Into_Space`) may contain manual scans but were not opened — [archive.org search](https://archive.org/advancedsearch.php?q=%22race+into+space%22&fl%5B%5D=identifier&fl%5B%5D=title&fl%5B%5D=mediatype&rows=50&output=json).
- Whether the candidate pool is drawn from the historical roster in historical-group order (e.g. Mercury Seven first) is not confirmed by any source reached.

---

## A2. Attributes/skills, mood, typical ranges, training facilities and durations

### Takeaway
Each astronaut has five rated skills (capsule handling, LM piloting, EVA/spacewalking, docking, endurance) plus a mood/morale value; skills add a small percentage (community reports 0–4%) to each mission step's safety check; training runs through Basic Training (reported 3 turns) and then Advanced Training at the Astronaut Complex / Cosmonaut Center, with half-credit for early withdrawal introduced in v1.1 of the open-source port.

### Cited Findings
- Astronauts are rated on "capsule handling, lunar module piloting, spacewalking, docking, and endurance" — [COMPUTE! Oct 1993](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- "Astronauts have five stats, indicating what role they fulfil on the craft." "Capsule pilot is one of the most important stats, since every mission requires a pilot." Docking, EVA and LM also matter; "a bad lunar module pilot could crash the lander" — [SpaceSector review](https://www.spacesector.com/blog/wp-json/wp/v2/posts/9465)
- Crewed missions "apply astronaut skill bonuses to each step's safety check" — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- Community analysis: skills add 0 to 4% to the safety check; maximum spacecraft safety is 94% and a highly skilled pilot can reach 98%; Voskhod maxes at 92%. Worked example: "90%(R&D) - 9%(penalty for 0 LM pts) + 4%(Aldrin skill) = 85% reliable" for a lunar module — [Orbiter-Forum thread, posts #64 and #69](https://webmail.orbiter-forum.com/goto/post?id=336463)
- Experience changes failure outcomes: veterans more often get recoveries such as "negative ignition, but crew was able to perform a makeshift burn," recruits more often "craft stranded in orbit, crew dead"; "a major problem tends to almost always mean death for fresh recruits" — [Orbiter-Forum thread, posts #67, #69](https://webmail.orbiter-forum.com/goto/post?id=336463)
- Crews are "assigned to training facilities to raise these ratings" — [COMPUTE! Oct 1993](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- Basic Training lasts three turns before a recruit moves to the Astronaut Complex (US) or Cosmonaut Center (USSR) — reported in a search snippet of the open-source port's manual ([search result referencing github manual.md](https://github.com/raceintospace/raceintospace/blob/master/doc/manual/manual.md); the page itself was NOT opened, so this is a second-hand snippet only).
- "They can't be put back into training after being pulled out of it, so be careful"; the reviewer advises against skipping basic training; "It's best to leave the crew a full year to learn the capsule before you try to throw them into orbit" — [SpaceSector review](https://www.spacesector.com/blog/wp-json/wp/v2/posts/9465)
- v1.1 (open-source port, July 2013): "Advanced Training now has several improvements"; withdrawing someone after half of Advanced Training now gives "half credit rather than nothing at all" — [Orbiter-Forum thread, post #66](https://webmail.orbiter-forum.com/goto/post?id=336463)
- Config option in v1.0/1.1 of the port: "Set the compatibility level of nauts (10 is default, 1 complete)"; lower values reduce conflicts between crew members — [Orbiter-Forum thread, post #73](https://webmail.orbiter-forum.com/goto/post?id=336463)

### Inferences
- (Inferred) The pre-launch "safety" of a crewed step is roughly `min(cap, component_reliability + skill_bonus - penalties)`, where the cap is around 94–98%, consistent with the community worked example. Exact formula not sourced.
- (Inferred) Because the port exposes a "compatibility level" tunable, crew compatibility is a numeric relation between astronauts, not merely a flavour text.

### Gaps
- Numeric ranges of the five skills and of mood (e.g. 0–4 vs 0–99), how much each training period adds, the length of Advanced Training in turns, and whether the Basic/Advanced facilities have capacity limits or costs: only present in the repository-hosted manual, not opened.

---

## A3. Crews: Primary/Backup, capsule crew sizes, compatibility, assignment

### Takeaway
Crews are assembled as primary and backup flight crews and assigned to a planned mission; incompatible pairings generate "bad feelings" that can jeopardise the mission; a backup crew prevents a scrub if a primary member is lost to a random event. Explicit capsule seat counts (1/2/3) were not stated in any non-repository source reached, though the hardware tiers (Mercury/Vostok one-seat through Apollo/Soyuz three-seat) are historical.

### Cited Findings
- "You assemble primary and backup flight crews" — [COMPUTE! Oct 1993](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- "Pairing incompatible recruits provokes bad feelings that could jeopardize your mission" — [COMPUTE! Oct 1993](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- Astronauts have "differing personalities which could cause them to be more or less effective when combined into crews" — [Digital Antiquarian](https://www.filfre.net/2020/01/buzz-aldrins-race-into-space-and-space-program-games-in-general/)
- Players "select individual astronauts, even going as far as rating astronaut chemistry within individual flight crews" — [Giant Bomb via search](https://www.giantbomb.com/wd/3030-10819)
- Backup flight crews mean "the mission won't be scrubbed" if a primary astronaut dies in a random event — [SpaceSector review](https://www.spacesector.com/blog/wp-json/wp/v2/posts/9465)
- After launch "the player has no direct control over the mission" — [COMPUTE! Oct 1993](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- Mission variety: "More than 300 mission variations" among milestones; mission types include suborbital, manned and unmanned orbital, flybys, lunar landing tests, lunar passes/orbits and landings — [COMPUTE!](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php); [HotU](https://www.homeoftheunderdogs.net/game.php?id=160)
- Voskhod (a multi-seat Soviet capsule) is given a lower safety ceiling (92%) in community analysis, making it risky for lunar missions — [Orbiter-Forum thread](https://webmail.orbiter-forum.com/goto/post?id=336463)

### Inferences
- (Inferred) Crew size is dictated by the capsule program chosen for the mission (historical one-, two- and three-seat tiers); the sources name the capsule families (Mercury, Gemini, Apollo, Vostok, Voskhod, Soyuz) but do not state the seat numbers explicitly.
- (Inferred) Compatibility is evaluated at crew-formation time (hence "pairing ... provokes bad feelings") and feeds mood, which in turn feeds mission performance.

### Gaps
- Seat counts per capsule, whether a mission can fly with fewer than the full crew, whether backup crews must also be trained in the specific program, and the rule by which a backup replaces a primary member: not sourced.

---

## A4. Mood/morale: drivers, bottoming out, resignations, news items

### Takeaway
Mood falls with inaction and with failed missions (surviving astronauts "perform worse"), and with incompatible crew pairings; if it gets too low the astronaut quits the program. No source reached describes the specific "unhappy astronaut" news-item text or the numeric thresholds.

### Cited Findings
- Players must monitor crews' "emotional well-being"; astronauts "respond negatively to inaction" — [COMPUTE! Oct 1993](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- Mood: "If it gets too low, they'll quit the space program" — [SpaceSector review](https://www.spacesector.com/blog/wp-json/wp/v2/posts/9465)
- Failed missions "destroy the morale of your surviving astronauts, causing them to perform worse" — [Digital Antiquarian](https://www.filfre.net/2020/01/buzz-aldrins-race-into-space-and-space-program-games-in-general/)
- Skills and morale were added around August 1991 — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- Random events can kill an astronaut outside a mission; example from a player log: "Casualties : 1 (Glenn, automobile accident...)" — [Orbiter-Forum thread, post #64](https://webmail.orbiter-forum.com/goto/post?id=336463)

### Inferences
- (Inferred) Mood is a per-astronaut scalar with at least three sources of change: time idle (negative), mission outcomes (positive on success/negative on failure for survivors), and crew compatibility (negative when paired badly). A quit threshold exists.

### Gaps
- Numeric mood range, decay per idle turn, bonus for successful flights, the quit threshold, whether being "passed over" for a mission specifically penalises mood, and whether retirement is distinct from resignation: not sourced outside the repository.
- Wording of the in-game newspaper/"unhappy astronaut" messages: not sourced (and any verbatim text would be copyrightable expression in any case — see B4).

---

## A5. Death, injury, memorial, Hall of Fame/Museum, prestige impact

### Takeaway
Crew deaths are a major prestige loss and can happen through mission failure (including being stranded on the Moon) or random events; experienced crews soften failures. No source reached describes an in-game memorial, Hall of Fame or Museum screen; that remains a gap.

### Cited Findings
- Prestige is lost through mission failures, "especially those involving astronaut/cosmonaut fatalities" — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- "Losing a crew, however, is very bad." "Prestige is effectively your score." Firsts such as "the first woman in space and the first docking" earn more prestige than routine flights — [SpaceSector review](https://www.spacesector.com/blog/wp-json/wp/v2/posts/9465)
- Serious failures can "chew through your astronaut corps"; some failures leave astronauts "stranded on the Moon to wait for their life support to run out," while sometimes they "make it home safely" — [Digital Antiquarian](https://www.filfre.net/2020/01/buzz-aldrins-race-into-space-and-space-program-games-in-general/)
- Prestige mechanics: earned through "firsts"; the second successful mission of a type usually earns some points and later ones few or none; skipping a milestone causes a safety penalty to dependent missions; "Falling too far behind gets you fired" — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space); [COMPUTE!](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- Mission resolution is dice-based per step; failed components reset to near-zero reliability (criticised as illogical); Interplay issued "a patch to tweak the numbers somewhat" after complaints — [Digital Antiquarian](https://www.filfre.net/2020/01/buzz-aldrins-race-into-space-and-space-program-games-in-general/)
- A 1.01 patch and a "Sound Config Patch" for the original exist as archive.org software items (`BARIS101_ZIP`, `BARIS_ZIP`) — [archive.org search](https://archive.org/advancedsearch.php?q=%22race+into+space%22&fl%5B%5D=identifier&fl%5B%5D=title&fl%5B%5D=mediatype&rows=50&output=json)

### Inferences
- (Inferred) Injury as a distinct state (vs death) is not mentioned by any reviewer; it may not exist in the original, or may be subsumed under "random event" outcomes.

### Gaps
- Existence and behaviour of a memorial / Hall of Fame / Museum screen, and whether deceased astronauts carry a prestige or mood effect beyond the mission-failure penalty: not sourced.

---

## A6. Named rosters: real names, and usability of historical names

### Takeaway
The original used real historical astronauts and cosmonauts (reviewers cite Glenn, Conrad and Aldrin by name as roster members); the Buzz Aldrin name/likeness was a separate licence limited to the DOS game and has been removed from the open-source port. Historical names are facts, but the sources show real-person name use is governed by publicity/passing-off law rather than copyright, with different outcomes in the US and NZ.

### Cited Findings
- Roster described as "106 simplified profiles (per side) of real-life flyboys" — [COMPUTE! Oct 1993](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php)
- Player logs cite real names in-game: "Glenn, automobile accident"; "Aldrin skill" LM points — [Orbiter-Forum thread](https://webmail.orbiter-forum.com/goto/post?id=336463); HotU names "astronaut Pete Conrad" and "Wernher von Braun (his Nova concept)" — [HotU](https://www.homeoftheunderdogs.net/game.php?id=160)
- Valentina Tereshkova appears as a historical milestone — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- Aldrin "consulted on the game and gave permission for his name to be used," in an advisory role by August 1991, and spoke at a 1992 CES reception — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space); his role was "largely promotional" — [Digital Antiquarian](https://www.filfre.net/2020/01/buzz-aldrins-race-into-space-and-space-program-games-in-general/)
- Open-source port: "Dr. Aldrin's name and imagery have been dropped because permission to use them was limited to the old DOS game" — [Flathub](https://flathub.org/en/apps/org.raceintospace.Raceintospace)
- The 2014 successor is sold with the line "Buzz Aldrin name licensed from Buzz Aldrin Enterprises" — [GOG](https://www.gog.com/en/game/buzz_aldrins_space_program_manager)
- A data file named `NautRoster.txt` exists in the SourceForge download set (not opened; name only) — [OSDN mirror listing via search](https://es.osdn.net/projects/sfnet_raceintospace/downloads/NautRoster.txt/)
- US right-of-publicity: Aldrin sued Topps (filed Dec 2010) over his name/image on the 2009 "American Heritage: American Heroes" cards; on 27 Sept 2011 the court denied a preliminary injunction because the cards "use Aldrin's name in the course of conveying information about his historically significant achievements" and were not purely commercial — [Cardboard Connection](https://www.cardboardconnection.com/moon-topps-wins-buzz-aldrin-lawsuit/amp); Law360 reports the suit was later dismissed as protected speech — [Law360 via search](https://law360.com/articles/274660/buzz-aldrin-fight-over-topps-cards-grounded). Aldrin's complaint described his name and likeness as "valuable assets" — [collectSPACE via search](https://www.collectspace.com/news/news-112999a.html)
- Aldrin's earlier publicity disputes: Omega (no suit) and Bacardi (settled, public apology); NASA later adopted standards for compensating astronauts for commercial use of image/name — [Slaw.ca, 22 Jul 2009](https://www.slaw.ca/2009/07/22/one-small-step-for-a-brand/)
- NASA policy: if imagery "includes an identifiable person, using the image for commercial purposes may infringe that person's right of privacy or publicity" — [NASA via search](https://www.nasa.gov/wp-content/uploads/2016/01/aldrin_buzz.pdf)
- USPTO: no standalone "BUZZ ALDRIN" word mark surfaced; Buzz Aldrin Enterprises, Inc. is listed as owner of an image mark (serial 77435988, filed 31 Mar 2008, radios/telescopes) and THEREALBUZZ (serial 85856184, energy drinks); status not shown — [Justia trademarks via search](https://trademarks.justia.com/owners/buzz-aldrin-enterprises-inc-3291140) (page itself returned 403)
- NZ: a commentator in the Jonah Lomu documentary dispute said there are "no relevant personality or publicity rights" in New Zealand; the leading NZ character-merchandising case *Tot Toys Ltd v Mitchell* [1993] 1 NZLR 325 was decided as passing off — [Asia IP via search](https://asiaiplaw.com/index.php/article/wife-of-late-nz-rugby-legend-loses-control-of-hubbys-ip-in-trademark-battle-with-his-lawyer); [NZ Law Reports headnote](https://www.lawreports.nz/tot-toys-ltd-v-mitchell-1993-1-nzlr-325/)
- NZ commentators on game clones say protection is more likely via "a catchy brand (trade mark)" and "visual environment (copyrighted characters and graphics)", and that some clones "could well amount to trade mark infringement and the tort of passing off" — [Play It Again: Law and the game cloners](https://ourdigitalheritage.org/hostedArchives/playitagain/law-and-the-game-cloners/index.html)

### Inferences
- (Inferred) Historical facts (that John Glenn was a Mercury astronaut, flew in 1962, etc.) are not copyrightable in either the US or NZ (see B4), so a cleanroom game can recreate a historical roster from public histories without copying the original's roster file. The risk vector for real names is not copyright but (a) US state publicity rights for living/recently deceased astronauts in commercial products and (b) passing off / false endorsement, which is sharply higher for *Buzz Aldrin* because his name is a licensed brand and was the game's title.
- (Inferred) The Topps ruling (informational, historical use is protected speech in the US) is favourable to a historical roster, but it was a US First Amendment outcome; it does not transfer to NZ law, where passing off is the relevant tort and would turn on implied endorsement.
- (Inferred) Using a title without "Buzz Aldrin" and omitting his likeness/voice is necessary; including "Aldrin" as one roster entry among ~100 historical names is lower-risk than title use, but a trademark/publicity check by counsel is warranted. Fictional names remove this question entirely at the cost of historical flavour.

### Gaps
- Whether the original roster used the full real names of all ~106/side (vs a mix of real and invented Soviet names) is not confirmed; the Soviet side's hardware is described as "more speculative" but no source addresses cosmonaut names specifically — [Digital Antiquarian](https://www.filfre.net/2020/01/buzz-aldrins-race-into-space-and-space-program-games-in-general/).
- Live USPTO/IPONZ status of any "BUZZ ALDRIN" marks: not verified (Justia page 403; no IPONZ search run).

---

## B1. Release timeline, versions, open-source release, community ports and licences

### Takeaway
Floppy DOS release 11 March 1993 (after 28 months of development; Interplay deal signed Aug 1991), CD-ROM 1994 (adds launch video, multiplayer modes), Japanese PC-98 1995; rights reverted to Bronner and the source was released under GPL in 2005 (SourceForge project registered 20 Jan 2005); community port v1.0/1.1 (2013) and v2.0.0 (2025, C→C++, JSON data, moved to GitHub); licence GPL-2.0 (packagers list GPL-2.0-or-later). The 1993 game is not sold on Steam/GOG; only the 2014 successor *Buzz Aldrin's Space Program Manager* is.

### Cited Findings
- Board-game origin: Bronner's *Liftoff!* (Task Force Games, debuted Origins summer 1989; some sources say 1988); his contract gave New World one year to develop a computer version, after which rights reverted to him; Strategic Visions formed end of 1990 with programmer Michael K. McCarty (recruited Nov 1990, age 22) — [Digital Antiquarian](https://www.filfre.net/2020/01/buzz-aldrins-race-into-space-and-space-program-games-in-general/); [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space); [oldgames.sk company page](https://www.oldgames.sk/en/company/strategic-visions-inc)
- Interplay signed August 1991 with a projected May 1992 release; the game then became *Buzz Aldrin's Race into Space*; a six-month plan ran ~3x longer; Interplay's art team produced most non-digitised graphics; development moved from Amiga to MS-DOS — [Digital Antiquarian](https://www.filfre.net/2020/01/buzz-aldrins-race-into-space-and-space-program-games-in-general/); [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- Floppy release 11 March 1993; ~100 MB of photos/animations cut for space; modem play dropped — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space). Fedora/SourceForge prose says "disk-based game in 1992" — [Fedora](https://packages.fedoraproject.org/pkgs/raceintospace/raceintospace); [SourceForge](https://sourceforge.net/projects/raceintospace/) — conflicting with 1993 given by Wikipedia, oldgames.sk and the COMPUTE! review date (Oct 1993).
- CD-ROM 1994 (~14 months after floppy): incorporated floppy updates, "improved video of the mission launches," new multiplayer modes; produced for Interplay by Rusty Buchert; reviewers mention ~600 MB historical footage and the orchestral music tracks "only on the CD version" (only two tracks done due to size) — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space); [HotU](https://www.homeoftheunderdogs.net/game.php?id=160); [SpaceSector](https://www.spacesector.com/blog/wp-json/wp/v2/posts/9465)
- CD-ROM SKU details: Interplay product ID 40421-13024, UPC 040421130245, box includes a historical book; requirements MS-DOS 3.1, 386, 4 MB, VGA; 2-player modem and Internet email play — [Eli's Software Encyclopedia](https://elisoftware.org/wiki/Buzz_Aldrin%27s_Race_Into_Space_(PC,_CD-ROM)_Interplay_Productions_-_1993_USA,_Canada_Release)
- Japanese PC-98 edition 1995 (Japan only) — [oldgames.sk](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space); archive.org lists `buzz_aldrins_race_into_space_jp_1995_dos` — [archive.org](https://archive.org/advancedsearch.php?q=%22race+into+space%22&fl%5B%5D=identifier&fl%5B%5D=title&fl%5B%5D=mediatype&rows=50&output=json)
- Companion print: Bronner's manual; 132-page historical guide *The Conquest of Space* (with Robert Reeves); 400-page *Buzz Aldrin's Race into Space Companion* (Osborne/McGraw-Hill) with designer notes and an Aldrin interview — [COMPUTE!](https://www.atarimagazines.com/compute/issue157/88_Buzz_Aldrins_Race_i.php); companion book author also given as Anthony Mesaros "with help from NASA" — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- Original patch: Interplay released "a patch to tweak the numbers" after difficulty complaints — [Digital Antiquarian](https://www.filfre.net/2020/01/buzz-aldrins-race-into-space-and-space-program-games-in-general/); archive.org has `BARIS101_ZIP` (1.01 patch) — [archive.org](https://archive.org/advancedsearch.php?q=%22race+into+space%22&fl%5B%5D=identifier&fl%5B%5D=title&fl%5B%5D=mediatype&rows=50&output=json)
- Strategic Visions wound down; Bronner "regained the rights and in 2005 released the game's source code as open source under the name Race Into Space" — [oldgames.sk](https://www.oldgames.sk/en/company/strategic-visions-inc). Digital Antiquarian: "Bronner's rights reverted to him, and in 2005 he released the game under the General Public License, along with all of its source code" — [filfre.net](https://www.filfre.net/2020/01/buzz-aldrins-race-into-space-and-space-program-games-in-general/). Escapist (Oct 2005): "The BARIS copyright has reverted to the designers, who have made the game freely available"; the SourceForge port "appears to have stalled" at that time — [Escapist](https://www.escapistmagazine.com/the-buzz-is-gone/)
- Wikipedia's framing: "After Interplay's 2005 bankruptcy, the developers released the source code and content under the GPL, and the music as freeware" — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space). Note: Interplay's own history shows Titus (its parent) declared bankrupt Jan 2005 and Interplay was "brought up to the bankruptcy court" in 2006; the article does not say Interplay itself filed in 2005 — [Wikipedia: Interplay Entertainment](https://en.wikipedia.org/wiki/Interplay_Entertainment). (Conflict/imprecision flagged.)
- SourceForge project registered 2005-01-20; licence GPLv2; v1.1 released 2013; v2.0.0 current, hosted on GitHub (moved 2025-03-27 per page; developer reply confirming 2.0 edited 2025-12-17); copyright line "Original source Copyright (C) 2005 Michael K. McCarty & Fritz Bronner" — [SourceForge](https://sourceforge.net/projects/raceintospace/); [raceintospace.sourceforge.net](https://raceintospace.sourceforge.net/)
- Downloads: over 90,000 from SourceForge 2005–2017; Pandora port v1.1.0.2 Sept 2013; Android 1.0c build on archive.org — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space); [archive.org](https://archive.org/advancedsearch.php?q=%22race+into+space%22&fl%5B%5D=identifier&fl%5B%5D=title&fl%5B%5D=mediatype&rows=50&output=json)
- v2.0 (2025): code converted from C to C++, many data files converted to JSON, project moved from SourceForge to GitHub; Mac build had no music at release, 2.0.1 planned — [GitHub release page via search, not opened](https://github.com/raceintospace/raceintospace/releases/tag/v2.0.0); [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space)
- Packaging: Fedora `raceintospace` 2.0.0, licence field "GPL-2.0-or-later", upstream URL raceintospace.org; separate `raceintospace-data` and `raceintospace-doc` packages — [Fedora](https://packages.fedoraproject.org/pkgs/raceintospace/raceintospace); Flathub lists 2.0, "developed by Raceintospace", community-provided — [Flathub](https://flathub.org/en/apps/org.raceintospace.Raceintospace)
- Commercial availability: the 1993 game is not sold; abandonware sites host the floppy version — [Escapist](https://www.escapistmagazine.com/the-buzz-is-gone/). Steam/GOG carry only the 2014 successor *Buzz Aldrin's Space Program Manager* (Polar Motion / Slitherine, 31 Oct 2014, DRM-free on GOG) — [GOG](https://www.gog.com/en/game/buzz_aldrins_space_program_manager); [Steam](https://store.steampowered.com/app/308270/Buzz_Aldrins_Space_Program_Manager/)

### Inferences
- (Inferred) The GPL release was made by the authors (McCarty & Bronner) as rights-holders after reversion, not by Interplay; Wikipedia's "Interplay's 2005 bankruptcy" is loose. The copyright line on the SourceForge site supports authors-as-licensors.
- (Inferred) "GPL-2.0-only" (SourceForge, OpenTTD-style) vs "GPL-2.0-or-later" (Fedora) disagree; the exact "or later" clause must be read from the COPYING/LICENSE in the repo, which this research deliberately did not do.

### Gaps
- No contemporaneous 2005 announcement (Slashdot, Freshmeat, press release) was found; the precise release date within 2005 and the exact wording of what was released are unconfirmed.
- The original v1.0 of the port's release date was not found (only v1.1 = 2013).

---

## B2. Who owns the copyright now; Buzz Aldrin name/likeness; title implications

### Takeaway
Sources agree the game copyright reverted from the publisher to the designers (Bronner and McCarty), who licensed the code under GPL in 2005; the "Buzz Aldrin" name and imagery were a separate permission limited to the DOS game and are now licensed commercially through Buzz Aldrin Enterprises, so a reimplementation must use a different title and omit his likeness/voice.

### Cited Findings
- "After the company wound down, Fritz Bronner regained the rights" — [oldgames.sk](https://www.oldgames.sk/en/company/strategic-visions-inc); "The BARIS copyright has reverted to the designers" — [Escapist, Oct 2005](https://www.escapistmagazine.com/the-buzz-is-gone/); "Original source Copyright (C) 2005 Michael K. McCarty & Fritz Bronner" — [raceintospace.sourceforge.net](https://raceintospace.sourceforge.net/)
- Original "Software copyright: Strategic Visions" per HotU; publisher Interplay — [HotU](https://www.homeoftheunderdogs.net/game.php?id=160)
- Interplay's own art team produced most non-digitised graphics — [Digital Antiquarian](https://www.filfre.net/2020/01/buzz-aldrins-race-into-space-and-space-program-games-in-general/)
- Interplay corporate status: Titus bankrupt Jan 2005; Interplay bought Titus's assets; in bankruptcy court 2006; sold Fallout IP 2007 — [Wikipedia: Interplay](https://en.wikipedia.org/wiki/Interplay_Entertainment)
- Aldrin "gave permission for his name to be used" (1991–92) — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space); the port dropped his "name and imagery because permission to use them was limited to the old DOS game" — [Flathub](https://flathub.org/en/apps/org.raceintospace.Raceintospace)
- "Buzz Aldrin name licensed from Buzz Aldrin Enterprises" for the 2014 Slitherine game — [GOG](https://www.gog.com/en/game/buzz_aldrins_space_program_manager); Buzz Aldrin Enterprises, Inc. holds USPTO filings (image mark serial 77435988; THEREALBUZZ serial 85856184) — [Justia via search](https://trademarks.justia.com/owners/buzz-aldrin-enterprises-inc-3291140)
- The 1993 CD-ROM "included original voice and video recordings of the actual 1960s events" — [GOG user review via search](https://www.gog.com/en/game/buzz_aldrins_space_program_manager)

### Inferences
- (Inferred) Three distinct rights layers exist: (1) game code and design documents — Bronner/McCarty, GPL'd; (2) art produced by Interplay's art team — ownership depends on the 1991 publishing contract (unknown); the existence of a separate "nonfree" data repository (B3) suggests at least some assets could not be GPL'd; (3) Aldrin name/likeness/voice — Aldrin/Buzz Aldrin Enterprises, never transferable by the developers.
- (Inferred) Because Interplay's successors may still hold rights in Interplay-produced art, FMV editing and the CD-ROM voice work, the "proprietary" risk for a cleanroom project is concentrated in audio-visual assets, not rules.

### Gaps
- The 1991 Interplay–Strategic Visions contract terms (who owns Interplay-produced art, FMV compilation, music commissioned for CD) were not found.
- Whether the historical NASA/Soviet footage on the CD was public-domain NASA film vs licensed archive footage: not sourced.

---

## B3. Which assets were open-sourced vs still proprietary

### Takeaway
Reports say "source code and content" went under GPL and the music was released as freeware, but the project maintains a separate repository described as "Race into Space game data with licensing restriction," and the Aldrin name/imagery were withdrawn. The exact file-by-file split could only be verified by reading the repositories, which the cleanroom rule forbids.

### Cited Findings
- "the developers released the source code and content under the GPL, and the music as freeware" — [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space); same at [oldgames.sk](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space)
- A software-archive index says Interplay "released this game's source and data as freeware in 2005" — [archived.software via search](https://proxy.archived.software/QmTkRqm4ysSErYX3MRoJRybM8N182F6sErpkJ92AqCjW1i) (page itself failed TLS; snippet only; the attribution to Interplay conflicts with the authors-as-licensors sources above)
- A GitHub repository `raceintospace-nonfree` is described as "Race into Space game data with licensing restriction," separate from the main GPL code — [GitHub org via search, not opened](https://www.github.com/raceintospace)
- Fedora ships `raceintospace-data` as a separate package from the engine — [Fedora data package](https://packages.fedoraproject.org/pkgs/raceintospace/raceintospace-data/)
- The port "comes with both the original versions and the orchestral" soundtrack — [SpaceSector](https://www.spacesector.com/blog/wp-json/wp/v2/posts/9465)
- Aldrin's name and imagery removed from the port — [Flathub](https://flathub.org/en/apps/org.raceintospace.Raceintospace)
- v2.0 converted "many data files to JSON" — [GitHub release via search, not opened](https://github.com/raceintospace/raceintospace/releases/tag/v2.0.0)
- A fan "Guide to creating replacement movies for RIS.doc" exists in the SourceForge Mods downloads (title only, not opened) — [OSDN mirror via search](https://fr.osdn.net/projects/sfnet_raceintospace/downloads/Mods/Guide%20to%20creating%20replacement%20movies%20for%20RIS.doc/)

### Inferences
- (Inferred) "Content under GPL" cannot have been complete, since a restricted-data repo exists; likely candidates for restriction are the FMV/launch footage, voice recordings and Aldrin imagery, with music as freeware (not GPL). The existence of a guide for *replacement* movies suggests the original CD video is not freely redistributable.
- (Inferred) For a cleanroom project this split is largely moot: the project should produce its own art, text, music and data regardless, and must not pull from either repository.

### Gaps
- Precise list of what is in `raceintospace-nonfree` vs the GPL tree, and the licence text of the music "freeware" grant: not readable under the cleanroom rule; would need to be confirmed by a person outside the implementation team if ever needed.

---

## B4. Legal basis of cleanroom reimplementation (US and NZ), with precedents

### Takeaway
Both US case law and NZ authority hold that copyright protects expression, not ideas, rules or methods of play; what remains protectable is code, artwork, specific text, music, audio-visual presentation and (in the US) trade dress. Clean-room design is characterised as best practice for proving independent creation rather than a legal requirement, and it does not defend against patents or trade marks.

### Cited Findings
- Clean-room design: "copying a design by reverse engineering it and then recreating it without infringing the copyrights"; it works through independent creation; it "is usually best practice rather than strictly required by law"; process = one team writes a specification, a lawyer reviews it, a separate team implements. It does not defend against patents. Cases: *Apple v. Franklin*, 714 F.2d 1240 (3d Cir. 1983) (firmware is copyrightable); *NEC v. Intel* (1990) (functional similarities not creative expression; first US trial to accept the clean-room argument); *Sony v. Connectix*, 203 F.3d 596 (9th Cir. 2000) (BIOS "contains unprotected aspects that cannot be examined without copying") — [Wikipedia: Clean room design](https://en.wikipedia.org/wiki/Clean_room_design)
- *Tetris Holding, LLC v. Xio Interactive, Inc.*, 863 F. Supp. 2d 394 (D.N.J. 30 May 2012, Wolfson J): gameplay rules and mechanics are not copyrightable; the US Copyright Office view quoted: "copyright does not protect the idea for a game, its name or title, or the method or methods for playing it"; but expressive choices (20x10 board, piece colours/styles, shadow piece, next-piece preview, etc.) were protectable and Mino infringed; Xio had admitted copying — [Wikipedia](https://en.wikipedia.org/wiki/Tetris_Holding,_LLC_v._Xio_Interactive,_Inc.); commentary: "Any game expression can always be defined as relating to a game rule" (rejecting a rules-only defence) — [Cole Schotz](https://www.coleschotz.com/?p=5314)
- *Spry Fox v. Lolapps* (W.D. Wash. 2012, Jones J): motion to dismiss denied; "Spry Fox has plausibly identified enough copying to state a claim"; look-and-feel can be protected; settled Oct 2012 with Spry Fox taking ownership of Yeti Town — [Wikipedia](https://en.wikipedia.org/wiki/Spry_Fox,_LLC_v._Lolapps,_Inc.); [MCV](https://mcvuk.com/development-news/triple-town-cloning-suit-settled/)
- Counter-example: *DaVinci v. Ziko Games* (S.D. Tex. 2016): re-skinning a game's rules with a new theme escaped liability — [FKKS](https://fkks.com/news/how-courts-view-copyright-protection-for-video-games)
- NZ: "copyright does not protect ideas"; "Copyright protects only particular expressions of an idea and not the idea itself"; TRIPS art 9(2) quoted; NZ Court of Appeal in *Karum v Fisher & Paykel Finance* (a software case): "It is the expression of an idea, rather than the idea itself, that copyright protects"; using another's idea in a new combination does not infringe under the 1994 Act — [AJ Park](https://ajpark.com/insights/copyright-act-review-does-copyright-suppress-innovation-what-does-it-actually-protect-copyright-does-not-protect-ideas/)
- NZ Copyright Act 1994: protection is automatic; categories are literary, dramatic, artistic, musical works, sound recordings, films, broadcasts, typographical arrangements; computer programs are literary works; term 50 years p.m.a. for literary/artistic/musical works, 50 years from release for films and sound recordings; the 2021 UK FTA commits NZ to a 20-year extension within 15 years; only software exception listed is back-up copies — [Wikipedia: Copyright law of New Zealand](https://en.wikipedia.org/wiki/Copyright_law_of_New_Zealand)
- NZ academic view: the Act "makes it clear that computer programs are protected as a literary work, but the extent of that protection is unclear"; NZ courts would likely protect "look and feel" more readily than US courts; non-literal elements such as menu structures are unsettled — [VUW Law Review via search](https://ojs.victoria.ac.nz/vuwlr/article/view/6109)
- NZ game-clone commentary: "copyright law has never protected an idea; it only protects the expression of an idea"; best protection for a game is a brand (trade mark) and the "visual environment (copyrighted characters and graphics)"; clones "could well amount to trade mark infringement and the tort of passing off"; the Patents Act 2013 excludes "computer programs, as such" but has no European-style exclusion for "methods of playing a game" — [Play It Again: Law and the game cloners](https://ourdigitalheritage.org/hostedArchives/playitagain/law-and-the-game-cloners/index.html)
- Open-source reimplementation precedents: OpenTTD (announced 2003 as a reverse-engineering of TTD to C; v0.1 6 Mar 2004; GPL-2.0-only; in 2009 added alternative base graphics/sound/music sets; OpenMSX music is community-composed GPLv2; free on Steam from Feb 2021; after Atari's March 2026 TTD re-release OpenTTD is no longer free on Steam/GOG but remains free from its own site; now "does not contain any content from the Transport Tycoon Deluxe game") — [Wikipedia: OpenTTD](https://en.wikipedia.org/wiki/OpenTTD); [SlackBuilds](https://www.slackbuilds.org/repository/14.2/games/openttd/); [GamingOnLinux 2026](https://www.gamingonlinux.com/2026/03/transport-tycoon-deluxe-returns-from-atari-now-a-requirement-for-openttd-via-steam-and-gog/comment_id=291614)
- Freeciv: begun Nov 1995 by three Aarhus students, first release Jan 1996; "The rules of the game were close to Civilization," architecture from XPilot; GPL-2.0-or-later; no legal challenge reported — [Wikipedia: Freeciv](https://en.wikipedia.org/wiki/Freeciv)
- OpenRA: open-source remake of early C&C games that "uses the assets (art and sound files) from the original games"; freeware status of Tiberian Dawn/Red Alert/Tiberian Sun assets is community-asserted, Dune 2000 "legally dubious" per commenters; no EA statement found — [OpenRA forum](https://forum.openra.net/viewtopic.php?p=300798); [GamingOnLinux 2018 comments](https://www.gamingonlinux.com/2018/02/a-new-openra-release-adds-the-full-harkonnen-campaign-for-dune-2000-and-more/page=1/)
- Open Fodder: engine only; "requires the user to own a copy of Cannon Fodder" and copy the data files (e.g. `CF_ENG.DAT`), obtainable from GOG — [pkgsrc](https://pkgsrc.se/wip/openfodder-data); [OpenBSD port](https://openports.pl/path/games/openfodder); [GamingOnLinux 2020](https://gamingonlinux.com/2020/01/open-fodder-the-open-source-game-engine-for-cannon-fodder-has-a-new-release)

### Inferences
- (Inferred) The precedent pattern is: engine reimplementations that depend on the owner's data files (Open Fodder, early OpenTTD, OpenRA) tolerate rather than resolve the rights question; projects that replaced all assets with original ones (OpenTTD post-OpenGFX/OpenSFX/OpenMSX; Freeciv from day one) are the safer model and the one closest to this project's cleanroom goal.
- (Inferred) Under both regimes the protectable surface of BARIS is: source code (GPL'd but off-limits to a cleanroom by project rule), Interplay/Strategic Visions artwork and UI pixel art, mission/news/event text strings, the manual and companion book text, music, FMV compilation and voice-overs, and the specific audiovisual look-and-feel (which NZ courts may protect more readily than US courts). Not protectable: the six-month-turn structure, prestige-for-firsts concept, five-skill astronaut model, dice-per-step mission resolution, R&D/safety concepts, historical facts, dates, names of programs and hardware.
- (Inferred) Because Tetris v. Xio found even simple presentational choices (board dimensions, preview display) to be expression, a cleanroom BARIS should avoid reproducing distinctive screen layouts (e.g. the space-center-as-menu scene) pixel-for-pixel or in close composition, not just the code.
- (Inferred) Patents are unlikely to matter for a 1993 design (any US patents would have expired), but the clean-room doctrine's explicit non-coverage of patents and trade marks is why the title must change.

### Gaps
- No NZ case was found that applies the idea/expression line to video-game rules specifically; the nearest NZ authorities are *Karum* (software) and the Play It Again commentary. Statutory text of the Copyright Act 1994 (legislation.govt.nz) was not fetched directly; the summary relies on Wikipedia and AJ Park.
- Whether NZ has implemented the UK-FTA term extension (to 70 years) as of 2026: not confirmed.

---

## B5. Prior community reimplementations or remakes (other than the GPL port)

### Takeaway
No independent fan remake of BARIS was found; the only continuation is the GPL port (and its distro/Flathub/Pandora/Android builds), and the only new game is the officially licensed 2014 *Buzz Aldrin's Space Program Manager* (Polar Motion/Slitherine), which reviewers regard as a weaker successor without period footage.

### Cited Findings
- The GPL port is the single lineage: SourceForge 2005 → v1.1 (2013) → GitHub v2.0.0 (2025); Pandora v1.1.0.2 (Sept 2013); Android 1.0c build on archive.org — [SourceForge](https://sourceforge.net/projects/raceintospace/); [Wikipedia](https://en.wikipedia.org/wiki/Buzz_Aldrin%27s_Race_Into_Space); [archive.org](https://archive.org/advancedsearch.php?q=%22race+into+space%22&fl%5B%5D=identifier&fl%5B%5D=title&fl%5B%5D=mediatype&rows=50&output=json)
- In Oct 2005 the SourceForge port "appears to have stalled" and a commercial remake was "increasingly unlikely" — [Escapist](https://www.escapistmagazine.com/the-buzz-is-gone/)
- Reader comments on the Digital Antiquarian say Bronner later developed *LIFTOFF! 2.0* (board game); Home of the Underdogs notes he still sold copies of the original *Liftoff!* — [filfre.net comments](https://www.filfre.net/2020/01/buzz-aldrins-race-into-space-and-space-program-games-in-general/); [HotU](https://www.homeoftheunderdogs.net/game.php?id=160)
- *Buzz Aldrin's Space Program Manager* (Polar Motion, Slitherine, 31 Oct 2014) is described by reviewers as the successor to BARIS, with a sandbox mode for three agencies; some call it clunkier with "no period video footage" — [GOG](https://www.gog.com/en/game/buzz_aldrins_space_program_manager); [Steam](https://store.steampowered.com/app/308270/Buzz_Aldrins_Space_Program_Manager/); also named "spiritual successor" by [oldgames.sk](https://www.oldgames.sk/en/game/buzz-aldrins-race-into-space)
- A BARIS fan wiki (`baris-online.net`) linked from the SourceForge site no longer resolves — [raceintospace.sourceforge.net](https://raceintospace.sourceforge.net/) (DNS failure on fetch, 2026-10-11)
- An itch.io project named "Race In Space" (formosadev) surfaced in search but is unrelated to BARIS on the evidence seen — [itch.io via search](https://formosadev.itch.io/race-in-space/devlog/522867/finalized-release)

### Inferences
- (Inferred) The absence of any other remake means this project has no prior cleanroom spec to borrow from; it also means there is no precedent of the rights-holders objecting to a reimplementation, for better or worse.

### Gaps
- No search of itch.io/GitHub for abandoned BARIS-inspired hobby projects beyond the one search above; a wider survey could be run by someone permitted to browse repositories.
