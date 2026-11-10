# Day-by-day variations: what each day changes in every phase (plan)

Status: **plan only, nothing built.** The Investigation side (the question each day asks, the clues, the decoys, the report) is in `docs/day_variations_investigation_plan.md`; this document adds the other four phases and the shared things that make eight days affordable.

Decisions taken: seven tabs relabeled per day; 4 clues on Days 1 to 4 and 5 from Day 5; **one threat actor per day**; the new Investigation report forms (yes); hardening echoes (yes, added after the eight days work without them); **every day has its own four upgrades, each with an always-on passive and a specific counter**; **all art is made by the assistant, in code**; one day drafted at a time, for review. The Day 2 draft is in `docs/day2_malware_draft.md`.

---

## 1. The contract: what is the same every day and what is the threat's

Every day has the same five phases and the same loop. A day is *defined* by its threat; the threat changes these things.

| Phase | Stays the same | Changes with the threat |
|---|---|---|
| **Investigation** | 7 tabs, entries, clues, report, pay | the question, tab labels, evidence, decoys, report form (see the other plan) |
| **Monitoring** | a shift of logs, REPORT or LET PASS, a rulebook, hint clicks that cost patience | **what an event is** (a sign-in, a program, a file change, a transfer...), the rules, the decoys |
| **Hardening** | deck, shop, upgrades with a load budget (2 per day number) | the upgrades the threat makes useful, and which are recommended from the clues found |
| **Response** | cards, then dodging; 3 attack patterns, each with one counter upgrade; the harder version without it | the enemy, the three patterns (how the threat really behaves), which upgrade counters each |
| **Recovery** | the office, stations, a work order made from the attacks that got through, a final check | the repairs (one per pattern that got through), each a small task with a line on why it matters |

The rule that ties a day together, as on Day 1: **the evidence found in Investigation points to the upgrades in Hardening, which counter the patterns in Response, and the patterns that get through become the repairs in Recovery.** Every day has to keep that chain whole, and the Monitoring shift rehearses the same threat's signs.

---

## 2. Shared building blocks (this is what keeps it to a reasonable size)

Eight days of brand-new mechanics is too much. The plan is to **reuse a small set of mechanics with new content** (for mechanics, bullet behaviours and Recovery tasks; upgrades are not reused: each day has its own), and add a new mechanic only when a threat truly needs it.

### 2.1 Upgrades: four per day, each with a passive and a counter

Every day has its own four upgrades (32 in all). Each upgrade does **two things**:
- **Always (the passive):** a general benefit in every fight while it is equipped, whatever the threat. This is what makes an upgrade worth its load even on a day it does not counter anything.
- **Against (the counter):** the specific effect on the one attack pattern it answers. Three upgrades of a day counter the three patterns; the fourth is a helper that eases all three a little (like Unusual Sign-in Alerts on Day 1). Without a pattern's counter, that pattern is played in its harder version.

The passives come from one small catalogue, so they stay balanced across days (the number is per point of load):

| Passive | Effect | Per load |
|---|---|---|
| `max_hp` | more health in the fight | +10 |
| `block_per_turn` | Block at the start of each of your turns | +3 |
| `heal_per_turn` | health back at the start of each of your turns | +2 |
| `attack_bonus` | extra damage on every attack card | +1 |
| `first_draw` | extra cards in your first hand | +1 |
| `first_energy` | extra energy on your first turn | +1 (load 2 only) |

Day 1's four upgrades get passives too (the one change to something already built): Unique Passwords `max_hp` +10, Two-step Sign-in `block_per_turn` +3, Lock After Failed Tries `attack_bonus` +2, Unusual Sign-in Alerts `first_draw` +2. The Upgrade Editor and the shop show both lines: "ALWAYS: ..." and "AGAINST <pattern>: ...". Costs and loads stay as on Day 1 (loads 1, 1, 2, 2; prices 30, 30, 50, 50); the budget of 2 per day number still means no day can bring all four.

Because every day has its own set, the recommended upgrades of a day (from the clues found) are the ones that matter that day, and the earlier days' upgrades are still worth bringing for their passives.

### 2.2 Response: new bullet behaviours (the "kinds")

Existing: `stream` (guesses), `sweep` (a wall with a gap), `aimed` (a line warns, then a key flies). New kinds, each used by more than one day:

