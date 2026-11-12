# Day 6: Distributed Denial-of-Service (draft for review)

Status: **built in all five phases** (see section 12 for what differs from this plan; the sections above are the plan as approved). Same shape as `day5_exfiltration_draft.md`, with everything learned on Days 3 to 5 folded in (section 10). Day 6 is the **"a crowd is not proof, look at what each visitor does"** day: the biggest rush of the day is made of real customers, and the flood that took the site down asks for one page, in one browser, and never buys anything.

- **Day title:** *Locked Door* (the shop door is crowded, so no customer can enter)
- **Threat:** Distributed Denial-of-Service (the Book Archive's threat 6 opens when this Investigation is finished; its five pages exist, it still lacks the ATTACK PATTERNS and RECOMMENDED UPGRADES pages)
- **The question Joshua answers:** *Is this a rush of customers, or an attack?*
- **The story:** The website goes down at lunch. Everybody blames Marketing's lunch sale (it starts at 12:00), but the site was already slow at **11:42**. Nine thousand two hundred addresses, many of them cameras and routers, ask for the same search page again and again, with the same browser name, and none of them logs in or buys anything. At 12:00 the real customers arrive too, and cannot get in. Nothing is stolen: the goal is only to cause a stop.
- **People:** Joshua (narrator, helping less), Carla (in person), **Jonas Pike** (the web admin, by phone, the hook), **Leila Haddad** (Marketing: she sent the sale, a decoy and a callback), Ben and Marta (callbacks, a customer call).
- **Enemy:** the DDoS sprite that already exists (`ddos_frames.tres`).
- **One threat actor** (standing decision): the botnet's owner, unknown. No second actor.

---

## 1. Investigation

**Five clues** (standing decision: 5 from Day 5 on; the older plan said 4). The report is a new form: **compare two traffic graphs** (section 1, "The report"), then fill the reasons.

### Tabs (the same seven slots, relabeled)

| Slot | Day 5 | **Day 6** | What it shows |
|---|---|---|---|
| 1 | EMAIL | **EMAIL** | complaints, the sale, notices |
| 2 | JOBS | **TRAFFIC** | requests by page and by browser name |
| 3 | HOSTS | **SOURCES** | who is asking: groups of addresses, their ranges and what they are |
| 4 | DESTINATIONS | **ORDERS** | who logged in, who bought |
| 5 | FILES | **FILES** | settings and logs (the request limit, the access log) |
| 6 | NETWORK | **NETWORK** | requests and bandwidth by minute |
| 7 | SERVERS | **SERVERS** | web-01, db-01, the load balancer |

### The 36 entries (**CLUE** counts, decoy looks like a clue but is harmless, link connects clues by a shared name, noise)

| Tab | Entry | Role | What it is |
|---|---|---|---|
| EMAIL | "The site is down!" (Jonas, 11:58) | link (the hook) | "Slow since 11:42, down since 11:50. Marketing's sale?" |
| EMAIL | Lunch sale, 12:00 (Leila, 09:30) | decoy | The sale was planned and announced; it starts at 12:00. |
| EMAIL | "Customers cannot buy" (Support, 12:15) | link | Real customers are turned away. |
| EMAIL | Maintenance window Sunday | noise | |
| EMAIL | Parking permits | noise | |
| TRAFFIC | `/search?q=` , 41,000 requests a minute from 11:42 | **CLUE** | Every one asks for the same page. |
| TRAFFIC | Browser name `bot-kit/1.0`, 97% of the requests | **CLUE** | One browser name for thousands of "visitors". |
| TRAFFIC | Shop and checkout pages, 14,000 a minute from 12:05 | decoy | Many pages, real browsers, the sale. |
| TRAFFIC | A search-engine crawler, 30 a minute | decoy | Polite and listed in `robots.txt`. |
| TRAFFIC | A normal Tuesday: 900 requests a minute | link (the baseline) | |
| TRAFFIC | Image downloads | noise | |
| SOURCES | 9,200 addresses in 40 ranges: cameras, routers, small servers | link | Devices nobody owns on purpose. |
| SOURCES | The sale's customers: 3,100 addresses, six countries | decoy | Real people, different every minute. |
| SOURCES | The office, the partner's API, our own monitor | noise (3) | |
| ORDERS | The 9,200 addresses: 0 logins, 0 orders | **CLUE** | Nobody in the flood ever buys. |
| ORDERS | The sale: 412 orders in 20 minutes | decoy | |
| ORDERS | Password resets, refunds, newsletter sign-ups | noise (3) | |
| FILES | Request limit setting: none | link | Nothing limits one visitor. |
| FILES | `access.log`: 40 MB to 2 GB since 11:42 | link | |
| FILES | `promo_banner.png` | decoy | Marketing's file; nothing to do with the load. |
| FILES | `robots.txt`, `maintenance.html` | noise (2) | |
| NETWORK | 41,000 requests a minute from 9,200 addresses, from 11:42 | **CLUE** | Rises in two minutes, flat, not a curve. |
| NETWORK | The sale: 14,000 a minute from 12:00, peak 12:20, falling | decoy | A rush rises, peaks and falls. |
| NETWORK | Nightly backup at 01:00 | noise | |
| NETWORK | Staff browsing | noise | |
| NETWORK | Gateway note | echo (Day 5 **Flag Odd Transfers**) | Equipped: *"The gateway flagged the spike as odd at 11:43."* Not equipped: *"The gateway let the spike through without a note."* |
| SERVERS | web-01: processor 100% since 11:43, queue full | **CLUE** | |
| SERVERS | db-01: normal | noise / link | |
| SERVERS | The load balancer: sends everything to web-01 | link | There is no spare to share the load. |
| SERVERS | Test page on port 8081 | echo (Day 5 **Close Unused Ports**) | Equipped: *"Only ports 80 and 443 are open."* Not equipped: *"An old test page on port 8081 is open, and is being hit too."* |
| SERVERS | The update server | noise | |

**Total:** 36 entries shown in each version, **5 clues**, 6 decoys, 6 links. All times are 24-hour; no AM or PM.

### Joshua helps less
Joshua says what he noticed and asks the question: *"All of them ask for the same page. Real customers wander around the shop."* A clue is still marked FOUND when investigated.

### The report: compare two graphs (a new form)
A small **graph** (drawn in code, 11:00 to 13:00 on the bottom, requests a minute on the side) is shown twice at the top of the report: **Graph A** and **Graph B**. One is the sale (rises from 12:00, peaks, falls), the other is the attack (jumps at 11:42 and stays flat). The story is a fill-in with five blanks:

> *Graph A is {1}, and graph B is {2}. The flood began {3}. Every request asked for {4}, and none of them {5}.*

| Blank | Right chip | Decoys |
|---|---|---|
| 1 Graph A | the real rush of customers | the attack |
| 2 Graph B | the attack | the real rush of customers *(a swap is the classic mistake; its reason says to check when it rises and whether it falls)* |
| 3 When | at 11:42, before the sale | at 12:00, when the sale began |
| 4 What | the same page, from one browser | many different pages |
| 5 What they did not do | log in or buy anything | ask for help *(and one more)* |

Each wrong chip explains itself. Pay as before: 20 per clue, -5 per mistake, 25 for a flawless report. Which graph is which (A or B) is fixed in the data, not random, so the validator can check it.

### The notes highlight what matters
The report screen's notes color times (gold), amounts (cyan) and names (green). The amount pattern gets the units **requests, addresses and ranges**, so *41,000 requests* and *9,200 addresses* stand out (a small change to `NOTE_PATTERN` in `report_screen.gd`).

### Links to Hardening
Clues recommend upgrades: the flat 41,000 a minute and the one-node load balancer to **Spread the Load**; the same-page, one-browser traffic to **Limit Requests**; the 0 logins to **Close Idle Connections**; the 100% processor to **Spare Capacity**.
Findings copied for Recovery: the five clue summaries.

---

## 2. Monitoring: "a traffic sample"

Each log is one minute of traffic and has four parts: **Requests a minute**, **From each address**, **Pages**, **Browser**. Three rules, all kinds the engine already has, so **no engine work**.

| Rule | Kind | Text | Good | Bad | Why |
|---|---|---|---|---|---|
| Requests a minute | `info` (Day 5) | A big number does not decide. | 900, 2,000, 14,000 | (never a rule) | The sale is huge and real. The lesson of Day 5 comes back. |
| From each address | `threshold`, max **40** a minute, odd margin 10, exempt: Our monitor | One visitor sends at most 40 requests a minute. | 2 to 25 | 300, 600, 1,200 | A person clicks. A bot floods. |
| Pages | `allowed` | Real visitors ask for many pages: the shop, a product, the cart, the checkout. | many different pages | only `/search?q=`, only the home page | A flood asks for the same page. |
| Browser | `allowed`, with `odd_values` | A real browser has a real name. | Chrome, Firefox, Safari, Edge | `bot-kit/1.0`, an empty name | Thousands of visitors never share one made-up name. |

### Decoys (look odd, follow the rules)
- **The sale rush:** 14,000 requests a minute, 12 from each address, many pages, Chrome. Huge, and fine.
- **The search-engine crawler:** 30 a minute from one address, `friendly-bot/2.1` (an `odd_value`: allowed, worth a second look).
- **Our own monitor:** 600 requests a minute from one address, exempt by name (like the Backup Agent on Day 3).

### The threat
Most bad logs ask for **`/search?q=`** with browser **`bot-kit/1.0`** (the values that repeat). Story logs follow the flood through its minute: 11:42 (it starts), 12:00 (the sale begins on top of it).

---

## 3. Hardening: four upgrades (ALWAYS passive + AGAINST counter)

New names (nothing repeats Days 1 to 5). Loads 1, 1, 2, 2; prices 30, 30, 50, 50.

| Upgrade (id) | Load / price | ALWAYS | AGAINST | Recommended by | Icon (32x32) |
|---|---|---|---|---|---|
| **Spread the Load** (`spread`) | 1 / 30 | **Heal 3 HP** at the start of each of your turns | **Flood:** the load is shared: the bullets come from one side at a time | the flat 41,000 and the one-node balancer | a balance with two servers |
| **Limit Requests** (`limit`) | 1 / 30 | **+1 Dodge** at the start of each of your turns *(new passive key `dodge_per_turn`)* | **Many sources:** each source may fire only twice | the same-page, one-browser traffic | a gate with a counter |
| **Close Idle Connections** (`idle`) | 2 / 50 | **+1 damage** on every attack card | **Slow drip:** a held connection closes after 2.5 seconds | 0 logins and 0 orders | a plug being pulled from a socket |
| **Spare Capacity** (`spare`, helper) | 2 / 50 | **+10 max HP** | **Every attack:** a longer warning before it starts | the processor at 100% | a stack of extra servers |

### Hardening echoes
Day 5's **Flag Odd Transfers** and **Close Unused Ports** each change one entry (section 1). Both replace a noise entry, so the count stays 36.

---

## 4. Response: the DDoS fight

Enemy: the existing sprite. Player 90 HP; enemy about 130 HP (tuned with the dodge bots). Each pattern has a harder version without its counter, announced as before. Reading comes **before** the bullets, each pattern has a cue in the box, and the strip is only the name while dodging.

| Pattern | New kind | How it plays | Counter | Without it (harder) |
|---|---|---|---|---|
| **Flood** | `flood` | A dense stream of small bullets from the right, and short bursts from the top and the bottom. There is always a gap, but it moves. | Spread the Load: the bullets come from **one side at a time**, so the other sides are quiet | All sides at once, denser and faster |
| **Many sources** | `swarm` | Six "sources" light up around the edge of the box. Each fires bullets **aimed at where the heart is when it fires** (not homing). | Limit Requests: each source may fire **only twice**, then it shows LIMITED and goes quiet | No limit: sources keep firing, and fire in pairs |
| **Slow drip** | `drip` | A few slow bullets that **stop inside the box and stay**. They pile up, so the free room shrinks all through the pattern. | Close Idle Connections: a held bullet **closes after 2.5 s** | They stay until the pattern ends, and they are bigger |

The helper (Spare Capacity) delays the start of every pattern. Draft lessons (at most two lines): *Flood: "Too much at once from every side. Share it out."* / *Many sources: "Thousands of senders. Cap each one."* / *Slow drip: "Connections that never close fill the room."*

### New card effect: **Cap**
**Cap N** limits the enemy's turn: **each hit does at most N damage** until that turn is over (gone with Block and Dodge when the enemy turn ends). It shows as a chip under **your** HP bar (a flat bar with a ceiling mark, the Block color) with a tooltip; it only works on big hits (a 1-damage hit stays 1) and stacks by keeping the **lowest** Cap. Keyword in `data/keywords.json` (`cap`): *"Each hit of the enemy's turn does at most this much damage."* Value for balance: worth about 4 Block per point against hits of 8 or more.

---

## 5. Cards: the 10 new ones (Cap is on 4 of them)

Same format as before (`cards.json`, `"day": 6`, a line from Carla, 64x44 art in code, the shop NEW filter). **A card text fits three short lines (30 letters at most), a card name about 11 letters.**

| Card | Type | Cost | Text | Price | Art |
|---|---|---|---|---|---|
| Ping | offensive | 1 | Deal 5 damage. Dodge 1. | 35 | a radar ping ring over a dot |
| Packet Trap | offensive | 2 | Deal 8 damage. Expose 1. | 45 | a net closing over packets |
| Blackhole | offensive | 2 | Deal 7 damage. Cap 3. | 45 | a dark spiral eating arrows |
| Takedown | offensive | 3 | Deal 19 damage. | 60 | a botnet node with a red cross |
| Rate Cap | defensive | 1 | Gain 3 Block. Cap 4. | 35 | a barrier with a ceiling bar |
| Load Balancer | defensive | 2 | Gain 6 Block. Dodge 1. | 45 | one stream split to three servers |
| Choke Point | defensive | 2 | Gain 7 Block. Cap 5. | 50 | a funnel narrowing to a door |
| Throttle | utility | 1 | Cap 3. Draw 1. | 35 | a tap turned half closed |
| Warm Cache | utility | 0 | Draw 1. Gain 2 Block. | 25 | a small box with a flame |
| Failover | utility | 2 | Heal 3. Draw 2. | 50 | two servers with a swap arrow |

Mix: 4 offensive, 3 defensive, 3 utility. Cap is on Blackhole, Rate Cap, Choke Point and Throttle. (Numbers are a first guess; the balance model in `notes.json` card_balance sets the final ones when I build it.)

---

## 6. Recovery: set the limit, bring the site back, and fix what the flood burned

Each attack that got through becomes repairs; the last is the final check. **Every repair is a hands-on mini-game that teaches the fix step by step with pictures, not with a list of sentences** (the way the Blue Screen laptop and the ransomware laptop with its backup work): the thing is drawn, the player does each step on it with the mouse, the next step is hinted by a glow, a wrong move bounces back with one plain reason, and a one-line caption says what the step is for.

| Attack that got through | Repair (component id) | Mechanic | What the player does |
|---|---|---|---|
| Flood | **Set a request limit** (`limit`) | **new: a gate with a dial** (`RateDial`) | See section 6a. |
| Flood | **Cool the room, replace the failing fan** (`fan`) | **new: a server and its room** (`FanSwap`, two stages) | See section 6b. The flood kept the processor at 100% for an hour, so a fan gave up. |
| Many sources | **Block the attackers, not the customers** (`block`) | account action (Day 4 and 5, a new scene file `BlockSources.tscn`) | Step 1: choose which traffic to block from six groups (the 9,200 devices in 40 ranges; wrong: the sale's customers, the office, the partner's API, the crawler, our own monitor). Step 2: choose what to tell the customers (a short notice on the site; not silence, not a scary alarm). |
| Slow drip | **Power-cycle the rack in order** (`powercycle`) | **new: a rack with a switch on every unit** (`RackPower`, two stages) | See section 6c. |
| (final check) | **Back to work** (`file_server`) | test (FileServerRepair, 3 checks) | The site loads, the limit is set, and the cooling and the rack are healthy. |

An attack can now stand for **more than one** repair: in the data an attack may have `"components": ["limit", "fan"]` (a list) as well as `"component": "limit"` (one), a few lines in `RecoveryData.components_for_attacks`. The Day 6 room has 4 repairs and the final check, so 5 machines are used. The world has 9 machines (servers 3, access 2, monitoring 2, network 1, backup 1) and the groups below fit (limit: network; block: access or monitoring; fan, powercycle and the final check: servers); this is tight and I will check it with the room test.

### 6a. Set a request limit: the gate (`RateDial`)
- **The picture:** a pipe of traffic runs into the shop door. Small blue dots are real customers (a few requests each), red dots are bots (hundreds). A gate in the pipe opens as wide as the limit.
- **The player:** drags a slider (the new slider look, `assets/ui/slider`) from 1 to 200 requests per address a minute. The dots move live: too low and blue dots bounce off the gate (a meter *Customers let in* falls); too high and red dots flood through (a meter *Attackers let in* rises).
- **Right zone:** 30 to 60. Pressing SET LIMIT outside it bounces back with its reason ("Real customers need up to 25. A limit of 10 turns them away." / "The flood sends 300. A limit of 150 lets it through.").
- **Lesson line:** *A limit that is too tight blocks your own customers. One that is too loose blocks nothing.*

### 6b. Cool the room, replace the failing fan (`FanSwap`, two stages)
- **Stage 1, the room (picture of a server room, a thermometer at 41 degrees):** drag the boxes off the two blocked air vents; turn the air conditioner on and set it to 20 (a dial); close the door. The thermometer falls to 24. Wrong: setting the dial to 5 ("Too cold causes damp and wastes power. 20 to 24 is right.").
- **Stage 2, the server (picture of a rack unit, case drawn from the side):**
  1. Shut the server down properly (hold the power button; the bar fills). *Never pull the plug on a running server.*
  2. Unplug the power cable (drag the plug out). *Power off and unplugged before you open it.*
  3. Open the case (click the two latches).
  4. Find the failing fan: three fans show their speed (0, 4,200, 4,100 rpm); click the one that has stopped. Clicking a good one bounces back ("That fan spins fine.").
  5. Swap it: drag the dead fan out, drag the new fan in (the arrow on it must point the way the air flows; the case shows the arrow).
  6. Close the case, plug it back in, power on. The temperature meter falls and the fan LED turns green.
- **Lesson line:** *Power it off and unplug it before you open it. Replace the part that failed, then check the temperature.*

### 6c. Power-cycle the rack in order (`RackPower`, two stages)
- **The picture:** a rack with six units from the bottom up: power strip, network switch, database, app server, web server, load balancer. Each has a big switch and an LED (red off, amber starting, green on) and a one-word job.
- **Stage 1, shut down (top to bottom):** the player turns off the load balancer, then web, app, database, switch, power strip. A wrong order shows the fault the unit would cause ("The database is still serving the app. Turn the app off first.").
- **Stage 2, start up (bottom to top):** power strip, switch, database, app, web, load balancer; each unit takes a moment (amber) and will not start before what it needs ("The app server needs the database. Start the database first.").
- **Lesson line:** *Shut down from the top, start from the bottom, and wait for each part to be ready.*

**The three new tasks and the old ones are guided in the same way:** the next step glows, a wrong move explains itself in one line and counts as a mistake (it only shrinks the clean bonus), and nothing runs on a clock. Each is one scene plus one script with the content in the day's JSON, like the others; all three use the shared parts that exist (`DragItem`, `DropSlot`, `HoldButton`).

---

## 7. Dialogue (five scenes; beats, the lines are written when built)

1. **Before Investigation.** Jonas (the web admin) by phone: the site is down at lunch; everybody blames the sale. Choice: *Could it just be the sale?* (Joshua: "Possible. Evidence first.") / *Since when?* (since 11:42, he thinks, but the sale was planned for 12:00). Joshua: *5 clues should be enough.*
2. **Before Monitoring.** Carla in person: *"A crowd and a flood look the same from far away. Do not count the crowd. Look at what each visitor does."* Choice: *How do I tell a customer from a bot?* (many pages, a real browser, a few requests) / *Can't we block the busy hours?* (the sale is busy and real).
3. **Before Hardening.** Carla: spread the load, limit each visitor, close idle connections. Introduces **Cap** (*"Limit what one hit can do."*).
4. **Before Response.** The attack does not break in. It crowds the door. Three tricks: **flood**, **many sources**, **slow drip**. Choice: *What is it doing?* / *Are we ready?*
5. **Before Recovery.** Carla: *"Stopped is not fixed. The door is still too easy to crowd, and some real customers were turned away."* Choice: *What do we fix first?* (the limit, then the bad ranges, then the rack and the fan) / *Do we tell the customers?* (a short, honest notice on the site). Carla adds: *"The flood ran the server hot for an hour. Hardware gets hurt too."*

---

## 8. Art, made in code

| Asset | Size | Description |
|---|---|---|
| 4 upgrade icons | 32 x 32 | see section 3 |
| 10 card arts | 64 x 44 | see section 5; same dithered navy background |
| Bullet: request | 5 x 5 | the flood (a small blue-white packet) |
| Bullet: source shot | 7 x 5 | the many sources (a dart with a flag) |
| Bullet: connection | 9 x 9 | the slow drip (a plug / socket glyph) |
| Marks | 7 x 8 | the Cap ceiling bar; the source "LIMITED" cross |
| The two graphs | in code | lines on a dark panel, 11:00 to 13:00 |
| Recovery pictures | in code | the traffic pipe with its gate and dots; a server room with vents, boxes, an AC dial and a thermometer; a server case from the side with three fans and a latch; a rack of six units with switches and LEDs |
| Enemy | exists | `ddos_frames.tres` |

Before anything is wired in I show a contact sheet (all sprites enlarged).

---

## 9. What gets built

1. **Monitoring:** `data/scenarios/day 6/monitoring.json` (the engine is ready: `info`, `threshold` with `exempt`, `allowed` with `odd_values`).
2. **Investigation:** `data/scenarios/day 6/investigation.json` (tabs, 36 entries, echoes, 5 clues, the compare-graphs report); a small **`TrafficGraph`** control drawn in code and shown by the report screen when the data has `graphs`; the notes' amount units; Joshua's shorter monologues.
3. **Hardening and cards:** four upgrades with passives (one new passive key, `dodge_per_turn`, in `response.gd`), icons, shop lines; 10 cards with art; the **Cap** effect (`response.gd`, `keywords.json`, a chip and a mark in `hp_bar.gd`, the validator's effect keys).
4. **Response:** three arena kinds (`flood`, `swarm`, `drip`) each with a harsh version; `response_day6.json`; the dodge bots taught to read the sources and the held bullets; tuning (target as before: with the counter an average bot takes about 0 to 1, without it about 4 to 7).
5. **Recovery:** three new hands-on tasks, `RateDial` (`limit`), `FanSwap` (`fan`) and `RackPower` (`powercycle`), each one script and one scene; `BlockSources.tscn` (AccountAction, `block`); `day6_recovery.json`; register the four in `RecoveryData` (and the list form `"components"` of an attack); the equipment groups; the finish-check content. The pictures are drawn in code.
6. **Dialogues, archive, tutorials:** five scenes; the DDoS ATTACK PATTERNS and RECOMMENDED UPGRADES pages; `Tutorial.maybe_show_new` keys (see below).
7. **Validator and tests:** the day validator, the new arena kinds, Cap, the graphs report, the Day 6 playthrough; all earlier suites re-run.

Order: Monitoring, Investigation (with the graph), Hardening and cards, Response, Recovery, dialogues, playthrough, report.

---

## 10. Carried over from Days 3 to 5 (so nothing is missed)

**A. Objectives** (`days.json`, at most 80 letters; Hardening at most 29)
| Phase | `objective` | Second step |
|---|---|---|
| Investigation | INVESTIGATE AND FIND CLUES | `objective_report`: TELL THE RUSH FROM THE ATTACK (29) |
| Monitoring | WATCH THE TRAFFIC AND REPORT WHAT IS NOT REAL CUSTOMERS | |
| Hardening | HARDEN AND KEEP THE SITE UP (27) | |
| Response | KEEP THE SITE UP: PLAY CARDS, THEN DODGE | |
| Recovery | SET THE LIMIT AND BRING THE SITE BACK | |

**B. Learning and story.** Story is the five dialogues. Learning, one line per phase: Investigation *a lot of traffic is not proof: ask who is asking and what they do*; Monitoring *judge each visitor by what it does, not by how loud the crowd is*; Hardening *share the load, cap each visitor, close what stays open*; Response *many small things can fill a room*; Recovery *set a limit that lets customers in and keeps the flood out, then restart in order*.

**C. Tutorials** (`Tutorial.maybe_show_new`, named by the day's data): `response_day6` (Cap is a chip under *your* bar; point at it), `investigation_compare` (the two graphs and what to look at), `recovery_dial` (the gate and its two meters), `recovery_hardware` (the next step glows; power off and unplug before you open anything; used by the fan and the rack).

**D. Details that bit before:** card text at most 30 letters (three short lines) and a name about 11 letters; no AM or PM (the validator rejects it); a Hardening objective at most 29 letters; test scripts need `tutorial_seen` filled or the overlay pauses the game; a test script cannot name a class that uses an autoload (use `load()`); more than four choices in an AccountAction wrap (done on Day 5); the Settings colors (`GameColors`) are used for anything new that is good, bad, block or highlight; the new slider look (`assets/ui/slider`) is used by the dial.

**E. Keywords** (`data/keywords.json`): `cap` (the Block color).

---

## 11. Questions, and the answers

1. **The story** (the lunch sale blamed for a flood that began 18 minutes earlier): *your answer: up to my recommendation* -> keep it as written. The sale is a good decoy because it is real, it is announced, and it comes after.
2. **The compare-graphs report** (two graphs plus five blanks): *up to my recommendation* -> keep both: the graphs are the evidence and the blanks make the player say why.
3. **Cap:** *up to my recommendation* -> keep it as the new effect (each hit does at most N damage this enemy turn, a chip under your bar). It is the one that matches DDoS ("limit") and does something Block and Dodge cannot: it makes the 18-damage hit small.
4. **A new passive** (`dodge_per_turn`): *up to my recommendation* -> keep it. It is a small change in `response.gd` and fits Limit Requests.
5. **Slow drip** (bullets that stay and shrink the box): *up to my recommendation* -> keep it, with a safety rule: the box never fills more than half, so there is always a way through.
6. **Recovery, the physical jobs:** *yes, as hands-on mini-games that teach the fix step by step with pictures, like the Blue Screen laptop and the ransomware laptop with its backup.* -> done: section 6 now has the gate (`RateDial`), the room and the fan (`FanSwap`) and the rack (`RackPower`), and an attack can stand for more than one repair.
7. **Anything else?** Nothing open. Say "start making Day 6" and I build it in the order of section 9.

---

## 12. As built: what differs from the plan

- **The limit dial: the bots' rates.** To give the right zone (30 to 60) a reason, customers ask for 1 to 25 requests a minute and the bots for 60 to 600 (the quietest hides low). The meters are exact, not sampled: *Customers let in* is how much of 1 to 25 fits under the limit, *Attackers let in* how much of 60 to 600 does. Round dots are customers and square dots are bots, so the picture does not rely on color.
- **Fan: the case is drawn from the side** (lid, cable and plug, wall socket, a light, three fans with their speeds). The stage 2 steps are six: shut down, unplug, open, find the stopped fan, put in the new one with its arrow the right way (a choice of two), close up and power on. Stage 1 steps can be done in any order and the glow goes to the next one that is undone. The thermometer is 41 and falls by 4, 4, 8 and 1 to 24.
- **Rack:** each unit is a drawn face with its name, job and a light (red off, amber starting, green on), and a POWER button. In stage 2 a unit refuses until the one it needs is green ("still starting" costs a mistake too).
- **Cap** only works on damage: Leak is not capped, and Block takes its share of what is left after the Cap. The lowest Cap played counts (Choke Point's Cap 5 does not raise Blackhole's Cap 3).
- **Flood with the counter** fires from the right most of the time (right, top, right, bottom, 1.8 s each) and marks the firing edge of the box; without it the right side and one more side fire at every tick. **Many sources** are six squares on the edge: a lit one blinks, then shoots at where the heart is right then; with the counter a source that has fired twice shows a cross. **Slow drip** bullets stop at a random place and stay (at most 8 at once with the counter, 24 without it, so there is always a way through); with the counter a held one closes after 2.5 s, and all of them close when the pattern is over.
- **Attacks and repairs:** Flood stands for the limit and the fan (`"components": ["limit", "fan"]`, a list; `RecoveryData.components_of`); the validator and the hand-off read the list. The Day 6 work order uses 5 of the 9 machines (limit: network or monitoring, block: access or monitoring, fan, powercycle and the final check: the three servers).
- **Recommended clues:** Spread the Load recommends `net_flood` (the plan said the one-node load balancer, which is not a clue).
- **Report:** the notes' amount pattern also colors *requests, addresses and ranges*. The graphs' axis is shared (45k a minute at the top), so the sale looks small next to the attack, which is the point.
- **Tests:** `validate_days.gd` (4208 checks), a Cap / passive / arena-kinds test, an Investigation report test (swapped graphs), a Recovery test of the five tasks, the Day 6 playthrough (including that all five repairs get a machine), and the bot tuning.
