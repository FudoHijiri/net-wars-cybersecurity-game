# Day-by-day variations: Investigation (plan)

Status: **plan only, nothing built.** Decisions taken are in section 9. The other four phases are planned together with this one in `docs/day_variations_gameplay_plan.md`.

Goal: every day has its own threat (the order of the Book Archive), and the Investigation of that day teaches **how to recognize that threat from evidence**, not just a new story over the same puzzle.

---

## 1. What Day 1 is today

Data: `data/scenarios/day 1/investigation.json`, loaded by `GameState.set_day()` into `GameState.scenario`.

| Part | Day 1 | Notes |
|---|---|---|
| Tabs | 7 apps: EMAIL, LOGS, COMPUTERS, LOGIN, FILES, NETWORK, SERVERS | **The 7 buttons and their labels are fixed in `Investigation.tscn`.** |
| Entries | 36 (5 or 6 per app), each with cells, title, detail, summary, a monologue of 1 or 2 lines, and `entities` | about 2,100 words |
| Clues | 4, one in each of EMAIL, LOGIN, FILES, NETWORK (`clues_required: 4`) | the rest is normal noise that looks a little odd |
| Links | `entities` (user, device, ip, host, file) connect entries | `GameState.related_entries()` already finds entries that share one, so a player can follow a thread |
| Report | a sentence with 4 blanks and 8 words (4 right, 4 decoys with a reason each) | `report.answers`, `report.chips` |
| Pay | 20 per clue, -5 per report mistake, 25 bonus for a first-try report | `finish` |

What depends on the Investigation (so a new day must keep these working):
- **Book Archive:** threat N opens when Day N's Investigation is finished.
- **Hardening:** an upgrade is *recommended* when the player found a clue it answers (`upgrades.json` lists clue ids).
- **Recovery:** the evidence and the one-line summaries of the clues found are copied into the save (`phase_findings`) and shown later.
- **Monitoring:** the same threat entity (the unknown computer) turns up in the shift's logs.

What Day 1 does well (keep): one clear question, evidence in several places that agree, noise that explains itself, and a report that makes you check each word against a clue.

---

## 2. The idea: each threat asks a different question

The Investigation's puzzle is the same; the **question the player must answer** changes. That is what makes each day feel new and teaches the threat.

| Day | Threat | The question Joshua has to answer | Where the answer lives |
|---|---|---|---|
| 1 | Credential Abuse | Who is *really* signing in? | LOGIN, EMAIL, FILES, NETWORK |
| 2 | Malware | What is running here that nobody installed? | COMPUTERS, EMAIL, LOGS, NETWORK |
| 3 | Ransomware | How did it start, and how far did it spread? | EMAIL, FILES, SERVERS, LOGS |
| 4 | Insider Threat | Is this access real but wrong for this person's job? | FILES, LOGIN, NETWORK, EMAIL |
| 5 | Data Exfiltration | What left, through which door, and when? | NETWORK, SERVERS, FILES, LOGS |
| 6 | DDoS | Is this an attack, or just a lot of real customers? | NETWORK, SERVERS, EMAIL, LOGS |
| 7 | Phishing | Who clicked, who typed a password, and where did it lead? | EMAIL, LOGS, LOGIN, COMPUTERS |
| 8 | Web Application Attack | What did someone type into our website that it should have refused? | LOGS (web), SERVERS, FILES, LOGIN |

---

## 3. The knobs (what can change from day to day)

1. **Which tabs matter, and what they are called.** Same 7 slots, relabeled and refilled per day (for example COMPUTERS becomes ENDPOINTS on the malware day, LOGS becomes WEB LOGS on Day 8). Needs a small scene change: tab text from the data.
2. **How many clues, and what kind.** Direct (a login from another country), indirect (a computer that did something it never does), and **absence** (a backup that is *intact*, which is itself a finding).
3. **The decoys, which are the lesson.** Each day has look-alikes that are harmless (a promotion that really did bring a rush of customers; a manager who is allowed in the HR folder; our own security scanner) and a clue that looks boring. Decoys teach the difference between a symptom and a cause.
4. **How deep the cross-checking goes.** Day 1: each clue is visible alone. Later days: a clue is only convincing next to another (a big upload is fine at 02:00 only if it is the approved backup).
5. **The report form.** Not always "fill 4 blanks": fill blanks (Day 1), put events in **order** (Ransomware), choose **what we know vs. what we do not** (Insider), compare two graphs (DDoS), inspect a message's **sender, reply-to and link** (Phishing).
6. **How much Joshua helps.** The monologue after INVESTIGATE gets shorter and asks more of the player as days go on. Day 1 says "that's a real clue"; Day 5 says what it noticed and lets the player decide.
7. **Continuity.** The same company, people and attacker across days, and (optional) the player's earlier hardening changes the evidence (see 5).

### Difficulty ramp (decided: 4 clues on Days 1 to 4, 5 clues from Day 5)

