# Decluttering plan: every phase (draft for review)

Status: **Response, Investigation, Hardening, Recovery and the objective bars are built (see section 9). Monitoring and the top-bar unification are not.** Built from screenshots of the current screens (Day 2 build). The goal is that on every screen the player sees **what they must decide now**, and finds everything else by pointing at it.

## Decisions (from your review)
1. **HP bar below each fighter.** Buffs and debuffs go **under the HP bar, starting from the left**, and each one shows a tooltip when pointed at (Block now, Dodge on Day 3).
2. **Teach strip: yes, but nothing to read while dodging.** Everything the player has to read comes *before* the bullets (the lesson, only the first time an attack appears; the "harder" reason; both always available by pointing at the attack above the threat). During the dodge the strip is only the attack's name.
3. **Hide things until they matter**, as long as it reduces clutter.
4. **The OBJECTIVE line stays on every phase** (it answers the panel's "clear objectives, learning and story in every stage"). It was missing in Response and Recovery. It is now written in `data/days.json` (`objective` per phase and day), so each day can word its own, and the validator requires it.
5. **Scenes:** Claude may edit the scene files.

Open from the panel feedback: **learning** (what the player learned, shown at the end of a phase) and **story** (who and why, at the start). Story already has the dialogues; learning is only the finish-screen comment so far.

## 0. The rules I used (so each phase gets the same treatment)

1. **One job per area.** If two places show the same fact (a number on the bar and again in a label), keep the one next to the thing it describes.
2. **Show what changes the decision.** A number that never changes during the screen (the day, the max HP) is shown small or only once.
3. **Teaching text appears once, where it applies, then gets out of the way.** After it has been read, it moves behind a hover (as the card words do now).
4. **No dead controls.** A disabled button that can never be pressed yet (REPORT before all clues) is hidden until it can be used, or shows its progress.
5. **Fonts stay as decided:** Minecraft Standard 6 px for text, Press Start 8 px for headings. Shorter text is the fix for overflow, never a smaller font.
6. **Same place on every screen** for the same kind of thing: phase and goal at the top-left, points and pause at the top-right, the main action bottom-right.

---

## 1. Response (the most cluttered; the biggest change)

### What is on the screen now (Day 2 build)
Top-left: `YOUR SYSTEM`, a bar, `90 / 90`, `BLOCK 8`. Top-right: `MALWARE`, a bar, `100 / 100`, `NEXT: Trojan (HARDER)`. Top-center: the big **Teach panel** (title, body, the "No ... : the trojan ..." line), taking a third of the screen height, plus the line `YOUR TURN - play cards, then end the turn` under it. Bottom-left: `ENERGY 3 / 3` and `DRAW 4 DISCARD 5`. Bottom-right: `END TURN`. Middle: the two fighters. Bottom: the hand. The upgrade icons share the corner with the player's bar.
That is **fourteen** pieces of text around two small sprites, and the two HP bars are at opposite corners, far from the fighters they belong to.

### Recommendation

**HP bars go directly below each fighter (not above).**
- Below keeps the eyes on the fighters' faces and the top of the screen free for the threat's message and its intent. Fighting games and deck-builders do the same, and it matches the shadow already under each sprite.
- One bar per fighter: the **name above the bar in small text**, the **number inside the bar**. No separate `90 / 90` label, no `BLOCK 8` label.
- Player bar under the hero, enemy bar under the enemy, same size, same height, so both can be compared at a glance.

**Block is the blue part of the same bar (as you described): temporary HP.**
- With no Block: the bar is green (player) or red (threat), the number is the HP.
- With Block: the bar **turns blue and gets a shield mark**; the blue segment is added after the HP, and the **number is HP plus Block** (90 and 8 Block reads `98`, in cyan, with a small shield). The cyan frame around the hero stays as now.
- When a hit lands, the **blue goes first** (the chunk melts away), then the green. The number counts down the same way. When Block is gone at the end of the enemy turn the bar returns to green and the number to the plain HP.
- This also removes the question *"what does Block do?"*: you can see it protect the bar. (The word still has its hover explanation on the cards.)
- Dodge (Day 3) gets the same treatment: a **small mark per Dodge** next to the shield on the bar (one chevron per stack, in the Dodge color).
- The mockup above shows the three states: normal, with 8 Block, after a hit of 14 (8 absorbed, 6 through).

**The Teach panel becomes a one-line banner.**
- During the enemy turn: `TROJAN - HARDER` and the one-line reason (the "No Block Unknown Programs ..." sentence) in a slim strip at the top, 2 lines at most. The longer teaching text (`teach`, `say`) is shown **only the first time that pattern appears in the run**, and always available by pointing at the intent icon.
- During your turn: nothing at the top. The pattern that is coming is shown by the **intent** (below).

**The intent moves above the enemy's head.**
- A small icon and the attack's name (`Trojan`) over the threat, with `HARDER` in red when the counter is missing. This replaces the `NEXT:` checkbox in the corner. Pointing at it opens the teaching text.

**Energy and piles go with the hand.**
- Energy as **three orbs** (filled or empty) at the bottom-left next to the draw pile, the pile's count on the pile itself (`4`), the discard count on its own small icon. No `ENERGY 3 / 3` and no `DRAW 4 DISCARD 5` lines. Extra energy (Day 2's Energy cards) adds a fourth orb.
- `END TURN` stays bottom-right.

