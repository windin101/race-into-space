# UI style guide

What every Race Into Space screen should look and behave like. Written 2026-10-13 after
studying *Buzz Aldrin's Space Program Manager* (Polar Motion / Slitherine, 2014), the
closest modern relative of what we are building, alongside the 1993 original whose
screen structures `screen-style.md` already records.

This guide takes **principles** from that study. It does not take assets, logos, fonts,
icons, photographs, text or exact layouts from either game. Where SPM did something well,
the rule below says what the idea is and how we do it with our own art; where it did
something badly (the critiques are well documented), the rule says what to do instead.
`screen-style.md` stays the per-screen reference for structure; this guide governs the
frame, the components and the visual language around it.

---

## 1. What we learned

Twenty official screenshots, the developers' design notes and player and press reviews
were studied. Seven ideas carry the game:

1. **The frame never moves.** Every screen keeps a thin top bar (where am I, prestige,
   date) and a bottom resource bar (money with its per-season change, staff and facility
   counts, one context action at the right). Players always know the state of the race.
2. **One tinted photograph per place.** Each screen sits on a full-bleed, single-hue
   archival image of the room it represents (a control room, a boardroom), faded behind
   translucent panels. The place is felt without being in the way.
3. **Panels have one anatomy.** Rounded translucent panel, a dark title strip in spaced
   small capitals, content, and an optional full-width action bar along the bottom edge.
   Panels nest one level deep at most.
4. **Colour means one thing.** Green bar: go, proceed, launch. Yellow bar: the secondary
   or cautious choice (scrub, schedule). Red bar: unavailable or failed, with a reason.
   Lamps follow the same three: nominal, warning, failure.
5. **The hardware is the hero.** Program and component screens lead with a large render
   of the object, its name on a strip beneath with arrows to cycle, and an info badge in
   the corner. Results screens show the object in three orthographic views like a
   technical drawing, with a reliability history chart and a gauge.
6. **Mission control is a wall of monitors.** The main viewport, an orbit diagram with
   numbered step nodes, a camera feed of the room, a vertical reliability gauge, the
   controller and crew rosters as lamp columns, and a status block of three lamps.
7. **Story beats are cards.** Historic moments arrive as a large tinted picture card
   with a title banner, the agency emblem, a paragraph and a Proceed bar, tinted to the
   side (blue for one agency, red for the other).

And six things that players and reviewers said did not work, which we must avoid:

1. **Too deep.** Reaching research took six levels (headquarters, location, category,
   programme, mission, configuration). Simple jobs needed many clicks.
2. **The way back was unclear.** Players got lost between screens, and there was no
   right-click or keyboard back.
3. **Key numbers were hidden** behind info icons or a second screen (controller
   requirements, crew counts, per-component reliability).
4. **Lists could not be sorted** by the thing that mattered (technicians by skill,
   projects by readiness) and staff could not be assigned from the list showing them.
5. **Text was tiny and low contrast**: light-blue labels on light-blue panels, dense
   spec tables in small type.
6. **Pacing**: the launch sequence switched stages too quickly to follow.

---

## 2. Our frame

Every screen except the title and full-screen playback uses this frame. It replaces the
current `ScreenPanel` header line.

```
┌─ TOP BAR (48 px) ───────────────────────────────────────────────────────────┐
│ ◀  ADMINISTRATION › HARDWARE PURCHASE                     ★ 42    SPRING 1961 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│                       screen content on its backdrop                         │
│                                                                              │
├─ BOTTOM BAR (56 px) ────────────────────────────────────────────────────────┤
│ MB 102 (+18)   PADS 2/3   CREWS 4/7   TEAMS 3   NEXT REVIEW: FALL   [ACTION] │
└─────────────────────────────────────────────────────────────────────────────┘
```

- **Top bar left**: a back arrow, then a breadcrumb of at most two levels in spaced
  capitals. Each breadcrumb segment is clickable.
- **Top bar right**: prestige (star glyph, gold) and the date. Rival prestige in the
  rival's accent beside it only on screens about the race (Museum, Budget, Intelligence).
- **Bottom bar**: icon-and-number chips. Money shows the per-season change in green or
  red after it. Counts read `used/total`. Chips are tooltipped and clickable: each opens
  the screen that manages it.
- **Bottom bar right**: exactly one context action, the most likely next step: `End
  season` on the spaceport, `Back to spaceport` elsewhere, `Proceed` on turn screens.
- **Back is everywhere**: the arrow, `Esc`, right-click on empty space, and the mouse back
  button all go back one screen. No screen is more than three steps from the spaceport.

## 3. Backdrops

