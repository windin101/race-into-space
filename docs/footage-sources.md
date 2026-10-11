# Archival footage for the mission vignettes

The original game's CD edition used archival NASA and Soviet film for its mission
sequences. We cannot take that from the game, but most of the US material is public
domain at the source, often in better quality than a 1994 CD-ROM, and there are lawful
routes to Soviet-era imagery. This note records what was checked on 2026-10-11, where the
files are, what resolution they come in, and the licence position, so clips can be
imported with `tools/footage_import.py` into `game/assets/art/vignettes/`.

Not legal advice. For a hobby, non-commercial project the position below is comfortable;
anything commercial needs the caveats at the end taken seriously.

## US side: NASA and the National Archives (public domain)

NASA's own works are not subject to copyright in the United States; the agency asks only
that it be credited and that its insignia not be used, and warns that third-party
material it hosts is marked as such ([NASA media guidelines](https://www.nasa.gov/nasa-brand-center/images-and-media)).

| source | what | resolution | how to get it |
|---|---|---|---|
| NASA Image and Video Library, `HD 049 Mercury_Gemini_Apollo_Resource Reel 1` | one-hour silent resource reel of Mercury, Gemini and Apollo footage, cut for reuse | 1280x720 | `https://images-api.nasa.gov/asset/<nasa_id>` lists `~orig.mp4`, `~large.mp4` and smaller renditions; no API key; search `media_type=video` for "Resource Reel" to find the sibling reels |
| National Archives series 255-FR "Moving Images Relating to Documentary Stock Footage, 1959-1996" | 630 digitised NASA stock films with shot lists | up to 1920x1080 | each item in the [National Archives Catalog](https://catalog.archives.gov/) has a Download button; mirrors on archive.org under `255-*` identifiers, e.g. [255-s-4655](https://archive.org/details/255-s-4655), the Apollo 11 launch and tracking at 1920x1080 (112 MB MP4) |
| archive.org, NASA/Johnson uploads | [Apollo 16mm launch views](https://archive.org/details/APOLLO16MMLAUNCHVIEWS) (Apollo 8, 11, 12, 14), [Apollo 11 16mm onboard film](https://archive.org/details/Apollo1116mmOnboardFilm), [Apollo 16 and 17 onboard film](https://archive.org/details/Apollo16And1716mmOnboardFilm), [Apollo onboard select views from HD transfers](https://archive.org/details/APOLLO_16MM_ONBOARD_SELECT_VIEWS) | 852x480 MP4 with larger MPEG masters (2.5 GB) on some items | direct download from the item page |
| archive.org, "Launch of the Saturn 5" [255-AD-15](https://archive.org/details/255-AD-15) | 16mm scan of a NASA edit from the National Archives | SD | direct download |
| NASA Apollo 50 resource list | pointers to the Image and Video Library, the Apollo Flight Journal video index, STI YouTube, and NARA's ongoing large-format digitisation (contact mopix@nara.gov) | varies | [PDF](https://www.nasa.gov/wp-content/uploads/static/apollo50th/img/Resources_Video_Film_Apollo_50.pdf) |

The resource reel alone covers most US vignette families: pad launches (Redstone, Atlas,
Titan, Saturn), capsule recovery and splashdown, Gemini EVA and docking, Apollo in lunar
orbit, LM descent and ascent, and the moonwalk.

## Soviet side

There is no Soviet equivalent of NASA's public-domain rule. The Russian state film
archive licenses its newsreels commercially and routes foreign requests through an
intermediary ([RGAKFD terms](https://abb.eastview.com/rep/B-11.tab4.php),
[Russian Archives Online](https://russianarchives.com/)); Russian copyright terms are
long and date-dependent ([Copyright law of the Russian Federation](https://en.wikipedia.org/wiki/Copyright_law_of_the_Russian_Federation)).
Three lawful routes exist:

| route | what | resolution | licence |
|---|---|---|---|
| Universal Newsreels, 1929-1967, donated to the public domain by Universal | Sputnik ([1957-10-07 "New Moon"](https://commons.wikimedia.org/wiki/File:1957-10-07_New_Moon.ogv)), Gagarin ([1961-04-19 first pictures](https://commons.wikimedia.org/wiki/File:1961-04-19_First_Pictures-Yuri_Gagarin-selection.ogv)), and the rest of the space race as the US newsreels showed it | 640x480 on Commons; NARA holds the masters | public domain (Commons tag PD-Universal Newsreel). Some reels incorporate Soviet-supplied footage, which the donation cannot cover; use the newsreel framing shots and the clearly American material freely, treat embedded Soviet film as a small residual risk |
| Roscosmos's own channel, mirrored on Commons under CC BY 3.0 | e.g. [Roscosmos "First Satellite" documentary](https://commons.wikimedia.org/wiki/File:Roscosmos_First_Satellite_documentary.ogv) with Sputnik-era archive film | 480x270 on Commons; higher on the channel | CC BY 3.0: attribute Roscosmos in the manifest and credits |
| Modern Soyuz launches filmed by NASA TV | e.g. [Soyuz TMA-11M launch](https://commons.wikimedia.org/wiki/File:Soyuz_TMA-11M_Launch.webm) and many more on Commons | 640x360 on Commons; NASA originals in HD via the images API | public domain (NASA). The Soyuz rocket is the R-7 family that launched Sputnik, Vostok and Voskhod, so a modern launch is a credible stand-in for every Soviet launch vignette |

What does not exist freely: Soviet onboard, EVA (Leonov), docking and Luna footage in
native quality. For those families the Soviet side keeps the procedural vignettes, or
uses the Universal Newsreel versions.

## Importing a clip

```
python3 -I tools/footage_import.py --src apollo11_launch.mp4 --family launch --outcome ok \
    --start 00:01:12 --duration 3 --fps 12 \
    --source-url https://archive.org/details/255-s-4655 --licence "Public domain (NASA/NARA)"
```

That writes `game/assets/art/vignettes/launch_ok/frame_0001.png` and following at
1920x1080 letterboxed, a `SOURCE.txt` beside them, and prints the line to paste into
`game/assets/MANIFEST.md`. The playback stage picks the frames up automatically
(`ArtAssets.vignette_frames`); nothing else changes. Keep clips to 2 to 4 seconds and
10 to 15 fps: 36 frames at 1080p is about 20 MB, and the player stretches the
sequence over the step's duration.

Failure variants: real failure footage is rare and grim; the procedural explosion overlay
stays for `_fail` sequences unless a suitable public-domain clip (e.g. an unmanned
Atlas or Vanguard failure from the NASA reels) is found.

## Caveats

- Credit NASA (and Roscosmos for CC BY material) in the credits screen and the manifest.
- Do not use NASA insignia or imply endorsement; this is a hobby project, so the
  commercial-use rules on identifiable people do not bite, but they would if that changed.
- Universal Newsreel reels that incorporate Soviet-supplied film carry residual risk;
  prefer shots that are plainly the newsreel's own.
- Nothing from the original game or its port is used, as before.

## Imported so far (2026-10-11)

| family | clip | source |
|---|---|---|
| launch | Apollo 11 liftoff from the pad, 4 s | NARA 255-S-4655 |
| insertion | Apollo 11 first-stage burn, tracking camera, 3 s | NARA 255-S-4655 |
| landing | Mercury capsule recovery, frogmen alongside, 4 s | NASA resource reel HD 049 at 29:20 |
| eva | Ed White's Gemini 4 spacewalk, 3.5 s | HD 049 at 31:48 |
| orbit | Gemini drifting over Earth, 3 s | HD 049 at 36:34 |
| docking | Agena target vehicle approach, 3 s | HD 049 at 40:10 |
| duration | Earth crescent past the S-IVB, 3 s | HD 049 at 50:44 |
| lm_ops | Apollo 9 lunar module free flight, 3 s | HD 049 at 57:40 |

All at 12 fps, lossy WebP, about 16 MB in total. Still procedural: power_on, reentry,
lunar_pass, lunar_eva, lm_descent, lm_landing, lm_liftoff, lm_test, photo, planetary,
and every failure variant. Reel 1 ends at Apollo 9; the Apollo 11 lunar surface and
descent footage is on archive.org (`Apollo1116mmOnboardFilm`) and in NASA's other
resource reels, which is the next pull. The 4:3 film is pillarboxed in the 16:9 stage;
`footage_import.py` could gain a crop option if the bars annoy.

Workflow that worked: download once into `reference/footage/` (gitignored), run
`tools/footage_sheet.py --every 20` for an overview, then `--every 2` around a window,
then `footage_import.py` with the chosen in-point.
