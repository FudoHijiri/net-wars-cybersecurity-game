class_name RecoveryData
extends RefCounted

const DEFAULT_PATH := "res://data/recovery/day1_recovery.json"
const TASKS := "res://scenes/gameplay/recovery/tasks/"

## The single list of Recovery minigames: component ID -> its scene.
## Order sets the work-order order; file_server (Final Check) always runs last.
## Adding a minigame = one line here + its scene + its JSON content.
const COMPONENTS := {
	"password": TASKS + "ResetPassword.tscn",
	"sessions": TASKS + "KickSessions.tscn",
	"settings": TASKS + "UndoChanges.tscn",
	"reused": TASKS + "ChangeTheLocks.tscn",
	"network": TASKS + "NetworkRepair.tscn",
	"backup_database": TASKS + "BackupRepair.tscn",
	"file_server": TASKS + "FileServerRepair.tscn",
}
const FINAL_CHECK := "file_server"
const COMPONENT_IDS: Array[String] = ["password", "settings", "sessions", "reused", "network", "backup_database", "file_server"]


static func load_data(path: String = DEFAULT_PATH) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Recovery: cannot read %s" % path)
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text().trim_prefix(String.chr(0xfeff))) != OK or not json.data is Dictionary:
		push_error("Recovery: invalid JSON in %s at line %d" % [path, json.get_error_line()])
		return {}
	return json.data


static func task_scene(component_id: String) -> PackedScene:
	return load(COMPONENTS[component_id]) as PackedScene if COMPONENTS.has(component_id) else null


## Response hand-off (option A): each enemy attack in the Day's "attacks" list stands
## for one component. Attacks the player was hit by become the components to repair.
static func components_for_attacks(data: Dictionary, hit_attack_ids: Array) -> Array[String]:
	var damaged: Array[String] = []
	for attack: Dictionary in data.get("attacks", []):
		var component := str(attack.get("component", ""))
		if hit_attack_ids.has(attack.get("id", "")) and COMPONENT_IDS.has(component) and not damaged.has(component):
			damaged.append(component)
	return damaged


## Points for one repair: {"base", "clean_bonus"} from the component's "points", else the Day's "points".
static func component_points(data: Dictionary, component_id: String) -> Dictionary:
	var defaults: Dictionary = data.get("points", {"base": 15, "clean_bonus": 10})
	var own: Dictionary = data.get("components", {}).get(component_id, {}).get("points", {})
	return {"base": int(own.get("base", defaults.get("base", 0))), "clean_bonus": int(own.get("clean_bonus", defaults.get("clean_bonus", 0)))}


## The Recovery results for FinishScreen.show_results(). Every finished repair pays its base;
## a repair with no wrong moves adds its clean bonus. Mistakes only shrink the bonus, never the base.
## Rows match RecoveryFinishScreen.tscn: Repairs done, Mistakes | Fixes, Clean fixes, Final check.
static func results(data: Dictionary, required: Array[String], mistakes: Dictionary) -> Dictionary:
	var fixes := 0
	var fix_points := 0
	var clean := 0
	var clean_points := 0
	var final_points := 0
	var total_mistakes := 0
	for id in required:
		var points := component_points(data, id)
		var wrong := int(mistakes.get(id, 0))
		total_mistakes += wrong
		var bonus: int = points.clean_bonus if wrong == 0 else 0
		if id == FINAL_CHECK:
			final_points = points.base + bonus
			continue
		fixes += 1
		fix_points += points.base
		if wrong == 0:
			clean += 1
			clean_points += bonus
	var finish: Dictionary = data.get("finish", {})
	var comments: Dictionary = finish.get("comments", {})
	return {
		"rows": [
			{"count": required.size()},
			{"count": total_mistakes},
			{"count": fixes, "points": fix_points},
			{"count": clean, "points": clean_points},
			{"count": 1 if required.has(FINAL_CHECK) else 0, "points": final_points},
		],
		"comment": str(comments.get("clean" if total_mistakes == 0 else "done", "")),
		"bonus": 0,
		"total": fix_points + clean_points + final_points,
	}


## Editor dropdown text for an @export String that must hold a component ID.
static func enum_hint(extra: Array[String] = []) -> String:
	return ",".join(COMPONENT_IDS + extra)


static func credits(data: Dictionary) -> Array[String]:
	var paragraphs: Array[String] = []
	paragraphs.assign(data.get("art_credits", []))
	return paragraphs
