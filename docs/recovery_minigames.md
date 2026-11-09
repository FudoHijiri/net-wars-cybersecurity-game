# Recovery minigames: design plan

_Approved list: 2026-11-06. This replaces the three menu-style tasks with short, hands-on minigames in the style of the Among Us task system._

## 1. Goals

- **Among Us feel:** walk to a machine, press E, do one physical action for 10–30 seconds, then the machine shows a check mark.
- **Each minigame teaches one real recovery step**, explained in a single plain-language line when you finish. It follows the handout's plain-language rule.
- **One mechanic, many Days:** each minigame is one scene whose content comes from that Day's JSON, so a new Day mostly needs new data rather than new code.
- **No fail state, no countdown.** A wrong move bounces back with a short reason why. Mistakes only lower the bonus (see 4).
- **Accessible:** mouse first, with a keyboard fallback (select, then place) for every drag. Never colour alone: every good or bad state also has a label, icon or shape. No flashing.

## 2. The minigames

| ID | Minigame | Machine (eligible group) | Action | Lesson line (draft) |
|---|---|---|---|---|
| `network` | Reconnect Cables | Network switch (`network`) | Drag each cable plug to the socket with the same number and shape. Plugs on unchecked devices are taped down and can't be moved; trying one explains why. | "Only plug back in what has been checked. A cable is not a safety check." |
| `backup_database` | Restore Backup | Backup storage → server (`backup`, then `servers`) | Two stops. At storage, read the cartridge labels and take the clean one. At a server, insert it and hold the restore button while the bar fills; letting go pauses it without losing progress. | "Restore from a complete copy made before the attack, then check it." |
| `password` | Reset Password | Access terminal (`access`) | Drag word tiles into a passphrase. The meter rises with length; tiles that are personal info (name, birthday, "password") bounce off. Then flip the 2-step switch on. | "A long passphrase plus a second step stops a stolen password from being enough." |
| `sessions` | Kick Sessions | Monitoring desk (`monitoring`) | A list of devices signed in to the account, each showing device, place and time. Swipe or click Sign out on the unknown ones and keep the known ones. Signing out a known device warns you but lets you continue. | "After a break-in, sign the account out everywhere you don't recognise." |
| `quarantine` | Quarantine Sweep | Monitoring desk (`monitoring`) | Files slide along a belt. Drag files showing the infection marker into the quarantine box; clean files pass. The belt pauses while you hover a file. | "Isolate infected files so they can't spread. Don't just delete at random." |
| `patch` | Install Patch | Workstation or server (`monitoring` / `servers`) | Drag four step cards into order (Download → Check it's genuine → Install → Restart), then hold to install. | "Close the hole the attacker used, with an update from a trusted source." |
| `traffic` | Traffic Filter | Network switch (`network`) | Packets flow down a pipe, each labelled with its source. Click packets from the bad source to block them; let real users through. Speed is gentle and pauses on hover. | "Block the bad traffic without cutting off real users." |
| `access` | Access Cleanup | Access terminal (`access`) | A board of people and room keys. Drag back the keys someone shouldn't hold (former staff, extra rooms). | "Give people only the access their job needs." |
| `mail` | Mail Cleanup | Monitoring desk (`monitoring`) | Several inboxes. Find every copy of the phishing email (same sender and subject), delete them, then press Block sender. | "Remove the bait from everyone's inbox, not just one." |
| `restart` | Restart in Order | Server rack (`servers`) | Flip four switches in order: Power → Network → Server → App. A wrong order shows a plain-language fault line and resets that switch. | "Bring systems back step by step, in the order they depend on each other." |
| `file_server` | Final Check | Server rack or access terminal | The current verification, polished: run each check, then confirm. A mismatch shows the reason and keeps recovery open. | "Recovery isn't finished until you've checked it works." |

`network`, `backup_database` and `file_server` keep their current IDs so existing saves still load.

## 3. Which minigames each Day uses

Response damage picks which of the Day's minigames are needed (see 5). **Final Check always runs last**, even with zero damage.

| Day | Threat | Minigames (plus Final Check) |
|---|---|---|
| 1 | Credential Abuse | password, sessions, network |
| 2 | Malware | quarantine, patch, network |
| 3 | Ransomware | backup_database, restart, quarantine |
| 4 | Insider Threat | access, sessions, backup_database |
| 5 | Data Exfiltration | traffic, password, access |
| 6 | DDoS | traffic, restart, network |
| 7 | Phishing | mail, password, quarantine |
| 8 | Web App Attack | patch, backup_database, traffic |

## 4. Points

Each finished minigame pays a **base** amount, plus a **clean bonus** if you made no wrong moves. Mistakes only shrink the bonus, never the base, and the total never goes below the base. This matches the Monitoring finish-screen rule. Replays pay half, as in the other phases.

Proposed for Day 1: base 15, clean bonus 10, Final Check base 20.

**Built 2026-11-06.** Each task counts wrong moves (`RecoveryTask.note_mistake`). The count is saved per repair (`GameState.recovery_mistakes`). `RecoveryData.results()` turns it into the FinishScreen rows: Repairs done, Mistakes | Fixes, Clean fixes, Final check. The numbers live in the Day JSON: `points` (default) and `components.<id>.points` (Final Check: base 20, no bonus). Day 1 pays 95 for a perfect run, 85 with one slip, and 65 minimum. Practice runs show the points as "Practice, not paid".

Recovery's finish screen reuses `FinishScreen`. It shows each repair as a row, then the points, then the first-clear passives and cards, then CONTINUE to the next Day (see `notes.json`, `finish_screens.recovery`).

## 5. Link to Response damage (decided 2026-11-06: option A, hits per attack)

Response is the digital-world fight; Recovery is the real office afterwards. Each enemy attack stands for one real thing the attack can break:

- Each Day's Response enemy has **one attack pattern per minigame component** (for Day 1: password, sessions, network).
- Any hit the player takes during a pattern **marks that component as damaged**. Dodged or blocked patterns leave it intact.
- When the fight ends, Response calls `GameState.begin_recovery(damaged_ids, outcome)`, exactly as it does now.
- **Zero damage still runs Final Check**, so every Day ends with the verification lesson.
- Until Response is built, a temporary handoff after Hardening (or the practice lab) supplies sample damage.

## 6. How it's built

- **One scene per minigame** in `scenes/gameplay/recovery/tasks/`, each inheriting `RecoveryTask.tscn`. Layout lives in the scene and uses `recovery_theme.tres`; the script only fills in data and runs the rules. This follows the editor-authored rule in `scenes/gameplay/recovery/README.md`.
- **Shared parts** in `tasks/parts/`, reused across minigames:
  - `DragItem.tscn` / `DropSlot.tscn`: draggable item and target slot, with keyboard select-then-place built in, a bounce-back animation and a reason line.
  - `HoldButton.tscn`: hold to fill a labelled progress bar; letting go pauses it.
  - `Conveyor.tscn`: moving lane for Quarantine Sweep and Traffic Filter; pauses on hover or focus.
  - The existing `CartridgeCard` and `CheckCard`.
- **Content** sits per Day in `data/recovery/dayN_recovery.json` under `components.<id>`: labels, items, correct answers, reasons and the lesson line. A new Day adds only a JSON file and a `days.json` entry.
- **Component IDs in one place:** `RecoveryData.COMPONENT_IDS` becomes the only list. Today the IDs are also hard-coded in `game_state.gd` (2 places), `recovery_context.gd`, and the `@export_enum`s in `recovery_equipment.gd` and `recovery_interactable.gd`. The enums become a plain String validated against the list, so adding a minigame touches no other script.
- **Machine choice per Day** stays in `equipment_selection` (component → eligible groups). The room picks one matching machine at random when Recovery starts and keeps that choice for the run.
- **Two-stop tasks** (Restore Backup) record the first stop in the run state, so walking away and coming back keeps the cartridge in hand.

## 7. Day 1 content (first build)

- **Reset Password:** tiles `river`, `lantern`, `orbit`, `velvet`, `cactus`, `summer`. The bounce tiles are `Anna`, `1990`, `password`, `123456`; each shows its reason ("Your name is easy to guess"). The meter fills at 4 good words. Then the 2-step switch: "Ask for a code from Anna's phone."
- **Kick Sessions:** Anna's account shows
  - Anna's computer — Office — 08:30 (keep)
  - Anna's phone — Office — 08:32 (keep)
  - Unknown computer — Germany — 02:43 (sign out)
  - Unknown computer — Germany — 02:51 (sign out)

  The values reuse Monitoring's story logs, so the player recognises them.
- **Reconnect Cables:** the current devices (Anna's laptop, file server, unknown device), reworked as drag-and-drop.
- **Final Check:** the current sign-in, recovery-contact and test-file checks.

Machines: password → access terminal, sessions → monitoring desk, network → network switch, Final Check → one server rack. All four are spread across both rooms, so the player walks the office the way an Among Us crewmate walks the ship.

## 8. Build order

1. Shared parts: `DragItem`/`DropSlot`, `HoldButton`, plus the single component-ID list.
2. Day 1 set: Reset Password, Kick Sessions, the Reconnect Cables redo, Final Check polish. Then points and the Recovery finish screen.
3. Restore Backup redo (two stops) and Quarantine Sweep, which `Conveyor` enables.
4. Remaining mechanics as their Days are written: patch, traffic, access, mail, restart.

Each step keeps the three Recovery test suites passing and adds tests for its minigame: keyboard-only completion, a wrong move bounces with a reason, success emits once, and points follow the rule.

## 9. Open questions

- ~~Map movement~~ **Decided 2026-11-06:** keep the walkable office. Map movement turned out to be in scope. (`notes.json` requirement fr5 still says otherwise and needs the same update.)
- **Point numbers** in 4: are they in line with Investigation (20 per clue) and Monitoring (10 per correct call)?
- ~~Damage link~~ **Decided 2026-11-06:** option A, one attack per component. The Day JSON's `attacks` list maps each attack to its component, and `RecoveryData.components_for_attacks()` turns the attacks the player was hit by into the repair list.

## 10. Day 1, fitted to the Response fight (2026-11-09)

Each Day 1 repair now teaches the same counter as the Response attack that caused it (`AI generated/data/response_day1.json` → `defenses`):

| Response attack (pattern id) | Counter in the fight | Recovery repair | What the player does |
|---|---|---|---|
| Rapid guesses (`stream`) | Lock after failed tries | **Stop the guessing** (`password`) | Build a 4-word passphrase. The bounce tiles are the attacker's own guesses (`admin123`, `password1`, `qwerty`, `letmein`). Then switch on "Lock the account after 5 wrong tries". |
| Stolen password (`stolen`) | Two-step sign-in | **Lock out the thief** (`sessions`) | Sign out the two "Unknown computer 7F3A" sessions, keep Anna's own devices, then switch on 2-step sign-in. |
| One password, many accounts (`sweep`) | Unique passwords | **Change reused passwords** (`reused`) | Change the accounts still using `Summer2024`, the password the attacker tried; leave the ones with their own password. |

Both switch-ending tasks use a `FinalSwitch` whose label and messages come from the Day JSON (`final_switch`, `final_switch_locked`, `final_prompt`), so later Days can reuse them with other settings.

## 11. Day 1, recovery-only redesign (2026-11-09)

Section 10 made each task copy the fight's counter, which felt like replaying Response. Day 1 now has the player **clean up after** each attack instead. The fight's counter still appears, as the last switch of the task.

| Response attack | Recovery task | What the player does |
|---|---|---|
| Rapid guesses (`stream`) | **Give Anna her account back** (`password`, ResetPassword.tscn) | Two recovery requests arrive. Compare each with Anna's HR record: reject the one from phone ...97 in Germany (the thief), approve Anna in the office. Then build a 4-word passphrase (the attacker's guesses bounce) and switch on the lockout. |
| Stolen password (`stolen`) | **Undo the thief's changes** (`settings`, UndoChanges.tscn) | Compare four settings with last week's backup. Restore forwarding, the recovery phone and the unknown trusted computer; leave the display name, which never changed. Then switch on 2-step sign-in. |
| One password, many accounts (`sweep`) | **Change the locks** (`reused`, ChangeTheLocks.tscn) | Drag the stolen key `Summer2024` onto each account door (or press the key, then a door). Doors it opens get a new lock; doors it does not open are left alone. Rekeying an untested or safe door is a mistake. |
| Final Check | **Back to work** (`file_server`, BackToWork.tscn) | Walk Anna through her morning: pick her passphrase words in the order the player set them, type the code shown on her phone, and open the payroll report. Each step checks one Response verification flag (`sign_in`, `recovery_contact`, `test_file`); a false flag fails that step with its reason and recovery stays open. |

Plumbing: `RecoveryTask.report` is saved per component (`GameState.recovery_reports`, `recovery_runs.<day>.reports`) and handed to every task as `content.memory`. `components.file_server.scene` points Day 1 at BackToWork; practice profiles (`backup`) keep the CheckCard version. The old `ChangeReusedPasswords.tscn` is in `.godot/recovery-import-backup/2026-11-09-recovery-redesign/`.

## 12. Machines and a lighter password step (2026-11-09)

Playtest notes: the tasks were all about Anna's account although the player opens different machines, and building and then recalling a 4-word passphrase was too hard. Changes:

- **Each task is the tool of the machine it opens on**, named in a title bar ("ACCESS 01 / SIGN-IN SYSTEM"). Day 1: sign-in system (access terminal) gives Anna her account back; activity log (monitoring desk) undoes the thief's changes; account manager (the other access terminal) changes the locks; file server (server rack) runs Back to Work.
- **Password step is a simple pick.** After the identity check the player picks the strongest of three cards: `Anna2024` (name + year), `P@ssw0rd!` (on every guess list) and `river lantern orbit velvet` (four random words). Weak picks are crossed out with the reason. Back to Work just signs in with the picked password (one press); no recall.
- **Undo the thief's changes is an activity log**: time / who / what happened. Undo the three entries by "Unknown 7F3A"; Anna's own change from yesterday is kept.
- **New look** for every repair screen: monitor bezel, title bar with machine icon, cards with a pressed state, coloured feedback bar (amber next step, green right move, red mistake), a screen shake on mistakes and a REPAIRED stamp on success.

