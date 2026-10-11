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

Regenerate the audio with `python3 -I tools/gen_audio.py --out game/assets/audio`.
`test_assets.gd` fails if a file under `assets/` is missing from this table.
