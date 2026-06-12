extends Control

var player_pos := Vector2.ZERO
var camera_pos := Vector2.ZERO
var enemies: Array = []
var boss_telegraph_pos := Vector2.INF
var objective_markers: Array = []
var last_drawn_count := 0

func set_world_state(p_player_pos: Vector2, p_camera_pos: Vector2, p_enemies: Array, p_boss_telegraph_pos := Vector2.INF, p_objective_markers: Array = []) -> void:
	player_pos = p_player_pos
	camera_pos = p_camera_pos
	enemies = p_enemies
	boss_telegraph_pos = p_boss_telegraph_pos
	objective_markers = p_objective_markers
	queue_redraw()

func _draw() -> void:
	var threats := []
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.elite or enemy.data.boss:
			threats.append({"pos": enemy.position, "elite": enemy.elite, "boss": enemy.data.boss, "color": enemy.color})
	if boss_telegraph_pos != Vector2.INF:
		threats.append({"pos": boss_telegraph_pos, "elite": false, "boss": true, "color": Color(1.0, 0.682, 0.259)})
	for marker in objective_markers:
		threats.append({"pos": marker, "elite": false, "boss": false, "objective": true, "color": Color(0.48, 0.88, 0.52)})
	threats.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ap := 3 if a.boss else 2 if a.elite else 1
		var bp := 3 if b.boss else 2 if b.elite else 1
		if ap == bp:
			return player_pos.distance_squared_to(a.pos) < player_pos.distance_squared_to(b.pos)
		return ap > bp
	)
	var view_rect := Rect2(Vector2.ZERO, size)
	var center := size * 0.5
	var drawn := 0
	for threat in threats:
		if drawn >= Config.THREAT_CHEVRON_MAX:
			break
		var screen_pos: Vector2 = threat.pos - camera_pos + center
		if view_rect.has_point(screen_pos):
			continue
		var dir: Vector2 = (screen_pos - center).normalized()
		var edge: Vector2 = center + dir * min(size.x, size.y) * 0.47
		_draw_chevron(edge, dir.angle(), Color(1.0, 0.91, 0.77) if threat.elite or threat.boss else threat.color)
		drawn += 1
	last_drawn_count = drawn

func _draw_chevron(pos: Vector2, angle: float, color: Color) -> void:
	var forward := Vector2(cos(angle), sin(angle))
	var side := forward.orthogonal()
	var points := PackedVector2Array([
		pos + forward * 13.0,
		pos - forward * 8.0 + side * 8.0,
		pos - forward * 4.0,
		pos - forward * 8.0 - side * 8.0,
	])
	draw_colored_polygon(points, color)
