extends SceneTree

const DEFAULT_MANIFEST := "res://data/art/phase6b_sprite_manifest.json"

var failures := 0

func _initialize() -> void:
	var args := _args_after_separator()
	var manifest_path := DEFAULT_MANIFEST if args.is_empty() else args[0]
	_build_from_manifest(manifest_path)
	quit(failures)

func _args_after_separator() -> PackedStringArray:
	var all_args := OS.get_cmdline_args()
	var result := PackedStringArray()
	var found := false
	for arg in all_args:
		if found:
			result.append(arg)
		elif arg == "--":
			found = true
	return result

func _build_from_manifest(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	if json.parse(text) != OK:
		_fail("manifest does not parse: %s" % path)
		return
	var manifest: Dictionary = json.get_data()
	for target in manifest.get("targets", []):
		if target is Dictionary and bool(target.get("enabled", true)):
			_build_target(target)

func _build_target(target: Dictionary) -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var render_dir := String(target.get("render_dir", ""))
	var runtime_resource := String(target.get("runtime_resource", ""))
	if render_dir == "" or runtime_resource == "":
		_fail("target missing render_dir/runtime_resource: %s" % str(target))
		return
	for anim in target.get("animations", []):
		if anim is Dictionary:
			_add_directional_animation(frames, String(target.get("id", "")), render_dir, anim)
	var err := ResourceSaver.save(frames, runtime_resource)
	if err == OK:
		print("Saved SpriteFrames: %s" % runtime_resource)
	else:
		_fail("failed to save SpriteFrames %s: %s" % [runtime_resource, error_string(err)])

func _add_directional_animation(frames: SpriteFrames, entity_id: String, render_dir: String, anim: Dictionary) -> void:
	var anim_name := String(anim.get("name", "walk"))
	var count := int(anim.get("frames", 1))
	var directions := int(anim.get("directions", 1))
	var fps := float(anim.get("fps", 10.0))
	var loops := bool(anim.get("loop", true))
	for direction in range(directions):
		var name := StringName("%s_%02d" % [anim_name, direction])
		frames.add_animation(name)
		frames.set_animation_speed(name, fps)
		frames.set_animation_loop(name, loops)
		for frame_index in range(count):
			var path := "%s/%s_%s_dir%02d_frame%02d.png" % [render_dir, entity_id, anim_name, direction, frame_index]
			if not ResourceLoader.exists(path):
				_fail("missing rendered frame: %s" % path)
				continue
			var texture := load(path)
			if texture is Texture2D:
				frames.add_frame(name, texture)
			else:
				_fail("rendered frame is not a Texture2D: %s" % path)
	if frames.has_animation(&"walk_00") and not frames.has_animation(&"idle") and not frames.has_animation(&"idle_00"):
		frames.add_animation(&"idle")
		frames.set_animation_speed(&"idle", fps)
		frames.set_animation_loop(&"idle", true)
		for frame_index in range(frames.get_frame_count(&"walk_00")):
			frames.add_frame(&"idle", frames.get_frame_texture(&"walk_00", frame_index))

func _fail(message: String) -> void:
	failures += 1
	push_error(message)
