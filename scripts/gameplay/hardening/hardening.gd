extends Control
## Hardening phase. One panel is shown at a time: the Build Hub (deck.gd), the shop (shop.gd), the Deck
## Editor (deck_editor.gd) and the Upgrade Editor (upgrade_editor.gd). The panels share one HardeningState;
## this script switches between them and ends the phase.
##
## Opened from the day select with OPEN DECK (SceneManager.build_only) it is only the place to change the
## deck and the upgrades: no shop, no objective and no move to the next phase. It saves when it is left.

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
var _build_only := false


func _ready() -> void:
	_build_only = SceneManager.build_only
	SceneManager.build_only = false # it is for this visit only
	_next_text = _next_phase.text
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
	_show("Deck") # the editor shows one panel at a time while laying them out
	if not _build_only:
		await SceneManager.wait_for_transition()
		Tutorial.maybe_show(self, "hardening")


func _exit_tree() -> void:
	if _build_only and SaveManager.current_slot >= 0:
		SaveManager.save() # no NEXT PHASE here, so the changes are kept when the scene is left


## Makes a button open a panel. A button the scene does not have yet is skipped.
func _link(button_path: String, panel: String) -> void:
	var button := get_node_or_null(button_path) as Button
	if button != null:
		button.pressed.connect(_show.bind(panel))


func _show(panel: String) -> void:
	for name: String in TITLES:
		get_node(name).visible = name == panel
	_screen_label.text = TITLES[panel]
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
		Tutorial.maybe_show(self, VIEW_TUTORIALS[panel])


func _refresh_wallet() -> void:
	_points.text = "%d SP" % GameState.wallet()


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
	await get_tree().create_timer(2.0).timeout
	_next_phase.text = _next_text


## Hardening has no FinishScreen, so this is its save point: the phase counts as done and the
## game continues with the next phase (the Response phase is not built yet: the stage select).
func _on_next_phase_pressed() -> void:
	if _state.deck_list().size() < HardeningState.MIN_DECK:
		_warn_deck()
		return
	_next_phase.disabled = true
	if SaveManager.current_slot >= 0:
		SaveManager.complete_phase(GameState.current_day, GameState.current_phase)
		SaveManager.save()
	var next := GameState.PHASES.find(GameState.current_phase) + 1
	if next >= GameState.PHASES.size():
		SceneManager.load_stage_select()
		return
	GameState.set_phase(GameState.PHASES[next])
	SceneManager.open_current_phase()
