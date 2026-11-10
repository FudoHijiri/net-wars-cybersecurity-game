# Visual effects plan (all phases)

Status: **first pass built and tested** (see "What was built" at the end). Written after reading the code of every phase.
Goal: every interaction that matters gets a visual answer that is **not only a color change** and **not instant**.

---

## 1. Where we are today

| Area | Already animated | Instant or color-only |
|---|---|---|
| **Scene changes** | one black fade for every scene (`SceneTransitions`) | the same fade whatever the destination |
| **Dialogue** | text fades in by character, opening cover fade, sprite entrances (Joshua, Carla, phone), head bobbing | choices pop in, the speaker is only shown by the name label, the phone "ring" is a line of text, the day banner is static |
| **Investigation** | the report screen opens with an animation | switching app rebuilds the rows at once; selecting a row only recolors it; the monologue appears and disappears; a found clue only changes a tag and a counter; report chips teleport between tray and blank; wrong words vanish back to the tray; verdict is a message line |
| **Monitoring** | the log card arrives (`LogAnimation`); hints fade through the text | the verdict is a bubble **color** (green/red) only; hint tags appear at once; the rule-breaking line gets a text prefix; the score changes silently; patience bar is a plain bar; the rulebook pops open; NEXT LOG has no exit for the old card |
| **Hardening** | Carla's line types; panel text | panels swap instantly; buying only changes a text line and the wallet number; add/remove a card rebuilds the grid; equip is a list change; "DECK FULL" is a text flash; the selected tile is dimmed (color only) |
| **Response** | most of it, after the last round: bolts, shield, hit flash, dissolve, victory, finish screen | card draw and discard, HP bars (jump), energy, turn change, the start of the fight |
| **Recovery** | shake, bounce and a REPAIRED stamp inside the tasks; attention bounce on `!` markers | marker status flips by color; a task window appears and disappears at once; a repaired machine just changes state; the final check has no moment; dialogs pop |
| **Menus** | book page flip | title panels, save select, settings, pause and stage select all toggle `visible`; unlocking a day or threat has no moment |
| **Tutorial** | the highlight, the panel | the highlight jumps to the next target |

The building blocks that exist and should be reused: `ScreenEffects` (Reduce Screen Effects, Screen Shake), `ResponseFx` (pixel particles, rings, shield, sprite shader), `FadeText`, `FinishScreen` (the model of a good sequence: fade, reveal one by one, count up).

---

## 2. Rules for every effect

1. **Two channels, never color alone.** A state needs a second cue: a shape (check, cross, star, `!`), motion (pop = good, shake = wrong), text, or position. This also covers the color-blind modes.
2. **Short and non-blocking.** Feedback is 0.1 to 0.35 s. Anything longer is skippable (click or Space) and never blocks the next input that makes sense.
3. **The end state is the real state.** An effect only decorates a change that already happened in the data, so skipping or interrupting it can never desync the game.
4. **Crisp pixels.** Whole-pixel positions, scale only to exact integers once settled, and no rotated or scaled text at rest (this is what blurred the cards). Stamps rotate for a few frames and settle at 0.
5. **One vocabulary.** The same meaning always has the same effect, so the player learns it once.
6. **Respect the settings.** With *Reduce Screen Effects*: no particles, no flashes, no shake; motion becomes an instant change or a short fade. *Screen Shake* off: no shake.
7. **Pause-safe.** Anything on the pause menu or settings keeps running while the game is paused.

### The vocabulary

| Meaning | Effect | Second channel |
|---|---|---|
| Good / correct / found | pop (scale 1 → 1.15 → 1) + small gold sparkle | check or star glyph |
| Wrong / refused / full | 4-step horizontal shake + brief red flicker | cross glyph or text |
| New information | slide in from its source | label |
| A cost | the number counts down, a `-N` floats away | the number itself |
| A reward | the number counts up, `+N` floats up, sparkles at the source | the number itself |
| Needs attention | slow 1 px bounce or outline pulse | `!` |
| State becomes final | stamp: slam, tiny shake, settle | stamp word |
| Opening / closing a panel | slide + fade, from where it was triggered | |
| Switching views | the old view slides out, the new slides in, in the direction of travel | |

