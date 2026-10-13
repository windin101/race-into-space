# Asset manifest

Every file under `game/assets/` with its origin and licence. Procedural art (spaceports,
hardware, portraits, vignettes) is code, not files, and is covered by the project licence.

| path | what | origin | licence |
|---|---|---|---|
| fonts/SourceSans3-Regular.otf | body font | Adobe Source Sans 3 | SIL OFL 1.1 (fonts/OFL-SourceSans3.txt) |
| fonts/SourceSans3-Semibold.otf | body font, semibold | Adobe Source Sans 3 | SIL OFL 1.1 |
| fonts/SourceSans3-Bold.otf | body font, bold | Adobe Source Sans 3 | SIL OFL 1.1 |
| fonts/Oswald-Variable.ttf | heading font | Oswald (Vernon Adams et al., Google Fonts) | SIL OFL 1.1 (fonts/OFL-Oswald.txt) |
| fonts/RISLabel-Regular.ttf | wide label font | modified from Michroma (The Michroma Project Authors, Google Fonts): renamed, percent glyphs removed | SIL OFL 1.1 (fonts/OFL-Michroma.txt) |
| audio/music/title_theme.ogg | title and end-game music, 48 s loop | synthesised by tools/gen_audio.py | CC0 |
| audio/music/spaceport_day.ogg | spaceport ambience, 60 s loop | synthesised by tools/gen_audio.py | CC0 |
| audio/music/mission.ogg | mission playback music, 40 s loop | synthesised by tools/gen_audio.py | CC0 |
| audio/sfx/click.ogg | screen open | synthesised | CC0 |
| audio/sfx/back.ogg | screen close | synthesised | CC0 |
| audio/sfx/confirm.ogg | confirmation | synthesised | CC0 |
| audio/sfx/flag.ogg | end of season | synthesised | CC0 |
| audio/sfx/launch.ogg | launch rumble | synthesised | CC0 |
| audio/sfx/explosion.ogg | step failure | synthesised | CC0 |
| audio/sfx/success.ogg | mission accomplished | synthesised | CC0 |
| audio/sfx/failure.ogg | mission failed | synthesised | CC0 |
| audio/sfx/first.ogg | prestige first fanfare | synthesised | CC0 |
| audio/sfx/newscast.ogg | newscast sting | synthesised | CC0 |

Vignette frame sequences are imported with `python3 -I tools/footage_import.py`; each folder
also carries a `SOURCE.txt` with the clip, timecode and licence.

Regenerate the audio with `python3 -I tools/gen_audio.py --out game/assets/audio`.
`test_assets.gd` fails if a file under `assets/` is missing from this table.
| art/portraits/*.png | 230 astronaut and cosmonaut portraits, 336x400 | Qwen-Image (Apache 2.0) text-to-image via tools/comfy_batch.py from reference/art_source/portrait_features.json; seed = crc32(name), IVANOVA and PONOMARYOVA +1; plus five fictional figures (President, Vice President, General Secretary +1, Politburo, the news anchor), seed = crc32(figure/name) | CC0 (AI output) |
| art/hardware/usa/*.png | US hardware icons, 512x512, green-screen keyed to alpha | Qwen-Image (Apache 2.0) text-to-image via tools/comfy_batch.py from the descriptions in tools/comfy_style.json; seed = crc32(side/group_slot), Ranger, Titan and Eagle +1, Saturn and Kicker-B +2 | CC0 (AI output) |
| art/hardware/ussr/*.png | Soviet hardware icons, 512x512, green-screen keyed to alpha | Qwen-Image (Apache 2.0) text-to-image via tools/comfy_batch.py from the descriptions in tools/comfy_style.json; seed = crc32(side/group_slot), Luna and UR-700 +1, Kicker-A +3 | CC0 (AI output) |
| art/backdrops/*.png | title, newscast and end-game backdrops, 1920x1080 | Qwen-Image (Apache 2.0) text-to-image via tools/comfy_batch.py; seed = crc32(name), newscast_ussr +2, mission_control_usa +1, title +20 (visor repainted gold by hand) | CC0 (AI output) |
| art/spaceport/usa/*.png | Cape Canaveral: two season backgrounds (1920x1080) and green-screen cutouts for each building, plot, pad state and flag | Qwen-Image (Apache 2.0) text-to-image via tools/comfy_batch.py from tools/comfy_style.json; seed = crc32(side/layer), flag +1 | CC0 (AI output) |
| art/spaceport/ussr/*.png | Baikonur: the same layer set | Qwen-Image (Apache 2.0) text-to-image via tools/comfy_batch.py; seed = crc32(side/layer) | CC0 (AI output) |
| art/icons/budget.svg, hardware.svg, future.svg, recruiting.svg, preferences.svg | Administration menu glyphs, 64x64 | hand-drawn for this project | GPL-2.0-or-later (project) |
| art/icons/flag_usa.svg, flag_ussr.svg | simplified national flags, 76x40 | hand-drawn for this project | GPL-2.0-or-later (project) |
| art/icons/*.png | fictional programme and agency emblems, app icon, 512x512 | Qwen-Image (Apache 2.0) text-to-image via tools/comfy_batch.py icons; seed = crc32(name) | CC0 (AI output) |
| art/patches/usa/*.png | one 256x256 mission patch per mission, US colours | Qwen-Image (Apache 2.0) via tools/comfy_batch.py patches, motif from the mission name; seed = crc32(patch/side/index), missions 3, 9, 55, 60, 61 +1 | CC0 (AI output) |
| art/patches/ussr/*.png | the same in Soviet colours | as above, missions 8, 10, 11, 31, 54, 57, 61 +1 | CC0 (AI output) |
| art/vignettes/*/frame_*.webp | animated mission vignettes, every step family and outcome, 60 frames at 1920x1080 | Qwen-Image keyframe animated by Wan 2.2 image-to-video (both Apache 2.0) via tools/comfy_video.py; seed = crc32(vignette/<family>_<outcome>); each folder's SOURCE.txt holds the prompts | CC0 (AI output) |
