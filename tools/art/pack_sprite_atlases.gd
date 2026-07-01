extends SceneTree

const DEFAULT_MANIFEST := "res://data/art/phase6b_sprite_manifest.json"

var failures := 0

func _initialize() -> void:
	var args := _args_after_separator()
	var manifest_path := DEFAULT_MANIFEST if args.is_empty() else args[0]
	_pack_from_manifest(manifest_path)
	quit(failures)

func _args_after_separator() -> PackedStringArray:
	var result := PackedStringArray()
	var found := false
	for arg in OS.get_cmdline_args():
		if found:
			result.append(arg)
		elif arg == "--":
			found = true
	return result

func _pack_from_manifest(path: String) -> void:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		_fail("manifest does not parse: %s" % path)
		return
	var manifest: Dictionary = json.get_data()
	for target in manifest.get("targets", []):
		if target is Dictionary and bool(target.get("enabled", true)):
			_pack_target(target)

func _pack_target(target: Dictionary) -> void:
	var entity_id := String(target.get("id", ""))
	var render_dir := String(target.get("render_dir", ""))
	if entity_id == "" or render_dir == "":
		_fail("target missing id/render_dir: %s" % str(target))
		return
	for animation in target.get("animations", []):
		if animation is Dictionary:
			_pack_animation(entity_id, render_dir, animation)

func _pack_animation(entity_id: String, render_dir: String, animation: Dictionary) -> void:
	var animation_name := String(animation.get("name", "walk"))
	var frame_count := int(animation.get("frames", 1))
	var directions := int(animation.get("directions", 1))
	var frame_size := int(animation.get("frame_size", 96))
	var atlas := Image.create(frame_count * frame_size, directions * frame_size, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	for direction in range(directions):
		for frame_index in range(frame_count):
			var source_path := "%s/%s_%s_dir%02d_frame%02d.png" % [render_dir, entity_id, animation_name, direction, frame_index]
			var source := Image.load_from_file(ProjectSettings.globalize_path(source_path))
			if source == null or source.is_empty():
				_fail("missing rendered frame: %s" % source_path)
				continue
			if source.get_width() != frame_size or source.get_height() != frame_size:
				_fail("frame size mismatch for %s" % source_path)
				continue
			atlas.blit_rect(source, Rect2i(0, 0, frame_size, frame_size), Vector2i(frame_index * frame_size, direction * frame_size))
	var atlas_path := "%s/%s_%s_atlas.png" % [render_dir, entity_id, animation_name]
	var error := atlas.save_png(ProjectSettings.globalize_path(atlas_path))
	if error == OK:
		print("Saved sprite atlas: %s" % atlas_path)
	else:
		_fail("failed to save atlas %s: %s" % [atlas_path, error_string(error)])

func _fail(message: String) -> void:
	failures += 1
	push_error(message)