- Every place has a painted backdrop in the house style, shown **monotone**: desaturate,
  then tint toward the screen's hue at about 65 % strength, then darken to 45-55 %
  brightness so panels read. One hue per side: our navy for the United States, a deep
  oxblood for the Soviet Union. Implement as a shader on the backdrop `TextureRect`, so the
  same painting serves both tints.
- Offices (Administration, Purchase, Research, Programs, Budget) get a quiet room painting;
  stage-like screens (playback, newscast, review, end game) get their full-colour painting
  as now.
- Backdrops never carry information. Nothing in a painting needs to line up with a control.

## 4. Panels

```
╭─ HARDWARE ─────────────────────────────────── (i) ╮   ← title strip
│                                                    │
│   content                                          │   ← panel body
│                                                    │
╞════════════════════════════════════════════════════╡
│               PURCHASE PROGRAM  (24 MB)            │   ← action bar
╰────────────────────────────────────────────────────╯
```

- **Body**: `UiPalette.PANEL` at 82 % opacity over the backdrop, radius 10, 1 px border in
  `BORDER_SOFT`.
- **Title strip**: 30 px, a darker fill (`PANEL_SUNKEN`), the title in spaced capitals at
  `SIZE_SMALL` + 1 in `TEXT_DIM`, an optional `(i)` help badge at the right that opens the
  manual entry (our existing `UiHelp` codes).
- **Action bar**: full width, 44 px, flush with the panel's bottom edge, label in spaced
  capitals. Two actions split the bar 50/50. Colour rules in section 6.
- **Nesting**: a panel may hold sub-panels; sub-panels may not hold panels. Prefer a
  divider line to a third level.
- **Banner** (from `screen-style.md`): the gold capitals heading stays for the one most
  important subject on a screen (`LAUNCH FACILITY: A`, `NAME: GRISSOM`). Panel titles are
  quieter. One banner per screen region.

## 5. Typography

| use | face | size at 1080p | case |
|---|---|---|---|
| banners | Oswald | 30 (`SIZE_HEADING`) | capitals |
| panel titles, bar labels, button labels, lamp labels | a wide face, Michroma (OFL) planned | 15-16, tracking +8 % | capitals |
| body, table cells | Source Sans 3 | 18 (`SIZE_BODY`) | sentence |
| small print, legends | Source Sans 3 | 15 (`SIZE_SMALL`), never smaller | sentence |
| readouts (gauges, money, reliability) | Source Sans 3 Semibold, tabular figures | 22 | numbers |

- **Nothing below 15 px** at 1080p, including tooltips and table headers.
- **Contrast**: body text at least 7:1 against its panel, small print at least 4.5:1.
  Never set light-blue text on a light-blue panel; dim text uses `TEXT_DIM` on the dark
  panel colours only.
- The wide label face is the one new font. Until it is added, labels use Source Sans 3
  Semibold in capitals with tracking.

## 6. Colour meaning

| colour | buttons and bars | lamps | text |
|---|---|---|---|
| green `OK` | proceed, launch, recruit, research | nominal, assigned, ready | success, positive change |
| amber `WARN` | secondary or cautious action: scrub, schedule, downgrade | warning, partial | caution, rushed, low mood |
| red `DANGER` | unavailable: the label says why ("Unavailable: no capsule") and the bar opens the reason | failure, damaged | failure, deaths, negative change |
| gold `GOLD` | none | none | banners, prestige, firsts |
| side accent | the selected tab, the selected row, the side's emblem | none | the side's name |
| grey | disabled control (with a tooltip saying why) | off, unassigned | muted |

A red action bar is never just disabled: it states the reason in its label, and clicking
it explains in full. This replaces greyed-out buttons that leave the player guessing.

## 7. Components

**Viewer.** A large subject (hardware render, portrait, patch) on `CASE_BG` with the soft
spotlight; a name strip across its foot with `◀ ▶` at either end; an `(i)` badge top
right; an optional status band. Our Research, Purchase and Intelligence cases already
follow this; add the name strip overlaid on the case instead of beneath it.

**Card row.** For lists of choices (missions, programmes, candidates): a thumbnail on the
left, a title strip in spaced capitals, and beneath it a row of **stat chips**: an icon
and a number each, for the things the player chooses on (crew seats, controllers or
teams needed, payload weight, safety, cost, seasons). Rule from the critique: if a number
decides the choice, it is on the card, not behind `(i)`.

**Stat chip.** A 24 px icon (our SVG set, monochrome, tinted) and a value, 8 px apart, on
a sunken pill. Tooltip names the quantity. Red value when it blocks the choice.

**Lamp column.** For rosters that are either assigned or not (crew seats, step lights,
teams): a column of pill buttons labelled in spaced capitals, lit green when assigned,
dark when empty, amber when the person is weak for the role. Clicking a lamp assigns or
releases.

**Status lamps.** Three stacked lamps, Nominal / Warning / Failure, only one lit. Used on
the playback screen and on any screen that judges readiness (VAB, Mission Control).

