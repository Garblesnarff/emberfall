extends SceneTree

const EXPECTED_EXPORTS := {
	"Windows Steam": "exports/windows/EMBERFALL.exe",
	"Linux Steam": "exports/linux/EMBERFALL.x86_64",
	"macOS Steam": "exports/macos/EMBERFALL.zip",
}

const EXPECTED_ACHIEVEMENTS := {
	&"first_light": "ACH_FIRST_LIGHT",
	&"slagbreaker": "ACH_SLAGBREAKER",
	&"choir_silencer": "ACH_CHOIR_SILENCER",
	&"tyrants_end": "ACH_TYRANTS_END",
	&"forge_secured": "ACH_FORGE_SECURED",
	&"untouchable": "ACH_UNTOUCHABLE",
	&"centurion": "ACH_CENTURION",
	&"evolved": "ACH_EVOLVED",
	&"full_bank": "ACH_FULL_BANK",
	&"old_hand": "ACH_OLD_HAND",
}

const EXPECTED_STATS := {
	&"runs": "STAT_RUNS",
	&"kills": "STAT_KILLS",
	&"deaths": "STAT_DEATHS",
	&"play_ms": "STAT_PLAY_MS",
	&"victories": "STAT_VICTORIES",
	&"best_wave": "STAT_BEST_WAVE",
	&"best_score": "STAT_BEST_SCORE",
	&"best_combo": "STAT_BEST_COMBO",
	&"embers": "STAT_EMBERS",
}

const EXPECTED_INPUT_ACTIONS := {
	&"move": "Move",
	&"aim": "Aim",
	&"dash": "Dash",
	&"pause": "Pause",
	&"ui_accept": "MenuAccept",
	&"ui_cancel": "MenuBack",
	&"ui_navigate": "MenuNavigate",
}

var failures := 0
var warnings := 0

func _initialize() -> void:
	print("EMBERFALL Phase 5 readiness check")
	_check_project_version()
	_check_steamworks_manifest()
	_check_export_presets()
	_check_steam_api_maps()
	_check_local_file_hygiene()
	_check_handoff_docs()
	if failures == 0:
		print("PASS: Phase 5 local readiness checks passed with %d warning(s)." % warnings)
	else:
		push_error("FAIL: Phase 5 local readiness checks found %d failure(s), %d warning(s)." % [failures, warnings])
	quit(failures)

func _pass(message: String) -> void:
	print("PASS: " + message)

func _warn(message: String) -> void:
	warnings += 1
	push_warning("WARN: " + message)

func _fail(message: String) -> void:
	failures += 1
	push_error("FAIL: " + message)

func _assert_true(value: bool, message: String) -> void:
	if value:
		_pass(message)
	else:
		_fail(message)

func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	_assert_true(actual == expected, "%s (expected %s, got %s)" % [message, str(expected), str(actual)])

func _check_project_version() -> void:
	var version := String(ProjectSettings.get_setting("application/config/version"))
	_assert_true(version != "", "project has an application version")
	_assert_true(version.split(".").size() == 3, "project version uses three-part numbering")

func _check_steamworks_manifest() -> void:
	_assert_true(FileAccess.file_exists("res://data/steamworks_manifest.json"), "Steamworks setup manifest exists")
	var text := FileAccess.get_file_as_string("res://data/steamworks_manifest.json")
	var json := JSON.new()
	_assert_eq(json.parse(text), OK, "Steamworks setup manifest parses as JSON")
	if json.get_data() is Dictionary:
		var manifest: Dictionary = json.get_data()
		_assert_eq(String(manifest.get("app_id", "")), "TBD", "Steamworks manifest keeps app ID unset until external setup")
		var cloud: Dictionary = manifest.get("cloud", {})
		_assert_eq(String(cloud.get("save_path", "")), "user://emberfall.save", "Steamworks manifest declares the cloud save path")
		_assert_manifest_entries(manifest.get("achievements", []), "id", "api_name", EXPECTED_ACHIEVEMENTS, "achievement")
		_assert_manifest_entries(manifest.get("stats", []), "id", "api_name", EXPECTED_STATS, "stat")
		_assert_manifest_entries(manifest.get("input_actions", []), "id", "action_name", EXPECTED_INPUT_ACTIONS, "Steam Input action")
		_assert_manifest_exports(manifest.get("export_targets", []))

func _check_export_presets() -> void:
	var cfg := ConfigFile.new()
	_assert_eq(cfg.load("res://export_presets.cfg"), OK, "export presets config loads")
	var project_version := String(ProjectSettings.get_setting("application/config/version"))
	var found := {}
	for index in range(EXPECTED_EXPORTS.size()):
		var section := "preset.%d" % index
		var options_section := "%s.options" % section
		var name := String(cfg.get_value(section, "name", ""))
		found[name] = true
		_assert_true(EXPECTED_EXPORTS.has(name), "export preset %d is an expected Steam target" % index)
		_assert_eq(String(cfg.get_value(section, "custom_features", "")), "steam", "%s uses the steam feature tag" % name)
		_assert_eq(String(cfg.get_value(section, "export_path", "")), String(EXPECTED_EXPORTS.get(name, "")), "%s export path stays under ignored exports/" % name)
		var exclude_filter := String(cfg.get_value(section, "exclude_filter", ""))
		_assert_true(exclude_filter.contains("steam_appid.txt"), "%s export excludes local steam_appid.txt" % name)
		_assert_true(exclude_filter.contains("exports/**"), "%s export excludes local export outputs" % name)
		_assert_true(exclude_filter.contains("reports/**"), "%s export excludes local test reports" % name)
		_assert_true(bool(cfg.get_value(section, "runnable", false)), "%s export is runnable" % name)
		if name == "Windows Steam":
			_assert_eq(String(cfg.get_value(options_section, "application/file_version", "")), project_version, "Windows file version matches project version")
			_assert_eq(String(cfg.get_value(options_section, "application/product_version", "")), project_version, "Windows product version matches project version")
		elif name == "macOS Steam":
			_assert_eq(String(cfg.get_value(options_section, "application/short_version", "")), project_version, "macOS short version matches project version")
			_assert_eq(String(cfg.get_value(options_section, "application/version", "")), project_version, "macOS build version matches project version")
	for expected_name in EXPECTED_EXPORTS.keys():
		_assert_true(found.has(expected_name), "export presets include %s" % expected_name)

