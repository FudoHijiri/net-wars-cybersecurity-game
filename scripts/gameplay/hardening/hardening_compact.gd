class_name HardeningCompact
extends Node
## The decluttered layout of the Hardening phase (docs/hardening_declutter_plan.md). Hardening.tscn is not changed:
## this moves and hides what is in it when the scene starts, so the old layout is one switch away
## (COMPACT_LAYOUT in hardening.gd; false leaves the scene exactly as it was laid out).
##
## What it does:
##  - one column on the right of every screen (x 512 to 632): the four tabs HUB, SHOP, DECK, UPGRADES (the current one lit)
##    and NEXT PHASE at the bottom, instead of three buttons that change names and places on every screen; between them
##    the card or upgrade in focus (the info panel of the editors) or Carla (the shop);
##  - one FILTER button for each list, with the filters in a panel under it (FilterMenu);
##  - Carla at the size of her sprite (48 x 48 pixels, one pixel on the screen for each pixel of the sprite) with her
##    line in a small panel under her.

const COLUMN_X := 512.0
const COLUMN_W := 120.0
const MIDDLE_W := 264.0 # the width of the stats and the upgrades of the hub (x 240 to 504)
const TABS := [["HUB", "Deck"], ["SHOP", "Shop"], ["DECK", "DeckEditor"], ["UPGRADES", "UpgradeEditor"]]
const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
const BACK := Color(0.101960786, 0.10980392, 0.17254902)
const LINE := Color(0.3372549, 0.42352942, 0.5254902)
const TEXT := Color(0.95686275, 0.95686275, 0.95686275)
const GOLD := Color(1, 0.8039216, 0.45882353)

## The tutorial targets of the old buttons -> the controls that took their place; and the words of the steps that
## spoke of those buttons.
const TARGETS := {
	"Deck/Buttons/OpenShop": "Rail/TabShop",
	"Deck/Buttons/EditPassives": "Rail/TabUpgradeEditor",
	"Deck/Buttons/EditDeck": "Rail/TabDeckEditor",
	"Deck/NextPhase": "Rail/NextPhase",
	"Shop/Buttons/LeaveButton": "Rail/TabDeck",
	"DeckEditor/Buttons/GoToShop": "Rail/TabShop",
	"UpgradeEditor/Collection/RecommendedFilter": "UpgradeEditor/Collection/FilterMenu",
}
const WORDS := {
	"Leave when you are done. You can come back before the fight.": "These tabs take you between the hub, the shop, the deck and the upgrades. You can come back before the fight.",
	"The buttons above filter by type and cost.": "FILTER above it narrows the list by type and cost.",
	"RECOMMENDED shows only those.": "Open FILTER and turn on RECOMMENDED to see only those.",
}

var _h: Control
var _rail: Control
var _tabs: Dictionary = {} # panel name -> its tab
var _filters: Array[FilterMenu] = []
var _build_only := false
var _checklist: RichTextLabel # the hub's "before the fight"


## `hardening` is the Hardening scene root, after its panels are set up.
func setup(hardening: Control, build_only: bool) -> void:
	_h = hardening
	_build_only = build_only
	_rail = Control.new()
	_rail.name = "Rail"
	_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rail.set_anchors_preset(Control.PRESET_FULL_RECT)
	_h.add_child(_rail)
	for old: String in ["Deck/Buttons", "Shop/Buttons", "DeckEditor/Buttons", "UpgradeEditor/Buttons"]:
		_h.get_node(old).hide() # the buttons that changed on every screen; their links stay, unused
	_build_tabs(build_only)
	_move_next_phase()
	_layout_hub()
	_layout_shop()
	_layout_deck_editor()
	_layout_upgrade_editor()
	(_h.get_node("Shop") as HardeningShop).fly_targets = {"card": _tabs.get("DeckEditor"), "upgrade": _tabs.get("UpgradeEditor")}
	(_h.get_node("Deck") as HardeningDeck).set_upgrade_hint("Nothing equipped yet. Open the UPGRADES tab to equip upgrades.", 240.0)


## Lights the tab of the screen that is shown.
func show_panel(panel: String) -> void:
	for name: String in _tabs:
		(_tabs[name] as Button).set_pressed_no_signal(name == panel)
	if panel == "Deck":
		_refresh_checklist()
	elif panel == "Shop":
		_settle_shop.call_deferred()


## Closes any open filter panel (a screen change).
func close_filters() -> void:
	for menu in _filters:
		menu.close()


## The tutorial steps of Hardening, pointed at the new controls.
func adapt_steps(steps: Array) -> Array:
	var adapted: Array = []
	for step: Dictionary in steps:
		var copy := step.duplicate()
		var target := str(copy.get("target", ""))
		if TARGETS.has(target):
			copy["target"] = TARGETS[target]
		var text := str(copy.get("text", ""))
		for old: String in WORDS:
			text = text.replace(old, WORDS[old])
		copy["text"] = text
		adapted.append(copy)
	return adapted


