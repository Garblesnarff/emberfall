extends RefCounted
class_name PlaceholderSpriteFactory

static func enemy_frames(color: Color, radius: float, sides: int) -> SpriteFrames:
	var frames := SpriteFrames.new()
	var texture := _polygon_texture(color, radius, max(3, sides))
	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 1.0)
	frames.add_frame(&"idle", texture)
	return frames

static func _polygon_texture(color: Color, radius: float, sides: int) -> ImageTexture:
	var pad := 6
	var size := int(ceil(radius * 2.0)) + pad * 2
	var center := Vector2(size * 0.5, size * 0.5)
	var verts := PackedVector2Array()
	for i in range(sides):
		var a := TAU * float(i) / float(sides) - PI * 0.5
		var wobble := 0.82 + 0.18 * sin(float(i) * 7.0)
		verts.append(center + Vector2(cos(a), sin(a)) * radius * wobble)
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in range(size):
		for x in range(size):
			var p := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(p, verts):
				image.set_pixel(x, y, color)
			elif _near_edge(p, verts, 1.4):
				image.set_pixel(x, y, color.lightened(0.45))
	return ImageTexture.create_from_image(image)

static func _near_edge(p: Vector2, verts: PackedVector2Array, threshold: float) -> bool:
	var best := INF
	for i in range(verts.size()):
		var a := verts[i]
		var b := verts[(i + 1) % verts.size()]
		best = min(best, Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p))
	return best <= threshold
