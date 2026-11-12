# Day 4: Insider Threat (draft for review)

Status: **built (see section 12 for what differs from this plan).** Same shape as `day3_ransomware_draft.md`, with everything I learned building Day 3 already folded in (section 10). Day 4 is the **"real access, wrong use"** day: the sign-ins are real, so the lesson is to look at *what a person does*, to give people only the access their job needs, and to **ask before you accuse**.

- **Day title:** *Wrong Door*
- **Threat:** Insider Threat (the Book Archive's threat 4 opens when this Investigation is finished; its five pages exist, it still lacks the ATTACK PATTERNS and RECOMMENDED UPGRADES pages)
- **The question Joshua answers:** *Is this access real, but wrong for this person's job?*
- **The story:** HR says **Victor Lang** leaves on Friday. Three weeks ago he moved from Engineering to Sales, and IT never closed his old access. Last night, between 21:30 and 22:25, his account opened the salary folder, zipped a 2 GB project archive and sent it to a personal cloud, and he forwarded the customer list to a personal address. **The logs show what he did, never why.** HR's reply (the only way to learn about the role change) says he is leaving and asks IT not to confront him yet. Nobody ever proves intent: that is the lesson.
- **People:** Joshua (narrator), Carla (in person), **Nadia Costa** (HR manager, by phone; she is also a decoy: she is *allowed* in the salary folder), **Victor Lang** (the insider; we never speak to him until Recovery), **Omar Singh** (works late on a deadline: a decoy), **Lena Moreau** (sent the customer list to the wrong customer by accident: a decoy for "accident versus intent"), Dana, Marta (callbacks).
- **Enemy:** the Insider Threat sprite that already exists (`insider_threat_frames.tres`).

---

## 1. Investigation

### Tabs (the same seven slots, relabeled)

| Slot | Day 3 | **Day 4** | What it shows |
|---|---|---|---|
| 1 | EMAIL | **EMAIL** | messages, including the ones the player sends |
| 2 | ALERTS | **ACCESS LOG** | who opened which folder, and when |
| 3 | LAPTOPS | **PEOPLE** | each person: role, previous role, status (staying or leaving) |
| 4 | BACKUPS | **PERMISSIONS** | which person may open which folder, and since when |
| 5 | FILES | **FILES** | copies, archives, forwards |
| 6 | NETWORK | **NETWORK** | what left the building, and to where |
| 7 | SERVERS | **SERVERS** | the file server, the HR system, the mail server |

### The 36 entries (roles: **CLUE** counts, decoy looks like a clue but is harmless, link connects clues by a shared name, noise)

| Tab | Entry | Role | What it is |
|---|---|---|---|
| EMAIL | Fwd: Customer list | **CLUE** | Victor to `vlang.home@webmail.example`, last night 21:48, attachment `customers_q3.xlsx`. A personal address is not a company address. |
| EMAIL | To HR: question about Victor | link, **opens the next one** | Joshua's drafted question to Nadia. INVESTIGATE sends it. Until it is sent, the reply does not exist. |
| EMAIL | Re: Victor's access | **CLUE, appears only after the question is sent** | Nadia: Victor moved from Engineering to Sales three weeks ago; his Engineering and salary-folder access was never removed; he leaves on Friday; *please do not confront him yet.* |
| EMAIL | "Oops, wrong person" | decoy | Lena sent the same customer list to a customer by accident and asked for it back. Also an insider, also harmless: accident versus intent. |
| EMAIL | Victor leaves on Friday | link | HR notice. |
| EMAIL | Team offsite | noise | |
| ACCESS LOG | Victor opens Salaries (22:05, 14 files) | **CLUE** | Role Sales; the folder belongs to HR. |
| ACCESS LOG | Nadia opens Salaries (09:10) | decoy | Role HR: allowed. |
| ACCESS LOG | Omar opens Projects (22:40) | decoy | Role Engineering, a deadline, valid sign-in at night. |
| ACCESS LOG | Victor opens Projects (21:30) | link | His *old* folder. |
| ACCESS LOG | Carla opens Servers (14:00) | noise | |
| PEOPLE | Victor Lang | link | Sales (was Engineering until three weeks ago), leaving Friday. |
| PEOPLE | Nadia Costa | decoy | HR manager. |
| PEOPLE | Omar Singh, Lena Moreau, Carla Patel | noise | |
| PERMISSIONS | Victor: Engineering, Salaries still open | link | "Never removed." |
| PERMISSIONS | Customers folder: Sales | noise | |
| PERMISSIONS | Salaries: HR | noise | |
| PERMISSIONS | Finance folder | echo (Day 3 **Limit Shared Folders**) | Equipped: *"The walls from last week kept Victor out of Finance."* Not equipped: *"Victor could open Finance too."* |
| PERMISSIONS | The policy | noise | "Access should match the job." |
| FILES | Projects archive zipped, 2 GB (22:20) | link | Victor's laptop. |
| FILES | `customers_q3.xlsx` saved and sent | link | |
| FILES | Nightly backup archive | decoy | Big, approved, at 01:00 (callback to Day 3). |
| FILES | Salary view log, Handbook | noise | |
| NETWORK | 2 GB to a personal cloud (22:25) | **CLUE** | Victor's laptop to an unknown cloud address. |
| NETWORK | Nightly backup copy (01:00) | decoy | Larger than the upload, approved. |
| NETWORK | Printer, Browsing | noise | |
| NETWORK | The upload | echo (Day 3 **Encrypt Stored Data**) | Equipped: *"The files were scrambled, so the cloud only holds noise."* Not equipped: *"The files left readable."* |
| SERVERS | File server, HR system, Mail server, Backup computer, Cloud gateway | link / noise | The mail server logged the forward. |

**Total:** 36 entries (the table lists 38; two are echo variants), **4 clues**, 6 decoys, 5 links. All times are 24-hour.

### Joshua's voice (samples; the full text is written in the build)
- Clue, ACCESS LOG: *"Victor is in Sales. The salary folder is HR's. The sign-in is real, so the question is why he opened it."*
- Gate, EMAIL (before sending): *"I do not know why he has that access. I should ask HR before I decide anything."*
- Decoy, ACCESS LOG: *"Nadia is HR. She is allowed in there. Real access is not the same as wrong access."*

### New engine: a clue that exists only after you ask
An entry may name `after: "<entry id>"`: its row is hidden until that other entry has been investigated, and then it appears with a NEW tag. The validator checks the target exists and that the gate is reachable. (The hint "ask HR" is also in Joshua's monologue of the first clue, so no player is stuck.)

### The report: **what we know, and what we do not know** (the new form)

> *From the logs we KNOW {1}, {2}, {3} and {4}. We do NOT know {5} or {6}.*

| Blanks | Right chips (any order inside a group) | Why the decoys are wrong |
|---|---|---|
| 1 to 4 (KNOW) | Victor opened the salary folder at 22:05 · 2 GB went to a personal cloud at 22:25 · the customer list was forwarded to a personal address · his old access was never removed | *"Victor is stealing for a rival"*: nobody has shown that; the logs show what he did, never why. *"Nadia opened the salary folder"*: she is HR, allowed. *"Omar worked late"*: valid. *"Lena sent the list to the wrong person"*: a separate accident, already recalled. |
| 5 and 6 (DO NOT KNOW) | why he did it · whether anyone else has the files | A *fact* in an unknown slot says: *"This one the logs do show."* |

A fact placed in an unknown slot (or the reverse) says so: *"The logs show what happened, not why."* Engine change: a blank's answer may be a **list**, so two blanks can accept the same group in any order (data plus a few lines in `report_screen.gd`).

### Finish and links
- Pay as before: 20 per clue, -5 per mistake, 25 for a flawless report. Unlocks Book Archive threat 4.
- Clues recommend upgrades: "Victor opens Salaries" to **Least Access**; "2 GB to a personal cloud" to **Watch Outgoing Data**; "Re: Victor's access" to **Close Access on Exit**; "Fwd: Customer list" to **Unusual Activity Alerts**.
- Findings copied for Recovery: the four clue summaries, plus *"the person is leaving on Friday"* (the account step uses it).

---

## 2. Monitoring: "a folder is opened"

Each log has four parts: **Who**, **Role**, **Folder**, **Time**. Two rules (a third was dropped: four short parts are enough to read).

| Rule | Text | Good | Bad | Why |
|---|---|---|---|---|
| Folder fits the job | The rulebook lists which role may open which folder (Engineering: Projects, Design; Sales: Customers, Price lists; HR: HR files, Salaries; Finance: Finance; IT: Servers, Backups). | Sales opens Customers | Sales opens Salaries | A person needs only the folders their job uses. |
| Hours | Work happens 07:00 to 19:00. IT on call may work at night. | 14:20 | 22:05 | Night access is rare and worth a look. |

### Decoys (look odd, follow the rules)
- **HR manager opens Salaries** (role HR).
- **IT on call opens Servers at 02:10** (the exception).
- **A person opens a folder at 18:40** (in the 30-minute "a bit odd" margin).

### The threat
Most bad logs are a role opening **Salaries** (the folder that repeats), with **Victor Lang** as a story person whose logs follow his night.

### Engineering for this event
Two small additions to the generic event path (the others, `allowed` and `threshold`, exist): a **`lookup` check** (a role decides which folders are allowed; the generator picks the role first, then the folder from its list, or one that is not) and a **clock check** on an `HH:MM` part (so a `range` rule works in the generic path). Hints, guided first logs, mix 6/3/1, story logs and the HUD line are data.

---

## 3. Hardening: four upgrades (ALWAYS passive, AGAINST counter)

| Upgrade | Load / price | ALWAYS | AGAINST | Recommended by | Icon (32x32) |
|---|---|---|---|---|---|
| **Least Access** | 1 / 30 | **+10 max HP** | **Trusted access:** bullets can only appear in the far part of the box | "Victor opens Salaries" | a key ring with all but one key crossed out |
| **Unusual Activity Alerts** | 1 / 30 | **heal 2 HP** at the start of each turn | **Slow copy:** an alert fires and the copying stops half way | "Fwd: Customer list" | a bell over a stack of files |
| **Watch Outgoing Data** | 2 / 50 | **+5 Block** at the start of each turn | **Walk-out:** the carriers are slow, and the item they go for is marked | "2 GB to a personal cloud" | a door with an eye over an arrow out |
| **Close Access on Exit** (helper) | 2 / 50 | **draw 2 extra cards** in the first hand | **Every attack:** a longer warning before it starts | "Re: Victor's access" | a badge with a cross, and a door closing |

(Passives use keys that exist: `max_hp`, `heal_per_turn`, `block_per_turn`, `first_draw`. The helper uses the helper engine of Day 2 and Day 3.)

### Hardening echoes (content)
- Day 3's **Limit Shared Folders** and **Encrypt Stored Data** change one PERMISSIONS and one NETWORK entry (see section 1). Both pairs replace noise, so the count stays 36.

---

## 4. Response: the Insider fight

Enemy: the existing Insider Threat sprite. Player 90 HP; enemy about 120 HP (tuned with the dodge bots). The enemy does **not** fire from outside the box: it already has the keys. Each pattern has a harder version without its counter, announced as before.

| Pattern | New kind | How it plays | Counter | Without it (harder) |
|---|---|---|---|---|
| **Trusted access** | `inside` | A badge **appears inside the box**, flashes for 0.7 s, then bursts into a ring of small bullets that fly outward. Nothing comes from the edge. | Least Access: badges can only appear in the far third of the box, so most of it is safe | Anywhere, including near the heart; 0.35 s warning; bigger rings |
| **Slow copy** | `ramp` | A quiet trickle of small slow bullets whose rate **grows** over the pattern. A "COPIED" bar under the box shows how much has been taken. | Unusual Activity Alerts: at half way an **ALERT** stops the copying; the bar freezes and says so | It keeps growing until it is dense |
| **Walk-out** | `carry` | Three **data items** sit in the box. Carriers fly in, take one and leave through the edge; a lost item costs 6 HP. **Staying near an item guards it** (the carrier passes by). | Watch Outgoing Data: carriers are slow and the item they want is marked with a line | Fast carriers, no mark |

The helper (Close Access on Exit) delays the start of every pattern, as on Days 2 and 3. Reading comes **before** the bullets: each pattern has a lesson of at most two lines (draft: *Trusted access: "A badge appears inside the box. Move away before it bursts."* / *Slow copy: "A little at a time. Watch the COPIED bar."* / *Walk-out: "Stay near a file to guard it."*) and a cue in the box itself (the badge flash, the COPIED bar, the guarded item's glow), because nothing can be read while dodging.

### New card effect: **Exposed**
A card with **Expose N** puts **Exposed N** on the threat until the end of your turn: every card played **after it** deals N more damage (flat, per damage card; it adds to the passive attack bonus). Exposed is a **debuff on the threat**, so it is the first status under the *enemy's* HP bar (`HpBar.set_statuses` already takes a list; it needs a mark for it, a crosshair). Keyword in `data/keywords.json` (`exposed`, `expose`), color pink (`#ff8fb1`, distinct from Damage orange): *"The threat takes N more damage from each card you play after this, until the end of your turn."* Value in the point model: 2 per stack (as in `card_balance`).

---

## 5. Cards: the 10 new ones (Exposed is on 4 of them)

Same format as Days 2 and 3 (`cards.json` with `"day": 4`, a line from Carla, 64x44 art in code, the shop NEW filter). **A card text must fit three short lines on the card face**, so the verb is "Expose" (9 characters), never "+1 Exposed" (it wraps to four lines).

| Card | Type | Cost | Text | Value | Price | Art |
|---|---|---|---|---|---|---|
| Access Audit | offensive | 1 | Deal 3 damage. Expose 1. | 5 | 35 | a magnifier over a list of names |
| Cross-check | offensive | 1 | Deal 4 damage. Draw 1 card. | 6 | 35 | two lists with a line between matching rows |
| Deep Review | offensive | 2 | Deal 10 damage. Expose 1. | 12 | 45 | an open folder under a spotlight |
| Revoke | offensive | 3 | Deal 17 damage. Heal 2. | 20 | 65 | a badge cut in two |
| Need to Know | defensive | 1 | Gain 4 Block. Draw 1 card. | 6.8 | 35 | a folder with a lock and a name tag |
| Access Check | defensive | 2 | Gain 8 Block. Heal 2. | 12.6 | 50 | a turnstile with a green light |
| Two-person Rule | defensive | 2 | Gain 5 Block. +1 Dodge. | 11 | 45 | two keys for one lock |
| Flag Account | utility | 0 | Expose 1. | 2 | 25 | a red flag on a user card |
| Ask HR | utility | 1 | Draw 2 cards. Heal 2. | 7 | 35 | a phone and a speech bubble |
| Review Log | utility | 1 | Heal 2. Expose 2. | 7 | 35 | a scroll of log lines with one highlighted |

Mix: 4 offensive, 3 defensive, 3 utility. Exposed is on Access Audit, Deep Review, Flag Account and Review Log (4 of 10, as decided); Dodge (Day 3) returns on Two-person Rule so it stays in play. A cost 3 card gets no Exposed (there would be no energy left to use it).

---

## 6. Recovery: close the access, and ask before you accuse

Each attack that got through becomes one repair; the last is the final check.

| Attack that got through | Repair | Mechanic | What the player does | The line on why it matters |
|---|---|---|---|---|
| Trusted access | **Take away the extra access** | **permission grid** (built on Day 3, new content) | Victor (Sales) still opens Engineering and Salaries; Lena and Omar have one folder too many; Nadia must keep Salaries. Taking away what a job needs bounces back with its reason. | "Give only the access the job needs." |
| Slow copy | **Disable the account, then talk to the person** | **account action** (new, two steps) | Step 1: choose which account to disable from four (Victor's, a shared admin account, Nadia's, Lena's), with a reason for each wrong choice. Step 2: choose how to talk to Victor: accuse him in front of the team, ask him in private with HR, or say nothing. | "Close a person's access the day they leave. Ask before you accuse: the logs show what, never why." |
| Walk-out | **Get the deleted file back** | **backup timeline, versions mode** (the Day 3 task, no 3-2-1 step) | `customers_q3.xlsx` was overwritten during the copy. A timeline of versions with a marker where it changed; pick the last good one, test it, restore it. | "A version history turns a mistake into an annoying day." |
| (final check) | **Back to work** | test (FileServerRepair, 3 checks) | Victor's old folders are closed, his account is disabled, the customer file opens at its last good version. | "Test that normal work still works." |

Choosing to accuse is allowed but costs a mistake and explains itself (*"He may have a reason. Ask first."*). New task script: `account_action.gd`; the versions mode is a few lines in `backup_timeline.gd` (skip step 2 when the content has no `rule_heading`). Stations: the existing equipment (access, servers, backup).

---

## 7. Dialogue (five scenes; beats, the lines are written when built)

1. **Before Investigation.** Nadia (HR) by phone: Victor Lang leaves on Friday; the access system flagged him opening the salary folder last night. Choice: *Is he stealing?* (Joshua: "We do not know. The sign-in is real. Evidence first.") / *What do you need from me?* (Do not confront him; do not touch his account yet.) Joshua: *4 clues should be enough.*
2. **Before Monitoring.** Carla in person: *"Not every odd access is bad. HR is allowed in the salary folder. IT works nights when on call."* Choice: *How do I know who may open what?* (the rulebook table) / *Can't we just block everyone at night?* (no: real work happens). Introduces the lookup rule.
3. **Before Hardening.** Carla: least privilege and closing access when someone leaves. Introduces **Exposed**: *"Mark the threat first, then hit it."* Joshua buys what the clues point at.
4. **Before Response.** The insider has keys and does not need to break in: three tricks, **trusted access**, **slow copy**, **walk-out**. Choice: *What is it doing?* / *Are we ready?*
5. **Before Recovery.** Carla: *"Stopped is not fixed. The access is still open, and there is a person in all this."* Choice: *What do we fix first?* (the access, then the account) / *Should we tell the team?* (no: ask him in private, with HR).

---

## 8. Art, made in code

| Asset | Size | Description |
|---|---|---|
| 4 upgrade icons | 32 x 32 | see section 3 |
| 10 card arts | 64 x 44 | see section 5; same dithered navy background |
| Bullet: badge (trusted access) | 9 x 9 | an ID card with a red stripe |
| Bullet: pip | 5 x 5 | the small bullets of a burst and of the slow copy |
| Bullet: data item | 9 x 9 | a blue file |
| Bullet: carrier | 9 x 9 | a grabbing hand |
| Enemy | exists | `insider_threat_frames.tres` |

Before anything is wired in I show a contact sheet (all sprites enlarged).

---

## 9. What gets built

1. **Monitoring:** `lookup` check and the clock check in `log_generator.gd`; `data/scenarios/day 4/monitoring.json`.
2. **Investigation:** `data/scenarios/day 4/investigation.json` (tabs, 36 entries, echoes, the gated entry, the report data); the `after` gate in `app_view_panel.gd`; list answers in `report_screen.gd`.
3. **Hardening and cards:** four upgrades with passives, icons, shop lines; 10 cards with art; the **Exposed** effect (`response.gd`, `keywords.json`, the enemy status chip and mark in `hp_bar.gd`, validator effect key).
4. **Response:** three new arena kinds (`inside`, `ramp`, `carry`) each with a harsh version; `response_day4.json`; the dodge bots taught to avoid badges and to guard items; tuning (target as on Day 3: with the counter an average bot takes about 0 to 1 damage, without it about 4 to 7).
5. **Recovery:** `account_action.gd` plus scene; the versions mode of `BackupTimeline`; the permission grid content; `day4_recovery.json`; register the new task in `RecoveryData`.
6. **Dialogues, archive, tutorials:** five scenes; the ATTACK PATTERNS and RECOMMENDED UPGRADES pages of the Insider entry (data); `Tutorial.maybe_show_new` keys (see below).
7. **Validator and tests:** the day validator (it already checks cards, upgrades, patterns, counters, objectives and echoes; **new: it rejects AM or PM after a number in any day's text**, which was promised for Day 3 and never written), `after` targets exist, role tables are complete, the new tasks, the arena kinds, Exposed, a full Day 4 playthrough; all earlier suites re-run.

Order: Monitoring, Investigation, Hardening and cards, Response, Recovery, dialogues, playthrough, report.

---

## 10. Carried over from Day 3 (so nothing is missed this time)

**A. Objectives** (`days.json`, at most 80 letters; Hardening at most 29)
| Phase | `objective` | Second step |
|---|---|---|
| Investigation | INVESTIGATE AND FIND CLUES | `objective_report`: SEPARATE WHAT WE KNOW FROM WHAT WE DO NOT |
| Monitoring | CHECK WHO OPENS WHAT AND REPORT ACCESS THAT DOES NOT FIT THE JOB | |
| Hardening | HARDEN AND LIMIT ACCESS (23) | |
| Response | STOP THE INSIDER: PLAY CARDS, THEN DODGE | |
| Recovery | FIX THE ACCESS AND ASK BEFORE YOU ACCUSE | |

The report screen carries its own objective (*FINISH THE REPORT BY SORTING FACTS FROM GUESSES*).

**B. Learning and story.** Story is the five dialogues. Learning, one line per phase (for the "What you learned" line, if you want it built): Investigation *real access can still be wrong, and the logs show what happened, not why*; Monitoring *the job decides what is normal*; Hardening *give each person only the access the job needs*; Response *the danger can start inside*; Recovery *close access, then ask before you accuse*.

**C. Tutorials** (`Tutorial.maybe_show_new`, named by the day's data): `response_day4` (Exposed: the status under the *threat's* bar, point at it), `investigation_know` (the know / do not know form, and "some things you ask for"), `recovery_account` (the two-step task). The gate needs no tutorial: Joshua says it.

**D. Details that bit me before:** card text at most three short lines; no AM or PM anywhere (the validator will reject it: the check is added with Day 4); a Hardening objective that fits the bar; test scripts need `tutorial_seen` filled or the overlay pauses the game; the card hand needs a bridge zone only if the panel changes (it does not).

---

## 11. What I want you to check

1. **The story:** Victor Lang, the unproven intent, HR asking us not to confront him. Right tone for a security lesson about people?
2. **A clue that appears only after you ask HR** (the new `after` gate): good, or too easy to miss? (The first clue's monologue points to it.)
3. **The report form:** six blanks in two groups (KNOW / DO NOT KNOW), with a list of accepted facts per group. Clear enough?
4. **Exposed:** *"every card you play after it deals N more damage until the end of your turn"*, shown as a debuff under the threat's bar. Right size, and is "Expose 1." on the card clear?
5. **Walk-out:** guarding an item by staying near it, while dodging the carriers' path. Fun, or too much to watch?
6. **The Recovery tasks:** permission grid again, the account action (pick the account, then accuse or ask), versions of one file. Anything to add or cut?
7. **Anything else** before I build it.


---

## 12. As built (what differs from the plan above)

- **Answers to section 11:** story as planned; the other questions were answered "what you recommend", so everything above was built as written, except the points below.
- **Card names and texts** were shortened to fit the card face: *Access Audit* became **Audit Trail**, *Access Check* became **Turnstile**, *Two-person Rule* became **Two Keys**; *Cross-check* and *Need to Know* say "Draw 1." (not "Draw 1 card.", which wraps to four lines).
- **Upgrade ids:** `least`, `activity`, `outgoing`, `exit` (Close Access on Exit, the helper). Passives: +10 max HP, heal 2, +5 Block, 2 extra cards in the first hand.
- **Monitoring:** `lookup` and `clock` checks in `log_generator.gd`. The rulebook prints the role table as the details of the first rule.
- **Investigation:** an entry may name `after` (a reply that exists only once the question was sent): the row appears tagged NEW and is selected. A report blank's answer may be a list of chips (the KNOW group and the DO NOT KNOW group). The report has its own objective and tutorial key (`investigation_know`). The network and permissions tabs each have one echo pair (Limit Shared Folders, Encrypt Stored Data).
- **Exposed:** the effect key is `expose`. It affects the cards played after it (its own damage is not boosted), stacks, and ends with the turn. It is a chip under the threat's HP bar (`hp_bar.gd` has a crosshair mark for it).
- **Arena kinds** (`bullet_arena.gd`): `inside` (a badge blinks, then bursts into a ring; with Least Access it only appears from 62 % of the box width on), `ramp` (the gaps shrink over the pattern; the alert at half way stops it and ends the pattern), `carry` (three files; a carrier that reaches a file the heart is not within 28 px of takes it out of the box, which costs 5 HP, or 7 in the harder version; with the counter the carriers are slow and the file they want is marked).
- **Recovery:** `account_action.gd` is new (two steps: close the right account, then choose how to talk). The backup timeline restores one file when its content has no `rule_heading` (the versions mode). The repairs of Day 4 are `folders`, `account` and `restore` (the Recovery room lists them in registry order).
- **Tuning** (dodge bots, 16 runs each): with the counter an average bot takes 0 to 1 damage per pattern; without it about 4 (trusted access), 4 (slow copy) and 6 (walk-out). Walk-out is the hardest with the counter, because the bot guards less well than a person.
- **Also done this day:** the **Book Archive** was redesigned (contents and the threat's picture on the first spread, pixel arrows, two topics to a spread), and the **validator rejects AM or PM** after a number in any text of a day.
