# Hardening: decluttering plan (a suggestion, nothing is built)

## What makes the screens busy now

| Screen | Controls the player has to read before doing anything |
|---|---|
| Shop | Two shelves, each with its own row of filters (cards: NEW, OFFENSIVE, DEFENSIVE, UTILITY and a cost list; upgrades: NEW, RECOMMENDED and a cost list), Carla's portrait and speech box, three navigation buttons, the info panel and the buy button |
| Deck editor | The deck grid, a collection list with OFFENSIVE / DEFENSIVE / UTILITY and a cost list, the info panel, three navigation buttons |
| Upgrade editor | The same shape with RECOMMENDED and a cost list |
| All of them | The screen title, the day, the Security Points, the objective bar and the pause button |

The same three navigation buttons change names and places from screen to screen (LEAVE, GO TO SHOP, EDIT DECK, EDIT UPGRADES), and every list repeats its own filter row.

## The plan

**1. One FILTER button per list, and the filters in a pop-up.**
- Each list (the card shelf, the upgrade shelf, the deck editor's collection, the upgrade editor's collection) has a single `FILTER` button where the row of filters is now. A small badge on it shows how many filters are on (`FILTER 2`), so the player always sees that something is hidden.
- Pressing it opens a small panel right under the button with the filters as check boxes in groups: **Type** (offensive, defensive, utility), **Cost** (0, 1, 2, 3 or more, instead of the cost list), and **Show** (new today, recommended). Buttons CLEAR and DONE at the bottom; Escape or a click outside closes it.
- The panel is the same on every screen. A list that has no use for a group does not show it (the upgrade lists have no Type).
- Filters stay while the player moves between shop, deck and upgrades, so coming back does not reset the view. One small line under the list's title says what is on ("Offensive, cost 1-2"), with an x to clear it.
- Lists with only a few items (the filters are already hidden when there are fewer than a few cards) do not show the button at all.

**2. One navigation rail instead of three buttons that change.**
- A narrow rail on the left, the same on every Hardening screen: `SHOP`, `DECK`, `UPGRADES` as three tabs (the current one lit), and `NEXT PHASE` at the bottom. LEAVE (back to the day select) moves to the pause menu, where the other ways out already are.
- This removes the buttons that were different on every screen, and the player always sees where they are.

**3. Carla smaller.**
- The portrait shrinks and her line goes into a one- or two-line speech strip under the shop header. The big white speech box under the portrait goes. The line fades after a few seconds, and her last line can be read again by pointing at the portrait.

**4. The info panel only when there is something to show.**
- It shows the picked or pointed-at card or upgrade, in the same place on every screen, and is empty (with one hint line) otherwise. The buy button lives inside it, so the shelves do not need a button under every tile (the price stays on the tile as a number).

**5. Optional, if the shop is still crowded: tabs instead of two shelves.**
- `CARDS | UPGRADES` tabs on the shop, each with the full height. This gives bigger tiles and no second set of filters, at the cost of not seeing both at once. It can be decided after steps 1 to 4 are tried.

## Order of work and risks

1. The FILTER button and pop-up as one reusable control (`FilterMenu`), used by the four lists. Risk: the lists read their filter buttons directly (`shop.gd`, `deck_editor.gd`, `upgrade_editor.gd`), so each needs a small change to read the control instead. Tests: the filters give the same lists as now.
2. The navigation rail on the three screens and `NEXT PHASE`. Risk: the scene (`Hardening.tscn`) has the buttons placed by hand, so this is mostly scene work that you may want to do yourself; I would write the script side.
3. Carla's strip and the info panel.
4. Keyboard and focus: every control reachable with Tab and Enter, the pop-up traps focus until it closes, Escape closes it.
5. Check the 640 x 360 layout with the scan used for the text overflow, with all eight days' cards and upgrades.

## What stays

The deck editor's grid, the card faces, the upgrade icons, the load meter, the Security Points counter and the objective bar. Only the controls around them change.

## As built

Switch: `COMPACT_LAYOUT` at the top of `scripts/gameplay/hardening/hardening.gd`. `true` is the decluttered layout, `false` is the layout of `Hardening.tscn` exactly as it was laid out. The scene is not edited: `hardening_compact.gd` moves and hides what is in it when the scene starts, so going back is one word. (The keyword colors and tooltips below stay either way.)

- **Right column on every screen (x 512 to 632):** the tabs HUB, SHOP, DECK, UPGRADES (the one you are on is lit) and NEXT PHASE at the bottom. The three buttons that changed on every screen are hidden. LEAVE is the pause menu's BACK TO STAGE SELECT. The deck-only visit (OPEN DECK) has no SHOP tab and no NEXT PHASE, as before.
- **FILTER button** (`filter_menu.gd`) for each of the four lists, with the existing filter buttons and drop-downs moved into a panel under it (so the lists read them as they always did). The badge counts the filters on (`FILTER 2`), CLEAR turns them off, DONE, a click outside or Escape closes it. A list too short to need filters has no button. Filters stay while moving between the tabs. Not done from the plan: the cost as check boxes (it stays the drop-down) and the line that says what is on under the list title (the badge and the panel say it).
- **Carla** is drawn at the size of her sprite, 48 x 48 pixels (before, the sprite was doubled to 96 x 96). Nothing is scaled down, so the pixels stay sharp. Her line stays in a smaller speech panel under her; the shop moved to the left and her column is on the right, over the NEXT PHASE button.
- **Seeing a whole card:** the shop shelves still show full cards, and the info panel of the Deck and Upgrade editors stays (now in the right column, with the card at its real size, 72 x 100). Pointing at a card in the collection or the deck shows it there.
- **Keywords:** the texts of the BUY panel and of the info panels color Block, Dodge, Exposed, Leak... like the Response fight does (`keyword_text.gd`, the words are in `data/keywords.json`). Pointing at a colored word shows what it means. Every card picture in the shop and the decks also has the same explanations as its tooltip.
- **Tutorial:** its steps for Hardening are pointed at the new controls (`adapt_tutorial`), and the words that spoke of LEAVE and of the filter buttons are changed.
- **Background:** the moving background of Hardening is unchanged. `hardening_background.gdshader` now has `tile_size`, so the same shader can scroll another square tile (the Response grid tile is 40 x 40) when Response gets its moving background.
- **Not done:** step 5 (tabs instead of the two shelves in the shop).