**Gauge.** A vertical or horizontal bar with ticks every 10 %, the current value as a
needle and a readout box. Reliability and safety use it; colour follows
`UiPalette.safety_color`.

**History chart.** A bar per season along a time axis, for reliability, prestige and
review index. One colour per series, side-accented.

**Story card.** Centred, 900 x 560, the illustration filling the top two-thirds (tinted
to the side), a title banner in capitals across its top with the side emblem at the
right, a short paragraph, a Proceed bar. Used for newscast events, firsts, reviews and
programme unlocks. Never more than one card at a time; queue them.

## 8. Layout grid

- 1920 x 1080 logical canvas, 24 px outer margin, 16 px gutters, 12 columns.
- Typical splits: viewer 5 columns + details 7; list 4 + detail 5 + actions 3.
- Panels align to the grid; nothing floats.
- Wide screens extend the backdrop and the outer columns, never the reading width of text
  (body text lines at most 90 characters).

## 9. Interaction rules

1. **Three clicks to anything** from the spaceport. A screen that needs a fourth level
   gets a tab instead.
2. **Act where you look.** If a list shows people or programmes, the actions on them are
   on that screen (assign, train, research, buy), not one screen away.
3. **Every list sorts** by any column, and remembers its sort per screen.
4. **Every control has a tooltip**, and every disabled control's tooltip says why.
5. **Keyboard**: arrows move in lists and viewers, `Enter` takes the green action, `Esc`
   goes back, `Tab` moves between panels, `F1` opens the help for the focused panel.
6. **Pacing**: mission playback holds each step for at least 1.6 s at speed 1, the step
   name stays up for the whole step, and the player can pause. Speed settings scale from
   there.
7. **No modal stacks.** One dialog or story card at a time.

## 10. Mission playback (the control room)

Our control room screen already has the monitor wall. Bring it in line with sections 6
and 7:

- Left column: the **controller lamp column** (roles lit for the active step).
- Right column: **flight crew lamps** with portrait tiles, then the three **status lamps**.
- Main viewport: the vignette, with the step name as a caption strip along its top.
- Beside it: a vertical **reliability gauge** for the current step's hardware.
- Lower monitors: the **trajectory diagram** (numbered nodes on the path, reusing the
  Future Missions diagram) and a camera feed of the painted room.
- Side emblem top right.

## 11. What we do not take

- No NASA insignia or Soviet state emblems drawn from real sources: our emblems are the
  fictional ones already generated. The flags are our own SVGs.
- No archival photographs of real people. Our story cards use our paintings, and real
  historical figures are not depicted.
- No SPM fonts, icons, colours as a set, renders, text or Buzz-opedia content.
- No copying of an SPM screen's arrangement. Where our layouts resemble the 1993
  original, `screen-style.md` already records that lineage.

## 12. Gap list: our screens against this guide

| area | now | to do |
|---|---|---|
| frame | header with status text; no bottom bar | top bar with breadcrumb, prestige, date; bottom resource bar with clickable chips and one context action |
| backdrops | flat panel colour on offices | monotone tinted room paintings per office, shader-based |
| panels | plain cards; gold banners | title strips with `(i)`, full-width action bars |
| typography | Oswald and Source Sans | add the wide label face; enforce 15 px floor |
| colour | green/red used; amber rarely | amber for secondary actions; red bars that explain |
| cards | DataTable rows for missions and candidates | card rows with stat chips where a choice is made |
| lamps | step lights on playback only | lamp columns for crew seats and controllers |
| playback | monitor wall | controller and crew lamps, status lamps, gauge, numbered trajectory |
| navigation | back button and Esc | breadcrumb, right-click and mouse-back, three-click rule audit |
| story cards | newscast panel | event, first and unlock cards with the side tint |

## Sources

- Store page and twenty official screenshots: [Steam, app 308270](https://store.steampowered.com/app/308270), [GOG](https://www.gog.com/en/game/buzz_aldrins_space_program_manager)
- Developers' design notes on the mission screens: [Slitherine forum](https://forum.slitherine.com/viewtopic.php?p=426060), [early post](https://forum.slitherine.com/viewtopic.php?p=422663)
- Player critique of the interface: ["Fun game, poor interface", Slitherine forum](https://forum.slitherine.com/viewtopic.php?p=503922)
- Press: [HistoryNet review](https://www.historynet.com/review-buzz-aldrins-space-program-manager/), [Space Sector beta impressions](https://www.spacesector.com/blog/2013/11/buzz-aldrins-space-program-manager-beta-first-impressions/), [RAWG reviews](https://rawg.io/games/buzz-aldrins-space-program-manager/reviews)

The screenshots were studied locally and are not stored in this repository.
