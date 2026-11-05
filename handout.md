# NET WARS (Reworked) — Current Plans Handout

_Last updated: 2026-10-25_

_This handout is the current source of truth for the project's plans._

## 1. Project snapshot

- **NET WARS** is a 2D pixel-art cybersecurity educational game built in **Godot**, as a BSIT capstone.
- Audience: the general public, with little or no cybersecurity background. It should feel like a game first and teach concepts naturally.
- Visual identity: pixel-art UI built on the palette in section 5. No heavy neon or cyberpunk decoration.
- Team uses **GitHub** for version control.

## 2. Structure of the game

The game is a run of 8 "Days". Each Day is one cybersecurity threat:

| Day | Threat | Day title |
|---|---|---|
| 1 | Credential Abuse | An Unusual Login |
| 2 | Malware | Something Got In |
| 3 | Ransomware | Files Under Lock |
| 4 | Insider Threat | Someone Inside |
| 5 | Data Exfiltration | Data on the Move |
| 6 | DDoS | Under Heavy Load |
| 7 | Phishing | A Message to Trust |
| 8 | Web Application Attack | The Open Door |

Each Day opens with story dialogue (visual-novel style), then runs five objectives. **Each objective uses different gameplay:**

| Objective | Gameplay | Inspired by |
|---|---|---|
| Investigation | Point-and-click detective game, then a word-puzzle report | Zenless Zone Zero's Truth Journal |
| Monitoring | Puzzle observation game: inspect logs, then Pass or Report | Papers, Please |
| Hardening | Deckbuilding shop | Library of Ruina (deck editing, without the book system) |
| Response | Turn-based card battle with a bullet-hell enemy turn | Slay the Spire + Undertale / Deltarune |
| Recovery | Many short repair microgames | Among Us task system |

Choices carry forward: points earned in Investigation and Monitoring are spent in Hardening, the deck built in Hardening is used in Response, and the damage taken in Response decides what must be repaired in Recovery.

### 2.1 Investigation
- Point-and-click detective game. The player inspects entries and uses an **"Investigate This Clue"** button, which plays a short monologue saying whether the clue was correct.
- The player must find **4 correct clues** (decoy entries are mixed in). After the 4th, a monologue tells them to press the **Report** button.
- **Report = word puzzle**, very similar to the Truth Journal. A long sentence explains the case and has **4 blanks**. At the bottom are **8 clue chips: 4 correct, 4 false**. The player drags a chip (or selects it, then presses the box) to place it in the blank where it belongs.
- The phase ends when all 4 are placed correctly. Wrong placements bounce back so the player can retry.
- Points are earned here for use in Hardening.

### 2.2 Monitoring
- Puzzle observation game similar to Papers, Please.
- The player inspects recent logs one at a time and makes a call:
  - **Suspicious** (they spot something wrong): press **Report**.
  - **Normal**: press **Pass**.
- Correct calls earn points for Hardening.

### 2.3 Hardening
- Deckbuilding shop. The player spends the points earned in Investigation and Monitoring on **upgrades and cards**.
- The player starts with **9 basic cards** and can edit the deck here, replacing any of the 9 with cards they buy.
- Deck editing follows how **Library of Ruina** handles deckbuilding, minus the book system.

### 2.4 Response
- A **Slay the Spire**-style turn-based card game at its core.
- **Enemy turn = bullet hell.** It plays like Undertale or Deltarune: the player controls a soul/heart and dodges attacks.
- Cards are used for **attacks, block and spells**.
- **Block** lets the heart tank hits. The amount of block decides how many hits it can absorb. The heart has brief invulnerability after being hit.
- Damage taken here carries into Recovery.

### 2.5 Recovery
- A lot of short **microgames**, each tied to a different part of the system or network that needs repairing (including the backup database).
- Plays like the **Among Us** task system: the player works through various minigames, set in the theme of a network system.

## 3. Active work

