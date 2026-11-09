extends SceneTree

var passed := 0
var failed := 0
var state: Node
var saves: Node
var context

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("PASS ", message)
	else:
		failed += 1
		push_error("FAIL " + message)

func discard(scene: Node) -> void:
	root.remove_child(scene)
	scene.queue_free()
	current_scene = null
	await process_frame

func _run() -> void:
	create_timer(60.0).timeout.connect(func() -> void: quit(1))
	await process_frame
	state = root.get_node("GameState")
	saves = root.get_node("SaveManager")
	context = load("res://scripts/gameplay/recovery/recovery_context.gd")
	saves.save_dir = "res://.godot/recovery-test-saves"
	check(saves.new_game(0), "Create isolated test slot without touching player saves")
	state.reset_progress()
	state.set_day(1)
	check(state.PHASES == ["investigation", "monitoring", "hardening", "response", "recovery"], "Production phase order unchanged")
	check(state.phase_info("monitoring").scene == "res://scenes/gameplay/monitoring/Monitoring.tscn", "New Monitoring scene preserved")
	check(state.is_phase_built("hardening") and state.is_phase_built("response") and state.is_phase_built("recovery"), "Hardening, Response and Recovery are all registered")
	var investigation = load("res://scenes/gameplay/investigation/Investigation.tscn").instantiate()
	root.add_child(investigation)
	current_scene = investigation
	await process_frame
	investigation.debug_find_all_clues()
	investigation.call("_on_report_completed")
	investigation.get_node("FinishScreen").set("_skipping", true)
	for frame in 4: await process_frame
	check(saves.is_phase_complete(1, "investigation"), "Existing Investigation results still complete and save")
	check(state.investigation_evidence.size() == 4 and state.identified_threat == "Credential Abuse", "Native Investigation hands its actual four clues to Recovery")
	check(saves.data.phase_findings["1"].investigation.findings.size() == 4, "Submitted findings stored in active slot")
	await discard(investigation)
	state.set_phase("monitoring")
	var monitoring = load("res://scenes/gameplay/monitoring/Monitoring.tscn").instantiate()
	root.add_child(monitoring)
	current_scene = monitoring
	await process_frame
	monitoring.set("_answers", [
		{"id": "log_001", "reported": true, "right": false, "reason": "Anna's office sign-in follows the rules."},
		{"id": "log_002", "reported": true, "right": true, "reason": "An unknown computer signed in outside working hours."},
	])
	monitoring.set("_reported", ["log_001", "log_002"])
	monitoring.set("_correct", 1)
	monitoring.set("_wrong", 1)
	monitoring.call("_finish_shift")
	monitoring.get_node("FinishScreen").set("_skipping", true)
	for frame in 4: await process_frame
	check(saves.is_phase_complete(1, "monitoring"), "Existing Monitoring results still complete and save")
	var briefing: Dictionary = context.snapshot_live()
	check(briefing.evidence.size() == 4 and "Anna" in briefing.evidence[0], "Briefing resolves new Investigation dataset")
	check(briefing.reports.size() == 2 and "FALSE ALARM" in briefing.reports[0] and "SUSPICIOUS" in briefing.reports[1], "Generated report snapshots retain normal versus suspicious verdicts")
	check("outside working hours" in briefing.reports[1], "Generated reports retain the actual rule explanation")
	await discard(monitoring)
	# These two phases are simulated only in this isolated fixture, not added to gameplay.
	saves.complete_phase(1, "hardening")
	saves.complete_phase(1, "response")
	var outcome: Dictionary = context.sample_outcome()
	state.begin_recovery(["network", "network"] as Array[String], outcome)
	check(state.response_damage == ["network"], "Response handoff retains stable IDs and removes duplicates")
	check(not state.complete_recovery_component("file_server"), "Final check cannot bypass required restoration")
	check(state.assign_recovery_equipment("network", "network_switch") == "network_switch", "Selected equipment saved once")
	check(state.complete_recovery_component("network", 2), "Live repair completion accepted")
	check(not state.complete_recovery_component("network"), "Duplicate repair cannot count twice")
	state.reset_progress()
	check(state.response_damage.is_empty() and state.phase_findings.is_empty(), "Run reset clears live Recovery and findings")
	check(saves.load_slot(0) == saves.Status.OK, "Reload actual saved slot")
	state.set_day(1)
	state.set_phase("recovery")
	check(state.recovery_completed_components == ["network"] and state.recovery_equipment_assignments.network == "network_switch" and int(state.recovery_mistakes.get("network", -1)) == 2, "Repair progress, selection and mistake count survive disk reload")
	check(context.snapshot_live().evidence.size() == 4 and context.snapshot_live().reports.size() == 2, "Earlier findings survive resume")
	check(saves.resume_point() == {"day": 1, "phase": "recovery"}, "Existing Resume points to incomplete Recovery")
	check(not state.finish_recovery(), "Unverified work order cannot complete the saved phase")
	check(state.complete_recovery_component("file_server") and state.finish_recovery(), "Verified live Recovery completes through existing SaveManager")
	check(saves.is_phase_complete(1, "recovery") and saves.resume_point().day == 2, "Finished day advances the existing resume point")
	var before: Dictionary = saves.data.duplicate(true)
	var lab = load("res://scenes/gameplay/recovery/RecoveryDemo.tscn").instantiate()
	root.add_child(lab)
	current_scene = lab
	await process_frame
	for id in ["all", "server", "day1", "current", "backup", "healthy", "waiting"]:
		lab.launch_preset(id)
		await process_frame
		lab.call("_show_presets")
		await process_frame
	check(saves.data == before, "All seven practice scenarios leave save-slot data unchanged")
	await discard(lab)
	var legacy: Dictionary = saves.call("_new_data")
	legacy.erase("phase_findings")
	legacy.erase("recovery_runs")
	var encoded: PackedByteArray = saves.call("_encode", legacy)
	var decoded: Dictionary = saves.call("_decode", encoded)
	check(decoded.status == saves.Status.OK and decoded.data.phase_findings.is_empty() and decoded.data.recovery_runs.is_empty(), "Existing version-1 saves load with empty optional Recovery records")
	check(saves.new_game(1), "Fresh save slot starts")
	state.reset_progress()
	state.set_day(1)
	check(state.response_outcome.is_empty() and state.recovery_completed_components.is_empty() and state.recovery_equipment_assignments.is_empty(), "New Game cannot inherit another slot's Recovery progress")
	check(not state.finish_recovery(), "No Response outcome cannot authorize completion")
	state.begin_recovery([] as Array[String], context.sample_outcome())
	check(state.response_damage.is_empty() and not state.recovery_verification_passed, "Confirmed zero damage still requires final verification")
	check(state.complete_recovery_component("file_server"), "No-damage verification is available")
	# The real Response hands the attacks that got through to Recovery (option A).
	state.reset_progress()
	state.set_day(1)
	state.set_phase("response")
	saves.data["tutorial"] = [] # the tutorial pop-up pauses the game, and the ending of the fight needs it running
	paused = false # the Recovery scenes above were removed by hand, so they never un-paused the game
	var response = load(str(state.phase_info("response").scene)).instantiate()
	root.add_child(response)
	current_scene = response
	for frame in 3: await process_frame
	response.hit_patterns.assign(["stream", "stolen"])
	await response._finish(true) # the threat falls apart and the player celebrates first
	check("Rapid guesses" in response.get_node("FinishScreen/CommentTitle/CommentContent").text, "Response's win screen names what got through")
	response.call("_on_leave_pressed")
	check(state.response_damage == ["password", "settings"] and state.current_phase == "recovery" and state.response_outcome.get("contained", false), "Attacks that got through become the Recovery repairs")
	check(saves.is_phase_complete(1, "response"), "Winning Response saves the phase as complete")
	await create_timer(3.0).timeout
	check(current_scene != null and current_scene.scene_file_path == "res://scenes/gameplay/recovery/Recovery.tscn", "CONTINUE after the fight opens Recovery")
	if current_scene != null:
		await discard(current_scene)
	for slot in [0, 1]: saves.delete_slot(slot)
	state.reset_progress()
	print("INTEGRATION RESULTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
