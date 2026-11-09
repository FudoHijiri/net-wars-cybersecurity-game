extends SceneTree

## Prop structure: repairable equipment inherits props/RecoveryEquipment.tscn (reach + marker),
## furniture and decor inherit props/RecoveryProp.tscn (art + footprint, no interaction),
## wall items inherit props/RecoveryDecal.tscn, and per-instance edits stay independent.

const PROPS := "res://scenes/gameplay/recovery/props"
const PROP_BASE := PROPS + "/RecoveryProp.tscn"
const EQUIPMENT_BASE := PROPS + "/RecoveryEquipment.tscn"
const DECAL_BASE := PROPS + "/RecoveryDecal.tscn"
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("PASS ", message)
	else:
		failed += 1
		push_error("FAIL " + message)

func _base_of(scene: PackedScene) -> String:
	var base := scene.get_state().get_node_instance(0)
	return base.resource_path if base != null else ""

func _run() -> void:
	await process_frame
	var counts := {"equipment": 0, "prop": 0, "decal": 0}
	for group in ["equipment", "furniture", "decor"]:
		for name in DirAccess.get_files_at(PROPS + "/" + group):
			if not name.ends_with(".tscn"):
				continue
			var scene := load(PROPS + "/" + group + "/" + name) as PackedScene
			var base := _base_of(scene)
			if base == DECAL_BASE:
				counts.decal += 1
				var decal := scene.instantiate() as Sprite2D
				check(decal.texture != null and decal.find_children("*", "CollisionObject2D", true, false).is_empty(), "Wall decoration has art and no collision: " + name)
				decal.free()
			elif group == "equipment":
				counts.equipment += 1
				check(base == EQUIPMENT_BASE, "Equipment inherits RecoveryEquipment: " + name)
				await _check_equipment(scene, name)
			else:
				counts.prop += 1
				check(base == PROP_BASE, "Furniture/decor inherits RecoveryProp: " + name)
				await _check_prop(scene, name)
	check(_base_of(load(EQUIPMENT_BASE)) == PROP_BASE, "RecoveryEquipment itself extends RecoveryProp")
	check(counts.equipment == 5 and counts.prop >= 15 and counts.decal >= 3, "Library: %d equipment, %d furniture/decor, %d wall items" % [counts.equipment, counts.prop, counts.decal])
	_check_room()
	await _check_library(counts.equipment + counts.prop + counts.decal)
	print("PROP RESULTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

## Shared checks: art present, footprint independent per instance, root carries parts, edits persist.
func _check_common(scene: PackedScene, name: String) -> Node2D:
	var prop := scene.instantiate() as Node2D
	var sibling := scene.instantiate() as Node2D
	root.add_child(prop)
	root.add_child(sibling)
	await process_frame
	var sprite := prop.get_node("Sprite2D") as Sprite2D
	var floor_shape := prop.get_node("SolidBody/CollisionShape2D") as CollisionShape2D
	check(sprite.texture != null and floor_shape.shape != null, "Artwork and floor footprint are present: " + name)
	check(floor_shape.shape != sibling.get_node("SolidBody/CollisionShape2D").shape, "Footprint edits remain independent between instances: " + name)
	var image_before := sprite.global_position
	var floor_before := floor_shape.global_position
	prop.position += Vector2(31, 17)
	check(sprite.global_position == image_before + Vector2(31, 17) and floor_shape.global_position == floor_before + Vector2(31, 17), "Moving the root carries the art and footprint: " + name)
	floor_shape.shape.size = Vector2(37, 23)
	var packed := PackedScene.new()
	var filename := "res://.godot/recovery-prop-edit-roundtrip.tscn"
	var saved: bool = packed.pack(prop) == OK and ResourceSaver.save(packed, filename) == OK
	var restored := (ResourceLoader.load(filename, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate()
	check(saved and restored.position == Vector2(31, 17) and restored.get_node("SolidBody/CollisionShape2D").shape.size == Vector2(37, 23), "Edited footprint survives save/reopen: " + name)
	restored.free()
	sibling.queue_free()
	return prop

func _check_prop(scene: PackedScene, name: String) -> void:
	var prop := await _check_common(scene, name)
	check(prop.get_node_or_null("Interaction") == null and prop.find_children("*", "Area2D", true, false).is_empty() and not prop is RecoveryEquipment, "Decorative prop has no interaction area: " + name)
	prop.queue_free()
	await process_frame

func _check_equipment(scene: PackedScene, name: String) -> void:
	var prop = await _check_common(scene, name)
	var area = prop.get_node("Interaction")
	check(prop is RecoveryEquipment and area is RecoveryInteractable and area.status_marker is RecoveryStatusMarker and prop.static_sprite == prop.get_node("Sprite2D"), "Equipment has reach, shared status marker and script: " + name)
	var sibling = scene.instantiate()
	check(area.interaction_shape.shape != sibling.get_node("Interaction").interaction_shape.shape, "Reach edits remain independent between instances: " + name)
	sibling.free()
	var proxy := Node2D.new()
	root.add_child(proxy)
	proxy.global_position = area.interaction_shape.global_position
	prop.interaction_enabled = false
	await process_frame
	var disabled: bool = not area.is_in_reach(proxy) and not area.monitoring and not area.status_marker.visible
	prop.equipment_id = "test_prop"
	prop.interaction_enabled = true
	await process_frame
	check(disabled and area.is_in_reach(proxy) and area.monitoring and area.equipment_id == "test_prop", "Root interaction switch disables/enables the complete area: " + name)
	area.interaction_shape.shape.size = Vector2(138, 94)
	prop.display_name = "Designer edit"
	var packed := PackedScene.new()
	var filename := "res://.godot/recovery-prop-edit-roundtrip.tscn"
	var saved: bool = packed.pack(prop) == OK and ResourceSaver.save(packed, filename) == OK
	var restored = (ResourceLoader.load(filename, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate()
	check(saved and restored.display_name == "Designer edit" and restored.get_node("Interaction/CollisionShape2D").shape.size == Vector2(138, 94), "Edited label and reach survive save/reopen: " + name)
	restored.free()
	proxy.queue_free()
	prop.queue_free()
	await process_frame

func _check_room() -> void:
	var world = load("res://scenes/gameplay/recovery/RecoveryWorld.tscn").instantiate()
	var actors: Node = world.get_node("Actors")
	var decorative_without_reach := true
	var equipment := 0
	for child in actors.get_children():
		if child.name == "Player":
			continue
		if child is RecoveryEquipment:
			equipment += 1
		else:
			decorative_without_reach = decorative_without_reach and child.find_children("*", "Area2D", true, false).is_empty()
	check(equipment == 9 and decorative_without_reach, "Room has 9 repairable machines; every other floor item has no interaction area")
	var wall_ok := true
	for child in world.get_node("WallDecor").get_children():
		wall_ok = wall_ok and child is Sprite2D and (child as Sprite2D).texture != null
	check(wall_ok and world.get_node("WallDecor").get_index() < actors.get_index(), "Wall decoration draws behind the y-sorted floor items")
	check(actors.get_child_count() >= 30, "The room is furnished (%d floor items)" % (actors.get_child_count() - 1))
	world.free()

func _check_library(expected: int) -> void:
	var library = load("res://scenes/gameplay/recovery/RecoveryPropLibrary.tscn").instantiate()
	root.add_child(library)
	current_scene = library
	for frame in 3: await process_frame
	var preview_count := 0
	var inactive := true
	for child in library.get_children():
		if child.scene_file_path.is_empty():
			continue
		preview_count += 1
		if child is RecoveryEquipment:
			inactive = inactive and not child.interaction_enabled and not child.interaction.enabled
	check(preview_count == expected and inactive, "Library previews every prop without authorizing repair work")
	library.queue_free()
