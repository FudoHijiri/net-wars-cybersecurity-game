class_name RecoveryContext
extends RefCounted

## Read-only bridge. A monitoring report is not necessarily a confirmed threat.
static func snapshot_live() -> Dictionary:
	var info := GameState.day_info()
	var data := RecoveryData.load_data()
	var evidence: Array[String] = []
	var submitted: Dictionary = GameState.phase_findings.get("investigation", {})
	evidence.assign(submitted.get("findings", []))
	# F6/unsaved runs can still resolve current clue IDs against the current phase's dataset.
	if evidence.is_empty():
		var investigation := _read_json(str(GameState.phase_info("investigation").get("data", "")))
		for app: Dictionary in investigation.get("investigation", {}).values():
			for entry: Dictionary in app.get("entries", []):
				if GameState.investigation_evidence.has(str(entry.get("id", ""))):
					evidence.append(str(entry.get("summary", entry.get("title", ""))))
	var reports: Array[String] = []
	var resolved: Array[String] = []
	for report: Dictionary in GameState.phase_findings.get("monitoring", {}).get("reports", []):
		var id := str(report.get("id", ""))
		var verdict := "SUSPICIOUS" if report.get("suspicious", false) else "NORMAL / FALSE ALARM"
		reports.append(verdict + " - " + id + ": " + str(report.get("reason", "")))
		resolved.append(id)
	for id: String in GameState.reported_anomalies:
		if not resolved.has(id):
			reports.append("Reported log " + id + ": its details were not retained; the verdict is unavailable.")
	return {
		"day": GameState.current_day, "title": info.get("title", "Day %d" % GameState.current_day),
		"threat": GameState.identified_threat if not GameState.identified_threat.is_empty() else "Not identified yet",
		"evidence": evidence, "reports": reports, "points": GameState.wallet(),
		"hardening": data.get("room", {}).get("hardening_unavailable", ""),
		"brief": data.get("case", {}).get("brief", "") if GameState.current_day == 1 else "No recovery lesson has been authored for this day yet.",
		"profile": "day1" if GameState.current_day == 1 else "unsupported",
	}


static func sample_context(profile: String = "day1") -> Dictionary:
	var data := RecoveryData.load_data()
	if profile == "current":
		return snapshot_live().duplicate(true)
	if profile == "server":
		var server := sample_context("backup")
		server["title"] = "One server needs checking"
		server["practice_kind"] = "server"
		server["threat"] = "Service availability practice"
		server["brief"] = "Response has cleared the equipment. Check the marked server before returning it to normal use. The other two servers remain online."
		server["lesson"] = "A server appearing online does not prove recovery. Check that ordinary access and expected records work."
		return server
	if profile == "combined":
		var combined := sample_context("backup")
		combined["title"] = "Combined recovery practice"
		combined["practice_kind"] = "combined"
		combined["brief"] = "A separate practice incident left equipment disconnected and records unavailable. Reconnect only cleared devices, restore a trustworthy backup, then verify the recovered service."
		return combined
	var case_data: Dictionary = data.get("case", {})
	var practice: Dictionary = data.get("practice", {})
	return {
		"day": 1, "title": practice.get("title", "") if profile == "backup" else case_data.get("day_title", ""),
		"threat": "Separate data-restoration exercise" if profile == "backup" else case_data.get("threat", ""),
		"evidence": [] if profile == "backup" else case_data.get("sample_evidence", []).duplicate(),
		"reports": [] if profile == "backup" else case_data.get("sample_monitoring", []).duplicate(),
		"points": 0, "hardening": data.get("room", {}).get("hardening_unavailable", ""),
		"brief": practice.get("brief", "") if profile == "backup" else case_data.get("brief", ""),
		"profile": "backup" if profile == "backup" else "day1",
	}


static func sample_outcome() -> Dictionary:
	var outcome: Dictionary = RecoveryData.load_data().get("sample_outcome", {}).duplicate(true)
	outcome["received"] = true
	return outcome


static func is_cleared(outcome: Dictionary) -> bool:
	return outcome.get("received", false) == true and outcome.get("contained", false) == true


static func required_components(damage: Array[String]) -> Array[String]:
	var required: Array[String] = []
	for id in RecoveryData.COMPONENT_IDS:
		if id != RecoveryData.FINAL_CHECK and damage.has(id):
			required.append(id)
	# Every supported outcome ends with final verification, even with zero damage.
	required.append(RecoveryData.FINAL_CHECK)
	return required


static func _read_json(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