| Kind | What it does | Used for |
|---|---|---|
| `split` | a bullet breaks into copies that spread | worm (D2), mass lock (D3) |
| `flicker` | bullets fade in and out of sight | spyware (D2), hidden door (D5) |
| `disguise` | a bullet looks harmless, then turns hostile | trojan (D2), lure (D7) |
| `creep` | the dangerous area grows from a point (tiles lock) | ransomware (D3) |
| `inside` | bullets appear inside the box, not from the edge | insider (D4) |
| `carry` | bullets take small "data" items out of the box; the player guards them | exfiltration (D5) |
| `flood` | very dense, from several sides | DDoS (D6) |
| `bait` | pick-ups that are real or fake: the player must read the label | phishing (D7) |
| `inject` | bullets made of fragments that only hurt when joined | web attack (D8) |

Each also has its **harder version** (the `harsh` numbers: more of it, faster, less warning), applied when the counter upgrade is not equipped.

### 2.3 Monitoring: event types and rule kinds

Existing rule kinds: `range` (a number inside limits), `pattern` (a value matches a shape), `allowed` (a value is in a list). New: `threshold` (a count per minute), `lookup` (a person's role decides what is allowed), `match` (two fields must agree, such as a sender and a link). The log generator, the guided first three logs, the decoys, the hints and the rulebook stay.

### 2.4 Recovery: a catalogue of real repair jobs

Recovery should feel like the repairs people really do on computers and servers, the ones many players have met at home or at work. Each repair is a small game that shows **what broke, what to check, and why the right fix is right**. The jobs fall into families, and each family is one mechanic reused with new content, so the variety is large and the number of new mechanics stays small.

| Family | Real job | The small game | Lesson | Days |
|---|---|---|---|---|
| **Troubleshoot** (read the error, find what changed, choose the action) | **Blue Screen of Death** | A blue screen with its stop code. Panels: *what changed recently* (times of installs and updates), *what the code means*, and a boot menu (restart normally, **Safe Mode**, reinstall Windows, ignore). Safe Mode shows the installed programs: remove the one that arrived just before the crash, then restart. Wrong choices have consequences: restarting normally crashes again; reinstalling would erase the user's files. | A crash usually follows a recent change. Safe Mode starts with only the basics. | 2 |
| | Computer will not start (no boot device) | the recovery menu: choose what to try first | Try the least destructive fix first. | 3 |
| | Website shows an error (500) | read the error log, find the line, roll back the last change or restart the service | Errors name their cause if you read them. | 6, 8 |
| | Disk is full | find the huge hidden archive and the folders that are safe to clean | Do not delete what you cannot explain. | 5 |
| **Backups** (extends the existing cartridge task) | **Restore from a backup** | A timeline of backups with a marker where the infection began. Each has a date, a size and a checked or unchecked flag. Pick the **newest one from before the infection**, test it, restore, and see how many hours of work were lost. | The newest backup may carry the infection; a backup nobody tested may not work; there is always a gap. | 3, 8 (and 1) |
| | The 3-2-1 rule | place the copies: 3 copies, on 2 kinds of storage, 1 of them away from the network | One offline copy is what ransomware cannot reach. | 3 |
| | Get one deleted file back | pick the right earlier version of a file | Versions let you undo a single mistake. | 4 |
| **Rebuild** | **Wipe and rebuild a computer** | put the steps in order: unplug it, save the files you need and scan them, reinstall the system from a clean image, install only approved programs, restore the files, reconnect | When the damage runs deep, rebuilding beats cleaning. | 3 |
| | Replace a failing part | a close-up of a computer's case: take out the failed drive, fan or memory, fit the new one, plug the cables to the right sockets (shapes and numbers, not only colors) | Hardware also fails, and not everything is an attack. | 6 |
| **Network** | Cables to sockets (exists) | match each cable to its socket | | 1, 2, 6 |
| | **Firewall rules** | a table of connections: block the bad address, keep the ones the company needs | Block what is wrong, not everything. | 2, 5, 8 |
| | Power-cycle in order | restart the modem, then the router, then the switch, then the servers | Order matters. | 6 |
| **Accounts and access** | Approve or reject requests (exists) | compare each request with the record | | 1, 4, 7 |
| | Remove sessions (exists) | pick the sign-ins that are not the user's | | 1, 7 |
| | **Permission grid** | who may open what: remove the extra access | Give only the access the job needs. | 3, 4, 5 |
| **Servers and services** | Restart services in order | database first, then the website | Dependencies decide the order. | 6, 8 |
| | Cool the server room | set the fans and close the open door against the temperature gauge | Load makes heat. | 6 |
| **Mail** | **Search and delete** | find the phishing message in every inbox and remove it; write a filter that catches the next one | Remove it everywhere, not only where you saw it. | 7 |
| **Protection** | **Switch panel** | turn on the update, the antivirus, the firewall for each computer; leave the ones already on | Switch protection back on first. | 2, 3, 6 |
| | Scan and quarantine | run the scan, quarantine what is bad, leave the harmless file | Not every warning is a threat. | 2, 7 |
| **Communication** | Choice cards (exists) | whom to tell, and the words of the warning | Say what happened, plainly. | 4, 5, 7 |

**New mechanics to build:** the troubleshoot screen (one scene, different content), the backup timeline (an extension), 3-2-1 placement, order steps (one mechanic reused by rebuild, power-cycle and service restart), hardware close-up, firewall table, permission grid, search and delete, the switch panel. About nine, each reused two or three times. Every one keeps the rule already in the notes: one line on **what broke and why it matters**, and shapes or labels, never color alone. The screens (a blue screen, a backup timeline, a case close-up) are drawn in code, so they need no art from you.

---

## 3. The eight days

For each day: Monitoring, Hardening, Response, Recovery. (Investigation: see the other plan.) "Attack that got through" means the pattern whose counter was not equipped; it becomes one repair.

### Day 1: Credential Abuse (built, the baseline)
- **Monitoring:** a sign-in; rules: hours, company computers, location. Decoys: on call at night, a typo.
- **Hardening:** Unique Passwords, Two-step Sign-in, Lock After Failed Tries, Unusual Sign-in Alerts.
- **Response:** Rapid guesses (`stream`, lockout), One password many accounts (`sweep`, unique), Stolen password (`aimed`, two-step).
- **Recovery:** password, settings, reused passwords, sessions, network, backup, final check.

### Day 2: Malware (first to build)
- **Monitoring:** event = **a program starts**: program, who started it, where it came from, antivirus on or off. Rules: `allowed` (approved programs only), `match` (not from an email attachment), `allowed` (antivirus on). Decoys: IT installing an approved program; the monthly update.
- **Hardening:** counters Block Unknown Programs, Keep Software Updated, Antivirus Always On; helper Scan Attachments.
- **Response:** *Trojan* (`disguise`, allowlist), *Worm* (`split`, updates), *Spyware* (`flicker`, antivirus).
- **Recovery:** *Blue Screen* (Trojan: read the code, Safe Mode, remove the program), update the other laptops (Worm, switch panel), scan and clean (Spyware), then the final check.

### Day 3: Ransomware
- **Monitoring:** event = **files changed**: user, how many files a minute, folder. `threshold` (more than N a minute is not editing); decoys: the backup job, a user moving a folder.
- **Hardening:** counters Limit Shared Folders, Offline Backups, Encrypt Stored Data; helper Filter Suspicious Email.
- **Response:** *Mass lock* (`creep`, segments: it stops spreading), *Ransom demand* (a timed demand bar: the backup makes it empty), *Double extortion* (`carry`, encrypt).
- **Recovery:** the **backup day**: unplug the infected computer (cables), **restore from the right backup** on the timeline (the newest one before the infection), **wipe and rebuild** the infected laptop (order steps), set up backups by the 3-2-1 rule, reopen the shared folders with care (permission grid), then the final check.

### Day 4: Insider Threat
- **Monitoring:** event = **a file is opened**: person, role, folder, time. `lookup` (the rulebook lists who may open what). Decoys: a manager allowed in HR, an on-call night.
- **Hardening:** counters Least Access, Unusual Activity Alerts, Watch Outgoing Data.
- **Response:** *Trusted access* (`inside`, least access shrinks where bullets appear), *Slow copy* (a quiet stream that grows, alerts), *Walk-out* (`carry`, watch outgoing). The enemy does not shoot "friends": the lesson is that the access is real.
- **Recovery:** remove extra access (permission grid), disable the account (confirm), get one deleted file back (versions), a choice card on *accuse or ask*, then the final check.

### Day 5: Data Exfiltration
- **Monitoring:** event = **a transfer**: host, destination, size, time. `allowed` (approved destinations) and `threshold`. Decoy: the big approved backup. Bad: small, steady, unknown destination.
- **Hardening:** counters Watch Outgoing Data, Encrypt Stored Data, Limit Shared Folders; helper Least Access.
- **Response:** *Quiet trickle* (`carry`, small), *Big grab* (one large bullet that needs a block), *Hidden door* (`flicker`).
- **Recovery:** close the door (**firewall rules**), find the hidden archive (disk is full), change keys and passwords (request cards), choose whom to tell and the words (choice cards), then the final check.

### Day 6: DDoS
- **Monitoring:** event = **a traffic sample**: requests a minute, how many sources, which pages, how many logins. `threshold` plus a calendar (the promotion window) in the rulebook. Decoy: a real promotion rush.
- **Hardening:** counters Spread the Load, Limit Requests, Unusual Activity Alerts.
- **Response:** *Flood* (`flood`, spread the load), *Many sources* (`flood` from several sides, limit requests), *Slow drip* (a few bullets that never leave, alerts).
- **Recovery:** set a limit (slider), **power-cycle in order**, restart the services in order, **cool the server room** and **replace a failing fan**, then the final check.

### Day 7: Phishing
- **Monitoring:** event = **an email arrives**: sender domain, link target, subject. `match` (sender and link must agree with the company). Decoy: the real IT password notice and a genuine HR link.
- **Hardening:** counters Filter Suspicious Email, Staff Training, Two-step Sign-in (back from Day 1).
- **Response:** *Lure* (`bait`, filter), *Fake login page* (`disguise`, training: the label becomes readable), *Stolen password* (`aimed`, two-step).
- **Recovery:** reset the passwords of the people who typed one (request cards), **search and delete** the email from every inbox and write the filter, sign the thief out (sessions), write the warning for staff (choice cards), then the final check.

### Day 8: Web Application Attack
- **Monitoring:** event = **a web request**: path, what was typed, answer code. `match` / `allowed` (no code characters in a name field). Decoy: *O'Brien*, our own scanner.
- **Hardening:** counters Check Input, Keep Software Updated, Two-step Sign-in; helper Limit Requests.
- **Response:** *Injection* (`inject`, check input), *Known hole* (`split` through a gap, updates), *Stolen admin* (`aimed`, two-step).
- **Recovery:** the site shows an error (read the log, roll back), **patch** (test), **restore the website from a backup** (timeline), remove the planted file and the new administrator, then the final check.

---

## 4. Optional layer: hardening echoes

What the player bought on one day changes what they see on a later day. It is separate from the threat (each day still has one threat actor).
- **Evidence echo:** with Two-step equipped, a stolen-password sign-in on Day 7 or 8 is shown as *blocked: second step needed*, in LOGIN and in the Monitoring logs.
- **Response echo:** upgrades kept from earlier days keep their effect, so the player starts a new day already a little ready.
- **Cost:** each affected evidence entry needs a variant, and the tests need to cover both. Recommended only after the eight days work without it.

---

## 5. What each day needs built

| Item | Per day | Total for Days 2 to 8 |
|---|---|---|
| Investigation data | about 2,100 words | about 15,000 words |
| Monitoring data (rules, decoys, hints, rulebook) | about 600 words | about 4,200 |
| Dialogue (five "before" scenes) | about 850 words | about 6,000 |
| Hardening: new upgrades (each with a passive and a counter) | 4 new | 28 new, each with an icon |
| Response: three patterns and their harder versions | 3 | 21 patterns; bullet sprites for each |
| Recovery: repairs | 4 to 5 | about 30 small tasks (about 9 new mechanics, each used two or three times) |
| Archive | already written | none |

**Art needed, all drawn by the assistant in code (pixel art, shown as a contact sheet for approval before it is wired in):** the 8 enemy sprites already exist (idle only). Bullet sprites exist only for Credential Abuse, so each day needs about 3 to 5 new ones. 28 new upgrade icons (32 by 32, like the existing ones). Office props for the new Recovery stations only where a task needs one.

**Engineering that every day depends on** (done once, with Day 2):
- `days.json` and the loaders take the data of every day: **Response currently reads `response_day1.json` from a fixed path**, and Recovery its Day 1 file; both need a path per day.
- Tabs relabeled from the data.
- The new rule kinds and event types in the Monitoring generator.
- The new Response kinds (added as each day needs them).
- The new Recovery mechanics (added as each day needs them).
- A **content validator**: every upgrade a day recommends exists; every pattern's counter exists; every pattern that can get through has a repair; every clue is linked; every report answer is solvable. Run in the tests, so eight days of data stay consistent.

---

## 6. Day 2 across all its phases (the first build)

Scope: the Day 2 Investigation; the Day 2 Monitoring shift ("a program starts"); four new upgrades (Block Unknown Programs, Antivirus Always On, Keep Software Updated, Scan Attachments); the Malware enemy with its three patterns (new kinds `disguise`, `split`, `flicker`) and harder versions; four Recovery repairs; five dialogues; and the shared engineering above. Order inside the day: validator and loaders first, then Investigation, Monitoring, Hardening, Response, Recovery, then a full playthrough test like the Day 1 one.

Why Day 2 and not a later one: it is the first day that changes every phase, so it forces the shared engineering to exist, and its new bullet kinds (`split`, `flicker`, `disguise`) are reused by Days 3, 5, 7 and 8.

---

## 7. Decisions

All taken (see the top). What remains is reviewing each day's draft, starting with `docs/day2_malware_draft.md`.