# --- the column ---

func _build_tabs(build_only: bool) -> void:
	var group := ButtonGroup.new()
	var y := 32.0
	for entry: Array in TABS:
		if build_only and entry[1] == "Shop":
			continue # the deck-only visit has no shop
		var tab := Button.new()
		tab.name = "Tab" + str(entry[1])
		tab.text = entry[0]
		tab.toggle_mode = true
		tab.button_group = group
		tab.focus_mode = Control.FOCUS_ALL
		tab.add_theme_font_override("font", FONT)
		tab.add_theme_font_size_override("font_size", 6)
		tab.add_theme_color_override("font_color", TEXT)
		tab.add_theme_color_override("font_hover_color", TEXT)
		tab.add_theme_color_override("font_pressed_color", GOLD)
		tab.add_theme_color_override("font_hover_pressed_color", GOLD)
		tab.add_theme_stylebox_override("normal", _box(BACK, LINE))
		tab.add_theme_stylebox_override("hover", _box(Color(0.17, 0.19, 0.28), TEXT))
		tab.add_theme_stylebox_override("pressed", _box(Color(0.24, 0.2, 0.12), GOLD))
		tab.add_theme_stylebox_override("hover_pressed", _box(Color(0.24, 0.2, 0.12), GOLD))
		tab.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), GOLD))
		_rail.add_child(tab)
		place(tab, Rect2(COLUMN_X, y, COLUMN_W, 16))
		y += 18.0
		_tabs[entry[1]] = tab
		tab.pressed.connect(_on_tab_pressed.bind(str(entry[1])))


func _on_tab_pressed(panel: String) -> void:
	if (_h.get_node(panel) as Control).visible:
		(_tabs[panel] as Button).set_pressed_no_signal(true) # the tab of the screen that is open stays lit
		return
	_h.call("_show", panel)


## NEXT PHASE is the same button as before, in the same place on every screen.
func _move_next_phase() -> void:
	var next := _h.get_node("Deck/NextPhase") as Button
	next.reparent(_rail, false)
	place(next, Rect2(COLUMN_X, 316, COLUMN_W, 32))


# --- the screens ---

## The Build Hub: stats and upgrades fill the width beside the column, and the column holds a check of what is ready
## for the fight (the upgrades panel and its tiles are anchored, so they follow the size of the panel).
func _layout_hub() -> void:
	place(_h.get_node("Deck/Stats") as Control, Rect2(240, 40, MIDDLE_W, 88))
	# the cost bars are anchored and grow with the panel; the legend has a fixed place, so it is centered in the part of
	# the panel on the right of the bars
	var bars_end := 240.0 + MIDDLE_W * (_h.get_node("Deck/Stats/CostCurveRow") as Control).anchor_right
	var region := Rect2(bars_end, 0.0, 240.0 + MIDDLE_W - bars_end, 0.0)
	var legend := _h.get_node("Deck/Stats/DeckStats") as Control
	legend.global_position.x = region.position.x + (region.size.x - legend.size.x) / 2.0
	var legend_title := _h.get_node("Deck/Stats/CardsInDeck") as Label
	legend_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(legend_title, Rect2(Vector2(region.position.x, legend_title.global_position.y), Vector2(region.size.x, legend_title.size.y)))
	place(_h.get_node("Deck/Upgrades") as Control, Rect2(240, 136, MIDDLE_W, 212))
	(_h.get_node("Deck") as HardeningDeck).upgrade_columns = 3 # the tiles are 64 pixels wide
	if not _build_only:
		_build_checklist()


## "Before the fight": what is ready and what is not, so the hub shows what to do next.
func _build_checklist() -> void:
	var stats := _h.get_node("Deck/Stats") as Control
	var panel := Panel.new()
	panel.name = "Checklist"
	panel.add_theme_stylebox_override("panel", stats.get_theme_stylebox("panel"))
	_h.get_node("Deck").add_child(panel)
	place(panel, Rect2(COLUMN_X, 108, COLUMN_W, 200))
	var title := Label.new()
	title.text = "BEFORE THE FIGHT"
	title.add_theme_font_override("font", FONT)
	title.add_theme_font_size_override("font_size", 6)
	title.add_theme_color_override("font_color", GOLD)
	title.position = Vector2(6, 5)
	panel.add_child(title)
	_checklist = RichTextLabel.new()
	_checklist.bbcode_enabled = true
	_checklist.scroll_active = false
	_checklist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_checklist.add_theme_font_override("normal_font", FONT)
	_checklist.add_theme_font_size_override("normal_font_size", 6)
	_checklist.position = Vector2(6, 18)
	_checklist.size = Vector2(COLUMN_W - 12.0, 176)
	panel.add_child(_checklist)


