# Day 7: Phishing (draft for review)

Status: **built in all five phases** (see section 12 for what differs from this plan; the sections above are the plan as approved). Same shape as `day6_ddos_draft.md`, with everything learned on Days 3 to 6 folded in (section 10). Day 7 is the **"check who sent it and where the link really goes"** day: the fake looks like the real thing, so the player learns to inspect a message instead of trusting how it looks, and to tell it from the real IT notice and the real HR link that look just as official.

- **Day title:** *Look Closer*
- **Threat:** Phishing (the Book Archive's threat 7 opens when this Investigation is finished; its five pages exist, it still lacks the ATTACK PATTERNS and RECOMMENDED UPGRADES pages)
- **The question Joshua answers:** *Is this message really from who it says, and where does its link really go?*
- **The story:** At 09:12, 40 people get an email, *"Your password expires today"*, from `c0mpany-it.com` (a zero where the "o" should be). Its link says `portal.company-it.com` but really goes to `c0mpany-it.com/login`. Tessa at the front desk forwards it to IT: *"Is this real?"* Three people clicked (Marta and Ben closed the page); **Ravi Menon** typed his password. At 09:35, Ravi's account is signed in from a place he has never been. Nothing is encrypted and nothing is copied yet: the thief only has one key.
- **People:** Joshua (narrator, helping less), Carla (in person), **Tessa Brandt** (the front desk, by phone, the hook), **Ravi Menon** (Sales, the one who typed a password), **Marta Silva** and **Ben Okoye** (clicked and closed the page: decoys for "who is at fault"), **Hana Ito** (HR: her real benefits email is a decoy).
- **Enemy:** the Phishing sprite that already exists (`phishing_frames.tres`).
- **One threat actor** (standing decision): whoever runs `c0mpany-it.com`. No second actor.

---

## 1. Investigation

**Five clues** (standing decision: 5 from Day 5 on; the older plan said 4). The report is a new form: **inspect two messages**, then fill the blanks (section 1, "The report").

### Tabs (the same seven slots, relabeled)

| Slot | Day 6 | **Day 7** | What it shows |
|---|---|---|---|
| 1 | EMAIL | **EMAIL** | the message, Tessa's forward, the real notices |
| 2 | TRAFFIC | **CLICKS** | who opened the link, who typed something |
| 3 | SOURCES | **PEOPLE** | who got the message, by job |
| 4 | ORDERS | **SIGN-INS** | each account's sign-ins: when, from where |
| 5 | FILES | **FILES** | the message's source (sender, reply address, link) |
| 6 | NETWORK | **NETWORK** | the sender's domain: when it was made, where it lives |
| 7 | SERVERS | **SERVERS** | the mail server, the spam filter, the IT portal |

### The 36 entries (**CLUE** counts, decoy looks like a clue but is harmless, link connects clues by a shared name, noise)

| Tab | Entry | Role | What it is |
|---|---|---|---|
| EMAIL | "Your password expires today", from `c0mpany-it.com`, 09:12, to 40 staff | **CLUE** | The sender's domain has a zero instead of an "o". |
| EMAIL | Tessa's forward, "Is this real?", 09:40 | link (the hook) | |
| EMAIL | "Password policy reminder" from `company-it.com`, last Monday | decoy | The real IT notice: its link goes to the real portal. |
| EMAIL | "Benefits open until Friday" from `hr.company.com` | decoy | A real HR message with a link to the benefits partner. |
| EMAIL | Fire drill on Thursday | noise | |
| CLICKS | Three clicked the link, 09:18 to 09:31, and one typed a password | **CLUE** | |
| CLICKS | Marta clicked at 09:18, closed the page | link | |
| CLICKS | Ben clicked at 09:21, closed the page | link | |
| CLICKS | Ravi clicked at 09:25 and typed his password | link | |
| CLICKS | The real IT notice: 12 clicks, all to the portal | decoy | |
| CLICKS | The benefits link: 18 clicks | decoy | |
| PEOPLE | Ravi Menon (Sales), Marta Silva (Finance), Ben Okoye (Support) | link (3) | |
| PEOPLE | Tessa Brandt (front desk): reported it | link | |
| PEOPLE | The 40 who got it | noise | |
| SIGN-INS | Ravi's account, 09:35, from a new place, far away | **CLUE** | Ten minutes after he typed his password. |
| SIGN-INS | Ravi's usual sign-ins: the office, 08:40 | link (the baseline) | |
| SIGN-INS | The new sign-in and the second code | echo (Day 1 **Two-step Sign-in**) | Equipped: *"The new sign-in asked for a second code and failed."* Not equipped: *"The new sign-in needed only the password, and worked."* |
| SIGN-INS | Marta's and Ben's sign-ins | noise (2) | |
| FILES | The message's source: sender `c0mpany-it.com`, reply to `helpdesk@c0mpany-it.com`, link text `portal.company-it.com`, link goes to `c0mpany-it.com/login` | **CLUE** | The text and the target disagree. |
| FILES | The real IT notice's source | decoy | Sender, reply address and link all `company-it.com`. |
| FILES | The HR message's source | decoy | Link to `benefits-partner.example`, which is on the approved list. |
| FILES | A screenshot of the fake login page | link | |
| FILES | The staff handbook | noise | |
| NETWORK | `c0mpany-it.com` was made 2 days ago and lives in another country | **CLUE** | |
| NETWORK | Traffic to the real IT portal: normal | decoy | |
| NETWORK | Traffic to the benefits partner: normal | decoy | |
| NETWORK | Nightly backup | noise | |
| NETWORK | Staff browsing | noise | |
| SERVERS | The mail server delivered the message to 40 people at 09:12 | link | |
| SERVERS | The spam filter | echo (Day 3 **Filter Suspicious Email**) | Equipped: *"The filter held 5 of the 40 copies."* Not equipped: *"All 40 copies were delivered."* |
| SERVERS | The IT portal: normal | noise | |
| SERVERS | The web gateway | noise | |
| SERVERS | The login server | noise | |

**Total:** 36 entries shown in each version, **5 clues**, 6 decoys, 6 links. All times are 24-hour; no AM or PM.

### Joshua helps less
Joshua says what he noticed and asks the question: *"The link says one address, and goes to another. Which one do you trust?"* A clue is still marked FOUND when investigated.

### The report: inspect two messages (a new form)
Two small **message cards** (drawn in code, side by side over the story, like the two graphs of Day 6) show **Message A** (the real IT notice) and **Message B** (the fake). The player can **click a part to look closer**: the sender shows its whole address, the reply address appears, and the link shows where it really goes. Looking closer is never required, but the text alone looks the same, which is the lesson. The story is a fill-in with five blanks:

> *Message {1} is the fake. Its sender is {2}, its link really goes to {3}, and it wants you to {4}. Ravi {5}.*

| Blank | Right chip | Decoys |
|---|---|---|
| 1 Which | B | A *(its sender, reply address and link all match the company)* |
| 2 Sender | `c0mpany-it.com`, with a zero | `company-it.com` *(that is the real one)*, `hr.company.com` |
| 3 Link | a page on the look-alike domain | the real IT portal, the benefits partner |
| 4 Wants you to | type your password to keep it | read a notice, open a document |
| 5 Ravi | typed his password, and a thief signed in ten minutes later | only closed the page *(that is Marta and Ben)*, did nothing |

Each wrong chip explains itself. Pay as before: 20 per clue, -5 per mistake, 25 for a flawless report; unlocks Book Archive threat 7.

### The notes highlight what matters
Times (gold), amounts (cyan) and names (green) are colored. The name pattern also takes **domains** (`c0mpany-it.com`) so they stand out (a small addition to `NOTE_PATTERN`: a word with a dot and one of the endings `com`, `example`), and the amount pattern takes **people and copies**.

### Links to Hardening
Clues recommend upgrades: the look-alike domain to **Check the Sender**; the link that disagrees with its text to **Staff Training**; Ravi's sign-in to **Security Key**; the message sitting in 40 inboxes to **Report Button**.
Findings copied for Recovery: the five clue summaries, plus Ravi's account.

---

## 2. Monitoring: "an email arrives"

Each log is one incoming email and has four parts: **Sender**, **Link goes to**, **Asks you to**, **Sent**. Three rules, all kinds the engine already has, so **no engine work** (the older plan's `match` is done with `lookup`).

| Rule | Kind | Text | Good | Bad | Why |
|---|---|---|---|---|---|
| Sender | `allowed` | Mail may come only from our own domains and our partners'. | `company-it.com`, `hr.company.com`, `training.company.com` | `c0mpany-it.com`, `cornpany-it.com`, `company-it.net` | A look-alike is not the real thing. |
| Link goes to | `lookup` (the sender decides) | Each sender's links may go only to its own places. | `company-it.com` to the portal; `hr.company.com` to the benefits partner | any sender to a look-alike or a link shortener | A link is only as good as where it goes. |
| Asks you to | `allowed`, with `odd_values` | A message may ask you to read, or to open the portal yourself. | read a notice, open the portal | type your password here, send a code, pay an invoice today | Real notices never ask for a password in a message. |

### Decoys (look odd, follow the rules)
- **The real IT password reminder:** from `company-it.com`, to the portal, "open the portal yourself" (an `odd_value`: it is about passwords, so look twice).
- **The HR benefits message:** `hr.company.com` to `benefits-partner.example`: an outside link, and fine.
- **Our own training test:** from `training.company.com`, a fake on purpose (allowed sender, link back to the training site).

### The threat
Most bad logs come from **`c0mpany-it.com`** and ask to **type your password here** (the values that repeat). Story logs follow the message: 09:12 (it arrives), 09:25 (Ravi clicks).

---

## 3. Hardening: four upgrades (ALWAYS passive + AGAINST counter)

New names (nothing repeats Days 1 to 6; Two-step Sign-in and Filter Suspicious Email come back as echoes only). Loads 1, 1, 2, 2; prices 30, 30, 50, 50.

| Upgrade (id) | Load / price | ALWAYS | AGAINST | Recommended by | Icon (32x32) |
|---|---|---|---|---|---|
| **Check the Sender** (`sender`) | 1 / 30 | **+4 Block** at the start of each of your turns | **Lure:** the fake pick-ups carry a warning mark | the look-alike domain | an envelope with a magnifier over the "@" |
| **Staff Training** (`training`) | 1 / 30 | **Heal 2 HP** at the start of each of your turns | **Fake login page:** the page shows what it is from the start | the link that disagrees with its text | a hat with a shield |
| **Security Key** (`key`) | 2 / 50 | **+15 max HP** | **Stolen password:** the stolen key does only a third of the damage | Ravi's new sign-in | a hardware key on a ring |
| **Report Button** (`reporter`, helper) | 2 / 50 | **+1 Energy on your first turn** | **Every attack:** a longer warning before it starts | the message in 40 inboxes | an envelope with a flag |

### Hardening echoes
Day 1's **Two-step Sign-in** and Day 3's **Filter Suspicious Email** each change one entry (section 1). Both replace a noise entry, so the count stays 36.

---

## 4. Response: the Phishing fight

Enemy: the existing sprite. Player 90 HP; enemy about 125 HP (tuned with the dodge bots). Each pattern has a harder version without its counter, announced as before. Reading comes **before** the bullets, each pattern has a cue in the box, and the strip is only the name while dodging.

| Pattern | Kind | How it plays | Counter | Without it (harder) |
|---|---|---|---|---|
| **Lure** | `bait` *(new)* | Envelopes drift across the box, each with a **word on it**. The fake ones carry the red-flag words (**URGENT, PRIZE, VERIFY, FREE**) and hurt when touched. The real ones carry ordinary words (**MEETING, LUNCH, NOTICE, PAYSLIP**) and give **2 HP** when touched. Reading the word is the game. | Check the Sender: every fake envelope also carries a **warning mark** | More envelopes, faster, and some fakes drift **toward** the heart |
| **Fake login page** | `disguise` | A harmless-looking sign-in box drifts in, then turns into a hook and hurts. | Staff Training: the box is shown **as a hook from the start** | It turns later and closer to you |
| **Stolen password** | `aimed` | A line blinks, then a key flies along it; every few shots a fan of keys. | Security Key: each hit does only **a third** of the damage | Full damage, and less warning |

The helper (Report Button) delays the start of every pattern. Draft lessons (at most two lines): *Lure: "Pretty things in the box. Read them before you touch them."* / *Fake login page: "It looks harmless until you use it."* / *Stolen password: "A key that is not yours still opens the door."*

### New card effect: **Reflect**
**Reflect N** sends the hit back: **each time a hit lands on you during the enemy's turn, the threat takes N damage** (even when Block absorbs it; a dodged hit does not count). It shows as a chip under **your** HP bar (a small mirror mark, the Good color) with a tooltip; it is gone when your next turn starts, like Block, and it stacks. Keyword in `data/keywords.json` (`reflect`): *"Each time you are hit during the enemy's turn, the threat takes this much damage."* Value for balance: worth about 4 damage per point against a pattern that hits 3 to 5 times.

---

## 5. Cards: the 10 new ones (Reflect is on 4 of them)

Same format as before (`cards.json`, `"day": 7`, a line from Carla, 64x44 art in code, the shop NEW filter). **A card text fits three short lines (30 letters at most), a card name about 11 letters.**

| Card | Type | Cost | Text | Price | Art |
|---|---|---|---|---|---|
| Spam Trap | offensive | 1 | Deal 5 damage. Draw 1. | 35 | a mail slot with a net |
| Honeypot | offensive | 2 | Deal 7 damage. Reflect 2. | 45 | a jar of honey with a spark in it |
| Blocklist | offensive | 2 | Deal 8 damage. Expose 1. | 45 | a list with a red line through one name |
| Sinkhole | offensive | 3 | Deal 18 damage. | 60 | a funnel pulling envelopes into a hole |
| Verify | defensive | 1 | Gain 4 Block. Reflect 1. | 35 | a check mark in a shield |
| Hover Check | defensive | 1 | Gain 3 Block. Draw 1. | 35 | a cursor over a link with a pop-up |
| Mail Filter | defensive | 2 | Gain 8 Block. Reflect 2. | 50 | a sieve with envelopes above it |
| Mirror | utility | 1 | Reflect 3. Draw 1. | 35 | a mirror throwing a beam back |
| Spot Check | utility | 0 | Draw 1. Gain 2 Block. | 25 | an eye over a letter |
| Report It | utility | 1 | Heal 2. Draw 1. | 35 | a flag on an envelope |

Mix: 4 offensive, 3 defensive, 3 utility. Reflect is on Honeypot, Verify, Mail Filter and Mirror. (Numbers are a first guess; the balance model in `notes.json` card_balance sets the final ones when I build it.)

---

## 6. Recovery: reset the keys, clean the inboxes, warn the staff

Each attack that got through becomes one repair; the last is the final check. **Every repair is a hands-on mini-game that teaches the fix step by step with pictures** (the standing rule since Day 6): the thing is drawn, the player works on it, the next step glows, a wrong move bounces back with one plain reason.

| Attack that got through | Repair (component id) | Mechanic | What the player does |
|---|---|---|---|
| Lure | **Clean every inbox, block the sender, warn the staff** (`mail`) | **new: three inboxes and a rule builder** (`MailCleanup`, three stages) | See section 6a. |
| Fake login page | **Reset the passwords of the people who typed one** (`password`) | the Day 1 password task, **new content** | Ravi's account: build a long passphrase from word tiles (tiles with his name or birthday bounce off), then switch on the second step. |
| Stolen password | **Sign the thief out** (`sessions`) | the Day 1 sessions task, **new content** | Ravi's list of signed-in devices: sign out the unknown one (09:35, far away), keep his laptop and phone. |
| (final check) | **Back to work** (`file_server`) | test (FileServerRepair, 3 checks) | No copy is left in any inbox, Ravi's password is new, and the thief's device is signed out. |

### 6a. Clean every inbox (`MailCleanup`, three stages)
- **Stage 1, the inboxes:** three inboxes (Marta, Ben, Ravi), three or four messages each. The player ticks every copy of the fake (same sender domain, same subject) and presses DELETE. The real IT reminder and the HR message sit in the same inboxes and look just as official: deleting one bounces back with its reason. Pressing DELETE with a copy left behind says where one is hiding.
- **Stage 2, the filter rule:** a small rule builder, *Block mail where [what] is [this]*: three choices of **what** (the sender's domain, the subject, the link text) and three of **this** (`c0mpany-it.com`, `company-it.com`, "password"). Blocking `company-it.com` would block the real IT; blocking the word "password" would block the real reminder too. Only *the sender's domain* is `c0mpany-it.com` is right.
- **Stage 3, the warning:** choose the message that goes to the staff from three cards: calm and specific (what the fake looked like, what to check, where to report it), scary and vague (*"Hackers are everywhere!"*), or none. Only the first is right; the others explain why.
- **Lesson line:** *Remove it from every inbox, block what you checked (not a guess), and tell the staff what to look for.*

The Day 7 room uses 4 repairs and the final check, so 4 machines are used (mail: monitoring; password: access; sessions: monitoring; the final check: servers).

---

## 7. Dialogue (five scenes; beats, the lines are written when built)

1. **Before Investigation.** Tessa (front desk) by phone: *"Is this real? It says my password expires today."* Choice: *Did you click it?* (no, she asked first: Joshua: "Good habit.") / *Who else got it?* (40 people, she thinks). Joshua: *5 clues should be enough.*
2. **Before Monitoring.** Carla in person: *"A fake does not need to be clever. It needs to look official and be in a hurry."* Choice: *How do I tell a fake from the real IT notice?* (the sender's domain and where the link goes, never how it looks) / *Can't we block every email with a link?* (HR and IT send links too).
3. **Before Hardening.** Carla: check the sender, train the staff, a key you hold. Introduces **Reflect** (*"Send the hit back."*).
4. **Before Response.** It does not break in. It offers you something. Three tricks: **lure**, **fake login page**, **stolen password**. Choice: *What is it doing?* / *Are we ready?*
5. **Before Recovery.** Carla: *"Stopped is not fixed. Forty inboxes still hold it, and Ravi's password is out there."* Choice: *What do we fix first?* (the inboxes, the password, the sign-in) / *Do we tell the staff?* (yes, calmly, with what to check).

---

## 8. Art, made in code

| Asset | Size | Description |
|---|---|---|
| 4 upgrade icons | 32 x 32 | see section 3 |
| 10 card arts | 64 x 44 | see section 5; same dithered navy background |
| Bullet: envelope | 11 x 8 | the lure (an envelope; its word is drawn on it in code) |
| Bullet: sign-in box | 9 x 9 | the fake login page, harmless-looking (a small form) |
| Bullet: hook | 9 x 9 | the same box once it has turned (a hook through it) |
| Bullet: key | 7 x 5 | the stolen password (a small gold key) |
| Marks | 7 x 8 | the Reflect mirror; the warning mark on a fake envelope |
| The two message cards | in code | a mail header (From, Reply-to, subject), a body with a link; clickable parts |
| Recovery pictures | in code | three inboxes with checkboxes, the rule builder, the warning cards |
| Enemy | exists | `phishing_frames.tres` |

Before anything is wired in I show a contact sheet (all sprites enlarged).

---

## 9. What gets built

1. **Monitoring:** `data/scenarios/day 7/monitoring.json` (the engine is ready: `allowed` with `odd_values`, `lookup`).
2. **Investigation:** `data/scenarios/day 7/investigation.json` (tabs, 36 entries, echoes, 5 clues, the inspect report); a small **`MessageCard`** control (drawn in code, clickable parts) shown by the report screen when the data has `messages`, like the `graphs` of Day 6; the notes' domain pattern; Joshua's shorter monologues.
3. **Hardening and cards:** four upgrades with passives (all old keys), icons, shop lines; 10 cards with art; the **Reflect** effect (`response.gd`, `keywords.json`, a chip and a mark in `hp_bar.gd`, the validator's effect keys).
4. **Response:** one new arena kind, `bait` (envelopes with words; fakes hurt, real ones heal 2, through one new signal `healed(amount)`); `disguise` and `aimed` reused (the `aimed` counter becomes data: a pattern's `reduced_damage` applies when its own counter is equipped, instead of the hard-coded Two-step); `response_day7.json`; the dodge bots taught to avoid the fake envelopes and take the real ones; tuning (target as before: with the counter an average bot takes about 0 to 1, without it about 4 to 7).
5. **Recovery:** one new task, `MailCleanup` (`mail`, one script and one scene, three stages), and the Day 1 `password` and `sessions` tasks with new content; `day7_recovery.json`; register `mail` in `RecoveryData`; the equipment groups. The pictures are drawn in code.
6. **Dialogues, archive, tutorials:** five scenes; the Phishing ATTACK PATTERNS and RECOMMENDED UPGRADES pages; `Tutorial.maybe_show_new` keys (see below).
7. **Validator and tests:** the day validator, the new arena kind, Reflect, the message cards report, the mail cleanup, the Day 7 playthrough; all earlier suites re-run.

Order: Monitoring, Investigation (with the message cards), Hardening and cards, Response, Recovery, dialogues, playthrough, report.

---

## 10. Carried over from Days 3 to 6 (so nothing is missed)

**A. Objectives** (`days.json`, at most 80 letters; Hardening at most 29)
| Phase | `objective` | Second step |
|---|---|---|
| Investigation | INVESTIGATE AND FIND CLUES | `objective_report`: SPOT WHAT WAS FAKE IN THE MESSAGE |
| Monitoring | READ EACH EMAIL AND REPORT THE FAKES | |
| Hardening | HARDEN AGAINST FAKE EMAIL (25) | |
| Response | READ BEFORE YOU TOUCH: PLAY CARDS, THEN DODGE | |
| Recovery | RESET THE KEYS, CLEAN THE INBOXES, WARN THE STAFF | |

**B. Learning and story.** Story is the five dialogues. Learning, one line per phase: Investigation *check who sent it and where the link really goes before you click*; Monitoring *a link is only as good as where it goes, not what it says*; Hardening *filter, train, and ask for a second proof*; Response *a pretty thing in your path can be a trap: read it first*; Recovery *remove it from every inbox, reset the key, and tell the staff what to look for*.

**C. Tutorials** (`Tutorial.maybe_show_new`, named by the day's data): `response_day7` (Reflect is a chip under *your* bar; the envelopes carry words, read them), `investigation_inspect` (click a part of a message to look closer), `recovery_mailbox` (the inboxes, the rule and the warning).

**D. Details that bit before:** card text at most 30 letters and a name about 11 letters; no AM or PM (the validator rejects it); a Hardening objective at most 29 letters; a recommended clue must be a real clue (`is_clue`); a hint may not use the words *suspicious, normal, allowed, rule, report, bad*; test scripts need `tutorial_seen` filled or the overlay pauses the game; a test script cannot name a class that uses an autoload (use `load()`); choices in an AccountAction wrap after four; a machine for every repair (the room has 9); the Settings colors (`GameColors`) are used for anything new that is good, bad, block or highlight.

**E. Keywords** (`data/keywords.json`): `reflect` (the Good color).

---

## 11. What I want you to check

1. **The story:** a look-alike domain, a link that disagrees with its text, three clicks, one typed password, a sign-in ten minutes later. Right tone? Is Ravi the right person to be at fault, or should nobody be blamed?
2. **The inspect report:** two message cards you can click to look closer, plus five blanks (one new small control, `MessageCard`). Right size, or do you want the cards only?
3. **Reflect:** *each hit that lands on you sends N damage back to the threat*, a chip under your bar. Fair, and different enough from Block and Cap?
4. **The Lure:** envelopes with words on them, fakes hurt and real ones heal 2, so the player has to **read**. Fun, or too much reading in the middle of dodging?
5. **Recovery:** one new three-stage task (inboxes, filter rule, staff warning) and two reused ones with new content. Anything to add or cut? (The older plan also had a phishing test email for the staff; it is left out.)
6. **Anything else** before I build it.

---

## 12. As built: what differs from the plan

- **The report's exhibits** are under `report.cards` (a list of message entries: label, from_name, from_addr, reply_to, link_text, link_target, ask); the report screen shows them like the `graphs` of Day 6, in the same row over the story. The helper lines of the report stay under `report.messages` as always. A card starts closed (the sender shows `<...>`, the reply address `(hidden)`); clicking the sender, the reply address or the link shows the whole address, or where the link really goes, with the words MATCHES or DOES NOT MATCH (never color alone).
- **The notes** only needed the units *copies, people, clicks, inboxes*: a domain such as `c0mpany-it.com` was already colored as a name.
- **Monitoring needed one small fix, no new kind.** A bad log may break the sender (a look-alike domain) and then its link: `LogGenerator._break_lookup` now accepts a "by" part that is not in the table. The time is an `info` rule (Day 5): the rulebook says the clock decides nothing.
- **Lure:** the envelope's word is drawn on it in code. Real envelopes heal 2 HP through a new signal, `BulletArena.healed`, and are gone when touched; fakes carry URGENT, PRIZE, VERIFY or FREE and use the normal hit. With Check the Sender a fake also carries a red warning mark. The harder version has more fakes, faster, and most of them aim at the heart. The dodge bots cannot read, so their numbers are only about the fakes; the reading is the human's game.
- **The aimed kind lost its hard-coded Two-step:** a pattern whose own counter is equipped now takes its `reduced_damage` (Day 1 still reads `twostep`, Day 7 reads `key`), with its own `hit_note`.
- **Reflect** is sent back after the hit has been taken (and after Block): a hit that would take the threat to 0 contains it at once. The chip is the mirror mark, in the Good color.
- **Recovery:** the password and sessions tasks are the Day 1 scenes with Ravi's content (the HR record, his phone ending in 58, two unknown devices at 09:35 and 09:50). `MailCleanup` is one script: three inboxes with a fake copy in each and one more in Ravi's archive, the filter rule (what: sender's domain, subject, link text; this: `c0mpany-it.com`, `company-it.com`, "password"), and three warning cards. The Day 7 room uses 4 machines.
- **Tests:** `validate_days.gd` (4912 checks), a Reflect / Lure / aimed-counter test, an Investigation report test (message A named as the fake), a Recovery test of the three tasks, the Day 7 playthrough (including that all four repairs get a machine), and the bot tuning.
