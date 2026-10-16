# Mission vignettes: rework plan (audit 2026-10-16)

## What is there now

36 clips under `game/assets/art/vignettes/<family>_<ok|fail>/` (60 WebP frames each,
12 fps, 5 s), made on 2026-10-13 by `tools/comfy_video.py`: a Qwen-Image keyframe from a
one-line scene prompt in `tools/comfy_style.json` ("vignettes.scenes"), animated by Wan 2.2.
The playback stage (`scripts/playback/vignettes.gd`) picks `family_for(step letter)` and the
outcome, and plays whatever is in that folder. The procedural vector painters in the same
file remain as the fallback when a folder is empty.

Three structural problems, before any individual clip is judged:

1. **One clip per family for all three sides.** The step letter and outcome are the only
   inputs; the vehicle flown and the side are not. A Soviet Vostok re-entry, a Commonwealth
   Highlander re-entry and a Mercury re-entry all play the same clip.
2. **The vehicles in the clips predate the hardware set.** They were prompted as "a
   cone-shaped capsule", "a tall white rocket", "a four-legged lander", so Qwen drew its
   generic idea of each: the pill/pharmaceutical-capsule shapes the player objects to,
   Shuttle-ish rockets, Lego-brick landers. None resembles the icons now in
   `art/hardware/`.
3. **Several clips do not depict the step.** Listed below.

## Clip-by-clip audit (middle frame of each)

| family | ok | fail | verdict |
|---|---|---|---|
| launch | rocket on a pad at dawn, plausible | fireball on the pad, good | keep the composition; vehicle is generic, not the flown rocket |
| insertion | cartoon finned rocket (red fins) climbing over Earth | the same rocket breaking up | **wrong vehicle**: staging should show the real upper stage separating |
| power_on | satellite with a panel and vapour over Earth | similar, vapour plume | acceptable; satellite generic |
| reentry | a smooth pill-shaped capsule, nose-first, no heat shield | a pill capsule with flames | **worst offender**: capsule is the wrong shape and enters nose-first; must be blunt-end-first with the shield glowing |
| landing | capsule under three red/white chutes, ship nearby | chutes streaming | composition good; capsule is a pill |
| orbit | pill capsule with a drum module, Earth | Gemini-ish capsule with a plume | generic |
| lunar_pass | tiny finned rocket by the Moon | the same | **wrong vehicle**: a CSM/Soyuz-type craft, not a finned rocket |
| eva | astronaut on a tether, Earth | astronaut at a hatch | good, keep; capsule behind is generic |
| lunar_eva | astronaut, flag, lander, Earth in the sky | astronaut stumbling by a rover | ok has a **rover** that no 1960s mission in the game carries; fail likewise |
| docking | capsule nose to nose with a target drum | too-fast approach, bullseye on the target | the target has a literal red-and-white **bullseye**; capsule generic |
| lm_ops | lander separating from a CSM over the Moon | lander with a bent leg | fair; vehicles generic |
| lm_descent | lander on a flame over the Moon | tilted lander | fair |
| lm_landing | lander touching down, dust | crumpled lander in a dust cloud | fair |
| lm_liftoff | ascent stage rising, flag | weak flame | ok shows the **whole lander lifting off** rather than the ascent stage leaving the descent stage |
| lm_test | lander firing in Earth orbit | ragged flame | fair |
| photo | satellite with a lens over a coast | jammed door | fair |
| planetary | probe with a dish past a planet | drifting probe | fair |
| duration | capsule and module over the terminator | frost and a red glow inside | the fail frame shows a **warning triangle icon** and a see-through hull: not in style |

## What needs doing

### A. Make the clips vehicle- and side-aware (code)

- Extend `ArtAssets.vignette_frames(family, ok)` to try, in order:
  `vignettes/<family>_<ok|fail>/<side>/<hardware>/`, then `<side>/`, then the family folder.
  `Vignettes.paint` already receives `ctx.hardware` and the side colour; pass the side id too.
- The playback stage already resolves the flown hardware per step (`_prepare_feeds`); the
  same lookup feeds the folder choice.
- Keep the generic clip as the fallback so nothing goes blank while the set is filled in.

### B. Regenerate the keyframes from the hardware icons (art)

The seeded method that fixed the icons applies here: give the edit model the icon of the
vehicle actually flown as the image reference and ask for the scene around it, so the
capsule in the re-entry clip *is* the Mercury/Vostok/Spriteship icon. Then animate the
keyframe with Wan as before. Per family the keyframe needs the right vehicle class:

| family | vehicle shown | variants needed |
|---|---|---|
| launch, insertion | the rocket (and boosters) | 5 rockets x 3 sides = 15 per outcome |
| reentry, landing, orbit, duration, lunar_pass, eva, docking, power_on | the capsule or probe | 7 manned + 3 probe per side |
| lm_ops, lm_descent, lm_landing, lm_liftoff, lm_test, lunar_eva | the lander (slots 4-6) + the CSM-type capsule | 3 landers per side |
| photo | photo-recon satellite | 1 per side |
| planetary | probe | 3 per side |

That is roughly 36 families x outcomes x (up to 7 vehicles) x 3 sides: too many to hand
pick one by one. Proposed cut: generate per **vehicle class** rather than per slot where the
silhouette is shared (the three Commonwealth/US/Soviet landers differ little in a wide
shot), and prioritise the families the player sees most: launch, insertion, orbit,
reentry, landing, docking, lm_descent, lm_landing, lunar_eva. Fill the rest from the
generic clip until done.

### C. Fix the clips that are wrong regardless of vehicle (prompts)

- reentry: blunt end first, heat shield glowing, no nose-first entry.
- lunar_eva: no rover; astronaut, flag and the lander only.
- docking fail: no bullseye on the target.
- lm_liftoff ok: ascent stage leaves the descent stage on the surface.
- duration fail: no warning-triangle icon, no x-ray hull.
- insertion, lunar_pass: no cartoon fins.

### D. Side flavour

- Soviet clips: R-7 tulip at launch, sphere-capsule re-entry (Vostok lands by parachute on
  land, not at sea: the **landing** family needs a steppe variant), LK-type lander.
- Commonwealth: Blue Streak/Black Arrow launches, RAF roundel capsules, Woomera red desert
  at launch and recovery on land (Woomera range) or sea.
- US: as now, with the real vehicles.

### E. Housekeeping

- `tools/comfy_video.py`: add `--side`, `--hardware`, and a keyframe mode that seeds from
  the hardware icon (reuse the edit graph from `tools/art_source/hardware_seeded.py`).
- `MANIFEST.md` rows per folder; `docs/footage-sources.md` note that the vehicle-specific
  set supersedes the generic one.
- Tests: `test_assets.gd` manifest coverage picks the new folders up via wildcard rows.

## Order of work

1. Code (A) with the generic fallback: half a day, no visual change until clips exist.
2. Keyframe pipeline (E) and the prompt fixes (C): generate the US re-entry/landing/orbit
   set for Mercury and Apollo as the proof, review, then run the priority families for all
   three sides.
3. Backfill the lunar families and side-flavoured landings.
