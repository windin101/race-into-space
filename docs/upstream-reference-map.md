# Upstream reference map: `reference/raceintospace`

Where every piece of **game data** and **documentation** lives in the shallow clone of
[raceintospace/raceintospace](https://github.com/raceintospace/raceintospace)
(HEAD `e1fbccc`, post-2.0.0 master, cloned 2026-10-11). All paths below are relative to
`reference/raceintospace/`. The clone is read-only reference material: load the tables from it,
never build or run anything inside it.

Quick orientation:

| Area | Path | What it is for a Godot port |
|---|---|---|
| Rules tables | `data/gamedata/*.json` (26 files, 14 MB incl. one 8.5 MB binary) | **The payload.** Hardware, missions, prestige, rosters, news, failures, help text. |
| Media | `data/audio/`, `data/images/`, `data/video/` (1,979 files, 80 MB) | Original Interplay art/voice/video converted to PNG/OGG. Present in clone; music is not. |
| Manual | `doc/manual/manual.md` (2,141 lines, 17k words, 41 images) | Rewritten 2.0 manual with the numeric tables. |
| Engine | `src/game/*.cpp` (~70 files) | Only consulted here to locate what is *not* data (section 6). |

## 1. `data/` tree

`data/` has exactly four subtrees, all installed verbatim by `CMakeLists.txt:72`
(`install(DIRECTORY data/audio data/gamedata data/images data/video icons ...)`). There is no
`data/README`, `data/LICENSE` or `data/audio/music/` in the clone. The game locates files via the
`BARIS_DATA` env var (`dist/linux-tgz/run.sh`, `README.md`), so the directory layout is load-bearing
for upstream but irrelevant to a reimplementation.

### 1.1 `data/gamedata/` - the rules tables

All JSON is written by the `cereal` C++ serializer, so expect its quirks: a single wrapper key
(`"value0"`, `"missionData"`, ...), fixed-size C arrays emitted as objects with `"value0".."valueN"`
keys, and a `"cereal_class_version"` field on the first record of each vector. Text uses the
original BARIS control characters: `*` = line break, trailing `x` = end-of-string.

| File | Format | Contents | Size / rows | Loaded by |
|---|---|---|---|---|
| `hist.json` | JSON | **Historical-model hardware table**: 8 vectors (`Data->P[0..1].{Probe,Rocket,Manned,Misc}`) x 7 `Equipment` slots each; cost, safety, Max R&D, Max Safety, weight, payload. | 50 KB, 56 slots (42 non-empty) | `src/game/prefs.cpp:517` (only when model is Historical) |
| `urast.json` | JSON | Entire zeroed **new-game state** (`struct Players`). Contains the **Basic-model hardware table** (same 8 vectors, balanced US/USSR values), the **28-row prestige table** (`Prestige[].Add`), difficulty struct `Def`, both players' opening `Budget` (60) and names (WEBB / KOROLYOV), empty astronaut `Pool[65]`, `Mission[3]`, `History[100]`. | 942 KB | `src/game/game_main.cpp:232` |
| `mission.json` | JSON | **Mission list**: 62 `mStr` records (index 0 = NONE ... 61 = rescue variants) with name, step-sequence `Code`, 36-slot `Alt`/`AltD` alternate-step tables, flags `Days Dur Doc EVA LM Jt Lun mEq mCrew`, `mVab[2]` and `PCat[5]` (prestige categories awarded). | 182 KB, 62 rows | `src/game/mission_util.cpp:240` |
| `missSteps.json` | JSON (list of strings) | **Future-mission diagram steps** per mission index: one line per mission, tokens `A1 B0 C000 D00 ... Z` drawn by the Future Missions bubble screen. | 3.7 KB, 66 lines (62 real) | `src/game/futbub.cpp:145` |
| `downgrades.json` | JSON | For each mission index, the ordered list of mission indices it may be **downgraded** to when hardware is missing (e.g. 56 -> [51, 49, 0]). | 2.8 KB, 62 rows | `src/game/downgrader.cpp` |
| `fails.json` | JSON | **Failure-mode table**: 925 records keyed by `MissionStep` (44 step codes `F000..F0xx`, `F1xx`) with `percentage` (roll band), `code`/`val`/`xtra` (outcome codes), `fail` (35 distinct failure IDs) and the on-screen `text`. | 207 KB, 925 rows | `src/game/game_main.cpp:216` |
| `crew.json` | JSON | **Historical astronaut/cosmonaut roster, flat**: 224 records `Name Sex Race Service Cap LM EVA Docking Endurance`. | 54 KB, 224 rows | `src/game/admin.cpp:277` (`CacheCrewFile`) |
| `roster.json` | JSON | **Roster by recruitment group**: 2 players x 5 groups; each group has `entries[]` (14/21/23/31/23 names), `number_to_choose` (7/9/14/16/14) and `recruiting_delay` (6/4/4/8/99 seasons). Entry keys: `sex race service capsule docking endurance eva lunar name`. | 88 KB, 224 entries | `src/game/ast1.cpp:641` |
| `event.json` | JSON | **Newscast event text**: `us_event[117]` and `sov_event[117]` of `{text, color}` (color 0/1/2 = neutral/good/bad). | 48 KB, 234 rows | `src/game/news.cpp:1037` |
| `news.json` | JSON | **Filler news strings**: `astro_news[12]`, `cosmo_news[12]`, `us_reasons[13]`, `sov_reasons[13]` (retirement reasons), `us_news[124]`, `sov_news[83]`. | 23 KB, 257 strings | `src/game/news.cpp:1054` |
| `ntable.json` | JSON (int list) | **Budget-adjustment table** used by the newscast: 180 ints = 3 blocks x 6 budget bands x 10 random picks (bands 0-50, 50-90, 90-110, 110-140, 140-160, 160+ MB). | 1 KB, 180 ints | `src/game/news_suq.cpp:107` |
| `p_rev.json` | JSON | **Presidential/Politburo review text**: 36 strings. | 4 KB, 36 rows | `src/game/review.cpp:378` |
| `endgame.json` | JSON | **End-of-game narration**: 12 strings indexed by outcome. | 4.7 KB, 12 rows | `src/game/endgame.cpp:831` |
| `help.json` | JSON | **In-game help/F1 text**: 289 records `{Code: "I001".., description[]}` with layout directives (`%07:0`, `.011`). | 168 KB, 289 rows | `src/game/game_main.cpp:217` |
| `seq.json` | JSON | **Mission-animation sequence table**: 828 records mapping a `MissionIdSequence` key (e.g. `110DEFAULT`) to 5 `video[]` + 5 `audio[]` clip IDs. | 135 KB, 828 rows | `src/game/game_main.cpp:214` |
| `fseq.json` | JSON | Same as `seq.json` but for **failure** animations, keyed additionally by `MissionStep`: 2,954 records. | 565 KB, 2,954 rows | `src/game/game_main.cpp:215` |
| `legacy-seq.json`, `legacy-fseq.json` | JSON | Old-save-game compatibility: 818-string and 2,954 `{key,value}` lookup lists mapping numeric sequence codes to the IDs above. | 12 KB + 177 KB | `src/game/legacy.cpp:265` |
| `liftoff.json` | JSON | Frame index for the launch animations: 41 `indexEntry`/`header`/`palettes`/`bHeader` records (frame counts, loop, 384-int palettes). Pairs with `data/images/liftoff/`. | 548 KB, 41 rows | `src/game/mis_c.cpp:1374` |
| `usa_port.json`, `sov_port.json` | JSON | **Spaceport screen layout**: 35 `MObj` building objects (name, help code, 4 `Reg` click regions), 43 `Img` headers, 768-int palette, 55 `pOutline` bone lists. | 295 KB + 303 KB | `src/game/port.cpp:235,275` |
| `vtable.json` | JSON | VAB sprite rectangles: 56 `{x1,y1,x2,y2,yOffset}` (2 players x 28) into `images/vab.img.*.png`. | 7.6 KB, 56 rows | `src/game/vab.cpp:118` |
| `portbut.json` | JSON | 7 x 570-byte raw sprite arrays for the AI-purchasing screen buttons. | 65 KB | `src/game/aipur.cpp:124` |
| `letter.json` | JSON (int list) | **Bitmap heading font**: 20,540 bytes of 15-px-tall glyph cells (width byte + pixels) for ASCII `' '..'?'` and `'A'..'`'`, consumed by `draw.cpp:144 draw_heading`. The body-text font is not data at all (see 1.2). | 226 KB | `src/game/pace.cpp:45` |
| `news.cdr` | **binary** | Original BARIS newscast image archive. Superseded: the engine now loads `images/news/news.cdr.{usa,ussr}.N.png` (`news.cpp:1012`). | 8.5 MB | `src/utils/news2png.cpp` (converter only) |
| `spots.cdr` | **binary** | Spaceport background animations (planes, crawler): `SpotHeader` + 283 `SimpleHdr` image headers + palettized cels + 21 named animation sequences. Format documented in `src/game/spot.cpp:195-240`. | 147 KB | `src/game/spot.cpp` |
| `babypicx.cdr`, `babyclif.cdr`, `babynorm.cdr` | **binary** | Small Mission Control playback images and the two "baby" (small-window) overlays; still read at `mis_c.cpp:491`. | 941 KB + 12 KB + 12 KB | `src/game/mis_c.cpp` |

Not in `data/` but referenced by the loader: `user.json` (custom roster) and `settings.json`
(audio prefs) live in the **save** directory (`admin.cpp:279`, `settings.cpp:47`).

#### Schema: `hist.json` / `urast.json` hardware record (`struct Equipment`, `src/game/data.h:253`)

```json
{"Name":"ATLAS","ID":{"value0":82,"value1":48},"Safety":10,"MisSaf":0,"MSF":0,"Base":10,
 "InitCost":26,"UnitCost":3,"UnitWeight":0,"MaxPay":500,"RDCost":2,"Code":0,"Num":-1,
 "Spok":0,"Seas":0,"Used":0,"Steps":0,"Failures":0,"MaxRD":87,"MaxSafety":98,"SMods":0,
 "SaveCard":0,"Delay":0,"Duration":0,"Damage":0,"DCost":0,"MisSucc":0,"MisFail":0}
```

Static design columns (the rest are runtime counters): `Base` = starting safety %, `InitCost` =
program cost (MB), `UnitCost` = per-unit cost, `RDCost` = cost per R&D team, `UnitWeight`,
`MaxPay` = lift capacity (rockets only), `MaxRD` = research ceiling %, `MaxSafety` = flight ceiling
%, `Duration` = max days (capsules only; Mercury 5, Gemini 14, Apollo 21, XMS-2 15, Jupiter 24).
Slot order is fixed and indexed by the engine:

| Group | US slots 0-6 | USSR slots 0-6 |
|---|---|---|
| Probe | EXPLORER, RANGER, SURVEYOR, -, -, -, - | SPUTNIK, COSMOS, LUNA, -, -, -, - |
| Rocket | ATLAS, TITAN, SATURN, NOVA, BOOSTERS, -, - | R-7, PROTON, N1, UR-700, BOOSTERS, -, - |
| Manned | MERCURY, GEMINI, APOLLO, XMS-2, JUPITER, EAGLE (LM), CRICKET (LM) | VOSTOK, VOSKHOD, SOYUZ, LAPOT, LK-700, LKM (LM), LK (LM) |
| Misc | KICKER-A, KICKER-B, KICKER-C (US: empty), EVA SUITS, DOCKING, PHOTO RECON, - | KICKER-A, KICKER-B, KICKER-C, EVA SUITS, DOCKING, PHOTO RECON, - |

Historical values (`hist.json`) US/USSR, from the file:

| Program | Cost | Unit | R&D | Weight | Lift | MaxRD | MaxSaf |
|---|---|---|---|---|---|---|---|
| Explorer/Sputnik | 6/6 | 1/1 | 1/1 | 200/400 | - | 95/95 | 98/98 |
| Ranger/Cosmos | 24/20 | 5/3 | 3/3 | 700/1000 | - | 90/88 | 93/93 |
| Surveyor/Luna | 30/26 | 7/6 | 4/4 | 1200/1500 | - | 85/85 | 88/88 |
| Atlas/R-7 | 26/20 | 3/3 | 2/2 | - | 500/800 | 87/85 | 98/98 |
| Titan/Proton | 60/60 | 12/12 | 4/4 | - | 1200/1900 | 91/90 | 98/98 |
| Saturn/N1 | 90/84 | 18/18 | 6/7 | - | 3500/3900 | 95/93 | 98/98 |
| Nova/UR-700 | 150/150 | 30/30 | 8/8 | - | 4800/5500 | 94/94 | 98/98 |
| Boosters | 18/15 | 4/4 | 2/2 | - | 800/1200 | 85/87 | 98/98 |
| Mercury/Vostok | 20/18 | 3/3 | 1/1 | 500/700 | - | 78/76 | 92/92 |
| Gemini/Voskhod | 30/24 | 7/6 | 2/2 | 1200/1400 | - | 83/80 | 94/92 |
| Apollo/Soyuz | 40/36 | 14/12 | 5/5 | 1700/1900 | - | 89/85 | 94/94 |
| XMS-2/Lapot | 55/65 | 30/30 | 7/7 | 1400/1800 | - | 91/87 | 94/94 |
| Jupiter/LK-700 | 65/60 | 30/30 | 8/9 | 4600/5300 | - | 89/89 | 94/94 |
| Eagle/LKM | 30/35 | 8/8 | 2/2 | 1500/1700 | - | 90/91 | 94/94 |
| Cricket/LK | 42/48 | 9/9 | 4/4 | 1100/1500 | - | 89/90 | 94/93 |
| Kicker-A | 12/12 | 3/3 | 1/1 | 300/500 | - | 92/91 | 97/95 |
| Kicker-B | 18/18 | 6/6 | 2/2 | 700/700 | - | 94/91 | 97/95 |
| Kicker-C (USSR) | -/40 | -/20 | -/4 | -/3000 | - | -/90 | -/94 |
| EVA suit | 18/18 | 0/0 | 1/1 | - | - | 91/91 | 94/94 |
| Docking module | 18/15 | 3/2 | 0/0 | 300/300 | - | 0/0 | 93/94 |
| Photo recon | 0/0 | - | - | - | - | 0/0 | 99/99 |

The **Basic model** is the same 8 vectors inside `urast.json` at `value0.P.value0.{Probe,Rocket,Manned,Misc}`
(US) and `value0.P.value1.*` (USSR); e.g. Atlas there is cost 24 / lift 600 / MaxRD 84, Mercury
18 / MaxRD 76 / MaxSafety 90. The engine loads `urast.json` always and overlays `hist.json` only
when the Historical model is chosen (`prefs.cpp:268-276, 517`). The Random model is generated in
code (`src/game/randomize.cpp`) and has no data file.

#### Schema: prestige table (`urast.json` -> `value0.Prestige.value0..value27`)

```json
"value0": {"Add":[12,5,1,-3],"Goal":[0,0],"Points":[0,0],"Index":0,"Place":0,"mPlace":0,"Month":0,"Year":0}
```

`Add` = [first, second, subsequent, failure]. Row order follows the `Prestige_*` enum
(`src/game/data.h:1105-1135`); the **row names are not in the data file** - they are the hardcoded
`PF[29][40]` / `tame[29][40]` string tables in `src/game/endgame.cpp:50` and `src/game/museum.cpp:56`:

| # | Name | Add | # | Name | Add |
|---|---|---|---|---|---|
| 0 | Orbital Satellite | 12,5,1,-3 | 14 | Two-Person Craft | 7,2,0,0 |
| 1 | Lunar Flyby | 5,3,2,-3 | 15 | Three-Person Craft | 15,5,0,0 |
| 2 | Mercury Flyby | 5,2,2,-3 | 16 | Minishuttle | 20,8,0,0 |
| 3 | Venus Flyby | 7,4,2,-3 | 17 | Four-Person Craft | 20,8,0,0 |
| 4 | Mars Flyby | 7,4,2,-3 | 18 | Manned Orbital | 12,5,1,-10 |
| 5 | Jupiter Flyby | 8,4,2,-3 | 19 | Manned Lunar Pass | 12,5,2,-10 |
| 6 | Saturn Flyby | 9,4,2,-3 | 20 | Manned Lunar Orbit | 20,7,1,-10 |
| 7 | Lunar Probe Landing | 16,9,2,-5 | 21 | Manned Rescue Attempt | 10,9,9,-3 |
| 8 | Duration F | 7,7,0,0 | 22 | Manned Lunar Landing | 40,15,8,-10 |
| 9 | Duration E | 5,5,0,0 | 23 | Orbiting Lab | 6,4,0,-10 |
| 10 | Duration D | 1,1,0,0 | 24 | Manned Docking | 8,4,1,-3 |
| 11 | Duration C | 5,5,0,0 | 25 | Woman in Space | 8,0,0,-4 |
| 12 | Duration B | 3,3,0,0 | 26 | Spacewalk | 8,4,1,-3 |
| 13 | One-Person Craft | 3,1,0,0 | 27 | Manned Space Mission | 15,5,0,-10 |

#### Schema: `mission.json` record (`struct mStr`, `src/game/data.h:983`)

```json
{"Index":56,"Name":"JT LUNAR LANDING: LOR ","Abbr":"JT LUNAR LANDING: LOR",
 "Code":"+1ABJCL+2ABJOL+1IRUSQPT+2M+1I+2KNgDE!OLd+2Hd|",
 "Alt":{"value0":-1,...,"value5":23,"value6":22,...,"value35":0},
 "AltD":{"value0":0,...},
 "Days":4,"Dur":0,"Doc":1,"EVA":1,"LM":1,"Jt":1,"Lun":1,"mEq":2,"mCrew":3,
 "mVab":{"value0":97,"value1":137},"PCat":{"value0":27,"value1":18,"value2":19,"value3":20,"value4":22},"LMAd":0}
```

`Code` is the mission-step string (one letter per step, `+1`/`+2` = joint-launch part, `!` end,
`|` terminator); `Alt[36]` gives per-step alternate/abort step index (-1 none, -2 continue, -3 end);
`PCat[5]` lists up to five prestige rows (above) the mission can claim; `mCrew` = crew size;
`Days` appears to be the duration level (0 none, 1-6 = A-F) and `mEq` an equipment-class code -
both inferred from values, confirm against `src/game/mission_util.cpp` before relying on them.
Index list: 0 NONE,
1 Orbital Satellite, 2 Manned Suborbital, 3 Unmanned Suborbital, 4 Manned Earth Orbital,
5 Unmanned Earth Orbital, 6 Manned Orbital EVA, 7 Lunar Flyby, 8 Lunar Probe Landing,
9-13 Venus/Mars/Mercury/Jupiter/Saturn Flyby, 14-41 docking/duration/orbiting-lab/LM-test
variants, 42-52 lunar pass/orbital/LM-test variants, 53 Historical Manned Lunar Landing,
54 Direct Ascent, 55 JT Landing EOR, 56 JT Landing LOR, 57 Soyuz Lunar Landing, 58-61 rescues.
Prerequisite relationships are not in `mission.json`; they are expressed by `downgrades.json`
(what a mission falls back to), `missSteps.json` (diagram) and the hardcoded milestone checks
(`src/game/prest.cpp:122 MilestonePenalty`).

#### Schema: rosters and news

```json
// roster.json  (top level is a 2-element list, one per player)
[{"player":0,"groups":[{"number_to_choose":7,"recruiting_delay":6,
   "entries":[{"name":"GRISSOM","sex":0,"race":0,"service":1,"capsule":3,"lunar":1,"eva":1,"docking":1,"endurance":1}, ...]}, ...]}, ...]
// crew.json  (flat, same people; Sex 1 = female, Service: 0 civilian/1-3 branch)
{"value0":[{"Name":"GRISSOM","Sex":0,"Race":0,"Service":1,"Cap":3,"LM":1,"EVA":1,"Docking":1,"Endurance":1}, ...]}
// event.json / news.json
{"us_event":[{"text":"PRESIDENT EISENHOWER ANNOUNCED ...","color":0}, ...], "sov_event":[...]}
{"astro_news":["xASTRONAUTS IN THE NEWS...x", ...], "us_reasons":[" FOR FAMILY REASONS.x", ...], "us_news":[...], ...}
// fails.json
{"value0":[{"MissionStep":"F102","percentage":2000,"code":4,"val":0,"xtra":0,"fail":97,
            "text":"MINOR PROBLEM WITH CABIN AIR RECIRCULATION SYSTEM. ... MISSION SCRUBBED."}, ...]}
```

Mood/`Happy`, `Compat`, `Hero`, medals etc. are runtime fields of the in-game `Astros` record
(`urast.json` -> `P.value0.Pool[65]`, 42 keys), not roster inputs. `doc/RosterChanges.txt`
documents every name change from the BARIS roster (typos, transliterations, added women).

### 1.2 Media assets (present in the clone)

| Directory | Files | Format | Contents |
|---|---|---|---|
| `data/images/` (root) | 148 | PNG (+1 BMP) | UI screens and button strips converted from BARIS `.but`/`.img` files: `main_menu.png`, `budget_*`, `moon.but.N`, `vab.img.0/1`, `liftoff.abz.*` (launch key-frames), `lenin.png`, `flag.*`, `preferences.png`, `error.png`, `moon_32x32.bmp` (window icon). |
| `data/images/faces/` | 97 | PNG | Astronaut portraits `faces.but.N.png`. |
| `data/images/patches/` | 110 | PNG | Mission patches. |
| `data/images/news/` | 230 | PNG | Newscast backdrops `news.cdr.{usa,ussr}.N.png` (decoded from `news.cdr`). |
| `data/images/liftoff/` | 328 | PNG | Launch animation frames `liftoff.<ID>.<frame>.png`, indexed by `liftoff.json`. |
| `data/images/port/` | 77 | PNG | Spaceport layers `usa_port.dat.N`, `sov_port.dat.N`, `flag.seq.N`. |
| `data/images/intel/`, `letter/`, `mhist/`, `rd/`, `presr/`, `portbut/`, `aprog/` | 62/65/23/41/18/18/14 | PNG | Screen-specific button and panel sprites (Intelligence, mail, museum history, R&D, review, port buttons, program badges). |
| `data/audio/sounds/` | 13 | OGG Vorbis | UI/ambient effects (`crane`, `crawler`, `gate`, ...). |
| `data/audio/mission/` | 171 | OGG Vorbis | Mission-control voice/sound clips `0agf_00.ogg` ..., referenced by `seq.json`/`fseq.json` `audio[]`. |
| `data/audio/news/` | 234 | OGG Vorbis | Newscaster voice-overs `sov_000`.., `usa_*`. |
| `data/video/mission/` | 537 | OGG Theora | Mission animation clips referenced by `seq.json`/`fseq.json` `video[]`. |
| `data/video/news/` | 12 | OGG Theora | Newscast opening/closing/angle loops per side. |
| `data/video/training/` | 10 | OGG Theora | Astronaut training clips. |
| `data/audio/music/` | **absent** | - | Must be copied from `raceintospace-nonfree` (`README.md` "Music", `Release.md`). |
| `icons/` | 14 | GIF/ICO/PNG/XPM/.desktop | Launcher icons (Gemini, Moon, Saturn V, Sputnik, Voskhod). |

No font files exist anywhere in the clone (`*.ttf/otf/fon/fnt` search is empty). The small
body-text font is a **vector stroke font hardcoded as line segments** in
`src/game/draw.cpp:332 draw_character` (one `case` per letter); the large heading font is the
bitmap data in `data/gamedata/letter.json` (and its PNG renders in `data/images/letter/`). A port
needs its own font, or must transcribe those strokes.

## 2. Licensing of `data/`

| Evidence | Says |
|---|---|
| `COPYING` (18 KB) | Verbatim GPL-2.0 text, no project-specific preamble and **no mention of data/assets**. |
| `README.md` "License" | "Race Into Space is distributed under GNU General Public License (GPL) version 2." Nothing distinguishes code from data. |
| `README.md` "Music", `Release.md`, `ChangeLog.md:73` | "Due to copyright concerns, the game's music has been placed in a nonfree repository" (`github.com/raceintospace/raceintospace-nonfree`, dir `data/audio/music`). Music is the **only** asset class upstream treats as non-free. |
| `AUTHORS`, `src/game/admin.cpp:1-24` | Code copyright "2005 Michael K. McCarty & Fritz Bronner"; headers still carry "Interplay's BUZZ ALDRIN's RACE into SPACE ... Copyright 1991 by Strategic Visions, Inc." as a historical note. |
| `contrib/fedora/raceintospace.spec:33` | `License: GPLv2+` for the whole package incl. the `-data` subpackage. |
| `doc/org.raceintospace.Raceintospace.metainfo.xml:11-12` | `<project_license>GPL-2.0+</project_license>`, `<metadata_license>CC0-1.0</metadata_license>`. |
| `contrib/flatpak/*.yml` | No licence statement. |
| `data/**` | No README, LICENSE or notice files at all. |

Practical reading: everything in `data/` (JSON tables, PNG art, OGG voice/video) is original
1993/1994 Interplay/Strategic Visions content that the authors re-released with the source and
that upstream distributes as GPL-2.0+; there is no separate asset licence and no CC/public-domain
grant. The music is the one class the upstream maintainers themselves withhold. Treat the numeric
tables as rules (facts) and the art, voice and video as GPL-2.0+-by-upstream-assertion with
unresolved Interplay provenance - fine for a hobby reimplementation, but do not relicense them.

## 3. `doc/` tree

| File | Format | Contents |
|---|---|---|
| `doc/manual/manual.md` | Markdown with embedded HTML tables | **Race Into Space Game Manual v2.0** by Leon Baradat, "Based on Buzz Aldrin's Race Into Space! Rules of Play by Fritz Bronner". 2,141 lines / 17,143 words / 18 HTML tables. |
| `doc/manual/image_*.png|jpg` (41) | PNG/JPG | Screenshots and hardware artwork referenced by the manual. |
| `doc/RosterChanges.txt` | text, 31 KB | Every change to the astronaut/cosmonaut roster since BARIS (typos, transliteration, misplacements, black astronauts, fictional and female additions). |
| `doc/dev/unorganized_notes.txt` | text, 4.5 KB | Developer notes: screen-to-function map of the engine (`Main menu -> game_main.cpp` ... `Mission control -> rush.cpp`), palette notes, code style. |
| `doc/org.raceintospace.Raceintospace.metainfo.xml` | AppStream XML | Package metadata, release 2.0 dated 2025-03-27. |
| `README.md`, `TESTING.md`, `Release.md`, `ChangeLog.md` (43 KB) | Markdown | Build/test/release docs; ChangeLog "Version 2.0" lists every rule tweak vs BARIS (worth reading before copying a number). |

### 3.1 `doc/manual/manual.md` heading outline (`##` level; `###` nested)

```
Introduction (###)
## Designer's Notes
## Multiplayer
## Lift Off!                      ### Advanced Preferences, Turn Announcement, Network News, Spaceports,
                                  Administration Building, Museum of Space History, Pentagon/KGB,
                                  Capitol/Politburo, VAB/VIB, Launch Pads A B C, Research & Development,
                                  Moon/Luna, Viewing Stand, Mission Control, Arlington/Kremlin Wall,
                                  The Flagpole, Basic Training, Astronaut Complex, Capsule/Shuttle
                                  Program, Hospital, Advanced Training, L.M. Program, Satellite Programs
## PRESTIGE
## MISSION MILESTONE STEPS        ### Orbital Satellite, Manned Suborbital, Manned Orbital, Lunar Flyby,
                                  Lunar Probe Landing, Manned Lunar Pass, Manned Lunar Orbital,
                                  Manned Lunar Landing
## Other Milestones ...           ### Photo Reconnaissance, Spacewalk, (Manned) Docking, Duration, LM Tests
## STRATEGY                       ### How I Won and Lost the Moon Race, Space Hardware and R&D, To the Moon
## REALISM
## MISSION DESCRIPTIONS
## APPENDIX A                     ### Getting Started
## APPENDIX B                     (Hardware artwork)
## APPENDIX C                     ### Quick Reference, LIFT CAPABILITIES AND PAYLOAD WEIGHTS
```

### 3.2 Numeric tables in the manual and what to cross-check them against

| Manual section (line) | Table | Cross-check |
|---|---|---|
| `## PRESTIGE` (552) | 28 rows x First/Second/Other/Failure | = `urast.json` `Prestige[].Add` exactly. 1993 text `rules-of-play-1993.txt:1215-1280` has the same table (OCR drops some digits: rows 11 and 14-16 blank). |
| `### Advanced Preferences` (124-176) | option list incl. `succesRDMax` | RIS-only; no 1993 equivalent. |
| `### Administration Building` (200-365) | 2 tables (budget/purchasing) | Compare with 1993 "Administration Building" text (`:395-415` for Max R&D definition). |
| `### Capsule/Shuttle Program` (493) | capsule crew/duration table | Duration caps vs `hist.json` `Duration` (XMS-2 = 15 days in data vs "max Duration D" in manual - verify). |
| `### DURATION` (810) | days -> level A-F -> prestige | Levels not in data; prestige per level matches `Prestige[8..12]`. 1993 manual gives per-capsule max durations in its hardware cards (`:1360-1385`). |
| `## MISSION DESCRIPTIONS` (912) | 62-row mission table | Names match `mission.json` exactly. |
| `### Quick Reference` (1346) | abbreviations, minimum rocketry | RIS heuristics; no data file. |
| `### LIFT CAPABILITIES ...` (1423) | 6 tables: US/USSR lift and weights, **Historical** and **Basic** "Hardware and R&D Costs" (Cost/Unit/R&D/Weight/Lift/MaxRD/MaxSafety) | Historical table = `hist.json` (verified row-by-row above). Basic table = `urast.json` `P.*` vectors. 1993 manual `:1285-1425` prints the **Basic** values as per-program cards ("This data is from the Basic Module"), e.g. Titan/Proton cost 60 R&D 4 lift 1500, Saturn/N-1 cost 84 R&D 6 lift 3200, Kicker-C cost 40. |
| `### Mission Control` (449) | rush cost 3 MB/3 % and 6 MB/6 % | Hardcoded (`src/game/rush.cpp`). |
| `### Advanced Training` (522) | 2 years, +2 skill, 3 MB | Hardcoded (`src/game/ast3.cpp`). |

Other reference texts already in this repo: `original/manuals/rules-of-play-1993.txt` (2,127
lines OCR, two-column artefacts), `cd-edition-manual.txt`, `players-reference-card.txt`.

## 4. Exact licence

`COPYING` is the unmodified FSF text beginning:

```
		    GNU GENERAL PUBLIC LICENSE
		       Version 2, June 1991
```

Of the 181 `.cpp/.h` files under `src/`, 64 carry a GPL notice and 63 of those use the
"or later" wording (e.g. `src/game/admin.cpp:1-7`):

```
    Copyright (C) 2005 Michael K. McCarty & Fritz Bronner

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.
```

So the project is **GPL-2.0-or-later** (the headers, `GPLv2+` in the Fedora spec and `GPL-2.0+`
in the AppStream file all agree); `README.md`'s "GPL version 2" is just shorthand. The single
exception is `src/game/valgrind.h` ("version 2. See ..."), a third-party header. This repo's own
`LICENSE` is byte-identical in size (17,987 B) to upstream `COPYING`.

## 5. Gaps: original rules that exist only in `src/`, not as data

Identified by file/grep only; algorithms are not summarised here.

| Rule | Where it lives | Note |
|---|---|---|
| Prestige row names | `src/game/endgame.cpp:50 PF[29][40]`, `src/game/museum.cpp:56 tame[29][40]`, enum `data.h:1105` | Values are data, labels are code. |
| Budget formula and cap | `src/game/game_main.cpp:738-746` (`Budget += Prestige`, cap 180), `src/game/budget.cpp:308`, `news_suq.cpp:95-115` (bands + `ntable.json`) | Difficulty-dependent adjustment is a TODO in code. |
| Difficulty effects | `Def.Lev1/Lev2` 0-2 (`data.h:139`), used in `aimast.cpp:69`, `mis_m.cpp:211`, `mc2.cpp:493`, `intel.cpp:1369`, `hardef.cpp:1594 CalcScore` | No difficulty table; branches on level. |
| Mission step roll / R&D roll | `src/game/game_main.cpp:1003 MisRandom()`, `src/game/rdplex.cpp`, `aipur.cpp:775` | Dice bands are in `fails.json` `percentage`; the roll itself is code. |
| Duration, milestone, new-mission and rush penalties | `src/game/prest.cpp:87 DurationPenalty`, `:122 MilestonePenalty`, `:164 NewMissionPenalty`, `:609 PrestNeg`; `src/game/rush.cpp`, `mc.cpp:288` | Percentages (e.g. 3 %/6 % rush) are literals. |
| Duration day bands A-F | manual `### DURATION` only; engine in `prest.cpp`/`mc.cpp` | No data file. |
| Failure severity / outcome mapping | `fails.json` `code`/`val`/`xtra` are data; their meaning is in `src/game/mc2.cpp`, `mis_m.cpp` | 24 distinct `code` values. |
| Hardware prerequisites, crew capacity, LM points | `src/game/ast4.cpp:58 crew_capacity_per_program[6] = {0,1,2,3,3,4}`, `hardware.cpp:181 RocketMaxRD`, `data.h LMpts` | |
| Random hardware model | `src/game/randomize.cpp` | Ranges described in its header comment. |
| Custom-roster stat generation | `src/game/roster_entry.cpp:63`, `ast1.cpp:530` | "more generous than historical". |
| Astronaut mood, compatibility, retirement, injury | `src/game/astros.cpp:118 Compatible`, `ast*.cpp` | Retirement *text* is in `news.json`. |
| AI purchasing and strategy | `src/game/aimast.cpp`, `aimis.cpp`, `aipur.cpp` | `AIStrategy[10]` zeroed in `urast.json`. |
| Calendar, month names, patch index | `mis_c.cpp:97 daysAMonth`, `newmis.cpp:45`, `rush.cpp:55`, `records.cpp:62 Pict[56]` | Trivial. |
| Mission step letter semantics (`Code`, `missSteps.json` tokens) | `src/game/mc.cpp`, `mc2.cpp`, `futbub.cpp` | Needed to interpret the data; test/game/mission_step_chain_test.cpp exercises it. |