| Days | Entries | Clues | Decoys that look like clues | Joshua's help | Report |
|---|---|---|---|---|---|
| 1 | 36 | 4 | 0 (noise only) | says it is a clue | 4 blanks |
| 2 to 3 | 36 to 40 | 4 | 2 | says what he noticed | 4 blanks, or an order |
| 4 | 40 | 4 | 3 | gives the fact, not the verdict | a form of its own |
| 5 to 8 | 44 | 5 | 3 to 4 | gives the fact only | a form of its own, 5 parts |

(The day outlines in section 4 list four clues. For Days 5 to 8 a fifth clue is added when each day is drafted.)

The archive and the hints stay plain-worded (the style already decided: whole natural sentences, a few words per fact).

---

## 4. The eight days, Investigation only

For each day: the story hook, the evidence, the decoys, the report, what the player should walk away with, and which upgrade the evidence points to (so Hardening can recommend it). The upgrades marked *(new)* do not exist yet: only the four Credential Abuse upgrades do.

### Day 1: Credential Abuse (built)
Anna's account signs in from Germany at 02:43; the payroll file is copied; 48 MB leaves. Report: who, from where, what, to where. Points to Two-step Sign-in, Unique Passwords, Unusual Sign-in Alerts.

### Day 2: Malware
- **Hook:** Ben's laptop is slow and shows pop-ups. He also "installed a free tool".
- **Clues (4):** an email with `invoice.zip` that Ben opened (EMAIL); `FreeGameTools.exe` installed, not on the approved list (COMPUTERS); the antivirus turned itself off five minutes later (LOGS); the laptop contacts an outside address every minute (NETWORK).
- **Decoys:** it is slow because of a Windows update (real); IT installed an approved program the same day; a large download that is just the update.
- **Report:** "Ben opened {1}. It installed {2}, turned off {3}, and then talked to {4}." Chips include the real attachment and the legitimate update.
- **Lesson:** malware arrives through a click and hides; one sign is not proof, several together are.
- **Points to:** *(new)* Block Unknown Programs, *(new)* Scan Attachments, *(new)* Antivirus Always On.

### Day 3: Ransomware
- **Hook:** Finance cannot open its files; a message demands payment.
- **Clues (4):** a link in an email clicked on one laptop (EMAIL); that laptop's files renamed first (FILES); hundreds of files renamed in three minutes across a shared folder (LOGS); **last night's backup is intact** (SERVERS, an "absence of damage" clue).
- **Decoys:** the nightly backup job also renames files; a user moving a big folder; an archive job.
- **Report form: put the events in order** (click, first file locked, spread, ransom note). New report mode.
- **Lesson:** ransomware spreads fast, and a backup that was kept apart is what saves you.
- **Points to:** *(new)* Offline Backups, *(new)* Limit Shared Folders, Scan Attachments.

### Day 4: Insider Threat
- **Hook:** HR says an engineer is leaving. Odd file access follows.
- **Clues (4):** opens the salary folder, which is not their job (FILES); copies 2 GB to a personal cloud the night before leaving (NETWORK); forwards the customer list to a personal address (EMAIL); the account still had access after a role change (LOGIN/permissions).
- **Decoys:** the HR manager *is* allowed in that folder; a colleague working late with a valid sign-in; an accidental case (a file sent to the wrong person).
- **Report form: "what we know / what we do not"**: the player marks facts as known or unknown. The intent cannot be known from logs: the lesson is *ask before you accuse* (an email reply from HR is the only way to unlock that clue).
- **Lesson:** the sign-ins are real; look at what the person does, and give people only the access their job needs.
- **Points to:** *(new)* Least Access, *(new)* Unusual Activity Alerts.

### Day 5: Data Exfiltration
- **Hook:** customer data is seen for sale.
- **Clues (4):** a database export at 03:10 (SERVERS); a large archive created in a temp folder (FILES); many small transfers to an unfamiliar host, not one big one (NETWORK); a scheduled job nobody remembers creating (LOGS).
- **Decoys:** the approved nightly backup to the cloud is *bigger* than the theft; that is the point: **normal is a baseline, not a size**.
- **Report:** what left, how, to where, and when it started.
- **Lesson:** compare against what is normal for that host; small and steady can be worse than big and expected.
- **Points to:** *(new)* Watch Outgoing Data, *(new)* Encrypt Stored Data.

### Day 6: DDoS
- **Hook:** the website is down during lunch.
- **Clues (4):** tens of thousands of requests a minute from thousands of addresses (NETWORK); the server's processor at maximum (SERVERS); all of them ask for the same page with the same browser name (LOGS); none of them log in or buy anything (LOGS).
- **Decoys:** Marketing sent a promotion that morning (EMAIL): a **real** rush of customers who do buy things. The attack began *before* the promotion.
- **Report form: compare two traffic graphs** (a real rush and the attack) and say which is which, then fill the reasons.
- **Lesson:** a lot of traffic is not proof; look at who it is and what they do.
- **Points to:** *(new)* Limit Requests, *(new)* Spread the Load.

