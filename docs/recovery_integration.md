# Recovery migration into the latest main

Completed 2026-11-05. The project under `net-wars-cybersecurity-game/net-wars-cybersecurity-game-main` is the main version. The previous project contributes Recovery only.

## Files added

- `scenes/gameplay/recovery/`: office, reusable props, player, interactions, shared markers, three tasks and explicit practice launcher.
- `scripts/gameplay/recovery/`, `data/recovery/`, `assets/recovery/`: Recovery logic, Day 1/practice content, supplied office art and unchanged technician. Main-menu fonts are reused.
- `art_source/recovery/`: active source records and supplied originals only, excluded through `.gdignore`. Retired art and prior project caches are not imported.
- `tests/recovery/`: gameplay and integration runners, excluded from export through `.gdignore`.
- `tools/prepare_recovery_office.ps1`: reproducible transparent crops and rack GIF extraction.

## Existing files extended

1. `autoload/game_state.gd`: preserve phase API and all current state; add Response/Recovery handoff, findings snapshots, per-day restoration and completion.
2. `autoload/save_manager.gd`: two optional per-day dictionaries and backward-compatible defaults for existing version-1 saves. Slot encryption, wallet, deck data and progression logic are preserved.
3. `scripts/gameplay/finish_screen.gd`: one call captures findings before its existing completion/save step.
4. `scripts/gameplay/monitoring/monitoring.gd`: one summary field exposes the existing answer records; gameplay, timers, judgement, scores and animations are preserved.
5. `data/days.json`: register the Day 1 Recovery scene/data without changing other phase entries.

The project configuration, SceneManager, Investigation scenes/scripts/data, menus, Pause, Settings and original assets are not replaced. The old PhaseTransition helper is not used by Recovery; return navigation uses the main project's existing SceneManager.

## Play and integration contract

Open `scenes/gameplay/recovery/RecoveryDemo.tscn` and press F6. Seven isolated scenarios include Combined Practice and a single-server work order. The live scene is `scenes/gameplay/recovery/Recovery.tscn`.

A future Response implementation supplies:

```gdscript
GameState.begin_recovery(["network"] as Array[String], {
    "contained": true,
    "summary": "Containment confirmed. Recovered access is ready for checks.",
    "cleared_devices": {"anna_device": true, "payroll_server": true, "unknown_device": false},
    "verification": {"sign_in": true, "recovery_contact": true, "test_file": true},
})
GameState.set_phase("recovery")
SceneManager.open_current_phase()
```

Response must complete its own phase through the main save flow. Calling `begin_recovery()` does not mark unimplemented phases complete. Missing outcomes wait; confirmed zero damage still requires final verification. Day 1 does not automatically require backup restoration or claim to retrieve stolen information.

## Validation

- 176 headless Recovery checks passed; 204 rendered checks passed.
- 31 integration checks passed, including actual native Investigation/Monitoring result screens, context capture, normal/suspicious reports, slot reload, retained repairs, duplicate completion, new game, seven-demo isolation and old version-1 save compatibility.
- A dedicated test save directory under the project cache avoids player save files.
- Native/2x captures are generated under `.godot/recovery-office-qa/`.
- Tests cover physical routes, editable collisions/reach, keyboard/mouse tasks, modal locking, pause/settings, retries and completion.
- Two misplaced copied reach-shape overrides were removed so the switch/workbench can be approached. Preview physics is explicitly disabled; its scenery cannot block the playable room. Recovery restores its own focus after using the existing pause overlay.
- Existing engine certificate-store/editor-settings environment messages are distinct from script/test failures.

```text
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/recovery/recovery_integration_test.gd
godot --headless --path . --script res://tests/recovery/recovery_test.gd
godot --path . --windowed --resolution 1280x720 --script res://tests/recovery/recovery_test.gd -- --visual
```

All physical placement remains authored in Godot scenes. Later Days, final art provenance, implementing Response/Hardening and unrelated legacy code audits remain separate work.

