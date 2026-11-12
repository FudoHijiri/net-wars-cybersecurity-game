extends Control
## Hardening phase. One panel is shown at a time: the Build Hub (deck.gd), the shop (shop.gd), the Deck
## Editor (deck_editor.gd) and the Upgrade Editor (upgrade_editor.gd). The panels share one HardeningState;
## this script switches between them and ends the phase.
##
## Opened from the day select with OPEN DECK (SceneManager.build_only) it is only the place to change the
## deck and the upgrades: no shop, no objective and no move to the next phase. It saves when it is left.

## The decluttered layout (HardeningCompact, docs/hardening_declutter_plan.md): one column of tabs on the right, a FILTER
## button for each list, a small Carla. false gives the layout of the scene as it was laid out, unchanged.
const COMPACT_LAYOUT := true

## Panel name -> the text of the top bar.
const TITLES := {"Deck": "1  BUILD HUB", "Shop": "2  SHOP", "DeckEditor": "3  EDIT DECK", "UpgradeEditor": "4  UPGRADES"}
## Button (path from this scene) -> the panel it opens. A button the scene does not have is skipped.
const LINKS := {
	"Deck/Buttons/OpenShop": "Shop",
	"Deck/Buttons/EditDeck": "DeckEditor",
	"Deck/Buttons/EditPassives": "UpgradeEditor",
	"Shop/Buttons/LeaveButton": "Deck",
	"Shop/Buttons/EditDeck": "DeckEditor",
	"Shop/Buttons/EditUpgrades": "UpgradeEditor",
	"DeckEditor/Buttons/GoToShop": "Shop",
	"DeckEditor/Buttons/EditUpgrades": "UpgradeEditor",
	"UpgradeEditor/Buttons/LeaveButton": "Deck",
	"UpgradeEditor/Buttons/GoToShop": "Shop",
	"UpgradeEditor/Buttons/EditDeck": "DeckEditor",
}
## View -> its tutorial, shown the first time the player opens the view (the Build Hub's comes with the phase).
const VIEW_TUTORIALS := {"Shop": "hardening_shop", "DeckEditor": "hardening_deck_editor", "UpgradeEditor": "hardening_upgrade_editor"}
## What the deck-only visit (OPEN DECK) does not show.
const BUILD_ONLY_HIDDEN := ["Deck/Buttons/OpenShop", "Deck/NextPhase", "TopBar/Objective", "DeckEditor/Buttons/GoToShop", "UpgradeEditor/Buttons/GoToShop"]

@onready var _deck: HardeningDeck = $Deck
@onready var _shop: HardeningShop = $Shop
@onready var _deck_editor: HardeningDeckEditor = $DeckEditor
@onready var _upgrade_editor: HardeningUpgradeEditor = $UpgradeEditor
@onready var _screen_label: Label = $TopBar/CurrentScreen
@onready var _points: Label = $TopBar/SPWallet
@onready var _next_phase: Button = $Deck/NextPhase

var _state := HardeningState.new()
var _next_text := ""
var _doom_warned := false # the button warned that an upgrade is missing, and the next press goes on
var _build_only := false
var _shown_wallet := -1 # the wallet last shown, so a change counts up or down
var _compact: HardeningCompact # null with the old layout


func _ready() -> void:
	_build_only = SceneManager.build_only
	SceneManager.build_only = false # it is for this visit only
	_next_text = _next_phase.text
	($TopBar/Label as Label).text = "Day %d" % GameState.current_day # the scene says Day 1 for the editor
	($TopBar/Objective as Label).text = GameState.objective("objective", "hardening")
	_deck.setup(_state)
	_shop.setup(_state)
	_deck_editor.setup(_state)
	_upgrade_editor.setup(_state)
	_shop.changed.connect(_refresh_wallet)
	_deck_editor.leave_requested.connect(_show.bind("Deck"))
	$TopBar/PauseButton.pressed.connect(PauseMenu.open)
	for path: String in LINKS:
		_link(path, LINKS[path])
	_next_phase.pressed.connect(_on_next_phase_pressed)
	if _build_only:
		for path: String in BUILD_ONLY_HIDDEN:
			get_node(path).hide()
	if COMPACT_LAYOUT:
		_compact = HardeningCompact.new()
		add_child(_compact)
		_compact.setup(self, _build_only)
	_show("Deck", false) # the editor shows one panel at a time while laying them out
	if not _build_only:
		await SceneManager.wait_for_transition()
		Tutorial.maybe_show(self, "hardening")


## The tutorial of Hardening points at the controls of the layout in use (see Tutorial).
func adapt_tutorial(steps: Array) -> Array:
	return _compact.adapt_steps(steps) if _compact != null else steps


## What is equipped now is what later days remember of this day (see GameState: some evidence echoes it).
func _remember_build() -> void:
	if SaveManager.current_slot >= 0:
		SaveManager.data["equipped_history"][str(GameState.current_day)] = _state.equipped_list().duplicate()


func _exit_tree() -> void:
	if _build_only and SaveManager.current_slot >= 0:
		_remember_build()
		SaveManager.save() # no NEXT PHASE here, so the changes are kept when the scene is left


## Makes a button open a panel. A button the scene does not have yet is skipped.
func _link(button_path: String, panel: String) -> void:
	var button := get_node_or_null(button_path) as Button
	if button != null:
		button.pressed.connect(_show.bind(panel))


