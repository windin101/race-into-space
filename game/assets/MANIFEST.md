# Asset manifest

Every file under `game/assets/` with its origin and licence. Procedural art (spaceports,
hardware, portraits, vignettes) is code, not files, and is covered by the project licence.

| path | what | origin | licence |
|---|---|---|---|
| fonts/SourceSans3-Regular.otf | body font | Adobe Source Sans 3 | SIL OFL 1.1 (fonts/OFL-SourceSans3.txt) |
| fonts/SourceSans3-Semibold.otf | body font, semibold | Adobe Source Sans 3 | SIL OFL 1.1 |
| fonts/SourceSans3-Bold.otf | body font, bold | Adobe Source Sans 3 | SIL OFL 1.1 |
| fonts/Oswald-Variable.ttf | heading font | Oswald (Vernon Adams et al., Google Fonts) | SIL OFL 1.1 (fonts/OFL-Oswald.txt) |
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
| art/vignettes/launch_ok/frame_*.webp | launch vignette (ok), 48 frames | https://archive.org/details/255-s-4655 | Public domain (NASA/NARA 255-S-4655) |
| art/vignettes/insertion_ok/frame_*.webp | insertion vignette (ok), 36 frames | https://archive.org/details/255-s-4655 | Public domain (NASA/NARA 255-S-4655) |
| art/vignettes/landing_ok/frame_*.webp | landing vignette (ok), 48 frames | https://images.nasa.gov/details/HD%20049%20Mercury_Gemini_Apollo_Resource%20Reel%201 | Public domain (NASA resource reel HD 049) |
| art/vignettes/eva_ok/frame_*.webp | eva vignette (ok), 42 frames | https://images.nasa.gov/details/HD%20049%20Mercury_Gemini_Apollo_Resource%20Reel%201 | Public domain (NASA resource reel HD 049) |
| art/vignettes/orbit_ok/frame_*.webp | orbit vignette (ok), 36 frames | https://images.nasa.gov/details/HD%20049%20Mercury_Gemini_Apollo_Resource%20Reel%201 | Public domain (NASA resource reel HD 049) |
| art/vignettes/docking_ok/frame_*.webp | docking vignette (ok), 36 frames | https://images.nasa.gov/details/HD%20049%20Mercury_Gemini_Apollo_Resource%20Reel%201 | Public domain (NASA resource reel HD 049) |
| art/vignettes/duration_ok/frame_*.webp | duration vignette (ok), 36 frames | https://images.nasa.gov/details/HD%20049%20Mercury_Gemini_Apollo_Resource%20Reel%201 | Public domain (NASA resource reel HD 049) |
| art/vignettes/lm_ops_ok/frame_*.webp | lm_ops vignette (ok), 36 frames | https://images.nasa.gov/details/HD%20049%20Mercury_Gemini_Apollo_Resource%20Reel%201 | Public domain (NASA resource reel HD 049) |
| art/portraits/*.png | 230 astronaut and cosmonaut portraits, 336x400 | Qwen-Image (Apache 2.0) text-to-image via tools/comfy_batch.py from reference/art_source/portrait_features.json; seed = crc32(name), IVANOVA and PONOMARYOVA +1 | CC0 (AI output) |
| art/hardware/usa/*.png | US hardware icons, 512x512, green-screen keyed to alpha | Qwen-Image (Apache 2.0) text-to-image via tools/comfy_batch.py from the descriptions in tools/comfy_style.json; seed = crc32(side/group_slot), Ranger, Titan and Eagle +1, Saturn and Kicker-B +2 | CC0 (AI output) |
| art/hardware/ussr/*.png | Soviet hardware icons, 512x512, green-screen keyed to alpha | Qwen-Image (Apache 2.0) text-to-image via tools/comfy_batch.py from the descriptions in tools/comfy_style.json; seed = crc32(side/group_slot), Luna and UR-700 +1, Kicker-A +3 | CC0 (AI output) |
| art/backdrops/*.png | title, newscast and end-game backdrops, 1920x1080 | Qwen-Image (Apache 2.0) text-to-image via tools/comfy_batch.py; seed = crc32(name), newscast_ussr +2 | CC0 (AI output) |
| art/spaceport/usa/*.png | Cape Canaveral: two season backgrounds (1920x1080) and green-screen cutouts for each building, plot, pad state and flag | Qwen-Image (Apache 2.0) text-to-image via tools/comfy_batch.py from tools/comfy_style.json; seed = crc32(side/layer), flag +1 | CC0 (AI output) |
| art/spaceport/ussr/*.png | Baikonur: the same layer set | Qwen-Image (Apache 2.0) text-to-image via tools/comfy_batch.py; seed = crc32(side/layer) | CC0 (AI output) |
