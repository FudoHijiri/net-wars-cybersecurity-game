# Day 5: Data Exfiltration (draft for review)

Status: **built in all five phases** (see section 12 for what differs from this plan; the sections above are the original plan). Same shape as `day4_insider_draft.md`, with everything learned on Days 3 and 4 already folded in (section 10). Day 5 is the **"normal is a baseline, not a size"** day: the biggest transfer of the night is the harmless one, and the one that matters is small, steady and goes somewhere nobody approved.

- **Day title:** *Slow Leak*
- **Threat:** Data Exfiltration (the Book Archive's threat 5 opens when this Investigation is finished; its five pages exist, it still lacks the ATTACK PATTERNS and RECOMMENDED UPGRADES pages)
- **The question Joshua answers:** *What left, through which door, and when did it start?*
- **The story:** Priya Anand in Customer Support gets a complaint: a customer received spam at an address they gave **only to us**. Carla checks the database server (`db-01`) and sees an export at 03:10. A job called `sync_cache` has copied the customer table every night for **eleven nights**, in small pieces of 2 MB every five minutes, to a host (`198.51.100.23`) that is not on the approved list. It used the account `svc-report`, whose password has never changed. Nothing about it is loud. The nightly backup, which is approved, sends **9 GB** the same night.
- **People:** Joshua (narrator, helping less: he says what he noticed and the player decides), Carla (in person), **Priya Anand** (Support, by phone, the hook), **Tomas Ruiz** (the database admin, a decoy: he runs the approved nightly backup and a partner export), Ben and Marta (callbacks).
- **Enemy:** the Data Exfiltration sprite that already exists (`data_exfiltration_frames.tres`).
- **One threat actor** (standing decision): an outside attacker who used the `svc-report` account. No second actor.

---

## 1. Investigation

**Five clues from this day on** (standing decision: 4 on Days 1 to 4, 5 from Day 5). The report is a **fill-in-the-blanks** form again, with five blanks.

### Tabs (the same seven slots, relabeled)

| Slot | Day 4 | **Day 5** | What it shows |
|---|---|---|---|
| 1 | EMAIL | **EMAIL** | complaints and notices |
| 2 | ACCESS LOG | **JOBS** | what runs on a timer, who made it, when |
| 3 | PEOPLE | **HOSTS** | each computer and what is *normal* for it (the baseline) |
| 4 | PERMISSIONS | **DESTINATIONS** | the approved list of places data may go, and what was seen |
| 5 | FILES | **FILES** | archives and temporary files |
| 6 | NETWORK | **NETWORK** | every transfer: when, how much, to where |
| 7 | SERVERS | **SERVERS** | the database server, the backup server, the gateway |

### The 36 entries (**CLUE** counts, decoy looks like a clue but is harmless, link connects clues by a shared name, noise)

| Tab | Entry | Role | What it is |
|---|---|---|---|
| EMAIL | "Spam to my private address" | link (the hook) | Priya's customer got spam at the address used only for us. |
| EMAIL | Partner report, 08:00 | decoy | Tomas sends the approved analytics partner a small file every hour. |
| EMAIL | IT notice: nightly backup | noise | |
| EMAIL | Lunch menu, training day | noise | |
| EMAIL | Alert summary | echo (Day 4 **Unusual Activity Alerts**) | Equipped: *"The alerts flagged `db-01` three times this week. Nobody read them."* Not equipped: *"No alert fired on `db-01`."* |
| JOBS | `sync_cache`, created 11 days ago by `svc-report` | **CLUE** | Runs every night at 03:10. Nobody remembers creating it. |
| JOBS | `nightly_backup`, created by Carla | decoy | Runs at 01:00, approved. |
| JOBS | Log rotation, updates check | noise | |
| JOBS | `svc-report` last password change: never | link | |
| JOBS | Weekly report | noise | |
| HOSTS | `db-01` (database) | link | Normal: about 1 transfer an hour, 5 MB, quiet at night except the 01:00 backup. |
| HOSTS | `backup-01` | decoy | Normal: 9 GB at 01:00. Big, and normal for it. |
| HOSTS | Reception laptop, Carla's laptop, Marta's laptop | noise | |
| DESTINATIONS | `198.51.100.23` | **CLUE** | Not on the approved list. First seen 11 nights ago. |
| DESTINATIONS | Backup cloud, Analytics partner, Update server | decoy / noise | Approved. |
| DESTINATIONS | The approved list policy | noise | |
| DESTINATIONS | Gateway log | echo (Day 4 **Watch Outgoing Data**) | Equipped: *"The gateway flagged the host as odd and logged it."* Not equipped: *"The gateway let it through without a note."* |
| FILES | `tmp_cache.zip`, 480 MB, in the temp folder of `db-01` | **CLUE** | Created at 03:12; deleted at 05:40 each night. |
| FILES | Nightly backup archive | decoy | 9 GB, approved. |
| FILES | Handbook, onboarding guide, `report_march.xlsx` | noise | |
| NETWORK | 29 transfers of 2 MB, 03:15 to 05:35, to `198.51.100.23` | **CLUE** | Small and steady, not one big one. |
| NETWORK | Nightly backup copy, 9 GB, 01:00 | decoy | Approved destination. |
| NETWORK | Partner upload, 3 MB every hour | decoy | Approved destination. |
| NETWORK | Printer, browsing | noise | |
| SERVERS | `db-01`, export at 03:10, 41,000 customer rows | **CLUE** | Job `sync_cache`. |
| SERVERS | `backup-01`, the gateway, the mail server, the update server | link / noise | |

**Total:** 36 entries shown in each version (the table lists 38; two are echo variants), **5 clues**, 6 decoys, 5 links. All times are 24-hour; no AM or PM anywhere.

### Joshua helps less
Day 4's monologues told the player what a clue meant. From Day 5 Joshua says **what he noticed and asks the question**, and the player decides: *"A transfer every five minutes, all night, all the same size. That is not how a person sends files."* A clue is still marked FOUND when investigated.

### The report: fill the blanks (five)

> *At {1}, the job {2} began copying {3}, {4}, to {5}.*

| Blank | Right chip | Decoys |
|---|---|---|
| 1 When it started | eleven nights ago, at 03:10 | *last night, at 01:00* (the backup), *this morning, at 08:00* (the partner report) |
| 2 The job | `sync_cache` | `nightly_backup`, the weekly report |
| 3 What | the customer table | the finance folder, the handbook |
| 4 How | a little at a time, 2 MB every five minutes | in one big download of 9 GB |
| 5 Where | a host that is not on the approved list | the backup cloud, the analytics partner |

Each wrong chip explains itself (*"That is the nightly backup. It is big, but it goes to an approved place at its own hour."*). Pay as before: 20 per clue, -5 per mistake, 25 for a flawless report; unlocks Book Archive threat 5.

### The notes highlight what matters
The report screen's notes now color **times (gold), amounts (cyan), names, files and addresses (green) and people or places (white)**, so the player can find what a blank asks for. Day 5's notes are written with those in mind (a time, an amount and a name in nearly every clue).

### Links to Hardening
Clues recommend upgrades: `sync_cache` to **Label Sensitive Data**; the unapproved host to **Approved Destinations Only**; the 03:10 export to **Flag Odd Transfers**; `tmp_cache.zip` to **Close Unused Ports**.
Findings copied for Recovery: the five clue summaries, plus the account name `svc-report`.

---

## 2. Monitoring: "a transfer"

Each log has four parts: **Host**, **Sent to**, **Size**, **An hour** (how many transfers that hour). Two rules, both already in the engine (`lookup` from Day 4, `threshold` from Day 3), so **no engine work**.

| Rule | Text | Good | Bad | Why |
|---|---|---|---|---|
| Where | Each host may send only to its own approved places (the rulebook lists them: `db-01`: the backup cloud; `backup-01`: the backup cloud; `web-01`: the update server and the analytics partner; laptops: none). | `backup-01` to the backup cloud | `db-01` to `198.51.100.23` | Data should only go where it is approved. |
| How often | A host makes at most **6 transfers an hour**. | 2 | 12 | A steady trickle is a pattern. A person does not click 12 times an hour. |

**Size is not a rule.** That is the lesson: size appears on the card, but only the destination and the rhythm decide.

### Decoys (look odd, follow the rules)
- **The nightly backup: 9,000 MB** from `backup-01` to the backup cloud, one transfer. Huge, and fine.
- **The partner upload:** 3 MB, once an hour, to the analytics partner.
- **An update download:** 600 MB to a laptop from the update server (a host receiving, listed as allowed).

### The threat
Most bad logs are **`db-01` sending 2 MB to `198.51.100.23`, 12 times an hour** (the value that repeats). Story logs follow `sync_cache` through its night.

---

## 3. Hardening: four upgrades (ALWAYS passive, AGAINST counter)

New names (Days 3 and 4 already used Watch Outgoing Data and Least Access). Loads 1, 1, 2, 2; prices 30, 30, 50, 50.

| Upgrade (id) | Load / price | ALWAYS | AGAINST | Recommended by | Icon (32x32) |
|---|---|---|---|---|---|
| **Approved Destinations Only** (`egress`) | 1 / 30 | **+1 damage** on every attack card | **Quiet trickle:** the leak is closed: small bullets do not add Leak | the unapproved host | a list with one entry highlighted and a door with a padlock |
| **Flag Odd Transfers** (`flagodd`) | 1 / 30 | **+3 Block** at the start of each turn | **Big grab:** it comes apart into three small pieces | the 03:10 export | a flag on a bar chart |
| **Close Unused Ports** (`ports`) | 2 / 50 | **+20 max HP** | **Hidden door:** the lane about to fire lights up first | `tmp_cache.zip` | a wall socket with a plug and a stop sign |
| **Label Sensitive Data** (`labels`, helper) | 2 / 50 | **+1 Energy on your first turn** | **Every attack:** a longer warning before it starts | `sync_cache` | a file with a red tag |

### Hardening echoes
Day 4's **Unusual Activity Alerts** and **Watch Outgoing Data** each change one entry (see section 1); both replace noise, so the count stays 36.

---

## 4. Response: the Data Exfiltration fight

Enemy: the existing sprite. Player 90 HP; enemy about 125 HP (tuned with the dodge bots). Each pattern has a harder version without its counter, announced as before. Reading comes **before** the bullets, each pattern has a cue in the box, and the strip is only the name while dodging.

| Pattern | New kind | How it plays | Counter | Without it (harder) |
|---|---|---|---|---|
| **Quiet trickle** | `leak` | Small, slow bullets in a steady stream. Each hit does **1 damage** but adds **Leak** to you: at the start of your next turn you lose HP equal to your Leak (Block cannot stop it). The Leak status shows under your HP bar. | Approved Destinations Only: the leak is closed: hits add no Leak | Leak adds 2 per hit, and the stream is denser |
| **Big grab** | `blob` | One **huge** slow package homes toward the heart for the whole pattern (it turns slowly). One hit costs 18; Block takes it. | Flag Odd Transfers: it comes apart into three small pieces that do not home | It is faster, turns tighter and hits for 24 |
| **Hidden door** | `lanes` | Five horizontal lanes. Now and then one lane fires a fast volley across the whole box. | Close Unused Ports: the lane about to fire is lit for 0.8 s first | No warning: only a 0.15 s flash |

The helper (Label Sensitive Data) delays the start of every pattern. Draft lessons (at most two lines): *Quiet trickle: "Each hit is tiny, but they add up at the start of your turn."* / *Big grab: "One big package follows you. Keep moving, or block it."* / *Hidden door: "A lane fires without warning. Stay between the lanes."*

### New card effect: **Charge**
**Charge N** gives you **N Energy at the start of your next turn** (card idea "Recharge" from `notes.json`: worth about 6 points per Energy). It shows as a chip under **your** HP bar (a lightning mark, the Energy color) with a tooltip; it is spent when the turn starts. Keyword in `data/keywords.json` (`charge`): *"You get this much Energy at the start of your next turn."*

### A second new status: **Leak**
A **debuff on you**: the first debuff under the player's bar (red chip with a drop mark, tooltip: *"Lose this much HP at the start of your next turn. Block cannot stop it."*). `BulletArena` gets a `leaked(amount)` signal next to `hit`; `response.gd` adds to `_leak` and pays it at the start of the player's turn.

---

## 5. Cards: the 10 new ones (Charge is on 4 of them)

Same format as before (`cards.json`, `"day": 5`, a line from Carla, 64x44 art in code, the shop NEW filter). **A card text fits three short lines, a card name about 11 letters.**

| Card | Type | Cost | Text | Value | Price | Art |
|---|---|---|---|---|---|---|
| Sniffer | offensive | 1 | Deal 4 damage. Draw 1. | 6 | 35 | a nose-shaped probe over a packet |
| Egress | offensive | 2 | Deal 6 damage. Charge 1. | 12 | 45 | an arrow leaving a box, stopped by a hand |
| Trace Route | offensive | 1 | Deal 5 damage. Heal 1. | 6.5 | 35 | a dotted path of hops |
| Data Seizure | offensive | 3 | Deal 18 damage. | 18 | 60 | a hand taking a drive back |
| Closed Port | defensive | 2 | Gain 4 Block. Charge 1. | 10.8 | 45 | a socket with a plug of wood |
| Sealed Pipe | defensive | 2 | Gain 9 Block. Heal 1. | 12.3 | 50 | a pipe with a cap |
| Rate Limit | defensive | 1 | Gain 3 Block. Draw 1. | 5.6 | 35 | a gate with a counter |
| Recharge | utility | 1 | Charge 1. | 6 | 35 | a battery filling |
| Night Job | utility | 2 | Charge 2. Draw 1. | 14 | 50 | a moon over a clock |
| Audit Log | utility | 0 | Draw 1. Heal 1. | 3.5 | 25 | a scroll with a tick |

Mix: 4 offensive, 3 defensive, 3 utility. Charge is on Egress, Closed Port, Recharge and Night Job. A cost 3 card gets no Charge (the point of Charge is to pay for next turn, and a cost 3 card already empties this one).

---

## 6. Recovery: close the door and change the keys

Each attack that got through becomes one repair; the last is the final check. **No new task script**: all three reuse a task from Day 3 or 4 with new content.

| Attack that got through | Repair | Mechanic | What the player does | The line on why it matters |
|---|---|---|---|---|
| Hidden door | **Close the door: firewall rules** | **permission grid** (Day 3 and 4, content: rows are hosts, columns are destinations, "May send") | `db-01` may send only to the backup cloud; the laptops to none; `198.51.100.23` is in no column. Taking away a needed destination bounces back with its reason. | "Allow only the places data is meant to go." |
| Quiet trickle | **Change the keys: rotate `svc-report`** | **order steps** (Day 3) | Six steps in order: disable the old password, create a new one, update the job that needs it, test the job, remove the old key everywhere, write down who owns the account. A wrong order explains why. | "A password that never changes is a door that never closes." |
| Big grab | **Find the hidden archive, then tell the right people** | **account action** (Day 4, a new scene file `FindArchive.tscn` with the same script) | Step 1: choose which of six files is the leftover archive (`tmp_cache.zip`, found by its size and its odd hour) and delete it. Step 2: choose whom to tell and how (the manager and the customers affected, plainly; not everyone; not nobody). | "Find what is left, then tell the people who must know, honestly." |
| (final check) | **Back to work** | test (FileServerRepair, 3 checks) | The job is gone, the transfers to the unknown host are blocked, and the account has a new password. | "Test that nothing is still leaking." |

---

## 7. Dialogue (five scenes; beats, the lines are written when built)

1. **Before Investigation.** Priya (Support) by phone: a customer got spam at the private address given only to us. Choice: *Could it be a coincidence?* (Joshua: "Possible. Evidence first.") / *Which customers?* (all of them, she thinks). Joshua: *5 clues should be enough.*
2. **Before Monitoring.** Carla in person: *"Do not look at size. The backup is the biggest thing we send and it is fine. Look at where it goes and how often."* Choice: *How do I tell a backup from a leak?* (the approved list and the rhythm) / *Can't we just block everything at night?* (the backup runs at night).
3. **Before Hardening.** Carla: approved destinations and ports. Introduces **Charge** (*"Pay now for next turn."*).
4. **Before Response.** The thief does not shout. Three tricks: **quiet trickle**, **big grab**, **hidden door**. Choice: *What is it doing?* / *Are we ready?*
5. **Before Recovery.** Carla: *"Stopped is not fixed. The door is open, the key never changed, and the data is already out."* Choice: *What do we fix first?* (the door, then the key) / *Do we tell the customers?* (yes, plainly, after we know what left).

---

## 8. Art, made in code

| Asset | Size | Description |
|---|---|---|
| 4 upgrade icons | 32 x 32 | see section 3 |
| 10 card arts | 64 x 44 | see section 5; same dithered navy background |
| Bullet: tiny packet | 5 x 5 | the quiet trickle (a small white packet) |
| Bullet: big package | 20 x 20 | the big grab (a box with a handle) |
| Bullet: volley bolt | 9 x 5 | the hidden door (a sharp bolt) |
| Status marks | 7 x 8 | a drop (Leak), a lightning bolt (Charge) |
| Enemy | exists | `data_exfiltration_frames.tres` |

Before anything is wired in I show a contact sheet (all sprites enlarged).

---

## 9. What gets built

1. **Monitoring:** `data/scenarios/day 5/monitoring.json` (the engine is ready).
2. **Investigation:** `data/scenarios/day 5/investigation.json` (tabs, 36 entries, echoes, 5 clues, the fill-in report); Joshua's shorter monologues.
3. **Hardening and cards:** four upgrades with passives, icons, shop lines; 10 cards with art; the **Charge** effect (`response.gd`, `keywords.json`, a chip under the player's bar, a mark in `hp_bar.gd`, the validator's effect keys).
4. **Response:** three arena kinds (`leak`, `blob`, `lanes`) each with a harsh version; the **Leak** status and the `leaked` signal; `response_day5.json`; the dodge bots taught to avoid the blob and the lanes; tuning (target as before: with the counter an average bot takes about 0 to 1, without it about 4 to 7).
5. **Recovery:** content for the grid, the order steps and the account action; `FindArchive.tscn`; `day5_recovery.json`; register `archive` in `RecoveryData`.
6. **Dialogues, archive, tutorials:** five scenes; the Data Exfiltration ATTACK PATTERNS and RECOMMENDED UPGRADES pages; `Tutorial.maybe_show_new` keys (see below).
7. **Validator and tests:** the day validator (it already checks cards, upgrades, patterns, counters, objectives, echoes, AM and PM), the new arena kinds, Charge, Leak, the Day 5 playthrough; all earlier suites re-run.

Order: Monitoring, Investigation, Hardening and cards, Response, Recovery, dialogues, playthrough, report.

---

## 10. Carried over from Days 3 and 4 (so nothing is missed)

**A. Objectives** (`days.json`, at most 80 letters; Hardening at most 29)
| Phase | `objective` | Second step |
|---|---|---|
| Investigation | INVESTIGATE AND FIND CLUES | `objective_report`: FILL IN WHAT LEFT, HOW AND WHERE |
| Monitoring | WATCH WHAT LEAVES AND REPORT TRANSFERS THAT DO NOT FIT | |
| Hardening | HARDEN AND WATCH WHAT LEAVES (28) | |
| Response | STOP THE LEAK: PLAY CARDS, THEN DODGE | |
| Recovery | CLOSE THE DOOR AND CHANGE THE KEYS | |

**B. Learning and story.** Story is the five dialogues. Learning, one line per phase (for the "What you learned" line, if you want it built): Investigation *normal is a baseline for each host, not a size*; Monitoring *where it goes and how often decide, not how big*; Hardening *allow only the places data is meant to go*; Response *small and steady can cost more than big and rare*; Recovery *close the door, change the key, then tell the people honestly*.

**C. Tutorials** (`Tutorial.maybe_show_new`, named by the day's data): `response_day5` (Charge and Leak: both are chips under *your* bar, point at them), `recovery_archive` (the two-step task again, new content).

**D. Details that bit before:** card text at most three short lines and a name about 11 letters; no AM or PM (the validator rejects it); a Hardening objective at most 29 letters; test scripts need `tutorial_seen` filled or the overlay pauses the game; the report screen's clue tray is now in a scroll container (chips wrap, the list scrolls).

**E. Keywords** (`data/keywords.json`): `charge` (energy color) and `leak` (red).

---

## 11. What I want you to check

1. **The story:** the quiet leak over eleven nights, the unchanged service account, the spam to a private address. Right tone?
2. **Size is not a rule.** The 9 GB backup is the decoy and the 2 MB trickle is the threat. Is that clear enough as the lesson?
3. **Leak:** the first debuff on the player (lose HP at the start of your next turn; Block cannot stop it). Fair and readable?
4. **Charge:** *"Energy at the start of your next turn"*, shown under your bar. Right size?
5. **Big grab:** a huge homing package for a whole pattern (the harder version is faster). Fun, or frustrating?
6. **Recovery:** three reused tasks with new content (firewall grid, rotate the key, find the archive and tell the right people). Anything to add or cut?
7. **Anything else** before I build it.

---

## 12. As built: what differs from the plan

- **Monitoring needed one tiny engine addition.** A part with no rule has no value in the generic path, so Size could not be shown. LogGenerator got a rule kind `info` (shown, never broken, never picked to break). The rulebook lists it as "3. Size: Size is not a rule", which is the lesson of the day. The decoy backup shows 9,000 MB.
- **Rotate the key: a different order.** The plan disabled the old password first, which breaks the report job. As built: create the new password, give it to the job, test the job, disable the old one, remove the saved copies, write down the owner. The wrong order says why.
- **The Recovery key task is a new scene of an old script:** `RotateKey.tscn` (OrderSteps, component `rotate`); `FindArchive.tscn` (AccountAction, component `archive`). Both are in `RecoveryData`. AccountAction wraps its choices when there are more than four (six files).
- **Big grab:** one package at a time that homes (turn rate), the harder version sends two, faster, turning tighter. With Flag Odd Transfers the package comes apart after 1.1 s into three small pieces that do not home. The dodge bots (tests: tune_bot5) said one package was too easy to avoid.
- **Hidden door:** the harder version lights two lanes at once and fires five bolts. With Close Unused Ports a lane is lit for 0.8 s first; without, 0.15 s.
- **Leak and Charge are chips under the player's bar** (a red drop, a blue bolt) with tooltips. A hit that adds Leak counts as "got through" for Recovery even when Block took its damage. A dodged hit adds no Leak.
- **Card ids:** `sniffer, egress_cut (Egress), trace_route, data_seizure, closed_port, sealed_pipe, rate_limit, recharge, night_job, audit_log`.
- **Archive:** the Data Exfiltration pages got ATTACK PATTERNS and RECOMMENDED UPGRADES, and WARNING SIGNS no longer says "a big amount of data" (size is not the sign).
- **Tests:** `validate_days.gd` (3488 checks), the Day 5 playthrough, a Charge/Leak/arena test, an Investigation report test, a Recovery test, and the bot tuning.
