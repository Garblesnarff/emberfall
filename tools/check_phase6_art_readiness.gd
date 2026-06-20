extends SceneTree

const MANIFEST_PATH := "res://data/static_art_manifest.json"
const REQUIRED_GROUPS := [&"runtime_ui", &"boss_portraits", &"capsules"]

var failures := 0

func _initialize() -> void:
	print("EMBERFALL Phase 6A static art readiness check")
	_check_manifest()
	_check_ui_references()
	_check_version()
	if failures == 0:
		print("PASS: Phase 6A static art readiness checks passed.")
	else:
		push_error("FAIL: Phase 6A static art readiness checks found %d failure(s)." % failures)
	quit(failures)

func _pass(message: String) -> void:
	print("PASS: " + message)

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

func _check_manifest() -> void:
	_assert_true(FileAccess.file_exists(MANIFEST_PATH), "static art manifest exists")
	var json := JSON.new()
	var text := FileAccess.get_file_as_string(MANIFEST_PATH)
	_assert_eq(json.parse(text), OK, "static art manifest parses")
	if not json.get_data() is Dictionary:
		_fail("static art manifest root is a dictionary")
		return
	var manifest: Dictionary = json.get_data()
	for group_name in REQUIRED_GROUPS:
		var group: Variant = manifest.get(String(group_name), {})
		if not group is Dictionary:
			_fail("%s group is a dictionary" % String(group_name))
			continue
		for key in group.keys():
			var path := String(group[key])
			_assert_true(path.begins_with("res://assets/"), "%s/%s uses an asset path" % [String(group_name), String(key)])
			_assert_true(not path.begins_with("res://assets/concepts/"), "%s/%s does not point at concept art" % [String(group_name), String(key)])
			_assert_true(ResourceLoader.exists(path), "%s/%s resource exists" % [String(group_name), String(key)])
			var texture := load(path)
			_assert_true(texture is Texture2D, "%s/%s loads as Texture2D" % [String(group_name), String(key)])
			if texture is Texture2D:
				_assert_true(texture.get_width() > 0 and texture.get_height() > 0, "%s/%s has non-zero dimensions" % [String(group_name), String(key)])

func _check_ui_references() -> void:
	var forge_scene := FileAccess.get_file_as_string("res://scenes/ui/forge_menu.tscn")
	var recap_script := FileAccess.get_file_as_string("res://scripts/ui/recap.gd")
	_assert_true(forge_scene.contains("res://assets/sprites/ui/menu_background.png"), "Forge menu references production menu background")
	_assert_true(forge_scene.contains("res://assets/sprites/ui/word_mark.png"), "Forge menu references production wordmark")
	_assert_true(not forge_scene.contains("res://assets/concepts/"), "Forge menu has no concept art references")
	_assert_true(recap_script.contains("res://assets/sprites/ui/victory_screen.png"), "Recap references production victory screen")
	_assert_true(recap_script.contains("res://assets/sprites/ui/defeat_screen.png"), "Recap references production defeat screen")
	_assert_true(not recap_script.contains("res://assets/concepts/"), "Recap has no concept art references")

func _check_version() -> void:
	var version := String(ProjectSettings.get_setting("application/config/version"))
	_assert_true(version.begins_with("0.6."), "project version is in the Phase 6 range")
