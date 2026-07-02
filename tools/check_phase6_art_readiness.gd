extends SceneTree

const MANIFEST_PATH := "res://data/static_art_manifest.json"
const SPRITE_MANIFEST_PATH := "res://data/art/phase6b_sprite_manifest.json"
const REQUIRED_GROUPS := [&"runtime_ui", &"boss_portraits", &"capsules"]

var failures := 0

func _initialize() -> void:
	print("EMBERFALL Phase 6 art readiness check")
	_check_manifest()
	_check_sprite_atlases()
	_check_ui_references()
	_check_export_filters()
	_check_version()
	if failures == 0:
		print("PASS: Phase 6 art readiness checks passed.")
	else:
		push_error("FAIL: Phase 6 art readiness checks found %d failure(s)." % failures)
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

func _check_sprite_atlases() -> void:
	_assert_true(FileAccess.file_exists(SPRITE_MANIFEST_PATH), "sprite manifest exists")
	var json := JSON.new()
	_assert_eq(json.parse(FileAccess.get_file_as_string(SPRITE_MANIFEST_PATH)), OK, "sprite manifest parses")
	if not json.get_data() is Dictionary:
		_fail("sprite manifest root is a dictionary")
		return
	for target in json.get_data().get("targets", []):
		if not target is Dictionary or not bool(target.get("enabled", true)):
			continue
		var entity_id := String(target.get("id", ""))
		var render_dir := String(target.get("render_dir", ""))
		var runtime_resource := String(target.get("runtime_resource", ""))
		_assert_true(ResourceLoader.exists(runtime_resource), "%s SpriteFrames resource exists" % entity_id)
		for animation in target.get("animations", []):
			var animation_name := String(animation.get("name", ""))
			var atlas_path := "%s/%s_%s_atlas.png" % [render_dir, entity_id, animation_name]
			_assert_true(ResourceLoader.exists(atlas_path), "%s/%s atlas exists" % [entity_id, animation_name])
			var atlas := load(atlas_path)
			_assert_true(atlas is Texture2D, "%s/%s atlas loads as Texture2D" % [entity_id, animation_name])
			if atlas is Texture2D:
				var frame_size := int(animation.get("frame_size", 0))
				_assert_eq(atlas.get_width(), int(animation.get("frames", 0)) * frame_size, "%s/%s atlas width matches manifest" % [entity_id, animation_name])
				_assert_eq(atlas.get_height(), int(animation.get("directions", 0)) * frame_size, "%s/%s atlas height matches manifest" % [entity_id, animation_name])

func _check_version() -> void:
	var version := String(ProjectSettings.get_setting("application/config/version"))
	var parts := version.split(".")
	_assert_true(parts.size() == 3 and int(parts[0]) == 0 and int(parts[1]) >= 6, "project version includes Phase 6 or later")

func _check_export_filters() -> void:
	var presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	var source_filter := "assets/sprites/**/generated/*_dir*_frame*.png"
	_assert_eq(presets.count(source_filter), 6, "all release and demo presets exclude inspectable frame sequences")