func _assert_manifest_entries(entries: Variant, id_key: String, value_key: String, expected: Dictionary, label: String) -> void:
	if not entries is Array:
		_fail("Steamworks manifest %s list is an array" % label)
		return
	var found := {}
	for entry in entries:
		if entry is Dictionary:
			found[StringName(String(entry.get(id_key, "")))] = String(entry.get(value_key, ""))
	for id in expected.keys():
		_assert_eq(String(found.get(id, "")), String(expected[id]), "Steamworks manifest %s %s matches code contract" % [label, String(id)])

func _assert_manifest_exports(entries: Variant) -> void:
	if not entries is Array:
		_fail("Steamworks manifest export target list is an array")
		return
	var found := {}
	for entry in entries:
		if entry is Dictionary:
			found[String(entry.get("name", ""))] = String(entry.get("path", ""))
	for name in EXPECTED_EXPORTS.keys():
		_assert_eq(String(found.get(name, "")), String(EXPECTED_EXPORTS[name]), "Steamworks manifest export target %s matches preset path" % name)

func _check_steam_api_maps() -> void:
	var steam_manager := FileAccess.get_file_as_string("res://autoload/SteamManager.gd")
	for id in EXPECTED_ACHIEVEMENTS.keys():
		_assert_true(steam_manager.contains("&\"%s\"" % String(id)), "Steam achievement map includes %s" % String(id))
		_assert_true(steam_manager.contains(String(EXPECTED_ACHIEVEMENTS[id])), "Steam achievement API map includes %s" % String(EXPECTED_ACHIEVEMENTS[id]))
	for id in EXPECTED_STATS.keys():
		_assert_true(steam_manager.contains("&\"%s\"" % String(id)), "Steam stat map includes %s" % String(id))
		_assert_true(steam_manager.contains(String(EXPECTED_STATS[id])), "Steam stat API map includes %s" % String(EXPECTED_STATS[id]))
	for id in EXPECTED_INPUT_ACTIONS.keys():
		_assert_true(steam_manager.contains("&\"%s\"" % String(id)), "Steam Input map includes %s" % String(id))
		_assert_true(steam_manager.contains(String(EXPECTED_INPUT_ACTIONS[id])), "Steam Input action map includes %s" % String(EXPECTED_INPUT_ACTIONS[id]))

func _check_local_file_hygiene() -> void:
	var ignore_text := FileAccess.get_file_as_string("res://.gitignore")
	_assert_true(ignore_text.contains("exports/"), "exports directory is gitignored")
	_assert_true(ignore_text.contains("steam_appid.txt"), "local steam_appid.txt is gitignored")
	_assert_true(ignore_text.contains("reports/"), "test reports directory is gitignored")
	if FileAccess.file_exists("res://steam_appid.txt"):
		_warn("steam_appid.txt exists locally; keep it out of commits and remove it from release archives when inappropriate")

func _check_handoff_docs() -> void:
	_assert_true(FileAccess.file_exists("res://docs/PHASE_5_STEAM_HANDOFF.md"), "Steam handoff doc exists")
	_assert_true(FileAccess.file_exists("res://docs/PHASE_5_RELEASE_READINESS.md"), "release readiness doc exists")
	_assert_true(FileAccess.file_exists("res://docs/PHASE_5_LOCAL_COMPLETION_AUDIT.md"), "Phase 5 local completion audit exists")
	_assert_true(FileAccess.file_exists("res://docs/STEAMWORKS_DASHBOARD_CHECKLIST.md"), "Steamworks dashboard checklist exists")
	var handoff := FileAccess.get_file_as_string("res://docs/PHASE_5_STEAM_HANDOFF.md")
	_assert_true(handoff.contains("data/steamworks_manifest.json"), "handoff doc points to the Steamworks setup manifest")
	_assert_true(handoff.contains("ACH_FIRST_LIGHT"), "handoff doc lists achievement API IDs")
	_assert_true(handoff.contains("STAT_RUNS"), "handoff doc lists stat API IDs")
	_assert_true(handoff.contains("MenuAccept"), "handoff doc lists Steam Input action names")
	var checklist := FileAccess.get_file_as_string("res://docs/STEAMWORKS_DASHBOARD_CHECKLIST.md")
	_assert_true(checklist.contains("data/steamworks_manifest.json"), "dashboard checklist points to the Steamworks setup manifest")
	_assert_true(checklist.contains("ACH_FIRST_LIGHT"), "dashboard checklist lists achievement API IDs")
	_assert_true(checklist.contains("STAT_RUNS"), "dashboard checklist lists stat API IDs")
	_assert_true(checklist.contains("MenuAccept"), "dashboard checklist lists Steam Input action names")
	var audit := FileAccess.get_file_as_string("res://docs/PHASE_5_LOCAL_COMPLETION_AUDIT.md")
	_assert_true(audit.contains("Phase 5 is locally prepared"), "local completion audit states the local Phase 5 boundary")
	_assert_true(audit.contains("GodotSteam GDExtension binaries"), "local completion audit lists external GodotSteam requirement")
	_assert_true(audit.contains("Steam Deck hardware"), "local completion audit lists external Deck verification")
