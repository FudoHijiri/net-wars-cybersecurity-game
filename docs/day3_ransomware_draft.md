# Day 3: Ransomware (draft for review)

Status: **built (see section 12 for what differs from this plan).** Same shape as `day2_malware_draft.md`. Day 3 is the **backup day**: the lesson, the Recovery work and the new report form all point at one idea, *a backup that was kept apart is what saves you*.

**Decisions (from your review):**
1. The order report uses **option A** (reuse the blank screen: "First, Then, Then, Last").
2. **Dodge** stays on 6 of the 10 cards, because it is the introduction. It is explained by the **colored keyword and the hover panel** (built: `data/keywords.json`, the Response card panel), plus one line in the Response tutorial. Hover works in the panel beside the card, before the fight starts. A later step can add the same keyword hover to the Hardening panels.
3. **Ransomware is malware that encrypts files and locks them behind a payment demand.** The backup is the counter: you load a backup from **before the infection existed** and the problem goes away. So the Recovery task is built around *which backup predates the infection* (the red marker at 09:12), and the clue "the offline backup is intact" stays as the fourth clue.

- **Day title:** *Locked Out*
- **Threat:** Ransomware (the Book Archive's threat 3 opens when this Investigation is finished; its pages already exist)
- **The question Joshua answers:** *How did it start, how far did it spread, and what can we still trust?*
- **The story:** Marta Silva in Finance clicked a "parcel waiting" link at 09:12. By 09:14 the files on her laptop were renamed `.locked`. By 09:18 the shared Finance folder on the file server was locked too. At 09:19 a note, `READ_ME.txt`, demanded payment. **Last night's offline backup (01:00) is intact**, and that is what makes the day recoverable.
- **People:** Joshua (narrator), Carla (in person), Marta (the victim, by phone, scared about the month-end report), Dana (a decoy: she moved a big folder).
- **Enemy:** the Ransomware sprite that already exists (`ransomware_frames.tres`).

---

## 1. Investigation

### Tabs (the same seven slots, relabeled)

| Slot | Day 1 | Day 2 | **Day 3** | What it shows |
|---|---|---|---|---|
| 1 | EMAIL | EMAIL | **EMAIL** | messages to staff |
| 2 | LOGS | SECURITY | **ALERTS** | what the alarms said, and when |
| 3 | COMPUTERS | PROGRAMS | **LAPTOPS** | each laptop: state, last seen, files changed |
| 4 | LOGIN | DOWNLOADS | **BACKUPS** | every backup: when, where kept, checked or not |
| 5 | FILES | FILES | **FILES** | renamed, created and changed files |
| 6 | NETWORK | NETWORK | **NETWORK** | who talked to whom |
| 7 | SERVERS | SERVERS | **SERVERS** | the company's main computers |

### The 36 entries (roles: **CLUE** counts, decoy looks like a clue but is harmless, link connects two clues by a shared name, noise)

| Tab | Entry | Role | What it is |
|---|---|---|---|
| EMAIL | "Parcel waiting" | **CLUE** | `notice@track-parc3l.com` (a "3" for the "e"), to Marta, 09:12: *"Your parcel could not be delivered. Click to choose a new date."* |
| EMAIL | "My files look strange" | link | Marta to IT, 09:20: files have odd endings and a note on the screen. |
| EMAIL | Real parcel from a known courier | decoy | Right address, tracking number Marta really ordered, 08:40. Teaches real versus fake. |
| EMAIL | Month-end reminder | noise | Finance, 07:55. |
| EMAIL | Lunch menu | noise | |
| EMAIL | *Echo A* (see section 3) | echo | Replaces one noise entry. |
| ALERTS | Hundreds of files changed in 3 minutes | **CLUE** | File server, Finance folder, 09:15 to 09:18, 612 files, started by Marta's account. Nobody edits 600 files in 3 minutes. |
| ALERTS | Backup job renamed files | decoy | 01:00, the nightly backup adds `.bak`. Also many files at once, but approved, at its own hour, from its own program. |
| ALERTS | One wrong password | noise | Dana, then right. |
| ALERTS | Updates installed | noise | 03:00 (callback to Day 2). |
| ALERTS | *Echo B* | echo | Replaces one noise entry. |
| LAPTOPS | Marta's laptop | link | Unplugged by Marta at 09:21. 42 files changed in the first 2 minutes. |
| LAPTOPS | Dana's laptop | decoy | 400 files changed at 10:30: she moved the Design archive. Looks like ransomware, is not (the endings are normal). |
| LAPTOPS | Carla's laptop | noise | Fine. |
| LAPTOPS | Reception laptop | noise | Fine. |
| LAPTOPS | Backup computer | noise | Fine. |
| BACKUPS | Offline backup, 01:00 | **CLUE** | Kept on a drive that is unplugged after the copy. **Checked: restores fine. No locked files.** (The clue is an absence of damage.) |
| BACKUPS | Backup on the shared drive | link | Copied at 01:00, but the shared drive was reachable from the network: **its files are locked too.** Teaches why "offline" matters. |
| BACKUPS | Weekly backup, 4 days ago | decoy | Older, unchecked. Looks safe, is not proven. |
| BACKUPS | Backup of the design files | noise | Dana's. |
| BACKUPS | Backup schedule | noise | When each job runs. |
| FILES | Finance files renamed `.locked` | **CLUE** | Marta's laptop, 09:14: `budget_march.xlsx` becomes `budget_march.xlsx.locked`, then 41 more, in order. |
| FILES | `READ_ME.txt` | link | Appears on Marta's laptop at 09:19 and in the shared Finance folder at 09:19. |
| FILES | Design archive moved | decoy | Dana, 10:30, 400 files, ordinary endings. |
| FILES | Onboarding guide | noise | Carla. |
| FILES | Handbook | noise | |
| NETWORK | Laptop to file server, heavy writes | link | Marta's laptop writes to the Finance folder at 09:15 to 09:18, far above normal. |
| NETWORK | Laptop to an outside address | link | A small message at 09:14 (the program "phoning home" for its key). |
| NETWORK | Nightly backup copy | decoy | 01:00, file server to backup computer, 9 GB. Approved. |
| NETWORK | Printer | noise | |
| NETWORK | Normal web browsing | noise | |
| SERVERS | File server | link | Busy at 09:16, 3 times its normal load, Finance folder `.locked`. |
| SERVERS | Archive job | decoy | Zips old logs at 08:00 (also many file changes; harmless). |
| SERVERS | Backup computer | noise | Offline drive was unplugged at 01:20 (explains why it is intact). |
| SERVERS | Mail server | noise | |
| SERVERS | Update server | noise | |

**Total:** 36 entries (the table lists 38; two are echo variants that replace noise entries), **4 clues**, 6 decoys, 5 links.

### Joshua's voice (samples; the full text comes with the build)
- Clue, EMAIL: *"A parcel notice from track-parc3l, with a 3 where the E should be. A real courier would not hide behind a typo. That's a real clue."*
- Clue, BACKUPS: *"The offline backup was unplugged right after the copy, so the locks never reached it. It restores fine. Good news, and a clue about what to do next."*
- Decoy, ALERTS: *"The nightly backup also renames a lot of files, but it does it at 01:00, with its own program. Many files is not proof."*

### The report: **put the events in order** (the new form)

> *Put what happened in order, from first to last.*
> **First, {1}. Then {2}. Then {3}. Last, {4}.**

| Slot | Right card | Decoy cards (look like events, are not part of the attack) |
|---|---|---|
| 1 | Marta clicked the link in the parcel email (09:12) | *The nightly backup ran* (01:00) |
| 2 | Her files were locked (09:14) | *Dana moved a big folder* (10:30) |
| 3 | It spread to the shared Finance folder (09:16) | *The old weekly backup was checked* |
| 4 | The ransom note appeared (09:19) | |

A wrong order explains itself: *"The note comes last. The attacker locks the files first and asks for money after."* A card that is a real event but in the wrong place says so, as on Days 1 and 2.

Two ways to build the form: **(A)** reuse the existing blank-filling screen, with the text and the chips above (data only, almost free; the slots read "First", "Then"); **(B)** a real timeline (four numbered rows, with the cards dragged between them). I recommend **A now, B only if time is left**.

### Finish and links
- Pay as before: 20 per clue, -5 per mistake, 25 for a report right on the first try. Unlocks Book Archive threat 3.
- Clues recommend upgrades: "Parcel waiting" to **Filter Suspicious Email**; "Hundreds of files changed" to **Limit Shared Folders**; "Offline backup, intact" to **Offline Backups**. **Encrypt Stored Data** has no clue (general advice, like Keep Software Updated on Day 2).
- Findings copied for Recovery: the four clue summaries, plus the **time of the click (09:12)** that the backup timeline uses.

---

## 2. Monitoring: "files changed"

The shift reads a stream of **file activity** logs. Each log has four parts: **Program**, **Started by**, **Files a minute**, **New ending**.

### The rulebook (three rules)
| Rule | Text | Good | Bad | Why |
|---|---|---|---|---|
| Speed | A person changes at most 20 files a minute. | 6 | 240 | Nobody edits files that fast. A program does. |
| Ending | Files keep their usual ending (.docx, .xlsx, .pdf, .txt). | .xlsx | .locked | A new ending means the file was changed into something else. |
| Program | Only approved programs change files. | Office Suite | pay_now.exe | (the Day 2 list, plus Backup Agent) |
| (exception) | The Backup Agent may change many files at 01:00 and 13:00. | | | The backup job is approved and expected. |

### Decoys (look odd, follow every rule)
- **The Backup Agent changing 300 files** in its window (exempt from the speed rule).
- **A person saving a big batch:** 18 files a minute, normal endings, `Office Suite`. It is a lot for a person, but it is at the limit and the rest of the card is fine.
- **A new ending that is allowed**, such as `.pdf` for a scanned page.

### The threat
Most bad logs end in **`.locked`**, from one program name (**`FinanceLock.exe`**), at a high speed. The ending that repeats is the clue, as 7F3A and UpdateHelper were.

### Engineering for this event
The generic event path from Day 2 needs two small additions: a **`threshold` rule** (a number with a maximum, shown in the log as a plain number) and an **`exempt` field** (a value of another part that is allowed to break the rule, as the Backup Agent). The rest (guided first logs, mix 6/3/1, 25 % per hint, story logs for Marta) is data.

---

## 3. Hardening: four upgrades (ALWAYS passive, AGAINST counter)

| Upgrade | Load / price | ALWAYS | AGAINST | Recommended by | Icon (32x32) |
|---|---|---|---|---|---|
| **Filter Suspicious Email** | 1 / 30 | **+1 damage** on every attack card | **Every attack:** a longer warning before it starts (helper, as Scan Attachments) | "Parcel waiting" | an envelope with a hook and a crossed-out link |
| **Limit Shared Folders** | 1 / 30 | **heal 2 HP** at the start of each turn | **Mass lock:** the locked area cannot cross the wall between folders (it stays in its segment) | "Hundreds of files changed" | three folders with a barrier between them |
| **Offline Backups** | 2 / 50 | **+1 Energy** on your first turn | **Ransom demand:** the demand bar can never fill: the threat has nothing to ask for | "Offline backup, intact" | a drive with its cable unplugged |
| **Encrypt Stored Data** | 2 / 50 | **+4 Block** at the start of each turn | **Double extortion:** the stolen copy is useless, so the second wave does not come | none | a padlock over a file |

(The passives use keys that exist: `attack_bonus`, `heal_per_turn`, `first_energy`, `block_per_turn`. The Day 1 and Day 2 upgrades keep theirs. Numbers are tuned in the build with the dodge bots.)

### Hardening echoes (content, since the engine exists)
- If Day 2's **Scan Attachments** was equipped: EMAIL shows *"A scanner caught the same parcel notice for Dana and moved it to junk"*; without it, *"Dana got the same notice and nearly clicked"*.
- If Day 2's **Keep Software Updated** was equipped: ALERTS shows *"Laptops patched last week: a known hole in the courier's program is closed"*; without it, *"One laptop was missing the patch"*. (Both replace noise entries, so the count stays 36.)

---

## 4. Response: the Ransomware fight

Enemy: the existing Ransomware sprite. Player 90 HP; enemy about 110 HP (to tune with the dodge bots). Each pattern has a harder version without its counter, announced like on Days 1 and 2.

| Pattern | New kind | How it plays | Counter | Without it (harder) |
|---|---|---|---|---|
| **Mass lock** | `creep` | A padlock appears at one point of the box and **spreads**: tiles around it lock (red, hurt on touch) one ring at a time. The player keeps to the free part. | Limit Shared Folders: the lock stops at a visible wall (the box is split into segments) | The lock spreads faster, across the walls |
| **Ransom demand** | `demand` | A **demand bar** at the top of the box fills over the pattern while slow notes fall. When it is full, one wall sweeps with a very small gap. | Offline Backups: the bar cannot fill: no wall, no demand | The bar fills faster and the gap is smaller |
| **Double extortion** | `twin` | Bullets come in **pairs, from both sides at once** (a "copy" and a "threat"): pay or be published. | Encrypt Stored Data: the copy is useless, so only one side attacks | Pairs come closer together and more often |

The helper (Filter Suspicious Email) adds warning to every pattern (the same helper engine as Day 2). Each pattern gets `teach`, `say` and `works_note` lines in the style of the earlier days. Three new kinds: `creep`, `demand`, `twin`.

### New card effect: **Dodge**
Cards that give **Dodge N** make the next **N hits** of the enemy turn do no damage (a hit that is dodged shows DODGED). It is the effect from `notes.json` (`card_effect_ideas`) and fits the day: *"the copy you keep apart cannot be touched"*. Dodge stacks and is spent by the hits, so a stack is worth about one bullet (5 points at these sizes).

---

## 5. Cards: the 10 new ones (Dodge is on 6 of them)

Same format as Day 2 (data in `cards.json` with `"day": 3`, a line from Carla, 64x44 art in code, shop NEW filter). Prices from the point model (cost 0 = 3 points, 1 = 6, 2 = 13, 3 = 21; dodge about 5 per stack).

| Card | Type | Cost | Text | Value | Price | Art |
|---|---|---|---|---|---|---|
| Cut Cable | offensive | 1 | Deal 2 damage. Gain 1 Dodge. | 7 | 35 | scissors over a network cable |
| Decrypt | offensive | 2 | Deal 11 damage. | 11 | 40 | a key turning in a lock, the lock opens |
| Wipe | offensive | 3 | Deal 16 damage. Gain 1 Dodge. | 21 | 65 | a broom sweeping a screen clean |
| Lockpick | offensive | 1 | Deal 7 damage. | 7 | 35 | a pick in a keyhole |
| Air Gap | defensive | 1 | Gain 2 Block. Gain 1 Dodge. | 7.4 | 35 | a computer and a wall of empty space with a dotted gap |
| Offline Copy | defensive | 2 | Gain 3 Block. Gain 2 Dodge. | 13.6 | 55 | a drive with an unplugged cable |
| Snapshot | defensive | 1 | Gain 6 Block. | 7.2 | 30 | a camera flash over a file |
| Backup Check | utility | 1 | Heal 3. Draw 1 card. | 6.5 | 40 | a checklist with a tick over a drive |
| Rotate Keys | utility | 0 | Gain 1 Dodge. | 5 | 30 | two keys swapping places |
| Redundancy | utility | 2 | Gain 2 Dodge. Draw 1 card. | 12 | 50 | three stacked copies of a file |

Mix: 4 offensive, 3 defensive, 3 utility. Dodge appears on Cut Cable, Wipe, Air Gap, Offline Copy, Rotate Keys and Redundancy (6 of 10, since it is the new effect; Rotate Keys is the cheap way to get a taste of it).

---

## 6. Recovery: the backup day

Each attack that got through becomes one repair; the last is the final check. The Response result decides which of these the player gets.

| Attack that got through | Repair | Mechanic | What the player does | The line on why it matters |
|---|---|---|---|---|
| Mass lock | **Wipe and rebuild the laptop** | **order steps** (new, reused later) | Put six steps in order: unplug it, save the files you need and scan them, reinstall the system from a clean image, install only approved programs, restore the files, reconnect. A wrong order explains itself (reconnecting first would infect the network again). | "When the damage runs deep, rebuilding beats cleaning." |
| Ransom demand | **Restore from the right backup** | **backup timeline** (extends the existing cartridge task) | A timeline of backups, with a red marker at **09:12** where the infection began. Each backup has a time, a place (shared drive or offline) and a checked flag. Pick the **newest one from before the infection that is offline and checked**, run the test, restore, and read how much work was lost (a gap from 01:00 to 09:12). Then the second step: place **3 copies on 2 kinds of storage, 1 of them offline** (the 3-2-1 rule) so it never happens again. | "The newest backup may carry the infection. A backup nobody tested may not work. There is always a gap." |
| Double extortion | **Reopen the shared folders with care** | **permission grid** (new; Day 4 and 5 reuse it) | A grid of who may open which folder. Remove the extra access that let one laptop reach everything (Marta had write access to Finance and HR); keep what each job needs. | "Give only the access the job needs." |
| (final check) | **Back to work** | test (FileServerRepair, 3 checks) | Open a file from the restored backup (opens, **no `.locked` ending**), run the backup job (it completes), check the folder permissions (Marta can write to Finance only). | "Test that normal work still works." |

Stations: Day 3 reuses the existing equipment (laptops on the access and monitoring groups, the backup station, the servers). Every screen (the order list, the timeline, the grid) is drawn in code.

---

## 7. Dialogue (five scenes; beats, the lines are written when built)

1. **Before Investigation.** Marta on the phone, scared: *"My files all end in .locked and there is a note asking for money! The month-end report is in there!"* Choice: *Did you click a link?* (she remembers a parcel notice) / *Is it plugged in?* ("unplug the cable, yes!" Joshua: *do not pay, do not touch anything*). Joshua: *4 clues should be enough.*
2. **Before Monitoring.** Carla in person: *"Marta's laptop is unplugged and the server is safe for now. But this works by speed: so many files, so fast. Tonight we watch every file change."* Choice: *How do I tell a backup from an attack?* (the approved program and its hour) / *Can't we just pay?* (no promise, and it pays for the next attack). Introduces the rulebook.
3. **Before Hardening.** Carla: *"The one thing that saved us is a copy that was kept apart. Let's make sure it always is."* Joshua: the first upgrade he buys is the one the clues point at. (Introduces **Dodge**.)
4. **Before Response.** The malware is spreading *"like spilled ink"*; three tricks: **mass lock**, **ransom demand**, **double extortion**. Choice: *What is it doing?* / *Are we ready?* (a missing defense makes that trick harder).
5. **Before Recovery.** Carla: *"Stopped is not fixed. The files are still locked, the laptop is still sick, and the doors are still open."* Choice: *What do we fix first?* (the laptop, then the files) / *Can we get the files back?* (yes, from the offline backup: *that is why we kept one*).

---

## 8. Art, made in code

Everything is drawn pixel by pixel. Before it is wired in I show a **contact sheet** (all sprites enlarged next to each other).

| Asset | Size | Description |
|---|---|---|
| 4 upgrade icons | 32 x 32 | see section 3 |
| 10 card arts | 64 x 44 | see section 5; same dithered navy background as the other cards |
| Bullet: lock tile (mass lock) | 9 x 9 | a red padlock; a locked-tile frame is drawn in code |
| Bullet: ransom note (demand) | 9 x 9 | a yellow note with a dollar mark; the bar is drawn in code |
| Bullet: copy and threat (twin) | 9 x 9 | two small files, one red, one yellow |

---

## 9. What gets built

1. **Monitoring:** `threshold` rule and `exempt` field in `log_generator.gd`; `data/scenarios/day 3/monitoring.json`.
2. **Investigation:** `data/scenarios/day 3/investigation.json` (tabs, 36 entries, echoes, the order report as data, option **A**).
3. **Hardening:** four upgrades with passives (data), icons, shop lines; the echoes.
4. **Response:** three new arena kinds (`creep`, `demand`, `twin`) each with a harsh version; **Dodge** in the card engine and in the arena; `response_day3.json`; tuning with the dodge bots.
5. **Recovery:** three new tasks (`OrderSteps`, `BackupTimeline` with the 3-2-1 step, `PermissionGrid`) plus `day3_recovery.json` and the final check; register them in `RecoveryData`.
6. **Cards:** 10 cards, art, lines from Carla, Dodge; the validator already counts 10 per day.
7. **Dialogues:** five scenes. **Archive:** the Ransomware pages for attack patterns and upgrades (data).
8. **Validator and tests:** the day validator (it already checks everything it checked for Day 2), the three new tasks, the arena kinds, Dodge, a full Day 3 playthrough; all earlier suites re-run.

Order: Monitoring, Investigation, Hardening and cards, Response, Recovery, dialogues, playthrough, report.

---

## 10. What I want you to check

1. **The story:** Marta, the fake parcel notice, `.locked`, the intact offline backup. Right level and tone?
2. **The report form:** A (reuse the blank screen with "First, Then, Then, Last") or B (a real timeline). I recommend A.
3. **The clue that is an absence of damage** ("the offline backup is intact"): is it a good fourth clue? (It teaches *what is still safe*, not only *what went wrong*.)
4. **The patterns:** do `creep` (a lock that spreads), `demand` (a bar that fills, then one wall) and `twin` (pairs from both sides) sound fun to dodge?
5. **Dodge:** is *"the next N hits do nothing"* the right new effect for Day 3, and are 6 of 10 cards using it too many?
6. **The recovery tasks:** order steps (rebuild), the backup timeline with 3-2-1, and the permission grid. Anything to add or cut?
7. **Anything else** before I build it.


---

## 11. Added after the declutter and top-bar work (these were missing from sections 1-10)

**A. Objectives (in `data/days.json`; the validator already requires one per phase, at most 80 letters).** The top bar of every phase shows it.
| Phase | `objective` | Second step |
|---|---|---|
| Investigation | INVESTIGATE AND FIND CLUES | `objective_report`: PUT WHAT HAPPENED IN ORDER |
| Monitoring | WATCH FILE CHANGES AND REPORT THE ONES THAT BREAK A RULE | |
| Hardening | BUILD YOUR DEFENSE AND KEEP A COPY APART | |
| Response | STOP THE RANSOMWARE: PLAY CARDS, THEN DODGE | |
| Recovery | RESTORE THE FILES FROM A SAFE BACKUP | |

**B. Learning and story (panel feedback).** Story is the five dialogues of section 7. Learning is one sentence per phase, to show at the end of the phase if you want the "What you learned" line (not built, your decision): Investigation *a real sender would not hide behind a typo, and a copy kept apart is still safe*; Monitoring *many files changed at once, with a new ending, is a program and not a person*; Hardening *a copy kept apart is the best defense against locking*; Response *a threat that spreads has to be walled in*; Recovery *restore from a backup made before the infection, and test it*.

**C. Dodge, exactly.** A hit that lands while Dodge is up does **no damage and does not touch Block**; one Dodge is spent per hit; unspent Dodge is gone when the turn is over (this is what `data/keywords.json` already tells the player). Order on a hit: Dodge, then Block, then HP. A dodged hit shows DODGED, the chip pulses and its number drops. A creep tile that keeps touching the heart is one hit and then 0.6 s of grace, so a single tile cannot drain the whole stack.
- **UI:** Dodge is a second status chip under the HP bar, after Block, with its number and a tooltip from `keywords.json`. **Engineering gap:** `HpBar._draw_statuses` draws the shield mark for every status; it needs a chevron mark for Dodge (and a mark per id).

**D. Read before the bullets.** The strip shows the lesson only before the attack and only the first time, and only the attack's name while dodging. So the three new patterns need a `teach` line of at most two lines, **and a cue in the box itself**, because nothing can be read in the box while moving: the lock tiles flash red one ring before they harden (mass lock), the demand bar is drawn in the box and its fill is visible (ransom demand), and the two sides get a matching color pair (double extortion). Draft `teach` lines: *Mass lock: "The lock spreads from one spot. Stay in the free part."* / *Ransom demand: "A bar fills as the demand grows. When it is full, a wall comes."* / *Double extortion: "Two copies come, one from each side. Pay or be published."*

**E. Tutorials (`data/tutorials.json`).** Response: one step on the status row ("Buffs and debuffs sit under your HP bar. Point at one to read it"), added with Dodge. Investigation report: the order form needs its own step text ("Put what happened in order"). Monitoring: the Backup Agent exception in the rulebook example. Recovery: one or two steps per new task (order steps, backup timeline, permission grid).

**F. Plumbing.** The Day 3 entry of `days.json` (title *Locked Out*, the five dialogue files in `scenes/gameplay/visual novel/day 3/`, data paths for investigation, monitoring, response and recovery, the objectives above). `GameState` threat id `ransomware` for the archive.

**G. 24-hour time.** Every time in Day 3 is HH:MM in tables, emails, monologues, dialogues, the archive and Carla's lines, never AM or PM. I will add a validator check that rejects `AM`/`PM` after a number in any Day 3 text.

**H. Balance.** Not planned in numbers: enemy HP, bullet speeds and damage are set in the build with the dodge bots, using Day 2's tuning results as the target (what the bots take with the counters and without them). Dodge value (5 points per stack) is also checked there.

**I. Still open from section 10:** your answers to 1 (story tone), 4 (do `creep`, `demand` and `twin` sound fun) and 6 (the three Recovery tasks).

## Note (declutter)
Dodge is shown as a status under the player's HP bar (left to right, after Block), with a tooltip from `data/keywords.json` (`dodge`). `HpBar.set_statuses()` already takes the list; Day 3 only adds the entry and the icon.


---

## 12. As built (what differs from the plan above)

- **Card texts** use `+N Dodge` ("Deal 2 damage. +1 Dodge.", "+2 Dodge. Draw 1 card."), because a card face holds three short lines and "Gain 1 Dodge." made four. Rotate Keys keeps "Gain 1 Dodge." (two lines).
- **Hardening objective** is "HARDEN AND KEEP A COPY APART" (the bar has room for 41 letters with "OBJECTIVE - "); the validator limits the Hardening objective to 29 letters.
- **Mass lock** uses a 7 x 7 grid of 16 px cells. A new padlock appears every 2.0 s (not near the heart), blinks for 0.55 s, then locks; the lock spreads one ring every 1.0 s up to 40 % of the cells. With Limit Shared Folders two walls (between columns 2|3 and 4|5) stop it. Without it: a ring every 0.4 s, 0.3 s of blink, up to 78 % of the cells.
- **Ransom demand** has the bar under the box; the harder version sends two walls (1.1 s apart) with gaps of 26 px.
- **Double extortion**: with Encrypt Stored Data only the threat's side attacks; the copy (yellow) comes from the left.
- **Tutorials:** the Day 1 tutorial system could not teach a Day 3 mechanic, so `Tutorial.maybe_show_new(scene, key)` shows a one-time tutorial named by the day's data (`tutorial` in `response_day3.json`, in the `report` of the investigation, in the three Recovery components). The save keeps `tutorial_seen`.
- **Recovery:** the 3-2-1 step is part of the BackupTimeline task. The order of the six rebuild steps is checked one click at a time (a wrong click explains why it has to wait). The permission grid has four rows (Marta, Dana, Carla, Reception) and three folders.
- **Report screen objective:** a report may carry its own `objective` (Day 3: "FINISH THE REPORT BY PUTTING THE EVENTS IN ORDER"); Days 1 and 2 keep the text of the scene.
- **Tuning** (dodge bots, 16 runs each): with the counter an average bot takes about 0 to 1 damage per pattern; without it about 3.5 (mass lock, harder), 7 (ransom demand) and 6 (double extortion).