func _refresh_checklist() -> void:
	if _checklist == null:
		return
	var state: HardeningState = _h._state
	var good := GameColors.color(&"good").to_html(false)
	var bad := GameColors.color(&"bad").to_html(false)
	var warn := GameColors.color(&"highlight").to_html(false)
	var lines: Array[String] = []
	var cards := state.deck_list().size()
	if cards < HardeningState.MIN_DECK:
		lines.append("[color=#%s]Deck: %d cards. You need %d or more.[/color]" % [bad, cards, HardeningState.MIN_DECK])
	else:
		lines.append("[color=#%s]Deck: %d / %d cards.[/color]" % [good, cards, HardeningState.DECK_SIZE])
	var missing: String = _h._missing_critical_upgrade()
	if not missing.is_empty():
		lines.append("[color=#%s]Missing: %s. The attacks of this fight cannot be stopped without it.[/color]" % [bad, missing])
	if state.equipped_list().is_empty():
		lines.append("[color=#%s]No upgrade is equipped.[/color]" % warn)
	else:
		lines.append("[color=#%s]Upgrades: load %d / %d.[/color]" % [good, state.equipped_load(), state.upgrade_budget()])
	var recommended := 0
	for id: String in state.owned_list("upgrade"):
		if state.upgrades.has(id) and not state.equipped_list().has(id) and state.is_recommended(id):
			recommended += 1
	if recommended > 0:
		lines.append("[color=#%s]%d upgrade%s that answer%s your clues %s not equipped.[/color]" % [warn, recommended, "s" if recommended > 1 else "", "" if recommended > 1 else "s", "are" if recommended > 1 else "is"])
	var wallet := GameState.wallet()
	if wallet > 0:
		lines.append("You have %d SP to spend in the shop." % wallet)
	_checklist.text = "\n\n".join(lines)


## The shop moves to the left (its shelves keep their sizes, a little narrower), Carla and her line take the column.
func _layout_shop() -> void:
	var content := _h.get_node("Shop/ShopContent") as Control
	var rect := content.get_global_rect()
	place(content, Rect2(Vector2(8.0, rect.position.y), Vector2(496.0, rect.size.y))) # its shelves are anchored in it: they follow

	# the divider between the shelves was drawn for a panel 520 wide: it stops at the narrower panel
	var line := content.get_node("Line2D") as Line2D
	var points := line.points
	for i in points.size():
		points[i].x = minf(points[i].x, 496.0)
	line.points = points
	var keeper := _h.get_node("Shop/ShopKeeper") as Control
	place(keeper, Rect2(COLUMN_X + (COLUMN_W - 52.0) / 2.0, 108, 52, 52))
	var sprite := keeper.get_node("AnimatedSprite2D") as Node2D
	sprite.scale = Vector2.ONE # the sprite is 48 x 48: shown as it is, not stretched
	sprite.position = Vector2(26, 26)
	var dialogue := _h.get_node("Shop/Dialogue") as Control
	place(dialogue, Rect2(COLUMN_X, 164, COLUMN_W, 84))
	place(dialogue.get_node("Content") as Control, Rect2(COLUMN_X, 164, COLUMN_W, 84))

	_filter_for(content, content.get_node("CardsShop") as Control, [
		{"title": "Type", "controls": [content.get_node("OffensiveFilter"), content.get_node("DefensiveFilter"), content.get_node("UtilityFilter")]},
		{"title": "Cost", "controls": [content.get_node("CostFilterCards")]},
		{"title": "Show", "controls": [content.get_node("NewFilterCards")]},
	])
	_filter_for(content, content.get_node("UpgradesShop") as Control, [
		{"title": "Load", "controls": [content.get_node("CostFilterUpgrades")]},
		{"title": "Show", "controls": [content.get_node("NewFilterUpgrades"), content.get_node("RecommendedFilter")]},
	])


