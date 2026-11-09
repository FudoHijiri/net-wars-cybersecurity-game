extends SceneTree

# Native GUI input, real collisions and one shared workroom; no production shortcuts.
const ROOM := "res://scenes/gameplay/recovery/Recovery.tscn"
const DEMO := "res://scenes/gameplay/recovery/RecoveryDemo.tscn"
var passed := 0
var failed := 0
var _state: Node
var _pause: CanvasLayer
var _context
var _visual := false
var _stages: Array[String] = []

func _initialize() -> void:
	_visual = "--visual" in OS.get_cmdline_user_args()
	if _visual:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	_run.call_deferred()

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		push_error("FAIL " + label)

func _run() -> void:
	create_timer(240.0).timeout.connect(func() -> void:
		push_error("Recovery test timeout")
		quit(1))
	await process_frame
	Engine.time_scale = 2.0 # Speeds the input-driven walking tests only.
	_state = root.get_node("GameState")
	_pause = root.get_node("PauseMenu")
	_context = load("res://scripts/gameplay/recovery/recovery_context.gd")
	check(not _pause.visible and not paused, "Pause starts hidden")
	await _test_art()
	await _test_context()
	await _test_scene_authoring()
	await _test_equipment_selection()
	await _test_interaction_comfort()
	await _test_day1_journey()
	await _test_safety()
	await _test_standalone()
	await _test_day1_minigames()
	await _test_backup()
	await _test_live_state_and_lab()
	await _test_pause_and_return()
	check(_stages.size() == 11, "Every scenario reached its final checkpoint")
	_state.reset_progress()
	await process_frame
	print("RECOVERY RESULTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _new_room(damage: Array[String], outcome: Dictionary, profile: String = "day1", live: bool = false):
	var room = load(ROOM).instantiate()
	if not live:
		room.configure_demo(damage, [] as Array[String], outcome, _context.sample_context(profile))
	root.add_child(room)
	current_scene = room
	await process_frame
	await process_frame
	return room

func _remove(node: Node) -> void:
	if _pause.visible:
		_pause.close()
	if current_scene == node:
		current_scene = null
	root.remove_child(node)
	node.queue_free()

func _key(code: Key, held: bool = true) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = held
	Input.parse_input_event(event)
	await process_frame
	if held:
		var released := event.duplicate() as InputEventKey
		released.pressed = false
		Input.parse_input_event(released)
		await process_frame

func _press(button: BaseButton) -> void:
	button.grab_focus()
	await _key(KEY_ENTER)

func _click(button: Control) -> void:
	# Feedback can queue a container sort, and a mistake shakes the screen for 0.2 s:
	# target the settled button rectangle.
	await create_timer(0.25).timeout
	await process_frame
	await process_frame
	var center := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = center
	root.push_input(motion, true)
	for is_down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = center
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = is_down
		root.push_input(event, true)
		await process_frame

func _close_briefing(room) -> void:
	if is_instance_valid(room.dialog):
		await _press(room.dialog.buttons["close"])
	await process_frame

func _walk_to(room, target: Vector2) -> void:
	for axis in range(2):
		for step in range(350):
			var delta: float = target[axis] - room.player.global_position[axis]
			if absf(delta) < 7:
				break
			var action := ("recovery_right" if delta > 0 else "recovery_left") if axis == 0 else ("recovery_down" if delta > 0 else "recovery_up")
			Input.action_press(action)
			await physics_frame
			Input.action_release(action)
	await physics_frame
	await physics_frame

func _equipment(room, id: String) -> void:
	var station = room.get_equipment(id)
	if station == null:
		station = room.get_interactable(id)
	var local: Vector2 = room.world.to_local(room.player.global_position)
	var target: Vector2 = room.world.to_local(station.global_position)
	# Navigate the real aisle and the 77px connecting doorway in source coordinates.
	if local.y > 650:
		await _walk_to(room, room.world.to_global(Vector2(local.x, 850)))
		await _walk_to(room, room.world.to_global(Vector2(1174, 850)))
		if target.y < 650:
			await _walk_to(room, room.world.to_global(Vector2(1174, 420)))
	else:
		await _walk_to(room, room.world.to_global(Vector2(local.x, 420)))
		if target.y > 650:
			await _walk_to(room, room.world.to_global(Vector2(1174, 420)))
			await _walk_to(room, room.world.to_global(Vector2(1174, 850)))
	var aisle_y := 850.0 if target.y > 650 else 420.0
	await _walk_to(room, room.world.to_global(Vector2(target.x, aisle_y)))
	await _walk_to(room, station.global_position)
	check(station.is_in_reach(room.player), "Walkable office route reaches " + id)
	await _key(KEY_E)
	await process_frame

## Skips the results animation and waits until CONTINUE can be pressed.
func _finish_results(room) -> void:
	await process_frame
	var screen = room.finish_screen
	var button: Button = screen.get_node("LogsButton")
	for i in 600:
		if screen.visible and not button.disabled:
			return
		if screen.visible:
			screen.set("_skipping", true)
		await process_frame

## Finishes whichever Final Check is open: Back to Work (Day 1) or the practice verification.
func _finish_final_check(task) -> void:
	if task.get("sign_in_button") != null:
		await _press(task.sign_in_button)
		for digit in str(task.content.code):
			await _press(task.digit_buttons[digit])
		await _press(task.file_buttons[str(task.content.test_file)])
	else:
		for button: Button in task.check_buttons.values():
			await _press(button)
		await _press(task.test_button)

func _fixture_at(room, id: String) -> void:
	room.player.global_position = room.get_interactable(id).global_position + Vector2(0, 8)
	await physics_frame
	await physics_frame

func _snapshot(label: String) -> void:
	# Let feedback animations (bounce wobble) finish before measuring layout.
	await create_timer(0.3).timeout
	await process_frame
	var frames := root.find_children("Frame", "PanelContainer", true, false)
	for frame: PanelContainer in frames:
		if not frame.is_visible_in_tree():
			continue
		# Repair screens sit inside the monitor bezel; dialogs keep the plain frame.
		var intended := Rect2(22, 16, 596, 326) if frame.get_parent().has_node("Bezel") else Rect2(32, 24, 576, 312)
		var fits := frame.get_global_rect().is_equal_approx(intended)
		var action_rects: Array[Rect2] = []
		for button: BaseButton in frame.find_children("*", "BaseButton", true, false):
			if button.is_visible_in_tree():
				fits = fits and intended.encloses(button.get_global_rect())
				for previous in action_rects:
					fits = fits and not previous.intersects(button.get_global_rect())
				action_rects.append(button.get_global_rect())
		check(fits, "Frame/actions fit without button overlap: " + label)
	if not _visual:
		return
	await process_frame
	RenderingServer.force_draw()
	DirAccess.make_dir_recursive_absolute("res://.godot/recovery-office-qa")
	var screenshot := root.get_texture().get_image()
	check(screenshot.save_png("res://.godot/recovery-office-qa/" + label + ".png") == OK, "Rendered checkpoint " + label)
	DirAccess.make_dir_recursive_absolute("res://.godot/recovery-office-qa/2x")
	screenshot.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	screenshot.save_png("res://.godot/recovery-office-qa/2x/" + label + ".png")

func _test_art() -> void:
	# The technician is Joshua (tools/build_technician.gd): 6 frames x down/left/right/up.
	var image := (load("res://assets/recovery/technician.png") as Texture2D).get_image()
	image.decompress()
	var mirrored := true
	var colours: Dictionary = {}
	for y in 32:
		for x in 120:
			var frame_x := x % 20
			var left := image.get_pixel(x, 32 + y)
			var right := image.get_pixel(x - frame_x + 19 - frame_x, 64 + y)
			mirrored = mirrored and (left.a == 0 and right.a == 0 or left.is_equal_approx(right))
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a > 0:
				colours[pixel.to_html(false)] = true
	check(image.get_size() == Vector2i(120, 128), "Technician sheet keeps the 6x4 grid of 20x32 frames")
	check(mirrored, "Every left-walking frame is the exact mirror of its right-walking frame")
	check(colours.has("556666") and colours.has("99aabb") and colours.has("ffddcc"), "Technician uses Joshua's hair, shirt and skin colours")
	for name in ["office-background", "dual-monitor-desk", "access-terminal", "printer-and-cabinet", "sofa-and-side-table", "server-rack", "network-switch", "backup-nas", "repair-workbench", "server-rack-frames"]:
		var texture := load("res://assets/recovery/office/" + name + ".png") as Texture2D
		check(texture != null and texture.get_image().get_used_rect().has_area(), "Supplied office artwork imports: " + name)
	var frames := load("res://assets/recovery/office/server-activity.tres") as SpriteFrames
	check(frames.get_frame_count("activity") == 6 and is_equal_approx(frames.get_frame_duration("activity", 0) / frames.get_animation_speed("activity"), 0.60), "Rack animation retains the six GIF frames and original timing")
	_stages.append("art")

func _test_context() -> void:
	_state.reset_progress()
	_state.investigation_evidence = ["email_anna_reply", "login_germany"]
	_state.identified_threat = "Credential Abuse"
	_state.reported_anomalies = ["log_001", "log_002"]
	_state.phase_findings["monitoring"] = {"reports": [
		{"id": "log_001", "suspicious": false, "reason": "An allowed normal sign-in."},
		{"id": "log_002", "suspicious": true, "reason": "An unknown computer broke a rule."},
	]}
	_state.security_points = 20
	var context: Dictionary = _context.snapshot_live()
	check(context.evidence.size() == 2 and "Anna" in context.evidence[0], "Briefing resolves real submitted Investigation evidence")
	check(context.reports.size() == 2 and "FALSE ALARM" in context.reports[0] and "SUSPICIOUS" in context.reports[1], "Monitoring normal reports remain false alarms")
	check("No hardening" in context.hardening, "Unbuilt Hardening results are not fabricated")
	var before: Array = _state.investigation_evidence.duplicate()
	context.evidence.clear()
	check(_state.investigation_evidence == before, "Recovery context does not mutate earlier phase state")
	var outcome: Dictionary = _context.sample_outcome()
	_state.begin_recovery([] as Array[String], outcome)
	outcome.contained = false
	check(_state.response_outcome.contained, "Response metadata is copied, not aliased")
	_stages.append("context")

func _test_scene_authoring() -> void:
	var room = load(ROOM).instantiate()
	var authored := true
	var prop_count := 0
	for prop in room.world.get_node("Actors").get_children():
		if prop == room.player:
			continue
		prop_count += 1
		var has_reach: bool = prop.get_node_or_null("Interaction/CollisionShape2D") != null
		authored = authored and not prop.scene_file_path.is_empty() and prop.get_node_or_null("SolidBody/CollisionShape2D") != null and has_reach == (prop is RecoveryEquipment)
	check(authored and prop_count > 0, "Placed props are editable scene instances; only repairable equipment has an interaction area")
	var rack: Node2D = room.world.get_node("Actors/Server01")
	check(rack.get_node("Sprite2D") is Sprite2D and rack.get_node("SolidBody/CollisionShape2D").shape != null and rack.get_node("Interaction/CollisionShape2D").shape != null, "Sprite, separate solid body and interaction are authored children under an editable prop root")
	check(room.world.get_node("Actors/Server02").scene_file_path == rack.scene_file_path and room.world.get_node("Actors/Server03").scene_file_path == rack.scene_file_path, "Three server instances share one reusable scene")
	var marker_local: Vector2 = rack.get_node("Interaction").status_marker.position
	var expected_rack: Vector2 = rack.position + Vector2(20, 0)
	var expected_spawn: Vector2 = room.player.position + Vector2(16, 0)
	var sibling_size: Vector2 = room.world.get_node("Actors/Server02/SolidBody/CollisionShape2D").shape.size
	rack.position += Vector2(20, 0)
	room.world.position = Vector2(8, 0)
	room.player.position += Vector2(16, 0)
	rack.display_name = "Edited server"
	rack.get_node("Interaction").interaction_shape.shape.size = Vector2(104, 120)
	rack.get_node("SolidBody/CollisionShape2D").shape.size = Vector2(56, 23)
	var roundtrip_path := "res://.godot/recovery-editor-roundtrip-%s.tscn" % ("visual" if _visual else "headless")
	var edited := PackedScene.new()
	check(edited.pack(room) == OK and ResourceSaver.save(edited, roundtrip_path) == OK, "Edited office can be saved as a Godot scene")
	room.free()
	room = (ResourceLoader.load(roundtrip_path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene).instantiate()
	room.configure_demo([] as Array[String], [] as Array[String], _context.sample_outcome(), _context.sample_context("server"), {"file_server": "server_01"})
	root.add_child(room)
	current_scene = room
	await process_frame
	await process_frame
	await _close_briefing(room)
	rack = room.world.get_node("Actors/Server01")
	var interaction = room.get_equipment("server_01")
	check(rack.position == expected_rack and room.player.position == expected_spawn, "Designer placements and player spawn survive scene roundtrip")
	check(interaction.title == "Edited server" and interaction.interaction_shape.shape.size == Vector2(104, 120) and rack.get_node("SolidBody/CollisionShape2D").shape.size == Vector2(56,23), "Root label, reach and floor footprint remain Inspector-editable and persist")
	check(room.world.get_node("Actors/Server02/SolidBody/CollisionShape2D").shape.size == sibling_size, "Editing one server footprint does not change its two siblings")
	check(interaction.status_marker.global_position.is_equal_approx(interaction.to_global(marker_local)), "Moving the prop carries its status marker and interaction together")
	rack.name = "DesignerRenamedServer"
	room.player.global_position = interaction.global_position + Vector2(0, 55)
	await physics_frame
	room.open_station(interaction)
	check(room.active_task != null, "Equipment ID survives node renaming and edited interaction reach")
	room.close_task()
	room.player.global_position = interaction.global_position + Vector2(0, 65)
	room.open_station(interaction)
	check(room.active_task == null, "Authored interaction shape rejects remote use")
	room.player.global_position = interaction.global_position + Vector2(0, 10)
	Input.action_press("recovery_up")
	for i in 25: await physics_frame
	Input.action_release("recovery_up")
	check(room.player.global_position.y >= rack.global_position.y, "Moved server floor collision blocks the player")
	_remove(room)
	await process_frame
	_stages.append("authoring")

func _test_equipment_selection() -> void:
	var room = await _new_room(["file_server"], _context.sample_outcome(), "server")
	await _close_briefing(room)
	var selected: Dictionary = room.equipment_assignments().duplicate()
	var affected := 0
	var online := 0
	for id in ["server_01", "server_02", "server_03"]:
		var status: String = room.station_status(room.get_equipment(id))
		affected += int(status == "needs_repair")
		online += int(status == "working")
	check(affected == 1 and online == 2 and room.get("_required") == ["file_server"], "Single-server scenario selects exactly one rack and leaves its two siblings online")
	await _snapshot("26-single-server")
	for id in ["monitoring_01", "monitoring_02", "access_01", "access_02", "server_01", "server_02", "server_03", "network_switch", "backup_nas"]:
		await _equipment(room, id)
		if room.active_task != null:
			room.close_task()
		elif room.dialog != null:
			await _close_briefing(room)
	check(room.equipment_assignments() == selected, "Visiting every repairable prop, opening and closing tasks never rerolls affected instances")
	await _equipment(room, "file_server")
	var task = room.active_task
	for button: Button in task.check_buttons.values(): await _press(button)
	await _press(task.test_button)
	check(room.repairs_done() == 1 and room.get_interactable("file_server").status_marker.check_mark.visible, "Selected server completes once and shows a repaired check")
	task.succeed()
	check(room.repairs_done() == 1, "Repeated completion cannot count the selected server twice")
	await _press(task.back_button)
	await _snapshot("27-server-repaired")
	var completed: Array[String] = room.completed_components().duplicate()
	_remove(room)
	await process_frame
	var restored = load(ROOM).instantiate()
	restored.configure_demo(["file_server"] as Array[String], completed, _context.sample_outcome(), _context.sample_context("server"), selected)
	root.add_child(restored)
	current_scene = restored
	await process_frame
	await process_frame
	check(restored.equipment_assignments() == selected and restored.can_finish(), "An explicit demo resume preserves both equipment selection and completion")
	_remove(restored)
	await process_frame
	_stages.append("selection")

func _test_day1_journey() -> void:
	var room = await _new_room(["network"], _context.sample_outcome())
	await _snapshot("01-work-order")
	check(is_instance_valid(room.dialog) and not room.player.movement_enabled, "Work order opens on entry and owns input")
	check(room.world.get_node("Backdrop") is Sprite2D and room.world.get_node("Boundaries").get_child_count() >= 10, "Two-room backdrop and editable collision boundaries are authored in the world")
	check(room.player.get_parent().y_sort_enabled and room.player.get_parent() == room.world.get_node("Actors"), "Player and individual furniture share foot-based depth sorting")
	var station_ids: Array[String] = []
	for item in room.interactables:
		station_ids.append(item.target)
	check(room.interactables.size() == 10 and station_ids.has("work_order") and station_ids.has("network") and station_ids.has("file_server") and station_ids.has("backup_database"), "Office has nine spaced equipment targets and the exit/work-order interaction")
	var network_marker: RecoveryStatusMarker = room.get_interactable("network").status_marker
	check(network_marker.is_visible_in_tree() and network_marker.glyph.text == "!", "Required repair has a visible exclamation marker")
	var network_sprite: Sprite2D = room.get_interactable("network").get_parent().get_node("Sprite2D")
	check(network_marker.global_position.y + 11 * network_marker.global_scale.y < network_sprite.global_position.y + network_sprite.offset.y * network_sprite.global_scale.y, "Repair marker floats above the equipment instead of covering it")
	check(not room.get_interactable("backup_database").status_marker.is_visible_in_tree(), "Healthy equipment has no attention marker")
	check(room.get_interactable("file_server").status_marker.glyph.text != "!", "Blocked verification does not advertise an available repair")
	check(room.get_equipment("access_01").get_parent().static_sprite.texture.resource_path != room.get_equipment("network_switch").get_parent().static_sprite.texture.resource_path, "Repair equipment uses distinct supplied artwork")
	var frames: SpriteFrames = room.player.sprite.sprite_frames
	check(frames.get_animation_names().size() == 4 and frames.get_frame_count("left") == 6 and room.player.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Four-direction source animations preserve crisp pixels")
	await _press(room.dialog.buttons["findings"])
	check(room.dialog != null and not room.player.movement_enabled, "Detailed findings open without releasing modal input")
	await _snapshot("16-findings")
	var original_evidence: Array = room.get("_context").evidence.duplicate()
	for i in 14:
		room.get("_context").evidence.append("Additional submitted evidence %d: the account activity needs review." % (i + 1))
	room.call("_show_findings")
	await _snapshot("18-long-findings")
	var scroll: ScrollContainer = room.dialog.get("_scroll")
	await _key(KEY_PAGEDOWN)
	check(scroll.scroll_vertical > 0, "Detailed findings scroll with keyboard while the footer stays reachable")
	await _key(KEY_PAGEUP)
	room.get("_context").evidence = original_evidence
	await _press(room.dialog.buttons["back"])
	await _press(room.dialog.buttons["credits"])
	await _snapshot("17-room-credits")
	check(room.dialog != null, "Art attribution is available from the live work order")
	await _press(room.dialog.buttons["back"])
	await _close_briefing(room)
	await _snapshot("02-workroom")
	check(room.get("_hud").get_node("Header").size == Vector2(640, 24), "The single HUD strip leaves the room viewport clear")
	check(room.get("_required") == ["network", "file_server"], "Credential Abuse requires reconnection and final verification, not backup restoration")
	room.show_summary()
	check(room.summary == null, "A shift cannot finish early or from a remote HUD")
	await _snapshot("03-all-stations")
	var station = room.get_interactable("network")
	room.player.global_position = room.world.to_global(Vector2(500, 420))
	room.open_station(station)
	check(room.active_task == null, "Remote repair calls are rejected")
	await _equipment(room, "network")
	var task = room.active_task
	var old_position: Vector2 = room.player.global_position
	check(task != null and not room.player.movement_enabled, "Patch-panel close-up requires visiting the equipment")
	await _snapshot("04-patch-panel")
	await _click(task.device_buttons["unknown_device"])
	await _click(task.socket_buttons["unknown_device"])
	check(task.connected.is_empty() and "not been cleared" in task.feedback.text, "Unchecked equipment stays offline with an explanation")
	await _snapshot("19-unsafe-device")
	await _press(task.device_buttons["anna_device"])
	await _press(task.socket_buttons["payroll_server"])
	check(task.connected.is_empty(), "Wrong socket does not complete a connection")
	for id: String in ["anna_device", "payroll_server"]:
		await _press(task.device_buttons[id])
		await _press(task.socket_buttons[id])
	await _snapshot("20-connected-leads")
	await _press(task.test_button)
	check(task.solved and room.repairs_done() == 1 and not task.connected.has("unknown_device"), "Only cleared devices are reconnected")
	check(network_marker.check_mark.visible and room.get_interactable("file_server").status_marker.glyph.text == "!", "Finished equipment gets a check and final verification becomes available")
	await _snapshot("21-network-complete")
	var before_count: int = room.repairs_done()
	task.succeed()
	check(room.repairs_done() == before_count, "Duplicate completion cannot add progress")
	await _press(task.back_button)
	check(room.player.global_position.is_equal_approx(old_position), "Closing equipment preserves player position")
	await _snapshot("05-verification-station")
	await _equipment(room, "file_server")
	task = room.active_task
	await _snapshot("06-verification")
	check(task.scene_file_path.ends_with("BackToWork.tscn"), "Day 1 ends with Back to Work")
	check(task.get_node("%Machine").text.begins_with("SERVER") and "FILE SERVER" in task.get_node("%System").text, "The Final Check is drawn as the server's screen")
	await _finish_final_check(task)
	check(task.solved and room.can_finish(), "Anna signs in, enters her code and opens her file")
	await _snapshot("23-verification-complete")
	await _press(task.back_button)
	await _snapshot("07-backup-station")
	await _equipment(room, "backup_database")
	check(room.active_task == null and room.dialog != null, "Day 1 does not invent backup damage")
	await _close_briefing(room)
	room.show_summary()
	check(room.summary == null, "Finishing requires returning to the work-order terminal")
	await _equipment(room, "work_order")
	await _snapshot("08-day-complete")
	check(room.summary != null and not room.player.movement_enabled, "The work-order terminal finishes the verified shift")
	_remove(room)
	await process_frame
	_stages.append("journey")

func _test_safety() -> void:
	var room = await _new_room(["network"], {})
	await _close_briefing(room)
	await _fixture_at(room, "network")
	await _equipment(room, "network")
	check(not room.is_ready() and room.active_task == null and not room.can_finish() and room.equipment_assignments().is_empty(), "Missing Response outcome cannot authorize reconnection or select damaged equipment")
	check(room.get_interactable("network").status_marker.glyph.text == "?", "Waiting for Response is distinguished from a repairable problem")
	await _close_briefing(room)
	await _snapshot("13-waiting-room")
	check(room.player.movement_enabled, "Waiting outcome still allows exploration")
	_remove(room)
	await process_frame
	var unresolved: Dictionary = _context.sample_outcome()
	unresolved.contained = false
	room = await _new_room(["network"], unresolved)
	await _close_briefing(room)
	await _fixture_at(room, "network")
	await _equipment(room, "network")
	check(not room.is_ready() and room.active_task == null and not room.can_finish(), "Received but unresolved containment cannot authorize work")
	_remove(room)
	await process_frame
	var outcome: Dictionary = _context.sample_outcome()
	outcome.cleared_devices = {}
	room = await _new_room(["network"], outcome)
	await _close_briefing(room)
	await _fixture_at(room, "network")
	await _equipment(room, "network")
	var task = room.active_task
	await _press(task.device_buttons["anna_device"])
	await _press(task.socket_buttons["anna_device"])
	await _press(task.test_button)
	check(not task.solved and task.connected.is_empty(), "An absent device-clearance list does not make devices safe")
	# Movement and directional UI focus must stay inside the task.
	var position_before: Vector2 = room.player.global_position
	Input.action_press("recovery_right")
	for i in range(8): await physics_frame
	Input.action_release("recovery_right")
	check(room.player.global_position.is_equal_approx(position_before), "Room movement stays locked behind the close-up")
	for code: Key in [KEY_TAB, KEY_RIGHT, KEY_DOWN, KEY_LEFT, KEY_UP]:
		await _key(code)
		var focus := root.gui_get_focus_owner()
		check(focus != null and task.is_ancestor_of(focus), "Repair retains focus for key %s" % code)
	await _press(task.retry_button)
	check(task.connected.is_empty(), "Start Over resets only the puzzle")
	await _press(task.back_button)
	await _equipment(room, "network")
	check(room.active_task.connected.is_empty(), "Reopening a partial puzzle starts it cleanly")
	room.close_task()
	# Real physics must stop in front of the wall-mounted switch (approached from below).
	room.player.global_position = room.get_interactable("network").global_position + Vector2(0, 8)
	Input.action_press("recovery_up")
	for i in range(35): await physics_frame
	Input.action_release("recovery_up")
	var switch_floor_y: float = room.get_interactable("network").get_parent().global_position.y
	check(room.player.global_position.y >= switch_floor_y and room.player.global_position.y <= switch_floor_y + 40, "Visible patch-panel footprint blocks walking through equipment")
	_remove(room)
	await process_frame
	_stages.append("safety")

func _test_standalone() -> void:
	var before: Array = _state.recovery_completed_components.duplicate()
	for scene in ["NetworkRepair", "FileServerRepair", "BackupRepair", "ResetPassword", "KickSessions", "UndoChanges", "ChangeTheLocks", "BackToWork"]:
		var task = load("res://scenes/gameplay/recovery/tasks/" + scene + ".tscn").instantiate()
		var completions: Array = []
		task.completed.connect(func(id: String) -> void: completions.append(id))
		root.add_child(task)
		current_scene = task
		await process_frame
		match scene:
			"NetworkRepair":
				for id in ["anna_device", "payroll_server"]:
					await _press(task.device_buttons[id])
					await _press(task.socket_buttons[id])
				await _press(task.test_button)
			"FileServerRepair":
				for button: Button in task.check_buttons.values(): await _press(button)
				await _press(task.test_button)
			"BackupRepair":
				await _press(task.backup_buttons["clean"])
				await _press(task.test_button)
				await _press(task.restore_button)
		task.succeed()
		check(task.solved and completions.size() == 1, "Standalone completion signal is emitted once: " + scene)
		await _press(task.back_button)
		check(not task.solved, "Standalone reset supports another attempt: " + scene)
		_remove(task)
		await process_frame
	check(_state.recovery_completed_components == before, "Standalone task scenes do not write live completion")
	_stages.append("standalone")

## Day 1 minigames: registry, Response attack map, keyboard-only play, mouse drag-and-drop,
## bounced wrong moves with reasons, and a single completion signal.
func _test_day1_minigames() -> void:
	var registry = load("res://scripts/gameplay/recovery/recovery_data.gd")
	var data: Dictionary = registry.load_data()
	var registry_ok := true
	for id: String in registry.COMPONENT_IDS:
		var scene: PackedScene = registry.task_scene(id)
		var task = scene.instantiate() if scene else null
		registry_ok = registry_ok and task != null and task.has_signal("completed") and task.component_id == id and data.components.has(id)
		if task:
			task.free()
	check(registry_ok, "Every registered minigame has a scene with the matching ID and Day 1 content")
	check(registry.components_for_attacks(data, ["stream", "sweep", "not_an_attack"]) == ["password", "reused"], "Response hits per attack map to the machines that need repair")
	check(registry.components_for_attacks(data, []).is_empty(), "A perfectly dodged fight breaks nothing")
	var day1: Array[String] = ["password", "settings", "reused", "file_server"]
	var perfect: Dictionary = registry.results(data, day1, {})
	var one_slip: Dictionary = registry.results(data, day1, {"password": 1})
	var no_damage: Dictionary = registry.results(data, ["file_server"] as Array[String], {})
	check(perfect.total == 95 and one_slip.total == 85 and no_damage.total == 20, "Points: 15 per repair, +10 when clean, 20 for Final Check (95 / 85 / 20)")
	check(one_slip.rows[1].count == 1 and one_slip.rows[3].count == 2 and one_slip.rows[2].points == 45, "A mistake only removes that repair's clean bonus, never its base")
	var many_slips: Dictionary = registry.results(data, day1, {"password": 9, "settings": 9, "reused": 9, "file_server": 9})
	check(many_slips.total == 65, "However many mistakes, every finished repair still pays its base")

	# Give Anna her account back (sign-in system), keyboard only.
	var task = load("res://scenes/gameplay/recovery/tasks/ResetPassword.tscn").instantiate()
	var completions: Array = []
	task.completed.connect(func(id: String) -> void: completions.append(id))
	root.add_child(task)
	current_scene = task
	await process_frame
	await _snapshot("30-reset-password")
	check(not task.final_switch.visible and task.request_cards.size() == 2, "Account recovery starts by checking who is asking")
	check("SIGN-IN SYSTEM" in task.get_node("%System").text, "The title bar names the machine's system")
	await _press(task.request_cards["request_a"].approve_button)
	check(task.decided.is_empty() and task.mistakes == 1 and "97" in task.feedback.text, "Approving the thief's request bounces back with the reason")
	check(task.feedback.theme_type_variation == &"FeedbackBad", "A mistake is shown in the mistake colour")
	await _press(task.request_cards["request_a"].reject_button)
	await _press(task.request_cards["request_b"].approve_button)
	check(task.identity_checked() and task.choice_cards.size() == 3 and not task.final_switch.visible, "Rejecting the thief and approving Anna opens the password pick")
	await _snapshot("39-identity-checked")
	await _press(task.choice_cards["name_year"])
	check(task.chosen.is_empty() and task.mistakes == 2 and "name" in task.feedback.text and task.choice_cards["name_year"].disabled, "A weak password is crossed out with its reason")
	await _snapshot("31-password-bounce")
	await _press(task.choice_cards["passphrase"])
	check(task.chosen == "river lantern orbit velvet" and task.final_switch.visible, "Picking the four random words shows the lockout switch")
	task.final_switch.grab_focus()
	await _key(KEY_ENTER)
	check(task.solved and completions == ["password"] and task.mistakes == 2, "Turning on the lockout completes the repair once, keeping the mistake count")
	check(task.report.get("password", "") == "river lantern orbit velvet", "The new password is remembered for Back to Work")
	check(task.get_node("%Stamp").visible, "A REPAIRED stamp pops up on success")
	await _snapshot("32-password-done")
	_remove(task)
	await process_frame

	# Kick Sessions.
	task = load("res://scenes/gameplay/recovery/tasks/KickSessions.tscn").instantiate()
	completions = []
	task.completed.connect(func(id: String) -> void: completions.append(id))
	root.add_child(task)
	current_scene = task
	await process_frame
	await _snapshot("33-kick-sessions")
	await _press(task.sign_out_buttons["anna_phone"])
	check(task.signed_out.is_empty() and task.mistakes == 1 and "phone" in task.feedback.text, "Signing out Anna's own device is refused with a reason")
	await _press(task.sign_out_buttons["unknown_germany"])
	check(task.signed_out == ["unknown_germany"] and not task.solved, "One unknown device signed out, one left")
	task.final_switch.grab_focus()
	await _key(KEY_ENTER)
	check(not task.solved and not task.final_switch.button_pressed, "2-step sign-in waits until every unknown device is signed out")
	await _press(task.sign_out_buttons["unknown_netherlands"])
	check(not task.solved and task.final_switch.visible, "A clean list then asks for 2-step sign-in")
	await _snapshot("38-lock-out-thief")
	task.final_switch.grab_focus()
	await _key(KEY_ENTER)
	check(task.solved and completions == ["sessions"], "Signing out the thief and turning on 2-step sign-in completes the task once")
	await _snapshot("34-sessions-done")
	_remove(task)
	await process_frame

	# Undo the thief's changes.
	task = load("res://scenes/gameplay/recovery/tasks/UndoChanges.tscn").instantiate()
	completions = []
	task.completed.connect(func(id: String) -> void: completions.append(id))
	root.add_child(task)
	current_scene = task
	await process_frame
	await _snapshot("40-undo-changes")
	await _press(task.sign_out_buttons["signature"])
	check(task.signed_out.is_empty() and task.mistakes == 1 and "Anna did this herself" in task.feedback.text, "A change Anna made herself is kept, with the reason")
	for id in ["forwarding", "recovery_phone", "trusted"]:
		await _press(task.sign_out_buttons[id])
	check(not task.solved and task.final_switch.visible, "Undoing every change the thief made then asks for 2-step sign-in")
	task.final_switch.grab_focus()
	await _key(KEY_ENTER)
	check(task.solved and completions == ["settings"], "Thief's changes undone and 2-step on: the task completes once")
	_remove(task)
	await process_frame

	# Change the locks.
	task = load("res://scenes/gameplay/recovery/tasks/ChangeTheLocks.tscn").instantiate()
	completions = []
	task.completed.connect(func(id: String) -> void: completions.append(id))
	root.add_child(task)
	current_scene = task
	await process_frame
	await _snapshot("37-change-locks")
	await _press(task.door_buttons["online_shop"])
	check(task.door_state.online_shop == "untested" and task.mistakes == 1, "A lock cannot be changed before the stolen key is tried")
	task.door_buttons["bank_app"]._drop_data(Vector2.ZERO, task.key.drag_payload())
	check(task.door_state.bank_app == "held", "Dragging the key onto a door with its own password: it stays locked")
	await _press(task.door_buttons["bank_app"])
	check(task.door_state.bank_app == "held" and task.mistakes == 2, "Changing a lock the key did not open is refused with a reason")
	await _press(task.key)
	await _press(task.door_buttons["personal_email"])
	check(task.door_state.personal_email == "opened", "Press the key, then a door: the stolen key opens a reused account")
	await _snapshot("41-door-opened")
	await _press(task.door_buttons["personal_email"])
	task.door_buttons["online_shop"]._drop_data(Vector2.ZERO, task.key.drag_payload())
	await _press(task.door_buttons["online_shop"])
	check(task.solved and completions == ["reused"], "Every door the key opened gets a new lock: the task completes once")
	_remove(task)
	await process_frame

	# Back to Work (Day 1 Final Check), signing in with the password the player picked.
	var data_script = load("res://scripts/gameplay/recovery/recovery_data.gd")
	var back_content: Dictionary = data_script.load_data().components.file_server.duplicate(true)
	back_content["memory"] = {"password": {"password": "river lantern orbit velvet"}}
	task = load("res://scenes/gameplay/recovery/tasks/BackToWork.tscn").instantiate()
	task.configure(back_content, data_script.load_data().task_ui, _context.sample_outcome())
	completions = []
	task.completed.connect(func(id: String) -> void: completions.append(id))
	root.add_child(task)
	current_scene = task
	await process_frame
	check(task.password == "river lantern orbit velvet", "Back to Work signs in with the password the player picked")
	await _press(task.digit_buttons["4"])
	check(task.step == 0 and task.entered_code == "", "The code waits until Anna has signed in")
	await _press(task.sign_in_button)
	check(task.step == 1, "One press signs Anna in")
	await _snapshot("42-phone-code")
	await _press(task.digit_buttons["9"])
	check(task.entered_code == "" and task.mistakes == 1, "A wrong code digit restarts the code")
	for digit in "4172":
		await _press(task.digit_buttons[digit])
	await _press(task.file_buttons["photo"])
	check(not task.solved and task.mistakes == 2, "Opening the wrong file does not count")
	await _press(task.file_buttons["payroll"])
	check(task.solved and completions == ["file_server"], "Anna is back to work: the Final Check completes once")
	await _snapshot("43-back-to-work-done")
	_remove(task)
	await process_frame
	var failing: Dictionary = _context.sample_outcome()
	failing.verification.recovery_contact = false
	task = load("res://scenes/gameplay/recovery/tasks/BackToWork.tscn").instantiate()
	task.configure(back_content, data_script.load_data().task_ui, failing)
	root.add_child(task)
	current_scene = task
	await process_frame
	await _press(task.sign_in_button)
	for digit in "4172":
		await _press(task.digit_buttons[digit])
	check(task.failed and not task.solved and "97" in task.feedback.text, "A code sent to the wrong phone keeps recovery open")
	_remove(task)
	await process_frame

	# Reconnect Cables: mouse drag-and-drop, taped plug, wrong socket.
	task = load("res://scenes/gameplay/recovery/tasks/NetworkRepair.tscn").instantiate()
	root.add_child(task)
	current_scene = task
	await process_frame
	var taped = task.device_buttons["unknown_device"]
	check(taped.locked and taped.drag_payload() == null and task.mistakes == 1 and "taped" in task.feedback.text, "The unchecked device's plug is taped down and explains why")
	var plug = task.device_buttons["anna_device"].drag_payload()
	task.socket_buttons["payroll_server"]._drop_data(Vector2.ZERO, plug)
	check(task.connected.is_empty() and task.mistakes == 2, "Dropping a plug on the wrong socket bounces back")
	for id in ["anna_device", "payroll_server"]:
		plug = task.device_buttons[id].drag_payload()
		task.socket_buttons[id]._drop_data(Vector2.ZERO, plug)
	check(task.connected.size() == 2, "Dragging each cleared plug to its socket connects it")
	await _press(task.test_button)
	check(task.solved, "Connection test passes after drag-and-drop")
	_remove(task)
	await process_frame

	# The live Day 1 work order puts each minigame on its own kind of machine.
	var room = await _new_room(["password", "settings", "reused"], _context.sample_outcome())
	await _close_briefing(room)
	check(room.get("_required") == ["password", "settings", "reused", "file_server"], "Day 1 work order follows the Response attacks, then final check")
	var groups := {}
	var machines := {}
	for id in ["password", "settings", "reused", "file_server"]:
		var station = room.get_interactable(id)
		groups[id] = station.equipment_group if station else ""
		machines[station.equipment_id if station else id] = true
	check(groups.password == "access" and groups.settings == "monitoring" and groups.reused in ["access", "monitoring"] and groups.file_server == "servers" and machines.size() == 4, "Each Day 1 minigame gets its own machine of an eligible group")
	await _equipment(room, "password")
	check(room.active_task != null and room.active_task.component_id == "password", "The access terminal opens Reset Password")
	room.close_task()
	await _equipment(room, "settings")
	check(room.active_task != null and room.active_task.component_id == "settings", "The monitoring desk opens Undo the thief's changes")
	room.close_task()
	_remove(room)
	await process_frame
	_stages.append("day1_minigames")

func _test_backup() -> void:
	var room = await _new_room(["network", "backup_database"], _context.sample_outcome(), "combined")
	await _close_briefing(room)
	await _equipment(room, "network")
	for id in ["anna_device", "payroll_server"]:
		await _press(room.active_task.device_buttons[id])
		await _press(room.active_task.socket_buttons[id])
	await _press(room.active_task.test_button)
	await _press(room.active_task.back_button)
	check(room.repairs_done() == 1, "Combined practice retains reconnection progress while walking to the other stations")
	await _fixture_at(room, "file_server")
	await _equipment(room, "file_server")
	check(room.active_task == null and room.dialog != null, "Final checks wait for required restoration")
	await _close_briefing(room)
	await _fixture_at(room, "backup_database")
	await physics_frame
	await physics_frame
	await _key(KEY_E)
	check(room.active_task != null and room.active_task.component_id == "backup_database", "Backup storage has a dedicated approach without a competing workbench target")
	room.close_task()
	await _fixture_at(room, "backup_database")
	await _equipment(room, "backup_database")
	var task = room.active_task
	await _snapshot("09-backup-cartridges")
	await _click(task.backup_buttons["recent"])
	await _click(task.test_button)
	check(task.verified_backup.is_empty(), "An unchecked post-incident backup is rejected")
	await _press(task.backup_buttons["partial"])
	await _press(task.test_button)
	check(task.verified_backup.is_empty(), "An incomplete older backup is rejected")
	await _snapshot("24-unsuitable-backup")
	for backup: Dictionary in task.content.backups:
		if backup.id == "partial":
			backup.complete = true
	await _press(task.test_button)
	check(task.verified_backup.is_empty(), "An earlier date alone does not establish trust")
	await _press(task.backup_buttons["clean"])
	await _press(task.restore_button)
	check(not task.solved, "Backup restoration requires a prior test")
	await _press(task.test_button)
	await _press(task.backup_buttons["recent"])
	await _press(task.restore_button)
	check(not task.solved, "Changing cartridge invalidates the previous passed test")
	await _press(task.backup_buttons["clean"])
	await _press(task.test_button)
	await _snapshot("10-backup-tested")
	await _press(task.restore_button)
	check(task.solved and not room.can_finish(), "Restoration still requires final verification")
	await _snapshot("25-backup-restored")
	await _press(task.back_button)
	await _fixture_at(room, "file_server")
	await _equipment(room, "file_server")
	task = room.active_task
	check(task.content.checks[0].label == "RESTORED RECORDS", "Backup practice has data-specific verification, not Anna's account story")
	task.runtime_outcome.verification.sign_in = false
	for button: Button in task.check_buttons.values(): await _press(button)
	await _press(task.test_button)
	check(not task.solved and not room.can_finish(), "A failed verification keeps recovery open")
	await _snapshot("11-failed-check")
	# Fixture: the response team supplies a corrected result. The player must rerun the check.
	task.runtime_outcome.verification.sign_in = true
	await _press(task.check_buttons["sign_in"])
	task.runtime_outcome["verification_details"] = {"recovery_contact": "code B8"}
	await _press(task.check_buttons["recovery_contact"])
	check(task.results.get("recovery_contact") == false, "A displayed mismatch overrides a claimed successful contact check")
	await _press(task.mismatch_button)
	await _press(task.test_button)
	check(not task.solved, "Correctly reporting a mismatch still leaves recovery incomplete")
	task.runtime_outcome.verification_details.recovery_contact = "code A2"
	await _press(task.test_button)
	check(not task.solved, "Corrected contact details require a fresh comparison")
	await _press(task.check_buttons["recovery_contact"])
	await _press(task.test_button)
	check(task.solved and room.can_finish(), "Corrected results must pass before final completion")
	await _press(task.back_button)
	await _snapshot("15-all-restored")
	check(room.repairs_done() == 3, "All three minigames complete in the same room and work order")
	await _equipment(room, "work_order")
	check(room.summary != null, "Combined practice finishes at the shared work-order terminal")
	_remove(room)
	await process_frame
	_stages.append("backup")

func _test_live_state_and_lab() -> void:
	_state.reset_progress()
	_state.begin_recovery([] as Array[String], _context.sample_outcome())
	var room = await _new_room([], {}, "day1", true)
	await _close_briefing(room)
	check(room.is_ready() and room.get("_required") == ["file_server"] and not room.can_finish(), "Cleared no-damage outcomes still need final verification")
	await _fixture_at(room, "file_server")
	await _equipment(room, "file_server")
	# Keyboard here: a real mouse over the visual-test window must not steal these presses.
	await _finish_final_check(room.active_task)
	check(_state.response_damage.is_empty() and _state.recovery_verification_passed, "Final verification records success without inventing damage")
	check(_state.recovery_mistakes.get("file_server", -1) == 0, "A clean final check is recorded with zero mistakes")
	await _press(room.active_task.back_button)
	var wallet_before: int = _state.wallet()
	await _fixture_at(room, "work_order")
	await _equipment(room, "work_order")
	await _press(room.summary.buttons["return"])
	await _finish_results(room)
	check(room.finish_screen.visible and _state.wallet() == wallet_before + 20 and not room.player.movement_enabled, "Finishing the live shift pays the Final Check's 20 points and locks the room")
	await _snapshot("36-live-results")
	var live_selection: Dictionary = _state.recovery_equipment_assignments.duplicate()
	check(not _state.complete_recovery_component("file_server"), "Live completion is idempotent")
	_remove(room)
	await process_frame
	room = await _new_room([], {}, "day1", true)
	await _close_briefing(room)
	check(room.can_finish() and room.repairs_done() == 1 and room.equipment_assignments() == live_selection, "Live completion and chosen equipment survive scene re-entry")
	_remove(room)
	await process_frame
	var live_outcome: Dictionary = _state.response_outcome.duplicate(true)
	var live_completed: Array = _state.recovery_completed_components.duplicate()
	var saved_selection: Dictionary = _state.recovery_equipment_assignments.duplicate()
	var demo = load(DEMO).instantiate()
	root.add_child(demo)
	current_scene = demo
	await process_frame
	await physics_frame
	await physics_frame
	var preview_hits := 0
	for point in [Vector2(237, 55), Vector2(196, 132)]:
		var query := PhysicsPointQueryParameters2D.new()
		query.position = point
		query.collision_mask = 1
		preview_hits += root.world_2d.direct_space_state.intersect_point(query).size()
	check(preview_hits == 0, "Lab scenery contributes no hidden furniture or wall collisions")
	var preview_indicators_hidden := true
	for marker in demo.preview_world.find_children("*", "Marker2D", true, false):
		if marker is RecoveryStatusMarker:
			preview_indicators_hidden = preview_indicators_hidden and not marker.is_visible_in_tree()
	check(preview_indicators_hidden, "Background preview markers cannot draw over the Lab menu")
	await _snapshot("00-lab")
	demo.call("_show_credits")
	await process_frame
	check(demo.get("_credits") != null, "In-game credits identify the active source artists")
	await _snapshot("14-art-credits")
	await _press(demo.get("_credits").buttons["close"])
	for id in ["all", "server", "day1", "current", "backup", "healthy", "waiting"]:
		demo.launch_preset(id)
		await process_frame
		await process_frame
		var local_room = demo.get("_room")
		check(local_room != null and local_room.demo_mode, "Explicit lab preset: " + id)
		if id == "all":
			await _close_briefing(local_room)
			await _equipment(local_room, "network")
			check(local_room.active_task != null, "A room launched inside the Lab retains physical travel and interaction")
		if id == "waiting":
			check(not local_room.is_ready(), "Waiting preset never fabricates containment")
		demo.call("_show_presets")
		await process_frame
	check(_state.response_outcome == live_outcome and _state.recovery_completed_components == live_completed and _state.recovery_equipment_assignments == saved_selection, "Every lab preset leaves live outcome, completion and equipment selection untouched")
	_remove(demo)
	await process_frame
	_state.reset_progress()
	check(_state.response_outcome.is_empty() and _state.response_damage.is_empty() and not _state.recovery_verification_passed and _state.recovery_equipment_assignments.is_empty(), "New Game clears the entire Recovery handoff including selected instances")
	room = await _new_room(["unknown_component"], _context.sample_outcome())
	await _close_briefing(room)
	check(not room.can_finish() and not room.get("_unknown").is_empty(), "Unsupported damage cannot silently disappear")
	_remove(room)
	await process_frame
	_stages.append("live_and_lab")

func _test_pause_and_return() -> void:
	var room = await _new_room([], _context.sample_outcome())
	await _close_briefing(room)
	await _fixture_at(room, "file_server")
	await _equipment(room, "file_server")
	var focus_before := root.gui_get_focus_owner()
	await _key(KEY_ESCAPE)
	check(paused and _pause.visible, "Escape pauses Recovery inside a task")
	_pause.call("_on_settings_button_pressed")
	await process_frame
	var settings: CanvasLayer = _pause.get("_settings")
	check(settings.visible and settings.layer > _pause.layer, "Settings is visible above Pause")
	await _snapshot("12-pause-settings")
	await _key(KEY_ESCAPE)
	await _key(KEY_ESCAPE)
	check(not paused and root.gui_get_focus_owner() == focus_before and not room.player.movement_enabled, "Resume restores task focus and keeps movement locked")
	await _finish_final_check(room.active_task)
	await _click(room.active_task.back_button)
	await _fixture_at(room, "work_order")
	await _equipment(room, "work_order")
	check(room.summary != null, "Verified no-damage case can finish at the work-order terminal")
	await _press(room.summary.buttons["return"])
	await _finish_results(room)
	check(room.finish_screen.visible and room.finish_screen.get_node("SecurityPoints/SecurityPointsGained/SPName").text.begins_with("Practice"), "Practice results show the points without paying them")
	await _snapshot("35-practice-results")
	await _press(room.finish_screen.get_node("LogsButton"))
	await create_timer(2.0).timeout
	check(current_scene != null and current_scene.scene_file_path == "res://scenes/menus/TitleMenu.tscn", "Final summary uses the existing title-menu loader")
	if current_scene != null:
		var stage := current_scene.get_node_or_null("MainContent/StageSelect") as Control
		check(stage != null and stage.visible, "Final summary returns to Stage Select")
		_remove(current_scene)
	await process_frame
	_stages.append("pause")

func _test_interaction_comfort() -> void:
	var room = await _new_room(["network", "backup_database"], _context.sample_outcome(), "combined")
	await _close_briefing(room)
	var zones: Array[Rect2] = []
	var no_overlap := true
	var generous := true
	for item in room.interactables:
		if item.kind != "task":
			continue
		var shape = item.interaction_shape.shape
		var area := Rect2(item.interaction_shape.global_position - shape.size / 2, shape.size)
		for previous in zones:
			no_overlap = no_overlap and not previous.intersects(area)
		zones.append(area)
		generous = generous and shape.size.x * 0.30859375 >= 30 and shape.size.y * 0.30859375 >= 28
		room.player.global_position = item.interaction_shape.global_position
		await physics_frame
		await physics_frame
		check(room.get("_nearby") == item and item.is_in_reach(room.player), "Standing at the approach spot selects only " + item.equipment_id)
	check(no_overlap, "Adjacent equipment interaction rectangles do not overlap")
	check(generous, "Every repair target has a comfortable footprint of at least 30 by 28 viewport pixels")
	check(room.get_equipment("repair_workbench") == null and room.world.get_node("Actors/RepairWorkbench/SolidBody") != null, "Decorative workbench keeps its collision without taking the E prompt")
	check(room.get_equipment("server_03") != null, "Existing saved server instance IDs remain available")
	_remove(room)
	await process_frame