**Static instructions leave.** `YOUR TURN - play cards, then end the turn` is replaced by the `YOUR TURN` banner animation that already exists for the enemy turn (and the Response tutorial says the rest, once).

**Upgrade icons** sit under the player's bar as a row of small icons; pointing at one shows its two lines (ALWAYS, AGAINST). Today they share the corner with the bar.

Result: roughly **six** things on the screen besides the fighters and the hand (two bars, the intent, the orbs and piles, END TURN, and the strip when it matters).

### Cost
Moderate. Moves existing nodes (`PlayerName`, `PlayerBar`, `PlayerHp`, `BlockLabel`, `BossName`, `BossBar`, `BossHp`, `Intent`, `Teach`, `TurnLabel`, `EnergyLabel`, `PilesLabel`) and removes five of them; the bar gets a second (blue) fill and the hit animation gets a second step. Because you build the scenes by hand, I would **only write the script side and tell you where each node should go**, or move them in the scene myself if you prefer.

---

## 2. Investigation

### Now
An `Objective - Investigate and find clues` bar on top; under it seven tabs, `Found Clues 0/4` and a disabled `REPORT` button; the app's title (`PROGRAMS > WHAT RUNS ON THE LAPTOPS`) and the hint `Click a row to inspect it`; a table where **every row has its own SELECT / VIEWING button**; on the right the entry's detail and an `INVESTIGATE LOG` button. Joshua's reply appears in a bubble.

### Recommendation
- **Remove the per-row buttons.** A row is clicked; the selected row is highlighted. Five buttons less per tab, and the column of buttons no longer competes with the data.
- **Merge `Found Clues 0/4` into the top bar** (`Investigate: clues 0/4`), and **hide REPORT until all clues are found** (then it appears with the attention bounce it already has).
- **Drop the hint line** after the first row is clicked (it is a tutorial sentence).
- The app title keeps its text; the table header row keeps its 6 px text. Shorten the long column titles on later days.
- The right panel keeps the entry's title, detail and button; Joshua's comment goes **under the detail** instead of a separate bubble area.

## 3. Monitoring

### Now
The objective bar (long sentence), a HUD line (`Approved programs only    On call tonight: ...`), `Correct 0 / Wrong 0`, `Time Left`, a **second** bar `TIME ON THIS LOG 10/10 - PAUSED`, the log card on the left, the NOTES chat on the right with three bubbles, `REPORT` / `LET PASS` in the middle, `NEXT LOG` under the card and `RULEBOOK` alone at the bottom-left.

### Recommendation
- **One timer row:** shift time left and the log's patience on the **same slim bar**, the log's patience drawn as the filled part, the shift time as the number.
- **`Correct / Wrong` only as two small numbers** (a green tick and a red cross) in the corner; the sentence form goes.
- **The three guide bubbles are shown one at a time** (the oldest fades when a new one comes) so NOTES does not fill up; after the guided logs, NOTES shows only the last answer.
- **One row of actions** under the card: `NEXT LOG`, `LET PASS`, `REPORT`, and `RULEBOOK` as a small book icon beside them (instead of a separate button at the opposite corner).
- The HUD line stays (it is the rule the player needs) but shares the bar with the objective: `Monitor: approved programs only - On call: Carla Patel`.

## 4. Hardening (hub, shop, editors)

### Now
A top bar with `1 BUILD HUB`, `Day 2`, the objective, the SP wallet and pause; the hub with the deck (9 cards), a stats panel (`HP 90`, `Energy 3`, `Draw 1 per turn`, a cost curve, `Cards in Deck: 4 Offensive...`, `Avg. Cost`), the upgrades panel (mostly empty), and four buttons (`OPEN SHOP`, `EDIT DECK`, `EDIT UPGRADES`, `MOVE TO NEXT PHASE`). The shop has a title row with five filters per row, Carla's dialogue, the cards row, the upgrades row, and the buy panel.