### Day 7: Phishing
- **Hook:** several people got "your password expires today".
- **Clues (4):** the sender's domain is a look-alike (`c0mpany-it.com`) (EMAIL); the link goes somewhere other than the text says (EMAIL); three people clicked, one typed a password (LOGS); a new sign-in for that account ten minutes later from another place (LOGIN).
- **Decoys:** the real IT password notice (the Day 1 email) and a genuine HR message with a link.
- **Report form: inspect the message.** The detail view shows sender, reply-to and link target side by side; the report asks which parts were fake.
- **Lesson:** check who sent it and where the link really goes, before you click.
- **Points to:** Two-step Sign-in (the Day 1 upgrade returns), *(new)* Filter Suspicious Email.

### Day 8: Web Application Attack
- **Hook:** the customer portal shows strange errors and a few odd orders.
- **Clues (4):** requests containing `' OR 1=1 --` in the login form (WEB LOGS); a spike in database errors (SERVERS); a new file in the website's folder that nobody uploaded (FILES); a new administrator account (LOGIN).
- **Decoys:** a customer named *O'Brien* (an apostrophe is not an attack); our own security team's approved scanner.
- **Report:** what was typed, what it did, what it left behind.
- **Lesson:** a website must check what people type, and be kept up to date.
- **Points to:** *(new)* Check Input, *(new)* Keep Software Updated.

---

## 5. Continuity across days (optional, recommended)

- **Same company and people:** Anna, Ben, Carla, Dana and others recur. A person who was a victim on Day 1 can be the careful one on Day 7.
- **A recurring attacker:** the unknown computer `7F3A` appears again on later days (a different threat, the same group), so the player recognizes it and it escalates.
- **The player's hardening echoes:** if Two-step Sign-in was equipped, the Day 7 sign-in after a phish shows "blocked: second step needed". The evidence changes, and the player sees that the choice mattered. Costs more authoring (each affected entry needs a variant) and is where an upgrade starts to feel real.

---

## 6. What has to be built

**Data (per day):** one `data/scenarios/day N/investigation.json` in the existing schema, registered in `days.json`. New optional keys:
- `tabs`: the label of each of the 7 slots, and which are hidden if unused.
- `clues_required`: already there; 4 to 5.
- `entries[].kind`: `clue`, `decoy` or `noise` (for tests only; the game still uses `is_clue`).
- `report.mode`: `blanks` (today), `order`, `known_unknown`, `compare`, `inspect`.

**Code:**
- Tab labels and visibility from data (a small change in `investigation.gd` and the scene).
- Report modes `order`, `known_unknown`, `compare`, `inspect`: each is a new small screen or a variation of `report_screen.gd` (the largest piece of work).
- An `inspect` detail view for emails (Day 7).
- Pay, finish comments and the archive unlock already follow the data.

**Tests (so 8 days of content stay correct):**
- every day's report is solvable: each answer id exists, each chip has a reason if it is a decoy;
- every clue is linked by `entities` to at least one other entry;
- no `summary` or `monologue` gives the answer to a different entry; no hint says the verdict;
- every app has entries; word budget per day; text fits the boxes (the 6 px font);
- the day's clues match what `upgrades.json` recommends.

**Writing:** about 2,100 words per day, 8 days: about 17,000 words, in the balanced style already agreed (whole natural sentences, few words per fact).

---

## 7. Proposed order of work

1. **Schema and tests** (tab labels, `kind`, validator), no new content.
2. **Day 2 (Malware) as a full vertical slice through all five phases**, so the pattern is proven before the others: Investigation, then what Monitoring, Hardening, Response and Recovery need for it.
3. **Day 3 (Ransomware)** with the `order` report mode.
4. **Days 4 to 8** one at a time, each adding its own report form.
5. **Continuity pass:** recurring attacker, hardening echoes.

---

## 8. Hand-off to the other phase plans

Each threat also needs, in the next plans: its **Monitoring** rules and decoys (what the shift watches for that day), its **Hardening** upgrades (listed above as *(new)*, each with a clue that recommends it and a pattern it counters), its **Response** attack patterns and enemy, and its **Recovery** repairs (the components in `day1_recovery.json` are Credential Abuse only). The Day 1 data is the template for all of them.

---

## 9. Decisions

**Taken**
1. **Tabs:** the same seven, relabeled per day.
2. **Clues:** 4 on Days 1 to 4, 5 from Day 5.
3. **Threat actor:** one per day (so no attacker who returns on later days).
4. **Order of work:** first plan what each day changes in every phase (`day_variations_gameplay_plan.md`), then build Day 2 across all its phases.
5. **Writing:** each day is drafted for review one at a time.

**Taken later**
- **Report forms:** yes: order the events (Day 3), know / do not know (Day 4), compare (Day 6), inspect a message (Day 7). Days 1, 2, 5 and 8 fill blanks (5 on Days 5 and 8).
- **Hardening echoes:** yes, added after the eight days work without them. The engine support (an entry that appears only if an earlier upgrade was equipped) is built with Day 2; the content is a later pass.
- **Art:** made by the assistant in code.
