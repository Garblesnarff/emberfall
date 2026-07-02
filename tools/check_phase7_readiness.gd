extends SceneTree

const EXPECTED_DEMOS := {
	"Windows Demo": "exports/demo/windows/EMBERFALL_DEMO.exe",
	"Linux Demo": "exports/demo/linux/EMBERFALL_DEMO.x86_64",
	"macOS Demo": "exports/demo/macos/EMBERFALL_DEMO.zip",
}

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_assert_true(FileAccess.file_exists("res://docs/PHASE_7_DEMO_BUILD.md"), "Phase 7 demo handoff exists")
	_assert_true(Config.DEMO_FINAL_WAVE == 7, "demo final wave is 7")
	_assert_true(Config.DEMO_WEAPON_ID == &"forgehammer", "demo weapon is Forgehammer")
	_assert_true(bool(ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc", false)), "ETC2/ASTC import is enabled for universal macOS exports")
	var cfg := ConfigFile.new()
	_assert_true(cfg.load("res://export_presets.cfg") == OK, "export presets load")
	for index in range(3, 6):
		var section := "preset.%d" % index
		var name := String(cfg.get_value(section, "name", ""))
		_assert_true(EXPECTED_DEMOS.has(name), "preset %d is a supported demo target" % index)
		_assert_true(String(cfg.get_value(section, "custom_features", "")) == "demo", "%s uses the demo feature" % name)
		_assert_true(String(cfg.get_value(section, "export_path", "")) == String(EXPECTED_DEMOS.get(name, "")), "%s uses its canonical path" % name)
		_assert_true(String(cfg.get_value(section, "exclude_filter", "")).contains("steam_appid.txt"), "%s excludes local Steam identity" % name)
		_assert_true(String(cfg.get_value(section, "exclude_filter", "")).contains("generated/*_dir*_frame*.png"), "%s excludes raw render frames" % name)
	var arena_source := FileAccess.get_file_as_string("res://scripts/arena/arena.gd")
	_assert_true(arena_source.contains("_finalize_demo_run()"), "arena has a dedicated demo completion path")
	_assert_true(arena_source.contains("SaveManager.record_demo_run"), "demo completion uses neutral progression accounting")
	print("EMBERFALL Phase 7 readiness: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(failures)

func _assert_true(value: bool, message: String) -> void:
	if value:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)
