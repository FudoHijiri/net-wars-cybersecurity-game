# NET WARS: looping music plan

Source: `D:\Art\Game Assets\Looping Music` (Abstraction by Benjamin Burnes, CC0, credit optional). All files are OGG loops, so they repeat without a gap in Godot.
This is a plan only. Nothing is copied or coded yet.

Track names below are the file names in the library (`Sketchbook ...` = the Sketchbook series, `Week N - ...` = the weekly series). Energy (E1-E5) comes from the library's own rating.

## Principles

- Quiet music for reading scenes (Dialogue, Investigation, Archive). Typing and click sounds stay clear.
- Energy rises with the phases: Hardening calm, Monitoring tense, Response loud, Recovery calm again.
- One track per scene, not per day, so the player learns the sound of each phase. Only Response and the ending change over the days.
- Music sits at about -12 dB under the SFX bus, on the existing `Music` bus (volume slider already in Settings).

## Scene map

| Scene | Track | Why |
|---|---|---|
| Title / Save select | Week 35 - Reverence ENDLESS (E1, ambient) | Slow, wide, a bit lonely. Save select keeps playing it. |
| Stage select | Sketchbook 2024-10-13 (E1, ambient) | Calm, the map feeling. Crossfades from the title track. |
| Intro | Ludum Dare 32 05 (E1, ambient/spooky) | Sets the unease before Day 1. |
| Dialogue (all days) | Sketchbook 2023-11-29 (E1, 114 s) | Long and quiet, so it does not repeat often under the typing sounds. |
| Dialogue, Day 8 ending | Week 2 - Ruined Lands HOPE | Same family as the finale, the first hopeful sound in the game. |
| Investigation | Patreon Challenge 01 (E1, spooky) | Detective mood, low enough to read logs. |
| Report screen | same track | No change while answering. |
| Monitoring | Sketchbook 2025-11-12 (E3, electronic, 70 s) | A steady pulse for the 2:00 timer. |
| Hardening / shop / deck editor | Sketchbook 2024-09-25 (lofi, 90 s) | Calm planning, a "workshop" feel. Alternate: Sketchbook 2024-11-20. |
| Response, fight | Week 4 - Cloak of Darkness STAGE 1, 2, 3 (E5) | Three stages of one tune, switched by the threat's HP: above 66%, 33-66%, under 33%. The fight gets more intense as the threat falls. |
| Response, doom fight (counter upgrade missing) | Week 6 - Never Miss FIRE (E5) | Different and harsher, so the player hears that something is wrong. |
| Response, victory / defeat screen | Win: Week 2 - Ruined Lands HOPE. Lose: Sketchbook 2024-06-26 (E1) | Relief or aftermath. |
| Recovery (room and tasks) | Sketchbook 2024-11-13 (E1, 102 s) | Calm after the fight, long enough for the tasks. |
| Recovery finish screen | no change | The Recovery track keeps playing. |
| Book Archive | Troubadeck 31 - Thinking Back (acoustic) | Acoustic, a library feeling. |
| Credits | Week 20 - Dust Bowl HOPE OF RAIN (E1) | Warm and hopeful (Troubadeck is used only once, in the Archive). |
| Pause menu | no new track | The scene music lowers to -10 dB and a low-pass filter on the Music bus. |
| Settings | no new track | The scene underneath keeps playing, so volume sliders can be heard. |

## Optional variation (only if you want it)

Response uses the same three stages every day, which repeats 8 times. If that is too much:

| Days | Fight music |
|---|---|
| 1-2 | Cloak of Darkness stages 1-3 |
| 3-5 | Sketchbook 2024-07-04 / 2024-10-30 (E5) |
| 6-8 | Sketchbook 2025-12-14 (E5, 75 s) |

The cost is more files and a second set of stage switching rules, so I would start without it.

## Things to check by ear before building

1. Cloak of Darkness stages 1-3: the library includes TRANS files. I would verify the three loops are the same length and tempo so the switch lands on a bar.
2. Week 4, Week 6 file lengths are short (14-27 s). If they feel repetitive, swap in Sketchbook 2024-10-30 (54 s, E5).
3. Sketchbook 2025-11-12 is E3. If it fights the Monitoring rulebook reading, drop to Sketchbook 2024-09-22 (68 s).

## How it would be built

1. Copy the ~25 chosen files to `assets/audio/music/` (about 70 MB as OGG; I can re-encode lower if the build size matters).
2. `data/music.json`: `{scene_key: {track, volume_db, fade}}`, plus `response_stages` (HP thresholds) and `ending`.
3. New autoload `Music` (after `Sfx`): two AudioStreamPlayers on the `Music` bus for crossfades (1.0 s), `Music.play(key)`, `Music.duck(amount)`, `Music.set_stage(n)`. If the new scene wants the same track, it keeps playing (no restart between Title and Save select).
4. `SceneManager` asks `Music` for the scene's key on every change. Response calls `set_stage` when HP crosses a threshold, and `play("response_doom")` when the counter upgrade is missing. PauseMenu calls `duck`.
5. Credits screen: add "Music: Abstraction by Benjamin Burnes (CC0)".
6. Validator test: every key in `music.json` points to an existing file.

## As built

Decisions: the Response stages are kept (an instrument is added as the threat falls); the Day 8 ending uses the hopeful track (`hope`, the same one as a Response victory); the Abstraction credit line is added (MUSIC section of the credits). Troubadeck is used once, for the Book Archive.

- `autoload/music.gd` (autoload `Music`, after `Sfx`): `Music.play(&"key")`, `Music.stop()`, `Music.set_intensity(0..1)`, `Music.current()`, `Music.stage()`. Two players crossfade (1 s). Every OGG is set to loop. The music drops 9 dB and gets a low-pass filter while the game is paused (pause menu, confirm panels).
- `data/music.json`: `tracks` (file or stage files, `volume` in dB measured so every loop is equally loud, `thresholds`), `scenes` (scene path -> track, started by the autoload when the scene is opened), `fade`, `paused_db`.
- `assets/audio/music/`: 14 tunes, 48 MB.
- Scripts that change the music by themselves: title menu (day select), day select (back to the title, Archive), book archive (back), dialogue (Day 8 ending), Response (doom tune, the stages from the threat's HP in `_refresh`, `hope`/`defeat` when the fight ends).
- Stage switches keep the place in the 13.7 s loop. The TRANS files of Cloak of Darkness are not used (a crossfade of 0.5 s does the job).
- `tests/content/validate_days.gd` checks that every track file, scene and script-played track exists.