---

## 3. The shared toolkit (built first, used everywhere)

- **`UiFx`** (static helpers or an autoload, in `scripts/fx/`): `pop`, `shake`, `flash`, `pulse`, `slide_in/out`, `swap_views`, `stagger_in`, `count_to`, `stamp`, `fly` (an icon travels from A to B on an arc). Every call returns the `Tween` and checks `ScreenEffects` itself, so no caller repeats the rules above. Built on `tween_method` (headless-safe).
- **`PixelFx`**: the particle, ring and burst code now inside `ResponseFx`, moved into a reusable overlay layer that any scene can drop in. `ResponseFx` keeps only the fighters' animations and uses it.
- **Glyphs**: check, cross, star, `!`, lock, coin drawn in code as pixel shapes first (no art needed); replaceable by sprites later.
- **Two shaders**: the pixel dissolve (already written for the enemy) generalized, and a wipe for scene changes.
- **A test helper** that asserts: end state equals the instant state, Reduce Effects makes it instant, interrupting is safe, and takes a mid-animation screenshot.

---

## 4. Plan by phase

Priority: **A** = felt immediately, do first. **B** = good polish. **C** = nice to have.

### Investigation
| Moment | Effect | Pri |
|---|---|---|
| Switch app (7 buttons) | old rows slide out, new rows cascade in (20 ms stagger, 0.25 s total); the active app button looks pressed in | A |
| Select a row | highlight bar slides to the row; detail text crossfades; a chevron marks it (not just color) | B |
| INVESTIGATE: monologue | panel slides up and fades in, slides down on close | A |
| Clue found | row tag **stamps** (CLUE), star glyph, gold sparkle at the row, counter ticks up with a pulse | A |
| Not a clue | tag slides in quietly, no sparkle, a muted dash glyph (different shape and motion, not just color) | A |
| All clues found | REPORT button bounces and glows until pressed | A |
| Report: drag a chip | chip lifts with a shadow; the blank highlights | B |
| Report: drop / return | chip settles with a small bounce; return glides back to the tray | B |
| Report: submit | right words lock with a lock glyph and a quick sweep; wrong words shake, show a cross, and glide back to the tray | A |
| Report: solved | CASE SOLVED stamp across the page, then the finish screen (already animated) | B |

### Monitoring
| Moment | Effect | Pri |
|---|---|---|
| REPORT / LET PASS pressed | the button depresses; a **stamp** slams onto the log card: REPORTED or PASSED | A |
| Verdict right | check stamp, sparkle, `+10` flies from the card to the score | A |
| Verdict wrong | cross stamp, the card shakes with a red flicker, wrong counter bumps | A |
| Hint tags (NORMAL / SUSPICIOUS) | flip in one after another instead of appearing | B |
| Line that broke a rule | an animated underline draws under it (instead of only the text prefix) | B |
| Inspect a line | sweep highlight on the line, hint bubble slides in from the right, a red chip flies off the patience bar for the cost | A |
| Patience / shift timer low | bar pulses and shakes slightly in the last 10 % | B |
| NEXT LOG | old card slides out left while the new one arrives | B |
| Rulebook | opens like a folder (slides up, unfolds), closes the same way back | A |
| Shift over | a SHIFT OVER banner sweeps across before the finish screen | B |

### Hardening
| Moment | Effect | Pri |
|---|---|---|
| Switch panel (Shop, Deck, editors) | slide + fade in the direction of travel; the screen title slides with it | A |
| Select a shop tile | tile lifts 2 px with an outline pulse (not only dimmed) | B |
| **Buy** | the item flies from the tile to the deck / collection icon, SP wallet counts down with a floating `-N`, coin sparkles, a SOLD stamp if sold out, copies badge pops | A |
| Cannot afford | wallet shakes, `NEED N MORE` | A |
| Carla | small bob or nod when she speaks (like the dialogue sprites) | C |
| Deck editor: add | the card arcs from the list into the deck grid; the grid shifts smoothly; `DECK 12 / 20` rolls and pulses | A |
| Deck editor: remove | the card lifts out and fades; the count rolls | B |
| Deck full / under minimum | counter shakes with a red outline and a cross glyph; NEXT PHASE shakes on refusal | A |
| Upgrade editor: equip | the icon snaps into its slot with a click; a **segmented load bar** fills with an animated segment | A |
| LOAD FULL | the load bar shakes with a cross | A |
| Recommended upgrade | star twinkles | C |
| Info card | flips in when a card is selected | C |