## Office dressing and interaction spacing, 2026-11-05

The room now has twenty authored props: eight additions include two spare desks, a records cabinet, a bookcase, two plants, a wastebasket and a wall clock. The small decorations use exact crops from the locally archived Pixel Office pack by 2dPig (CC0); their source sheet, licence and credits are included. Existing furniture artwork and the main-menu fonts are retained.

Backup storage moves to the main office. All three server IDs remain available, with racks spaced across the repair room. The workbench is decorative and no longer supplies an overlapping task target. Nine equipment interaction rectangles have no pairwise overlap and cover at least 30x28 viewport pixels. Collision footprints cover furniture bases, with the office and repair-room aisles kept clear. Every placement, footprint and reach rectangle remains editable in Godot.

The updated checks cover physical travel to every target, exact prompt selection at each approach, disjoint/generous reach areas, decorative workbench blocking without an E target, saved IDs, editor roundtrip, all minigames, pause/settings and retained progress. Validation passed: 188 headless checks, 216 rendered checks, and 31 main-project integration checks. Native and 2x screenshots were reviewed. Logs and captures are stored under the project cache.

## Foreground furniture direction, 2026-11-05

Foreground furniture now faces into the room. The spare desks use authored rear desk/monitor views, with the chairs on the far/room side. A nested y-sort and separate desk/chair footprints keep occlusion and collision aligned. The sofa uses an authored rear view, and the foreground filing cabinet shows its rear panel. The front-only bookcase moves to the rear wall at (1345,365); the original rear-wall desks and printer keep their front views.

Used directional sprites come from the free Office Pixel Art pack by Imersa Studios and the free Midcentury Modern Furniture Set by 0_mem0ry. Original files, creator licences, crop/normalization details and credits are retained. No generative art, vertical flips or negative sprite scales are used. All visual parts and floor footprints remain editable Godot nodes. Equipment IDs and task interaction zones are unchanged.

The full rendered room/task runner passed 216 checks with zero failures in staging. Collision and all-nine-target travel remain covered; final native/2x orientation screenshots are reviewed after deployment.

## Manual prop authoring and orientation revert, 2026-11-05

The automatic foreground orientation and bookcase relocation above have been reverted at the user's request. The room uses its previous foreground images and positions. Directional art remains available only as manually placeable alternatives: SpareDeskNorth, BreakCornerNorth and RearFilingCabinet.

All sixteen office prop types now directly own their artwork, physical floor collision, interaction rectangle and complete status marker in one scene. Decorative props have dormant interaction areas controlled by the root's Interaction Enabled switch. Clock blocking starts disabled. Recovery ignores disabled areas, preserving the existing repair targets, progress and E prompts. No runtime placement code is added.

RecoveryPropLibrary.tscn is a separate catalogue. It previews the available assets and does not rearrange the game room. The prop tests verify ownership, independent shapes, root movement, interaction toggles and save/reopen for every type. Gameplay authoring tests now accept designer placements rather than asserting a fixed furniture table. Existing room routes and all three minigames remain covered by the journey runner.

Validation for the editable prop library: 84 prop checks, 188 headless room checks and 216 rendered room checks passed. All prop children are owned by their own asset scene; shape edits round-trip independently.

## Editor-built UI and prop restructure, 2026-11-06

All Recovery UI is now authored as scenes instead of being built in code. `ui/RecoveryHUD.tscn` and `ui/RecoveryDialog.tscn` hold the HUD and dialogs. `tasks/RecoveryTask.tscn` is the shared repair frame, and NetworkRepair, BackupRepair and FileServerRepair inherit it. `tasks/parts/` holds CartridgeCard and CheckCard. Styling lives in `assets/recovery/ui/recovery_theme.tres`, using theme type variations. `RecoveryStyle` now only keeps the palette and the focus helper. The rendered output matches the previous screens.

