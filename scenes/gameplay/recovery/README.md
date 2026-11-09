# Recovery scenes

Everything you see in Recovery is an editable scene. Open the `.tscn`, select a node, change it in the Inspector. Scripts only fill in text from `data/recovery/day1_recovery.json` and run the rules.

## Folder map

```text
recovery/
  Recovery.tscn            Live room: World + HUD + TaskLayer
  RecoveryWorld.tscn       Backdrop, walls, WallDecor, Actors (y-sorted), office exit
  RecoveryDemo.tscn        Practice launcher (F6)
  RecoveryPropLibrary.tscn Catalogue of every prop (preview only)
  RecoveryStatusMarker.tscn  The ! / ? / check bubble used by every prop
  ui/
    RecoveryHUD.tscn       Top bar (day, counter, Pause) and bottom hint
    RecoveryDialog.tscn    Work order, findings, credits, summary
  tasks/
    RecoveryTask.tscn      Shared repair frame (title, instruction, Body, feedback, Back / Start over)
    ResetPassword.tscn     Inherits RecoveryTask: approve the real Anna (RequestCards), pick a strong password (ChoiceCards), lockout on
    UndoChanges.tscn       Inherits RecoveryTask (kick_sessions.gd): activity log, undo the thief's changes, 2-step on
    ChangeTheLocks.tscn    Inherits RecoveryTask: try the stolen key on each door, rekey the doors it opens
    BackToWork.tscn        Inherits RecoveryTask: Day 1 Final Check (sign in, phone code, open her file)
    KickSessions.tscn      Inherits RecoveryTask: sign out unknown devices (SessionRows)
    NetworkRepair.tscn     Inherits RecoveryTask: drag cables to matching sockets
    BackupRepair.tscn      Inherits RecoveryTask: three CartridgeCards
    FileServerRepair.tscn  Inherits RecoveryTask: practice Final Check, three CheckCards
    parts/                 DragItem, DropSlot (mouse drag + keyboard pick/place), SessionRow, SettingRow, RequestCard, ChoiceCard, CartridgeCard, CheckCard
  props/
    RecoveryProp.tscn      Base of furniture/decor: art + floor footprint, no interaction
    RecoveryEquipment.tscn Base of repairable equipment: RecoveryProp + E reach + status marker
    RecoveryDecal.tscn     Base of every wall picture/clock
    equipment/             Repairable: MonitoringDesk, AccessTerminal, BackupStorage, NetworkSwitch, ServerRack
    furniture/             Desks, cabinets, sofas, chairs, shelves, workbench
    decor/                 Plants, lamp, bin, wall prints, clocks
```

## Minigames

The list of minigames lives in one place: `RecoveryData.COMPONENTS` in `scripts/gameplay/recovery/recovery_data.gd` (ID -> scene). Each Day JSON holds the text and items under `components.<id>`, the machines that may host each one under `equipment_selection`, and the Response attack each one belongs to under `attacks`. The full design is in `docs/recovery_minigames.md`.

To add a minigame: make a scene that inherits `tasks/RecoveryTask.tscn`, add one line to `COMPONENTS`, and add its content to the Day JSON. Wrong moves call `note_mistake(reason)`, which shows the reason and counts it for points.

A Day can swap the scene for one component with `components.<id>.scene` (Day 1 uses it to make `file_server` open `BackToWork.tscn`; practice keeps `FileServerRepair.tscn`). A task can leave facts for later tasks in `report`: they are saved with the run and passed to every task as `content.memory` (Day 1: the password picked in ResetPassword is the one BackToWork signs in with).

Every repair screen is drawn as the screen of the machine the player opened. The room passes `content.machine` (its Display Name and group) and the Day JSON gives `components.<id>.system` (e.g. "SIGN-IN SYSTEM"); both show in the title bar, with an icon per group from `group_icons` on `RecoveryTask.tscn`.

## UI styling

All fonts, colours, panels and buttons come from **`assets/recovery/ui/recovery_theme.tres`**. Double-click it to open Godot's Theme editor. Change a colour or StyleBox once and every Recovery screen updates. Labels pick a look through **Theme Type Variation**:

