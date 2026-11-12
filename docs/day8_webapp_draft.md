# Day 8: Web Application Attack (draft for review)

Status: **built in all five phases** (see section 12 for what differs from this plan; the sections above are the plan as approved). Same shape as `day7_phishing_draft.md`, with everything learned on Days 3 to 7 folded in (section 10). Day 8 is the last day and the **"a website must check what people type"** day: the sign-in form builds its database question by gluing in whatever a visitor typed, so a visitor who types code can make the database answer anything. The lesson is also about keeping software up to date, and it closes the story with what the player has learned over the eight days.

- **Day title:** *Typed In*
- **Threat:** Web Application Attack (the Book Archive's threat 8 opens when this Investigation is finished; its five pages exist, it still lacks the ATTACK PATTERNS and RECOMMENDED UPGRADES pages)
- **The question Joshua answers:** *What did they type, what did the website do with it, and what did they leave behind?*
- **The story:** The customer portal shows strange errors, and two orders nobody placed. At 14:02 a single address (`198.51.100.80`) typed `' OR 1=1 --` into the login form 40 times. The form glues what is typed into its database question, so the database answered "everything": 2,400 rows. The site runs ShopKit 2.1, fourteen months old; the fix (2.4) has been waiting. At 14:20 a file nobody uploaded, `help.php`, appeared in the uploads folder, and at 14:25 a new administrator, `support_admin`, was made. At 14:31 that account signed in, from the same address.
- **People:** Joshua (narrator, helping less), Carla (in person), **Sam Kowalski** (the web developer, by phone, the hook), **Ciaran O'Brien** (a customer whose name has an apostrophe: a decoy, and the answer to *"is an apostrophe an attack?"*), and the **security team's scanner** (a decoy: it tests the site on purpose, every Tuesday, with code in its requests).
- **Enemy:** the Web Application Attack sprite that already exists (`web_app_attack_frames.tres`).
- **One threat actor** (standing decision): whoever owns `198.51.100.80`. No second actor.

---

## 1. Investigation

**Five clues** (standing decision: 5 from Day 5 on). The report is the plain fill-in again, with two small **query cards** as the exhibit (section 1, "The report"): one new small control, like the graphs of Day 6 and the messages of Day 7.

### Tabs (the same seven slots, relabeled)

| Slot | Day 7 | **Day 8** | What it shows |
|---|---|---|---|
| 1 | EMAIL | **EMAIL** | Sam's report, a customer, the scan schedule |
| 2 | CLICKS | **WEB LOGS** | requests: when, which page, what was typed, the answer |
| 3 | PEOPLE | **ACCOUNTS** | the administrators and some customers |
| 4 | SIGN-INS | **SIGN-INS** | administrator sign-ins: when, from where |
| 5 | FILES | **FILES** | the website's folders: what is in them, since when |
| 6 | NETWORK | **NETWORK** | which addresses talk to the site |
| 7 | SERVERS | **SERVERS** | web-01, the database, the framework version |

### The 36 entries (**CLUE** counts, decoy looks like a clue but is harmless, link connects clues by a shared name, noise)

| Tab | Entry | Role | What it is |
|---|---|---|---|
| EMAIL | "Odd errors and two odd orders" (Sam, 14:30) | link (the hook) | |
| EMAIL | "Is my name a problem?" (Ciaran O'Brien) | decoy | He types an apostrophe in his name and worries it breaks the site. It does not. |
| EMAIL | "Security scan on Tuesday" (Carla's team, today 13:15) | decoy | The approved scanner tests the site every Tuesday. |
| EMAIL | "Framework update next month" (IT) | link | The update to ShopKit 2.4 is planned, not done. |
| EMAIL | Weekly newsletter | noise | |
| WEB LOGS | `' OR 1=1 --` typed into the login form 40 times, from 14:02 | **CLUE** | One address, one string of code. |
| WEB LOGS | The request limit | echo (Day 6 **Limit Requests**) | Equipped: *"The limit stopped the address after 40 requests."* Not equipped: *"4,000 more requests followed, nothing stopped them."* |
| WEB LOGS | Ciaran O'Brien logs in, 10:20 | decoy | One apostrophe in a name, a page shown, nothing odd. |
| WEB LOGS | The scanner's test strings, 13:15 | decoy | Code in its requests, from `scanner.company.com`. Approved. |
| WEB LOGS | A search for "blue shirt" | noise | |
| WEB LOGS | Static files | noise | |
| ACCOUNTS | `support_admin`, made 14:25, administrator | **CLUE** | Nobody asked for it. |
| ACCOUNTS | Sam Kowalski, administrator | link (the baseline) | |
| ACCOUNTS | Carla Patel, administrator | link | |
| ACCOUNTS | Ciaran O'Brien, customer | decoy | A normal customer. |
| ACCOUNTS | 2,400 customer accounts | noise | |
| SIGN-INS | `support_admin` signed in at 14:31 from a new place | link | |
| SIGN-INS | The new sign-in and the security key | echo (Day 7 **Security Key**) | Equipped: *"It needed a security key and failed."* Not equipped: *"The password was enough, and it worked."* |
| SIGN-INS | Sam's usual sign-ins: the office, 08:50 | link (the baseline) | |
| SIGN-INS | Carla's sign-ins | noise | |
| SIGN-INS | Customers' sign-ins | noise | |
| FILES | `help.php`, made 14:20 in the uploads folder | **CLUE** | Nobody uploaded it. |
| FILES | `scanner_report.pdf` | decoy | The scanner's own report, from last Tuesday. |
| FILES | The site's backup of 14:00 | link | The last good copy. |
| FILES | `logo.png` | noise | |
| FILES | `robots.txt` | noise | |
| NETWORK | One address, `198.51.100.80`: the 40 code requests at 14:02 and the sign-in at 14:31 | **CLUE** | The same address, 29 minutes apart. |
| NETWORK | The scanner, 13:15 | decoy | An approved address. |
| NETWORK | Customer traffic | noise | |
| NETWORK | Nightly backup | noise | |
| NETWORK | Staff browsing | noise | |
| SERVERS | db-01: database errors from 2 to 600 an hour at 14:00 | **CLUE** | |
| SERVERS | web-01 runs ShopKit 2.1, fourteen months old | link | The fix, 2.4, was never installed. |
| SERVERS | The login form builds its question by gluing the typed text in | link | Shown as the two lines of code. |
| SERVERS | The web gateway | noise | |
| SERVERS | The mail server | noise | |

**Total:** 36 entries shown in each version, **5 clues**, 6 decoys, 6 links. All times are 24-hour; no AM or PM.

### Joshua helps less
Joshua says what he noticed and asks the question: *"The same line of code, forty times, from one address. A customer types a name. Who types that?"* A clue is still marked FOUND when investigated.

### The report: what was typed, what it did, what it left (and two query cards)
Two small **query cards** (drawn in code, side by side over the story, like Day 7's messages) show **what the website asks the database** when a visitor types *Maria* and when a visitor types `' OR 1=1 --`. A card starts with the typed text and the question built from it; **clicking RUN** shows the answer: *1 row* for Maria, *2,400 rows* for the code. The player sees why the code works: the typed text became part of the question. The story is a fill-in with five blanks:

> *At {1}, someone typed {2} into the {3}. The website {4}, and the attacker left {5} behind.*

| Blank | Right chip | Decoys |
|---|---|---|
| 1 When | 14:02 | 13:15 *(the scanner's test)*, 14:25 *(when the new administrator was made)* |
| 2 Typed | `' OR 1=1 --`, a piece of code | O'Brien, a customer's name *(an apostrophe in a name is normal)*, a search for blue shirt |
| 3 Into | the login form | the search box, the order form |
| 4 The website | put it into its database question, and the database ran it | refused it and showed an error page, ignored it |
| 5 Left behind | a planted file and a new administrator | nothing, a copy of the customer list |

Each wrong chip explains itself. Pay as before: 20 per clue, -5 per mistake, 25 for a flawless report; unlocks Book Archive threat 8.

### The notes highlight what matters
Times (gold), amounts (cyan), names, files, domains and addresses (green) are colored as before. The name pattern also takes a word ending in `.php` (`help.php`); the amount pattern takes *errors* and *rows*.

### Links to Hardening
Clues recommend upgrades: the code in the login form to **Check Input**; the old framework to **Patch the Framework**; the new administrator to **Admin Lockdown**; the burst of requests to **Web Firewall**.
Findings copied for Recovery: the five clue summaries, plus the account `support_admin`.

---

## 2. Monitoring: "a web request"

Each log is one request to the portal and has four parts: **Sent by**, **Typed in**, **What was typed**, **Answer**. Four rules, so the engine needs **one small addition** (section 9): an `allowed` rule may have an `exempt` part, like the `threshold` rules do (the scanner may type code).

| Rule | Kind | Text | Good | Bad | Why |
|---|---|---|---|---|---|
| Sent by | `info` (Day 5) | Who sends it does not decide. | a customer, our scanner, a search engine | (never a rule) | The scanner is ours; a customer can be an attacker. |
| Typed in | `info` | The box does not decide. | the login name, the search box, the order number | (never a rule) | |
| What was typed | `allowed`, with `exempt` (Our scanner) | A name, a search or an order number holds letters, digits and spaces. An apostrophe in a name is fine. Code is not. | `Maria`, `O'Brien`, `blue shirt`, `order 4471` | `' OR 1=1 --`, `admin'--`, `1; DROP TABLE users`, `' UNION SELECT *` | Typed text is data, never code. |
| Answer | `allowed` | A request returns what it asked for: one row, a page, or a polite "not found". Thousands of rows or a database error is not normal. | 1 row, a page, not found | 2,400 rows, a database error | The answer shows what the website really did. |

### Decoys (look odd, follow the rules)
- **Ciaran O'Brien's login:** an apostrophe in a name, and a page shown.
- **The security scanner:** code in its request, exempt by name; the log says it is the scanner.
- **A long search:** *"blue shirt size medium with a red stripe"*, 40 letters, nothing odd in it.

### The threat
Most bad logs type **`' OR 1=1 --`** into the login name (the values that repeat) and get **2,400 rows** back. Story logs follow the attack: 14:02 (the code), 14:31 (`support_admin` signs in).

---

## 3. Hardening: four upgrades (ALWAYS passive + AGAINST counter)

New names (nothing repeats Days 1 to 7; Limit Requests and Security Key come back as echoes only). Loads 1, 1, 2, 2; prices 30, 30, 50, 50.

| Upgrade (id) | Load / price | ALWAYS | AGAINST | Recommended by | Icon (32x32) |
|---|---|---|---|---|---|
| **Check Input** (`input`) | 1 / 30 | **+3 Block** at the start of each of your turns | **Injection:** a piece you touch is cleaned: it cannot join another | the code in the login form | a text box with a funnel |
| **Patch the Framework** (`framework`) | 1 / 30 | **+15 max HP** | **Known hole:** the bullet splits only once | the old framework | a gear with an up arrow |
| **Admin Lockdown** (`adminlock`) | 2 / 50 | **Heal 3 HP** at the start of each of your turns | **Stolen admin:** each hit does only a third of the damage | the new administrator | a padlock on a crown |
| **Web Firewall** (`waf`, helper) | 2 / 50 | **Draw 2 extra cards** in your first hand | **Every attack:** a longer warning before it starts | the burst of requests | a brick wall with a flame |

### Hardening echoes
Day 6's **Limit Requests** and Day 7's **Security Key** each change one entry (section 1). Both replace a noise entry, so the count stays 36.

---

## 4. Response: the Web Application Attack fight

Enemy: the existing sprite. Player 90 HP; enemy about 130 HP (tuned with the dodge bots). Each pattern has a harder version without its counter, announced as before. Reading comes **before** the bullets, each pattern has a cue in the box, and the strip is only the name while dodging.

| Pattern | Kind | How it plays | Counter | Without it (harder) |
|---|---|---|---|---|
| **Injection** | `inject` *(new)* | Small **fragments** drift across the box: pieces of a quote (`'`) and pieces of code (`OR 1=1`). One piece alone is harmless. The heart **collects** a piece by touching it, and shows what it holds under the box. If it holds **a quote and a piece of code at the same time**, they join and hit (the code runs). A held piece fades after 3 seconds. | Check Input: **a piece you touch is cleaned**, so it cannot join | Pieces never fade, there are more of them, and touching one pulls its partner toward you |
| **Known hole** | `split` | A bullet breaks into copies that spread (the Day 2 kind, new sprites). | Patch the Framework: it splits **only once** | It splits again and again |
| **Stolen admin** | `aimed` | A line blinks, then a key flies along it; every few shots a fan of keys. | Admin Lockdown: each hit does only **a third** of the damage | Full damage, and less warning |

The helper (Web Firewall) delays the start of every pattern. Draft lessons (at most two lines): *Injection: "Text you take in can turn into a command. Never mix a quote and a code."* / *Known hole: "An old hole is open to everyone."* / *Stolen admin: "A new key to the master door."*

### New card effect: **Exploit**
**Exploit N** is a bonus for a threat that is **Exposed**: **if the threat is Exposed when the card is played, it deals N more damage** (so Expose, from Days 4 and 6, finally pays off). There is no chip: it is only on the card. Keyword in `data/keywords.json` (`exploit`): *"If the threat is Exposed, this card deals this much more damage."* Value for balance: about 5 damage per point of Exploit when an Expose card is in the hand; a second use of Expose in the same turn stacks with it (Exposed already adds its own bonus to every card).

---

## 5. Cards: the 10 new ones (Exploit is on 4 of them)

Same format as before (`cards.json`, `"day": 8`, a line from Carla, 64x44 art in code, the shop NEW filter). **A card text fits three short lines (30 letters at most), a card name about 11 letters.** Three of the cards that are not attacks **Expose**, so Exploit works from Day 8 alone.

| Card | Type | Cost | Text | Price | Art |
|---|---|---|---|---|---|
| Fuzz Test | offensive | 1 | Deal 4 damage. Exploit 4. | 35 | random letters flying at a box |
| Pen Test | offensive | 2 | Deal 6 damage. Exploit 6. | 45 | a padlock with a lockpick |
| Hotfix | offensive | 1 | Deal 5 damage. Exploit 3. | 35 | a bandage over a crack |
| Lockdown | offensive | 3 | Deal 12 damage. Exploit 10. | 60 | a steel door slamming shut |
| Input Filter | defensive | 1 | Gain 4 Block. Expose 1. | 35 | a funnel catching a quote mark |
| Safe Query | defensive | 2 | Gain 8 Block. Heal 1. | 50 | a query line with a shield |
| Web Shield | defensive | 1 | Gain 3 Block. Dodge 1. | 35 | a shield in front of a browser window |
| Read Logs | utility | 0 | Draw 1. Expose 1. | 25 | a scroll with a magnifier |
| Code Review | utility | 2 | Expose 2. Draw 1. | 45 | two eyes over a block of code |
| Fresh Backup | utility | 1 | Heal 3. Draw 1. | 35 | a disk with a green tick |

Mix: 4 offensive, 3 defensive, 3 utility. Exploit is on Fuzz Test, Pen Test, Hotfix and Lockdown. Expose is on Input Filter, Read Logs and Code Review. (Numbers are a first guess; the balance model in `notes.json` card_balance sets the final ones when I build it.)

---

## 6. Recovery: restore the site, patch the hole, remove what was left

Each attack that got through becomes one repair; the last is the final check. **Every repair is a hands-on mini-game that teaches the fix step by step with pictures** (the standing rule since Day 6): the thing is drawn, the player works on it, the next step glows, a wrong move bounces back with one plain reason.

| Attack that got through | Repair (component id) | Mechanic | What the player does |
|---|---|---|---|
| Injection | **Restore the website from a backup** (`restore`) | the Day 3 and 4 backup timeline (versions mode), **new content** | The site's backups from Monday to today, with a marker at 14:02 (*"code ran here"*). Pick the last good one (14:00), test it, restore it. A later one carries the planted file; an earlier one loses orders. |
| Known hole | **Patch the framework, then prove it** (`patch`) | **new: a patch bench** (`SitePatch`, one script) | See section 6a. |
| Stolen admin | **Remove the planted file and the new administrator** (`backdoor`) | account action (Day 4 to 6, a new scene file `RemoveBackdoor.tscn`) | Step 1: choose which file in the uploads folder is the planted one (`help.php`; not `logo.png`, not the scanner's report) and delete it. Step 2: choose which administrator to remove (`support_admin`; not Sam, not Carla). |
| (final check) | **Back to work** (`file_server`) | test (FileServerRepair, 3 checks) | The site loads and the data is right, the attack string is rejected, and the planted file and the new administrator are gone. |

### 6a. Patch the framework, then prove it (`SitePatch`)
- **The picture:** a small terminal with the site's version (*ShopKit 2.1*), the vendor's notice (*"2.4 fixes the login hole"*), and two panels: **the test copy** and **the live site**, each with a login form and a light.
- **The steps, guided (the next one glows):** 1) take a backup of the live site; 2) download the update from a source: three buttons (*the vendor's own site*, *a link in a forum post*, *an email attachment*: only the vendor's is right, the others say why); 3) check the download against the vendor's number (two numbers shown: they must match; a second download that does not match is a trap); 4) install it on the **test copy**; 5) **test it**: the player types the attack string `' OR 1=1 --` into the test copy's login form: before the patch it returns *2,400 rows*, after it says *rejected*; 6) install it on the **live site** and restart.
- **A wrong order bounces back:** installing on the live site before the test says *"Test on a copy first. A bad update can break the live site."*
- **Lesson line:** *Back it up, take the update from the maker, check it, test on a copy, then do the real one.*

The Day 8 room uses 4 repairs and the final check, so 4 machines are used (restore: backup or servers; patch: servers; backdoor: access or monitoring; the final check: servers).

---

## 7. Dialogue (five scenes, and an ending; beats, the lines are written when built)

1. **Before Investigation.** Sam (the web developer) by phone: strange errors on the portal and two orders nobody placed. Choice: *Could it be a customer's typing mistake?* (Joshua: "Possible. Evidence first.") / *When did it start?* (around 14:00). Joshua: *5 clues should be enough.*
2. **Before Monitoring.** Carla in person: *"Typed text is data. It becomes a problem only when the site treats it as an order."* Choice: *Is an apostrophe an attack?* (no: O'Brien types one; look at the whole text) / *Can't we just block every odd character?* (names have them).
3. **Before Hardening.** Carla: check input, patch the framework, lock the admin door. Introduces **Exploit** (*"Expose it first, then it hurts."*).
4. **Before Response.** It does not break in; it types its way in. Three tricks: **injection**, **known hole**, **stolen admin**. Choice: *What is it doing?* / *Are we ready?*
5. **Before Recovery.** Carla: *"Stopped is not fixed. The site is damaged, the hole is still open, and somebody left a spare key."* Choice: *What do we fix first?* (the backup, the patch, the spare key) / *Do we tell the customers?* (the ones whose orders were touched, plainly).
6. **After Recovery (the ending).** A short last scene: Joshua and Carla look back at the eight days. The finish screen of Day 8 lists **what the player learned, one line for each day** (the "What you learned" lines from the plan of each day), and Joshua closes the story. See question 6.

---

## 8. Art, made in code

| Asset | Size | Description |
|---|---|---|
| 4 upgrade icons | 32 x 32 | see section 3 |
| 10 card arts | 64 x 44 | see section 5; same dithered navy background |
| Bullet: quote piece | 5 x 7 | the injection (a small quote mark) |
| Bullet: code piece | 9 x 5 | the injection (a piece of `OR 1=1`) |
| Bullet: crack | 7 x 7 | the known hole (a jagged bolt that splits) |
| Bullet: admin key | reuse | the gold key of Day 1 and 7 (`bullet_key.png`) |
| Marks | 7 x 8 | the held fragments under the box (a quote and a code piece); a "joined" flash |
| The two query cards | in code | the typed text, the question built from it (the glued part in color), a RUN button and the answer |
| Recovery pictures | in code | the patch bench (two login forms, two lights, the version), the uploads folder, the administrators list |
| Enemy | exists | `web_app_attack_frames.tres` |

Before anything is wired in I show a contact sheet (all sprites enlarged).

---

## 9. What gets built

1. **Monitoring:** `data/scenarios/day 8/monitoring.json`; one small engine addition: **`exempt` on an `allowed`/`pattern` rule** in `LogGenerator._evaluate` (the same shape as the one of `threshold`: another part with one of the listed values makes a break "odd, but cleared").
2. **Investigation:** `data/scenarios/day 8/investigation.json` (tabs, 36 entries, echoes, 5 clues, the fill-in report); a small **`QueryCard`** control (drawn in code, a RUN button) shown by the report screen when the data has `queries`, like the `cards` of Day 7; the notes' `.php` and units; Joshua's shorter monologues.
3. **Hardening and cards:** four upgrades with passives (all old keys), icons, shop lines; 10 cards with art; the **Exploit** effect (`response.gd`: a bonus when `_exposed > 0`; `keywords.json`; the validator's effect keys; no chip).
4. **Response:** one new arena kind, `inject` (fragments the heart collects; a quote and a code piece held together hit; fragments fade; the held pieces are shown under the box; with the counter a touched piece is cleaned); `split` and `aimed` reused; `response_day8.json`; the dodge bots taught to avoid collecting two different pieces; tuning (target as before: with the counter an average bot takes about 0 to 1, without it about 4 to 7).
5. **Recovery:** one new task, `SitePatch` (`patch`, one script and one scene); `restore` (BackupTimeline) and `backdoor` (AccountAction, `RemoveBackdoor.tscn`) with new content; `day8_recovery.json`; register `patch` and `backdoor` in `RecoveryData`; the equipment groups. The pictures are drawn in code.
6. **Dialogues, archive, tutorials, ending:** five scenes and the ending scene; the Web Application Attack ATTACK PATTERNS and RECOMMENDED UPGRADES pages; `Tutorial.maybe_show_new` keys (see below); the closing "what you learned" list on Day 8's last finish screen (if question 6 is yes).
7. **Validator and tests:** the day validator, the new arena kind, Exploit, the exempt rule, the query cards report, the site patch, the Day 8 playthrough; all earlier suites re-run.

Order: Monitoring (with the exempt rule), Investigation (with the query cards), Hardening and cards, Response, Recovery, dialogues and the ending, playthrough, report.

---

## 10. Carried over from Days 3 to 7 (so nothing is missed)

**A. Objectives** (`days.json`, at most 80 letters; Hardening at most 29)
| Phase | `objective` | Second step |
|---|---|---|
| Investigation | INVESTIGATE AND FIND CLUES | `objective_report`: SHOW WHAT WAS TYPED AND WHAT IT DID |
| Monitoring | CHECK EACH REQUEST AND REPORT THE CODE | |
| Hardening | HARDEN THE WEBSITE (19) | |
| Response | DO NOT JOIN THE PIECES: PLAY CARDS, THEN DODGE | |
| Recovery | RESTORE THE SITE, PATCH THE HOLE, REMOVE WHAT WAS LEFT | |

**B. Learning and story.** Story is the five dialogues and the ending. Learning, one line per phase: Investigation *typed text can become a command when a site mixes it into a question*; Monitoring *an apostrophe is not an attack: look at the whole text*; Hardening *check what comes in, and keep the software up to date*; Response *two harmless pieces can become one harmful one*; Recovery *restore a copy that is clean, patch from the maker after a test, and remove what the attacker left*. The ending lists these (and the seven before them).

**C. Tutorials** (`Tutorial.maybe_show_new`, named by the day's data): `response_day8` (Exploit is on the card, it needs the threat Exposed; the injection's held pieces show under the box), `investigation_query` (run a card to see what the database answers), `recovery_patch` (the next step glows; test on the copy first).

**D. Details that bit before:** card text at most 30 letters and a name about 11 letters; no AM or PM (the validator rejects it); a Hardening objective at most 29 letters; a recommended clue must be a real clue (`is_clue`); a hint may not use the words *suspicious, normal, allowed, rule, report, bad*; test scripts need `tutorial_seen` filled or the overlay pauses the game; a test script cannot name a class that uses an autoload (use `load()`); choices in an AccountAction wrap after four; a machine for every repair (the room has 9); the Settings colors (`GameColors`) are used for anything new that is good, bad, block or highlight; a test of the arena must seed the random numbers.

**E. Keywords** (`data/keywords.json`): `exploit` (the Highlight color).

---

## 11. What I want you to check

1. **The story:** a website that glues typed text into its database question, one address, a planted file and a spare administrator, and an old framework that was never patched. Right tone for the last day? Is Sam (the developer) at fault, or nobody?
2. **The query cards** (two small cards with a RUN button that show *1 row* for "Maria" and *2,400 rows* for the code): one new small control, `QueryCard`, over the five blanks. Right size, or do you want the cards only?
3. **Exploit:** a bonus when the threat is Exposed, no chip; three non-attack cards give Expose so it works from Day 8 alone. Fair and clear?
4. **The Injection pattern:** collecting fragments, with a quote and a piece of code together hitting you. Fun, or too hard to read in the middle of dodging? (The helper and the counter make a touched piece harmless.)
5. **Recovery:** one new task, the patch bench (back up, download from the maker, check, test on a copy with the attack string, then the live site), and two reused ones with new content. Anything to add or cut?
6. **The ending:** after Day 8's Recovery, a short closing scene and a list of **what you learned on each day** (eight lines). Yes or no? If yes, should it also appear as a recap page in the Book Archive?
7. **Anything else** before I build the last day.

---

## 12. As built: what differs from the plan

All six questions of section 11 were answered "use your recommendation": the plan was built as written, with these differences.

- **Clue to upgrade links.** A recommended clue must be a real clue, and the framework entry on SERVERS is a link, not a clue. So the recommendations are: Check Input from the code in the login form (`web_inject`), Patch the Framework from the planted file (`file_help`: a file that got in through a hole nobody patched), Admin Lockdown from the new administrator (`acct_new`), Web Firewall from the burst of requests from one address (`net_addr`). The database errors (`srv_db`) are the fifth clue and recommend nothing, as on earlier days.
- **QueryCard** (`scripts/gameplay/investigation/query_card.gd`) is one small control like `MessageCard`: it shows what was typed and the question built from it (the typed part underlined), a RUN button, and the answer with a one-line note. The report reads `report.queries` (label, typed, answer, note) beside `graphs` and `cards`. Running is never required.
- **Monitoring:** `LogGenerator._evaluate` now gives an `allowed` (or `pattern`) rule an `exempt` {part, values} like the `threshold` rules: a break by another part with one of those values is odd but cleared (hint group `exempt`). The scanner is not in the normal values of 'Sent by', so a bad log can never be cleared by chance; it only comes through the scanner decoy.
- **Exploit** is read in `response.gd` when a card with damage is played: `if _exposed > 0` the card deals `exploit` more, and an EXPLOIT +N float text shows it. There is no chip. The validator knows the effect key.
- **Injection** (`inject` in `bullet_arena.gd`): quote and code pieces (`frag`) drift across; touching one is `_collect`: with the counter it is cleaned (a note, nothing held), without it the heart holds the piece for `hold_time` (3 seconds; 99 in the harder version) and a quote plus a piece of code held together is a hit. Under the box the arena draws `HOLDING:` with the held pieces and a time bar, and `QUOTE + CODE = HIT`. The harder version also has `pull`: the partner of a held piece steers toward the heart.
- **Known hole** reuses `split` (sprite `bullet_crack.png`, once with the counter, four generations without). **Stolen admin** reuses the `aimed` kind with its own counter, as Day 7.
- **Cards:** Safe Query heals 1; the Exploit values are 4, 6, 3 and 10 (Fuzz Test, Pen Test, Hotfix, Lockdown).
- **Recovery:** `SitePatch` (`patch`) is six buttons the player presses in order (the next one glows while the caption names the step): back up; download from one of three sources (only the maker's is right); check the two numbers (the first download differs by one digit: "they differ, download again" costs nothing, "they match" there is a mistake); install on the test copy; try the attack string (before the patch it shows 2,400 rows without advancing, after it is rejected); install on the live site. Installing live before the copy is proven says to test on a copy first. `backdoor` is the `AccountAction` script in a new scene (`RemoveBackdoor.tscn`): four files (only `help.php` is right), then three administrators (only `support_admin`). `restore` is the Day 4 timeline with four backups and the marker at 14:02. The Day 8 room uses 4 machines.
- **The ending** is a dialogue, not a finish-screen list: `days.json` day 8 has an `ending` file (`AfterRecovery.json`); `FinishScreen` opens it after Recovery (`GameState.play_ending`), Carla reads what each of the eight days taught in four short blocks, Joshua closes, and the trigger goes back to the day select. It was not added to the Book Archive as a recap page.
- **Book Archive:** the Web Application Attack now has its ATTACK PATTERNS and RECOMMENDED UPGRADES pages.
- **Tests:** `validate_days.gd` (5651 checks, including the ending scene), `d8_test` (Exploit, the arena kinds), `inv8_test` (the query cards and the report), `rec8_test` (the three tasks), `playthrough8_test` (the whole day and the ending), and `tune_bot8`.