## The scroll bar of the upgrades shelf was under the BUY panel. The shelf is as tall as it needs to be (its tiles and
## the scroll bar, 101 pixels) and goes up a little, and the BUY panel is lower. Done after the first layout, so the
## shelf does not keep a height that the first layout of its tiles asked for (it is done each time the shop opens).
func _settle_shop() -> void:
	var content := _h.get_node("Shop/ShopContent") as Control
	var label := content.get_node("UpgradesShop") as Control
	place(label, Rect2(Vector2(label.get_global_rect().position.x, 182.0), label.size))
	var shelf := content.get_node("UpgradeShopScroll") as Control
	place(shelf, Rect2(Vector2(shelf.get_global_rect().position.x, 196.0), Vector2(shelf.size.x, shelf.get_combined_minimum_size().y)))
	var buy := content.get_node("Panel") as Control
	place(buy, Rect2(Vector2(buy.get_global_rect().position.x, shelf.get_global_rect().end.y + 1.0), Vector2(buy.size.x, 0)))
	buy.size.y = 350.0 - buy.global_position.y
	var row := buy.get_node("HBoxContainer") as Control
	row.position.y = 3.0
	row.size.y = buy.size.y - 6.0
	# the small line (what you own, the load) goes above the BUY button, so the title and three lines of text fit
	var shop := _h.get_node("Shop") as HardeningShop
	if not shop.short_hint:
		shop.short_hint = true
		shop.refresh()
	var hint := buy.get_node_or_null("HBoxContainer/VBoxContainer/Hint") as Label
	if hint != null:
		hint.reparent(buy, false)
	hint = buy.get_node("Hint") as Label
	var price := buy.get_node("PriceButton") as Control
	var button_x := buy.global_position.x + buy.size.x * price.anchor_left # the button is anchored in the panel
	var button_w := buy.size.x * (price.anchor_right - price.anchor_left)
	place(hint, Rect2(button_x, buy.global_position.y + 3.0, button_w, 12.0))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


func _layout_deck_editor() -> void:
	var collection := _h.get_node("DeckEditor/Collection") as Control
	_widen_collection(collection, _h.get_node("DeckEditor/Collection/ScrollContainer") as Control)
	_filter_for(collection, collection, [
		{"title": "Type", "controls": [collection.get_node("OffensiveFilter"), collection.get_node("DefensiveFilter"), collection.get_node("UtilityFilter")]},
		{"title": "Cost", "controls": [collection.get_node("CostFilter")]},
	], true)
	_info_panel(_h.get_node("DeckEditor/Info") as Control, _h.get_node("DeckEditor/Info/Card") as Control, null)


func _layout_upgrade_editor() -> void:
	var collection := _h.get_node("UpgradeEditor/Collection") as Control
	_widen_collection(collection, _h.get_node("UpgradeEditor/Collection/ScrollContainer") as Control)
	_filter_for(collection, collection, [
		{"title": "Load", "controls": [collection.get_node("CostFilter")]},
		{"title": "Show", "controls": [collection.get_node("RecommendedFilter")]},
	], true)
	_info_panel(_h.get_node("UpgradeEditor/Info") as Control, null, _h.get_node("UpgradeEditor/Info/Sprite") as Control)


## The collection list is wider (the column of the info panel is narrower) and starts under the FILTER row.
func _widen_collection(collection: Control, scroll: Control) -> void:
	var rect := collection.get_global_rect()
	place(collection, Rect2(rect.position, Vector2(264.0, rect.size.y)))
	place(scroll, Rect2(rect.position + Vector2(2, 22), Vector2(260.0, rect.size.y - 24.0)))
	for child in scroll.get_children():
		if child is Control:
			(child as Control).size.x = 260.0


## The info panel of an editor: in the right column, under the tabs, with the card (or the icon), the name and the text
## at the size they are drawn (a card is 72 x 100 pixels: it is not stretched with the panel).
func _info_panel(panel: Control, card: Control, icon: Control) -> void:
	place(panel, Rect2(COLUMN_X, 108, COLUMN_W, 200))
	var top := panel.global_position.y
	if card != null:
		place(card, Rect2(COLUMN_X + (COLUMN_W - 72.0) / 2.0, top + 4.0, 72, 100))
	if icon != null:
		place(icon, Rect2(COLUMN_X + (COLUMN_W - 32.0) / 2.0, top + 6.0, 32, 32))
	var name_y := top + (106.0 if card != null else 42.0)
	place(panel.get_node("Name") as Control, Rect2(COLUMN_X + 4.0, name_y, COLUMN_W - 8.0, 16))
	place(panel.get_node("Description") as Control, Rect2(COLUMN_X + 4.0, name_y + 18.0, COLUMN_W - 8.0, 200.0 - (name_y - top) - 22.0))


# --- helpers ---

## A FILTER button in the header of a list. `beside` is the title it goes after; when it is the panel of the
## list itself (`inside`), the button goes in the top left corner of the panel.
func _filter_for(parent: Control, beside: Control, groups: Array[Dictionary], inside: bool = false) -> void:
	var at := beside.get_global_rect().position + Vector2(4, 3) if inside else Vector2(beside.get_global_rect().end.x + 6.0, beside.get_global_rect().position.y + 1.0)
	var menu := FilterMenu.make(parent, at, groups)
	if menu != null:
		_filters.append(menu)


## A rectangle in screen coordinates, whatever the anchors of the control were in the scene.
static func place(control: Control, rect: Rect2) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.global_position = rect.position
	control.size = rect.size


static func _box(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_border_width_all(1)
	style.border_color = border
	style.set_content_margin_all(2)
	return style