### 3.1 New Investigation (in progress)
- Built in the `AI generated/` folder by copying and remaking the existing Investigation scene. Nothing outside that folder is modified.
- Data-driven: clues, monologues, report sentence and chips all live in JSON (starting with `AI generated/data/day1_investigation.json`), so other Days can be added without code changes.
- Day 1 (Credential Abuse) clue sources: email, sign-in history, computer activity, internet traffic, files. Four are real clues and the rest are decoys.
- It follows the Truth Journal's concept but **not its look**. It uses the NET WARS palette and UI style.
- A Claude Code prompt for building this has been written.

### 3.2 Plain-language writing rule
- All player-facing text must be plain and low-jargon for a general audience: clues, monologues, report sentences, chip labels, buttons and feedback.
- Short sentences, everyday words. If a technical term is unavoidable, explain it in the same line.
- Chips are short everyday phrases (for example "a stolen password", "a stranger's computer"). Fakes should be plausible but clearly wrong once the player reasons it through.
- Monologues are 1–2 short sentences and explain why a clue matters.

### 3.3 Title screen and intro rework
- The Windows-desktop-style title screen is being replaced.
- The existing monitor is reused for a **Katana ZERO-style TV intro**: a loading screen plus the dev team credits.
- It then transitions to a **new main menu that no longer looks like a computer desktop**.

### 3.4 Replacing AI-generated content
- The plan is to replace AI-generated content in NetWars with **human-made** content over time.
- The `AI generated/` folder currently holds the reworked Monitoring, Report, Transition, Pause, Debug and Accessibility pieces. Treat these as stand-ins until replaced.
- The Monitoring in that folder was built for an earlier design. It needs revisiting against the Papers, Please-style plan in 2.2.

### 3.5 Documentation
- Building a **progress report with a Gantt chart** for the reworked project.
- The capstone manuscript is being finalized separately (Chapters 1 and 2 revised, IEEE references added).

## 4. Design and accessibility principles

- Prefer simple, understandable systems. Avoid unnecessary complexity.
- Gameplay interactions over decorative UI. The screens should feel like one cohesive world, not unrelated menus.
- Use Godot `Control` nodes for UI-heavy screens.
- **Never communicate important information through colour alone.** This matters most for Monitoring (Pass vs Report), Investigation feedback (correct vs wrong) and block/health in Response. Pair colour with text, icons or shapes.
- Colorblind Mode is functional (Normal Vision plus eight colour-vision types).
- UI scaling and High Contrast were deliberately **removed** because they broke layouts or were weak implementations.
- Visual-comfort options being considered: Disable Shaders, Disable Dynamic Lighting (and Reduce Screen Effects).
- Prefer reusable pixel-art UI components over large amounts of one-off art.
- Bullet-hell sections need extra care for accessibility (clear hitbox, readable bullets, comfortable speed and invulnerability time).

## 5. UI colour palette

The UI palette is these 16 colours (it matches the well-known Sweetie 16 palette):

| Hex | | Hex | |
|---|---|---|---|
| `#1a1c2c` | darkest navy | `#257179` | dark teal |
| `#5d275d` | deep purple | `#29366f` | navy blue |
| `#b13e53` | red | `#3b5dc9` | royal blue |
| `#ef7d57` | orange | `#41a6f6` | sky blue |
| `#ffcd75` | yellow | `#73eff7` | cyan |
| `#a7f070` | light green | `#f4f4f4` | off-white |
| `#38b764` | green | `#94b0c2` | light grey-blue |
| `#566c86` | slate | `#333c57` | dark slate |

The dark navy, blue and cyan colours (`#1a1c2c`, `#29366f`, `#3b5dc9`, `#41a6f6`, `#73eff7`) carry the retro-computer base. The warm colours and greens add emphasis and feedback.

## 6. Still to define or decide

- What a Monitoring "log" looks like, what makes one suspicious, and how many logs per Day.
- How points are earned and spent: amounts from Investigation and Monitoring, card and upgrade prices, and the 9 starting basic cards.
- Library of Ruina-style deck rules: deck size limit, card duplicates, and card cost or energy.
- Response details: bullet patterns per threat, how block converts into hits absorbed, spells, and boss behaviour for each of the 8 threats.
- Recovery microgame types per network component and the backup database.
- Day 2–8 Investigation datasets (Day 1 is the template).
- Final art and audio, replacing the AI-generated placeholders.
