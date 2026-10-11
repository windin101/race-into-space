# Race Into Space

A cleanroom reimplementation of the 1993 DOS strategy game *Buzz Aldrin's Race Into Space*
(Interplay / Strategic Visions).

## Cleanroom policy

This project is written from scratch. To keep it that way:

- **No code** from the original game, from the 2005 GPL source release (`raceintospace`), or
  from any derivative port is copied, translated, or consulted while writing code here.
- **No original assets** (graphics, music, sound, text, data files) are included or depended on.
  Everything in `assets/` is newly created or clearly licensed for reuse.
- Design knowledge comes from **behavioural observation and public documentation only**:
  the manual, play-testing the original, published strategy guides, and historical sources
  on the US and Soviet space programmes.
- Findings from observation are written up as specifications in `docs/` *before* being
  implemented, so the spec is the thing that is built from, not the original.

If you have read the original source, do not contribute code to this repository.

## Layout

```
docs/      Game design specs derived from observation and documentation
src/       Engine and game code
assets/    Original (new) art, audio, and data
tools/     Build and development helpers
```

## Status

Day zero. Nothing runs yet.