### Recommendation
- **Top bar:** `Day 2 - Build Hub` as one label, and the objective moved to the first tutorial step (the long sentence is the same on every screen of the phase).
- **Stats panel:** keep the **cost curve** and the three type counts; drop `HP 90`, `Energy 3` and `Draw 1 per turn` (the same on every day; they are in the Response tutorial) and `Avg. Cost`.
- **Upgrades panel:** show the load as `2 / 4` with the equipped icons, and let the empty space show a gentle `Equip upgrades here` only when none are equipped.
- **Buttons:** group `OPEN SHOP`, `EDIT DECK`, `EDIT UPGRADES` as one column; `MOVE TO NEXT PHASE` stays apart and stands out (it is the main action).
- **Shop filters:** keep the new filters, but **show a row only when it has more than about 8 items** (on Day 1 the six cards need none). Carla's box keeps its lines.

## 5. Recovery

### Now
The office is busy by design (it is art). Top bar: `Day 2 / Recovery`, `0/3 checks`, `Pause`. A hint line at the bottom. A `!` marker over each machine that needs work. Repair screens: title bar, instruction, the task, a feedback line, `Back` and `Start over`.

### Recommendation
- This phase is the **least** cluttered, so only two small changes: change `0/3 checks` to `Repairs 0/3` (it counts repairs, not checks) and keep the hint line empty unless the player is standing at something.
- On repair screens: the **instruction line** is shown once and shrinks to a one-line reminder after the first right move; the **feedback line** keeps its color (green or red).
- `Start over` only shows after a first mistake (there is nothing to start over before it).

## 6. Across the phases

- **One top bar** in all five phases: `Day N - Phase` on the left, the one-line goal in the middle, `SP` and pause on the right. Today each phase draws its own version, with a long sentence in Investigation, Monitoring and Hardening.
- **The finish screens, dialogues and menus** are already sparse; no change.
- **Tutorials** keep working, but the extra step added for the card panel is the only text added anywhere.

---

## 7. Build order and cost

1. **Response HP bars and Block** (the visible win, and what you asked for first): script, the blue fill, the hit animation, Dodge marks later.
2. **Response banner, intent and energy orbs.**
3. **Investigation** (rows, REPORT, top bar).
4. **Monitoring** (timer row, actions, NOTES).
5. **Hardening and Recovery** (the small changes).
6. **The common top bar.**
Each step is tested with the existing suites plus a font and overflow audit, and screenshots before and after for you.

## 8. What I want you to check
1. **HP bar below the fighter, with the shield as a blue segment and the number as HP plus Block** (the mockup). Is that what you meant?
2. **The Teach panel becomes a one-line strip** that shows the full text only the first time (and on pointing at the intent). Too hidden?
3. **Hiding things until they matter** (REPORT, Start over, empty filter rows): do you want any of those always visible?
4. **The common top bar** (item 6): worth doing, or leave each phase as it is?
5. **Scenes:** you build scenes by hand. Should I move the nodes myself in the scene files, or do the scripts and tell you where each node goes?

---

## 9. What is built (status)

**Response** (`AI generated/scripts/response/`, `Response.tscn`)
- `hp_bar.gd` (`HpBar`): one bar under each fighter, the number inside it. Block is a blue part after the HP and the number is HP + Block (90 + 8 shows 98); a hit takes the blue first; a white chunk shows what was lost. Statuses sit under the bar from the left, each with a tooltip (Block now; Dodge on Day 3 only needs one more entry).
- The upgrade icons are under the player's bar. The threat's name is above its bar.
- The next attack is above the threat's head (icon, name, `HARDER` in red). Pointing at it opens the strip with the lesson and why it is harder.
- The strip is hidden on the player's turn, shrinks to the attack's name while dodging, and the lesson is read before the bullets and only the first time.
- Energy is orbs, the two piles are small card stacks with their count (tooltips explain them). Removed: `YOUR TURN...` text, `ENERGY 3 / 3`, `DRAW 4 DISCARD 5`, `90 / 90`, `BLOCK 8`.
- `objective_bar.gd` (`ObjectiveBar`): the top bar with `Day N / Response`, the OBJECTIVE and the pause button.
- Card panel fix: the card stayed only under the mouse's slot, so the mouse could not reach the panel. The top half of the popped card, on the panel's side, now keeps the card.

**Investigation**: the rows are the buttons (hover and shown row highlighted), the SELECT column is gone, REPORT only appears when all clues are found, the "Click a row" hint goes after the first click.
**Hardening**: stats panel keeps the type counts and a taller cost curve (HP, Energy, Draw and Avg. Cost are gone); a hint shows while no upgrade is equipped; the shop hides its filters when it is small (fewer than 9 cards / 5 upgrades).
**Recovery**: OBJECTIVE in the top bar; the counter reads `Repairs 0/3`.
**All phases**: the objective text of Investigation (both steps), Monitoring, Hardening, Response and Recovery comes from `days.json` (`GameState.objective()`).

Not built: Monitoring (one timer row, one note at a time, one row of actions), the `Start over` after the first mistake and the one-line instruction in the Recovery tasks, and unifying the top bars of the hand-made phases.