### Response (the rest of it)
| Moment | Effect | Pri |
|---|---|---|
| Draw | cards fly from the draw pile in an arc, one after another | A |
| End turn / discard | the hand flies to the discard pile instead of vanishing | A |
| Energy | pips pop when spent and refill with a ripple on the new turn | B |
| Turn change | YOUR TURN / ENEMY TURN banner sweeps across the screen | A |
| HP bars | a **ghost bar** (white chunk) lingers then shrinks on damage; low HP pulses | A |
| Start of the fight | the enemy enters with a ring and a pixel-in (the dissolve backwards), the hero hops in | B |
| Arena opens / closes | the box draws itself from a line | C |
| Heavy damage | a quick red vignette | B |

### Recovery
| Moment | Effect | Pri |
|---|---|---|
| Open / close a task | the window opens like a terminal (expands from a line with a scanline) and closes the same way | A |
| Repair completed | marker flips `!` to a check with a sparkle; the machine puffs and its smoke or sparks stop | A |
| Marker status change | flip instead of recolor (shape already differs) | B |
| Hover or approach a station | prompt pops, outline pulse | B |
| Work order list | check marks draw themselves | B |
| **Final check** | a green scan line sweeps the office and ticks each machine in turn; a failed one flickers red | A |
| Dialog open / close | slide + fade | B |
| Task internals | smooth fills and a snap-and-glow on a correct match (shake, bounce and the stamp already exist) | B |

### Dialogue
| Moment | Effect | Pri |
|---|---|---|
| Phone call | `*Ring ring...*` makes the phone vibrate | A |
| Speaker changes | the speaker brightens and hops once, the other dims (not only the name label); the name tag slides | A |
| Choices | stagger in; the picked one flashes while the others fade | A |
| Day banner | slides in at the start | C |

### Tutorial overlay
The highlight **moves** to the next target and resizes, instead of jumping; the arrow bobs; the panel slides from its side. (A)

### Menus
| Screen | Effect | Pri |
|---|---|---|
| Title buttons | hover slides the button and shows an arrow | B |
| Save select / settings / archive / stage select | slide or scale in instead of toggling `visible` | A |
| Delete confirmation | dim fades and the box pops | B |
| Pause | window pops in over a fading dim (runs while paused) | A |
| Stage select | unlocking a day or phase breaks a lock; a finished phase gets a check stamp; the current one pulses | A |
| Book Archive | a threat that just unlocked shines and shows a NEW badge (the page flip already exists) | B |