Props moved from `office/` to `props/{equipment,furniture,decor}/`. Every floor prop inherits `props/RecoveryProp.tscn`, which shares a single `RecoveryStatusMarker.tscn` instance. Wall items inherit `props/RecoveryDecal.tscn` and sit under `RecoveryWorld/WallDecor`. The superseded `office/` scenes, the old 2:1-normalised rear images and the previous RecoveryWorld are kept under `.godot/recovery-import-backup/2026-11-06-prop-restructure/`.

The room layout now faces props by wall. Front views stand on the north walls. Back views stand on the south walls: rear desks, filing cabinets, a lounge sofa and waiting armchairs. Side-view shelves stand on the west and east walls. The network switch moves to the office's north-east corner. The repair room has the three racks and the workbench on its north wall, with a technician desk and cabinets on its south wall. Plants, a lamp, a coffee table, bins, prints and two clocks fill the room. Imersa art is used at native pixels, and the new midcentury crops come from `tools/prepare_recovery_props.ps1`. All of it is sized at about 57 units per metre.

Validation: 146 prop checks, 216 rendered room checks and 31 integration checks passed.

## Day 1 play-through stand-in and Joshua sprite, 2026-11-06

`scenes/gameplay/standin/PhaseStandIn.tscn` temporarily stands in for **Hardening** and **Response** (`"stand_in": true` in `data/days.json`). With it, Day 1 runs Investigation → Monitoring → Hardening (stand-in) → Response (stand-in) → Recovery → results.
- The Response stand-in lists the Day's `attacks`. The player ticks which ones hit, and it calls `GameState.begin_recovery(RecoveryData.components_for_attacks(...))` with an assumed containment.
- Neither stand-in marks its phase complete.
- When the real phase is built, point its `"scene"` in `days.json` at it and remove `"stand_in"`.

The Recovery technician is now Joshua: `assets/recovery/technician.png`, rebuilt by `tools/build_technician.gd` from the CC0 MetroCity layers. Test: the left row is an exact mirror of the right row, and Joshua's colours are present.

## Merged into the main with Hardening and Response, 2026-11-09

Recovery now lives in this project, which has the real Hardening (`scenes/gameplay/hardening/`) and Response (`AI generated/scenes/response/Response.tscn`). The Hardening/Response stand-in from the previous project is not used.

**What was copied:**
- `scenes/`, `scripts/`, `data/`, `assets/` and `art_source/recovery`
- `tests/recovery`
- the `tools/` prop and technician builders
- `addons/godot_mcp_bridge`, enabled in `project.godot`

**Shared files extended (originals in `.godot/recovery-merge-backup/2026-11-09/`):**
- `game_state.gd`: Recovery state and handoff, plus the new `found_clue_ids` / `spend_points` / `add_points`.
- `save_manager.gd`: `phase_findings` and `recovery_runs` added to new games and as defaults for old saves.
- `finish_screen.gd`: findings capture, practice mode and `continue_requested`.
- `monitoring.gd`: `monitoring_answers` in the results.
- `days.json`: the `recovery` phase.

**Response → Recovery (option A):**
- `response.gd` records `hit_patterns`: the ids of attack patterns whose damage got past Block.
- After THREAT CONTAINED, CONTINUE saves Response as complete and calls `GameState.begin_recovery(RecoveryData.components_for_attacks(day data, hit_patterns), response_outcome)`, then opens Recovery.
- Day 1 attacks map as `stream` (Rapid guesses) → Reset Password, `stolen` (Stolen password) → Kick Sessions, and `sweep` (One password, many accounts) → **Change Reused Passwords**. That last one is a new minigame: the KickSessions scene with `components.reused` content.

**Upstream fix:** `finish_screen.gd` also collects rows from a node named `Container`. The new `Investigation.tscn` renamed its results rows to that, and the results screen found no rows and errored before CONTINUE.

Validation: 156 prop checks, 35 integration checks (including a real Response win handing off to Recovery) and 270 rendered room checks passed.