func _show(panel: String, animate: bool = true) -> void:
	var old: Control = null
	for name: String in TITLES:
		var node := get_node(name) as Control
		if node.visible and name != panel:
			old = node
	var keys := TITLES.keys()
	var dir := 1 if old == null or keys.find(panel) >= keys.find(old.name) else -1 # further on, or back
	for name: String in TITLES:
		var node := get_node(name) as Control
		if name != panel and not (animate and node == old):
			node.hide()
	var sliding: Tween = null
	if animate:
		sliding = UiFx.swap_views(old, get_node(panel) as Control, dir)
		UiFx.fade_in(_screen_label, 0.18)
	else:
		get_node(panel).show()
	_screen_label.text = TITLES[panel]
	if _compact != null:
		_compact.close_filters()
		_compact.show_panel(panel)
	if panel == "Deck":
		_deck.refresh() # the deck may have changed in the Deck Editor
	elif panel == "DeckEditor":
		_deck_editor.refresh() # cards may have been bought in the shop
	elif panel == "UpgradeEditor":
		_upgrade_editor.refresh() # so may upgrades
	if panel == "Shop":
		_shop.greet()
	_refresh_wallet()
	if not _build_only and VIEW_TUTORIALS.has(panel):
		# The tutorial pauses the game, which would freeze the view half way in (invisible): wait until it is there.
		if sliding != null and sliding.is_valid():
			await sliding.finished
		if get_node(panel).visible: # the player may have moved on meanwhile
			Tutorial.maybe_show(self, VIEW_TUTORIALS[panel])


func _refresh_wallet() -> void:
	var now := GameState.wallet()
	if _shown_wallet >= 0 and now != _shown_wallet:
		UiFx.count_to(_points, _shown_wallet, now, "%d SP", 0.4)
		UiFx.pop(_points, 0.2, 0.3)
		UiFx.float_text("%+d" % (now - _shown_wallet), UiFx.center_of(_points) + Vector2(0, 8), UiFx.RED if now < _shown_wallet else UiFx.GREEN)
	else:
		_points.text = "%d SP" % now
	_shown_wallet = now


# --- Debug panel (=) ---

func debug_actions() -> Array:
	return [["+100 SP >", func() -> void: _add_points(100)]]


func _add_points(amount: int) -> void:
	GameState.add_points(amount)
	_shop.refresh()
	_refresh_wallet()


## The button itself says why the phase cannot end yet, then goes back to its text.
func _warn_deck() -> void:
	_next_phase.text = "NEED %d+ CARDS\nIN THE DECK" % HardeningState.MIN_DECK
	UiFx.shake(_next_phase, 4.0)
	UiFx.badge(Glyph.Kind.CROSS, UiFx.RED, UiFx.center_of(_next_phase) + Vector2(_next_phase.size.x / 2.0 + 8.0, 0.0), 2, 1.6)
	await get_tree().create_timer(2.0).timeout
	_next_phase.text = _next_text


## The upgrade this day's threat cannot be beaten without (the "doom" of the Response data), when it is not equipped.
func _missing_critical_upgrade() -> String:
	var path := str(GameState.phase_info("response").get("data", ""))
	var file := FileAccess.open(path, FileAccess.READ) if not path.is_empty() else null
	if file == null:
		return ""
	var data: Variant = JSON.parse_string(file.get_as_text())
	var doom: Dictionary = data.get("doom", {}) if data is Dictionary else {}
	var counter := str(doom.get("counter", ""))
	if counter.is_empty() or _state.equipped_list().has(counter):
		return ""
	return str(_state.upgrades.get(counter, {}).get("name", counter))


## The button says it once: this fight cannot be won without that upgrade. Pressing it again goes on anyway.
func _warn_missing(upgrade_name: String) -> void:
	_doom_warned = true
	_next_phase.text = "ATTACKS CANNOT BE STOPPED!\nPRESS AGAIN TO GO ON"
	UiFx.float_text("MISSING: %s" % upgrade_name.to_upper(), UiFx.center_of(_next_phase) + Vector2(-70, 4), UiFx.RED, 6, 4.0)
	UiFx.shake(_next_phase, 4.0)
	UiFx.badge(Glyph.Kind.EXCLAIM, UiFx.RED, UiFx.center_of(_next_phase) + Vector2(_next_phase.size.x / 2.0 + 8.0, 0.0), 2, 2.4)
	await get_tree().create_timer(5.0).timeout
	_next_phase.text = _next_text
	_doom_warned = false


## Hardening has no FinishScreen, so this is its save point: the phase counts as done and the
## game continues with the next phase (the Response phase is not built yet: the stage select).
func _on_next_phase_pressed() -> void:
	if _state.deck_list().size() < HardeningState.MIN_DECK:
		_warn_deck()
		return
	if not _doom_warned and not _build_only:
		var missing := _missing_critical_upgrade()
		if not missing.is_empty():
			_warn_missing(missing)
			return
	_next_phase.disabled = true
	_remember_build()
	if SaveManager.current_slot >= 0:
		SaveManager.complete_phase(GameState.current_day, GameState.current_phase)
		SaveManager.save()
	var next := GameState.PHASES.find(GameState.current_phase) + 1
	if next >= GameState.PHASES.size():
		SceneManager.load_stage_select()
		return
	GameState.set_phase(GameState.PHASES[next])
	SceneManager.open_current_phase()