### Scene transitions
Today every change is the same black fade. Plan: keep the fade but add a **phase title card** while it is black (for example `PHASE 3  HARDENING`, with its glyph), and a pixel-dissolve wipe (the enemy's shader) so a phase change feels different from opening a menu. With Reduce Screen Effects the scene still changes at once.

---

## 5. Order of work

1. **Toolkit** (`UiFx`, `PixelFx`, glyphs, test helper) and the unified rules for Reduce Effects.
2. **Quick wins that change how the game feels:** Monitoring stamps and verdicts, the Investigation clue found and report submit, Hardening buy, equip and panel switching, Recovery task open and repair.
3. **Response and the Final check:** hand draw and discard, ghost HP bars, turn banners, the scan line.
4. **Dialogue, tutorial, menus, stage select** and the scene-transition title cards.
5. **Accessibility pass:** find every remaining color-only cue; verify each effect with Reduce Effects on and with the color-blind modes; performance check (particles capped, no per-frame allocation).

Each step ends with tests (end state equals instant state, reduced mode, interruption) and screenshots, like the Response work.

---

## 6. Decisions needed

1. **Intensity.** Snappy and subtle (0.1 to 0.2 s, small motion) or punchy (bigger pops, more particles)? Recommended: snappy in the computer-style phases (Investigation, Monitoring, Hardening) and punchy only in Response and rewards.
2. **Phase transitions.** One fade plus title cards, or a themed wipe per phase? Recommended: title cards plus the one pixel-dissolve wipe.
3. **Icons.** Code-drawn pixel glyphs first (fast, replaceable), or will you draw the check, cross, star and stamp sprites yourself? Recommended: code-drawn first.
4. **Sound.** Every effect above has a natural sound cue. Out of scope for this plan, but should the toolkit have an optional hook for it now?
5. **Order.** Is step 2 the right first target, or is there a phase you want finished first?

---

## 7. What was built in the first pass

Decisions taken (the defaults of section 6): snappy in the computer-style phases, punchy in Response and rewards; a title card on phase changes; code-drawn glyphs; no sound hook.

**Toolkit** (`scripts/fx/`): `UiFx` (pop, shake, flash, fade, slide, swap_views, stagger_fade, count_to, stamp, stamp_label, attention, hop, dim, float_text, fly, badge, sparkle, banner, terminal_open/close, sweep), `PixelFx` (particles, rings, slashes, screen flash; `ResponseFx` now extends it), `Glyph` (check, cross, star, exclaim, lock, coin, card) and the `Fx` autoload (an overlay above the game and below the scene fade). Every helper checks Reduce Screen Effects and Screen Shake itself.

| Phase | Built | Not built yet |
|---|---|---|
| Investigation | app rows cascade in; detail text crossfades; monologue slides up; clue stamps, glints and gets a star while the counter jumps; a normal entry fades its tag in quietly; REPORT bounces until pressed; report: placed word pops, returned word fades back, right words lock with a lock icon, wrong words shake with a cross, CASE SOLVED stamp | chip lift on drag, chips gliding back to the tray, monologue closing animation |
| Monitoring | verdict stamped on the card (REPORTED / PASSED / TIME UP) with a check or cross, a coin flies to the score on a right call, the card shakes on a wrong one, hint tags fade in one by one, an inspected line lights up and shows its cost on the bar, notes fade in, the rulebook slides | NEXT LOG exit, low-time pulse, SHIFT OVER banner |
| Hardening | panels slide in the direction of travel, the wallet counts and floats the change, a bought item flies to the deck or upgrades button with sparkles and an OWNED stamp, NEED N MORE shakes the buy button, card add/remove and equip fly with a pop, DECK FULL and LOAD FULL shake with a cross, a refused NEXT PHASE shakes | segmented load bar, copies badge, Carla nod, info-card flip, recommended star |
| Response | (earlier) bolts, shield, hit, defeat, victory; (now) the fighters form out of pixels, YOUR TURN / ENEMY TURN banners, cards fly out of the draw pile one by one and the hand flies to the discard pile, HP bars leave a white chunk, a heavy hit flashes the screen | energy pips, arena drawing itself |
| Recovery | task windows open and close like a terminal, a repaired marker pops with sparkles, the Final check scans the office with a green line and ticks each machine, dialogs fade in | hover prompts, work-order check animation, task internals |
| Dialogue | the phone vibrates on the ring line, the speaker is lit and hops while the others dim, choices come in one by one and the picked one flashes, the name tag fades | day banner |
| Tutorial | the highlight and the panel glide from one step to the next | |
| Menus | pause window drops in, delete confirmation drops in, RESUME hops | the title screen already had slide animations (the plan overstated this); stage-select unlock and check stamps, settings |
| Transitions | a phase title card on the black screen (skippable, not with Reduce Effects, not on a reload) | the pixel-dissolve wipe |

Lessons that changed the code: a text label must not be scaled or rotated at rest (attention is a whole-pixel bounce, not a pulse); effects that touch layout (a window opening) must keep running while the game is paused; a script that is loaded before the autoloads exist must find them by name (`UiFx` and `PixelFx` do).