| Variation | Use |
| --- | --- |
| RecoveryHeading | Titles (Press Start 2P) |
| RecoveryMuted | Secondary text |
| RecoveryAccent | Cyan labels |
| RecoveryWarning | Yellow feedback / counters |
| RecoverySuccess | Green "[OK]" results |
| RecoveryFrame | The task screen (inside RecoveryBezel, the monitor plastic) |
| RecoveryTitleBar | Machine name bar at the top of a task screen |
| RecoveryHeader / RecoveryWindow | Cards, rows and inner panels |
| RecoveryCard / RecoveryCardGood | Big pressable cards (doors, password and file choices, keypad); Good = done |
| FeedbackHint / FeedbackGood / FeedbackBad | The feedback bar: next step (amber), right move (green), mistake (red) |
| RecoveryDanger | Red "[X]" text |
| RecoveryStamp | The REPAIRED pop-up |
| RecoveryHUDBar | The room HUD strip |
| RecoveryCompactButton | Small Pause button |

Repeated items (dialog paragraphs and buttons, practice presets) are copies of a hidden **Template** node in the scene. Restyle the template to restyle every copy.

To redesign a repair screen, open its task scene. Bezel, title bar, frame, feedback, footer and the REPAIRED stamp come from `RecoveryTask.tscn`, so edit that file to change every task at once. A mistake shakes the screen; success pops the stamp (`_shake()` / `_show_stamp()` in `recovery_task.gd`). Each task's own controls sit under `Frame/Layout/Body` and in the footer. The patch-panel cables follow the Device and Socket buttons, so you can drag those buttons freely.

## Props

There are two bases, so only things that can break carry an interaction area:

```text
RecoveryProp.tscn            furniture and decor (desks, sofa, plants, cabinets...)
  Sprite2D                   artwork (texture, offset, scale)
  SolidBody/CollisionShape2D floor footprint that blocks walking

RecoveryEquipment.tscn       inherits RecoveryProp; repairable machines only
  + Interaction/CollisionShape2D  E reach
  + Interaction/StatusMarker      shared ! / ? / check marker
```

The root of every prop sits on the floor at the bottom-centre of the art.

- **Change every copy:** open the prop's scene (e.g. `props/furniture/RearDesk.tscn`) and edit it.
- **Change all props at once:** edit `props/RecoveryProp.tscn` (e.g. collision layers). Edit `props/RecoveryEquipment.tscn` to change every repair target (e.g. marker height).
- **Change one placed copy:** in RecoveryWorld, select it under `Actors`. Its children are editable there.
- **Make a new prop:** right-click `RecoveryProp.tscn` (decoration) or `RecoveryEquipment.tscn` (something to repair) → New Inherited Scene, then set Sprite2D's texture. Set `offset` to (-width/2, -height) so the root stays on the floor, then size the two shapes.
- **Make a repair target:** use a scene from `props/equipment`. On the placed copy, set a unique **Equipment ID**, a **Display Name**, the **Eligible Group** and the **Assigned Task**. Furniture and decor can never take the E prompt.

### Size convention

One floor tile is about **57 units ≈ 1 m**, and the technician is about 97 units tall. New art is scaled to real-world size against that. Office desks are about 135 units wide, server racks 65 × 108 and plants 60–100 tall.

### Which way props face

Furniture against a wall faces **into the room**, with its back to the wall:

| Wall | What you see | Examples |
| --- | --- | --- |
| North (top, back) wall | Its front, facing the camera | MonitoringDesk, AccessTerminal, ServerRack, PrinterCabinet, Bookshelf |
| South (bottom, front) wall | Its back; it faces north, away from the camera | SpareDesk (chair on the wall side), LoungeSofa, ArmchairBack, RearFilingCabinet |
| West / east walls | Its side | BookshelfSide |
| Anywhere | No facing | Plants, lamp, bin, CoffeeTable |

Hover a furniture scene in the scene tree to see which wall it belongs on.

Wall pictures and clocks are **RecoveryDecal** scenes. Put them under `RecoveryWorld/WallDecor` so they draw behind people and furniture.

## Art

`tools/prepare_recovery_props.ps1` re-creates the extra prop images in `assets/recovery/office/props/` from the licensed source sheets. It does exact crops only, with no scaling, flipping or generation. Credits are in `assets/recovery/CREDITS.txt`.

## Tests

```text
godot --headless --path . --script res://tests/recovery/recovery_props_test.gd
godot --headless --path . --script res://tests/recovery/recovery_integration_test.gd
godot --path . --windowed --resolution 1280x720 --script res://tests/recovery/recovery_test.gd -- --visual
```

The walking test follows the office aisle at y = 420 and the repair-room aisle at y = 850. Keep those aisles and the doorway (x 1135–1215) clear, or update the test waypoints.
